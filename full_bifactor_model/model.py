from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd
from scipy.optimize import minimize
from scipy.special import logsumexp, ndtri

from bifactor_model.model import (
    CONTINUOUS_COLUMNS,
    DOMAINS,
    FACTOR_NAMES,
    INDICATORS,
    FitResult,
    ParameterLayout,
    _continuous_log_prob,
    _ordinal_log_prob,
    continuous_parameter_table,
    domain_for_column,
    inverse_softplus,
    item_index,
    loading_table,
    make_layout,
    orient_params,
    quadrature_rule,
    threshold_table,
    unpack_params,
)


@dataclass(frozen=True)
class IndicatorObservations:
    """One indicator's observed values, sorted by individual index."""

    individual_index: np.ndarray
    values: np.ndarray


@dataclass(frozen=True)
class PreparedData:
    """Long-file arrays for a full-information mixed bifactor likelihood."""

    source_dir: Path
    individual_ids: np.ndarray
    n_individuals: int
    columns: list[str]
    continuous_columns: list[str]
    ordinal_columns: list[str]
    continuous: dict[str, IndicatorObservations]
    ordinal_codes: dict[str, IndicatorObservations]
    ordinal_categories: dict[str, list[float]]
    means: dict[str, float]
    stds: dict[str, float]
    observation_counts: dict[str, int]


def _normalise_id(value: object) -> str | None:
    if pd.isna(value):
        return None
    text = str(value).strip()
    if not text:
        return None
    if text.endswith(".0"):
        text = text[:-2]
    return text


def _id_sort_key(value: str) -> tuple[int, float | str]:
    try:
        return (0, float(value))
    except ValueError:
        return (1, value)


def _read_indicator_file(data_dir: Path, column: str) -> pd.DataFrame:
    path = data_dir / f"{column}.csv"
    if not path.exists():
        raise FileNotFoundError(f"Missing indicator file: {path}")

    df = pd.read_csv(path, dtype={"idauniq": "string"})
    missing = [name for name in ("idauniq", column) if name not in df.columns]
    if missing:
        raise ValueError(f"{path} is missing columns: {', '.join(missing)}")

    out = df.loc[:, ["idauniq", column]].copy()
    out["idauniq"] = out["idauniq"].map(_normalise_id)
    out[column] = pd.to_numeric(out[column], errors="coerce")
    out = out.dropna(subset=["idauniq", column])
    if out.empty:
        raise ValueError(f"{path} has no usable non-missing observations.")
    return out


def _sorted_observations(
    frame: pd.DataFrame,
    id_to_index: dict[str, int],
    values: np.ndarray,
) -> IndicatorObservations:
    individual_index = frame["idauniq"].map(id_to_index).to_numpy(dtype=int)
    order = np.argsort(individual_index, kind="stable")
    return IndicatorObservations(
        individual_index=individual_index[order].astype(int, copy=False),
        values=values[order],
    )


def prepare_data(data_dir: str | Path) -> PreparedData:
    """Load the 18 per-indicator CSV files and align rows by idauniq."""

    source_dir = Path(data_dir)
    frames = {column: _read_indicator_file(source_dir, column) for column in INDICATORS}

    all_ids = sorted(
        {
            individual_id
            for frame in frames.values()
            for individual_id in frame["idauniq"].to_numpy(dtype=object)
        },
        key=_id_sort_key,
    )
    if not all_ids:
        raise ValueError("No individuals found in the indicator files.")

    id_to_index = {individual_id: index for index, individual_id in enumerate(all_ids)}
    continuous: dict[str, IndicatorObservations] = {}
    ordinal_codes: dict[str, IndicatorObservations] = {}
    ordinal_categories: dict[str, list[float]] = {}
    means: dict[str, float] = {}
    stds: dict[str, float] = {}
    observation_counts: dict[str, int] = {}

    for column in INDICATORS:
        frame = frames[column]
        raw_values = frame[column].to_numpy(dtype=float)
        observation_counts[column] = int(len(raw_values))

        if column in CONTINUOUS_COLUMNS:
            mean = float(np.mean(raw_values))
            std = float(np.std(raw_values, ddof=0))
            if std <= 0:
                raise ValueError(f"{column} has zero variance and cannot be modeled as continuous.")
            means[column] = mean
            stds[column] = std
            continuous[column] = _sorted_observations(
                frame=frame,
                id_to_index=id_to_index,
                values=((raw_values - mean) / std).astype(float, copy=False),
            )
        else:
            categories = sorted(float(value) for value in pd.unique(raw_values))
            if len(categories) < 2:
                raise ValueError(f"{column} has fewer than two observed categories.")
            category_to_code = {category: code for code, category in enumerate(categories)}
            codes = np.array([category_to_code[float(value)] for value in raw_values], dtype=int)
            ordinal_codes[column] = _sorted_observations(
                frame=frame,
                id_to_index=id_to_index,
                values=codes,
            )
            ordinal_categories[column] = categories

    return PreparedData(
        source_dir=source_dir,
        individual_ids=np.array(all_ids, dtype=object),
        n_individuals=len(all_ids),
        columns=list(INDICATORS),
        continuous_columns=list(CONTINUOUS_COLUMNS),
        ordinal_columns=[column for column in INDICATORS if column not in CONTINUOUS_COLUMNS],
        continuous=continuous,
        ordinal_codes=ordinal_codes,
        ordinal_categories=ordinal_categories,
        means=means,
        stds=stds,
        observation_counts=observation_counts,
    )


def subset_individuals(data: PreparedData, keep_indices: np.ndarray) -> PreparedData:
    """Return a PreparedData view containing only the selected individuals."""

    keep_indices = np.sort(np.asarray(keep_indices, dtype=int))
    if len(keep_indices) == 0:
        raise ValueError("Cannot fit a model with zero sampled individuals.")
    if keep_indices[0] < 0 or keep_indices[-1] >= data.n_individuals:
        raise IndexError("Sampled individual index is outside the data range.")

    remap = np.full(data.n_individuals, -1, dtype=int)
    remap[keep_indices] = np.arange(len(keep_indices))

    def subset_observations(observations: IndicatorObservations) -> IndicatorObservations:
        mapped = remap[observations.individual_index]
        mask = mapped >= 0
        return IndicatorObservations(
            individual_index=mapped[mask].astype(int, copy=False),
            values=observations.values[mask],
        )

    continuous = {
        column: subset_observations(observations)
        for column, observations in data.continuous.items()
    }
    ordinal_codes = {
        column: subset_observations(observations)
        for column, observations in data.ordinal_codes.items()
    }
    observation_counts = {
        column: int(len(observations.values))
        for column, observations in {**continuous, **ordinal_codes}.items()
    }

    return PreparedData(
        source_dir=data.source_dir,
        individual_ids=data.individual_ids[keep_indices],
        n_individuals=len(keep_indices),
        columns=list(data.columns),
        continuous_columns=list(data.continuous_columns),
        ordinal_columns=list(data.ordinal_columns),
        continuous=continuous,
        ordinal_codes=ordinal_codes,
        ordinal_categories={key: list(value) for key, value in data.ordinal_categories.items()},
        means=dict(data.means),
        stds=dict(data.stds),
        observation_counts=observation_counts,
    )


def sample_individuals(data: PreparedData, sample_size: int, seed: int) -> PreparedData:
    if sample_size >= data.n_individuals:
        return data
    rng = np.random.default_rng(seed)
    keep_indices = rng.choice(data.n_individuals, size=sample_size, replace=False)
    return subset_individuals(data, keep_indices)


def initial_params(data: PreparedData, layout: ParameterLayout) -> np.ndarray:
    params = np.zeros(layout.n_params, dtype=float)
    params[layout.general] = 0.55
    params[layout.domain] = 0.35
    params[layout.continuous_intercepts] = 0.0
    params[layout.log_sigmas] = np.log(0.75)

    for column in data.ordinal_columns:
        start, stop = layout.thresholds[column]
        codes = data.ordinal_codes[column].values.astype(int, copy=False)
        n_categories = layout.ordinal_n_categories[column]
        counts = np.bincount(codes, minlength=n_categories).astype(float)
        cumulative = np.cumsum(counts)[:-1] / np.sum(counts)
        tau = ndtri(np.clip(cumulative, 1e-4, 1.0 - 1e-4))
        params[start] = tau[0]
        if stop - start > 1:
            gaps = np.maximum(np.diff(tau), 1e-3)
            params[start + 1 : stop] = inverse_softplus(gaps - 1e-4)

    return params


def _observation_slice(
    observations: IndicatorObservations,
    rows: slice,
) -> tuple[np.ndarray, np.ndarray]:
    if rows.start is None or rows.stop is None:
        raise ValueError("Observation slices must have explicit start and stop.")
    start = rows.start
    stop = rows.stop
    left = np.searchsorted(observations.individual_index, start, side="left")
    right = np.searchsorted(observations.individual_index, stop, side="left")
    return observations.individual_index[left:right] - start, observations.values[left:right]


def _domain_log_grid(
    data: PreparedData,
    params_dict: dict[str, object],
    domain: str,
    rows: slice,
    g_nodes: np.ndarray,
    s_nodes: np.ndarray,
) -> np.ndarray:
    start, stop, _ = rows.indices(data.n_individuals)
    n_rows = stop - start
    log_grid = np.zeros((n_rows, len(g_nodes), len(s_nodes)), dtype=float)
    general = params_dict["general"]
    domain_loadings = params_dict["domain"]
    thresholds = params_dict["thresholds"]
    intercepts = params_dict["intercepts"]
    sigmas = params_dict["sigmas"]

    for column in DOMAINS[domain]:
        j = item_index(column)
        mu = general[j] * g_nodes[None, :, None] + domain_loadings[j] * s_nodes[None, None, :]
        if column in data.continuous_columns:
            local_index, values = _observation_slice(data.continuous[column], rows)
            if len(values) == 0:
                continue
            mean = intercepts[column] + mu
            contribution = _continuous_log_prob(values, mean, sigmas[column])
        else:
            local_index, values = _observation_slice(data.ordinal_codes[column], rows)
            if len(values) == 0:
                continue
            contribution = _ordinal_log_prob(values.astype(int, copy=False), thresholds[column], mu)
        np.add.at(log_grid, local_index, contribution)

    return log_grid


def domain_log_likelihoods(
    data: PreparedData,
    params_dict: dict[str, object],
    g_nodes: np.ndarray,
    s_nodes: np.ndarray,
    log_s_weights: np.ndarray,
    block_size: int,
) -> Iterable[tuple[slice, dict[str, np.ndarray]]]:
    for start in range(0, data.n_individuals, block_size):
        rows = slice(start, min(start + block_size, data.n_individuals))
        block = {}
        for domain in DOMAINS:
            log_grid = _domain_log_grid(data, params_dict, domain, rows, g_nodes, s_nodes)
            block[domain] = logsumexp(log_grid + log_s_weights[None, None, :], axis=2)
        yield rows, block


def log_likelihood(
    params: np.ndarray,
    data: PreparedData,
    layout: ParameterLayout,
    quadrature_points: int,
    block_size: int = 2048,
) -> float:
    params_dict = unpack_params(params, data, layout)
    nodes, log_weights = quadrature_rule(quadrature_points)
    total = 0.0

    for _, domain_blocks in domain_log_likelihoods(
        data=data,
        params_dict=params_dict,
        g_nodes=nodes,
        s_nodes=nodes,
        log_s_weights=log_weights,
        block_size=block_size,
    ):
        outer = log_weights[None, :].copy()
        for domain_values in domain_blocks.values():
            outer = outer + domain_values
        total += float(np.sum(logsumexp(outer, axis=1)))

    return total


def negative_log_likelihood(
    params: np.ndarray,
    data: PreparedData,
    layout: ParameterLayout,
    quadrature_points: int,
    block_size: int,
) -> float:
    value = -log_likelihood(params, data, layout, quadrature_points, block_size)
    if not np.isfinite(value):
        return 1e100
    return value


def fit_bifactor(
    data: PreparedData,
    quadrature_points: int = 5,
    maxiter: int = 5,
    block_size: int = 2048,
) -> tuple[FitResult, ParameterLayout]:
    layout = make_layout(data)
    start = initial_params(data, layout)
    objective = lambda vector: negative_log_likelihood(
        vector,
        data=data,
        layout=layout,
        quadrature_points=quadrature_points,
        block_size=block_size,
    )
    result = minimize(
        objective,
        start,
        method="L-BFGS-B",
        options={
            "maxiter": maxiter,
            "disp": False,
            "maxls": 30,
        },
    )

    raw_params = np.asarray(result.x, dtype=float)
    oriented_params, orientation = orient_params(raw_params, layout)
    ll = log_likelihood(oriented_params, data, layout, quadrature_points, block_size)

    return (
        FitResult(
            params=oriented_params,
            raw_params=raw_params,
            success=bool(result.success),
            message=str(result.message),
            n_iter=int(result.nit),
            objective=float(result.fun),
            log_likelihood=float(ll),
            n_obs=data.n_individuals,
            quadrature_points=quadrature_points,
            orientation=orientation,
        ),
        layout,
    )


def factor_scores(
    data: PreparedData,
    params: np.ndarray,
    layout: ParameterLayout,
    quadrature_points: int,
    block_size: int = 2048,
) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    nodes, log_weights = quadrature_rule(quadrature_points)
    rows_out = []

    for rows, domain_blocks in domain_log_likelihoods(
        data=data,
        params_dict=params_dict,
        g_nodes=nodes,
        s_nodes=nodes,
        log_s_weights=log_weights,
        block_size=block_size,
    ):
        start, stop, _ = rows.indices(data.n_individuals)
        n_rows = stop - start

        domain_conditional_means = {}
        for domain in DOMAINS:
            log_grid = _domain_log_grid(data, params_dict, domain, rows, nodes, nodes)
            shifted = log_grid - np.max(log_grid, axis=2, keepdims=True)
            weights = np.exp(shifted) * np.exp(log_weights)[None, None, :]
            denominator = np.sum(weights, axis=2)
            numerator = np.sum(weights * nodes[None, None, :], axis=2)
            domain_conditional_means[domain] = numerator / np.maximum(denominator, 1e-300)

        outer = log_weights[None, :].copy()
        for domain_values in domain_blocks.values():
            outer = outer + domain_values
        outer_weights = np.exp(outer - logsumexp(outer, axis=1)[:, None])

        score_block = {
            "idauniq": data.individual_ids[start:stop],
            "general": outer_weights @ nodes,
        }
        for domain in DOMAINS:
            score_block[domain] = np.sum(outer_weights * domain_conditional_means[domain], axis=1)

        rows_out.append(pd.DataFrame(score_block, index=np.arange(n_rows)))

    return pd.concat(rows_out, ignore_index=True)


def observation_count_table(data: PreparedData) -> pd.DataFrame:
    rows = []
    for column in INDICATORS:
        rows.append(
            {
                "indicator": column,
                "domain": domain_for_column(column),
                "measurement": "continuous" if column in CONTINUOUS_COLUMNS else "ordinal_probit",
                "observations": data.observation_counts[column],
            }
        )
    return pd.DataFrame(rows)


def fit_summary(result: FitResult, data: PreparedData, layout: ParameterLayout) -> dict[str, object]:
    return {
        "success": result.success,
        "message": result.message,
        "iterations": result.n_iter,
        "objective": result.objective,
        "log_likelihood": result.log_likelihood,
        "n_individuals": result.n_obs,
        "n_observations": int(sum(data.observation_counts.values())),
        "observation_counts": data.observation_counts,
        "n_params": layout.n_params,
        "quadrature_points": result.quadrature_points,
        "factors": FACTOR_NAMES,
        "continuous_columns": CONTINUOUS_COLUMNS,
        "ordinal_columns": [column for column in INDICATORS if column not in CONTINUOUS_COLUMNS],
        "orientation": result.orientation,
    }

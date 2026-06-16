from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd
from numpy.polynomial.hermite import hermgauss
from scipy.optimize import minimize
from scipy.special import logsumexp, ndtr, ndtri


INDICATORS = [
    "depres",
    "effort",
    "sleep",
    "happy",
    "lonely",
    "going",
    "wspeed",
    "chr5sec",
    "balance",
    "grip",
    "fev",
    "hba",
    "imrc",
    "dlrc",
    "memory",
    "hearing",
    "nsight",
    "dsight",
]

CONTINUOUS_COLUMNS = ["wspeed", "chr5sec", "grip", "fev", "hba"]

DOMAINS = {
    "psychological": ["depres", "effort", "sleep", "happy", "lonely", "going"],
    "locomotor": ["wspeed", "chr5sec", "balance"],
    "vitality": ["grip", "fev", "hba"],
    "cognitive": ["imrc", "dlrc", "memory"],
    "sensory": ["hearing", "nsight", "dsight"],
}

FACTOR_NAMES = ["general", *DOMAINS.keys()]


@dataclass(frozen=True)
class PreparedData:
    """Arrays and metadata used by the mixed bifactor likelihood."""

    source_path: Path
    row_index: np.ndarray
    n_obs: int
    columns: list[str]
    continuous_columns: list[str]
    ordinal_columns: list[str]
    continuous: dict[str, np.ndarray]
    ordinal_codes: dict[str, np.ndarray]
    ordinal_categories: dict[str, list[float]]
    means: dict[str, float]
    stds: dict[str, float]


@dataclass(frozen=True)
class ParameterLayout:
    """Slices into the flat optimizer parameter vector."""

    n_items: int
    n_continuous: int
    ordinal_columns: list[str]
    ordinal_n_categories: dict[str, int]
    general: slice
    domain: slice
    continuous_intercepts: slice
    log_sigmas: slice
    thresholds: dict[str, tuple[int, int]]
    n_params: int


@dataclass
class FitResult:
    params: np.ndarray
    raw_params: np.ndarray
    success: bool
    message: str
    n_iter: int
    objective: float
    log_likelihood: float
    n_obs: int
    quadrature_points: int
    orientation: dict[str, float]


def prepare_data(path: str | Path) -> PreparedData:
    """Load the 18 indicator columns and prepare mixed model arrays."""

    source_path = Path(path)
    df = pd.read_csv(source_path)
    missing = [column for column in INDICATORS if column not in df.columns]
    if missing:
        raise ValueError(f"{source_path} is missing columns: {', '.join(missing)}")

    model_df = df.loc[:, INDICATORS].copy()
    before = len(model_df)
    model_df = model_df.dropna(axis=0, how="any")
    row_index = model_df.index.to_numpy()
    if len(model_df) == 0:
        raise ValueError("No complete rows remain after dropping missing indicator values.")
    if len(model_df) < before:
        print(f"Dropped {before - len(model_df)} rows with missing indicator values.")

    continuous = {}
    means = {}
    stds = {}
    for column in CONTINUOUS_COLUMNS:
        values = model_df[column].to_numpy(dtype=float)
        mean = float(np.mean(values))
        std = float(np.std(values, ddof=0))
        if std <= 0:
            raise ValueError(f"{column} has zero variance and cannot be modeled as continuous.")
        continuous[column] = (values - mean) / std
        means[column] = mean
        stds[column] = std

    ordinal_columns = [column for column in INDICATORS if column not in CONTINUOUS_COLUMNS]
    ordinal_codes = {}
    ordinal_categories = {}
    for column in ordinal_columns:
        values = model_df[column].to_numpy(dtype=float)
        categories = sorted(float(value) for value in pd.unique(values))
        if len(categories) < 2:
            raise ValueError(f"{column} has fewer than two observed categories.")
        category_to_code = {category: code for code, category in enumerate(categories)}
        ordinal_codes[column] = np.array([category_to_code[float(value)] for value in values], dtype=int)
        ordinal_categories[column] = categories

    return PreparedData(
        source_path=source_path,
        row_index=row_index,
        n_obs=len(model_df),
        columns=list(INDICATORS),
        continuous_columns=list(CONTINUOUS_COLUMNS),
        ordinal_columns=ordinal_columns,
        continuous=continuous,
        ordinal_codes=ordinal_codes,
        ordinal_categories=ordinal_categories,
        means=means,
        stds=stds,
    )


def make_layout(data: PreparedData) -> ParameterLayout:
    offset = 0
    n_items = len(INDICATORS)
    general = slice(offset, offset + n_items)
    offset += n_items
    domain = slice(offset, offset + n_items)
    offset += n_items
    continuous_intercepts = slice(offset, offset + len(CONTINUOUS_COLUMNS))
    offset += len(CONTINUOUS_COLUMNS)
    log_sigmas = slice(offset, offset + len(CONTINUOUS_COLUMNS))
    offset += len(CONTINUOUS_COLUMNS)

    thresholds = {}
    ordinal_n_categories = {}
    for column in data.ordinal_columns:
        n_categories = len(data.ordinal_categories[column])
        ordinal_n_categories[column] = n_categories
        n_threshold_params = n_categories - 1
        thresholds[column] = (offset, offset + n_threshold_params)
        offset += n_threshold_params

    return ParameterLayout(
        n_items=n_items,
        n_continuous=len(CONTINUOUS_COLUMNS),
        ordinal_columns=list(data.ordinal_columns),
        ordinal_n_categories=ordinal_n_categories,
        general=general,
        domain=domain,
        continuous_intercepts=continuous_intercepts,
        log_sigmas=log_sigmas,
        thresholds=thresholds,
        n_params=offset,
    )


def initial_params(data: PreparedData, layout: ParameterLayout) -> np.ndarray:
    params = np.zeros(layout.n_params, dtype=float)
    params[layout.general] = 0.55
    params[layout.domain] = 0.35
    params[layout.continuous_intercepts] = 0.0
    params[layout.log_sigmas] = np.log(0.75)

    for column in data.ordinal_columns:
        start, stop = layout.thresholds[column]
        codes = data.ordinal_codes[column]
        n_categories = layout.ordinal_n_categories[column]
        counts = np.bincount(codes, minlength=n_categories).astype(float)
        cumulative = np.cumsum(counts)[:-1] / np.sum(counts)
        tau = ndtri(np.clip(cumulative, 1e-4, 1.0 - 1e-4))
        params[start] = tau[0]
        if stop - start > 1:
            gaps = np.maximum(np.diff(tau), 1e-3)
            params[start + 1 : stop] = inverse_softplus(gaps - 1e-4)

    return params


def inverse_softplus(value: np.ndarray | float) -> np.ndarray | float:
    arr = np.asarray(value)
    clipped = np.maximum(arr, 1e-8)
    result = np.where(clipped > 20.0, clipped, np.log(np.expm1(clipped)))
    if np.isscalar(value):
        return float(result)
    return result


def softplus(value: np.ndarray) -> np.ndarray:
    return np.logaddexp(value, 0.0)


def quadrature_rule(points: int) -> tuple[np.ndarray, np.ndarray]:
    if points < 3:
        raise ValueError("Use at least 3 Gauss-Hermite quadrature points.")
    nodes, weights = hermgauss(points)
    normal_nodes = np.sqrt(2.0) * nodes
    log_normal_weights = np.log(weights) - 0.5 * np.log(np.pi)
    return normal_nodes.astype(float), log_normal_weights.astype(float)


def unpack_params(params: np.ndarray, data: PreparedData, layout: ParameterLayout) -> dict[str, object]:
    general = params[layout.general].copy()
    domain = params[layout.domain].copy()
    intercepts = {
        column: float(value)
        for column, value in zip(CONTINUOUS_COLUMNS, params[layout.continuous_intercepts])
    }
    sigmas = {
        column: float(np.exp(value))
        for column, value in zip(CONTINUOUS_COLUMNS, params[layout.log_sigmas])
    }

    thresholds = {}
    for column in data.ordinal_columns:
        start, stop = layout.thresholds[column]
        raw = params[start:stop]
        tau = np.empty(stop - start, dtype=float)
        tau[0] = raw[0]
        if len(tau) > 1:
            tau[1:] = tau[0] + np.cumsum(softplus(raw[1:]) + 1e-4)
        thresholds[column] = tau

    return {
        "general": general,
        "domain": domain,
        "intercepts": intercepts,
        "sigmas": sigmas,
        "thresholds": thresholds,
    }


def domain_for_column(column: str) -> str:
    for domain, columns in DOMAINS.items():
        if column in columns:
            return domain
    raise KeyError(column)


def item_index(column: str) -> int:
    return INDICATORS.index(column)


def _ordinal_log_prob(codes: np.ndarray, thresholds: np.ndarray, mu: np.ndarray) -> np.ndarray:
    lower = np.full(codes.shape, -np.inf, dtype=float)
    upper = np.full(codes.shape, np.inf, dtype=float)

    has_lower = codes > 0
    has_upper = codes < len(thresholds)
    lower[has_lower] = thresholds[codes[has_lower] - 1]
    upper[has_upper] = thresholds[codes[has_upper]]

    probability = ndtr(upper[:, None, None] - mu) - ndtr(lower[:, None, None] - mu)
    return np.log(np.clip(probability, 1e-12, 1.0))


def _continuous_log_prob(y: np.ndarray, mean: np.ndarray, sigma: float) -> np.ndarray:
    residual = y[:, None, None] - mean
    return -0.5 * (np.log(2.0 * np.pi) + 2.0 * np.log(sigma) + (residual / sigma) ** 2)


def _domain_log_grid(
    data: PreparedData,
    params_dict: dict[str, object],
    domain: str,
    rows: slice,
    g_nodes: np.ndarray,
    s_nodes: np.ndarray,
) -> np.ndarray:
    n_rows = len(range(*rows.indices(data.n_obs)))
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
            mean = intercepts[column] + mu
            log_grid += _continuous_log_prob(data.continuous[column][rows], mean, sigmas[column])
        else:
            log_grid += _ordinal_log_prob(data.ordinal_codes[column][rows], thresholds[column], mu)

    return log_grid


def domain_log_likelihoods(
    data: PreparedData,
    params_dict: dict[str, object],
    g_nodes: np.ndarray,
    s_nodes: np.ndarray,
    log_s_weights: np.ndarray,
    block_size: int,
) -> Iterable[tuple[slice, dict[str, np.ndarray]]]:
    for start in range(0, data.n_obs, block_size):
        rows = slice(start, min(start + block_size, data.n_obs))
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
    maxiter: int = 10,
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
            n_obs=data.n_obs,
            quadrature_points=quadrature_points,
            orientation=orientation,
        ),
        layout,
    )


def orient_params(params: np.ndarray, layout: ParameterLayout) -> tuple[np.ndarray, dict[str, float]]:
    oriented = params.copy()
    orientation = {factor: 1.0 for factor in FACTOR_NAMES}

    general_anchor = item_index("grip")
    if oriented[layout.general][general_anchor] < 0:
        oriented[layout.general] *= -1.0
        orientation["general"] = -1.0

    for domain, columns in DOMAINS.items():
        anchor = item_index(columns[0])
        if oriented[layout.domain][anchor] < 0:
            for column in columns:
                oriented[layout.domain.start + item_index(column)] *= -1.0
            orientation[domain] = -1.0

    return oriented, orientation


def loading_table(
    data: PreparedData,
    params: np.ndarray,
    layout: ParameterLayout,
) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    general = params_dict["general"]
    domain_loadings = params_dict["domain"]
    sigmas = params_dict["sigmas"]

    rows = []
    for column in INDICATORS:
        j = item_index(column)
        domain = domain_for_column(column)
        residual_variance = sigmas[column] ** 2 if column in CONTINUOUS_COLUMNS else 1.0
        total_latent_response_variance = general[j] ** 2 + domain_loadings[j] ** 2 + residual_variance
        scale = float(np.sqrt(total_latent_response_variance))
        rows.append(
            {
                "indicator": column,
                "domain": domain,
                "measurement": "continuous" if column in CONTINUOUS_COLUMNS else "ordinal_probit",
                "general_loading": float(general[j]),
                "domain_loading": float(domain_loadings[j]),
                "residual_sd": float(sigmas[column]) if column in CONTINUOUS_COLUMNS else 1.0,
                "std_general_loading": float(general[j] / scale),
                "std_domain_loading": float(domain_loadings[j] / scale),
            }
        )

    return pd.DataFrame(rows)


def threshold_table(data: PreparedData, params: np.ndarray, layout: ParameterLayout) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    rows = []
    for column in data.ordinal_columns:
        categories = data.ordinal_categories[column]
        thresholds = params_dict["thresholds"][column]
        for index, threshold in enumerate(thresholds):
            rows.append(
                {
                    "indicator": column,
                    "threshold_index": index + 1,
                    "lower_category": categories[index],
                    "upper_category": categories[index + 1],
                    "threshold": float(threshold),
                }
            )
    return pd.DataFrame(rows)


def continuous_parameter_table(
    data: PreparedData,
    params: np.ndarray,
    layout: ParameterLayout,
) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    rows = []
    for column in CONTINUOUS_COLUMNS:
        rows.append(
            {
                "indicator": column,
                "training_mean": data.means[column],
                "training_sd": data.stds[column],
                "standardized_intercept": params_dict["intercepts"][column],
                "standardized_residual_sd": params_dict["sigmas"][column],
            }
        )
    return pd.DataFrame(rows)


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
        start, stop, _ = rows.indices(data.n_obs)
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
            "source_row": data.row_index[start:stop],
            "general": outer_weights @ nodes,
        }
        for domain in DOMAINS:
            score_block[domain] = np.sum(outer_weights * domain_conditional_means[domain], axis=1)

        rows_out.append(pd.DataFrame(score_block, index=np.arange(n_rows)))

    return pd.concat(rows_out, ignore_index=True)


def fit_summary(result: FitResult, layout: ParameterLayout) -> dict[str, object]:
    return {
        "success": result.success,
        "message": result.message,
        "iterations": result.n_iter,
        "objective": result.objective,
        "log_likelihood": result.log_likelihood,
        "n_obs": result.n_obs,
        "n_params": layout.n_params,
        "quadrature_points": result.quadrature_points,
        "factors": FACTOR_NAMES,
        "continuous_columns": CONTINUOUS_COLUMNS,
        "ordinal_columns": [column for column in INDICATORS if column not in CONTINUOUS_COLUMNS],
        "orientation": result.orientation,
    }

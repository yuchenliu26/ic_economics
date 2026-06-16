from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

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

FACTOR_NAMES = list(DOMAINS.keys())
DOMAIN_INDEX = {domain: index for index, domain in enumerate(FACTOR_NAMES)}


@dataclass(frozen=True)
class PreparedData:
    """Arrays and metadata used by the mixed correlated-factor likelihood."""

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
    n_factors: int
    n_continuous: int
    n_corr: int
    ordinal_columns: list[str]
    ordinal_n_categories: dict[str, int]
    loadings: slice
    continuous_intercepts: slice
    log_sigmas: slice
    corr_unconstrained: slice
    thresholds: dict[str, tuple[int, int]]
    n_params: int


@dataclass
class FitResult:
    params: np.ndarray
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
    n_factors = len(FACTOR_NAMES)
    n_corr = n_factors * (n_factors - 1) // 2

    loadings = slice(offset, offset + n_items)
    offset += n_items
    continuous_intercepts = slice(offset, offset + len(CONTINUOUS_COLUMNS))
    offset += len(CONTINUOUS_COLUMNS)
    log_sigmas = slice(offset, offset + len(CONTINUOUS_COLUMNS))
    offset += len(CONTINUOUS_COLUMNS)
    corr_unconstrained = slice(offset, offset + n_corr)
    offset += n_corr

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
        n_factors=n_factors,
        n_continuous=len(CONTINUOUS_COLUMNS),
        n_corr=n_corr,
        ordinal_columns=list(data.ordinal_columns),
        ordinal_n_categories=ordinal_n_categories,
        loadings=loadings,
        continuous_intercepts=continuous_intercepts,
        log_sigmas=log_sigmas,
        corr_unconstrained=corr_unconstrained,
        thresholds=thresholds,
        n_params=offset,
    )


def initial_params(data: PreparedData, layout: ParameterLayout) -> np.ndarray:
    params = np.zeros(layout.n_params, dtype=float)
    params[layout.loadings] = 0.65
    params[layout.continuous_intercepts] = 0.0
    params[layout.log_sigmas] = np.log(0.75)
    params[layout.corr_unconstrained] = 0.35

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


def domain_for_column(column: str) -> str:
    for domain, columns in DOMAINS.items():
        if column in columns:
            return domain
    raise KeyError(column)


def item_index(column: str) -> int:
    return INDICATORS.index(column)


def correlation_from_unconstrained(values: np.ndarray, n_factors: int) -> np.ndarray:
    """Map unconstrained lower-triangular values to a valid correlation matrix."""

    lower = np.eye(n_factors, dtype=float)
    offset = 0
    for row in range(1, n_factors):
        for col in range(row):
            lower[row, col] = values[offset]
            offset += 1

    covariance = lower @ lower.T
    scale = np.sqrt(np.maximum(np.diag(covariance), 1e-12))
    correlation = covariance / np.outer(scale, scale)
    np.fill_diagonal(correlation, 1.0)
    return correlation


def unpack_params(params: np.ndarray, data: PreparedData, layout: ParameterLayout) -> dict[str, object]:
    loadings = params[layout.loadings].copy()
    intercepts = {
        column: float(value)
        for column, value in zip(CONTINUOUS_COLUMNS, params[layout.continuous_intercepts])
    }
    sigmas = {
        column: float(np.exp(value))
        for column, value in zip(CONTINUOUS_COLUMNS, params[layout.log_sigmas])
    }
    correlation = correlation_from_unconstrained(
        params[layout.corr_unconstrained],
        layout.n_factors,
    )

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
        "loadings": loadings,
        "intercepts": intercepts,
        "sigmas": sigmas,
        "correlation": correlation,
        "thresholds": thresholds,
    }


def orientation_from_loadings(loadings: np.ndarray) -> dict[str, float]:
    orientation = {factor: 1.0 for factor in FACTOR_NAMES}
    for domain, columns in DOMAINS.items():
        anchor = item_index(columns[0])
        if loadings[anchor] < 0:
            orientation[domain] = -1.0
    return orientation


def orientation_vector(orientation: dict[str, float]) -> np.ndarray:
    return np.array([orientation[factor] for factor in FACTOR_NAMES], dtype=float)


@lru_cache(maxsize=16)
def quadrature_grid(points: int, n_factors: int) -> tuple[np.ndarray, np.ndarray]:
    if points < 3:
        raise ValueError("Use at least 3 Gauss-Hermite quadrature points.")

    nodes, weights = hermgauss(points)
    normal_nodes = np.sqrt(2.0) * nodes.astype(float)
    log_normal_weights = np.log(weights.astype(float)) - 0.5 * np.log(np.pi)

    node_meshes = np.meshgrid(*([normal_nodes] * n_factors), indexing="ij")
    weight_meshes = np.meshgrid(*([log_normal_weights] * n_factors), indexing="ij")
    grid = np.stack([mesh.ravel() for mesh in node_meshes], axis=1)
    log_weights = np.sum(np.stack(weight_meshes, axis=-1), axis=-1).ravel()
    return grid, log_weights


def _safe_cholesky(matrix: np.ndarray) -> np.ndarray:
    jitter = 0.0
    for _ in range(6):
        try:
            return np.linalg.cholesky(matrix + jitter * np.eye(matrix.shape[0]))
        except np.linalg.LinAlgError:
            jitter = 1e-8 if jitter == 0.0 else jitter * 10.0
    return np.linalg.cholesky(matrix + jitter * np.eye(matrix.shape[0]))


def factor_grid(correlation: np.ndarray, points: int) -> tuple[np.ndarray, np.ndarray]:
    base_grid, log_weights = quadrature_grid(points, correlation.shape[0])
    chol = _safe_cholesky(correlation)
    return base_grid @ chol.T, log_weights


def _ordinal_log_prob(codes: np.ndarray, thresholds: np.ndarray, mu: np.ndarray) -> np.ndarray:
    lower = np.full(codes.shape, -np.inf, dtype=float)
    upper = np.full(codes.shape, np.inf, dtype=float)

    has_lower = codes > 0
    has_upper = codes < len(thresholds)
    lower[has_lower] = thresholds[codes[has_lower] - 1]
    upper[has_upper] = thresholds[codes[has_upper]]

    probability = ndtr(upper[:, None] - mu[None, :]) - ndtr(lower[:, None] - mu[None, :])
    return np.log(np.clip(probability, 1e-12, 1.0))


def _continuous_log_prob(y: np.ndarray, mean: np.ndarray, sigma: float) -> np.ndarray:
    residual = y[:, None] - mean[None, :]
    return -0.5 * (np.log(2.0 * np.pi) + 2.0 * np.log(sigma) + (residual / sigma) ** 2)


def response_log_grid(
    data: PreparedData,
    params_dict: dict[str, object],
    rows: slice,
    factors: np.ndarray,
) -> np.ndarray:
    n_rows = len(range(*rows.indices(data.n_obs)))
    log_grid = np.zeros((n_rows, len(factors)), dtype=float)
    loadings = params_dict["loadings"]
    thresholds = params_dict["thresholds"]
    intercepts = params_dict["intercepts"]
    sigmas = params_dict["sigmas"]

    for column in INDICATORS:
        j = item_index(column)
        domain = domain_for_column(column)
        factor_index = DOMAIN_INDEX[domain]
        mu = loadings[j] * factors[:, factor_index]
        if column in data.continuous_columns:
            mean = intercepts[column] + mu
            log_grid += _continuous_log_prob(data.continuous[column][rows], mean, sigmas[column])
        else:
            log_grid += _ordinal_log_prob(data.ordinal_codes[column][rows], thresholds[column], mu)

    return log_grid


def log_likelihood(
    params: np.ndarray,
    data: PreparedData,
    layout: ParameterLayout,
    quadrature_points: int,
    block_size: int = 512,
) -> float:
    params_dict = unpack_params(params, data, layout)
    factors, log_weights = factor_grid(params_dict["correlation"], quadrature_points)
    total = 0.0

    for start in range(0, data.n_obs, block_size):
        rows = slice(start, min(start + block_size, data.n_obs))
        log_grid = response_log_grid(data, params_dict, rows, factors)
        total += float(np.sum(logsumexp(log_grid + log_weights[None, :], axis=1)))

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


def fit_correlated_factor(
    data: PreparedData,
    quadrature_points: int = 3,
    maxiter: int = 1,
    block_size: int = 512,
) -> tuple[FitResult, ParameterLayout]:
    layout = make_layout(data)
    start = initial_params(data, layout)
    progress = {"eval": 0, "best_log_likelihood": -np.inf}

    def objective(vector: np.ndarray) -> float:
        progress["eval"] += 1
        ll = log_likelihood(
            vector,
            data=data,
            layout=layout,
            quadrature_points=quadrature_points,
            block_size=block_size,
        )
        if np.isfinite(ll):
            value = -ll
            progress["best_log_likelihood"] = max(progress["best_log_likelihood"], float(ll))
        else:
            value = 1e100

        print(
            "Optimization eval "
            f"{progress['eval']}: log likelihood = {ll:.6f}; "
            f"best = {progress['best_log_likelihood']:.6f}",
            flush=True,
        )
        return value

    if maxiter == 0:
        raw_params = start
        objective_value = float(objective(raw_params))
        success = True
        message = "Optimizer skipped because maxiter=0."
        n_iter = 0
    else:
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
        objective_value = float(result.fun)
        success = bool(result.success)
        message = str(result.message)
        n_iter = int(result.nit)

    params_dict = unpack_params(raw_params, data, layout)
    orientation = orientation_from_loadings(params_dict["loadings"])
    ll = log_likelihood(raw_params, data, layout, quadrature_points, block_size)

    return (
        FitResult(
            params=raw_params,
            success=success,
            message=message,
            n_iter=n_iter,
            objective=objective_value,
            log_likelihood=float(ll),
            n_obs=data.n_obs,
            quadrature_points=quadrature_points,
            orientation=orientation,
        ),
        layout,
    )


def loading_table(data: PreparedData, params: np.ndarray, layout: ParameterLayout) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    loadings = params_dict["loadings"]
    sigmas = params_dict["sigmas"]
    orientation = orientation_from_loadings(loadings)

    rows = []
    for column in INDICATORS:
        j = item_index(column)
        domain = domain_for_column(column)
        oriented_loading = orientation[domain] * float(loadings[j])
        residual_variance = sigmas[column] ** 2 if column in CONTINUOUS_COLUMNS else 1.0
        total_latent_response_variance = oriented_loading**2 + residual_variance
        scale = float(np.sqrt(total_latent_response_variance))
        rows.append(
            {
                "indicator": column,
                "domain": domain,
                "measurement": "continuous" if column in CONTINUOUS_COLUMNS else "ordinal_probit",
                "loading": oriented_loading,
                "residual_sd": float(sigmas[column]) if column in CONTINUOUS_COLUMNS else 1.0,
                "std_loading": float(oriented_loading / scale),
            }
        )

    return pd.DataFrame(rows)


def correlation_table(params: np.ndarray, data: PreparedData, layout: ParameterLayout) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    orientation = orientation_from_loadings(params_dict["loadings"])
    signs = orientation_vector(orientation)
    correlation = params_dict["correlation"] * np.outer(signs, signs)

    rows = []
    for i, factor_i in enumerate(FACTOR_NAMES):
        for j, factor_j in enumerate(FACTOR_NAMES):
            rows.append(
                {
                    "factor_1": factor_i,
                    "factor_2": factor_j,
                    "correlation": float(correlation[i, j]),
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
    block_size: int = 512,
) -> pd.DataFrame:
    params_dict = unpack_params(params, data, layout)
    factors, log_weights = factor_grid(params_dict["correlation"], quadrature_points)
    orientation = orientation_from_loadings(params_dict["loadings"])
    signs = orientation_vector(orientation)
    rows_out = []

    for start in range(0, data.n_obs, block_size):
        rows = slice(start, min(start + block_size, data.n_obs))
        log_grid = response_log_grid(data, params_dict, rows, factors)
        log_posterior = log_grid + log_weights[None, :]
        posterior_weights = np.exp(log_posterior - logsumexp(log_posterior, axis=1)[:, None])
        score_values = posterior_weights @ factors
        score_values = score_values * signs[None, :]

        start_index, stop_index, _ = rows.indices(data.n_obs)
        score_block = {"source_row": data.row_index[start_index:stop_index]}
        for index, factor in enumerate(FACTOR_NAMES):
            score_block[factor] = score_values[:, index]
        rows_out.append(pd.DataFrame(score_block))

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

# Full-information mixed bifactor model

This directory fits the same five-domain intrinsic-capacity bifactor structure
as `bifactor_model/`, but reads the 18 separate files in
`data/individual_data/`. Rows are aligned by `(idauniq, wave)`, not by file row
number. The same `idauniq` in two waves is treated as two distinct person-wave
measurement occasions.

Run from the repo root with the project venv:

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor
```

Useful quicker check:

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor --sample-size 500 --maxiter 2 --skip-scores
```

Outputs are written to a fresh `outputs/full_bifactor_runs/run_YYYYMMDD_HHMMSS/`
directory by default:

- `weights.csv`: general and domain-specific factor weights/loadings
- `factor_loadings.csv`: the same loadings using loading-oriented column names
- `ordinal_thresholds.csv`: thresholds for ordered-probit indicators
- `continuous_parameters.csv`: standardization and residual parameters
- `observation_counts.csv`: observations used from each indicator file
- `factor_scores.csv`: posterior mean scores by `idauniq` and `wave`, unless `--skip-scores`
- `likelihood_trace.csv`: objective evaluations and per-iteration likelihoods
- `figure1_full_bifactor_loadings.svg`: loading summary figure
- `fit_summary.json`: optimizer, sample, and model metadata

## Measurement model

For each person-wave unit `u = (idauniq, wave)`, the model has one general
factor and five independent domain factors:

```text
G_u ~ N(0, 1)
S_ud ~ N(0, 1), d in {psychological, locomotor, vitality, cognitive, sensory}
```

Let indicator `j` belong to domain `d(j)`. Each observed row `r` for person-wave
unit `u` and indicator `j` has linear predictor:

```text
eta_ujr = lambda_jG G_u + lambda_jd S_u,d(j)
```

The five continuous indicators are:

```text
wspeed, chr5sec, grip, fev, hba
```

They are standardized across all observed rows for that indicator and modeled as:

```text
Y_ujr | G_u, S_u,d(j) ~ N(alpha_j + eta_ujr, sigma_j^2)
```

All other indicators are ordered discrete variables. They use an ordered-probit
latent response with residual variance fixed to 1:

```text
Y*_ujr = eta_ujr + e_ujr,  e_ujr ~ N(0, 1)
P(Y_ujr = k | G_u, S_u,d(j))
  = Phi(tau_jk - eta_ujr) - Phi(tau_j,k-1 - eta_ujr)
```

The thresholds are constrained to be increasing by estimating the first
threshold freely and each subsequent positive gap through a softplus transform.

## Likelihood

For person-wave unit `u`, let `R_uj` be the set of rows observed for indicator
`j`. The full-information likelihood contribution is:

```text
L_u =
  integral phi(g)
    product_d [
      integral phi(s_d)
        product_{j in d} product_{r in R_uj}
          p(y_ujr | g, s_d)
      ds_d
    ]
  dg
```

The log likelihood sums `log L_u` over unique `(idauniq, wave)` values. The
integrals are approximated with Gauss-Hermite quadrature.

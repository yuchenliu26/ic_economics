# Full-information mixed bifactor model

This directory fits the same five-domain intrinsic-capacity bifactor structure
as `bifactor_model/`, but reads the 18 separate files in
`data/individual_data/`. Rows are aligned by `idauniq`, not by file row number.
If an `idauniq` appears multiple times for the same indicator, all of those
responses are treated as repeated observations from the same individual.

Run from the repo root with the project venv:

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor
```

Useful quicker check:

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor --sample-size 500 --maxiter 2 --skip-scores
```

Outputs are written to `outputs/full_bifactor/` by default:

- `weights.csv`: general and domain-specific factor weights/loadings
- `factor_loadings.csv`: the same loadings using loading-oriented column names
- `ordinal_thresholds.csv`: thresholds for ordered-probit indicators
- `continuous_parameters.csv`: standardization and residual parameters
- `observation_counts.csv`: observations used from each indicator file
- `factor_scores.csv`: posterior mean scores by `idauniq`, unless `--skip-scores`
- `figure1_full_bifactor_loadings.svg`: loading summary figure
- `fit_summary.json`: optimizer, sample, and model metadata

## Measurement model

For each individual `i`, the model has one general factor and five independent
domain factors:

```text
G_i ~ N(0, 1)
S_id ~ N(0, 1), d in {psychological, locomotor, vitality, cognitive, sensory}
```

Let indicator `j` belong to domain `d(j)`. Each observed row `r` for person `i`
and indicator `j` has linear predictor:

```text
eta_ijr = lambda_jG G_i + lambda_jd S_i,d(j)
```

The five continuous indicators are:

```text
wspeed, chr5sec, grip, fev, hba
```

They are standardized across all observed rows for that indicator and modeled as:

```text
Y_ijr | G_i, S_i,d(j) ~ N(alpha_j + eta_ijr, sigma_j^2)
```

All other indicators are ordered discrete variables. They use an ordered-probit
latent response with residual variance fixed to 1:

```text
Y*_ijr = eta_ijr + e_ijr,  e_ijr ~ N(0, 1)
P(Y_ijr = k | G_i, S_i,d(j))
  = Phi(tau_jk - eta_ijr) - Phi(tau_j,k-1 - eta_ijr)
```

The thresholds are constrained to be increasing by estimating the first
threshold freely and each subsequent positive gap through a softplus transform.

## Likelihood

For individual `i`, let `R_ij` be the set of rows observed for indicator `j`.
The full-information likelihood contribution is:

```text
L_i =
  integral phi(g)
    product_d [
      integral phi(s_d)
        product_{j in d} product_{r in R_ij}
          p(y_ijr | g, s_d)
      ds_d
    ]
  dg
```

The log likelihood sums `log L_i` over unique `idauniq` values. The integrals are
approximated with Gauss-Hermite quadrature.

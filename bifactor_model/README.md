# Vanilla mixed bifactor model

This directory implements a first-pass bifactor workflow for the 18 filtered
intrinsic-capacity indicators in `data/filtered_data/filtered.csv`.

Run from the repo root:

```bash
venv/bin/python -m bifactor_model.fit_bifactor
```

Useful quicker check:

```bash
venv/bin/python -m bifactor_model.fit_bifactor --sample-size 500 --maxiter 2 --skip-scores
```

For a pure plumbing check, `--maxiter 0` writes initial-parameter outputs. For
substantive estimates, increase `--maxiter` and use the full data. The CLI
defaults use 5-point quadrature and 10 optimizer iterations so the first full
run is practical; for a more stable final fit, raise both settings.

Outputs are written to `bifactor_model/outputs/`:

- `factor_loadings.csv`: raw and standardized general/domain loadings
- `ordinal_thresholds.csv`: thresholds for the ordinal probit indicators
- `continuous_parameters.csv`: standardization and residual parameters for continuous indicators
- `factor_scores.csv`: posterior mean scores for the general and five domain factors
- `figure1_bifactor_loadings.svg`: a Figure-1-style loading summary
- `fit_summary.json`: optimizer and model metadata

## Measurement choices

The five continuous variables are:

```text
wspeed, chr5sec, grip, fev, hba
```

All other indicators are modeled as ordered discrete variables:

```text
depres, effort, sleep, happy, lonely, going, balance,
imrc, dlrc, memory, hearing, nsight, dsight
```

The factors are:

```text
general intrinsic capacity
psychological: depres, effort, sleep, happy, lonely, going
locomotor: wspeed, chr5sec, balance
vitality: grip, fev, hba
cognitive: imrc, dlrc, memory
sensory: hearing, nsight, dsight
```

This is intentionally a vanilla model. It does not replicate the authors'
Mplus/WLSMV setup, survey weights, sex-specific models, partial-information
settings, or residual covariance terms.

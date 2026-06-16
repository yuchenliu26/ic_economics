# Vanilla mixed correlated-factor model

This directory implements a first-pass correlated-factor workflow for the 18
filtered intrinsic-capacity indicators in `data/filtered_data/filtered.csv`.

Run from this directory:

```bash
../venv/bin/python fit_correlated_factor.py
```

Useful quicker check:

```bash
../venv/bin/python fit_correlated_factor.py --sample-size 500 --maxiter 1 --skip-scores
```

For a pure plumbing check, `--maxiter 0` writes initial-parameter outputs. The
default uses 3 Gauss-Hermite points per factor dimension, giving a 3^5 grid,
and one optimizer iteration.
Raise `--quadrature-points` and `--maxiter` for more substantive estimates.

Outputs are written to `outputs/correlated_factor/` by default:

- `factor_loadings.csv`: raw and standardized domain loadings
- `factor_correlations.csv`: estimated latent domain correlation matrix in long form
- `ordinal_thresholds.csv`: thresholds for the ordinal probit indicators
- `continuous_parameters.csv`: standardization and residual parameters for continuous indicators
- `factor_scores.csv`: posterior mean scores for the five domain factors
- `figure1_correlated_loadings.svg`: a Figure-1-style loading summary
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

The five correlated factors are:

```text
psychological: depres, effort, sleep, happy, lonely, going
locomotor: wspeed, chr5sec, balance
vitality: grip, fev, hba
cognitive: imrc, dlrc, memory
sensory: hearing, nsight, dsight
```

This is intentionally a vanilla model. It does not replicate the authors'
Mplus/WLSMV setup, survey weights, partial-information settings, or binary
recoding of balance.

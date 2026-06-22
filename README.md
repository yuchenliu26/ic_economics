# ic_economics

This repository contains a Python data-processing and measurement-modeling
workflow for the ELSA intrinsic-capacity indicators. It prepares the raw long
indicator data, creates both complete-case and per-indicator analysis inputs,
and fits three mixed continuous/ordinal latent-factor models.

## Repository Layout

- `data/raw_data/`: raw ELSA intrinsic-capacity data and `.dta` to `.csv`
  conversion helper.
- `data/filtered_data/`: complete-case filtered data used by the vanilla
  bifactor and correlated-factor models.
- `data/individual_data/`: one CSV per indicator, used by the full-information
  bifactor model so partially observed rows can contribute information.
- `bifactor_model/`: complete-case mixed bifactor model.
- `full_bifactor_model/`: full-information mixed bifactor model using all
  available indicator observations.
- `correlated_factor_model/`: complete-case mixed correlated-factor model.
- `outputs/`: generated model outputs, summaries, scores, and loading figures.
- `ELSA CHARLS IC Cohort difference shared code/`: reference Stata and Mplus
  code from the source analysis workflow.

## Setup

From the repository root:

```bash
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

The scripts below assume commands are run from the repository root unless noted.

## Data Pipeline

The modeling workflow starts from `data/raw_data/elsa_ic_indicators_long.dta`
or the already converted `data/raw_data/elsa_ic_indicators_long.csv`.

1. Convert the Stata file to CSV:

   ```bash
   venv/bin/python data/raw_data/conversion.py
   ```

   The converter first tries pandas, then pyreadstat, then a local Stata
   executable if available.

2. Build the complete-case file:

   ```bash
   venv/bin/python data/filtered_data/filter.py
   ```

   This writes `data/filtered_data/filtered.csv`. It keeps rows with numeric
   values for all 18 intrinsic-capacity indicators, preserving selected metadata
   columns. With the current checked-in raw CSV, this keeps 9,428 of 63,100 rows.

3. Build the per-indicator files for partial-information modeling:

   ```bash
   venv/bin/python data/individual_data/conversion.py
   ```

   This writes one file per indicator in `data/individual_data/`, each with
   `idauniq` and the non-missing response for that indicator. These files allow
   the full bifactor model to use individuals who are missing some of the 18
   indicators.

Both data-preparation scripts treat blank values, `nan`, Stata-style extended
missing codes such as `.p`, and nonnumeric responses as missing. Numeric prefixes
are extracted from values before writing model inputs.

## Indicators and Domains

The 18 intrinsic-capacity indicators are grouped into five domains:

| Domain | Indicators |
| --- | --- |
| Psychological | `depres`, `effort`, `sleep`, `happy`, `lonely`, `going` |
| Locomotor | `wspeed`, `chr5sec`, `balance` |
| Vitality | `grip`, `fev`, `hba` |
| Cognitive | `imrc`, `dlrc`, `memory` |
| Sensory | `hearing`, `nsight`, `dsight` |

The continuous indicators are `wspeed`, `chr5sec`, `grip`, `fev`, and `hba`.
All other indicators are modeled as ordered discrete variables with ordered
probit thresholds.

## Models

### Complete-Case Bifactor Model

`bifactor_model/` fits a mixed continuous/ordinal bifactor model to
`data/filtered_data/filtered.csv`. Because that input is complete-case, only
rows with complete answers to all 18 indicators are used.

The model has one general intrinsic-capacity factor plus five independent
domain-specific factors.

```bash
venv/bin/python -m bifactor_model.fit_bifactor
```

Useful smoke test:

```bash
venv/bin/python -m bifactor_model.fit_bifactor --sample-size 500 --maxiter 2 --skip-scores
```

Default outputs are written to `outputs/bifactor1/`.

### Full-Information Bifactor Model

`full_bifactor_model/` fits the same general-plus-domain bifactor structure, but
it reads the 18 separate files in `data/individual_data/` and aligns responses
by `idauniq`. This implementation uses all available non-missing indicator
observations, so individuals can contribute data even when they are missing a
few of the 18 indicators.

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor
```

Useful smoke test:

```bash
venv/bin/python -m full_bifactor_model.fit_full_bifactor --sample-size 500 --maxiter 2 --skip-scores
```

Default outputs are written to `outputs/full_bifactor/`.

### Correlated-Factor Model

`correlated_factor_model/` fits a five-factor model to
`data/filtered_data/filtered.csv`. It does not include a general factor; instead,
the five domain factors are estimated as correlated latent factors.

Run from the model directory:

```bash
cd correlated_factor_model
../venv/bin/python fit_correlated_factor.py
```

Useful smoke test:

```bash
cd correlated_factor_model
../venv/bin/python fit_correlated_factor.py --sample-size 500 --maxiter 1 --skip-scores
```

Default outputs are written to `outputs/correlated_factor_5_iter/`.

## Outputs

The model scripts write CSV tables, SVG loading figures, and JSON fit summaries.
Common outputs include:

- `factor_loadings.csv`: raw and standardized factor loadings.
- `ordinal_thresholds.csv`: ordered-probit thresholds for ordinal indicators.
- `continuous_parameters.csv`: means, standard deviations, intercepts, and
  residual parameters for continuous indicators.
- `factor_scores.csv`: posterior mean factor scores, unless `--skip-scores` is
  passed.
- `fit_summary.json`: optimizer status, log likelihood, model dimensions, and
  run metadata.

Model-specific outputs include:

- `outputs/full_bifactor/weights.csv`: loading table with weight-oriented column
  names for the full bifactor model.
- `outputs/full_bifactor/observation_counts.csv`: number of observations used
  from each per-indicator file.
- `outputs/correlated_factor_5_iter/factor_correlations.csv`: estimated latent
  factor correlation matrix in long form.

Use `--output-dir` on any model script to write results somewhere else.

## Practical Notes

The default optimizer and quadrature settings are chosen to make full runs
practical in this repository. They are useful for plumbing checks and first-pass
fits, but final substantive estimates should use larger `--maxiter` values and,
where computationally feasible, more quadrature points.

For a pure pipeline check, the complete-case bifactor and correlated-factor
scripts support `--maxiter 0`, which writes initial-parameter outputs without
running optimizer iterations.

The Python implementations are intentionally vanilla mixed continuous/ordinal
models. They do not fully reproduce the original Mplus/WLSMV setup, survey
weights, sex-specific models, or every residual-covariance choice from the
reference analysis code.

from __future__ import annotations

import argparse
import json
from html import escape
from pathlib import Path

import pandas as pd

from model import (
    CONTINUOUS_COLUMNS,
    DOMAINS,
    INDICATORS,
    continuous_parameter_table,
    correlation_table,
    factor_scores,
    fit_correlated_factor,
    fit_summary,
    loading_table,
    prepare_data,
    threshold_table,
)


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Fit a vanilla mixed continuous/ordinal correlated-factor model to the 18 IC indicators."
    )
    parser.add_argument(
        "--data",
        type=Path,
        default=repo_root / "data" / "filtered_data" / "filtered.csv",
        help="CSV containing the 18 filtered IC indicator columns.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=repo_root / "outputs" / "correlated_factor_5_iter",
        help="Directory for model outputs.",
    )
    parser.add_argument(
        "--quadrature-points",
        type=int,
        default=3,
        help="Gauss-Hermite points per latent dimension. The grid has points^5 nodes.",
    )
    parser.add_argument(
        "--maxiter",
        type=int,
        default=1,
        help="Maximum L-BFGS-B optimizer iterations. Use 0 to export initial-parameter outputs.",
    )
    parser.add_argument(
        "--block-size",
        type=int,
        default=512,
        help="Observation block size used inside likelihood and score calculations.",
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=None,
        help="Optional row count for quick smoke tests or prototyping.",
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=2025,
        help="Random seed used only when --sample-size is supplied.",
    )
    parser.add_argument(
        "--skip-scores",
        action="store_true",
        help="Skip posterior mean factor score export.",
    )
    return parser.parse_args()


def maybe_sample_data(input_path: Path, output_dir: Path, sample_size: int | None, seed: int) -> Path:
    if sample_size is None:
        return input_path

    df = pd.read_csv(input_path)
    if sample_size >= len(df):
        return input_path

    sampled = df.sample(n=sample_size, random_state=seed).sort_index()
    sampled_path = output_dir / f"sample_{sample_size}_{input_path.name}"
    sampled.to_csv(sampled_path, index=False)
    return sampled_path


def write_outputs(args: argparse.Namespace) -> None:
    args.output_dir.mkdir(parents=True, exist_ok=True)
    data_path = maybe_sample_data(args.data, args.output_dir, args.sample_size, args.seed)
    data = prepare_data(data_path)
    result, layout = fit_correlated_factor(
        data=data,
        quadrature_points=args.quadrature_points,
        maxiter=args.maxiter,
        block_size=args.block_size,
    )

    summary = fit_summary(result, layout)
    summary["data"] = str(data_path)
    summary_path = args.output_dir / "fit_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n")

    loadings = loading_table(data, result.params, layout)
    loadings_path = args.output_dir / "factor_loadings.csv"
    loadings.to_csv(loadings_path, index=False)

    correlations = correlation_table(result.params, data, layout)
    correlations_path = args.output_dir / "factor_correlations.csv"
    correlations.to_csv(correlations_path, index=False)

    thresholds = threshold_table(data, result.params, layout)
    thresholds.to_csv(args.output_dir / "ordinal_thresholds.csv", index=False)

    continuous_parameters = continuous_parameter_table(data, result.params, layout)
    continuous_parameters.to_csv(args.output_dir / "continuous_parameters.csv", index=False)

    if not args.skip_scores:
        scores = factor_scores(
            data=data,
            params=result.params,
            layout=layout,
            quadrature_points=args.quadrature_points,
            block_size=args.block_size,
        )
        scores.to_csv(args.output_dir / "factor_scores.csv", index=False)

    write_loading_svg(loadings, args.output_dir / "figure1_correlated_loadings.svg")

    print(f"Wrote {summary_path}")
    print(f"Wrote {loadings_path}")
    print(f"Wrote {correlations_path}")
    print(f"Wrote {args.output_dir / 'figure1_correlated_loadings.svg'}")
    print(f"Optimizer success: {result.success} ({result.message})")
    print(f"Log likelihood: {result.log_likelihood:.3f}")


def write_loading_svg(loadings: pd.DataFrame, path: Path) -> None:
    row_height = 34
    top = 88
    bottom = 44
    width = 860
    height = top + bottom + row_height * len(loadings)
    label_x = 44
    domain_x = 220
    axis_x = 570
    bar_width = 170
    max_loading = max(0.1, float(loadings["std_loading"].abs().max()))
    scale = bar_width / max_loading
    colors = {
        "psychological": "#4575b4",
        "locomotor": "#1b9e77",
        "vitality": "#d95f02",
        "cognitive": "#756bb1",
        "sensory": "#6b6b6b",
    }

    def bar(y: int, value: float, color: str) -> str:
        length = abs(value) * scale
        x = axis_x if value >= 0 else axis_x - length
        return (
            f'<rect x="{x:.1f}" y="{y - 7}" width="{length:.1f}" height="14" '
            f'rx="2" fill="{color}" opacity="0.82" />'
        )

    parts = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
        "<style>",
        "text{font-family:Arial,Helvetica,sans-serif;fill:#202124}",
        ".title{font-size:22px;font-weight:700}",
        ".subtitle{font-size:13px;fill:#5f6368}",
        ".header{font-size:12px;font-weight:700;letter-spacing:.04em;fill:#3c4043}",
        ".row{font-size:13px}",
        ".small{font-size:11px;fill:#5f6368}",
        ".value{font-size:11px;fill:#202124}",
        "</style>",
        f'<text class="title" x="{label_x}" y="34">Correlated-factor domain loadings</text>',
        (
            f'<text class="subtitle" x="{label_x}" y="56">'
            "Standardized loadings from a mixed continuous/ordinal probit correlated-factor model"
            "</text>"
        ),
        f'<text class="header" x="{label_x}" y="78">INDICATOR</text>',
        f'<text class="header" x="{domain_x}" y="78">DOMAIN</text>',
        f'<text class="header" x="{axis_x - 112}" y="78">DOMAIN FACTOR LOADING</text>',
        f'<line x1="{axis_x}" y1="{top - 18}" x2="{axis_x}" y2="{height - bottom + 10}" stroke="#d5d8dc" />',
    ]

    for i, row in enumerate(loadings.itertuples(index=False)):
        y = top + i * row_height
        if i % 2 == 0:
            parts.append(f'<rect x="32" y="{y - 18}" width="{width - 64}" height="{row_height}" fill="#f8f9fa" />')
        color = colors[row.domain]
        parts.extend(
            [
                f'<text class="row" x="{label_x}" y="{y + 5}">{escape(row.indicator)}</text>',
                f'<text class="small" x="{domain_x}" y="{y + 5}">{escape(row.domain)}</text>',
                bar(y, row.std_loading, color),
                f'<text class="value" x="{axis_x + bar_width + 14}" y="{y + 4}">{row.std_loading:+.3f}</text>',
            ]
        )

    continuous_note = ", ".join(CONTINUOUS_COLUMNS)
    ordinal_note = ", ".join(column for column in INDICATORS if column not in CONTINUOUS_COLUMNS)
    parts.extend(
        [
            (
                f'<text class="small" x="{label_x}" y="{height - 18}">'
                f"Continuous: {escape(continuous_note)}. Ordinal probit: {escape(ordinal_note)}."
                "</text>"
            ),
            "</svg>",
        ]
    )

    path.write_text("\n".join(parts) + "\n")


def main() -> None:
    args = parse_args()
    write_outputs(args)


if __name__ == "__main__":
    main()

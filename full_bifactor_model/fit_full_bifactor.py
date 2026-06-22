from __future__ import annotations

import argparse
import json
from datetime import datetime
from html import escape
from pathlib import Path

import pandas as pd

try:
    from .model import (
        CONTINUOUS_COLUMNS,
        DOMAINS,
        INDICATORS,
        continuous_parameter_table,
        factor_scores,
        fit_bifactor,
        fit_summary,
        loading_table,
        observation_count_table,
        prepare_data,
        sample_individuals,
        threshold_table,
    )
except ImportError:
    from model import (
        CONTINUOUS_COLUMNS,
        DOMAINS,
        INDICATORS,
        continuous_parameter_table,
        factor_scores,
        fit_bifactor,
        fit_summary,
        loading_table,
        observation_count_table,
        prepare_data,
        sample_individuals,
        threshold_table,
    )


def parse_args() -> argparse.Namespace:
    repo_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description=(
            "Fit a full-information mixed continuous/ordinal bifactor model "
            "from 18 per-indicator CSV files."
        )
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=repo_root / "data" / "individual_data",
        help="Directory containing one idauniq+indicator CSV per IC indicator.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Directory for model outputs. If omitted, a fresh run directory is created.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=repo_root / "outputs" / "full_bifactor_hba",
        help="Parent directory used when --output-dir is omitted.",
    )
    parser.add_argument(
        "--quadrature-points",
        type=int,
        default=5,
        help="Gauss-Hermite points per one-dimensional latent integral.",
    )
    parser.add_argument(
        "--maxiter",
        type=int,
        default=5,
        help="Maximum L-BFGS-B optimizer iterations.",
    )
    parser.add_argument(
        "--block-size",
        type=int,
        default=2048,
        help="Individual block size used inside likelihood calculations.",
    )
    parser.add_argument(
        "--sample-size",
        type=int,
        default=None,
        help="Optional individual count for quick smoke tests or prototyping.",
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
    parser.add_argument(
        "--log-every",
        type=int,
        default=25,
        help="Print every N objective evaluations while also writing likelihood_trace.csv.",
    )
    return parser.parse_args()


def fresh_output_dir(args: argparse.Namespace) -> Path:
    if args.output_dir is not None:
        return args.output_dir

    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    candidate = args.output_root / f"run_{stamp}"
    suffix = 1
    while candidate.exists():
        candidate = args.output_root / f"run_{stamp}_{suffix:02d}"
        suffix += 1
    return candidate


def write_outputs(args: argparse.Namespace) -> None:
    args.output_dir = fresh_output_dir(args)
    args.output_dir.mkdir(parents=True, exist_ok=False)

    data = prepare_data(args.data_dir)
    full_n_person_waves = data.n_individuals
    full_n_observations = sum(data.observation_counts.values())
    if args.sample_size is not None:
        data = sample_individuals(data, args.sample_size, args.seed)

    likelihood_log_path = args.output_dir / "likelihood_trace.csv"
    result, layout = fit_bifactor(
        data=data,
        quadrature_points=args.quadrature_points,
        maxiter=args.maxiter,
        block_size=args.block_size,
        likelihood_log_path=likelihood_log_path,
        log_every=args.log_every,
    )

    summary = fit_summary(result, data, layout)
    summary["data_dir"] = str(args.data_dir)
    summary["full_n_person_waves"] = full_n_person_waves
    summary["full_n_observations"] = int(full_n_observations)
    summary["sample_size"] = args.sample_size
    summary["likelihood_trace"] = str(likelihood_log_path)
    summary_path = args.output_dir / "fit_summary.json"
    summary_path.write_text(json.dumps(summary, indent=2) + "\n")

    counts = observation_count_table(data)
    counts.to_csv(args.output_dir / "observation_counts.csv", index=False)

    loadings = loading_table(data, result.params, layout)
    loadings_path = args.output_dir / "factor_loadings.csv"
    loadings.to_csv(loadings_path, index=False)

    weights = loadings.rename(
        columns={
            "general_loading": "general_weight",
            "domain_loading": "domain_weight",
            "std_general_loading": "std_general_weight",
            "std_domain_loading": "std_domain_weight",
        }
    )
    weights_path = args.output_dir / "weights.csv"
    weights.to_csv(weights_path, index=False)

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

    write_loading_svg(loadings, args.output_dir / "figure1_full_bifactor_loadings.svg")

    print(f"Wrote {summary_path}")
    print(f"Wrote {loadings_path}")
    print(f"Wrote {weights_path}")
    print(f"Wrote {likelihood_log_path}")
    print(f"Optimizer success: {result.success} ({result.message})")
    print(f"Log likelihood: {result.log_likelihood:.3f}")


def write_loading_svg(loadings: pd.DataFrame, path: Path) -> None:
    row_height = 34
    top = 88
    bottom = 44
    width = 1160
    height = top + bottom + row_height * len(loadings)
    label_x = 44
    domain_x = 210
    group_axis_x = 610
    general_axis_x = 910
    bar_width = 160
    max_loading = max(
        0.1,
        float(loadings["std_domain_loading"].abs().max()),
        float(loadings["std_general_loading"].abs().max()),
    )
    scale = bar_width / max_loading
    colors = {
        "psychological": "#4575b4",
        "locomotor": "#1b9e77",
        "vitality": "#d95f02",
        "cognitive": "#756bb1",
        "sensory": "#6b6b6b",
    }

    def bar(axis_x: int, y: int, value: float, color: str) -> str:
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
        f'<text class="title" x="{label_x}" y="34">Full-information bifactor loadings for intrinsic capacity</text>',
        (
            f'<text class="subtitle" x="{label_x}" y="56">'
            "Standardized loadings from per-individual repeated indicator files"
            "</text>"
        ),
        f'<text class="header" x="{label_x}" y="78">INDICATOR</text>',
        f'<text class="header" x="{domain_x}" y="78">DOMAIN</text>',
        f'<text class="header" x="{group_axis_x - 105}" y="78">DOMAIN-SPECIFIC FACTOR</text>',
        f'<text class="header" x="{general_axis_x - 70}" y="78">GENERAL IC FACTOR</text>',
        f'<line x1="{group_axis_x}" y1="{top - 18}" x2="{group_axis_x}" y2="{height - bottom + 10}" stroke="#d5d8dc" />',
        f'<line x1="{general_axis_x}" y1="{top - 18}" x2="{general_axis_x}" y2="{height - bottom + 10}" stroke="#d5d8dc" />',
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
                bar(group_axis_x, y, row.std_domain_loading, color),
                bar(general_axis_x, y, row.std_general_loading, "#111827"),
                (
                    f'<text class="value" x="{group_axis_x + bar_width + 14}" y="{y + 4}">'
                    f'{row.std_domain_loading:+.3f}</text>'
                ),
                (
                    f'<text class="value" x="{general_axis_x + bar_width + 14}" y="{y + 4}">'
                    f'{row.std_general_loading:+.3f}</text>'
                ),
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

from pathlib import Path
import shutil
import subprocess
import tempfile


DATA_DIR = Path(__file__).resolve().parent
INPUT_FILE = DATA_DIR / "elsa_ic_indicators_long_v4.dta"
OUTPUT_FILE = INPUT_FILE.with_suffix(".csv")
STATA_APP = Path("/Applications/Stata/StataSE.app/Contents/MacOS/stata-se")


def convert_with_pandas(input_file: Path, output_file: Path) -> bool:
    try:
        import pandas as pd
    except ModuleNotFoundError:
        return False

    data = pd.read_stata(input_file)
    data.to_csv(output_file, index=False)
    return True


def convert_with_pyreadstat(input_file: Path, output_file: Path) -> bool:
    try:
        import pyreadstat
    except ModuleNotFoundError:
        return False

    data, _metadata = pyreadstat.read_dta(input_file)
    data.to_csv(output_file, index=False)
    return True


def find_stata() -> str | None:
    for name in ("stata-mp", "stata-se", "stata"):
        stata = shutil.which(name)
        if stata:
            return stata

    if STATA_APP.exists():
        return str(STATA_APP)

    return None


def convert_with_stata(input_file: Path, output_file: Path) -> bool:
    stata = find_stata()
    if stata is None:
        return False

    with tempfile.TemporaryDirectory() as temp_dir:
        do_file = Path(temp_dir) / "convert_dta_to_csv.do"
        do_file.write_text(
            "\n".join(
                [
                    "clear all",
                    "set more off",
                    f'use "{input_file}", clear',
                    f'export delimited using "{output_file}", replace',
                    "exit, clear",
                    "",
                ]
            )
        )

        subprocess.run(
            [stata, "-q", "-b", "do", str(do_file)],
            cwd=temp_dir,
            check=True,
        )

    return True


def convert_dta_to_csv(input_file: Path = INPUT_FILE, output_file: Path = OUTPUT_FILE) -> None:
    """Convert a Stata .dta file to CSV next to this script."""
    if not input_file.exists():
        raise FileNotFoundError(f"Could not find Stata file: {input_file}")

    for converter in (convert_with_pandas, convert_with_pyreadstat, convert_with_stata):
        if converter(input_file, output_file):
            return

    raise RuntimeError(
        "Could not convert the Stata file. Install pandas or pyreadstat, "
        "or make Stata available on PATH."
    )


if __name__ == "__main__":
    convert_dta_to_csv()
    print(f"Wrote {OUTPUT_FILE}")

import csv
import re
from pathlib import Path


NUMERIC_COLUMNS = [
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

FILTERED_DIR = Path(__file__).resolve().parent
RAW_DATA_DIR = FILTERED_DIR.parent / "raw_data"


def numeric_prefix(value):
    if value is None:
        return None

    text = str(value).strip()
    if not text or text.lower() == "nan":
        return None

    # Treat Stata extended missing/non-response codes like .p:proxy as missing.
    if re.match(r"^\.[a-z]", text, flags=re.IGNORECASE):
        return None

    match = re.match(r"^[+-]?(?:\d+(?:\.\d+)?|\.\d+)", text)
    if not match:
        return None

    return match.group(0)


def filter_elsa_csv(source_file):
    output_file = FILTERED_DIR / f"{source_file.stem}_numeric.csv"
    input_rows = 0
    output_rows = 0

    with source_file.open(newline="") as source, output_file.open("w", newline="") as target:
        reader = csv.DictReader(source)
        missing_columns = [column for column in NUMERIC_COLUMNS if column not in reader.fieldnames]
        if missing_columns:
            raise ValueError(f"{source_file} is missing columns: {', '.join(missing_columns)}")

        writer = csv.DictWriter(target, fieldnames=NUMERIC_COLUMNS)
        writer.writeheader()

        for row in reader:
            input_rows += 1
            numeric_row = {
                column: numeric_prefix(row.get(column))
                for column in NUMERIC_COLUMNS
            }
            if any(value is None for value in numeric_row.values()):
                continue

            writer.writerow(numeric_row)
            output_rows += 1

    return output_file, input_rows, output_rows


def main():
    csv_files = sorted(
        file for file in RAW_DATA_DIR.glob("elsa*.csv")
        if not file.stem.endswith("_numeric")
    )
    if not csv_files:
        raise FileNotFoundError(f"No elsa*.csv files found in {RAW_DATA_DIR}")

    for source_file in csv_files:
        output_file, input_rows, output_rows = filter_elsa_csv(source_file)
        print(f"Wrote {output_file} from {source_file} ({output_rows}/{input_rows} rows kept)")


if __name__ == "__main__":
    main()

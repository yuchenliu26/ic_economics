import csv
import re
from pathlib import Path


INDICATOR_COLUMNS = [
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

METADATA_COLUMNS = [
    ("idauniq", "idauniq"),
    ("wave", "wave"),
    ("age", "age"),
    ("female", "gender"),
    ("raeducl", "raeducl"),
    ("marital", "marital"),
]

FILTERED_DIR = Path(__file__).resolve().parent
RAW_DATA_DIR = FILTERED_DIR.parent / "raw_data"
SOURCE_FILE = RAW_DATA_DIR / "elsa_ic_indicators_long.csv"
OUTPUT_FILE = FILTERED_DIR / "filtered.csv"
OUTPUT_COLUMNS = [output_column for _, output_column in METADATA_COLUMNS] + INDICATOR_COLUMNS


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


def filter_elsa_csv(source_file, output_file=OUTPUT_FILE):
    input_rows = 0
    output_rows = 0

    with source_file.open(newline="") as source, output_file.open("w", newline="") as target:
        reader = csv.DictReader(source)
        input_columns = [input_column for input_column, _ in METADATA_COLUMNS] + INDICATOR_COLUMNS
        missing_columns = [column for column in input_columns if column not in reader.fieldnames]
        if missing_columns:
            raise ValueError(f"{source_file} is missing columns: {', '.join(missing_columns)}")

        writer = csv.DictWriter(target, fieldnames=OUTPUT_COLUMNS)
        writer.writeheader()

        for row in reader:
            input_rows += 1
            numeric_row = {
                column: numeric_prefix(row.get(column))
                for column in INDICATOR_COLUMNS
            }
            if any(value is None for value in numeric_row.values()):
                continue

            output_row = {
                output_column: row.get(input_column, "").strip()
                for input_column, output_column in METADATA_COLUMNS
            }
            output_row.update(numeric_row)
            writer.writerow(output_row)
            output_rows += 1

    return output_file, input_rows, output_rows


def main():
    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"{SOURCE_FILE} does not exist")

    output_file, input_rows, output_rows = filter_elsa_csv(SOURCE_FILE)
    print(f"Wrote {output_file} from {SOURCE_FILE} ({output_rows}/{input_rows} rows kept)")


if __name__ == "__main__":
    main()

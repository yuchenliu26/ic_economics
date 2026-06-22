import csv
import re
from pathlib import Path


INDICATORS = [
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

DATA_DIR = Path(__file__).resolve().parent
RAW_DATA_FILE = DATA_DIR.parent / "raw_data" / "elsa_ic_indicators_long.csv"


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


def write_individual_indicator_files(source_file=RAW_DATA_FILE, output_dir=DATA_DIR):
    counts = {indicator: 0 for indicator in INDICATORS}
    handles = {}
    writers = {}

    try:
        for indicator in INDICATORS:
            handle = (output_dir / f"{indicator}.csv").open("w", newline="")
            writer = csv.writer(handle)
            writer.writerow(["idauniq", indicator])
            handles[indicator] = handle
            writers[indicator] = writer

        with source_file.open(newline="") as source:
            reader = csv.DictReader(source)
            expected_columns = ["idauniq", *INDICATORS]
            missing_columns = [
                column for column in expected_columns
                if column not in (reader.fieldnames or [])
            ]
            if missing_columns:
                raise ValueError(
                    f"{source_file} is missing columns: {', '.join(missing_columns)}"
                )

            for row in reader:
                idauniq = numeric_prefix(row.get("idauniq"))
                if idauniq is None:
                    continue

                for indicator in INDICATORS:
                    response = numeric_prefix(row.get(indicator))
                    if response is None:
                        continue

                    writers[indicator].writerow([idauniq, response])
                    counts[indicator] += 1
    finally:
        for handle in handles.values():
            handle.close()

    return counts


def main():
    counts = write_individual_indicator_files()
    for indicator in INDICATORS:
        print(f"Wrote {indicator}.csv ({counts[indicator]} rows)")


if __name__ == "__main__":
    main()

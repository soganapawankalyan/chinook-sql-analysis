#!/usr/bin/env bash
# run_all.sh | Runs every SQL file against the Chinook SQLite database
# and saves the output as readable text in ./results/.
# Usage (from this folder):  bash run_all.sh
set -euo pipefail

DB="Chinook_Sqlite.sqlite"

if [ ! -f "$DB" ]; then
  echo "Missing $DB in this folder. Download it first (see the README steps)." >&2
  exit 1
fi

mkdir -p results

for f in 0[1-7]_*.sql; do
  out="results/${f%.sql}.txt"
  echo "Running $f -> $out"
  sqlite3 -header -column "$DB" < "$f" > "$out"
done

echo "Done. Open the files in ./results/ and paste key numbers into your README."

#!/usr/bin/env bash
# export_for_tableau.sh | Exports five tidy CSVs for Tableau Public into ./tableau_data/
# Tableau Public cannot read SQLite directly, so it connects to these CSVs.
# Run AFTER run_all.sh (needs the views from 07_views.sql).   Usage: bash export_for_tableau.sh
set -euo pipefail

DB="Chinook_Sqlite.sqlite"
[ -f "$DB" ] || { echo "Missing $DB in this folder." >&2; exit 1; }

mkdir -p tableau_data
for q in tableau/*.sql; do
  name="$(basename "${q%.sql}")"
  sqlite3 -header -csv "$DB" < "$q" > "tableau_data/${name}.csv"
  rows=$(( $(wc -l < "tableau_data/${name}.csv") - 1 ))
  echo "tableau_data/${name}.csv  (${rows} rows)"
done

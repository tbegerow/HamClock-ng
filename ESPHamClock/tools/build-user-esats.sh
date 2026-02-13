#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CFG="$BASE_DIR/config/satellites.yml"
DATA_DIR="$BASE_DIR/data"
OUT="$HOME/.hamclock/user-esats.txt"

source "$(dirname "$0")/tle-lib.sh"

mkdir -p "$(dirname "$OUT")"
: > "$OUT"

fetch_sources

echo "HamClock-ng – User TLE Generator"
echo "Output: $OUT"
echo

# YAML sehr bewusst simpel parsen
current_name=""
current_match=""
current_sources=""

while read -r line; do
  case "$line" in
    "  - name:"*)
      current_name="${line#*: }"
      ;;
    "    match:"*)
      current_match="${line#*: }"
      ;;
    "    sources:"*)
      current_sources="$(echo "$line" | tr -d '[],' | cut -d: -f2)"
      ;;
    "    special:"*)
      if [[ "${line#*: }" == "moon" ]]; then
        echo "Adding Moon"
        moon_tle >> "$OUT"
      fi
      ;;
    "")
      [[ -z "$current_name" ]] && continue

      echo
      echo "$current_name:"
      echo "  0) none"

      i=1
      for src in $current_sources; do
        echo "  $i) $src"
        ((i++))
      done

      read -rp "Select [0]: " sel
      sel="${sel:-0}"

      if [[ "$sel" != "0" ]]; then
        chosen=$(echo "$current_sources" | awk "{print \$$sel}")
        file="$DATA_DIR/$chosen.txt"

        if extract_tle "$current_match" "$file" >> "$OUT"; then
          echo "  ✓ added from $chosen"
        else
          echo "  ✗ not found in $chosen"
        fi
      fi

      current_name=""
      current_match=""
      current_sources=""
      ;;
  esac
done < "$CFG"

echo
echo "Done. Written $(wc -l < "$OUT") lines."

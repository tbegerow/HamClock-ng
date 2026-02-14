#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/tle-lib.sh"

HAMCLOCK_DIR="$HOME/.hamclock/"
CFG_USER="$BASE_DIR/tools/config/user-satellites.yml"
OUT="$HAMCLOCK_DIR/user-esats.txt"
TMP="$(mktemp)"

fetch_sources
: > "$TMP"

echo "→ Building user-esats.txt..."

yq -r '
.satellites[] |
[
  .name,
  .match,
  (.sources[0] // ""),
  (.sources[1] // ""),
  ("SPECIAL=" + (.special // ""))
] | join("|")
' "$CFG_USER" \
| while IFS="|" read -r name pattern source special; do

    if [[ "$special" == *"moon"* ]]; then
        echo "  → Adding Moon"
        moon_tle >> "$TMP"
        continue
    fi

    if [[ -z "$pattern" || -z "$source" ]]; then
        echo "  ⚠ Skipping $name (incomplete config)"
        continue
    fi

    file="$DATA_DIR/$source.txt"
    if [[ ! -f "$file" ]]; then
        echo "  ⚠ Source not found: $source"
        continue
    fi

    if extract_tle "$pattern" "$file" >> "$TMP"; then
        echo "  ✓ Added $name from $source"
    else
        echo "  ⚠ No TLE found for $name ($pattern)"
    fi
done

# Duplikate entfernen
gawk '
NR%3==1 {
  if (!seen[$0]++) keep=1
  else keep=0
}
keep { print }
' "$TMP" > "$OUT"

rm -f "$TMP"

LINES=$(wc -l < "$OUT" || echo 0)

if [[ "$LINES" -eq 0 ]]; then
    echo "✗ user-esats.txt is empty – aborting"
    exit 1
fi

echo "✓ Written $LINES lines to $OUT"
echo "ℹ Some historical satellites are no longer published by AMSAT"

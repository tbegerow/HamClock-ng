#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/tle-lib.sh"

OUT="$BASE_DIR/esats.txt"
TMP="$(mktemp)"

fetch_sources
: > "$TMP"

echo "→ Building esats.txt..."

yq -r '.satellites[] | "\(.name)|\(.match)|\(.sources[0] // "")|\(.sources[1] // "")|SPECIAL=\(.special // "")"' "$CFG" \
| while IFS="|" read -r name pattern s1 s2 special; do
    if [[ "$special" == "moon" ]]; then
        moon_tle >> "$TMP"
        continue
    fi

    for src in "$s1" "$s2"; do
        [[ -z "$src" ]] && continue
        file="$DATA_DIR/$src.txt"
        if extract_tle "$pattern" "$file" >> "$TMP" 2>/dev/null; then
            break
        fi
    done
done

gawk '
NR%3==1 {
  if (!seen[$0]++) keep=1
  else keep=0
}
keep { print }
' "$TMP" > "$OUT"

#rm -f "$TMP"

echo "✓ Written $(wc -l < "$OUT") lines to esats.txt"

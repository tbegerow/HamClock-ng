#!/usr/bin/env bash
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$TOOLS_DIR/data"
BASE_DIR="$(cd "$TOOLS_DIR/.." && pwd)"
CFG="$DATA_DIR/satellites.yml"
TLE_LOG="$BASE_DIR/tle.log"

mkdir -p "$DATA_DIR"

fetch_sources() {
  echo "→ Fetching TLE sources..."

  while read -r u f; do
      rm -f "$f"
      echo "  → Fetching $u"
      if ! curl -A "Mozilla/5.0" -fsSL --connect-timeout 10 --max-time 30 "$u" -o "$f"; then
          echo "Warning: could not fetch $u" >>"$TLE_LOG"
      fi
  done <<EOF
https://www.amsat.org/tle/current/dailytle.txt        $DATA_DIR/amsat.txt
https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=tle   $DATA_DIR/amateur.txt
https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle  $DATA_DIR/stations.txt
EOF
}

extract_tle() {
  local match="$1"
  local file="$2"

  awk -v pat="$match" '
  BEGIN { found=0 }
  {
    if ($0 ~ pat) {
      print $0
      getline; print
      getline; print
      found=1
      exit
    }
  }
  END { if (!found) exit 1 }
  ' "$file"
}

moon_tle() {
cat <<'EOF'
Moon
1     1U     1A   26001.00000000  .00000000  00000-0  0000000 0  0001
2     1  28.3000   0.0000 0362000   0.0000   0.0000  0.03660000    01
EOF
}

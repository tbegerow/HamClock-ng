#!/usr/bin/env bash
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="$TOOLS_DIR/config/satellites.yml"
DATA_DIR="$TOOLS_DIR/data"
BASE_DIR="$(cd "$TOOLS_DIR/.." && pwd)"

mkdir -p "$DATA_DIR"

fetch_sources() {
  echo "→ Fetching TLE sources..."

  curl -fsSL https://www.amsat.org/tle/current/dailytle.txt \
    -o "$DATA_DIR/amsat.txt"

  curl -fsSL "https://celestrak.org/NORAD/elements/gp.php?GROUP=amateur&FORMAT=tle" \
    -o "$DATA_DIR/amateur.txt"

  curl -fsSL "https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=tle" \
    -o "$DATA_DIR/stations.txt"
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

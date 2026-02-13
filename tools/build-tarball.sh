#!/usr/bin/env bash
set -e

# Root des Repos bestimmen
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

SRC_DIR="$REPO_ROOT/ESPHamClock"
OUT_DIR="$REPO_ROOT/dist"
TARBALL="$OUT_DIR/ESPHamClock.tgz"

echo "== HamClock-ng tarball builder =="
echo "Source: $SRC_DIR"
echo "Output: $TARBALL"

# Sanity checks
if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: ESPHamClock directory not found"
    exit 1
fi

mkdir -p "$OUT_DIR"

# Alte Version entfernen
rm -f "$TARBALL"

# Tarball erzeugen
tar \
  --exclude='.git' \
  --exclude='*.o' \
  --exclude='*.elf' \
  --exclude='*.bin' \
  --exclude='*.zip' \
  -czf "$TARBALL" \
  -C "$REPO_ROOT" \
  ESPHamClock

echo "Done."
echo "Created: $TARBALL"

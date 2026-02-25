#!/usr/bin/env bash
set -e

# Root des Repos bestimmen
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

SRC_DIR="$REPO_ROOT/ESPHamClock"
OUT_DIR="$REPO_ROOT/dist"
#TARBALL="$OUT_DIR/ESPHamClock.tgz"
VERSION="$(cat "$SRC_DIR/version.txt")"
TARBALL="$OUT_DIR/ESPHamClock-${VERSION}.tgz"

echo "== HamClock-ng tarball builder =="
echo "Version: $VERSION"
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

ln -sf "ESPHamClock-${VERSION}.tgz" "$OUT_DIR/ESPHamClock-latest.tgz"

echo "Done."
echo "Created: $TARBALL"

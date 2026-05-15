#!/usr/bin/env bash
# setup.sh — stage the /proc Observatory demo environment.
#
# Idempotent: safe to re-run before each rehearsal.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

echo "==> /proc Observatory setup"
echo "    Repo root: $ROOT"
echo

# 1. Sanity-check the tools the demos rely on.
echo "==> Checking required tools..."
missing=0
for tool in bash ps awk grep cat sleep readlink ln chmod date; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "    MISSING: $tool" >&2
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  echo "Install the missing tools and re-run setup." >&2
  exit 1
fi
echo "    All required tools present."
echo

# 2. Mark the demo scripts executable.
echo "==> Making demo scripts executable..."
chmod +x \
  "$ROOT/part1/launch-target.sh" \
  "$ROOT/part2/zombie-maker.sh" \
  "$ROOT/part3/proc-watch"
echo "    Done."
echo

# 3. Put the watcher on $PATH so Part 3 can call it from any directory.
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$ROOT/part3/proc-watch" "$BIN_DIR/proc-watch"
echo "==> Linked proc-watch -> $BIN_DIR/proc-watch"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "    $BIN_DIR is already on PATH."
    ;;
  *)
    echo "    NOTE: $BIN_DIR is not on PATH in this shell."
    echo "    Add it for the demo with:"
    echo "        export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac
echo

# 4. Scratch directory for files the demos open.
SCRATCH="$ROOT/scratch"
mkdir -p "$SCRATCH"
echo "==> Scratch dir: $SCRATCH"
echo

echo "==> Setup complete."
echo
echo "Next steps:"
echo "    less part1/demo.md      # Presenter A"
echo "    less part2/demo.md      # Presenter B"
echo "    less part3/demo.md      # Presenter C"

#!/usr/bin/env bash
# setup.sh — stage the /proc Observatory demo environment.
# Idempotent: safe to re-run before each rehearsal.

set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

# --- pretty colors (only if stdout is a terminal that supports them) -----
if [ -t 1 ] && command -v tput >/dev/null 2>&1 \
   && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
  C_CYAN=$(tput setaf 6)
  C_DIM=$(tput setaf 7)
  C_GRN=$(tput setaf 2)
  C_RST=$(tput sgr0)
else
  C_CYAN="" ; C_DIM="" ; C_GRN="" ; C_RST=""
fi

# --- banner --------------------------------------------------------------
printf '%s' "$C_CYAN"
cat <<'EOF'

   ╔══════════════════════════════════════════════════════════════╗
   ║                                                              ║
   ║       ██████╗ ██████╗  ██████╗  ██████╗                      ║
   ║       ██╔══██╗██╔══██╗██╔═══██╗██╔════╝                      ║
   ║       ██████╔╝██████╔╝██║   ██║██║                           ║
   ║       ██╔═══╝ ██╔══██╗██║   ██║██║                           ║
   ║       ██║     ██║  ██║╚██████╔╝╚██████╗                      ║
   ║       ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝                      ║
   ║                                                              ║
   ║                  O B S E R V A T O R Y                       ║
   ║                                                              ║
   ║         kernel data structures, dressed up as files          ║
   ║                                                              ║
   ╚══════════════════════════════════════════════════════════════╝

EOF
printf '%s' "$C_RST"

step() { printf '%s==>%s %s\n' "$C_CYAN" "$C_RST" "$1"; }
ok()   { printf '   %s✓%s %s\n' "$C_GRN"  "$C_RST" "$1"; }
note() { printf '   %s•%s %s\n' "$C_DIM"  "$C_RST" "$1"; }

# --- 1. tool check -------------------------------------------------------
step "Checking required tools"
missing=0
for tool in bash ps awk grep cat sleep readlink ln chmod date; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '   ✗ missing: %s\n' "$tool" >&2
    missing=1
  fi
done
[ "$missing" -eq 0 ] || { echo "Install the missing tools and re-run."; exit 1; }
ok "all required tools present"

# --- 2. mark scripts executable -----------------------------------------
step "Making demo scripts executable"
chmod +x \
  "$ROOT/part1/launch-target.sh" \
  "$ROOT/part2/zombie-maker.sh" \
  "$ROOT/part3/proc-watch"
ok "chmod +x done"

# --- 3. put proc-watch on PATH ------------------------------------------
step "Linking proc-watch onto \$PATH"
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
ln -sf "$ROOT/part3/proc-watch" "$BIN_DIR/proc-watch"
ok "linked $BIN_DIR/proc-watch -> $ROOT/part3/proc-watch"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    note "$BIN_DIR is already on PATH"
    ;;
  *)
    note "$BIN_DIR is not on PATH in this shell — add it with:"
    note "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    ;;
esac

# --- 4. scratch dir ------------------------------------------------------
step "Creating scratch directory"
mkdir -p "$ROOT/scratch"
ok "scratch dir: $ROOT/scratch"

# --- done ---------------------------------------------------------------
echo
printf '%sSetup complete.%s\n' "$C_GRN" "$C_RST"
echo
echo "Next: walk through the rooms in order."
echo "      cat part1/README.md"
echo "      cat part2/README.md"
echo "      cat part3/README.md"
echo

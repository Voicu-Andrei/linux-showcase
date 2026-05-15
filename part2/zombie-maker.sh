#!/usr/bin/env bash
# zombie-maker.sh — deliberately produce a zombie process for Part 2.
#
# Designed to be backgrounded: `./zombie-maker.sh &`.
#
# Strategy:
#   1. Fork a child that exits after ~1 second.
#   2. Immediately exec the parent into `sleep infinity`. After exec, the
#      parent's SIGCHLD disposition is the kernel default ("ignore"), which
#      — unlike an *explicit* SIG_IGN — does NOT cause auto-reaping. The
#      parent therefore never calls wait(), and the dead child stays in the
#      process table as a zombie (state Z, "<defunct>") until the parent
#      itself dies and init/systemd inherits and reaps the orphan.

set -u

SCRATCH="$(cd "$(dirname "$0")/.." && pwd)/scratch"
mkdir -p "$SCRATCH"

(sleep 1; exit 0) &
CHILD=$!

echo "$$"    > "$SCRATCH/zombie-parent.pid"
echo "$CHILD" > "$SCRATCH/zombie-child.pid"

echo "[part2] zombie maker armed: parent=$$  child=$CHILD  (PIDs in scratch/)"

# Replace this shell with sleep. Same PID, no SIGCHLD handler, no wait().
exec sleep infinity

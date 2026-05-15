#!/usr/bin/env bash
# zombie-maker.sh — deliberately produce a zombie process for Part 2.
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

(sleep 1; exit 0) &
CHILD=$!

cat <<EOF
Zombie maker armed.

  Parent PID: $$
  Child  PID: $CHILD

In ~1 second the child exits. The parent is about to exec into
'sleep infinity', which never calls wait() — so the child becomes a
zombie and stays one until the parent is killed.

In another terminal, try:
  ps -o pid,ppid,stat,comm,cmd -p $CHILD
  grep -E '^(Name|State|PPid):' /proc/$CHILD/status

To reap the zombie, kill the parent:
  kill $$

EOF

# Replace this shell with sleep. Same PID, no SIGCHLD handler, no wait().
exec sleep infinity

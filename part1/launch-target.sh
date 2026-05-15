#!/usr/bin/env bash
# launch-target.sh — start a long-running process whose /proc/<pid>/
# entry is interesting to inspect for Part 1 of the demo.
#
# Designed to be backgrounded: `./launch-target.sh &` then `T=$!`.

set -u

# /proc/<pid>/environ is a snapshot taken by the kernel at execve() time,
# not a live view of the process's current env — `export` after the fact
# would NOT show up there. So re-exec ourselves with the DEMO_* vars set
# at exec time, using a sentinel to avoid an infinite loop. `env -i` also
# clears inherited noise so the demo's `cat environ` output is short and
# obviously-ours.
if [ "${DEMO_OBSERVATORY:-}" != "1" ]; then
  exec env -i \
    PATH="/usr/local/bin:/usr/bin:/bin" \
    HOME="${HOME:-/tmp}" \
    TERM="${TERM:-xterm}" \
    DEMO_OBSERVATORY=1 \
    DEMO_USER="cm204-team" \
    DEMO_COURSE="Operating Systems" \
    DEMO_PROJECT="proc-observatory" \
    bash "$0" "$@"
fi

# Open extra file descriptors so /proc/<pid>/fd/ shows more than 0/1/2.
exec 3< /etc/hostname
exec 4< /etc/os-release

SCRATCH="$(cd "$(dirname "$0")/.." && pwd)/scratch"
mkdir -p "$SCRATCH"
exec 5> "$SCRATCH/launch-target.log"
echo "$$" > "$SCRATCH/target.pid"

echo "[part1] target up: PID=$$  (scratch/target.pid)"

# Park the shell so the PID stays observable. The inner sleep is a child
# process of this bash; bash itself is what /proc/<pid>/ describes.
while true; do
  sleep 60
done

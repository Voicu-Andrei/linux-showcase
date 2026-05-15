#!/usr/bin/env bash
# launch-target.sh — start a long-running process whose /proc/<pid>/
# entry is interesting to inspect for Part 1 of the demo.

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

LOG="$(cd "$(dirname "$0")/.." && pwd)/scratch/launch-target.log"
mkdir -p "$(dirname "$LOG")"
exec 5> "$LOG"

cat <<EOF
Target process up.

  PID:  $$
  Log:  $LOG

In another terminal, copy the PID and try:
  T=$$
  ls    /proc/\$T/
  cat   /proc/\$T/cmdline | tr '\0' ' '; echo
  grep  -E '^(Name|State|Pid|PPid|VmRSS|Threads):' /proc/\$T/status
  cat   /proc/\$T/environ | tr '\0' '\n' | grep '^DEMO_'
  ls -l /proc/\$T/fd/

Press Ctrl+C here when you're done with Part 1.
EOF

# Park the shell so the PID stays observable. The inner sleep is a child
# process of this bash; bash itself is what /proc/<pid>/ describes.
while true; do
  sleep 60
done

# /proc Observatory — Live Command Flow

This is the short terminal runbook. Use `PRESENTATION.md` for speaking
notes and this file for the exact commands.

## Setup

```bash
./setup.sh
```

## Part 1 — Live Process

```bash
./part1/launch-target.sh &
T=$!
ls /proc/$T/
tr '\0' ' ' < /proc/$T/cmdline; echo
grep -E '^(Name|State|Pid|PPid|VmRSS|Threads):' /proc/$T/status
ls -l /proc/$T/fd/
readlink /proc/$T/fd/3
readlink /proc/$T/fd/5
```

Optional:

```bash
readlink /proc/$T/exe
readlink /proc/$T/cwd
```

Finish Part 1:

```bash
kill $T
ls /proc/$T 2>&1 | head -1
```

## Part 2 — Zombie

```bash
./part2/zombie-maker.sh &
P=$!
sleep 1.5
Z=$(cat scratch/zombie-child.pid)
ps -o pid,ppid,stat,comm,cmd -p $Z
grep -E '^(Name|State|PPid):' /proc/$Z/status
ps -o pid,stat,comm,cmd -p $P
cat scratch/zombie-demo.env
kill $P
sleep 0.5
ps -o pid,ppid,stat,comm -p $Z 2>&1
```

## Part 3 — Watcher

```bash
which proc-watch
export PATH="$HOME/.local/bin:$PATH"   # only if which prints nothing
cd /tmp
sleep 8 &
proc-watch $!
cd -
```

Optional zombie watch:

```bash
./part2/zombie-maker.sh &
sleep 1.5
Z=$(cat scratch/zombie-child.pid)
P=$(cat scratch/zombie-parent.pid)
( sleep 5; kill $P ) &
proc-watch $Z
```

## Cleanup

```bash
jobs
kill %1 %2 2>/dev/null
rm -f ~/.local/bin/proc-watch
rm -rf scratch/
```

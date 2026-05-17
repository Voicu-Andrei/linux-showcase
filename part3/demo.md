# Part 3 — Cheat Sheet

**Single terminal · ~2 minutes**

## 1. Read the script

```bash
cat part3/proc-watch
```

The three lines that matter:

- `STATUS=/proc/$PID/status` — the file the kernel exposes for this PID
- `while [ -r "$STATUS" ]; do ... done` — loop ends when the file vanishes
- `awk -F'\t' '/^State:/'` — pull the state line each tick

> No `ptrace`, no `kill -0` race, no signal handler. Just file I/O on
> something the kernel synthesizes.

## 2. Confirm it's on `$PATH`

```bash
which proc-watch
```

If nothing prints:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## 3. Run it from a different directory

```bash
cd /tmp
sleep 8 &
proc-watch $!
```

You'll see one line per second showing the State (`S` while `sleep` is
blocked), then `is gone` after about 8 s.

Expected shape:

```text
Watching PID 1234 (sleep)
[12:00:01] S (sleeping)
[12:00:02] S (sleeping)
PID 1234 (sleep) is gone after 8s
```

Return to the repo:

```bash
cd -
```

## 4. (Optional) Watch a zombie disappear

This connects back to Part 2. Schedule the parent's death so the watcher
gets a clean ending:

```bash
./part2/zombie-maker.sh &
sleep 1.5
Z=$(cat scratch/zombie-child.pid)
P=$(cat scratch/zombie-parent.pid)
( sleep 5; kill $P ) &
proc-watch $Z
```

The watcher prints `Z (zombie)` each second, then `is gone` once init
reaps the orphan.

## 5. Tie back to OS internals

Three takeaways for the rubric:

1. **`/proc` is a kernel-side filesystem.** Every read is answered by
   kernel code, not by disk I/O.
2. **A file disappearing means a process exited.** Process lifecycle
   is reflected directly in the filesystem namespace.
3. **"Everything is a file"** is what lets a 20-line shell script do
   work that would be syscalls and signal handlers in C.

---

## What to say if asked

**Why does the script watch `/proc/<pid>/status`?** That file exists while
the process has a kernel task entry. When it disappears, the process has
been reaped.

**Is this production-grade monitoring?** No. It polls once per second and
can race with PID reuse. Modern Linux can use `pidfd_open` for a stronger
handle to one exact process.

**Why does it still show zombies?** A zombie still has a process table
entry, so `/proc/<pid>/status` remains until the zombie is reaped.

End of demo.

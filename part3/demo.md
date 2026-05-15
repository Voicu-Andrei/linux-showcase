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
sleep 30 &
proc-watch $!
```

You'll see one line per second showing the State (`S` while `sleep` is
blocked), then `is gone` after 30 s.

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

End of demo.

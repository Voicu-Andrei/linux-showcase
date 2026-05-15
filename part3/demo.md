# Part 3 — A shell-script `/proc` watcher

**Presenter C · ~2 minutes**

**Goal.** Build the smallest useful tool that polls `/proc/<pid>/status`
in a loop and reports when the process disappears. Then make it
executable, put it on `$PATH`, and run it from anywhere.

## 1. Read the script

```bash
cat part3/proc-watch
```

Walk the audience through the three lines that matter:

- **`STATUS=/proc/$PID/status`** — the file the kernel exposes for this PID.
- **`while [ -r "$STATUS" ]; do ... done`** — the loop runs as long as the
  status file is readable. The instant the process exits, the kernel
  removes the `/proc/<pid>/` entry, the test fails, the loop exits.
- **`awk -F'\t' '/^State:/ {print $2; exit}'`** — pull just the State line
  so we can show the process going `S` → `R` → `Z` → gone.

Talking point: this script makes **no syscall the kernel doesn't already
expose as a file**. No `ptrace`, no `kill -0` race, just `cat` and `[`.

## 2. Confirm it's executable and on `$PATH`

`setup.sh` already ran `chmod +x` on it and symlinked it into
`~/.local/bin/`.

```bash
ls -l ~/.local/bin/proc-watch
which proc-watch
```

If `which` prints nothing, the bin dir isn't on PATH in this shell:

```bash
export PATH="$HOME/.local/bin:$PATH"
which proc-watch
```

## 3. Run it from a different directory

```bash
cd /tmp
sleep 30 &
proc-watch $!
```

You'll see one line per second showing the State (`S` while `sleep` is
blocked, occasionally `R`), then a final `PID ... is gone` after 30s.

## 4. Try it on something that turns into a zombie

This connects back to Part 2. In one terminal:

```bash
~/path/to/repo/part2/zombie-maker.sh
```

Note the **child** PID it prints. In another terminal:

```bash
proc-watch <child pid>
```

You'll see the State flip to `Z (zombie)` and stay there until you
`kill` the parent — at which point the zombie is reaped and `proc-watch`
prints `is gone`.

## 5. Tie it back to OS internals (closer)

Three takeaways for the rubric:

1. **`/proc` is a kernel-side filesystem.** Every read is answered by
   kernel code, not by disk I/O.
2. **A file disappearing means a process exited.** The kernel's process
   lifecycle is reflected directly in the filesystem namespace.
3. **The Unix "everything is a file" philosophy is what lets a 20-line
   shell script do a job that would be syscalls and signal handlers in C.**

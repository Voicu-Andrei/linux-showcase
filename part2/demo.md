# Part 2 — Zombies and the `wait()` contract

**Presenter B · ~2 minutes**

**Goal.** Show that a process which has exited but whose parent hasn't
called `wait()` lives on as a "zombie" (state `Z`, marked `<defunct>`),
holding nothing but an exit code and a slot in the process table — until
the parent reaps it, or dies and lets `init`/`systemd` clean up.

> Open **two terminals**: A for the maker, B for inspection.

## 1. Why zombies exist (10-second framing before typing)

When a child process exits, the kernel **must** keep its exit status
somewhere so the parent can read it via `wait()` / `waitpid()`. That
"somewhere" is the process table entry. The entry can only be released
once `wait()` has been called for it. A child that has exited but not
yet been waited on is a **zombie**.

## 2. Launch the zombie maker — terminal A

```bash
./part2/zombie-maker.sh
```

Read out the printed parent PID `$P` and child PID `$Z`.

The script forks a child that exits after ~1s, then `exec`s into
`sleep infinity`. `sleep` never calls `wait()`, so the child becomes a
zombie and stays one.

## 3. Watch the child go zombie — terminal B

```bash
Z=<child pid>
ps -o pid,ppid,stat,comm,cmd -p $Z
```

Within a second:

- `STAT` includes `Z` (zombie).
- `CMD` shows `[bash] <defunct>` (or similar) — the kernel only kept the
  name, not the executable.

## 4. Show the kernel's view via `/proc`

```bash
grep -E '^(Name|State|PPid):' /proc/$Z/status
```

`State: Z (zombie)`. Talking points:

- The exit code lives in the parent's task struct, waiting to be read.
- The PID is reserved — it can't be recycled until the parent calls `wait()`.
- A few zombies are harmless. A buggy server that leaks them can exhaust
  PIDs and lock the system out of forking.

## 5. Show the parent that's failing to reap

```bash
P=<parent pid>
ps -o pid,stat,comm,cmd -p $P
```

It's `sleep infinity` — no SIGCHLD handler, no `wait()` call. Ever.
That's exactly the bug pattern: a parent that forks and forgets.

## 6. Clean up: kill the parent

```bash
kill $P
```

Then re-check the child:

```bash
ps -o pid,stat,comm,cmd -p $Z 2>&1
```

Gone. When the parent died, the orphaned zombie was re-parented to PID 1
(`init` / `systemd`), which immediately called `wait()` on it. **Reaping
orphans** is one of PID 1's defining responsibilities, and this is why.

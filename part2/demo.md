# Part 2 — Cheat Sheet

**Single terminal · ~2 minutes**

## 0. Quick framing (10 seconds)

When a child exits, the kernel must keep its exit status until the parent
calls `wait()`. A child that has exited but not been waited on is a
**zombie** (state `Z`, `<defunct>`).

## 1. Spawn the maker in the background

```bash
./part2/zombie-maker.sh &
P=$!
sleep 1.5
Z=$(cat scratch/zombie-child.pid)
```

The maker forks a child that exits in ~1s, then `exec`s into
`sleep infinity` — a process whose default SIGCHLD handling never
auto-reaps and which never calls `wait()`.

## 2. Show the zombie

```bash
ps -o pid,ppid,stat,comm,cmd -p $Z
```

`STAT` shows `Z`. `CMD` ends with `<defunct>`.

## 3. Show the kernel's view

```bash
grep -E '^(Name|State|PPid):' /proc/$Z/status
```

`State: Z (zombie)`. The exit code is sitting in the parent's task
struct, waiting to be read. The PID can't be recycled.

## 4. Show the unhelpful parent

```bash
ps -o pid,stat,comm,cmd -p $P
```

It's `sleep infinity`. No SIGCHLD handler. No `wait()` call. Ever.

## 5. Reap the zombie by killing the parent

```bash
kill $P
sleep 0.5
ps -o pid,ppid,stat,comm -p $Z 2>&1
```

Gone (or briefly reparented to PID 1, then reaped). When the parent
died, the orphan was inherited by `init`/`systemd` (PID 1), which
immediately called `wait()` on it.

> **Reaping orphans** is one of PID 1's defining responsibilities.
> This is exactly why.

---

Next room → `cat part3/README.md`

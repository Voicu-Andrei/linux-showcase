# Part 1 — Walking through `/proc/<pid>/`

**Presenter A · ~2 minutes**

**Goal.** Show that every running process has a directory under `/proc/`,
and that the kernel exposes its command line, status, environment, and
open file descriptors as ordinary readable files.

> Open **two terminals**: terminal A holds the running target, terminal B
> is where you read its `/proc` entry.

## 1. Launch the target process — terminal A

```bash
./part1/launch-target.sh
```

Read out the printed `PID:` line and copy the number.

The script sets some `DEMO_*` env vars, opens two extra files (FDs 3 and 4)
and a log file (FD 5), then parks itself in a loop so the PID stays alive.

## 2. List its `/proc` entry — terminal B

```bash
T=<paste the PID>
ls -F /proc/$T/
```

Talking point: this is **not** a real on-disk directory — every entry is
synthesized by the kernel from in-memory state when you read it.

## 3. `cmdline` — what argv was this process invoked with?

```bash
cat /proc/$T/cmdline | tr '\0' ' '; echo
```

The kernel stores the args NUL-separated; `tr` makes them readable. You'll
see `bash ./part1/launch-target.sh` — exactly the argv the kernel handed
the process at `execve()` time.

## 4. `status` — human-readable process metadata

```bash
grep -E '^(Name|State|Pid|PPid|Uid|VmRSS|Threads):' /proc/$T/status
```

Walk the audience through it:

- `State: S (sleeping)` — the bash is blocked in `wait4()` for the `sleep` child.
- `PPid` — the shell that ran `./launch-target.sh`.
- `VmRSS` — resident memory in KB.
- `Threads` — for a plain bash, this is 1.

## 5. `environ` — the env the process inherited

```bash
cat /proc/$T/environ | tr '\0' '\n' | grep '^DEMO_'
```

Same NUL-separated trick. Point out the three `DEMO_*` vars `launch-target.sh`
exported — environment is per-process, fixed at `execve()` (the kernel
doesn't update it later).

## 6. `fd/` — open file descriptors as symlinks

```bash
ls -l /proc/$T/fd/
```

- `0`, `1`, `2` — stdin/stdout/stderr, pointing at the terminal device.
- `3` — `/etc/hostname` (read-only).
- `4` — `/etc/os-release` (read-only).
- `5` — the scratch log (write-only).

Each entry is a symlink the kernel resolves to the underlying object:

```bash
readlink /proc/$T/fd/3
readlink /proc/$T/fd/4
readlink /proc/$T/fd/5
```

Talking point: this is how `lsof` works under the hood — it just walks
`/proc/*/fd/`.

## 7. Cleanup

In terminal A, hit `Ctrl+C`. Then in terminal B:

```bash
ls /proc/$T/ 2>&1 | head -1
```

The directory is gone. The kernel removed the `/proc/<pid>/` entry the
instant the process was reaped.

# /proc Observatory — Theory & Study Notes

Everything you need to know to defend your two-minute slot. Read your
part once, skim the others. Each section ends with **"questions the
professor might ask"** and short answers.

---

## Background: what is `/proc`?

`/proc` is a **virtual filesystem** (`procfs`) the Linux kernel mounts at
`/proc`. The files in it don't live on a disk — every `read()` is
answered by kernel code, on demand, from in-memory data structures.
Writing to certain files (`/proc/sys/...`) actually changes kernel
behavior at runtime.

```
$ mount | grep ^proc
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
```

For every running process the kernel exposes a directory at
`/proc/<pid>/`. The contents are computed from the kernel's
`task_struct` for that process — the same structure the scheduler uses.

Key consequence: **everything `ps`, `top`, `htop`, `lsof`, `pmap`,
`fuser`, `pidof`, `pgrep` does is, under the hood, just reading files
under `/proc`.** No syscall magic, no `ioctl`s — just `open` / `read`.

---

## PART 1 — Inspecting a live process

### Big picture

A running process is a `task_struct` inside the kernel. `/proc/<pid>/`
lets userspace look at parts of that struct as plain files. You'll
show four of those files plus the directory layout.

### The directory layout

```
$ ls /proc/$T/
attr/      coredump_filter  exe        latency  mounts        oom_adj
auxv       cpuset           fd/        limits   mountinfo     ...
cgroup     cwd              fdinfo/    loginuid mountstats    
clear_refs environ          gid_map    maps     net/           cmdline
cmdline    fd/              io         mem      ns/           statm
comm       ...                                                stat
                                                              status
```

The ones you'll use:

| file       | what's inside                                       |
| ---------- | --------------------------------------------------- |
| `cmdline`  | the `argv` the process was launched with (NUL-separated) |
| `status`   | human-readable summary of the `task_struct`         |
| `environ`  | snapshot of `envp` at `execve()` time (NUL-separated) |
| `fd/`      | one symlink per open file descriptor                |
| `cwd`      | symlink to current working directory                |
| `exe`      | symlink to the executable file                      |
| `maps`     | virtual memory regions (text, heap, stack, libs)    |
| `stat`     | machine-readable `status` (used by `ps`)            |
| `comm`     | the process's short name (max 15 chars)             |

### `cmdline`

The kernel keeps the original `argv` array, NUL-separated. That's why
you see one blob with `\0` between args:

```
$ cat /proc/$T/cmdline
bash./part1/launch-target.sh
```

`tr '\0' ' '` makes it readable. The blob is **what `execve()`
received**, not what `ps -f` reconstructs (a process can overwrite its
argv area at runtime — e.g. `nginx: master process`).

### `status` — field by field

The fields the demo greps are the ones a non-Linux examiner is most
likely to ask about:

| field     | meaning                                               |
| --------- | ----------------------------------------------------- |
| `Name`    | first 15 chars of the executable's `comm` (basename)  |
| `State`   | one-letter state code + word (see table below)        |
| `Pid`     | process ID                                            |
| `PPid`    | parent's PID                                          |
| `VmRSS`   | resident set size in KB — actual physical RAM in use  |
| `Threads` | number of threads in the process (1 for plain bash)   |

Bigger list of fields the file contains (point at any of these if asked
"what else is in there?"):

- `Tgid` — thread group ID (= PID of the main thread)
- `Uid`, `Gid` — real / effective / saved / fs UIDs and GIDs
- `VmSize` — total virtual memory; `VmPeak` — peak ever; `VmHWM` — peak resident
- `VmData`, `VmStk`, `VmExe`, `VmLib` — data / stack / text / shared-lib sizes
- `SigQ`, `SigPnd`, `SigBlk`, `SigIgn`, `SigCgt` — signal queue and masks (bitmasks in hex)
- `CapInh`, `CapPrm`, `CapEff`, `CapBnd` — Linux capability sets
- `voluntary_ctxt_switches`, `nonvoluntary_ctxt_switches` — scheduler stats
- `Cpus_allowed_list` — CPU affinity

### Process states (the letter in `State:`)

| letter | meaning             | notes                                            |
| ------ | ------------------- | ------------------------------------------------ |
| `R`    | running / runnable  | on a CPU or in a runqueue                        |
| `S`    | sleeping            | interruptible (a signal will wake it)            |
| `D`    | uninterruptible     | usually blocked on disk I/O — **cannot be killed** |
| `T`    | stopped             | by `SIGSTOP` / Ctrl-Z                            |
| `t`    | tracing stop        | stopped by `ptrace` (e.g. inside `gdb`)          |
| `X`    | dead                | brief; almost never observed                     |
| `Z`    | zombie              | exited, waiting for parent's `wait()`            |
| `I`    | idle                | kernel thread that's idle                        |

In the demo you'll see `S` because bash is blocked in `wait4()` for its
inner `sleep` child.

### `environ`

The environment block of `argv/envp` at `execve()` time, NUL-separated:

```
$ cat /proc/$T/environ | tr '\0' '\n'
PATH=/usr/local/bin:/usr/bin:/bin
HOME=/home/student
TERM=xterm
DEMO_OBSERVATORY=1
DEMO_USER=cm204-team
...
```

**Critical subtlety:** this is a **snapshot at exec time**. Calling
`putenv()` / `setenv()` / `export` later does **not** update the
kernel's copy. That's why the launcher script does
`exec env -i ... bash "$0"` — to bake the `DEMO_*` vars in at exec time
so they appear here.

### `fd/`

One symlink per open file descriptor. Each link points to the underlying
object — a regular file, a pipe (`pipe:[12345]`), a socket
(`socket:[67890]`), a device, etc.

```
$ ls -l /proc/$T/fd/
lrwx------ 1 user user 64 May 15 12:00 0 -> /dev/pts/3
lrwx------ 1 user user 64 May 15 12:00 1 -> /dev/pts/3
lrwx------ 1 user user 64 May 15 12:00 2 -> /dev/pts/3
lr-x------ 1 user user 64 May 15 12:00 3 -> /etc/hostname
lr-x------ 1 user user 64 May 15 12:00 4 -> /etc/os-release
l-wx------ 1 user user 64 May 15 12:00 5 -> /home/.../scratch/launch-target.log
```

The permission bits on the symlink itself encode the open mode:
`lr-x` = opened read-only, `l-wx` = write-only, `lrwx` = read/write.

`lsof` is literally a loop over `/proc/*/fd/`. So is `fuser`.

### Questions the professor might ask (Part 1)

> **Why isn't `/proc` on disk?**
> Because the data is the kernel's live state. Storing it on disk would
> mean copying it every time something changes. The procfs driver
> generates each file's contents on demand the moment you `read()`.

> **Why are `cmdline` and `environ` NUL-separated instead of newline-separated?**
> Because `execve()` takes `argv` and `envp` as arrays of pointers to
> NUL-terminated strings. The kernel just dumps the buffer as-is.

> **Can a process change its own `cmdline`?**
> Yes — by overwriting the memory pointed to by `argv[0..n]` (within
> the size the kernel reserved). `prctl(PR_SET_NAME)` changes
> `/proc/<pid>/comm`. That's how `postgres` shows `postgres: checkpointer`.

> **What's the difference between `comm` and `cmdline`?**
> `comm` is a short name (15 chars max) — the kernel-side `task->comm`.
> `cmdline` is the full original `argv`.

> **Why does `cat /proc/$T/environ` look stale after I `export FOO=bar`?**
> Because it's a snapshot at `execve()` time. `export` updates the
> process's in-memory env, not the kernel's copy.

---

## PART 2 — Zombies, `wait()`, and PID 1

### Big picture

A child process that has exited but whose parent hasn't called `wait()`
is a **zombie**. It holds no memory, no FDs, no nothing — just a slot
in the process table containing its exit code, waiting to be read.

### The Unix process lifecycle

```
   fork()          execve()            _exit(N)
   ─────►   child   ─────►   running   ─────►   ZOMBIE
                                                  │
                              parent ───wait()───►│
                                                  ▼
                                              REAPED
                                          (slot released)
```

- `fork()` (really `clone()`) makes a new process — a copy of the parent.
  It returns 0 in the child, the child's PID in the parent.
- `execve()` replaces the new process's memory image with a different
  program. The PID does not change.
- `_exit(N)` terminates the process. The kernel saves `N` and sends
  `SIGCHLD` to the parent.
- `wait()` / `waitpid()` / `wait4()` reads the exit status and tells
  the kernel "I've collected it — you can free the slot now."

Until that `wait()` happens, the process is in state **Z (zombie)** —
also called `<defunct>` in `ps` output.

### What a zombie still owns

Almost nothing. The kernel has already freed:

- the address space (heap, stack, mmap regions),
- the file descriptor table,
- the page tables.

What remains:

- the **PID** (so it can't be reused — that's the point),
- the **exit code** and **resource-usage info** (so the parent can read it),
- a **`task_struct`** linked in the process tree.

### SIGCHLD — the subtle bit

When a child exits, the kernel sends `SIGCHLD` to the parent. The parent
can do one of three things:

1. **Default disposition.** Action is "ignore" — *but the zombie is
   kept*. The parent has to call `wait()` later.
2. **Install a handler** (`signal(SIGCHLD, my_handler)`). The handler
   calls `wait()` and the zombie is reaped.
3. **Explicit `SIG_IGN`** (`signal(SIGCHLD, SIG_IGN)`) or
   `sigaction` with `SA_NOCLDWAIT`. The kernel **auto-reaps**: no
   zombie is ever created.

Cases 1 and 3 sound identical ("ignore SIGCHLD") but are **different
to the kernel**. Linux has the historical rule:

> *Default* ignore → zombies stick around.
> *Explicit* ignore → kernel reaps for you.

The zombie maker exploits this. After `exec sleep infinity`, the
process's SIGCHLD disposition is the default (because `execve()` resets
caught signals back to defaults). So the dead child is **not**
auto-reaped — it sits as a zombie.

### Why zombies are bad if leaked

A zombie is tiny in memory, but it holds a PID. PIDs are a finite
namespace (32768 by default — `cat /proc/sys/kernel/pid_max`). A buggy
server that forks workers and never reaps them can exhaust the PID
space and **lock the system out of forking anything else**, including
`bash`. You can't `kill` the zombie itself — it's already dead. You
have to fix the parent.

### PID 1 — init / systemd

`init` (PID 1, today usually `systemd`) is special:

- It is the **first userspace process**, started by the kernel.
- It **never exits**. If it did, the kernel would panic.
- It **inherits all orphans** — any process whose parent dies gets
  reparented to PID 1.
- It **must call `wait()` in a loop** so reparented orphans don't
  become permanent zombies.

That's the whole point of containers needing a proper init (e.g.
`tini`, `dumb-init`, `s6`, `runit`). A naive `CMD ["./my-app"]` makes
your app PID 1, and if it forks anything that orphans, you leak
zombies forever.

### The exact mechanics of the demo

```bash
(sleep 1; exit 0) &      # fork child A; child sleeps 1s then exits
CHILD=$!
exec sleep infinity       # parent becomes sleep; same PID; default SIGCHLD
```

1. Bash forks subshell A. A runs `sleep 1; exit 0`.
2. Bash `exec`s `sleep infinity`. PID unchanged, but the program is now
   `sleep`, and signal dispositions are reset to defaults.
3. ~1s later: child A calls `_exit(0)`. Kernel sends `SIGCHLD` to
   parent (= `sleep infinity`). `sleep`'s SIGCHLD disposition is
   default-ignore → no auto-reap → **child A is a zombie**.
4. We `kill <parent>`. The `sleep infinity` dies. Child A is orphaned.
5. The kernel reparents A to PID 1. PID 1 calls `wait()` on it
   immediately. **Reaped.**

### Questions the professor might ask (Part 2)

> **What's the difference between an orphan and a zombie?**
> An orphan is a process whose **parent** has died — the child is
> still alive, and gets re-parented to PID 1.
> A zombie is a process that has **exited itself** and is waiting for
> someone to call `wait()` on it.

> **Why can't I `kill -9` a zombie?**
> Because it's already dead. `kill` sends a signal to a running
> process; a zombie has no code to run. The only way to remove it
> is `wait()` from the parent (or kill the parent so PID 1 inherits and
> waits).

> **What's the difference between `SIGCHLD` being ignored by default
> and being explicitly set to `SIG_IGN`?**
> By default the signal is ignored *but the zombie is kept*. With
> *explicit* `SIG_IGN` (or `SA_NOCLDWAIT`), the kernel auto-reaps —
> no zombie is ever created. POSIX permits this Linux behaviour;
> it's an optimisation for daemons that don't care about exit codes.

> **What if PID 1 itself dies?**
> Kernel panic. The kernel will not let userspace run without an init.

> **Is `fork()` actually used today, or `clone()`?**
> `clone()`. `fork()` is implemented in glibc as a `clone()` call with
> specific flags. `clone()` is also what's used for threads (with
> shared-memory flags).

---

## PART 3 — A shell-script process watcher

### Big picture

Because the kernel exposes process state as a file, you don't need a
syscall to ask "is this process still alive?" — you can `cat` it.
When the process dies, the file **disappears**, so the question
"is it alive?" reduces to "does this file still exist?"

### The script, in words

```bash
STATUS=/proc/$PID/status
while [ -r "$STATUS" ]; do          # while the file is still readable...
  awk -F'\t' '/^State:/ {print $2}' "$STATUS"   # show its state
  sleep 1
done
echo "PID $PID is gone"
```

- `[ -r "$STATUS" ]` — the `test` builtin, equivalent to `access(STATUS, R_OK)`.
- `awk -F'\t' '/^State:/'` — `status` is tab-separated, so we split on `\t`
  to get the value cleanly.
- The loop exits the instant `/proc/<pid>/` is removed. The kernel
  removes that directory the moment the process is reaped (so for a
  zombie, the file still exists — the loop keeps running until the
  zombie is reaped).

### Why this matters pedagogically

The script uses **no special syscall**. It doesn't `ptrace`, it doesn't
`kill -0` (which races on PID reuse), it doesn't open a netlink socket.
Just `read()` and `access()`. The kernel's "everything is a file"
philosophy turns process introspection into a problem any tool that can
read a file can solve.

### PATH and symlinks

```bash
$ which proc-watch
/home/student/.local/bin/proc-watch
$ readlink /home/student/.local/bin/proc-watch
/home/student/linux-showcase/part3/proc-watch
```

`setup.sh` puts a symlink in `~/.local/bin/`, which Ubuntu/Debian
include on `$PATH` for interactive shells (via `~/.profile`). The
script keeps its real home in the repo; the symlink makes it
discoverable from any working directory.

### How other tools work (good to mention)

| tool   | what it reads under `/proc`                            |
| ------ | ------------------------------------------------------ |
| `ps`   | `/proc/*/stat`, `/proc/*/status`, `/proc/*/cmdline`    |
| `top`, `htop` | same, polled every second or two                |
| `lsof` | walks `/proc/*/fd/`                                    |
| `fuser`| walks `/proc/*/fd/`, `/proc/*/maps`                    |
| `pmap` | `/proc/<pid>/maps`, `/proc/<pid>/smaps`                |
| `pidof`, `pgrep` | `/proc/*/comm`, `/proc/*/cmdline`            |
| `strace -p` | uses `ptrace`, NOT procfs — different mechanism   |

### Limitations of polling (be ready for this)

Polling `/proc/<pid>/status` every second is fine for a demo but has
two real-world problems:

1. **Latency.** Up to one second between death and detection.
2. **PID reuse.** If the PID is recycled to a different process in
   between samples, you won't notice. Production-grade tools use
   `pidfd_open(2)` (since Linux 5.3): an opaque handle that uniquely
   identifies *this specific* process and signals via `poll()` when it
   exits. No race, no polling.

For the demo, polling is the right call — it makes the file-as-interface
idea visible.

### Questions the professor might ask (Part 3)

> **What does `[ -r file ]` actually do?**
> It calls `access(2)` with `R_OK`. For procfs files this never blocks
> on I/O — the kernel answers from in-memory state.

> **Why poll, instead of waiting for the process to die?**
> Because there's no portable filesystem notification for `/proc`
> entries disappearing — `inotify` doesn't fire on procfs. The modern
> answer is `pidfd_open` + `poll`, which we'd reach for in real code.

> **Why does the script still show `Z (zombie)` instead of "gone" when
> watching a zombie?**
> Because the `/proc/<pid>/` directory persists for as long as the
> task_struct does. A zombie still has a task_struct. Only when the
> zombie is reaped does the directory vanish.

> **What's the difference between `kill -0 $PID` and your approach?**
> `kill -0` sends signal 0, which checks if the PID exists and you have
> permission to signal it. It races on PID reuse: between two
> `kill -0`s the PID might have been recycled. Reading `/proc/<pid>/`
> has the same race in principle; only `pidfd_open` avoids it.

---

## One-paragraph recap (for the closing slide)

> Linux exposes every kernel data structure that describes a process
> as a file in `/proc/<pid>/`. Part 1 showed you can read those files
> with `cat` and learn everything `ps` and `lsof` know. Part 2 showed
> that the kernel keeps a slot for a dead process until its parent
> `wait()`s for it — and that this is *why* PID 1 exists, to reap
> orphans nobody else will. Part 3 showed that "is this process
> alive?" needs no special API: a 10-line shell script, four basic
> coreutils, and the file-as-interface model are enough.

---

## Further reading

- `man 5 proc` — the canonical reference for every file we touched.
- `man 2 wait` — the syscalls behind reaping.
- `man 7 signal` — SIGCHLD, default vs explicit ignore, `SA_NOCLDWAIT`.
- `man 2 pidfd_open` — the modern alternative to `proc-watch`.
- *The Linux Programming Interface*, Michael Kerrisk — chapters 24
  (Process Creation), 26 (Monitoring Child Processes), 12 (System &
  Process Information).

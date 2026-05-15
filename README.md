# /proc Observatory — CM-204 Linux Showcase

A live, three-part demo of the Linux `/proc` virtual filesystem, presented by
a three-person team for **CM-204 Operating Systems**. Each part runs in about
two minutes.

## What is `/proc`?

`/proc` is a virtual filesystem the Linux kernel mounts at `/proc`. The files
don't exist on disk — every read is answered by kernel code, on demand, from
live in-memory state. Each running process gets a directory at `/proc/<pid>/`
that exposes its command line, status, environment, open file descriptors,
memory map, and more.

This demo shows three angles on it:

| Part | Presenter   | Topic                                              |
| ---- | ----------- | -------------------------------------------------- |
| 1    | Presenter A | Navigating `/proc/<pid>/` of a live process        |
| 2    | Presenter B | Zombies, `wait()`, and why PID 1 reaps orphans     |
| 3    | Presenter C | A shell-script `/proc` watcher                     |

## Setup

Tested on Ubuntu 22.04 / Debian 12. Only standard userland is required
(`bash`, `ps`, `awk`, `grep`, `cat`, `sleep`, `readlink`).

From the repo root:

```bash
./setup.sh
```

This:

1. Verifies the required tools are installed.
2. Marks the demo scripts executable.
3. Symlinks `part3/proc-watch` into `~/.local/bin/` so it's on `$PATH`.
4. Creates a `scratch/` directory for any files the demos write.

## Running the demos

Each part has its own folder with a `demo.md` listing the exact commands
to type, in order:

- [`part1/demo.md`](part1/demo.md) — `/proc/<pid>/` walkthrough
- [`part2/demo.md`](part2/demo.md) — zombie creation & cleanup
- [`part3/demo.md`](part3/demo.md) — process watcher

A clean, repeatable order for the live presentation:

```bash
./setup.sh           # once, before the demo starts
# Presenter A
less part1/demo.md
# Presenter B
less part2/demo.md
# Presenter C
less part3/demo.md
```

## Layout

```
.
├── setup.sh                stage the demo environment
├── README.md               this file
├── part1/
│   ├── launch-target.sh    long-running process to inspect
│   └── demo.md
├── part2/
│   ├── zombie-maker.sh     forks a child and never calls wait()
│   └── demo.md
└── part3/
    ├── proc-watch          polls /proc/<pid>/status until the PID is gone
    └── demo.md
```

## Cleanup after the presentation

Stop any long-running demo processes you started (`launch-target.sh`, the
`sleep infinity` left behind by `zombie-maker.sh`) and remove the symlink:

```bash
rm -f ~/.local/bin/proc-watch
```

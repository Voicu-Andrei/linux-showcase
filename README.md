# /proc Observatory

A three-room live demo of the Linux `/proc` virtual filesystem.
For **CM-204 — Operating Systems**. ~2 minutes per presenter.

## What is this?

Every running process has a directory at `/proc/<pid>/` that the kernel
fills with its command line, status, environment, open file descriptors,
memory map, and more. The files don't exist on disk — every read is
answered by kernel code, on demand, from live in-memory state.

This demo shows three angles on it:

| Part | Presenter   | Topic                                          |
| ---- | ----------- | ---------------------------------------------- |
|  1   | Presenter A | Walk through `/proc/<pid>/` of a live process  |
|  2   | Presenter B | Make a zombie — and see why PID 1 reaps orphans |
|  3   | Presenter C | A 20-line shell-script process watcher          |

## Get started

```bash
./setup.sh
```

Then enter the first room:

```bash
cat part1/README.md
```

Each room tells you exactly what to type and points you to the next.

> **Run everything from the repo root** in **one terminal**. The demos
> use `&` to background long-running processes; you don't need a second
> shell.

## Layout

```
.
├── setup.sh              ASCII-banner + stage the environment
├── README.md             this file
├── part1/
│   ├── README.md         the room guide  (start here)
│   ├── demo.md           line-by-line cheat sheet
│   └── launch-target.sh  the process you'll inspect
├── part2/
│   ├── README.md
│   ├── demo.md
│   └── zombie-maker.sh
└── part3/
    ├── README.md
    ├── demo.md
    └── proc-watch        the watcher (also linked into ~/.local/bin/)
```

## Tested on

Ubuntu 22.04 / Debian 12. Standard userland only (`bash`, `ps`, `awk`,
`grep`, `cat`, `sleep`, `readlink`).

## Cleanup after the presentation

```bash
jobs                       # any leftover background processes?
kill %1 %2                 # kill what's still running
rm -f ~/.local/bin/proc-watch
rm -rf scratch/
```

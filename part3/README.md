# part3/ — The Watcher Room

> A small scroll on the table. Twenty lines of bash. It can tell you,
> from anywhere on the system, exactly when a process dies — without
> ever calling a single special syscall.

**Your job:** read the script, prove it's on `$PATH`, and run it from
somewhere other than the repo.

## What's in this room

| file         | what it does                                         |
| ------------ | ---------------------------------------------------- |
| `proc-watch` | shell script that polls `/proc/<pid>/status`         |
| `demo.md`    | the line-by-line script for the demo                 |
| `README.md`  | this guide                                           |

## Step 1 — confirm the watcher is on `$PATH`

`setup.sh` already symlinked it into `~/.local/bin/`.

```bash
which proc-watch
```

If `which` prints nothing, add the bin dir to `$PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Step 2 — follow the cheat sheet

```bash
cat part3/demo.md
```

## Step 3 — when you're done

You've finished the demo. Bow. Then check for stragglers:

```bash
jobs                                  # list any background processes
kill %1 %2 2>/dev/null                # tidy them up
rm -f ~/.local/bin/proc-watch         # remove the PATH link
rm -rf scratch/                       # remove pid files / log
```

# part2/ — The Zombie Room

> Cold air. Something on the floor used to be a process. Its exit code
> still glows faintly in the kernel's bookkeeping, waiting for a parent
> who will never come.

**Your job:** deliberately create a zombie, prove it's a zombie, then
clean it up by killing the parent.

## What's in this room

| file               | what it does                                |
| ------------------ | ------------------------------------------- |
| `zombie-maker.sh`  | forks a child, then becomes a parent that never calls `wait()` |
| `demo.md`          | the line-by-line script for the demo        |
| `README.md`        | this guide                                  |

## Step 1 — arm the maker

From the **repo root**, in the same terminal you used for Part 1:

```bash
./part2/zombie-maker.sh &
P=$!
sleep 1.5
Z=$(cat scratch/zombie-child.pid)
```

- `$P` — the parent (about to be `sleep infinity`, never reaps)
- `$Z` — the child, currently a zombie

## Step 2 — follow the cheat sheet

```bash
cat part2/demo.md
```

The commands all use `$P` and `$Z`.

## Step 3 — when you're done

```bash
kill $P
```

Killing the parent reparents the orphaned zombie to PID 1, which
immediately calls `wait()` and reaps it.

Then walk to the next room:

```bash
cat part3/README.md
```

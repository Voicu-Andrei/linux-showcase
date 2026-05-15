# part1/ — The Live Process Room

> A process is humming on a pedestal in the center of the room.
> The walls are covered in tiny doors, each labeled `/proc/<pid>/...`.

**Your job:** pick up a live process and read the kernel's notes on it
through `/proc`.

## What's in this room

| file               | what it does                                |
| ------------------ | ------------------------------------------- |
| `launch-target.sh` | starts the long-running process to inspect  |
| `demo.md`          | the line-by-line script for the demo        |
| `README.md`        | this guide                                  |

## Step 1 — wake the target

From the **repo root**, in a single terminal:

```bash
./part1/launch-target.sh &
T=$!
```

The script prints its PID. `$T` now holds it. The process will sit there
until you kill it.

## Step 2 — follow the cheat sheet

```bash
cat part1/demo.md
```

(or `less part1/demo.md` if you want to scroll.) Type the commands in
order — they all use `$T`.

## Step 3 — when you're done

```bash
kill $T
```

Then walk to the next room:

```bash
cat part2/README.md
```

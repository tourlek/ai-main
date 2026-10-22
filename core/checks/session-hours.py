#!/usr/bin/env python3
"""Active wall-clock time of a DSH session (plus its child subagent sessions).

Usage: session-hours.py <session-id-or-path> [--gap-min 15] [--entries entries.json]

Merges event times into blocks (gap <= --gap-min) and prints them in local time.
--entries: JSON list of {"task_id","start":"ISO8601+offset","hours":float}; exit 1 if
entries overlap, fall outside a block (2 min slack) or sum to more than the total.
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys
from datetime import datetime

SESSIONS = os.path.expanduser("~/.dsh/sessions")
SLACK_MS = 2 * 60 * 1000
CHILD = re.compile(r"started subagent ([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})")


def resolve(arg):
    if os.path.isfile(arg):
        return arg
    bare = arg[len("session-"):] if arg.startswith("session-") else arg
    for name in (bare, "session-" + bare):
        hits = glob.glob(os.path.join(SESSIONS, "*", name, "session.v4.jsonl.zstd"))
        if hits:
            return hits[0]
    return None


def read_lines(path):
    if path.endswith(".zstd") or path.endswith(".zst"):
        out = subprocess.run(["zstd", "-dc", path], check=True, capture_output=True).stdout
        text = out.decode("utf-8", "replace")
    else:
        with open(path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    return text.splitlines()


def collect(path, times, seen):
    children = set()
    for line in read_lines(path):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        t = ev.get("time") if isinstance(ev, dict) else None
        if isinstance(t, (int, float)):
            times.append(int(t))
        if "started subagent" in line:
            children.update(CHILD.findall(line))
    for cid in sorted(children - seen):
        seen.add(cid)
        cpath = resolve(cid)
        if cpath:
            collect(cpath, times, seen)
        else:
            print(f"note: child session {cid} not found, skipped", file=sys.stderr)


def blocks_of(times, gap_ms):
    out = []
    for t in sorted(times):
        if out and t - out[-1][1] <= gap_ms:
            out[-1][1] = t
        else:
            out.append([t, t])
    return out


def local(ms):
    return datetime.fromtimestamp(ms / 1000).astimezone()


def hm(minutes):
    return f"{minutes // 60}h{minutes % 60}m"


def check_entries(path, blocks, total_min):
    with open(path, encoding="utf-8") as f:
        entries = json.load(f)
    spans, problems = [], []
    for i, e in enumerate(entries):
        start = int(datetime.fromisoformat(e["start"]).timestamp() * 1000)
        end = start + int(round(float(e["hours"]) * 3600 * 1000))
        label = f"#{i} {e.get('task_id', '?')} {local(start):%Y-%m-%d %H:%M}->{local(end):%H:%M}"
        spans.append((start, end, label))
        if not any(b0 - SLACK_MS <= start and end <= b1 + SLACK_MS for b0, b1 in blocks):
            problems.append(f"OUTSIDE {label}: not inside any active block")
    spans.sort()
    for (s0, e0, l0), (s1, e1, l1) in zip(spans, spans[1:]):
        if s1 < e0:
            problems.append(f"OVERLAP {l0} and {l1}")
    booked = sum(float(e["hours"]) for e in entries) * 60
    if booked > total_min + 0.5:
        problems.append(f"SUM {hm(round(booked))} > total {hm(total_min)}")
    return problems


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("session")
    ap.add_argument("--gap-min", type=float, default=15)
    ap.add_argument("--entries")
    a = ap.parse_args()

    path = resolve(a.session)
    if not path:
        sys.exit(f"session not found: {a.session}")
    times = []
    collect(path, times, set())
    if not times:
        sys.exit(f"no event times in {path}")

    blocks = blocks_of(times, a.gap_min * 60 * 1000)
    total = 0
    for b0, b1 in blocks:
        m = round((b1 - b0) / 60000)
        total += m
        print(f"{local(b0):%Y-%m-%d %H:%M} -> {local(b1):%H:%M}  {m}m")
    print(f"TOTAL {hm(total)}")

    if a.entries:
        problems = check_entries(a.entries, blocks, total)
        for p in problems:
            print(p)
        sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()

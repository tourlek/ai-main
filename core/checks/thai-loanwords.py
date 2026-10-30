#!/usr/bin/env python3
"""Count rule breaks in assistant replies: Thai transliterations of English technical
terms, and any CJK (Chinese/Japanese) run.

Usage: thai-loanwords.py <session-id-or-path>... [--max N]

Reads assistant/message text blocks from archived DSH-format session logs (retired harness; not reasoning, not tool calls),
drops code fences and `inline code`, and reports each hit with its seq and kind. Word list:
core/checks/thai-loanwords.json. Exit 1 if there are more than --max hits (default 0).
"""
import argparse
import importlib.util
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("session_hours", os.path.join(HERE, "session-hours.py"))
sh = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sh)

CFG = json.load(open(os.path.join(HERE, "thai-loanwords.json"), encoding="utf-8"))
WORDS = re.compile("|".join(sorted(map(re.escape, CFG["words"]), key=len, reverse=True)))
ALLOW = re.compile("|".join(map(re.escape, CFG["allow"]))) if CFG["allow"] else None
CODE = re.compile(r"```.*?```|`[^`\n]*`", re.S)
CJK = re.compile(
    "[" + "".join(f"\\u{a}-\\u{b}" for a, b in CFG.get("cjkRanges", [])) + "]+"
)


def hits_in(text):
    text = CODE.sub(" ", text)
    if ALLOW:
        text = ALLOW.sub(" ", text)
    return [("loanword", w) for w in WORDS.findall(text)] + [("cjk", w) for w in CJK.findall(text)]


def scan(path):
    found = []
    for line in sh.read_lines(path):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") != "assistant/message":
            continue
        content = ((ev.get("data") or {}).get("message") or {}).get("content") or []
        text = "\n".join(b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text")
        found.extend((ev.get("seq"), kind, text) for kind, text in hits_in(text))
    return found


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("sessions", nargs="+")
    ap.add_argument("--max", type=int, default=0)
    a = ap.parse_args()
    total = 0
    for s in a.sessions:
        path = sh.resolve(s)
        if not path:
            sys.exit(f"session not found: {s}")
        found = scan(path)
        total += len(found)
        for seq, kind, text in found:
            print(f"{s} seq={seq} {kind} {text}")
    print(f"TOTAL {total}")
    sys.exit(1 if total > a.max else 0)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Estimate ai-main-owned Pi context and enforce its configured budget."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

AI_MAIN = Path(__file__).resolve().parent.parent
HOME = Path.home()
CONFIG = AI_MAIN / "config" / "pi-skills.json"
MANIFEST = AI_MAIN / "build" / "pi-skills-manifest.json"
APPEND_SYSTEM = HOME / ".pi" / "agent" / "APPEND_SYSTEM.md"


def estimate(text: str) -> int:
    ascii_chars = sum(ord(char) < 128 for char in text)
    non_ascii = len(text) - ascii_chars
    return ascii_chars // 4 + (non_ascii * 2) // 3


def description(text: str) -> str:
    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return ""
    lines = match.group(1).splitlines()
    for index, line in enumerate(lines):
        if not line.startswith("description:"):
            continue
        value = line.split(":", 1)[1].strip()
        if value not in {"|", ">"}:
            return value.strip("\"'")
        block = []
        for following in lines[index + 1 :]:
            if following and not following[0].isspace():
                break
            block.append(following.strip())
        return " ".join(part for part in block if part)
    return ""


def main() -> int:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    append_text = APPEND_SYSTEM.read_text(encoding="utf-8")
    append_tokens = estimate(append_text)

    catalog_parts = []
    for entry in manifest["entries"]:
        if entry["mode"] != "auto":
            continue
        source = Path(entry["source"])
        desc = description(source.read_text(encoding="utf-8"))
        location = AI_MAIN / "build" / "pi-skills" / entry["name"] / "SKILL.md"
        catalog_parts.append(
            f"<skill><name>{entry['name']}</name><description>{desc}</description>"
            f"<location>{location}</location></skill>"
        )
    catalog_tokens = estimate("\n".join(catalog_parts))
    total = append_tokens + catalog_tokens
    budget = int(config["budgetTokens"])

    print(f"Pi append context: ~{append_tokens} tokens")
    print(f"Pi visible skill catalog: ~{catalog_tokens} tokens ({manifest['autoCount']} skills)")
    print(f"Pi ai-main total: ~{total}/{budget} tokens")
    if total > budget:
        print("Pi context budget exceeded", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

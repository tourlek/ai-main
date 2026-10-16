#!/usr/bin/env python3
"""Build Pi's curated skill farm without changing canonical skill sources."""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import sys
from pathlib import Path

AI_MAIN = Path(__file__).resolve().parents[2]
HOME = Path.home()
CONFIG = AI_MAIN / "adapters" / "pi" / "skills.json"
OUTPUT = AI_MAIN / "build" / "pi-skills"
MANIFEST = AI_MAIN / "build" / "pi-skills-manifest.json"
EXCLUDED_PARTS = {"deprecated", "in-progress", "personal", "node_modules"}
VALID_SKILL_NAME = re.compile(r"^[a-z0-9][a-z0-9-]{0,63}$")


def frontmatter_value(text: str, key: str) -> str | None:
    match = re.match(r"^---\s*\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return None
    value = re.search(rf"^{re.escape(key)}:\s*([^\n]+)", match.group(1), re.MULTILINE)
    if not value:
        return None
    return value.group(1).strip().strip("\"'")


def discover() -> tuple[dict[str, Path], dict[str, list[str]]]:
    roots = [
        AI_MAIN / "skills",
        AI_MAIN / "external" / "9arm-skills" / "skills",
        AI_MAIN / "external" / "agent-skills" / "skills",
        AI_MAIN / "external" / "mattpocock-skills" / "skills",
        HOME / ".pi" / "agent" / "npm" / "node_modules" / "pi-subagents" / "skills",
        HOME / ".pi" / "agent" / "npm" / "node_modules" / "remote-pi" / "skills",
        HOME / ".pi" / "agent" / "npm" / "node_modules" / "pi-mcp-adapter" / "skills",
        HOME / ".agents" / "skills",
        HOME / ".pi" / "agent" / "skills",
    ]
    skills: dict[str, Path] = {}
    collisions: dict[str, list[str]] = {}
    for root in roots:
        if not root.is_dir():
            continue
        for skill_file in sorted(root.rglob("SKILL.md")):
            relative_parts = skill_file.relative_to(root).parts[:-1]
            if EXCLUDED_PARTS.intersection(relative_parts):
                continue
            try:
                text = skill_file.read_text(encoding="utf-8")
            except OSError:
                continue
            name = frontmatter_value(text, "name")
            description = frontmatter_value(text, "description")
            if not name or description is None or not VALID_SKILL_NAME.fullmatch(name):
                continue
            resolved = skill_file.resolve()
            if name in skills:
                existing = str(skills[name])
                if str(resolved) != existing:
                    collisions.setdefault(name, [existing]).append(str(resolved))
                continue
            skills[name] = resolved
    return skills, collisions


def manual_pointer(name: str, source: Path) -> str:
    return f"""---
name: {json.dumps(name)}
description: {json.dumps(f'Manually load the {name} skill.')}
disable-model-invocation: true
---

# Manual skill pointer

Read the required workflow and safety boundaries in `{source}` for this request.
Load linked references only when their stated condition applies; do not recursively read all links.
Resolve relative references against `{source.parent}` and preserve the current harness's approval and execution protocol.
"""


def main() -> int:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    auto = set(config["auto"])
    skills, collisions = discover()
    missing = sorted(auto - skills.keys())
    if missing:
        print(f"missing configured Pi auto skills: {', '.join(missing)}", file=sys.stderr)
        return 1

    shutil.rmtree(OUTPUT, ignore_errors=True)
    OUTPUT.mkdir(parents=True)
    entries = []
    for name, source in sorted(skills.items()):
        target = OUTPUT / name
        mode = "auto" if name in auto else "manual"
        if mode == "auto":
            target.symlink_to(source.parent, target_is_directory=True)
        else:
            target.mkdir()
            (target / "SKILL.md").write_text(manual_pointer(name, source), encoding="utf-8")
        entries.append({
            "name": name, "mode": mode, "source": str(source),
            "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        })

    manifest = {
        "schemaVersion": 1,
        "budgetTokens": config["budgetTokens"],
        "autoCount": sum(entry["mode"] == "auto" for entry in entries),
        "manualCount": sum(entry["mode"] == "manual" for entry in entries),
        "entries": entries,
        "collisions": collisions,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(
        f"Pi skill farm: {manifest['autoCount']} auto, "
        f"{manifest['manualCount']} manual, {len(collisions)} resolved collisions"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

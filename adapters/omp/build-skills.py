#!/usr/bin/env python3
"""Build OMP's curated skill farm without changing canonical skill sources.

Discovery is owned-first: ai-main skills, pinned external packs, ~/.agents/skills,
then native ~/.omp/agent/skills. OMP-managed skills (~/.omp/agent/managed-skills)
stay runtime-owned: they are neither scanned nor farmed here.
Backup snapshots under state/ are not a discovery root.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import sys
from collections.abc import Iterator
from pathlib import Path

AI_MAIN = Path(__file__).resolve().parents[2]
HOME = Path.home()
CONFIG = AI_MAIN / "adapters" / "omp" / "skills.json"
OUTPUT = AI_MAIN / "build" / "omp-skills"
MANIFEST = AI_MAIN / "build" / "omp-skills-manifest.json"
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


def discovery_roots() -> list[Path]:
    return [
        AI_MAIN / "skills",
        AI_MAIN / "adapters" / "omp" / "skills",
        AI_MAIN / "external" / "9arm-skills" / "skills",
        AI_MAIN / "external" / "agent-skills" / "skills",
        AI_MAIN / "external" / "mattpocock-skills" / "skills",
        HOME / ".agents" / "skills",
        HOME / ".omp" / "agent" / "skills",
    ]


def iter_skill_files(root: Path) -> Iterator[Path]:
    """Yield SKILL.md files depth-first, following directory symlinks.

    pathlib.rglob skips symlinked directories on Python >= 3.13, and
    ~/.agents/skills is itself a symlink farm, so walk explicitly with a
    resolved-path guard against cycles. Sorting keeps the walk deterministic.
    """
    seen: set[Path] = set()

    def walk(directory: Path) -> Iterator[Path]:
        resolved = directory.resolve()
        if resolved in seen:
            return
        seen.add(resolved)
        for entry in sorted(directory.iterdir(), key=lambda item: item.name):
            if entry.name == "SKILL.md" and entry.is_file():
                yield entry
                continue
            if entry.is_dir() and entry.name not in EXCLUDED_PARTS:
                yield from walk(entry)

    yield from walk(root)


def discover() -> tuple[dict[str, Path], dict[str, list[str]], list[dict[str, str]]]:
    skills: dict[str, Path] = {}
    collisions: dict[str, list[str]] = {}
    invalid: dict[str, dict[str, str]] = {}
    for root in discovery_roots():
        if not root.is_dir():
            continue
        for skill_file in iter_skill_files(root):
            resolved = skill_file.resolve()
            try:
                text = skill_file.read_text(encoding="utf-8")
            except OSError:
                invalid.setdefault(str(resolved), {"path": str(resolved), "reason": "unreadable"})
                continue
            name = frontmatter_value(text, "name")
            description = frontmatter_value(text, "description")
            if not name:
                invalid.setdefault(str(resolved), {"path": str(resolved), "reason": "missing frontmatter name"})
                continue
            if description is None:
                invalid.setdefault(str(resolved), {"path": str(resolved), "reason": "missing frontmatter description"})
                continue
            if not VALID_SKILL_NAME.fullmatch(name):
                invalid.setdefault(str(resolved), {"path": str(resolved), "reason": f"invalid skill name: {name}"})
                continue
            if name in skills:
                existing = str(skills[name])
                if str(resolved) != existing:
                    collisions.setdefault(name, [existing]).append(str(resolved))
                continue
            skills[name] = resolved
    return skills, collisions, sorted(invalid.values(), key=lambda item: item["path"])


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
    skills, collisions, invalid = discover()

    optional = set(config.get("optional", []))
    missing = sorted(auto - skills.keys())
    skipped = [name for name in missing if name in optional]
    missing = [name for name in missing if name not in optional]
    if missing:
        print(f"missing configured OMP auto skills: {', '.join(missing)}", file=sys.stderr)
        return 1
    if skipped:
        print(f"note: optional OMP auto skills not found here (provided by the runtime): {', '.join(skipped)}", file=sys.stderr)
        auto -= set(skipped)

    shutil.rmtree(OUTPUT, ignore_errors=True)
    OUTPUT.mkdir(parents=True)
    entries = []
    for name, source in sorted(skills.items()):
        target = OUTPUT / name
        mode = "auto" if name in auto else "manual"
        if mode == "auto":
            source_dir = source.parent
            # Repo-internal sources link relatively so the farm survives moving
            # the checkout; home-level sources link absolutely.
            link = os.path.relpath(source_dir, target.parent) if source_dir.is_relative_to(AI_MAIN) else str(source_dir)
            target.symlink_to(link, target_is_directory=True)
        else:
            target.mkdir()
            (target / "SKILL.md").write_text(manual_pointer(name, source), encoding="utf-8")
        entries.append({
            "name": name, "mode": mode, "source": str(source),
            "sourceSha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        })
    entries.sort(key=lambda entry: entry["name"])

    manifest = {
        "schemaVersion": 1,
        "autoCount": sum(entry["mode"] == "auto" for entry in entries),
        "manualCount": sum(entry["mode"] == "manual" for entry in entries),
        "discoveredCount": len(skills),
        "entries": entries,
        "collisions": {name: collisions[name] for name in sorted(collisions)},
        "invalid": invalid,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(
        f"OMP skill farm: {manifest['autoCount']} auto, {manifest['manualCount']} manual; "
        f"{len(collisions)} resolved collisions, {len(invalid)} invalid skipped"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

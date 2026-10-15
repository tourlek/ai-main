#!/usr/bin/env python3
"""Snapshot OMP-managed skills without writing runtime files or invoking Git."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import stat
import tempfile
from datetime import datetime, timezone
from pathlib import Path

AI_MAIN = Path(__file__).resolve().parent.parent
DEFAULT_SOURCE = Path.home() / ".omp" / "agent" / "managed-skills"
DEFAULT_ROOT = AI_MAIN / "state" / "omp-managed-skills"


def digest(files: dict) -> str:
    return hashlib.sha256(json.dumps(files, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def collect(source: Path) -> tuple[dict, dict[str, bytes]]:
    if not source.is_dir():
        raise ValueError(f"managed skills source not found: {source}")
    files, contents = {}, {}
    for path in sorted(source.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"refusing to snapshot a symlink: {path}")
        if not path.is_file():
            continue
        relative = path.relative_to(source).as_posix()
        data = path.read_bytes()
        files[relative] = {
            "sha256": hashlib.sha256(data).hexdigest(),
            "size": len(data),
            "mode": stat.S_IMODE(path.stat().st_mode),
        }
        contents[relative] = data
    return files, contents


def verify(snapshot: Path) -> dict:
    manifest = json.loads((snapshot / "manifest.json").read_text())
    files, _ = collect(snapshot / "files")
    if files != manifest["files"] or digest(files) != snapshot.name:
        raise ValueError(f"snapshot integrity mismatch: {snapshot}")
    return manifest


def backup(source: Path, root: Path, note: str | None) -> None:
    files, contents = collect(source)
    snapshot_id = digest(files)
    target = root / snapshot_id
    if target.exists():
        verify(target)
        print(f"unchanged: {snapshot_id}; {len(files)} files")
        return
    root.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".snapshot-", dir=root))
    try:
        (staging / "files").mkdir()
        for relative, data in contents.items():
            path = staging / "files" / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            path.chmod(files[relative]["mode"])
        manifest = {
            "schemaVersion": 1,
            "source": str(source.resolve()),
            "createdAt": datetime.now(timezone.utc).isoformat(),
            "note": note,
            "skills": sorted(path.split("/")[0] for path in files if path.endswith("/SKILL.md")),
            "files": files,
        }
        (staging / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        try:
            staging.rename(target)
        except FileExistsError:
            verify(target)
        print(f"snapshot: {snapshot_id}; {len(files)} files under {root}")
    finally:
        if staging.exists():
            shutil.rmtree(staging)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--note")
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--list", action="store_true")
    actions.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    try:
        if args.list or args.verify:
            snapshots = sorted(path for path in args.root.glob("*") if path.is_dir() and len(path.name) == 64)
            if args.verify and not snapshots:
                raise ValueError(f"no snapshots under {args.root}")
            for snapshot in snapshots:
                manifest = verify(snapshot) if args.verify else json.loads((snapshot / "manifest.json").read_text())
                print(f"{snapshot.name}: {len(manifest['files'])} files; {manifest['createdAt']}")
        else:
            backup(args.source, args.root, args.note)
        return 0
    except (OSError, ValueError, KeyError) as error:
        parser.exit(1, f"backup failed: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())

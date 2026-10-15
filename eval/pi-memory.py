#!/usr/bin/env python3
"""Behavioral tests for the bounded Pi memory CLI."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLI_SOURCE = ROOT / "bin" / "pi-memory"
HEADER = "# Pi Persistent Memory\n\n"
PROMPT_START = "<!-- ai-main:pi-memory:start -->"
PROMPT_END = "<!-- ai-main:pi-memory:end -->"


class PiMemoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / "ai-main"
        self.cli = self.root / "bin" / "pi-memory"
        self.store = self.root / "memory" / "pi" / "MEMORY.md"
        self.home = Path(self.temporary.name) / "home"
        self.prompt = self.home / ".pi" / "agent" / "APPEND_SYSTEM.md"
        self.cli.parent.mkdir(parents=True)
        self.store.parent.mkdir(parents=True)
        self.prompt.parent.mkdir(parents=True)
        shutil.copy2(CLI_SOURCE, self.cli)
        self.store.write_text(HEADER, encoding="utf-8")
        self.prompt.write_text(
            f"system prompt\n{PROMPT_START}\n{HEADER}{PROMPT_END}\nend\n",
            encoding="utf-8",
        )

    def run_cli(self, *arguments: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(self.cli), *arguments],
            capture_output=True,
            text=True,
            check=False,
            env=dict(os.environ, HOME=str(self.home)),
        )

    def test_add_replace_remove_update_only_prompt_memory_block(self) -> None:
        entry = "ผู้ใช้ชอบคำตอบสั้นและตรง"
        added = self.run_cli("add", entry)
        self.assertEqual(added.returncode, 0, added.stderr)
        prompt = self.prompt.read_text(encoding="utf-8")
        self.assertIn(f"{PROMPT_START}\n{HEADER}- {entry}\n{PROMPT_END}", prompt)
        self.assertIn("system prompt\n", prompt)
        self.assertTrue(prompt.endswith("end\n"))

        saved = self.store.read_text(encoding="utf-8")
        saved_prompt = prompt
        duplicate = self.run_cli("add", entry)
        self.assertEqual(duplicate.returncode, 0, duplicate.stderr)
        self.assertIn("Already saved", duplicate.stdout)
        self.assertEqual(self.store.read_text(encoding="utf-8"), saved)
        self.assertEqual(self.prompt.read_text(encoding="utf-8"), saved_prompt)

        self.assertEqual(self.run_cli("add", "ใช้ zsh กับ Homebrew").returncode, 0)
        replaced = self.run_cli("replace", "คำตอบสั้น", "ผู้ใช้ต้องการคำตอบภาษาไทยแบบกระชับ")
        self.assertEqual(replaced.returncode, 0, replaced.stderr)
        prompt = self.prompt.read_text(encoding="utf-8")
        self.assertIn("ผู้ใช้ต้องการคำตอบภาษาไทยแบบกระชับ", prompt)
        self.assertNotIn(entry, prompt)
        self.assertIn("ผู้ใช้ต้องการคำตอบภาษาไทยแบบกระชับ", self.store.read_text(encoding="utf-8"))

        removed = self.run_cli("remove", "zsh")
        self.assertEqual(removed.returncode, 0, removed.stderr)
        self.assertNotIn("zsh", self.store.read_text(encoding="utf-8"))
        self.assertNotIn("zsh", self.prompt.read_text(encoding="utf-8"))

    def test_ambiguous_match_and_missing_match_leave_store_and_prompt_unchanged(self) -> None:
        self.assertEqual(self.run_cli("add", "OHO API uses MongoDB").returncode, 0)
        self.assertEqual(self.run_cli("add", "OHO web uses Vue").returncode, 0)
        saved = self.store.read_text(encoding="utf-8")
        saved_prompt = self.prompt.read_text(encoding="utf-8")

        ambiguous = self.run_cli("remove", "OHO")
        self.assertNotEqual(ambiguous.returncode, 0)
        self.assertIn("2 entries matched", ambiguous.stderr)
        self.assertEqual(self.store.read_text(encoding="utf-8"), saved)
        self.assertEqual(self.prompt.read_text(encoding="utf-8"), saved_prompt)

        missing = self.run_cli("replace", "not present", "new fact")
        self.assertNotEqual(missing.returncode, 0)
        self.assertEqual(self.store.read_text(encoding="utf-8"), saved)
        self.assertEqual(self.prompt.read_text(encoding="utf-8"), saved_prompt)

    def test_character_limit_accepts_boundary_and_rejects_overflow(self) -> None:
        boundary_entry = "ก" * 698
        boundary = self.run_cli("add", boundary_entry)
        self.assertEqual(boundary.returncode, 0, boundary.stderr)
        self.assertIn("700/700", boundary.stdout)
        saved = self.store.read_text(encoding="utf-8")
        saved_prompt = self.prompt.read_text(encoding="utf-8")

        overflow = self.run_cli("add", "x")
        self.assertNotEqual(overflow.returncode, 0)
        self.assertIn("704/700", overflow.stderr)
        self.assertEqual(self.store.read_text(encoding="utf-8"), saved)
        self.assertEqual(self.prompt.read_text(encoding="utf-8"), saved_prompt)

    def test_missing_prompt_markers_preserve_prompt_and_report_partial_save(self) -> None:
        original = "user-owned prompt\n"
        self.prompt.write_text(original, encoding="utf-8")
        result = self.run_cli("add", "durable fact")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("memory was saved, but OMP prompt refresh failed", result.stderr)
        self.assertIn("- durable fact\n", self.store.read_text(encoding="utf-8"))
        self.assertEqual(self.prompt.read_text(encoding="utf-8"), original)

    def test_concurrent_adds_do_not_overwrite_memory_or_prompt_updates(self) -> None:
        entries = [f"Durable fact {index}" for index in range(8)]
        with ThreadPoolExecutor(max_workers=4) as executor:
            results = list(executor.map(lambda entry: self.run_cli("add", entry), entries))
        self.assertTrue(all(result.returncode == 0 for result in results))
        stored = self.store.read_text(encoding="utf-8")
        prompt = self.prompt.read_text(encoding="utf-8")
        for entry in entries:
            self.assertIn(f"- {entry}\n", stored)
            self.assertIn(entry, prompt)

if __name__ == "__main__":
    unittest.main()

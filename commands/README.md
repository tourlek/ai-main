# Shared Slash Commands

Slash commands defined here are synced by `install.sh` to:

- `~/.claude/commands/` — Claude Code
- `~/.cursor/commands/` — Cursor

Each command is a single Markdown file. The filename becomes the slash name:

```
commands/my-command.md   →   /my-command
```

## Format

Claude Code and Cursor both accept Markdown commands with YAML frontmatter. Keep them portable across both by sticking to the common fields:

```markdown
---
description: Short one-line summary shown in the command picker
---

Body of the prompt. Use $ARGUMENTS to receive whatever the user typed after the slash name.
```

Claude-specific fields like `allowed-tools`, `model`, `argument-hint` are ignored by Cursor but will not break it.

## Notes

- Codex and Gemini don't use this slash-command directory; they expose functionality through `skills/` instead.
- If a command must differ per tool, create `commands/claude/<name>.md` and `commands/cursor/<name>.md` and update `install.sh` accordingly.

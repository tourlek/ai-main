#!/usr/bin/env bash
# Cursor setup-worktree hook: link local-only agent files (not committed) into a new worktree.
set -euo pipefail
ROOT="${ROOT_WORKTREE_PATH:-$(git rev-parse --path-format=absolute --git-common-dir | sed 's#/.git$##')}"
WT="$(pwd)"
REPO="$(basename "$ROOT")"
AGENTS_SRC="/Users/tualek/ai-main/repo-agents/$REPO/docs/agents"
mkdir -p "$AGENTS_SRC" "$WT/docs"
ln -sfn "$AGENTS_SRC" "$WT/docs/agents"
for f in AGENTS.md CLAUDE.md GEMINI.md .ai .cursor/rules/ai-main-shared.mdc; do
  if [ -e "$ROOT/$f" ] && [ ! -e "$WT/$f" ]; then
    mkdir -p "$(dirname "$WT/$f")"
    ln -sfn "$ROOT/$f" "$WT/$f"
  fi
done
echo "linked agent files into $WT (repo=$REPO)"

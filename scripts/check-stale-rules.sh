#!/usr/bin/env bash
# Drift check: fail (exit 1, file:line on stdout) when live instruction text still names a retired
# tool (DeepSeek, Orca, DSH, OMP, Codex, "pi + DeepSeek") or teaches the typed "PROD ok" phrase.
# Usage: check-stale-rules.sh [root]   (default: the repo this script lives in)
# Scanned: config, skills, knowledge, core/hooks, adapters/claude, adapters/README.md, README.md, AGENTS.md.
# Not scanned: retro/, backup*/, archive/, notes/, .scratch/, build/, node_modules/, .git/, logs/, memory/,
# external/, context/ (history, generated or upstream), nor adapter deploy code (adapters/lib/deploy-common.sh
# markers must stay byte-identical). A line is allowed when it marks itself as a pointer to the retired
# tool: "retired", "legacy recognition", "unmaintained" or "archive/".
set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || exit 2

PATTERN='deepseek|\borca\b|\bdsh\b|\bomp\b|\bcodex\b|PROD[[:space:]]+ok'
ALLOW='retired|legacy recognition|unmaintained|archive/'

targets=()
for t in config skills knowledge core/hooks adapters/claude adapters/README.md README.md AGENTS.md; do
    [ -e "$t" ] && targets+=("$t")
done

hits="$(grep -rInEi "$PATTERN" "${targets[@]}" \
    --exclude-dir=retro --exclude-dir='backup*' --exclude-dir=archive --exclude-dir=notes \
    --exclude-dir=.scratch --exclude-dir=build --exclude-dir=node_modules --exclude-dir=.git \
    --exclude-dir=logs --exclude-dir=memory --exclude-dir=external --exclude-dir=context 2>/dev/null \
  | grep -viE "^[^:]+:[0-9]+:.*($ALLOW)")"

if [ -n "$hits" ]; then
    echo "stale-rules: retired-tool references in live files (fix, or move the text to archive/):" >&2
    echo "$hits" | cut -c1-200
    exit 1
fi
echo "stale-rules: clean"

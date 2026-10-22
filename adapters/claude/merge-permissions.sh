#!/usr/bin/env bash
# Union adapters/claude/settings.permissions.allow.json into settings.json permissions.allow.
#   merge-permissions.sh <settings.json> <backup dir>
# Idempotent: no write (and no backup) when every entry is already allowed. Order and other keys are kept.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/settings.permissions.allow.json"
SETTINGS="${1:?settings.json path}"
BACKUP="${2:?backup dir}"

[ -f "$SETTINGS" ] || { echo "merge-permissions: no ${SETTINGS}, skipped" >&2; exit 0; }
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
jq --indent 2 --slurpfile add "$SRC" '
  .permissions.allow = reduce $add[0][] as $p (.permissions.allow // []; if index([$p]) then . else . + [$p] end)
' "$SETTINGS" > "$TMP"
if jq -e --slurpfile a "$TMP" '. == $a[0]' "$SETTINGS" >/dev/null; then
    echo "  ✓ permissions.allow already has the ai-main entries"
    exit 0
fi
mkdir -p "$BACKUP"
cp -p "$SETTINGS" "${BACKUP}/claude_settings.json"
cat "$TMP" > "$SETTINGS" # in place: keeps mode, and writes through a symlink
echo "  ✓ permissions.allow += ai-main entries (backup: ${BACKUP}/claude_settings.json)"

#!/usr/bin/env bash
# git pre-commit hook — blocks deleting a migration/backfill script in the same change
# that removes the field it backfills.
#
# 2026-07: renaming read_by → unread_by while deleting the backfill scripts blanked every
# existing unread badge on deploy. A field being absent is not the same as it being safe to
# leave unpopulated.
#
# Bypass (when the deletion really is intended):  AIMAIN_ALLOW_DELETE_MIGRATION=1 git commit ...

set -euo pipefail
[ "${AIMAIN_BYPASS:-0}" = "1" ] && exit 0
[ "${AIMAIN_ALLOW_DELETE_MIGRATION:-0}" = "1" ] && exit 0

deleted="$(git diff --cached --name-only --diff-filter=D | grep -iE '(migrat|backfill)' || true)"
[ -n "$deleted" ] || exit 0

cat >&2 <<EOF
✗ commit blocked: this change deletes migration/backfill script(s):

$(printf '    %s\n' $deleted)

  Renaming or inverting a field that gates user-visible state (badges, counters) needs a
  backfill for documents that already exist — verify against production before removing the
  tooling that would have covered it.
  Intended: AIMAIN_ALLOW_DELETE_MIGRATION=1 git commit ...
EOF
exit 1

#!/usr/bin/env bash
# Offline check for merge-permissions.sh on a fixture (never the live settings.json).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
fail=0
ok() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }

FIRST="$(jq -r '.[0]' "$DIR/settings.permissions.allow.json")"
N="$(jq length "$DIR/settings.permissions.allow.json")"
printf '{"env":{"X":"keep"},"permissions":{"allow":["Bash(ls)","%s"],"deny":["Bash(rm)"]},"hooks":{}}\n' "$FIRST" > "$T/s.json"
chmod 600 "$T/s.json"

"$DIR/merge-permissions.sh" "$T/s.json" "$T/b1" >/dev/null
ok "adds missing entries once" '[ "$(jq ".permissions.allow | length" "$T/s.json")" -eq $((N + 1)) ]'
ok "keeps existing order first" '[ "$(jq -r ".permissions.allow[0]" "$T/s.json")" = "Bash(ls)" ]'
ok "keeps env, deny, hooks" 'jq -e ".env.X == \"keep\" and .permissions.deny == [\"Bash(rm)\"] and .hooks == {}" "$T/s.json" >/dev/null'
ok "backs up the original" 'jq -e ".permissions.allow | length == 2" "$T/b1/claude_settings.json" >/dev/null'
ok "keeps file mode" '[ "$(stat -f %Lp "$T/s.json")" = 600 ]'

"$DIR/merge-permissions.sh" "$T/s.json" "$T/b2" >/dev/null
ok "second run: no change, no backup" '[ ! -e "$T/b2" ] && [ "$(jq ".permissions.allow | length" "$T/s.json")" -eq $((N + 1)) ]'

echo '{}' > "$T/empty.json"
"$DIR/merge-permissions.sh" "$T/empty.json" "$T/b3" >/dev/null
ok "no permissions key: created" '[ "$(jq ".permissions.allow | length" "$T/empty.json")" -eq "$N" ]'
ok "missing settings: skipped" '"$DIR/merge-permissions.sh" "$T/none.json" "$T/b4" 2>/dev/null && [ ! -e "$T/none.json" ]'
exit $fail

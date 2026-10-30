#!/usr/bin/env bash
# Test for check-stale-rules.sh on a temp tree: clean passes, planted stale lines fail with file:line.
#   bash scripts/test-check-stale-rules.sh
set -uo pipefail
CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check-stale-rules.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/config" "$T/skills/x" "$T/archive"
printf 'Implement = Sonnet in T3.\nOrca/OMP (retired 2026-10): see archive/x\n' > "$T/config/workflow.md"
printf 'DeepSeek DSH Orca\n' > "$T/archive/old.md"   # archive is never scanned
fail=0
expect() { # <label> <want exit> <grep pattern on output, or ''>
  local out rc; out="$(bash "$CHECK" "$T" 2>&1)"; rc=$?
  if [ "$rc" -eq "$2" ] && { [ -z "$3" ] || grep -q -- "$3" <<<"$out"; }; then echo "PASS $1"
  else echo "FAIL $1 (rc=$rc): $out"; fail=1; fi
}
expect "clean tree passes (retired pointer + archive ignored)" 0 ""
echo 'implementer = pi + DeepSeek' >> "$T/skills/x/SKILL.md"
expect "planted pi + DeepSeek caught with file:line" 1 '^skills/x/SKILL.md:1:'
rm "$T/skills/x/SKILL.md"
echo 'ask for the PROD  ok phrase' >> "$T/config/workflow.md"
expect "planted typed PROD phrase caught" 1 '^config/workflow.md:3:'
sed -i.bak '$d' "$T/config/workflow.md"; rm -f "$T/config/workflow.md.bak"
expect "plant removed -> clean again" 0 ""
exit "$fail"

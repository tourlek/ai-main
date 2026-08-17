#!/usr/bin/env bash
#
# Prompt regression suite.
#
# Every rule that survives in a profile, and every rule that was deliberately removed from
# the prompt because a check now enforces it, is asserted here. Editing the sources is cheap;
# silently dropping a rule while editing them is what this catches.
#
#   ./eval/run.sh            # assertions only, no model calls
#
# Exit 0 = clean. This is what to run after touching config/*.md, memory/lessons/*, or
# core/checks/*.

set -uo pipefail
AI_MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${AI_MAIN}/build"
CHECKS="${AI_MAIN}/core/checks"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}✓${NC} $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}✗${NC} $1"; }

# assert_in <tier> <pattern> <label>
assert_in() {
    if grep -qF -- "$2" "${BUILD}/$1/SYSTEM.md" 2>/dev/null; then pass "[$1] $3"; else fail "[$1] $3 — not found in the $1 profile"; fi
}
# assert_not_in <tier> <pattern> <label>
assert_not_in() {
    if grep -qF -- "$2" "${BUILD}/$1/SYSTEM.md" 2>/dev/null; then fail "[$1] $3 — should NOT be in the $1 profile"; else pass "[$1] $3"; fi
}
# assert_denied <command> <label>   /  assert_allowed <command> <label>
assert_denied() {
    if "${CHECKS}/git-guard.sh" "$1" >/dev/null 2>&1; then fail "guard allowed: $1 ($2)"; else pass "guard denies: $1"; fi
}
assert_allowed() {
    if "${CHECKS}/git-guard.sh" "$1" >/dev/null 2>&1; then pass "guard allows: $1"; else fail "guard denied: $1 ($2)"; fi
}

echo -e "${BLUE}${BOLD}1) Profiles build and stay under their ceiling${NC}"
"${AI_MAIN}/bin/aimain" build >/dev/null 2>&1
while read -r tier tokens budget; do
    if [ "$tokens" = "-" ]; then fail "profile $tier was not built"
    elif [ "$tokens" -le "$budget" ]; then pass "profile $tier ~${tokens} tokens (ceiling ${budget})"
    else fail "profile $tier ~${tokens} tokens exceeds ceiling ${budget}"
    fi
done < <("${AI_MAIN}/bin/aimain" budget)

echo -e "\n${BLUE}${BOLD}2) The min profile carries the rules a 7B still has to obey${NC}"
assert_in min "Never commit without explicit authorization" "commit authorization"
assert_in min "stay inside that repo" "scope discipline"
assert_in min "Only revert when the user asks" "no unasked reverts"
assert_in min "Don't change test files" "hands off tests"
assert_in min "actually ran" "evidence honesty"
assert_in min "Confirm the target branch and worktree" "branch/worktree confirmation"

echo -e "\n${BLUE}${BOLD}3) The min profile drops what a small model cannot use${NC}"
assert_not_in min "Banned patterns" "Thai style examples"
assert_not_in min "codegraph explore" "code-search ladder"
assert_not_in min "Primary workspaces" "workspace inventory"

echo -e "\n${BLUE}${BOLD}4) The lean profile adds working method, not narrative${NC}"
assert_in lean "ast-grep" "code-search ladder"
assert_in lean "-F json" "glab flag"
assert_in lean "preserve existing UI, function, and feature behavior" "migration preservation"
assert_not_in lean "5–10 Codex sessions/day" "usage narrative"

echo -e "\n${BLUE}${BOLD}5) Rules removed from the prompt are enforced by a check${NC}"
assert_not_in full "Co-Authored-By" "AI attribution rule left the prompt"
grep -q 'co-authored-by' "${CHECKS}/commit-msg-lint.sh" && pass "…and commit-msg-lint.sh enforces it" || fail "commit-msg-lint.sh lost the attribution pattern"
grep -q 'json' "${CHECKS}/shims/glab" && pass "glab shim rewrites --json" || fail "glab shim lost the rewrite"

echo -e "\n${BLUE}${BOLD}6) git-guard classifies the commands that caused real incidents${NC}"
assert_denied "git reset --hard origin/main"        "destroys parallel-session work"
assert_denied "git clean -fd"                       "same"
assert_denied "git push --force origin feat"        "force push"
assert_denied "git branch --set-upstream-to=origin/feat" "implicit branch target"
assert_denied "git commit -m 'x'"                   "unauthorized commit"
assert_allowed "git status"                         "read-only"
assert_allowed "git diff v1.112.0 v1.113.0"         "release tag diff"
assert_allowed "rg unread_by src/"                  "not a git command"

echo -e "\n${BLUE}${BOLD}7) Every profile is free of tier markers${NC}"
for tier in full lean min; do
    if grep -q '<!--\(min\|lean\)-->' "${BUILD}/${tier}/SYSTEM.md" 2>/dev/null; then
        fail "profile ${tier} still contains tier markers"
    else
        pass "profile ${tier} is marker-free"
    fi
done

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ${PASS} assertions passed${NC}"
    exit 0
fi
echo -e "${RED}${BOLD}❌ ${FAIL} failed, ${PASS} passed${NC}"
exit 1

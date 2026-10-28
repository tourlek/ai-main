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

RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { PASS=$((PASS + 1)); echo -e "  ${GREEN}✓${NC} $1"; }
fail() { FAIL=$((FAIL + 1)); echo -e "  ${RED}✗${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

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

# Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/adapters/omp
echo -e "${BLUE}${BOLD}1) Profiles build and stay under their ceiling${NC}"
if ! "${AI_MAIN}/bin/aimain" build >/dev/null 2>&1; then
    fail "profile/skill build failed"
fi
while read -r tier tokens budget; do
    if [ "$tokens" = "-" ]; then fail "profile $tier was not built"
    elif [ "$tokens" -le "$budget" ]; then pass "profile $tier ~${tokens} tokens (ceiling ${budget})"
    else warn "profile $tier ~${tokens} tokens exceeds ceiling ${budget} (warning only)"
    fi
done < <("${AI_MAIN}/bin/aimain" budget)

echo -e "\n${BLUE}${BOLD}2) Every profile preserves equivalent safety and scope gates${NC}"
for tier in full; do
    assert_in "$tier" "Never commit without explicit authorization" "commit authorization"
    assert_in "$tier" "stay inside that repo" "scope discipline"
    assert_in "$tier" "Only revert when the user asks" "no unasked reverts"
    assert_in "$tier" "Don't change test files" "hands off tests"
    assert_in "$tier" "actually ran" "evidence honesty"
    assert_in "$tier" "Confirm the target branch and worktree" "branch/worktree confirmation"
    assert_in "$tier" "restricted (non-admin) account" "permission validation"
    assert_in "$tier" "Read-only/chat-only" "no incidental writes"
    assert_in "$tier" "applicable ancestor and nested instructions" "folder-scoped instructions"
    assert_in "$tier" "finish the approved steps without asking again" "continuation"
done

echo -e "\n${BLUE}${BOLD}2b) Every profile points curated memory to Obsidian${NC}"
for tier in full; do
    assert_in "$tier" "Project rules and corrections live in native auto memory" "native auto memory is the rules source"
    assert_in "$tier" "for prior-work recall" "Obsidian prior-work recall pointer"
    assert_in "$tier" "AI Memory/Home.md" "indexed prior-work recall"
done

echo -e "\n${BLUE}${BOLD}3) Rules removed from the prompt are enforced by a check${NC}"
assert_not_in full "Co-Authored-By" "AI attribution rule left the prompt"
grep -q 'co-authored-by' "${CHECKS}/commit-msg-lint.sh" && pass "…and commit-msg-lint.sh enforces it" || fail "commit-msg-lint.sh lost the attribution pattern"
grep -q 'json' "${CHECKS}/shims/glab" && pass "glab shim rewrites --json" || fail "glab shim lost the rewrite"

echo -e "\n${BLUE}${BOLD}4) git-guard classifies the commands that caused real incidents${NC}"
assert_denied "git reset --hard origin/main"        "destroys parallel-session work"
assert_denied "git clean -fd"                       "same"
assert_denied "git push --force origin feat"        "force push"
assert_denied "git branch --set-upstream-to=origin/feat" "implicit branch target"
assert_denied "git commit -m 'x'"                   "unauthorized commit"
assert_allowed "git status"                         "read-only"
assert_allowed "git diff v1.112.0 v1.113.0"         "release tag diff"
assert_allowed "rg unread_by src/"                  "not a git command"

echo -e "\n${BLUE}${BOLD}5) Every profile is free of tier markers${NC}"
for tier in full; do
    if grep -q '<!--\(min\|lean\)-->' "${BUILD}/${tier}/SYSTEM.md" 2>/dev/null; then
        fail "profile ${tier} still contains tier markers"
    else
        pass "profile ${tier} is marker-free"
    fi
done

echo -e "\n${BLUE}${BOLD}6) Scoped deployment and skill regressions (isolated fixtures)${NC}"
if python3 -B "${AI_MAIN}/eval/shared-brain.py"; then
    pass "shared-brain regressions"
else
    fail "shared-brain regressions"
fi

echo -e "\n${BLUE}${BOLD}7) Harness selection: no default harness, scoped adapters (isolated HOME)${NC}"
if python3 -B "${AI_MAIN}/eval/harness-dispatch.py"; then
    pass "harness dispatch regressions"
else
    fail "harness dispatch regressions"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ ${PASS} assertions passed${NC}"
    exit 0
fi
echo -e "${RED}${BOLD}❌ ${FAIL} failed, ${PASS} passed${NC}"
exit 1

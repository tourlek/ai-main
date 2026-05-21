#!/usr/bin/env bash

# Deep verification that every AI tool will actually load the ai-main configs.
# - Resolves all @-imports inside each entry file
# - Checks each import target exists and (when symlinked) points back into ai-main
# - Diffs shared files against the canonical source in ai-main/config/
# - Lists installed skills per tool
# - Computes the actual auto-loaded byte/token estimate

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ACTUAL_HOME="${HOME:-/Users/$(whoami)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "${CYAN}${BOLD}       🔍 AI-MAIN VERIFICATION — DEEP CHECK         ${NC}"
echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "Repo:  ${BOLD}${SCRIPT_DIR}${NC}"
echo -e "Home:  ${BOLD}${ACTUAL_HOME}${NC}"

# ----- helpers -----
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
bad()  { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL+1)); }

check_symlink_into_repo() {
    local path="$1"
    if [ ! -L "$path" ]; then
        bad "$path is not a symlink"
        return
    fi
    local target
    target="$(readlink "$path")"
    if [[ "$target" != "${SCRIPT_DIR}"* ]]; then
        bad "$path → $target (not pointing into ai-main!)"
        return
    fi
    if [ ! -e "$path" ]; then
        bad "$path → $target (broken symlink)"
        return
    fi
    ok "$path → $(echo "$target" | sed "s|${SCRIPT_DIR}|ai-main|")"
}

check_file_matches_canonical() {
    local installed="$1"
    local canonical="$2"
    if [ ! -e "$installed" ]; then
        bad "$installed missing"
        return
    fi
    if ! diff -q "$installed" "$canonical" >/dev/null 2>&1; then
        bad "$installed DRIFTED from canonical $canonical"
        diff -u "$canonical" "$installed" | head -20 | sed 's/^/      /'
        return
    fi
    ok "$installed == $(echo "$canonical" | sed "s|${SCRIPT_DIR}|ai-main|")"
}

# Parse @-imports from an entry file, resolve each, check existence
follow_imports() {
    local entry="$1"
    if [ ! -f "$entry" ]; then
        bad "$entry missing"
        return
    fi
    ok "Entry file present: $entry"
    local n=0
    while IFS= read -r imp; do
        n=$((n+1))
        if [ ! -e "$imp" ]; then
            bad "  @-import broken: $imp"
        else
            local resolved
            resolved="$(readlink -f "$imp" 2>/dev/null || echo "$imp")"
            if [[ "$resolved" == "${SCRIPT_DIR}"* ]]; then
                ok "  @-import OK: $imp → ai-main${resolved#${SCRIPT_DIR}}"
            elif [[ "$imp" == *RTK*.md ]]; then
                # RTK files are copies, not symlinks — that's expected
                ok "  @-import OK (copied file): $imp"
            else
                warn "  @-import resolves outside ai-main: $imp → $resolved"
            fi
        fi
    done < <(grep -E '^@' "$entry" | sed 's/^@//')
    if [ "$n" -eq 0 ]; then
        warn "  No @-imports found in $entry"
    fi
}

# ----- 1. Entry files + @-imports -----
echo -e "\n${BLUE}${BOLD}1) Entry files and @-imports${NC}"
echo -e "${CYAN}--- Claude Code (~/.claude/CLAUDE.md) ---${NC}"
follow_imports "${ACTUAL_HOME}/.claude/CLAUDE.md"
echo -e "${CYAN}--- Codex (~/.codex/AGENTS.md) ---${NC}"
follow_imports "${ACTUAL_HOME}/.codex/AGENTS.md"
echo -e "${CYAN}--- Gemini (~/.gemini/GEMINI.md) ---${NC}"
follow_imports "${ACTUAL_HOME}/.gemini/GEMINI.md"

# ----- 2. Shared files point at canonical ai-main sources -----
echo -e "\n${BLUE}${BOLD}2) Shared configs point at canonical sources${NC}"
for tool in claude codex gemini; do
    echo -e "${CYAN}--- $tool ---${NC}"
    for f in style.md workflow.md profile.md; do
        check_symlink_into_repo "${ACTUAL_HOME}/.${tool}/shared/${f}"
    done
done

# ----- 3. RTK files content matches canonical -----
echo -e "\n${BLUE}${BOLD}3) RTK files match canonical (these are copies, so drift is possible)${NC}"
check_file_matches_canonical "${ACTUAL_HOME}/.claude/RTK.md" "${SCRIPT_DIR}/config/RTK.md"
check_file_matches_canonical "${ACTUAL_HOME}/.codex/RTK.md"  "${SCRIPT_DIR}/config/RTK.manual.md"
check_file_matches_canonical "${ACTUAL_HOME}/.gemini/RTK.md" "${SCRIPT_DIR}/config/RTK.manual.md"

# ----- 4. Skills present per tool -----
echo -e "\n${BLUE}${BOLD}4) Skills installed per tool${NC}"
expected_owned=(gitlab-mr-description gitlab-mr-comment-reply git-commit-helper branch-perf-compare)
for tool in claude codex cursor gemini; do
    dir="${ACTUAL_HOME}/.${tool}/skills"
    echo -e "${CYAN}--- ~/.$tool/skills ---${NC}"
    if [ ! -d "$dir" ]; then
        bad "$dir missing"; continue
    fi
    count=$(find "$dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -not -name '.system' -not -name 'codex-primary-runtime' | wc -l | tr -d ' ')
    ok "$count skills present in $dir"
    for owned in "${expected_owned[@]}"; do
        if [ -e "${dir}/${owned}" ]; then
            ok "  owned: ${owned}"
        else
            bad "  owned MISSING: ${owned}"
        fi
    done
done

# ----- 5. Auto-loaded payload size summary -----
echo -e "\n${BLUE}${BOLD}5) Auto-loaded payload (entry + @-imports only)${NC}"
total_bytes_per_tool() {
    local entry="$1"
    [ -f "$entry" ] || { echo 0; return; }
    local sum
    sum=$(wc -c < "$entry")
    while IFS= read -r imp; do
        if [ -e "$imp" ]; then
            sum=$((sum + $(wc -c < "$imp")))
        fi
    done < <(grep -E '^@' "$entry" | sed 's/^@//')
    echo "$sum"
}
for tool in claude codex gemini; do
    case "$tool" in
        claude) entry_name="CLAUDE.md" ;;
        codex)  entry_name="AGENTS.md" ;;
        gemini) entry_name="GEMINI.md" ;;
    esac
    entry="${ACTUAL_HOME}/.${tool}/${entry_name}"
    bytes=$(total_bytes_per_tool "$entry")
    tokens=$(( bytes / 4 ))  # rough English-heavy approximation
    ok "$tool: ${bytes} bytes  ~${tokens} tokens (rough)"
done

# ----- 6. Final verdict -----
echo ""
echo -e "${CYAN}${BOLD}======================================================${NC}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ All checks passed — every tool should load ai-main configs correctly.${NC}"
else
    echo -e "${RED}${BOLD}❌ ${FAIL} check(s) failed — see above.${NC}"
fi
echo -e "${CYAN}${BOLD}======================================================${NC}"

echo -e "\n${YELLOW}Next: behavioral check.${NC} Paste the prompts in ${BOLD}scripts/canary-prompts.md${NC} into each tool and confirm the responses follow the rules in config/style.md and config/workflow.md."

exit $FAIL

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
        # Entry files are compiled (imports inlined) — verify known section headers instead
        case "$(basename "$entry")" in
            CLAUDE.md|AGENTS.md|GEMINI.md)
                if grep -q "User Profile & Environment" "$entry" && grep -q "Working Rules" "$entry" \
                   && grep -q "Shared Cross-Tool Memory" "$entry" && grep -q "Lessons" "$entry"; then
                    ok "  Compiled successfully (profile, workflow, shared memory, lessons all inlined)"
                else
                    bad "  Compiled but missing expected section headers in $entry"
                fi
                ;;
            *)
                warn "  No @-imports found in $entry"
                ;;
        esac
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
expected_owned=(gitlab-mr-description gitlab-mr-comment-reply git-commit-helper branch-perf-compare self-learning worklog)
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

# ----- 5b. Claude Desktop workspace symlinks & config -----
echo -e "\n${BLUE}${BOLD}5b) Claude Desktop integration & Workspaces${NC}"
PRIMARY_WORKSPACES=(
    "${ACTUAL_HOME}/ohochat"
    "${ACTUAL_HOME}/ohochat/oho-web-app"
    "${ACTUAL_HOME}/ohochat/oho-api"
    "${ACTUAL_HOME}/ohochat/oho-developer-api"
    "${ACTUAL_HOME}/ohochat/oho-backoffice"
    "${ACTUAL_HOME}/ohochat/oho-webhook"
    "${ACTUAL_HOME}/ohochat/oho-flutter-mobile"
    "${ACTUAL_HOME}/ohochat/script-oho"
    "${ACTUAL_HOME}/Documents/migrant-labor-crm"
    "${ACTUAL_HOME}/thaivagroups/vetrisync-cms"
    "${ACTUAL_HOME}/ohochat/jeraspec-api"
)
for workspace in "${PRIMARY_WORKSPACES[@]}"; do
    [ -d "$workspace" ] || continue
    kname="$(basename "$workspace")"
    if [ ! -f "${SCRIPT_DIR}/knowledge/${kname}.md" ]; then
        warn "No knowledge/${kname}.md for $workspace"
        continue
    fi
    ws_file="${workspace}/AGENTS.md"
    if [ -f "$ws_file" ] && head -1 "$ws_file" | grep -qF "generated by ai-main"; then
        ok "Workspace knowledge OK: $ws_file (generated from knowledge/${kname}.md)"
    else
        bad "Workspace knowledge MISSING or unmanaged: $ws_file"
    fi
    for alias_name in CLAUDE.md GEMINI.md; do
        alias_link="${workspace}/${alias_name}"
        if [ -L "$alias_link" ] && [ "$(readlink "$alias_link")" = "AGENTS.md" ]; then
            ok "  alias OK: ${alias_name} → AGENTS.md"
        elif git -C "$workspace" ls-files --error-unmatch "$alias_name" >/dev/null 2>&1; then
            warn "  alias skipped (repo-committed file wins): $alias_link"
        else
            bad "  alias WRONG or missing: $alias_link (expected symlink to AGENTS.md)"
        fi
    done
done

CLAUDE_CONFIG_FILE="${ACTUAL_HOME}/Library/Application Support/Claude/claude_desktop_config.json"
if [ -f "$CLAUDE_CONFIG_FILE" ]; then
    ok "Claude Desktop config file present: $CLAUDE_CONFIG_FILE"
    # Verify that localAgentModeTrustedFolders has our primary directories
    for folder in "${SCRIPT_DIR}" "${ACTUAL_HOME}/ohochat" "${ACTUAL_HOME}/Documents/migrant-labor-crm" "${ACTUAL_HOME}/thaivagroups/vetrisync-cms"; do
        if jq -e --arg folder "$folder" '.preferences.localAgentModeTrustedFolders | contains([$folder])' "$CLAUDE_CONFIG_FILE" >/dev/null; then
            ok "  Trusted folder present: $folder"
        else
            bad "  Trusted folder MISSING: $folder"
        fi
    done
else
    warn "Claude Desktop config file not found (Claude Desktop may not be installed): $CLAUDE_CONFIG_FILE"
fi

# ----- 5c. Memory, self-learning, sync automation -----
echo -e "\n${BLUE}${BOLD}5c) Memory, lessons, worklog & sync automation${NC}"
check_symlink_into_repo "${ACTUAL_HOME}/.ai-memory"
check_symlink_into_repo "${ACTUAL_HOME}/.codex/memories"
for mem_src in "${SCRIPT_DIR}"/memory/claude/*/; do
    [ -d "$mem_src" ] || continue
    slug="$(basename "${mem_src%/}")"
    check_symlink_into_repo "${ACTUAL_HOME}/.claude/projects/${slug}/memory"
done
[ -f "${SCRIPT_DIR}/memory/SHARED.md" ] && ok "memory/SHARED.md present" || bad "memory/SHARED.md missing"
[ -f "${SCRIPT_DIR}/memory/lessons/LESSONS.md" ] && ok "memory/lessons/LESSONS.md present" || bad "memory/lessons/LESSONS.md missing"
[ -x "${SCRIPT_DIR}/scripts/sync.sh" ] && ok "scripts/sync.sh executable" || bad "scripts/sync.sh missing or not executable"

GLOBAL_IGNORE="$(git config --global core.excludesFile 2>/dev/null || true)"
GLOBAL_IGNORE="${GLOBAL_IGNORE/#\~/$ACTUAL_HOME}"
[ -z "$GLOBAL_IGNORE" ] && GLOBAL_IGNORE="${ACTUAL_HOME}/.config/git/ignore"
for ignore_entry in CLAUDE.md AGENTS.md GEMINI.md; do
    if [ -f "$GLOBAL_IGNORE" ] && grep -qxF "$ignore_entry" "$GLOBAL_IGNORE"; then
        ok "global gitignore has: $ignore_entry"
    else
        bad "global gitignore MISSING: $ignore_entry (in $GLOBAL_IGNORE)"
    fi
done

CLAUDE_SETTINGS="${ACTUAL_HOME}/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ] && jq -e '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains("ai-main/scripts/sync.sh"))] | length > 0' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
    ok "Claude Code SessionStart sync hook wired"
else
    bad "Claude Code SessionStart sync hook MISSING in $CLAUDE_SETTINGS"
fi

PLIST="${ACTUAL_HOME}/Library/LaunchAgents/com.tualek.ai-main-sync.plist"
if [ -f "$PLIST" ]; then
    if launchctl print "gui/$(id -u)/com.tualek.ai-main-sync" >/dev/null 2>&1; then
        ok "launchd sync job loaded (every 6h)"
    else
        warn "launchd plist present but not loaded: $PLIST"
    fi
else
    bad "launchd plist missing: $PLIST"
fi

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

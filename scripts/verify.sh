#!/usr/bin/env bash

# Deep verification that the selected harnesses will actually load the ai-main configs.
# Usage: verify.sh [--harness <id>[,<id>...]]   (default: config/harnesses.local; ids:
#        codex, extra, legacy; dsh and omp are retired). With no selection only repo-level checks run.
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

# ----- harness selection (same ids as install.sh; no default harness) -----
SELECTED=()
if [ "${1:-}" = "--harness" ]; then
    IFS=, read -ra SELECTED <<< "${2:-}"
elif [ -f "${SCRIPT_DIR}/config/harnesses.local" ]; then
    while read -r id; do
        [ -n "$id" ] && SELECTED+=("$id")
    done < <(sed 's/#.*//' "${SCRIPT_DIR}/config/harnesses.local" | tr ', \t' '\n\n\n\n')
fi
want() { local h; for h in ${SELECTED[@]+"${SELECTED[@]}"}; do [ "$h" = "$1" ] && return 0; done; return 1; }

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
            CLAUDE.md|AGENTS.md|GEMINI.md|APPEND_SYSTEM.md)
                if grep -q "User Profile & Environment" "$entry" && grep -q "Working Rules" "$entry" \
                   && grep -q "Shared Cross-Tool Memory" "$entry" && grep -q "Rules earned from mistakes" "$entry"; then
                    ok "  Compiled successfully (profile, workflow, shared memory, rules all inlined)"
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

# ----- legacy all-harness checks (Claude/Gemini/Cursor/Codex entries) -----
if want legacy; then

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
check_file_matches_canonical "${ACTUAL_HOME}/.claude/RTK.md" "${SCRIPT_DIR}/adapters/claude/RTK.md"
check_file_matches_canonical "${ACTUAL_HOME}/.codex/RTK.md"  "${SCRIPT_DIR}/config/RTK.manual.md"
check_file_matches_canonical "${ACTUAL_HOME}/.gemini/RTK.md" "${SCRIPT_DIR}/config/RTK.manual.md"

# ----- 4. Skills present per tool -----
echo -e "\n${BLUE}${BOLD}4) Skills installed per tool${NC}"
expected_owned=()
for skill_dir in "${SCRIPT_DIR}"/skills/*/; do
    [ -f "${skill_dir}SKILL.md" ] || continue
    expected_owned+=("$(basename "${skill_dir%/}")")
done
for tool in claude codex cursor gemini; do
    dir="${ACTUAL_HOME}/.${tool}/skills"
    echo -e "${CYAN}--- ~/.$tool/skills ---${NC}"
    if [ ! -d "$dir" ]; then
        bad "$dir missing"; continue
    fi
    count=$(find "$dir" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) -not -name '.system' -not -name 'codex-primary-runtime' | wc -l | tr -d ' ')
    ok "$count skills present in $dir"
    for owned in "${expected_owned[@]}"; do
        if [ ! -f "${dir}/${owned}/SKILL.md" ]; then
            bad "  owned MISSING: ${owned}"
        elif cmp -s "${dir}/${owned}/SKILL.md" "${SCRIPT_DIR}/skills/${owned}/SKILL.md"; then
            ok "  owned source matches: ${owned}"
        elif [ "$owned" = "gitlab-mr-description" ] && \
             grep -qF "${ACTUAL_HOME}/.ai-skills/gitlab-mr-description/SKILL.md" "${dir}/${owned}/SKILL.md"; then
            ok "  owned redirect: ${owned}"
        else
            bad "  owned DRIFTED or shadowed by another pack: ${owned}"
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
        claude) entry_name="CLAUDE.md"; entry="${ACTUAL_HOME}/.${tool}/${entry_name}" ;;
        codex)  entry_name="AGENTS.md"; entry="${ACTUAL_HOME}/.${tool}/${entry_name}" ;;
        gemini) entry_name="GEMINI.md"; entry="${ACTUAL_HOME}/.${tool}/${entry_name}" ;;
    esac
    bytes=$(total_bytes_per_tool "$entry")
    tokens=$(( bytes / 4 ))  # rough English-heavy approximation
    ok "$tool: ${bytes} bytes  ~${tokens} tokens (rough)"
done

fi # legacy

# ----- 5a. Prompt profile budget: a single shared ceiling, reported as a warning only
# (the build runs from launchd every 6h and a prompt growing slightly must not brick it).
echo -e "\n${BLUE}${BOLD}5a) Prompt profile budgets${NC}"
if [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    while read -r tier tokens budget; do
        if [ "$tokens" = "-" ]; then
            bad "profile ${tier} was never built — run ./bin/aimain build"
        elif [ "$tokens" -le "$budget" ]; then
            ok "profile ${tier}: ~${tokens} tokens (ceiling ${budget})"
        else
            warn "profile ${tier}: ~${tokens} tokens exceeds its ${budget} ceiling"
        fi
    done < <("${SCRIPT_DIR}/bin/aimain" budget)
fi
if want legacy; then

# ----- 5aa. Shared MCP base -----
echo -e "\n${BLUE}${BOLD}5aa) MCP configuration${NC}"
MCP_CONFIG="${ACTUAL_HOME}/.config/mcp/mcp.json"
if jq -e '.["$comment"] == "generated by ai-main — edit ai-main/config/mcp.json.template"' "$MCP_CONFIG" >/dev/null 2>&1; then
    ok "shared MCP config is ai-main-managed and valid JSON"
else
    bad "shared MCP config missing, invalid, or unmanaged: $MCP_CONFIG"
fi
if jq -e '.mcpServers.codegraph.command == "codegraph" and (.mcpServers.obsidian.args | index("obsidian-mcp@2.0.1")) != null' "$MCP_CONFIG" >/dev/null 2>&1; then
    ok "CodeGraph uses PATH and Obsidian MCP is pinned"
else
    bad "shared MCP server commands drifted from config/mcp.json.template"
fi
if jq -e '.mcpServers.obsidian.approveTools | contains(["obsidian_move_note", "obsidian_delete_note"])' "$MCP_CONFIG" >/dev/null 2>&1; then
    ok "Obsidian move/delete require approval"
else
    bad "Obsidian destructive-tool approvals missing"
fi
if rg -q -- '--autostash' "${SCRIPT_DIR}/scripts/sync.sh"; then
    bad "scripts/sync.sh still uses git autostash"
else
    ok "startup sync never autostashes"
fi

# ----- 5b. Claude Desktop workspace symlinks & config -----
echo -e "\n${BLUE}${BOLD}5b) Claude Desktop integration & Workspaces${NC}"
# Workspace list comes from the registry (config/workspaces.json), not a second hardcoded copy
REGISTRY_FILE="${SCRIPT_DIR}/config/workspaces.json"
PRIMARY_WORKSPACES=()
WORKSPACE_KNOWLEDGE=()
if [ -f "$REGISTRY_FILE" ]; then
    while IFS=$'\t' read -r ws_path ws_knowledge; do
        PRIMARY_WORKSPACES+=("${ws_path//\{\{HOME\}\}/$ACTUAL_HOME}")
        WORKSPACE_KNOWLEDGE+=("$ws_knowledge")
    done < <(jq -r '.workspaces[] | [.path, (.knowledge // "")] | @tsv' "$REGISTRY_FILE")
else
    bad "Workspace registry missing: $REGISTRY_FILE"
fi
for ((i = 0; i < ${#PRIMARY_WORKSPACES[@]}; i++)); do
    workspace="${PRIMARY_WORKSPACES[$i]}"
    # A registered path that does not exist on this machine is expected — the registry is
    # shared across machines. A registered path whose knowledge file is missing is not.
    [ -d "$workspace" ] || continue
    kname="${WORKSPACE_KNOWLEDGE[$i]}"
    [ -n "$kname" ] || kname="_generic"
    if [ ! -f "${SCRIPT_DIR}/knowledge/${kname}.md" ]; then
        bad "Registered workspace $workspace points at a missing knowledge/${kname}.md"
        continue
    fi
    cursor_rule="${workspace}/.cursor/rules/ai-main-shared.mdc"
    if [ -f "$cursor_rule" ] && grep -qxF '<!-- generated by ai-main — shared Cursor baseline -->' "$cursor_rule"; then
        if grep -qxF 'alwaysApply: true' "$cursor_rule" && grep -qF 'Never commit without explicit authorization' "$cursor_rule"; then
            ok "Cursor project baseline: $cursor_rule"
        else
            bad "Cursor project baseline incomplete: $cursor_rule"
        fi
    elif [ -e "$cursor_rule" ] || [ -L "$cursor_rule" ]; then
        warn "Cursor local rule preserved; manual integration required: $cursor_rule"
    else
        bad "Cursor project baseline missing: $cursor_rule"
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
        elif [ -e "$alias_link" ] || [ -L "$alias_link" ]; then
            warn "  local instructions preserved; verify native loading/precedence: $alias_link"
        else
            bad "  alias WRONG or missing: $alias_link (expected symlink to AGENTS.md)"
        fi
    done
done

CLAUDE_CONFIG_FILE="${ACTUAL_HOME}/Library/Application Support/Claude/claude_desktop_config.json"
if [ -f "$CLAUDE_CONFIG_FILE" ]; then
    ok "Claude Desktop config file present: $CLAUDE_CONFIG_FILE"
    # Verify that localAgentModeTrustedFolders has our primary directories
    for folder in "${SCRIPT_DIR}" "${PRIMARY_WORKSPACES[@]}"; do
        [ -d "$folder" ] || continue
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
        warn "legacy global ignore can hide nested team instructions: $ignore_entry (preserved in $GLOBAL_IGNORE)"
    fi
done

CAVEMAN_CONFIG="${ACTUAL_HOME}/.config/caveman/config.json"
if jq -e '.defaultMode == "off"' "$CAVEMAN_CONFIG" >/dev/null 2>&1; then
    ok "Caveman startup default is off"
else
    bad "Caveman startup default is not off: $CAVEMAN_CONFIG"
fi
if [ -n "${CAVEMAN_DEFAULT_MODE:-}" ] && [ "$CAVEMAN_DEFAULT_MODE" != "off" ]; then
    warn "CAVEMAN_DEFAULT_MODE overrides explicit-only startup policy in this environment"
fi

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

fi # legacy

# Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/adapters/omp
if want omp; then
    warn "selected harness omp is retired; installed-file checks skipped"
fi

# ----- 5e. Codex adapter -----
if want codex; then
    echo -e "\n${BLUE}${BOLD}5e) Codex adapter${NC}"
    CODEX_MARKER="$(sed -n 's/^CODEX_MARKER="\(.*\)"$/\1/p' "${SCRIPT_DIR}/adapters/lib/deploy-common.sh")"
    if [ -f "${ACTUAL_HOME}/.codex/AGENTS.md" ] && grep -qxF "$CODEX_MARKER" "${ACTUAL_HOME}/.codex/AGENTS.md"; then
        ok "Codex entry is ai-main-managed: ${ACTUAL_HOME}/.codex/AGENTS.md"
    else
        bad "Codex entry missing or unmanaged: ${ACTUAL_HOME}/.codex/AGENTS.md"
    fi
fi
[ "${#SELECTED[@]}" -gt 0 ] || warn "no harness selected (config/harnesses.local or --harness): installed-file checks skipped"

# ----- 6. Final verdict -----
echo ""
echo -e "${CYAN}${BOLD}======================================================${NC}"
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✅ Installed-file checks passed (warnings and live model validation remain separate).${NC}"
else
    echo -e "${RED}${BOLD}❌ ${FAIL} check(s) failed — see above.${NC}"
fi
echo -e "${CYAN}${BOLD}======================================================${NC}"

echo -e "\n${YELLOW}Next: behavioral check.${NC} Paste the prompts in ${BOLD}scripts/canary-prompts.md${NC} into each tool and confirm the responses follow the rules in config/style.md and config/workflow.md."

exit $FAIL

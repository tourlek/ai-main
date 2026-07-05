#!/usr/bin/env bash

# Centralized AI Configuration & Shared Skills Installation Script
# Supports: Gemini, Claude Code, Cursor, Codex

set -euo pipefail

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}======================================================${NC}"
echo -e "${CYAN}${BOLD}       🤖 AI-MAIN GLOBAL SYNC & CONFIG INSTALLER     ${NC}"
echo -e "${CYAN}${BOLD}======================================================${NC}"

# 1. Detect Active User Home Directory
ACTUAL_HOME="${HOME:-/Users/$(whoami)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${ACTUAL_HOME}/.ai-backup-$(date +%Y%m%d_%H%M%S)"

# --sync: fast redeploy mode used by scripts/sync.sh — skips brew/submodules/backups,
# Claude Desktop config, settings.json hook merge, and launchd (one-time setup steps).
SYNC_MODE=0
for arg in "$@"; do
    [ "$arg" = "--sync" ] && SYNC_MODE=1
done

echo -e "${BLUE}Detected Home Folder:${NC} ${BOLD}${ACTUAL_HOME}${NC}"
echo -e "${BLUE}Active Sync Folder:${NC}  ${BOLD}${SCRIPT_DIR}${NC}"
echo -e "${BLUE}Backup Folder Location:${NC} ${BOLD}${BACKUP_DIR}${NC}"
echo ""

# 1.5 Bootstrap CLI dependencies (rtk, glab)
echo -e "${BLUE}🔧 Checking CLI dependencies...${NC}"
ensure_brew_pkg() {
    local pkg="$1"
    local bin="${2:-$1}"
    if command -v "$bin" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ ${bin} already installed ($(command -v "$bin"))${NC}"
        return 0
    fi
    if ! command -v brew >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠ ${bin} not found and Homebrew is unavailable — install ${pkg} manually${NC}"
        return 0
    fi
    echo -e "  ${YELLOW}→ Installing ${pkg} via Homebrew...${NC}"
    if brew install "$pkg"; then
        echo -e "  ${GREEN}✓ ${pkg} installed${NC}"
    else
        echo -e "  ${RED}✗ brew install ${pkg} failed — continuing without it${NC}"
    fi
}
if [ "$SYNC_MODE" -eq 0 ]; then
    ensure_brew_pkg rtk
    ensure_brew_pkg glab
fi

# 2. Initialize / update git submodules (9arm-skills)
if [ "$SYNC_MODE" -eq 0 ] && [ -f "${SCRIPT_DIR}/.gitmodules" ] && [ -d "${SCRIPT_DIR}/.git" ]; then
    echo -e "${BLUE}📦 Syncing git submodules (9arm-skills, ...)...${NC}"
    (cd "${SCRIPT_DIR}" && git submodule update --init --recursive --remote --quiet) || \
        echo -e "  ${YELLOW}⚠ submodule sync failed — continuing with current state${NC}"
fi

# Ensure target directories exist
mkdir -p "${ACTUAL_HOME}/.gemini/skills"
mkdir -p "${ACTUAL_HOME}/.gemini/shared"
mkdir -p "${ACTUAL_HOME}/.claude/skills"
mkdir -p "${ACTUAL_HOME}/.claude/commands"
mkdir -p "${ACTUAL_HOME}/.claude/shared"
mkdir -p "${ACTUAL_HOME}/.cursor/skills"
mkdir -p "${ACTUAL_HOME}/.cursor/commands"
mkdir -p "${ACTUAL_HOME}/.codex/skills"
mkdir -p "${ACTUAL_HOME}/.codex/shared"
mkdir -p "${ACTUAL_HOME}/.agents/skills"

# 3. Automated Backups
backup_if_exists() {
    local target_path="$1"
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        local parent_clean
        parent_clean=$(echo "$target_path" | sed "s|${ACTUAL_HOME}/||g" | sed 's|/|_|g' | sed 's|^\.||g')
        mkdir -p "$BACKUP_DIR"
        echo -e "  - Backing up: ${target_path} -> ${BACKUP_DIR}/${parent_clean}"
        mv "$target_path" "${BACKUP_DIR}/${parent_clean}"
    fi
}

if [ "$SYNC_MODE" -eq 0 ]; then
    echo -e "\n${YELLOW}📦 Backing up existing configurations...${NC}"
    backup_if_exists "${ACTUAL_HOME}/.ai-skills"
    backup_if_exists "${ACTUAL_HOME}/.gemini/GEMINI.md"
    backup_if_exists "${ACTUAL_HOME}/.gemini/RTK.md"
    backup_if_exists "${ACTUAL_HOME}/.claude/CLAUDE.md"
    backup_if_exists "${ACTUAL_HOME}/.claude/RTK.md"
    backup_if_exists "${ACTUAL_HOME}/.codex/AGENTS.md"
    backup_if_exists "${ACTUAL_HOME}/.codex/RTK.md"
    backup_if_exists "${ACTUAL_HOME}/.cursor/skills/gitlab-mr-description"
    backup_if_exists "${ACTUAL_HOME}/.codex/skills/gitlab-mr-description"
    backup_if_exists "${ACTUAL_HOME}/.gemini/skills/gitlab-mr-description"
    backup_if_exists "${ACTUAL_HOME}/.claude/skills/gitlab-mr-description"
fi

# 4. Link central shared-skills folder
echo -e "\n${BLUE}🔗 Linking shared skills folder...${NC}"
ln -sfn "${SCRIPT_DIR}/skills" "${ACTUAL_HOME}/.ai-skills"
echo -e "  ${GREEN}✓ ~/.ai-skills -> ${SCRIPT_DIR}/skills${NC}"

# 5. Template helpers ({{HOME}} and {{AI_MAIN}} placeholders; @-imports are inlined)
expand_placeholders() {
    # stdin -> stdout
    sed -e "s|{{HOME}}|${ACTUAL_HOME}|g" -e "s|{{AI_MAIN}}|${SCRIPT_DIR}|g"
}

generate_from_template() {
    local template_path="$1"
    local output_path="$2"
    echo -e "  - Generating: ${output_path}"
    expand_placeholders < "$template_path" > "$output_path"
}

compile_template() {
    # Inline every `@<path>` line so tools without import support (Codex, Cursor,
    # Claude Desktop) still get the full content. Re-run via sync.sh to propagate edits.
    local template_path="$1"
    local output_path="$2"
    echo -e "  - Compiling: ${output_path}"
    local temp_file
    temp_file=$(mktemp)

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^@ ]]; then
            local import_path="${line#@}"
            import_path="${import_path//\{\{HOME\}\}/$ACTUAL_HOME}"
            import_path="${import_path//\{\{AI_MAIN\}\}/$SCRIPT_DIR}"
            if [ -f "$import_path" ]; then
                cat "$import_path" >> "$temp_file"
                echo "" >> "$temp_file"
            else
                # Fallback to the in-repo copy if it hasn't been linked into place yet
                local base_name
                base_name=$(basename "$import_path")
                if [ -f "${SCRIPT_DIR}/config/${base_name}" ]; then
                    cat "${SCRIPT_DIR}/config/${base_name}" >> "$temp_file"
                    echo "" >> "$temp_file"
                elif [ -f "${SCRIPT_DIR}/memory/${base_name}" ]; then
                    cat "${SCRIPT_DIR}/memory/${base_name}" >> "$temp_file"
                    echo "" >> "$temp_file"
                else
                    echo -e "${RED}⚠ Warning: Import file not found: $import_path${NC}"
                    echo "# Broken Import: $line" >> "$temp_file"
                fi
            fi
        else
            echo "$line" | expand_placeholders >> "$temp_file"
        fi
    done < "$template_path"

    mv "$temp_file" "$output_path"
}

# 6. Sync RTK rule files (Claude gets hook-aware version; Codex/Gemini get manual-prefix version)
echo -e "\n${BLUE}🦀 Syncing RTK rules...${NC}"
copy_file() {
    local src="$1"
    local dst="$2"
    echo -e "  - Copying: ${src#${SCRIPT_DIR}/} -> ${dst}"
    cp -f "$src" "$dst"
}

copy_file "${SCRIPT_DIR}/config/RTK.md"        "${ACTUAL_HOME}/.claude/RTK.md"
copy_file "${SCRIPT_DIR}/config/RTK.manual.md" "${ACTUAL_HOME}/.codex/RTK.md"
copy_file "${SCRIPT_DIR}/config/RTK.manual.md" "${ACTUAL_HOME}/.gemini/RTK.md"

# 6b. Sync shared style / workflow / profile (symlinked so edits in ai-main propagate live)
echo -e "\n${BLUE}🪞 Linking shared style/workflow/profile into each tool...${NC}"
for shared_file in style.md workflow.md profile.md; do
    src="${SCRIPT_DIR}/config/${shared_file}"
    for tool_shared_dir in "${ACTUAL_HOME}/.claude/shared" "${ACTUAL_HOME}/.codex/shared" "${ACTUAL_HOME}/.gemini/shared"; do
        ln -sfn "$src" "${tool_shared_dir}/${shared_file}"
    done
    echo -e "  ${GREEN}✓ ${shared_file} → claude/codex/gemini shared/${NC}"
done

# 6c. Link canonical memory (repo is source of truth; ~/.ai-memory is the stable alias)
echo -e "\n${BLUE}🧠 Linking shared memory...${NC}"
mkdir -p "${SCRIPT_DIR}/memory/claude" "${SCRIPT_DIR}/memory/codex" "${SCRIPT_DIR}/memory/lessons"
ln -sfn "${SCRIPT_DIR}/memory" "${ACTUAL_HOME}/.ai-memory"
echo -e "  ${GREEN}✓ ~/.ai-memory -> ${SCRIPT_DIR}/memory${NC}"

# Codex: whole memories dir lives in the repo
if [ -e "${ACTUAL_HOME}/.codex/memories" ] && [ ! -L "${ACTUAL_HOME}/.codex/memories" ]; then
    # Adopt pre-existing local memories into the repo, then link back
    if [ -z "$(ls -A "${SCRIPT_DIR}/memory/codex" 2>/dev/null)" ]; then
        echo -e "  - Adopting existing ~/.codex/memories into repo"
        cp -R "${ACTUAL_HOME}/.codex/memories/." "${SCRIPT_DIR}/memory/codex/"
        rm -rf "${SCRIPT_DIR}/memory/codex/.git"
    fi
    backup_if_exists "${ACTUAL_HOME}/.codex/memories"
fi
ln -sfn "${SCRIPT_DIR}/memory/codex" "${ACTUAL_HOME}/.codex/memories"
echo -e "  ${GREEN}✓ ~/.codex/memories -> memory/codex${NC}"

# Claude: adopt any local project memory dirs not yet in the repo
for proj_dir in "${ACTUAL_HOME}"/.claude/projects/*/; do
    [ -d "$proj_dir" ] || continue
    mem_dir="${proj_dir}memory"
    slug="$(basename "${proj_dir%/}")"
    if [ -d "$mem_dir" ] && [ ! -L "$mem_dir" ]; then
        if [ ! -d "${SCRIPT_DIR}/memory/claude/${slug}" ]; then
            echo -e "  - Adopting Claude memory: ${slug}"
            mv "$mem_dir" "${SCRIPT_DIR}/memory/claude/${slug}"
        else
            backup_if_exists "$mem_dir"
        fi
    fi
done
# Link every repo-held Claude project memory back into place
for mem_src in "${SCRIPT_DIR}"/memory/claude/*/; do
    [ -d "$mem_src" ] || continue
    slug="$(basename "${mem_src%/}")"
    mkdir -p "${ACTUAL_HOME}/.claude/projects/${slug}"
    ln -sfn "${mem_src%/}" "${ACTUAL_HOME}/.claude/projects/${slug}/memory"
done
echo -e "  ${GREEN}✓ Claude project memories linked${NC}"

# 6d. Compile per-tool entry files (after RTK/shared/memory are in place)
echo -e "\n${BLUE}⚙️ Compiling personalized configurations from templates...${NC}"
compile_template "${SCRIPT_DIR}/config/CLAUDE.md.template" "${ACTUAL_HOME}/.claude/CLAUDE.md"
compile_template "${SCRIPT_DIR}/config/AGENTS.md.template" "${ACTUAL_HOME}/.codex/AGENTS.md"
compile_template "${SCRIPT_DIR}/config/GEMINI.md.template" "${ACTUAL_HOME}/.gemini/GEMINI.md"

# 7. Redirect skills for tools that need an in-tree SKILL.md (Claude, Gemini)
echo -e "\n${BLUE}🔄 Creating redirect pointer files for Claude & Gemini skills...${NC}"
mkdir -p "${ACTUAL_HOME}/.gemini/skills/gitlab-mr-description"
mkdir -p "${ACTUAL_HOME}/.claude/skills/gitlab-mr-description"
generate_from_template "${SCRIPT_DIR}/redirects/gemini/gitlab-mr-description/SKILL.md.template" "${ACTUAL_HOME}/.gemini/skills/gitlab-mr-description/SKILL.md"
generate_from_template "${SCRIPT_DIR}/redirects/claude/gitlab-mr-description/SKILL.md.template" "${ACTUAL_HOME}/.claude/skills/gitlab-mr-description/SKILL.md"

# 8. Direct symlinks for IDE & Codex (they follow symlinks fine)
echo -e "\n${BLUE}🎯 Symlinking gitlab-mr-description directly for Cursor & Codex...${NC}"
ln -sfn "${SCRIPT_DIR}/skills/gitlab-mr-description" "${ACTUAL_HOME}/.cursor/skills/gitlab-mr-description"
echo -e "  ${GREEN}✓ ~/.cursor/skills/gitlab-mr-description${NC}"
ln -sfn "${SCRIPT_DIR}/skills/gitlab-mr-description" "${ACTUAL_HOME}/.codex/skills/gitlab-mr-description"
echo -e "  ${GREEN}✓ ~/.codex/skills/gitlab-mr-description${NC}"
ln -sfn "${SCRIPT_DIR}/skills/gitlab-mr-description" "${ACTUAL_HOME}/.agents/skills/gitlab-mr-description"
echo -e "  ${GREEN}✓ ~/.agents/skills/gitlab-mr-description (Antigravity)${NC}"

# 8b. Direct-symlink every other owned skill in ai-main/skills/ to all four tools
echo -e "\n${BLUE}🧩 Linking other owned skills (ai-main/skills/*) to all AI tools...${NC}"
for skill_dir in "${SCRIPT_DIR}"/skills/*/; do
    name="$(basename "${skill_dir%/}")"
    # gitlab-mr-description is handled above via the redirect pattern
    if [ "$name" = "gitlab-mr-description" ]; then
        continue
    fi
    if [ ! -f "${skill_dir}/SKILL.md" ]; then
        continue
    fi
    for tool_skills in "${ACTUAL_HOME}/.claude/skills" "${ACTUAL_HOME}/.codex/skills" "${ACTUAL_HOME}/.cursor/skills" "${ACTUAL_HOME}/.gemini/skills" "${ACTUAL_HOME}/.agents/skills"; do
        target="${tool_skills}/${name}"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            rm -rf "$target"
        fi
        ln -sfn "${skill_dir%/}" "$target"
    done
    echo -e "  ${GREEN}✓ linked ${name}${NC}"
done

# 9. Sync external skill packs (9arm-skills, vercel-labs/agent-skills) to all four tools
TOOL_SKILL_DIRS=(
    "${ACTUAL_HOME}/.claude/skills"
    "${ACTUAL_HOME}/.codex/skills"
    "${ACTUAL_HOME}/.cursor/skills"
    "${ACTUAL_HOME}/.gemini/skills"
    "${ACTUAL_HOME}/.agents/skills"    # Antigravity (agy) global skills
)

link_external_pack() {
    local pack_label="$1"
    local pack_dir="$2"

    if [ ! -d "${pack_dir}/skills" ]; then
        echo -e "\n${YELLOW}⚠ ${pack_dir} not found. Run 'git submodule update --init' to fetch ${pack_label}.${NC}"
        return 0
    fi

    echo -e "\n${BLUE}📦 Linking ${pack_label} (shippable only) to all AI tools...${NC}"
    while IFS= read -r -d '' skill_md; do
        local src name target tool_dir
        src="$(dirname "$skill_md")"
        name="$(basename "$src")"
        # Don't overwrite our centrally-managed gitlab-mr-description
        if [ "$name" = "gitlab-mr-description" ]; then
            continue
        fi
        for tool_dir in "${TOOL_SKILL_DIRS[@]}"; do
            target="${tool_dir}/${name}"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                rm -rf "$target"
            fi
            ln -sfn "$src" "$target"
        done
        echo -e "  ${GREEN}✓ linked ${name}${NC}"
    done < <(find "${pack_dir}/skills" -name SKILL.md \
        -not -path '*/node_modules/*' \
        -not -path '*/deprecated/*' \
        -not -path '*/in-progress/*' \
        -not -path '*/personal/*' \
        -print0)
}

link_external_pack "9arm-skills"             "${SCRIPT_DIR}/external/9arm-skills"
link_external_pack "vercel-labs/agent-skills" "${SCRIPT_DIR}/external/agent-skills"

# 10. Sync slash commands (Claude + Cursor)
if [ -d "${SCRIPT_DIR}/commands" ]; then
    echo -e "\n${BLUE}⌨️  Syncing slash commands for Claude & Cursor...${NC}"
    for tool_cmd_dir in "${ACTUAL_HOME}/.claude/commands" "${ACTUAL_HOME}/.cursor/commands"; do
        while IFS= read -r -d '' cmd_file; do
            name="$(basename "$cmd_file")"
            # Skip the index README itself
            if [ "$name" = "README.md" ]; then
                continue
            fi
            ln -sfn "$cmd_file" "${tool_cmd_dir}/${name}"
        done < <(find "${SCRIPT_DIR}/commands" -maxdepth 1 -type f -name '*.md' -print0)
    done
    echo -e "  ${GREEN}✓ commands linked into ~/.claude/commands and ~/.cursor/commands${NC}"
fi

# 10b. Deploy CLAUDE.md to primary workspaces (for Claude Desktop Local Agent Mode & other editors)
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

# Each workspace gets ONE compiled knowledge file (AGENTS.md) plus CLAUDE.md/GEMINI.md
# symlinks to it. Global rules already load from ~/.claude etc. — workspace files carry
# repo-specific knowledge ONLY, so nothing is loaded twice.
KNOWLEDGE_MARKER="<!-- generated by ai-main install.sh — edit ai-main/knowledge/ instead -->"

echo -e "\n${BLUE}📚 Deploying per-repo knowledge to primary workspaces...${NC}"
for workspace in "${PRIMARY_WORKSPACES[@]}"; do
    [ -d "$workspace" ] || continue
    kname="$(basename "$workspace")"
    ksrc="${SCRIPT_DIR}/knowledge/${kname}.md"
    if [ ! -f "$ksrc" ]; then
        echo -e "  ${YELLOW}⚠ no knowledge/${kname}.md — skipping ${workspace}${NC}"
        continue
    fi
    target="${workspace}/AGENTS.md"
    # Never touch a file the workspace's own git tracks (a team-committed AGENTS.md)
    if git -C "$workspace" ls-files --error-unmatch AGENTS.md >/dev/null 2>&1; then
        echo -e "  ${YELLOW}⚠ ${target} is tracked by that repo's git — skipped${NC}"
        continue
    fi
    # Protect a hand-written AGENTS.md: only overwrite our own output
    if [ -f "$target" ] && [ ! -L "$target" ] && ! head -1 "$target" | grep -qF "generated by ai-main"; then
        if [ "$SYNC_MODE" -eq 1 ]; then
            echo -e "  ${YELLOW}⚠ ${target} is not ai-main-managed — skipped (sync mode)${NC}"
            continue
        fi
        backup_if_exists "$target"
    fi
    # Old design symlinked workspace CLAUDE.md → ~/.claude/CLAUDE.md (double-loaded global
    # config); replace any such symlink with a link to the knowledge file instead.
    temp_k=$(mktemp)
    echo "$KNOWLEDGE_MARKER" > "$temp_k"
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^@ ]]; then
            import_path="${line#@}"
            import_path="${import_path//\{\{HOME\}\}/$ACTUAL_HOME}"
            import_path="${import_path//\{\{AI_MAIN\}\}/$SCRIPT_DIR}"
            if [ -f "$import_path" ]; then
                cat "$import_path" >> "$temp_k"
                echo "" >> "$temp_k"
            else
                echo -e "  ${RED}⚠ knowledge import not found: $import_path${NC}"
            fi
        else
            echo "$line" | expand_placeholders >> "$temp_k"
        fi
    done < "$ksrc"
    if [ -L "$target" ]; then rm -f "$target"; fi
    mv "$temp_k" "$target"
    for alias_name in CLAUDE.md GEMINI.md; do
        alias_path="${workspace}/${alias_name}"
        if git -C "$workspace" ls-files --error-unmatch "$alias_name" >/dev/null 2>&1; then
            echo -e "  ${YELLOW}⚠ ${alias_path} is tracked by that repo's git — skipped${NC}"
            continue
        fi
        if [ -f "$alias_path" ] && [ ! -L "$alias_path" ] && ! head -1 "$alias_path" | grep -qF "generated by ai-main"; then
            [ "$SYNC_MODE" -eq 1 ] && continue
            backup_if_exists "$alias_path"
        fi
        ln -sfn "AGENTS.md" "$alias_path"
    done
    echo -e "  ${GREEN}✓${NC} ${workspace}/AGENTS.md (+CLAUDE.md, GEMINI.md) <- knowledge/${kname}.md"
done

# 10c. Configure Claude Desktop app (Local Agent Mode Trusted Folders)
CLAUDE_CONFIG_DIR="${ACTUAL_HOME}/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"

if [ "$SYNC_MODE" -eq 0 ] && [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "\n${BLUE}🖥️  Configuring Claude Desktop app (Local Agent Mode)...${NC}"
    
    TRUSTED_FOLDERS=(
        "${SCRIPT_DIR}"
        "${ACTUAL_HOME}/ohochat"
        "${ACTUAL_HOME}/Documents/migrant-labor-crm"
        "${ACTUAL_HOME}/thaivagroups/vetrisync-cms"
    )
    
    # Prepare backup target
    parent_clean=$(echo "$CLAUDE_CONFIG_FILE" | sed "s|${ACTUAL_HOME}/||g" | sed 's|/|_|g' | sed 's|^\.||g')
    backup_target="${BACKUP_DIR}/${parent_clean}"
    
    # Back up the file
    backup_if_exists "$CLAUDE_CONFIG_FILE"
    
    # If the backup file exists, use it as source; otherwise initialize a default config
    if [ -s "$backup_target" ]; then
        src_file="$backup_target"
    else
        src_file=$(mktemp)
        echo '{"preferences":{"localAgentModeTrustedFolders":[]}}' > "$src_file"
    fi
    
    temp_json=$(mktemp)
    folders_json=$(printf '%s\n' "${TRUSTED_FOLDERS[@]}" | jq -R . | jq -s .)
    
    jq --argjson new_folders "$folders_json" '
        if .preferences == null then .preferences = {} else . end |
        if .preferences.localAgentModeTrustedFolders == null then .preferences.localAgentModeTrustedFolders = [] else . end |
        .preferences.localAgentModeTrustedFolders = (.preferences.localAgentModeTrustedFolders + $new_folders | unique)
    ' "$src_file" > "$temp_json"
    
    mv "$temp_json" "$CLAUDE_CONFIG_FILE"
    echo -e "  ${GREEN}✓${NC} Trusted folders updated in ${CLAUDE_CONFIG_FILE}"
    echo -e "  Current trusted folders:"
    jq -r '.preferences.localAgentModeTrustedFolders[] | "    - \(. )"' "$CLAUDE_CONFIG_FILE"
fi

# 10d. Global gitignore — deployed AGENTS.md/CLAUDE.md/GEMINI.md must never land in work repos
echo -e "\n${BLUE}🙈 Ensuring global gitignore entries...${NC}"
GLOBAL_IGNORE="$(git config --global core.excludesFile 2>/dev/null || true)"
GLOBAL_IGNORE="${GLOBAL_IGNORE/#\~/$ACTUAL_HOME}"
if [ -z "$GLOBAL_IGNORE" ]; then
    GLOBAL_IGNORE="${ACTUAL_HOME}/.config/git/ignore"
fi
mkdir -p "$(dirname "$GLOBAL_IGNORE")"
touch "$GLOBAL_IGNORE"
for ignore_entry in CLAUDE.md AGENTS.md GEMINI.md CLAUDE.local.md; do
    if ! grep -qxF "$ignore_entry" "$GLOBAL_IGNORE"; then
        echo "$ignore_entry" >> "$GLOBAL_IGNORE"
        echo -e "  ${GREEN}✓ added ${ignore_entry}${NC}"
    fi
done
echo -e "  ${GREEN}✓ global ignore: ${GLOBAL_IGNORE}${NC} (use 'git add -f' if a repo should track one)"

# 10e. Claude Code SessionStart hook — pull latest ai-main at session start
if [ "$SYNC_MODE" -eq 0 ] && command -v jq >/dev/null 2>&1; then
    echo -e "\n${BLUE}🪝 Wiring Claude Code SessionStart sync hook...${NC}"
    CLAUDE_SETTINGS="${ACTUAL_HOME}/.claude/settings.json"
    [ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
    SYNC_CMD="${SCRIPT_DIR}/scripts/sync.sh --pull-only --quiet"
    if jq -e '[.hooks.SessionStart[]?.hooks[]? | select(.command | contains("ai-main/scripts/sync.sh"))] | length > 0' "$CLAUDE_SETTINGS" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ hook already present${NC}"
    else
        temp_settings=$(mktemp)
        jq --arg cmd "$SYNC_CMD" '
            .hooks = (.hooks // {}) |
            .hooks.SessionStart = ((.hooks.SessionStart // []) + [{"hooks":[{"type":"command","command":$cmd}]}])
        ' "$CLAUDE_SETTINGS" > "$temp_settings" && mv "$temp_settings" "$CLAUDE_SETTINGS"
        echo -e "  ${GREEN}✓ SessionStart hook added to ${CLAUDE_SETTINGS}${NC}"
    fi
fi

# 10f. launchd — full sync (pull + auto-commit memory/logs + push) every 6 hours
if [ "$SYNC_MODE" -eq 0 ] && [ "$(uname)" = "Darwin" ]; then
    echo -e "\n${BLUE}⏰ Installing launchd sync job (every 6h)...${NC}"
    chmod +x "${SCRIPT_DIR}/scripts/sync.sh"
    PLIST_DST="${ACTUAL_HOME}/Library/LaunchAgents/com.tualek.ai-main-sync.plist"
    mkdir -p "$(dirname "$PLIST_DST")"
    generate_from_template "${SCRIPT_DIR}/config/launchd/com.tualek.ai-main-sync.plist.template" "$PLIST_DST"
    launchctl bootout "gui/$(id -u)/com.tualek.ai-main-sync" 2>/dev/null || true
    if launchctl bootstrap "gui/$(id -u)" "$PLIST_DST" 2>/dev/null || launchctl load -w "$PLIST_DST" 2>/dev/null; then
        echo -e "  ${GREEN}✓ com.tualek.ai-main-sync loaded${NC}"
    else
        echo -e "  ${YELLOW}⚠ launchctl load failed — run manually: launchctl bootstrap gui/\$(id -u) ${PLIST_DST}${NC}"
    fi
fi

# 11. Verification
echo -e "\n${BLUE}🔍 Verifying installation...${NC}"
verify_link() {
    local link="$1"
    if [ -L "$link" ] && [ -e "$link" ]; then
        echo -e "  ${GREEN}✓${NC} $link"
    elif [ -f "$link" ]; then
        echo -e "  ${GREEN}✓${NC} $link (file)"
    else
        echo -e "  ${RED}✗${NC} $link missing or broken"
    fi
}

echo -e "\n${BLUE}🔍 Verifying workspace knowledge files...${NC}"
for workspace in "${PRIMARY_WORKSPACES[@]}"; do
    if [ -d "$workspace" ] && [ -f "${SCRIPT_DIR}/knowledge/$(basename "$workspace").md" ]; then
        verify_link "${workspace}/AGENTS.md"
        verify_link "${workspace}/CLAUDE.md"
        verify_link "${workspace}/GEMINI.md"
    fi
done

verify_link "${ACTUAL_HOME}/.ai-skills"
verify_link "${ACTUAL_HOME}/.ai-memory"
verify_link "${ACTUAL_HOME}/.codex/memories"
verify_link "${ACTUAL_HOME}/.claude/skills/self-learning"
verify_link "${ACTUAL_HOME}/.claude/skills/worklog"
verify_link "${ACTUAL_HOME}/.claude/CLAUDE.md"
verify_link "${ACTUAL_HOME}/.claude/RTK.md"
verify_link "${ACTUAL_HOME}/.claude/shared/style.md"
verify_link "${ACTUAL_HOME}/.claude/shared/workflow.md"
verify_link "${ACTUAL_HOME}/.claude/shared/profile.md"
verify_link "${ACTUAL_HOME}/.gemini/GEMINI.md"
verify_link "${ACTUAL_HOME}/.gemini/RTK.md"
verify_link "${ACTUAL_HOME}/.gemini/shared/style.md"
verify_link "${ACTUAL_HOME}/.codex/AGENTS.md"
verify_link "${ACTUAL_HOME}/.codex/RTK.md"
verify_link "${ACTUAL_HOME}/.codex/shared/style.md"
verify_link "${ACTUAL_HOME}/.cursor/skills/gitlab-mr-description"
verify_link "${ACTUAL_HOME}/.codex/skills/gitlab-mr-description"
verify_link "${ACTUAL_HOME}/.claude/skills/git-commit-helper"
verify_link "${ACTUAL_HOME}/.claude/skills/branch-perf-compare"
verify_link "${ACTUAL_HOME}/.claude/skills/gitlab-mr-comment-reply"

# 12. Summary
echo -e "\n${GREEN}${BOLD}🎉 INSTALLATION SUCCESSFUL!${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"
echo -e "Configs managed centrally in: ${BOLD}${SCRIPT_DIR}${NC}"
echo -e "Backups saved to:             ${BOLD}${BACKUP_DIR}${NC}"
echo -e "To sync a new device, clone this repo and run: ${BOLD}./install.sh${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"

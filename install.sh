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
ensure_brew_pkg rtk
ensure_brew_pkg glab

# 2. Initialize / update git submodules (9arm-skills)
if [ -f "${SCRIPT_DIR}/.gitmodules" ] && [ -d "${SCRIPT_DIR}/.git" ]; then
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

# 3. Automated Backups
echo -e "\n${YELLOW}📦 Backing up existing configurations...${NC}"
mkdir -p "$BACKUP_DIR"

backup_if_exists() {
    local target_path="$1"
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        local parent_clean
        parent_clean=$(echo "$target_path" | sed "s|${ACTUAL_HOME}/||g" | sed 's|/|_|g' | sed 's|^\.||g')
        echo -e "  - Backing up: ${target_path} -> ${BACKUP_DIR}/${parent_clean}"
        mv "$target_path" "${BACKUP_DIR}/${parent_clean}"
    fi
}

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

# 4. Link central shared-skills folder
echo -e "\n${BLUE}🔗 Linking shared skills folder...${NC}"
ln -sfn "${SCRIPT_DIR}/skills" "${ACTUAL_HOME}/.ai-skills"
echo -e "  ${GREEN}✓ ~/.ai-skills -> ${SCRIPT_DIR}/skills${NC}"

# 5. Generate rule configs from templates
echo -e "\n${BLUE}⚙️ Generating personalized configurations from templates...${NC}"

generate_from_template() {
    local template_path="$1"
    local output_path="$2"
    echo -e "  - Generating: ${output_path}"
    sed "s|{{HOME}}|${ACTUAL_HOME}|g" "$template_path" > "$output_path"
}

generate_from_template "${SCRIPT_DIR}/config/GEMINI.md.template" "${ACTUAL_HOME}/.gemini/GEMINI.md"
generate_from_template "${SCRIPT_DIR}/config/CLAUDE.md.template" "${ACTUAL_HOME}/.claude/CLAUDE.md"
generate_from_template "${SCRIPT_DIR}/config/AGENTS.md.template" "${ACTUAL_HOME}/.codex/AGENTS.md"

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
    for tool_skills in "${ACTUAL_HOME}/.claude/skills" "${ACTUAL_HOME}/.codex/skills" "${ACTUAL_HOME}/.cursor/skills" "${ACTUAL_HOME}/.gemini/skills"; do
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

verify_link "${ACTUAL_HOME}/.ai-skills"
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

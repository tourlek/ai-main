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

# Scoped OMP-first dispatch (default). Everything below is the LEGACY
# all-harness installer (Gemini/Claude/Cursor/Codex/Pi/...) and is opt-in only:
#   ./install.sh --legacy
# Default and `--sync` invocations run scripts/deploy-omp.sh instead, which
# touches only OMP-owned destinations.
_LEGACY_DISPATCH=0
for _dispatch_arg in "$@"; do
    [ "$_dispatch_arg" = "--legacy" ] && _LEGACY_DISPATCH=1
done
if [ "$_LEGACY_DISPATCH" -eq 0 ]; then
    case "${1:-}" in
        --help|-h) exec "${SCRIPT_DIR}/scripts/deploy-omp.sh" "$@" ;;
    esac
    "${SCRIPT_DIR}/bin/aimain" build
    exec "${SCRIPT_DIR}/scripts/deploy-omp.sh" "$@"
fi

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
mkdir -p "${ACTUAL_HOME}/.cursor/rules"
mkdir -p "${ACTUAL_HOME}/.codex/skills"
mkdir -p "${ACTUAL_HOME}/.codex/shared"
mkdir -p "${ACTUAL_HOME}/.agents/skills"
mkdir -p "${ACTUAL_HOME}/.pi/agent/skills"
mkdir -p "${ACTUAL_HOME}/.pi/agent/shared"
mkdir -p "${ACTUAL_HOME}/.pi/agent/bin"
mkdir -p "${ACTUAL_HOME}/.config/mcp"

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
    backup_if_exists "${ACTUAL_HOME}/.pi/agent/APPEND_SYSTEM.md"
    backup_if_exists "${ACTUAL_HOME}/.pi/agent/RTK.md"
    backup_if_exists "${ACTUAL_HOME}/.config/mcp/mcp.json"
    PI_MCP_OVERRIDE="${ACTUAL_HOME}/.pi/agent/mcp.json"
    if [ -f "$PI_MCP_OVERRIDE" ]; then
        if jq -e '((.mcpServers.obsidian.args // []) | index("obsidian-mcp@2")) != null or ((.mcpServers.codegraph.command // "") | startswith("/"))' "$PI_MCP_OVERRIDE" >/dev/null 2>&1; then
            backup_if_exists "$PI_MCP_OVERRIDE"
            echo -e "  ${YELLOW}Migrated legacy Pi MCP base; ~/.pi/agent/mcp.json is now reserved for overrides.${NC}"
        else
            echo -e "  ${YELLOW}Preserving Pi-specific MCP overrides: ${PI_MCP_OVERRIDE}${NC}"
        fi
    fi
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
copy_file "${SCRIPT_DIR}/config/RTK.manual.md" "${ACTUAL_HOME}/.pi/agent/RTK.md"

# 6b. Compile the tiered prompt profiles, then link the FULL tier into each tool.
#
# The sources under config/ and memory/ carry <!--min--> / <!--lean--> tier markers; the
# compiler strips them, so build/full is byte-identical to the pre-tiering files while
# build/lean and build/min exist for cheaper models. Tools always read from build/, never
# from the annotated sources.
echo -e "\n${BLUE}🧱 Compiling prompt profiles (full / lean / min)...${NC}"
if [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    # Legacy path: Pi farm + full/lean/min profiles (aimain default builds the OMP farm).
    "${SCRIPT_DIR}/bin/aimain" build --legacy || echo -e "  ${RED}✗ profile build failed — tools keep the previously built profiles${NC}"
fi

echo -e "\n${BLUE}🪞 Linking shared rules into each tool...${NC}"
for shared_file in style.md workflow.md profile.md SHARED.md RULES.md; do
    src="${SCRIPT_DIR}/build/full/${shared_file}"
    [ -f "$src" ] || { echo -e "  ${YELLOW}⚠ build/full/${shared_file} missing — skipped${NC}"; continue; }
    for tool_shared_dir in "${ACTUAL_HOME}/.claude/shared" "${ACTUAL_HOME}/.codex/shared" "${ACTUAL_HOME}/.gemini/shared"; do
        ln -sfn "$src" "${tool_shared_dir}/${shared_file}"
    done

    pi_src="${SCRIPT_DIR}/build/lean/${shared_file}"
    [ -f "$pi_src" ] || { echo -e "  ${YELLOW}⚠ build/lean/${shared_file} missing — skipped for Pi${NC}"; continue; }
    ln -sfn "$pi_src" "${ACTUAL_HOME}/.pi/agent/shared/${shared_file}"
    echo -e "  ${GREEN}✓ ${shared_file} → claude/codex/gemini full; pi lean${NC}"
done

echo -e "  ${GREEN}✓ Cursor session defaults${NC}"
ln -sfn "${SCRIPT_DIR}/config/cursor-rules/session-efficiency.mdc" "${ACTUAL_HOME}/.cursor/rules/session-efficiency.mdc"

# The Caveman startup hook otherwise defaults to full, overriding the shared prose rule.
# Merge only the centrally managed default; preserve other local options and session modes.
CAVEMAN_CONFIG="${ACTUAL_HOME}/.config/caveman/config.json"
if [ -L "$CAVEMAN_CONFIG" ] || { [ -e "$CAVEMAN_CONFIG" ] && ! jq -e 'type == "object"' "$CAVEMAN_CONFIG" >/dev/null 2>&1; }; then
    echo -e "  ${YELLOW}⚠ Caveman config is symlinked or invalid — preserved: ${CAVEMAN_CONFIG}${NC}"
else
    mkdir -p "$(dirname "$CAVEMAN_CONFIG")"
    caveman_tmp="$(mktemp)"
    if [ -f "$CAVEMAN_CONFIG" ]; then
        jq -s '.[0] * .[1]' "$CAVEMAN_CONFIG" "${SCRIPT_DIR}/config/caveman.json" > "$caveman_tmp"
    else
        cp "${SCRIPT_DIR}/config/caveman.json" "$caveman_tmp"
    fi
    mv "$caveman_tmp" "$CAVEMAN_CONFIG"
    echo -e "  ${GREEN}✓ Caveman startup default: off (explicit activation only)${NC}"
fi

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
compile_template "${SCRIPT_DIR}/config/PI.md.template" "${ACTUAL_HOME}/.pi/agent/APPEND_SYSTEM.md"

# 6e. Deploy the shared MCP base. Pi-specific overrides remain in ~/.pi/agent/mcp.json.
echo -e "\n${BLUE}🔌 Deploying shared MCP configuration...${NC}"
SHARED_MCP_CONFIG="${ACTUAL_HOME}/.config/mcp/mcp.json"
if [ -e "$SHARED_MCP_CONFIG" ] && ! jq -e '.["$comment"] == "generated by ai-main — edit ai-main/config/mcp.json.template"' "$SHARED_MCP_CONFIG" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠ ${SHARED_MCP_CONFIG} is not ai-main-managed — skipped${NC}"
else
    generate_from_template "${SCRIPT_DIR}/config/mcp.json.template" "$SHARED_MCP_CONFIG"
    echo -e "  ${GREEN}✓ ${SHARED_MCP_CONFIG}${NC}"
fi

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
echo -e "  ${GREEN}✓ ~/.agents/skills/gitlab-mr-description (Zcode / generic agents)${NC}"

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
            echo -e "  ${YELLOW}⚠ local skill preserved: ${target}${NC}"
            continue
        fi
        if [ -L "$target" ]; then
            case "$(readlink "$target")" in
                "${SCRIPT_DIR}"/*) ;;
                *) echo -e "  ${YELLOW}⚠ foreign skill link preserved: ${target}${NC}"; continue ;;
            esac
        fi
        ln -sfn "${skill_dir%/}" "$target"
    done
    echo -e "  ${GREEN}✓ linked ${name}${NC}"
done

# 9. Sync external skill packs (9arm-skills, vercel-labs/agent-skills) to all AI tools
TOOL_SKILL_DIRS=(
    "${ACTUAL_HOME}/.claude/skills"
    "${ACTUAL_HOME}/.codex/skills"
    "${ACTUAL_HOME}/.cursor/skills"
    "${ACTUAL_HOME}/.gemini/skills"
    "${ACTUAL_HOME}/.agents/skills"    # Zcode / generic agents global skills
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
        # Don't overwrite centrally-managed owned skills (ai-main/skills/*)
        if [ -d "${SCRIPT_DIR}/skills/${name}" ]; then
            continue
        fi
        for tool_dir in "${TOOL_SKILL_DIRS[@]}"; do
            target="${tool_dir}/${name}"
            if [ -e "$target" ] && [ ! -L "$target" ]; then
                echo -e "  ${YELLOW}⚠ local skill preserved: ${target}${NC}"
                continue
            fi
            if [ -L "$target" ]; then
                case "$(readlink "$target")" in
                    "${SCRIPT_DIR}"/*) ;;
                    *) echo -e "  ${YELLOW}⚠ foreign skill link preserved: ${target}${NC}"; continue ;;
                esac
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
link_external_pack "mattpocock/skills"        "${SCRIPT_DIR}/external/mattpocock-skills"

# Pi loads its curated farm explicitly through bin/pi-launcher. Remove only stale
# installer-owned links from Pi's default discovery root; preserve user/package entries.
echo -e "\n${BLUE}🥧 Configuring Pi's curated skill launcher...${NC}"
for target in "${ACTUAL_HOME}"/.pi/agent/skills/*; do
    [ -L "$target" ] || continue
    case "$(readlink "$target")" in
        "${SCRIPT_DIR}"/*) rm -f "$target" ;;
    esac
done
ln -sfn "${SCRIPT_DIR}/bin/pi-launcher" "${ACTUAL_HOME}/.pi/agent/bin/pi"
ln -sfn "${SCRIPT_DIR}/bin/pi-launcher" "${ACTUAL_HOME}/.pi/agent/bin/pi-raw"
ln -sfn "${SCRIPT_DIR}/bin/pi-memory" "${ACTUAL_HOME}/.pi/agent/bin/pi-memory"
echo -e "  ${GREEN}✓ Pi persistent memory CLI${NC}"
echo -e "  ${GREEN}✓ pi → lean context + curated skills${NC}"
echo -e "  ${GREEN}✓ pi-raw → default Pi discovery${NC}"

if [ -d "${SCRIPT_DIR}/config/pi-agents" ]; then
    mkdir -p "${ACTUAL_HOME}/.pi/agent/agents"
    for agent_file in "${SCRIPT_DIR}/config/pi-agents"/*.md; do
        [ -f "$agent_file" ] || continue
        agent_name="$(basename "$agent_file")"
        ln -sfn "$agent_file" "${ACTUAL_HOME}/.pi/agent/agents/${agent_name}"
        echo -e "  ${GREEN}✓ pi agent: ${agent_name} (advertised)${NC}"
    done
fi

# 9b. Sync plugins for Gemini CLI (~/.gemini/config/plugins/).
# In installed agy 1.1.28, agy plugin install also stages to ~/.gemini/config/plugins/
# (sharing registry location), while docs also cite ~/.gemini/antigravity-cli.
echo -e "\n${BLUE}✨ Syncing Gemini CLI global plugins...${NC}"
sync_gemini_plugin() {
    local plugin_name="$1"
    local plugin_desc="$2"
    local src_pack_dir="$3"

    [ -d "${src_pack_dir}/skills" ] || return 0
    local target_plugin_dir="${ACTUAL_HOME}/.gemini/config/plugins/${plugin_name}"
    mkdir -p "${target_plugin_dir}/skills"

    cat > "${target_plugin_dir}/plugin.json" <<EOF
{
  "name": "${plugin_name}",
  "version": "1.0.0",
  "description": "${plugin_desc}"
}
EOF

    while IFS= read -r -d '' skill_md; do
        local skill_dir name target
        skill_dir="$(dirname "$skill_md")"
        name="$(basename "$skill_dir")"
        target="${target_plugin_dir}/skills/${name}"
        if [ -d "${SCRIPT_DIR}/skills/${name}" ] && [ "$plugin_name" != "ai-main-skills" ]; then
            # Retire only this installer's exact upstream link now overridden by an owned skill.
            if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill_dir" ]; then
                rm -f "$target"
            fi
            continue
        fi
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo -e "  ${YELLOW}⚠ local plugin skill preserved: ${target}${NC}"
            continue
        fi
        if [ -L "$target" ]; then
            case "$(readlink "$target")" in
                "${SCRIPT_DIR}"/*) ;;
                *) echo -e "  ${YELLOW}⚠ foreign plugin skill link preserved: ${target}${NC}"; continue ;;
            esac
        fi
        ln -sfn "$skill_dir" "$target"
    done < <(find "${src_pack_dir}/skills" -name SKILL.md \
        -not -path '*/node_modules/*' \
        -not -path '*/deprecated/*' \
        -not -path '*/in-progress/*' \
        -not -path '*/personal/*' \
        -print0)
    echo -e "  ${GREEN}✓ Gemini CLI plugin ${plugin_name} synced${NC}"
}

sync_gemini_plugin "ai-main-skills"    "Centralized workspace skills"    "${SCRIPT_DIR}"
sync_gemini_plugin "9arm-skills"       "9arm curated AI skills"         "${SCRIPT_DIR}/external/9arm-skills"
sync_gemini_plugin "mattpocock-skills" "Matt Pocock engineering skills" "${SCRIPT_DIR}/external/mattpocock-skills"

# Antigravity CLI has a documented registry. Build and register only an
# ai-main-owned plugin; existing imports (for example agent-skills) are untouched.
if command -v agy >/dev/null 2>&1; then
    ANTIGRAVITY_PLUGIN="${SCRIPT_DIR}/build/antigravity-plugin"
    ANTIGRAVITY_MANIFEST="${ANTIGRAVITY_PLUGIN}/.ai-main-skill-hashes"
    rm -rf "$ANTIGRAVITY_PLUGIN"
    mkdir -p "${ANTIGRAVITY_PLUGIN}/skills"
    cat > "${ANTIGRAVITY_PLUGIN}/plugin.json" <<'EOF'
{
  "$schema": "https://antigravity.google/schemas/v1/plugin.json",
  "name": "ai-main-shared",
  "description": "ai-main owned shared engineering skills"
}
EOF
    : > "$ANTIGRAVITY_MANIFEST"
    for skill_dir in "${SCRIPT_DIR}"/skills/*/; do
        [ -f "${skill_dir}SKILL.md" ] || continue
        skill_name="$(basename "${skill_dir%/}")"
        ln -sfn "${skill_dir%/}" "${ANTIGRAVITY_PLUGIN}/skills/${skill_name}"
        printf '%s\t%s\n' "$skill_name" "$(shasum -a 256 "${skill_dir}SKILL.md" | awk '{print $1}')" >> "$ANTIGRAVITY_MANIFEST"
    done
    sync_agy_owned_plugin() { # <installed plugin path>
        local installed="$1" name expected source target current source_hash changed=0
        if ! cmp -s "$ANTIGRAVITY_PLUGIN/plugin.json" "$installed/plugin.json"; then
            echo -e "  ${YELLOW}⚠ Antigravity CLI ai-main-shared manifest has a local owner — preserved${NC}"
            return 1
        fi
        if [ ! -f "$installed/.ai-main-skill-hashes" ]; then
            # Bootstrap only if every copied skill still exactly matches its owned source.
            while IFS=$'\t' read -r name expected; do
                source="${SCRIPT_DIR}/skills/${name}/SKILL.md"; target="$installed/skills/${name}/SKILL.md"
                [ -f "$target" ] && [ "$(shasum -a 256 "$target" | awk '{print $1}')" = "$(shasum -a 256 "$source" | awk '{print $1}')" ] || {
                    echo -e "  ${YELLOW}⚠ Antigravity CLI ai-main-shared has untracked local skill content — preserved${NC}"; return 1; }
            done < "$ANTIGRAVITY_MANIFEST"
            cp "$ANTIGRAVITY_MANIFEST" "$installed/.ai-main-skill-hashes"
            echo -e "  ${GREEN}✓ Antigravity CLI plugin ai-main-shared ownership manifest adopted${NC}"
            return 0
        fi
        local new_manifest="${installed}/.ai-main-skill-hashes.tmp.$$"
        : > "$new_manifest"
        while IFS=$'\t' read -r name expected; do
            source="${SCRIPT_DIR}/skills/${name}/SKILL.md"; target="$installed/skills/${name}/SKILL.md"
            [ -f "$source" ] || continue
            current="$(shasum -a 256 "$target" 2>/dev/null | awk '{print $1}')"
            source_hash="$(shasum -a 256 "$source" 2>/dev/null | awk '{print $1}')"
            if [ "$current" = "$expected" ]; then
                if [ "$current" != "$source_hash" ]; then
                    mkdir -p "$(dirname "$target")"; cp "$source" "$target"; changed=1
                fi
                printf '%s\t%s\n' "$name" "$source_hash" >> "$new_manifest"
            elif [ "$current" != "$source_hash" ]; then
                echo -e "  ${YELLOW}⚠ Antigravity CLI local skill preserved: ${target}${NC}"
                printf '%s\t%s\n' "$name" "$expected" >> "$new_manifest"
                continue
            else
                printf '%s\t%s\n' "$name" "$source_hash" >> "$new_manifest"
            fi
        done < "$installed/.ai-main-skill-hashes"
        while IFS=$'\t' read -r name expected; do
            target="$installed/skills/${name}/SKILL.md"
            if [ ! -e "$target" ]; then
                source="${SCRIPT_DIR}/skills/${name}/SKILL.md"
                mkdir -p "$(dirname "$target")"; cp "$source" "$target"; changed=1
                printf '%s\t%s\n' "$name" "$expected" >> "$new_manifest"
            fi
        done < "$ANTIGRAVITY_MANIFEST"
        mv "$new_manifest" "$installed/.ai-main-skill-hashes"
        [ "$changed" -eq 0 ] || echo -e "  ${GREEN}✓ Antigravity CLI plugin ai-main-shared skills refreshed${NC}"
    }
    if agy plugin validate "$ANTIGRAVITY_PLUGIN" >/dev/null 2>&1; then
        if agy plugin list 2>/dev/null | grep -q '"name": "ai-main-shared"'; then
            # 1.1.28 stages here; retain the documented path as a future-compatible candidate.
            for installed in "${ACTUAL_HOME}/.gemini/config/plugins/ai-main-shared" "${ACTUAL_HOME}/.gemini/antigravity-cli/plugins/ai-main-shared"; do
                [ -d "$installed" ] || continue
                sync_agy_owned_plugin "$installed" || true
                break
            done
        elif agy plugin install "$ANTIGRAVITY_PLUGIN"; then
            echo -e "  ${GREEN}✓ Antigravity CLI plugin ai-main-shared registered${NC}"
            for installed in "${ACTUAL_HOME}/.gemini/config/plugins/ai-main-shared" "${ACTUAL_HOME}/.gemini/antigravity-cli/plugins/ai-main-shared"; do
                if [ -d "$installed" ] && cmp -s "$ANTIGRAVITY_PLUGIN/plugin.json" "$installed/plugin.json"; then
                    cp "$ANTIGRAVITY_MANIFEST" "$installed/.ai-main-skill-hashes"
                    break
                fi
            done
        else
            echo -e "  ${YELLOW}⚠ Antigravity CLI plugin registration failed; existing registry preserved${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ Antigravity CLI plugin validation failed; registry preserved${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ agy not found; Antigravity CLI plugin not registered${NC}"
fi

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

# 10b. Deploy per-repo knowledge to every registered workspace.
#
# The workspace list lives in config/workspaces.json (not hardcoded here) and the
# deploy logic lives in bin/aimain, so `aimain link <any folder>` and this installer
# always produce the same output. Each workspace gets ONE compiled knowledge file
# (AGENTS.md) plus CLAUDE.md/GEMINI.md symlinks to it; global rules already load from
# ~/.claude etc., so workspace files carry repo-specific knowledge ONLY.
echo ""
if [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    if [ "$SYNC_MODE" -eq 1 ]; then
        "${SCRIPT_DIR}/bin/aimain" deploy --all --sync || \
            echo -e "  ${YELLOW}⚠ workspace deploy reported problems — run './bin/aimain doctor'${NC}"
    else
        "${SCRIPT_DIR}/bin/aimain" deploy --all || \
            echo -e "  ${YELLOW}⚠ workspace deploy reported problems — run './bin/aimain doctor'${NC}"
    fi
else
    echo -e "  ${RED}✗ bin/aimain missing or not executable — workspace knowledge not deployed${NC}"
fi

# Workspace paths for the steps below (Claude Desktop trusted folders, verification)
PRIMARY_WORKSPACES=()
if command -v jq >/dev/null 2>&1 && [ -f "${SCRIPT_DIR}/config/workspaces.json" ]; then
    while IFS= read -r ws_path; do
        ws_path="${ws_path//\{\{HOME\}\}/$ACTUAL_HOME}"
        # Only folders that exist here — the registry is shared across machines and
        # a non-existent path must not end up in Claude Desktop's trusted list.
        if [ -d "$ws_path" ]; then PRIMARY_WORKSPACES+=("$ws_path"); fi
    done < <(jq -r '.workspaces[].path' "${SCRIPT_DIR}/config/workspaces.json")
fi

# 10b2. Deploy any adapter-described tool (adapters/*.json) — opencode, qwen, ...
echo ""
if [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    echo -e "${BLUE}🔌 Deploying adapter-described tools...${NC}"
    "${SCRIPT_DIR}/bin/aimain" adapters deploy || \
        echo -e "  ${YELLOW}⚠ adapter deploy reported problems${NC}"
fi

# 10b3. Install the git-level checks that replaced prompt rules (full install only —
# these write into work repos, so they are not part of the every-6h sync path).
if [ "$SYNC_MODE" -eq 0 ] && [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    echo -e "\n${BLUE}🛡️  Installing git checks + PATH shims...${NC}"
    "${SCRIPT_DIR}/bin/aimain" hooks install || true
    "${SCRIPT_DIR}/bin/aimain" shims || true
fi

# 10c. Configure Claude Desktop app (Local Agent Mode Trusted Folders)
CLAUDE_CONFIG_DIR="${ACTUAL_HOME}/Library/Application Support/Claude"
CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"

if [ "$SYNC_MODE" -eq 0 ] && [ -d "$CLAUDE_CONFIG_DIR" ]; then
    echo -e "\n${BLUE}🖥️  Configuring Claude Desktop app (Local Agent Mode)...${NC}"
    
    # Derived from the workspace registry — link a new folder and it becomes trusted too
    TRUSTED_FOLDERS=("${SCRIPT_DIR}")
    if [ "${#PRIMARY_WORKSPACES[@]}" -gt 0 ]; then
        TRUSTED_FOLDERS+=("${PRIMARY_WORKSPACES[@]}")
    fi

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

# 10d. Generated workspace files are excluded locally by aimain deploy.
# Never add global AGENTS.md/CLAUDE.md/GEMINI.md patterns: they hide legitimate
# nested instructions owned by other repositories. Existing user/global entries
# are left untouched; inspect with `git check-ignore -v <path>` before changing them.

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
if [ -x "${SCRIPT_DIR}/bin/aimain" ]; then
    "${SCRIPT_DIR}/bin/aimain" list || true
fi

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
verify_link "${ACTUAL_HOME}/.cursor/rules/session-efficiency.mdc"
verify_link "${ACTUAL_HOME}/.cursor/skills/gitlab-mr-description"
verify_link "${ACTUAL_HOME}/.codex/skills/gitlab-mr-description"
verify_link "${ACTUAL_HOME}/.claude/skills/git-commit-helper"
verify_link "${ACTUAL_HOME}/.claude/skills/branch-perf-compare"
verify_link "${ACTUAL_HOME}/.claude/skills/gitlab-mr-comment-reply"
verify_link "${ACTUAL_HOME}/.pi/agent/APPEND_SYSTEM.md"
verify_link "${ACTUAL_HOME}/.pi/agent/RTK.md"
verify_link "${ACTUAL_HOME}/.pi/agent/shared/style.md"
verify_link "${ACTUAL_HOME}/.pi/agent/bin/pi"
verify_link "${ACTUAL_HOME}/.pi/agent/bin/pi-raw"
verify_link "${ACTUAL_HOME}/.pi/agent/bin/pi-memory"
verify_link "${ACTUAL_HOME}/.config/mcp/mcp.json"

# 12. Summary
echo -e "\n${GREEN}${BOLD}🎉 INSTALLATION SUCCESSFUL!${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"
echo -e "Configs managed centrally in: ${BOLD}${SCRIPT_DIR}${NC}"
echo -e "Backups saved to:             ${BOLD}${BACKUP_DIR}${NC}"
echo -e "To sync a new device, clone this repo and run: ${BOLD}./install.sh${NC}"
echo -e "${CYAN}------------------------------------------------------${NC}"

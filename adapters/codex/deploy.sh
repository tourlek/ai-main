#!/usr/bin/env bash
#
# Codex adapter deployment for ai-main (optional; also run by `omp/deploy.sh --codex`).
#
# Writes only ~/.codex/AGENTS.md (marker-managed entry from build/full/SYSTEM.md) and
# bare-name symlinks for owned skills into ~/.codex/skills. Never touches external packs.
#
# Usage: adapters/codex/deploy.sh [--sync] [--quiet] [--help]
#
# Shared ownership model and helpers: adapters/lib/deploy-common.sh.
# Sources (built by `bin/aimain build`, never built here): build/full/SYSTEM.md.

set -euo pipefail

CODEX_MODE=1
SYNC_MODE=0
QUIET=0
for arg in "$@"; do
    case "$arg" in
        --sync)  SYNC_MODE=1 ;;
        --quiet) QUIET=1 ;;
        --help|-h)
            sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *)
            echo "codex/deploy.sh: unknown option: $arg (try --help)" >&2
            exit 2 ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ACTUAL_HOME="${HOME:-$(cd ~ && pwd -P)}"
BACKUP_DIR="${ACTUAL_HOME}/.ai-backup-$(date +%Y%m%d_%H%M%S)"
CODEX_SYSTEM="${REPO_DIR}/build/full/SYSTEM.md"

# shellcheck source=../lib/deploy-common.sh
source "${REPO_DIR}/adapters/lib/deploy-common.sh"

trap 'rm -f "${generated:-}"' EXIT

# --------------------------------------------------------------------------
# Optional Codex GUI adapter (--codex): generated entry from the shared
# profile + owned skills only (conservative: never external packs).
# --------------------------------------------------------------------------
deploy_codex() {
    [ -f "$CODEX_SYSTEM" ] || fail "missing $CODEX_SYSTEM (run bin/aimain build)"
    local codex_dir="${ACTUAL_HOME}/.codex"
    mkdir -p "$codex_dir"

    local generated
    generated="$(mktemp)"
    {
        echo "$CODEX_MARKER"
        echo ""
        cat "$CODEX_SYSTEM"
    } > "$generated"
    deploy_entry "$generated" "${codex_dir}/AGENTS.md" "Codex entry"

    # Owned skills: bare-name symlinks into ~/.codex/skills, pointing into this
    # repo. Foreign dirs/files and foreign symlinks are left untouched.
    local codex_skills="${codex_dir}/skills"
    mkdir -p "$codex_skills"
    local skill_dir name target link_dest
    for skill_dir in "${REPO_DIR}"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        name="$(basename "$skill_dir")"
        target="${codex_skills}/${name}"
        if [ -L "$target" ]; then
            link_dest="$(readlink "$target")"
            case "$link_dest" in
                "${REPO_DIR}"|"${REPO_DIR}"/*) ln -sfn "${REPO_DIR}/skills/${name}" "$target" ;;
                *) log "  ${YELLOW}skip ${name}: foreign symlink preserved ($link_dest)${NC}" ;;
            esac
        elif [ -e "$target" ]; then
            log "  ${YELLOW}skip ${name}: user-owned entry preserved ($target)${NC}"
        else
            ln -sfn "${REPO_DIR}/skills/${name}" "$target"
            log "  ${GREEN}✓ skill ${name} -> ~/.codex/skills/${name}${NC}"
        fi
    done
}

verify_codex() {
    grep -qxF "$CODEX_MARKER" "${ACTUAL_HOME}/.codex/AGENTS.md" || fail "verify: Codex entry marker missing"
    log "  ${GREEN}✓ verified Codex deployment${NC}"
}

# --------------------------------------------------------------------------
deploy_codex
verify_codex
log "${GREEN}Codex entry + owned skills deployed.${NC}"
exit 0

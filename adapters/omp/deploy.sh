#!/usr/bin/env bash
#
# Scoped OMP-first deployment for ai-main.
#
# Default: OMP-owned destinations (~/.omp/agent) and its role launchers (~/.local/bin).
# Never touches legacy tool homes (Claude, Gemini, Cursor, external packs) — use
# `install.sh --legacy` for the old all-harness installer.
#
# Usage: adapters/omp/deploy.sh [--codex] [--sync] [--quiet] [--legacy] [--help]
#   --codex   additionally run adapters/codex/deploy.sh (Codex entry + owned skills)
#   --sync    redeploy mode used by scripts/sync.sh (identical, quieter banner)
#   --quiet   suppress informational output (launchd)
#   --legacy  escape hatch: run the legacy all-harness installer (install.sh)
#
# Ownership model and shared helpers: adapters/lib/deploy-common.sh.
#
# Sources (built by `bin/aimain build`, never built here):
#   adapters/omp/entry.md.template -> OMP entry      (@imports build/omp/SYSTEM.md)
#   build/omp/SYSTEM.md        -> OMP system body
#   build/omp-skills/          -> OMP skill farm (skills.customDirectories[0])
#
# No network, no dependency installs, no submodule updates, no hooks, no
# launchd changes. Honors PI_CODING_AGENT_DIR for isolated fixtures.

set -euo pipefail

CODEX_MODE=0
SYNC_MODE=0
QUIET=0
for arg in "$@"; do
    case "$arg" in
        --codex)  CODEX_MODE=1 ;;
        --sync)   SYNC_MODE=1 ;;
        --quiet)  QUIET=1 ;;
        --legacy) exec "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/install.sh" "$@" ;;
        --help|-h)
            sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *)
            echo "deploy.sh: unknown option: $arg (try --help)" >&2
            exit 2 ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ADAPTER_DIR="${REPO_DIR}/adapters/omp"
ACTUAL_HOME="${HOME:-$(cd ~ && pwd -P)}"
AGENT_DIR="${PI_CODING_AGENT_DIR:-${ACTUAL_HOME}/.omp/agent}"
BACKUP_DIR="${ACTUAL_HOME}/.ai-backup-$(date +%Y%m%d_%H%M%S)"

# shellcheck source=../lib/deploy-common.sh
source "${REPO_DIR}/adapters/lib/deploy-common.sh"

OMP_TEMPLATE="${ADAPTER_DIR}/entry.md.template"
OMP_SYSTEM="${REPO_DIR}/build/omp/SYSTEM.md"
FARM_DIR="${REPO_DIR}/build/omp-skills"
CODEX_SYSTEM="${REPO_DIR}/build/full/SYSTEM.md"
LAUNCHER_DIR="${ACTUAL_HOME}/.local/bin"

# Retire the old exclusions: the farm now keeps these names as manual pointers.
# Arbitrary user exclusions are preserved.
RETIRE_IGNORED="agents-sdk cloudflare-one cloudflare-one-migrations durable-objects sandbox-migrate-to-next sandbox-next sandbox-sdk sandbox-stable turnstile-spin workers-best-practices vercel-composition-patterns vercel-optimize vercel-react-native-skills vercel-react-view-transitions web-perf git-guardrails-claude-code migrate-to-shoehorn scaffold-exercises"
export RETIRE_IGNORED

require_sources() {
    local missing=0
    command -v bun >/dev/null 2>&1 || fail "bun is required for the config merge"
    [ -f "$OMP_TEMPLATE" ] || { echo "missing: $OMP_TEMPLATE" >&2; missing=1; }
    [ -f "$OMP_SYSTEM" ]   || { echo "missing: $OMP_SYSTEM (run bin/aimain build)" >&2; missing=1; }
    [ -d "$FARM_DIR" ]     || { echo "missing: $FARM_DIR (run bin/aimain build)" >&2; missing=1; }
    for name in omp-review omp-verify omp-orca-role; do
        [ -f "${ADAPTER_DIR}/bin/${name}" ] || { echo "missing: adapters/omp/bin/${name}" >&2; missing=1; }
    done
    [ -f "${ADAPTER_DIR}/roles.json" ] || { echo "missing: adapters/omp/roles.json" >&2; missing=1; }
    if [ "$CODEX_MODE" -eq 1 ] && [ ! -f "$CODEX_SYSTEM" ]; then
        echo "missing: $CODEX_SYSTEM (run bin/aimain build)" >&2; missing=1
    fi
    [ "$missing" -eq 0 ] || fail "scoped deployment sources incomplete"
}

# --------------------------------------------------------------------------
# OMP config merge — safe YAML edit via Bun's YAML parser (no new deps).
# Sets: skills.customDirectories (farm first, foreign dirs preserved),
#       skills.enableAgentsUser=false (user-wide .agents discovery off),
#       retires exactly RETIRE_IGNORED from skills.ignoredSkills.
# Everything else is preserved byte-for-value.
# --------------------------------------------------------------------------
merge_omp_config() {
    local config_target="$1"
    command -v bun >/dev/null 2>&1 || fail "bun is required for the safe config.yml merge (no PyYAML dependency is added)"
    bun -e '
const fs = require("fs");
const [configPath, farmDir, repoDir] = process.argv.slice(1);
const retire = new Set(process.env.RETIRE_IGNORED.trim().split(/\s+/));
const realpathSafe = (p) => { try { return fs.realpathSync(p); } catch { return null; } };
const farmReal = realpathSafe(farmDir) || farmDir;

let raw = "";
try { raw = fs.readFileSync(configPath, "utf8"); } catch (error) { if (error.code !== "ENOENT") throw error; }
let cfg;
if (raw.trim() === "") {
    cfg = {};
} else {
    cfg = Bun.YAML.parse(raw);
    if (cfg === null || cfg === undefined) cfg = {};
    if (typeof cfg !== "object" || Array.isArray(cfg)) {
        console.error("not a YAML mapping: " + configPath);
        process.exit(1);
    }
}
if (cfg.skills !== undefined && (cfg.skills === null || typeof cfg.skills !== "object" || Array.isArray(cfg.skills))) {
    throw new Error("skills must be a YAML mapping: " + configPath);
}
cfg.skills ??= {};
const s = cfg.skills;

if (s.customDirectories !== undefined && !Array.isArray(s.customDirectories)) throw new Error("customDirectories must be an array");
const dirs = s.customDirectories || [];
const sourceReal = realpathSafe(repoDir + "/skills");
const kept = dirs.filter((d) => {
    const r = typeof d === "string" ? realpathSafe(d) : null;
    return d !== repoDir + "/skills" && d !== farmDir && !(r && (r === sourceReal || r === farmReal));
});
s.customDirectories = [farmDir, ...kept];

s.enableAgentsUser = false;                            // user-wide .agents source off; project scope untouched
s.enablePiUser = false;                               // native authored user skills are already in the farm

if (Array.isArray(s.ignoredSkills)) {
    const rest = s.ignoredSkills.filter((v) => !retire.has(v));
    if (rest.length > 0) s.ignoredSkills = rest; else delete s.ignoredSkills;
}

const out = Bun.YAML.stringify(cfg);
if (out === raw) { console.log("unchanged"); process.exit(0); }
const tmp = configPath + ".tmp-ai-main-" + process.pid;
const mode = fs.existsSync(configPath) ? fs.statSync(configPath).mode & 0o777 : 0o644;
fs.writeFileSync(tmp, out, { mode });
fs.renameSync(tmp, configPath);
console.log("updated");
' "$config_target" "$FARM_DIR" "$REPO_DIR"
}

find_omp_config() {
    if [ -f "${AGENT_DIR}/config.yml" ]; then
        echo "${AGENT_DIR}/config.yml"
    elif [ -f "${AGENT_DIR}/config.yaml" ]; then
        echo "${AGENT_DIR}/config.yaml"   # compatibility filename: loaded and updated in place
    else
        echo "${AGENT_DIR}/config.yml"
    fi
}

# --------------------------------------------------------------------------
install_role_launchers() {
    local name source legacy_source target
    mkdir -p "$LAUNCHER_DIR"
    for name in omp-review omp-verify omp-orca-role; do
        source="${ADAPTER_DIR}/bin/${name}"
        legacy_source="${REPO_DIR}/bin/${name}"
        target="${LAUNCHER_DIR}/${name}"
        if [ -L "$target" ]; then
            if [ "$(readlink "$target")" = "$legacy_source" ]; then
                ln -sfn "$source" "$target"  # exact-recognition migration of the pre-adapters launcher path
            else
                [ "$(readlink "$target")" = "$source" ] || fail "foreign launcher symlink preserved: $target"
            fi
        elif [ -e "$target" ]; then
            fail "user-owned launcher preserved: $target"
        else
            ln -s "$source" "$target"
        fi
    done
    log "  ${GREEN}✓ role launchers installed: ${LAUNCHER_DIR}${NC}"
}

verify() {
    local ok=0
    grep -qxF "$OMP_MARKER" "${AGENT_DIR}/AGENTS.md" || { echo "verify: OMP entry marker missing" >&2; ok=1; }
    grep -q "@.*build/omp/SYSTEM\.md" "${AGENT_DIR}/AGENTS.md" || { echo "verify: OMP entry does not import build/omp/SYSTEM.md" >&2; ok=1; }
    [ -f "$OMP_SYSTEM" ] || { echo "verify: $OMP_SYSTEM missing" >&2; ok=1; }
    for name in omp-review omp-verify omp-orca-role; do
        [ -x "${LAUNCHER_DIR}/${name}" ] || { echo "verify: launcher ${name} missing or not executable" >&2; ok=1; }
    done
    [ -d "$FARM_DIR" ] || { echo "verify: $FARM_DIR missing" >&2; ok=1; }

    bun -e '
const fs = require("fs");
const [configPath, farmDir] = process.argv.slice(1);
const cfg = Bun.YAML.parse(fs.readFileSync(configPath, "utf8"));
const s = (cfg && cfg.skills) || {};
const bad = [];
if (!Array.isArray(s.customDirectories) || s.customDirectories[0] !== farmDir) bad.push("customDirectories=" + JSON.stringify(s.customDirectories));
if (s.enableAgentsUser !== false) bad.push("enableAgentsUser=" + JSON.stringify(s.enableAgentsUser));
if (s.enablePiUser !== false) bad.push("enablePiUser=" + JSON.stringify(s.enablePiUser));
if (bad.length) { console.error("verify: config mismatch: " + bad.join("; ")); process.exit(1); }
' "$(find_omp_config)" "$FARM_DIR" || ok=1

    [ "$ok" -eq 0 ] || fail "verification failed"
    log "  ${GREEN}✓ verified OMP deployment${NC}"
}

# --------------------------------------------------------------------------
require_sources

log ""
log "${CYAN}${BOLD}OMP scoped deployment (ai-main)${NC}${CYAN} — repo: ${REPO_DIR}${NC}"
[ "$SYNC_MODE" -eq 1 ] || log "${BLUE}agent dir:${NC} ${AGENT_DIR}"
[ "$ACTUAL_HOME" = "${HOME}" ] || log "${BLUE}HOME:${NC} ${ACTUAL_HOME}"

trap 'rm -f "${generated:-}"' EXIT
mkdir -p "$AGENT_DIR"

log ""
log "${BLUE}⚙ OMP entry (adapters/omp/entry.md.template -> AGENTS.md)...${NC}"
generated="$(mktemp)"
expand_placeholders < "$OMP_TEMPLATE" > "$generated"
deploy_entry "$generated" "${AGENT_DIR}/AGENTS.md" "OMP entry"

log "${BLUE}🧩 OMP config ($(find_omp_config))...${NC}"
merge_omp_config "$(find_omp_config)" | while IFS= read -r line; do
    case "$line" in
        updated)   log "  ${GREEN}✓ skills sources/ignores updated (unrelated settings preserved)${NC}" ;;
        unchanged) log "  ${GREEN}✓ config already current${NC}" ;;
        *)         log "  $line" ;;
    esac
done
install_role_launchers

if [ "$CODEX_MODE" -eq 1 ]; then
    log ""
    log "${BLUE}🧠 Codex adapter (--codex -> adapters/codex/deploy.sh)...${NC}"
    codex_args=()
    [ "$SYNC_MODE" -eq 0 ] || codex_args+=(--sync)
    [ "$QUIET" -eq 0 ] || codex_args+=(--quiet)
    "${REPO_DIR}/adapters/codex/deploy.sh" ${codex_args[@]+"${codex_args[@]}"}
fi

log ""
verify

log ""
log "${GREEN}🎉 OMP deployment complete.${NC} Farm: ${FARM_DIR}"
exit 0

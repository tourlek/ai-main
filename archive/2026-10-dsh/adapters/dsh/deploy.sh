#!/usr/bin/env bash
# Install the DSH files (install.sh --harness dsh). Quit DSH first; see adapters/dsh/APPLY.md.
# Live files are moved to a timestamped backup dir, never deleted.
set -euo pipefail
AI_MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOME_DIR="${HOME:?}"
PROFILE="${DSH_PROFILE:-${HOME_DIR}/.dsh/profiles/desktop}"
BACKUP="${HOME_DIR}/.dsh/backup-$(date +%Y%m%d_%H%M%S)"

if pgrep -f "/DeepSeek Harness.app/Contents/MacOS/DeepSeek Harness" >/dev/null 2>&1; then
    echo "dsh deploy: DeepSeek Harness is running; quit it (Cmd+Q) and re-run." >&2
    exit 1
fi
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
"${AI_MAIN}/adapters/dsh/propose.sh" "$STAGE" >/dev/null

install_file() { # <src> <dst> <backup name>
    mkdir -p "$BACKUP" "$(dirname "$2")"
    if [ -e "$2" ] || [ -L "$2" ]; then cp -p "$2" "${BACKUP}/$3"; fi
    cp "$1" "$2"
    echo "  ✓ $2"
}
install_file "${STAGE}/package.json.proposed" "${PROFILE}/package.json" package.json
install_file "${STAGE}/cordis.patch.yml.proposed" "${PROFILE}/cordis.patch.yml" cordis.patch.yml
install_file "${STAGE}/AGENTS.md.proposed" "${HOME_DIR}/.dsh/AGENTS.md" AGENTS.md
install_file "${STAGE}/agents-AGENTS.md.proposed" "${HOME_DIR}/.agents/AGENTS.md" agents-AGENTS.md
# DSH scans <agentsHome>/skills; link clickup-card only when nothing is there yet (install.sh 7b handles replacement).
SK="${HOME_DIR}/.agents/skills/clickup-card"
if [ ! -e "$SK" ] && [ ! -L "$SK" ]; then mkdir -p "$(dirname "$SK")"; ln -s "${AI_MAIN}/skills/clickup-card" "$SK"; echo "  ✓ $SK"; fi
(cd "$PROFILE" && pnpm install)
echo "dsh deploy: backups in ${BACKUP}; start DeepSeek Harness again."

#!/usr/bin/env bash
# Render the DSH files ai-main would install, without touching live files.
#   adapters/dsh/propose.sh [OUT_DIR]   (default ~/.dsh/backup-20261021-consolidate)
# Writes only OUT_DIR/{package.json,cordis.patch.yml,AGENTS.md,agents-AGENTS.md}.proposed.
# Both @local plugins link to the ai-main copies (the live guard-bridge link points at ~/Documents; see APPLY.md).
set -euo pipefail
AI_MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOME_DIR="${HOME:?}"
PROFILE="${DSH_PROFILE:-${HOME_DIR}/.dsh/profiles/desktop}"
OUT="${1:-${HOME_DIR}/.dsh/backup-20261021-consolidate}"
PLUGINS="${AI_MAIN}/adapters/dsh/plugins"

[ -f "${AI_MAIN}/build/dsh/AGENTS.md" ] || "${AI_MAIN}/bin/aimain" build >/dev/null
[ -f "${PROFILE}/package.json" ] || { echo "propose.sh: no ${PROFILE}/package.json" >&2; exit 1; }
mkdir -p "$OUT"

# Live package.json plus the @local links and bundle entries; everything else unchanged.
jq --indent 2 \
   --arg rules "link:${PLUGINS}/dsh-ai-main-rules" --arg guard "link:${PLUGINS}/dsh-guard-bridge" \
   --arg rtk "link:${PLUGINS}/dsh-rtk-bridge" '
  .dependencies["@local/dsh-ai-main-rules"] = $rules
  | .dependencies["@local/dsh-guard-bridge"] = $guard
  | .dependencies["@local/dsh-rtk-bridge"] = $rtk
  | .dsh.profile.bundles |= (. + ["@local/dsh-ai-main-rules", "@local/dsh-guard-bridge", "@local/dsh-rtk-bridge"] | reduce .[] as $b ([]; if index([$b]) then . else . + [$b] end))
' "${PROFILE}/package.json" > "${OUT}/package.json.proposed"
# Live cordis.patch.yml plus any adapters/dsh/cordis.patch.yml row whose id it lacks (present rows untouched).
# shortcut: a present row with drifted config is not updated; diff the review step by eye, parse YAML if drift recurs.
FRAG="${AI_MAIN}/adapters/dsh/cordis.patch.yml"
LIVE_PATCH="${PROFILE}/cordis.patch.yml"
HAVE=" $( { grep -oE '(^|[^A-Za-z])id: *[A-Za-z0-9_-]+' "$LIVE_PATCH" 2>/dev/null || true; } | sed -E 's/.*id: *//' | sort -u | tr '\n' ' ')"
MISSING="$(awk -v have="$HAVE" '/^    - id: / { keep = index(have, " " $3 " ") == 0 } /^    / && keep' "$FRAG")"
{ [ -f "$LIVE_PATCH" ] && cat "$LIVE_PATCH"
  [ -n "$MISSING" ] && printf '# ai-main rows (adapters/dsh/cordis.patch.yml)\n- insert:\n%s\n' "$MISSING"
  true; } > "${OUT}/cordis.patch.yml.proposed"
cp "${AI_MAIN}/build/dsh/AGENTS.md" "${OUT}/AGENTS.md.proposed"
cp "${AI_MAIN}/build/dsh/agents-AGENTS.md" "${OUT}/agents-AGENTS.md.proposed"
echo "proposed: ${OUT}/{package.json,cordis.patch.yml,AGENTS.md,agents-AGENTS.md}.proposed"

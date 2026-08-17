#!/usr/bin/env bash
# git commit-msg hook — rejects AI attribution lines in commit messages.
#
# Replaces the prompt rule "no Co-Authored-By / AI attribution": a rule stated in a system
# prompt is advisory for every model, this is not. Install with: aimain hooks install <repo>
#
# Bypass (rare, deliberate):  AIMAIN_BYPASS=1 git commit ...

set -euo pipefail
[ "${AIMAIN_BYPASS:-0}" = "1" ] && exit 0

msg_file="${1:-}"
[ -n "$msg_file" ] && [ -f "$msg_file" ] || exit 0

# Strip comment lines git adds to the template before matching.
if grep -v '^#' "$msg_file" | grep -qiE '^[[:space:]]*(co-authored-by:|claude-session:)|generated with \[?(claude|codex|gemini)|🤖 generated with'; then
    cat >&2 <<'EOF'
✗ commit blocked: AI attribution line found in the commit message.

  The user has removed these repeatedly. Drop the Co-Authored-By / Claude-Session /
  "Generated with" line and commit again.
  Deliberate override: AIMAIN_BYPASS=1 git commit ...
EOF
    exit 1
fi
exit 0

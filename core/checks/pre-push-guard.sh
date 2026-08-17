#!/usr/bin/env bash
# git pre-push hook — refuses a direct push to master/main of a work repo.
#
# Replaces the prompt rule "never push to master/main": enforced at the git layer, so it
# applies to every tool and every model, including ones with no hook API of their own.
#
# git feeds refs on stdin as: <local ref> <local sha> <remote ref> <remote sha>
# Bypass (rare, deliberate):  AIMAIN_BYPASS=1 git push ...

set -euo pipefail
[ "${AIMAIN_BYPASS:-0}" = "1" ] && exit 0

blocked=0
while read -r _local_ref _local_sha remote_ref _remote_sha; do
    [ -n "${remote_ref:-}" ] || continue
    case "$remote_ref" in
        refs/heads/master|refs/heads/main)
            echo "✗ push blocked: ${remote_ref#refs/heads/} is a protected branch here." >&2
            blocked=1
            ;;
    esac
done

if [ "$blocked" -eq 1 ]; then
    echo "  Open a merge request from a feature branch instead." >&2
    echo "  Deliberate override: AIMAIN_BYPASS=1 git push ..." >&2
    exit 1
fi
exit 0

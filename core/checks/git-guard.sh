#!/usr/bin/env bash
# Command classifier for git operations that have burned this user before.
#
#   git-guard.sh "<the full shell command>"
#     exit 0  → allowed
#     exit 2  → denied, reason on stderr
#
# Used two ways:
#   - Claude Code PreToolUse hook (see core/hooks/claude-pre-tool-use.sh) — blocks the
#     command before it runs.
#   - Any other tool: call it yourself, or rely on the git hooks, which catch the same
#     cases at commit/push time.
#
# Each rule below replaces a line that used to sit in every session's prompt.

set -uo pipefail
cmd="${1:-}"
[ -n "$cmd" ] || exit 0
[ "${AIMAIN_BYPASS:-0}" = "1" ] && exit 0

deny() { printf '✗ blocked: %s\n' "$1" >&2; [ -n "${2:-}" ] && printf '  %s\n' "$2" >&2; exit 2; }

# Only inspect git invocations.
case "$cmd" in *git\ *|git\ *) ;; *) exit 0 ;; esac

# --- 2026-07: rewrote a commit three branches already contained ---------------
if printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(rtk[[:space:]]+)?git[[:space:]]+(commit[[:space:]]+.*--amend|rebase([[:space:]]|$))'; then
    current="$(git branch --show-current 2>/dev/null || true)"
    if [ -n "$current" ]; then
        containing="$( { git branch --format='%(refname:short)' --contains HEAD 2>/dev/null;
                         git branch -r --format='%(refname:short)' --contains HEAD 2>/dev/null; } \
                       | grep -vxE "${current}|origin/${current}" || true )"
        if [ -n "$containing" ]; then
            deny "HEAD is already contained by: $(echo "$containing" | tr '\n' ' ')" \
                 "Amending/rebasing it orphans a commit those branches reference. Add a new commit on top instead."
        fi
    fi
fi

# --- 2026-07: ran a git command with an implicit target after HEAD moved ------
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+branch[[:space:]]+--set-upstream-to=[^[:space:]]+[[:space:]]*$'; then
    deny "git branch --set-upstream-to with no branch argument" \
         "It silently targets whatever HEAD is now. Pass the branch explicitly: git branch --set-upstream-to=origin/X X"
fi
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+branch[[:space:]]+-f[[:space:]]+[^[:space:]]+[[:space:]]*$'; then
    deny "git branch -f with a single argument" "Pass both the branch and the target commit."
fi

# --- destructive history/worktree operations ---------------------------------
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+reset[[:space:]]+(--hard|--merge)'; then
    deny "git reset --hard" "The user runs several AI tools on the same worktree; this destroys work you did not create."
fi
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-z]*f'; then
    deny "git clean -f" "Same reason: untracked files here often belong to another tool's session."
fi
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]]+.*(--force([[:space:]]|$)|-f([[:space:]]|$))'; then
    deny "force push" "Use --force-with-lease at minimum, and only on a branch you own."
fi
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push([[:space:]]+[^[:space:]]+)*[[:space:]]+(master|main)([[:space:]]|$)'; then
    deny "push to master/main" "Open a merge request from a feature branch."
fi

# --- commit authorization ----------------------------------------------------
# The prompt rule stays for tools with no hook; this is the enforced version.
if printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(rtk[[:space:]]+)?git[[:space:]]+commit([[:space:]]|$)'; then
    if [ "${AIMAIN_ALLOW_COMMIT:-0}" != "1" ]; then
        deny "git commit without authorization" \
             "The user authorizes commits explicitly ('commit it'). Once they do: AIMAIN_ALLOW_COMMIT=1 git commit ..."
    fi
fi

exit 0

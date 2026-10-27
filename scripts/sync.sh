#!/usr/bin/env bash

# Auto-commit local changes (after a secret scan), pull --rebase, push main, rebuild local
# outputs, then redeploy the harnesses selected in config/harnesses.local. No default harness.
# Never force-pushes, never uses --no-verify. Personal repo only.
# Usage: sync.sh [--pull-only] [--quiet] [--legacy]

set -uo pipefail

# launchd starts with a minimal PATH; bun/git/gitleaks live in these dirs.
export PATH="$HOME/.bun/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOCK_DIR="${TMPDIR:-/tmp}/ai-main-sync.lock"

QUIET=0
LEGACY=0
for arg in "$@"; do
    case "$arg" in
        --pull-only) ;; # Existing startup callers already request local-only sync.
        --quiet)     QUIET=1 ;;
        --legacy)    LEGACY=1 ;;
        *) echo "sync.sh: unknown option: $arg" >&2; exit 2 ;;
    esac
done

log() {
    [ "$QUIET" -eq 1 ] && return 0
    echo -e "$@"
}

# Always printed (even with --quiet) so the launchd log records every commit/push/skip.
note() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') ai-main-sync: $*"
}

lock_mtime() {
    stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0
}

# --- lock (stale after 10 min) ---
if [ -d "$LOCK_DIR" ]; then
    lock_age=$(( $(date +%s) - $(lock_mtime "$LOCK_DIR") ))
    if [ "$lock_age" -lt 600 ]; then
        log "sync already running (lock ${LOCK_DIR}), skipping"
        exit 0
    fi
    rmdir "$LOCK_DIR" 2>/dev/null || true
fi
mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

cd "$REPO_DIR"

repo_is_clean() {
    [ -z "$(git status --porcelain --untracked-files=normal)" ]
}

# --- auto-commit + pull + push ---
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
SSH_CMD="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=5}"
SKIP_PUSH=0

# Scan only the lines being added. Prints "<file>: <pattern name>" -- never the matched value.
secret_scan() {
    local hits=0 f
    # Sensitive file names.
    while IFS= read -r f; do
        case "$(basename "$f")" in
            .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa|id_ed25519|id_ecdsa|*.keychain*|credentials.json)
                echo "$f: sensitive file name"; hits=1 ;;
        esac
    done < <(git diff --cached --name-only --diff-filter=AM)
    if command -v gitleaks >/dev/null 2>&1; then
        if ! gitleaks protect --staged --no-banner --redact >/dev/null 2>&1; then
            echo "(staged): gitleaks reported findings"; hits=1
        fi
    else
        local name pat files
        while IFS='|' read -r name pat; do
            files="$(git diff --cached -U0 --no-color | awk -v pat="$pat" '
                /^\+\+\+ b\// { file=substr($0,7); next }
                /^\+/ && !/^\+\+\+/ { if ($0 ~ pat) seen[file]=1 }
                END { for (f in seen) print f }')"
            if [ -n "$files" ]; then
                while IFS= read -r f; do echo "$f: $name"; done <<<"$files"
                hits=1
            fi
        done <<'PATTERNS'
OpenAI/Anthropic-style key (sk-)|sk-[A-Za-z0-9_-]{20,}
GitHub token (ghp_/gho_/ghs_/github_pat_)|(ghp_|gho_|ghs_|ghu_|github_pat_)[A-Za-z0-9_]{20,}
AWS access key (AKIA)|AKIA[0-9A-Z]{16}
Slack token (xox)|xox[abprs]-[A-Za-z0-9-]{10,}
Private key block|BEGIN [A-Z ]*PRIVATE KEY
password assignment|[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][[:space:]]*=[[:space:]]*["']?[^[:space:]"'$<{(]{6,}
PATTERNS
    fi
    return $hits
}

if git remote get-url origin >/dev/null 2>&1; then
    if [ "$BRANCH" != "main" ]; then
        note "on branch '$BRANCH', not main -- skipping auto-commit/pull/push"
        SKIP_PUSH=1
    else
        # 1. commit local changes
        if ! repo_is_clean; then
            git add -A
            if hits="$(secret_scan)"; then
                msg="chore(auto-sync): $(hostname -s) $(date '+%Y-%m-%d %H:%M')"
                if git commit -q -m "$msg"; then
                    note "committed: $msg ($(git show --stat --format= HEAD | tail -1 | sed 's/^ *//'))"
                else
                    note "SKIPPED push: git commit failed"
                    SKIP_PUSH=1
                fi
            else
                git reset -q
                note "!!! SECRET CHECK HIT -- auto-commit and push SKIPPED, changes left unstaged !!!"
                echo "$hits" | sed 's/^/    /'
                SKIP_PUSH=1
            fi
        fi

        # 2. pull --rebase (only on a clean tree)
        if repo_is_clean; then
            if GIT_SSH_COMMAND="$SSH_CMD" git pull --rebase --quiet origin "$BRANCH" 2>/dev/null; then
                log "✓ pulled latest ai-main"
            else
                if [ -d "$(git rev-parse --git-path rebase-merge)" ] || [ -d "$(git rev-parse --git-path rebase-apply)" ]; then
                    git rebase --abort 2>/dev/null || true
                    note "pull --rebase CONFLICT -- rebase aborted, push skipped"
                else
                    note "pull failed (offline?) -- push skipped"
                fi
                SKIP_PUSH=1
            fi
        else
            log "⚠ ai-main still dirty (secret check or commit failure) — skipping pull"
            SKIP_PUSH=1
        fi

        # 3. push (never forced)
        if [ "$SKIP_PUSH" -eq 0 ]; then
            ahead="$(git rev-list --count "origin/${BRANCH}..HEAD" 2>/dev/null || echo 0)"
            if [ "$ahead" -gt 0 ]; then
                if GIT_SSH_COMMAND="$SSH_CMD" git push --quiet origin "$BRANCH" 2>&1; then
                    note "pushed $ahead commit(s) to origin/$BRANCH"
                else
                    note "push FAILED (not forced)"
                fi
            fi
        fi
    fi
fi

# Which harnesses to redeploy: config/harnesses.local (gitignored, one machine's choice),
# whitespace/comma separated ids, '#' comments allowed. There is no default harness; with
# no selection this only rebuilds local outputs. --legacy additionally selects "legacy".
SELECTION_FILE="${REPO_DIR}/config/harnesses.local"
HARNESSES=()
if [ -f "$SELECTION_FILE" ]; then
    while read -r id; do
        [ -n "$id" ] && HARNESSES+=("$id")
    done < <(sed 's/#.*//' "$SELECTION_FILE" | tr ', \t' '\n\n\n\n')
fi
[ "$LEGACY" -eq 0 ] || HARNESSES+=(legacy)

# Fail before deployment when the build is incomplete.
if ! "${REPO_DIR}/bin/aimain" build >/dev/null; then
    echo "sync.sh: build failed; deployment skipped" >&2
    exit 1
fi

if [ "${#HARNESSES[@]}" -eq 0 ]; then
    log "✓ built local outputs; no harness selected (see config/harnesses.local.example), nothing deployed"
    exit 0
fi

HARNESS_LIST="$(IFS=,; echo "${HARNESSES[*]}")"
"${REPO_DIR}/install.sh" --harness "$HARNESS_LIST" --sync --quiet
DEPLOY_STATUS=$?
if [ "$DEPLOY_STATUS" -ne 0 ]; then
    echo "sync.sh: redeploy failed" >&2
    exit "$DEPLOY_STATUS"
fi
log "✓ local-only sync complete (${HARNESS_LIST}); auto-commit/push handled above"

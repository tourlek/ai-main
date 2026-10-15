#!/usr/bin/env bash

# Pull only from a clean checkout, rebuild local outputs, then deploy OMP.
# No commits or pushes. Legacy redeployment requires explicit --legacy.
# Usage: sync.sh [--pull-only] [--quiet] [--legacy]

set -uo pipefail

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

# --- pull ---
# Never autostash config or another agent's work. A stale local baseline is safer than
# temporarily hiding changes or producing an unattended rebase conflict.
if git remote get-url origin >/dev/null 2>&1; then
    if ! repo_is_clean; then
        log "⚠ ai-main is dirty — skipping pull and continuing with local state"
    elif GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=3}" \
        git pull --rebase --quiet origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null; then
        log "✓ pulled latest ai-main"
    else
        log "⚠ pull failed (offline or conflict) — continuing with local state"
    fi
fi

# Fail before deployment when the selected build is incomplete.
BUILD_ARGS=(build)
[ "$LEGACY" -eq 0 ] || BUILD_ARGS+=(--legacy)
if ! "${REPO_DIR}/bin/aimain" "${BUILD_ARGS[@]}" >/dev/null; then
    echo "sync.sh: build failed; deployment skipped" >&2
    exit 1
fi

if [ "$LEGACY" -eq 1 ]; then
    "${REPO_DIR}/install.sh" --legacy --sync
else
    "${REPO_DIR}/scripts/deploy-omp.sh" --sync --quiet
fi
DEPLOY_STATUS=$?
if [ "$DEPLOY_STATUS" -ne 0 ]; then
    echo "sync.sh: redeploy failed" >&2
    exit "$DEPLOY_STATUS"
fi
log "✓ local-only OMP sync complete; no commits or pushes"


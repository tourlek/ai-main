#!/usr/bin/env bash

# ai-main sync: pull latest config/memory/logs, redeploy, auto-commit memory+logs.
# Auto-commit is scoped to memory/ and logs/ ONLY — everything else stays manual.
#
# Usage: sync.sh [--pull-only] [--quiet]
#   --pull-only  pull + redeploy, never commit/push (used by session-start hooks)
#   --quiet      suppress output (used by launchd)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOCK_DIR="${TMPDIR:-/tmp}/ai-main-sync.lock"

PULL_ONLY=0
QUIET=0
for arg in "$@"; do
    case "$arg" in
        --pull-only) PULL_ONLY=1 ;;
        --quiet)     QUIET=1 ;;
    esac
done

log() {
    [ "$QUIET" -eq 1 ] && return 0
    echo -e "$@"
}

# --- lock (stale after 10 min) ---
if [ -d "$LOCK_DIR" ]; then
    lock_age=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -lt 600 ]; then
        log "sync already running (lock ${LOCK_DIR}), skipping"
        exit 0
    fi
    rmdir "$LOCK_DIR" 2>/dev/null || true
fi
mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

cd "$REPO_DIR"

# --- pull ---
if git remote get-url origin >/dev/null 2>&1; then
    if git pull --rebase --autostash --quiet origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null; then
        log "✓ pulled latest ai-main"
    else
        log "⚠ pull failed (offline or conflict) — continuing with local state"
    fi
fi

# --- redeploy configs/knowledge so pulled edits take effect ---
if [ -x "${REPO_DIR}/install.sh" ]; then
    if [ "$QUIET" -eq 1 ]; then
        "${REPO_DIR}/install.sh" --sync >/dev/null 2>&1 || log "⚠ redeploy failed"
    else
        "${REPO_DIR}/install.sh" --sync >/dev/null 2>&1 && log "✓ redeployed configs" || log "⚠ redeploy failed"
    fi
fi

[ "$PULL_ONLY" -eq 1 ] && exit 0

# --- auto-commit memory/ + logs/ only ---
if [ -n "$(git status --porcelain -- memory logs)" ]; then
    git add -- memory logs
    if git commit --quiet -m "chore(memory): auto-sync $(date '+%Y-%m-%d %H:%M')" -- memory logs; then
        log "✓ committed memory/logs changes"
        if git push --quiet origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null; then
            log "✓ pushed"
        else
            # remote moved between pull and push — rebase once and retry
            git pull --rebase --autostash --quiet 2>/dev/null && \
                git push --quiet origin "$(git rev-parse --abbrev-ref HEAD)" 2>/dev/null && \
                log "✓ pushed after rebase" || log "⚠ push failed — will retry next sync"
        fi
    fi
else
    log "· memory/logs unchanged"
fi

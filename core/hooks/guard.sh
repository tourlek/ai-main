#!/bin/bash
# core/hooks/guard.sh : the one ai-main guard (installed as ~/.claude/hooks/guard.sh).
# Input: Claude Code PreToolUse JSON on stdin (tool_name, tool_input, transcript_path, cwd).
# Deny: prints hookSpecificOutput.permissionDecision="deny" JSON, exit 0.
# Silent exit 0 = no decision (normal permission flow).
# Callers: Claude Code PreToolUse, the DSH guard bridge (no transcript), core/checks/git-guard.sh (CLI).
# Reason phrases are a contract with adapters/dsh/plugins/dsh-guard-bridge:
#   "never allowed" -> deny; "needs the user's explicit" / "needs a preview" / "must branch from origin/master" -> ask
#   (no transcript under DSH, so 'allow-worktree' is never seen; Claude Code still allows on that word).
set -u
input=$(cat)
tool=$(jq -r '.tool_name // ""' <<<"$input")
tpath=$(jq -r '.transcript_path // ""' <<<"$input")
TTL_MIN=${GUARD_CONFIRM_TTL_MIN:-30}

deny() {
  jq -nc --arg r "guard.sh: $1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Last real user message (text, newest first). Empty if older than TTL_MIN.
last_user_msg() {
  [ -n "$tpath" ] && [ -f "$tpath" ] || return 0
  if command -v tac >/dev/null 2>&1; then rev=(tac); else rev=(tail -r); fi
  "${rev[@]}" "$tpath" 2>/dev/null | jq -rn --argjson ttl "$TTL_MIN" '
    first(inputs
      | select(.type=="user" and .message.role=="user")
      | select((.isMeta // false)|not) | select((.isCompactSummary // false)|not)
      | select((.origin.kind // "human")=="human")
      | (.message.content) as $c
      | (if ($c|type)=="string" then $c
         else ([$c[] | select(.type=="text") | .text] | join("\n")) end) as $t
      | select(($c|type)=="string" or ([$c[]|select(.type=="tool_result")]|length)==0)
      | select($t|length>0)
      | select(($t|startswith("<task-notification") or startswith("<local-command"))|not)
      | {t: (if ($t|startswith("<command-")) then (try ($t|capture("<command-args>(?<a>[\\s\\S]*)</command-args>").a) catch "") else $t end),
         ts: (.timestamp // "")})
    | if .ts=="" then .t
      else ((.ts|sub("\\.[0-9]+Z$";"Z")|fromdateiso8601) as $s
            | if (now-$s) > ($ttl*60) then "" else .t end) end' 2>/dev/null
}

# ---- (a) ClickUp ----
if [[ "$tool" =~ clickup_ ]]; then
  op=${tool##*clickup_}
  # mcp__clickup__addComment (hauptsache clickup-mcp via DSH) leaves "_addComment"
  while [[ "$op" == _* ]]; do op=${op#_}; done
  lc=$(tr '[:upper:]' '[:lower:]' <<<"$op")
  write=0
  if [[ "$lc" =~ ^(create|update|add|attach|delete|move|merge|remove|set|start|stop|request_attachment|send|edit) ]]; then write=1; fi
  if [ "$op" = "execute_operator" ]; then
    o=$(jq -r '.tool_input.operator // ""' <<<"$input")
    [[ "$o" =~ ^(get|list|get_many|list_children|search)$ ]] || write=1
  fi
  [ $write -eq 1 ] || exit 0
  msg=$(last_user_msg)
  if grep -qiE 'confirm|ใส่ได้เลย' <<<"$msg"; then exit 0; fi
  deny "ClickUp write ($op) needs a preview, then the user's 'confirm' (or 'ใส่ได้เลย') within ${TTL_MIN} min. Show the preview and wait."
fi

# ---- (d) graphify MCP: network-only PR tools ----
if [[ "$tool" =~ ^mcp__graphify__ ]]; then
  op=${tool##*mcp__graphify__}
  case "$op" in
    list_prs|get_pr_impact|triage_prs)
      deny "graphify PR tool ($op) needs the user's explicit go: it calls the GitHub API via the gh CLI." ;;
  esac
  exit 0
fi

# ---- (b)(c) Bash ----
[ "$tool" = "Bash" ] || exit 0
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
# ---- (e) graphify CLI only via the pinned wrapper (no LLM, fixed env) ----
if grep -qE '(^|[;&|])[[:space:]]*([^[:space:]]*/)?graphify([[:space:]]|$)' <<<"$cmd" \
   && ! grep -qE '(^|[;&|])[[:space:]]*([^[:space:]]*/)?bin/gfy([[:space:]]|$)' <<<"$cmd"; then
  deny "graphify CLI must run through ~/ai-main/bin/gfy (pinned env, no LLM); needs the user's explicit override for anything else."
fi
# cheap pre-filter: nothing to check
grep -qE 'git|glab|orca' <<<"$cmd" || exit 0
cwd=$(jq -r '.cwd // "."' <<<"$input")

GIT='(^|[[:space:]])(rtk[[:space:]]+)?git([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--[^[:space:]]+))*[[:space:]]+'
msg_loaded=0; msg=""
need_msg() { [ $msg_loaded -eq 1 ] || { msg=$(last_user_msg); msg_loaded=1; }; }

# Unwrap `bash -c "git push ..."`, `sh -c '...'`, `$(git ...)`: quotes, backticks and parens become spaces.
# Then split into segments on ; && || | and newlines. `env X=1 git push` already matches GIT.
segs=$(tr "\"'\`()" '     ' <<<"$cmd" | sed -E 's/(\&\&|\|\||;|\|)/\n/g')

# --- TEMP run exception (react parity run 2026-10-18, user-approved 15:05). Remove flag file to disable.
REACT_RUN_FLAG="${GUARD_REACT_RUN_FLAG:-$HOME/.claude/hooks/run-exceptions/react-parity-run}"
react_run_ok() { # $1 = segment
  [ -f "$REACT_RUN_FLAG" ] || return 1
  if grep -qE '(^|[[:space:]])glab[[:space:]]+mr' <<<"$1"; then
    grep -qE 'mr[[:space:]]+merge|--target-branch[[:space:]=]+(master|main)' <<<"$1" && return 1
    local bb; bb=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
    [[ "$bb" == feat/react-* ]] || grep -qE 'feat/react-' <<<"$1"; return $?
  fi
  # never: merge, force, history rewrite, or pushing to protected/base branches
  grep -qE 'mr[[:space:]]+merge|--force|(^|[[:space:]])-f([[:space:]]|$)|\+[^[:space:]]+|--delete|(^|[[:space:]:])(init/migration-scaffold|master|main)([[:space:]]|$)' <<<"$1" && return 1
  local b; b=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  grep -qE 'feat/react-' <<<"$1" && return 0
  [[ "$b" == feat/react-* ]] && return 0
  return 1
}
while IFS= read -r seg; do
  [ -z "${seg// }" ] && continue
  # destructive operations on a worktree other sessions share (ported from core/checks/git-guard.sh)
  if grep -qE "${GIT}reset[[:space:]].*--(hard|merge)([[:space:]]|$)" <<<"$seg"; then
    deny "git reset --hard/--merge is never allowed: other AI sessions share this worktree."
  fi
  if grep -qE "${GIT}clean([[:space:]]+[^[:space:]]+)*[[:space:]]+(-[a-zA-Z]*f|--force)" <<<"$seg"; then
    deny "git clean -f is never allowed: untracked files often belong to another session."
  fi
  if grep -qE "${GIT}branch[[:space:]]+--set-upstream-to=[^[:space:]]+[[:space:]]*$" <<<"$seg"; then
    deny "git branch --set-upstream-to without a branch argument is never allowed; name the branch explicitly."
  fi
  if grep -qE "${GIT}branch[[:space:]]+-f[[:space:]]+[^[:space:]]+[[:space:]]*$" <<<"$seg"; then
    deny "git branch -f with a single argument is never allowed; pass both the branch and the target commit."
  fi
  if grep -qE "${GIT}(commit[[:space:]].*--amend|rebase)([[:space:]]|$)" <<<"$seg"; then
    cur=$(git -C "$cwd" branch --show-current 2>/dev/null)
    if [ -n "$cur" ]; then
      containing=$( { git -C "$cwd" branch --format='%(refname:short)' --contains HEAD 2>/dev/null
                      git -C "$cwd" branch -r --format='%(refname:short)' --contains HEAD 2>/dev/null; } \
                    | grep -vxE "${cur}|origin/${cur}" | tr '\n' ' ')
      [ -n "${containing// }" ] && deny "amending/rebasing HEAD is never allowed when other branches contain it (${containing% }); add a new commit instead."
    fi
  fi
  # push
  if grep -qE "${GIT}push([[:space:]]|$)" <<<"$seg"; then
    args=$(sed -E "s/.*${GIT}push//" <<<"$seg")
    if grep -qE '(^|[[:space:]:+])(refs/heads/)?(master|main)([[:space:]]|$)|--all|--mirror' <<<"$args"; then
      deny "push to master/main (or --all/--mirror) is never allowed."
    fi
    if grep -qE '(^|[[:space:]])(--force|-f)([[:space:]]|$)' <<<"$args"; then
      deny "force push is never allowed; use --force-with-lease on a branch you own, with the user's approval."
    fi
    # no explicit refspec: check current branch of cwd (best effort)
    nwords=$(awk '{n=0; for(i=1;i<=NF;i++) if ($i !~ /^-/ && $i !~ /^[0-9]*>/) n++; print n}' <<<"$args")
    if [ "${nwords:-0}" -lt 2 ]; then
      br=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
      [[ "$br" =~ ^(master|main)$ ]] && deny "current branch is $br; push to master/main is never allowed."
    fi
    react_run_ok "$seg" || { need_msg
    grep -qiE 'push|พุช' <<<"$msg" || deny "git push needs the user's explicit 'push' in the last message."; }
  fi
  # commit (GUARD_ALLOW_COMMIT is set only by core/checks/git-guard.sh for AIMAIN_ALLOW_COMMIT=1)
  if grep -qE "${GIT}commit([[:space:]]|$)" <<<"$seg" && [ "${GUARD_ALLOW_COMMIT:-0}" != "1" ]; then
    react_run_ok "$seg" || { need_msg
    grep -qiE 'commit|คอมมิ' <<<"$msg" || deny "git commit needs the user's explicit 'commit' in the last message."; }
  fi
  # glab mr create/update/merge (a --help/-h segment only prints usage, so it is a read)
  if grep -qE '(^|[[:space:]])glab[[:space:]]+mr[[:space:]]+(create|update|merge)([[:space:]]|$)' <<<"$seg" \
     && ! grep -qE '(^|[[:space:]])(--help|-h)([[:space:]]|$)' <<<"$seg"; then
    react_run_ok "$seg" || { need_msg
    grep -qiE '(^|[^a-z])mr([^a-z]|$)|merge request|merge' <<<"$msg" || deny "glab mr create/update/merge needs the user's explicit MR instruction in the last message."; }
  fi
  # worktree base
  if grep -qE "${GIT}worktree[[:space:]]+add([[:space:]]|$)|(^|[[:space:]])orca[[:space:]]+worktree[[:space:]]+create([[:space:]]|$)" <<<"$seg"; then
    if ! grep -q 'origin/master' <<<"$seg" && ! { [ -f "$REACT_RUN_FLAG" ] && grep -qE -- '--base-branch[[:space:]=]+feat/react-|[[:space:]]feat/react-[^[:space:]]+[[:space:]]*$' <<<"$seg"; }; then
      need_msg
      grep -qi 'allow-worktree' <<<"$msg" || deny "new worktree must branch from origin/master (git worktree add ... origin/master, or orca worktree create --base-branch origin/master). Ask the user if another base is intended (they can reply 'allow-worktree')."
    fi
  fi
done <<<"$segs"
exit 0

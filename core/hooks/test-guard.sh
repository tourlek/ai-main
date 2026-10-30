#!/usr/bin/env bash
# Offline regression test for core/hooks/guard.sh: feeds PreToolUse JSON payloads and checks
# deny|ask vs silent. Uses temp repos/transcripts and a temp react-run flag; never reads the live flag.
#   bash core/hooks/test-guard.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$HERE/guard.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
export GUARD_REACT_RUN_FLAG="$T/react-flag"   # absent unless a case creates it
pass=0; fail=0

g() { git -c core.hooksPath=/dev/null -c commit.gpgsign=false -c user.name=t -c user.email=t@t "$@"; }
mkrepo() { # <dir> <branch>
  g init -q -b "$2" "$1" && g -C "$1" commit -q --allow-empty -m init
}
mkrepo "$T/master" master
mkrepo "$T/feat" feat/x
mkrepo "$T/react" feat/react-x
mkrepo "$T/shared" feat/a && g -C "$T/shared" branch other   # HEAD contained by another branch

iso() { # <seconds ago>
  local s=$(( $(date +%s) - $1 ))
  date -u -r "$s" +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d "@$s" +%Y-%m-%dT%H:%M:%S.000Z
}
transcript() { # <name> <text> <seconds ago>
  jq -nc --arg t "$2" --arg ts "$(iso "$3")" '{type:"user",message:{role:"user",content:$t},timestamp:$ts}' > "$T/$1.jsonl"
  printf '%s' "$T/$1.jsonl"
}

# check <expect: deny|ask|allow> <label> <tool> <tool_input json> [cwd] [transcript] [reason substring]
check() {
  local want="$1" label="$2" tool="$3" ti="$4" cwd="${5:-$T/feat}" tp="${6:-}" sub="${7:-}"
  local out got reason decision
  out="$(jq -nc --arg tool "$tool" --argjson ti "$ti" --arg cwd "$cwd" --arg tp "$tp" \
          '{tool_name:$tool,tool_input:$ti,cwd:$cwd,hook_event_name:"PreToolUse"} + (if $tp=="" then {} else {transcript_path:$tp} end)' \
        | bash "$GUARD")"
  reason="$(jq -r '.hookSpecificOutput.permissionDecisionReason // empty' <<<"$out" 2>/dev/null)"
  decision="$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$out" 2>/dev/null)"
  if [ "$decision" = "deny" ]; then got=deny
  elif [ "$decision" = "ask" ]; then got=ask
  elif [ -z "$out" ]; then got=allow
  else got="other:$out"; fi
  if [ "$got" = "$want" ] && { [ -z "$sub" ] || grep -qF -- "$sub" <<<"$reason"; }; then
    pass=$((pass + 1)); echo "PASS $label -> $got"
  else
    fail=$((fail + 1)); echo "FAIL $label -> $got (want $want${sub:+, reason containing '$sub'}) $reason"
  fi
}
bash_ti() { jq -nc --arg c "$1" '{command:$c}'; }
NEVER="never allowed"; ASK="needs the user's explicit"

fresh_push=$(transcript push "ok push it" 60)
stale_push=$(transcript stale_push "push it" 7200)
fresh_commit=$(transcript commit "commit it" 60)
fresh_mr=$(transcript mr "open the MR" 60)
fresh_confirm=$(transcript confirm "confirm" 60)
stale_confirm=$(transcript stale_confirm "confirm" 7200)
fresh_wt=$(transcript wt "allow-worktree" 60)
cmd_args=$(transcript cmd "<command-name>/x</command-name><command-args>commit it</command-args>" 60)

echo "== ClickUp"
check ask   "clickup_create_task, no transcript"      clickup_create_task '{"name":"x"}' "" "" "needs a preview"
check allow "clickup_create_task + fresh confirm"     clickup_create_task '{"name":"x"}' "" "$fresh_confirm"
check ask   "clickup_create_task + stale confirm"     clickup_create_task '{"name":"x"}' "" "$stale_confirm" "needs a preview"
check allow "mcp__x__clickup_get_task (read)"         mcp__x__clickup_get_task '{"task_id":"1"}'
check allow "execute_operator get_many (read)"        mcp__x__clickup_execute_operator '{"operator":"get_many"}'
check ask   "execute_operator create_many (write)"    mcp__x__clickup_execute_operator '{"operator":"create_many"}' "" "" "needs a preview"
# @hauptsache.net/clickup-mcp tool names
for t in addComment editComment updateTask createTask updateListInfo createTimeEntry updateDocumentPage createDocumentOrPage; do
  check ask   "mcp__clickup__$t, no transcript"       "mcp__clickup__$t" '{}' "" "" "needs a preview"
  check allow "mcp__clickup__$t + fresh confirm"      "mcp__clickup__$t" '{}' "" "$fresh_confirm"
done
for t in getTaskById searchTasks searchSpaces getListInfo getTimeEntries readDocument; do
  check allow "mcp__clickup__$t (read)"               "mcp__clickup__$t" '{}'
done
check ask   "mcp__clickup__addComment + stale confirm" mcp__clickup__addComment '{"taskId":"1"}' "" "$stale_confirm" "needs a preview"

echo "== push"
check deny  "git push origin master"                  Bash "$(bash_ti 'git push origin master')" "" "$fresh_push" "$NEVER"
check deny  "cd x && rtk git push origin main"        Bash "$(bash_ti 'cd x && rtk git push origin main')" "" "$fresh_push" "$NEVER"
check deny  "git push origin HEAD:refs/heads/main"    Bash "$(bash_ti 'git push origin HEAD:refs/heads/main')" "" "$fresh_push" "$NEVER"
check deny  "git push --all"                          Bash "$(bash_ti 'git push --all origin')" "" "$fresh_push" "$NEVER"
check deny  "git push --mirror"                       Bash "$(bash_ti 'git push --mirror origin')" "" "$fresh_push" "$NEVER"
check deny  "git push (no refspec) on master"         Bash "$(bash_ti 'git push')" "$T/master" "$fresh_push" "current branch is master"
check deny  "git push --force origin feat/x"          Bash "$(bash_ti 'git push --force origin feat/x')" "" "$fresh_push" "$NEVER"
check deny  "git push -f origin feat/x"               Bash "$(bash_ti 'git push -f origin feat/x')" "" "$fresh_push" "$NEVER"
check ask   "git push origin feat/x, no transcript"   Bash "$(bash_ti 'git push origin feat/x')" "" "" "$ASK"
check allow "git push origin feat/x + fresh push"     Bash "$(bash_ti 'git push origin feat/x')" "" "$fresh_push"
check ask   "git push origin feat/x + stale push"     Bash "$(bash_ti 'git push origin feat/x')" "" "$stale_push" "$ASK"
check allow "git push -u origin feat/x + fresh push"  Bash "$(bash_ti 'git push -u origin feat/x')" "" "$fresh_push"

echo "== wrapped commands"
check deny  'bash -c "git push origin master"'        Bash "$(bash_ti 'bash -c "git push origin master"')" "" "$fresh_push" "$NEVER"
check ask   "sh -c 'git push origin feat/x'"          Bash "$(bash_ti "sh -c 'git push origin feat/x'")" "" "" "$ASK"
check deny  "env GIT_TRACE=1 git push origin main"    Bash "$(bash_ti 'env GIT_TRACE=1 git push origin main')" "" "$fresh_push" "$NEVER"
check ask   'echo $(git commit -m x)'                 Bash "$(bash_ti 'echo $(git commit -m x)')" "" "" "$ASK"
check allow 'git commit -m "fix push" + commit msg'   Bash "$(bash_ti 'git commit -m "fix push flow"')" "" "$fresh_commit"

echo "== commit"
check ask   "git commit -m x, no transcript"          Bash "$(bash_ti 'git commit -m x')" "" "" "$ASK"
check allow "git commit -m x + fresh commit"          Bash "$(bash_ti 'git commit -m x')" "" "$fresh_commit"
check allow "git commit + slash-command args"         Bash "$(bash_ti 'git commit -m x')" "" "$cmd_args"
check ask   "git commit + push-only message"          Bash "$(bash_ti 'git commit -m x')" "" "$fresh_push" "$ASK"

echo "== glab mr"
check ask   "glab mr create, no transcript"           Bash "$(bash_ti 'glab mr create --fill')" "" "" "$ASK"
check allow "glab mr create + fresh MR"               Bash "$(bash_ti 'glab mr create --fill')" "" "$fresh_mr"
check allow "glab mr view (read)"                     Bash "$(bash_ti 'glab mr view 12 -F json')"

echo "== worktree base"
check ask   "git worktree add ../w feature"           Bash "$(bash_ti 'git worktree add ../w feature')" "" "" "must branch from origin/master"
check allow "git worktree add -b f ../w origin/master" Bash "$(bash_ti 'git worktree add -b f ../w origin/master')"
check allow "git worktree add ../w dev + allow-worktree" Bash "$(bash_ti 'git worktree add ../w dev')" "" "$fresh_wt"

echo "== destructive (ported from git-guard.sh)"
check deny  "git reset --hard origin/main"            Bash "$(bash_ti 'git reset --hard origin/main')" "" "" "$NEVER"
check allow "git reset --soft HEAD~1"                 Bash "$(bash_ti 'git reset --soft HEAD~1')"
check deny  "git clean -fd"                           Bash "$(bash_ti 'git clean -fd')" "" "" "$NEVER"
check allow "git clean -n"                            Bash "$(bash_ti 'git clean -n')"
check deny  "git branch --set-upstream-to=origin/feat" Bash "$(bash_ti 'git branch --set-upstream-to=origin/feat')" "" "" "$NEVER"
check allow "git branch --set-upstream-to=origin/feat feat" Bash "$(bash_ti 'git branch --set-upstream-to=origin/feat feat')"
check deny  "git branch -f x"                         Bash "$(bash_ti 'git branch -f x')" "" "" "$NEVER"
check deny  "git commit --amend, HEAD in other branch" Bash "$(bash_ti 'git commit --amend --no-edit')" "$T/shared" "$fresh_commit" "$NEVER"
check deny  "git rebase, HEAD in other branch"        Bash "$(bash_ti 'git rebase origin/master')" "$T/shared" "" "$NEVER"
check allow "git rebase, HEAD not shared"             Bash "$(bash_ti 'git rebase origin/master')" "$T/feat"

echo "== react-parity run exception"
check ask   "flag absent: push origin feat/react-x"   Bash "$(bash_ti 'git push origin feat/react-x')" "$T/react" "" "$ASK"
touch "$GUARD_REACT_RUN_FLAG"
check allow "flag: push origin feat/react-x"          Bash "$(bash_ti 'git push origin feat/react-x')" "$T/react"
check allow "flag: commit on feat/react-x"            Bash "$(bash_ti 'git commit -m x')" "$T/react"
check ask   "flag: commit on feat/x"                  Bash "$(bash_ti 'git commit -m x')" "$T/feat" "" "$ASK"
check deny  "flag: push --force feat/react-x"         Bash "$(bash_ti 'git push --force origin feat/react-x')" "$T/react" "" "$NEVER"
check deny  "flag: push origin main"                  Bash "$(bash_ti 'git push origin main')" "$T/react" "" "$NEVER"
check allow "flag: glab mr create on feat/react-x"    Bash "$(bash_ti 'glab mr create --fill')" "$T/react"
check ask   "flag: glab mr merge"                     Bash "$(bash_ti 'glab mr merge 12')" "$T/react" "" "$ASK"
check allow "flag: worktree base feat/react-y"        Bash "$(bash_ti 'git worktree add ../w feat/react-y')" "$T/react"
rm -f "$GUARD_REACT_RUN_FLAG"

echo "== local-auto commit+push (AUTONOMOUS_GIT_LOCAL_OK)"
# Path under the default LOCAL_AUTO_ROOT_SUBSTR ($HOME/.t3/worktrees/oho-web-app/); HOME is a temp dir so nothing touches the real one.
export HOME="$T/home"
# Flag unlocks LOCAL commit + narrow origin push.
LOCAL_WT="$HOME/.t3/worktrees/oho-web-app/react-p0"
mkdir -p "$(dirname "$LOCAL_WT")"
mkrepo "$LOCAL_WT" feat/react-p0-ux
# bare origin so `git push` / upstream checks can resolve
g init -q --bare "$T/fake-origin.git"
g -C "$LOCAL_WT" remote add origin "$T/fake-origin.git"
g -C "$LOCAL_WT" push -q -u origin feat/react-p0-ux
export GUARD_LOG="$T/guard.log"
: > "$GUARD_LOG"
check ask   "local-auto absent: commit on feat/react-p0-ux" Bash "$(bash_ti 'git commit -m x')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto absent: push still ask"             Bash "$(bash_ti 'git push origin feat/react-p0-ux')" "$LOCAL_WT" "" "$ASK"
mkdir -p "$LOCAL_WT/.scratch/p0"
touch "$LOCAL_WT/.scratch/p0/AUTONOMOUS_GIT_LOCAL_OK"
check allow "local-auto flag: commit on feat/react-p0-ux" Bash "$(bash_ti 'git commit -m x')" "$LOCAL_WT"
grep -q 'LOCAL-AUTO-COMMIT' "$GUARD_LOG" && pass=$((pass+1)) && echo "PASS local-auto-commit logged -> guard.log" || { fail=$((fail+1)); echo "FAIL local-auto-commit not logged"; }
: > "$GUARD_LOG"
check allow "local-auto flag: push origin current branch" Bash "$(bash_ti 'git push origin feat/react-p0-ux')" "$LOCAL_WT"
grep -q 'LOCAL-AUTO-PUSH' "$GUARD_LOG" && pass=$((pass+1)) && echo "PASS local-auto-push logged -> guard.log" || { fail=$((fail+1)); echo "FAIL local-auto-push not logged"; }
check allow "local-auto flag: push -u origin current"     Bash "$(bash_ti 'git push -u origin feat/react-p0-ux')" "$LOCAL_WT"
check allow "local-auto flag: push origin (no refspec)"   Bash "$(bash_ti 'git push origin')" "$LOCAL_WT"
check allow "local-auto flag: push (upstream origin)"     Bash "$(bash_ti 'git push')" "$LOCAL_WT"
check allow "local-auto flag: push origin HEAD"           Bash "$(bash_ti 'git push origin HEAD')" "$LOCAL_WT"
check allow "local-auto flag: push origin HEAD:feat/react-p0-ux" Bash "$(bash_ti 'git push origin HEAD:feat/react-p0-ux')" "$LOCAL_WT"
check ask   "local-auto flag: push other dest ref ask"    Bash "$(bash_ti 'git push origin HEAD:feat/react-other')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto flag: push other remote ask"      Bash "$(bash_ti 'git push upstream feat/react-p0-ux')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto flag: push --force-with-lease ask" Bash "$(bash_ti 'git push --force-with-lease origin feat/react-p0-ux')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto flag: push +refspec ask"          Bash "$(bash_ti 'git push origin +feat/react-p0-ux')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto flag: push --delete ask"          Bash "$(bash_ti 'git push --delete origin feat/react-p0-ux')" "$LOCAL_WT" "" "$ASK"
check ask   "local-auto flag: push --tags ask"            Bash "$(bash_ti 'git push --tags origin')" "$LOCAL_WT" "" "$ASK"
check deny  "local-auto flag: push --force still deny"    Bash "$(bash_ti 'git push --force origin feat/react-p0-ux')" "$LOCAL_WT" "" "$NEVER"
check deny  "local-auto flag: push --all still deny"      Bash "$(bash_ti 'git push --all origin')" "$LOCAL_WT" "" "$NEVER"
check deny  "local-auto flag: push --mirror still deny"   Bash "$(bash_ti 'git push --mirror origin')" "$LOCAL_WT" "" "$NEVER"
check ask   "local-auto flag: glab mr still ask"         Bash "$(bash_ti 'glab mr create --fill')" "$LOCAL_WT" "" "$ASK"
check deny  "local-auto flag: push master still deny"    Bash "$(bash_ti 'git push origin master')" "$LOCAL_WT" "" "$NEVER"
# Wrong branch under react path: still ask
mkrepo "$HOME/.t3/worktrees/oho-web-app/other" feat/x
mkdir -p "$HOME/.t3/worktrees/oho-web-app/other/.scratch/p0"
touch "$HOME/.t3/worktrees/oho-web-app/other/.scratch/p0/AUTONOMOUS_GIT_LOCAL_OK"
check ask   "local-auto flag but branch not feat/react-*" Bash "$(bash_ti 'git commit -m x')" "$HOME/.t3/worktrees/oho-web-app/other" "" "$ASK"
check ask   "local-auto flag wrong branch: push ask"      Bash "$(bash_ti 'git push origin feat/x')" "$HOME/.t3/worktrees/oho-web-app/other" "" "$ASK"
# Flag in non-react path: still ask even on feat/react-*
mkdir -p "$T/react/.scratch/p0"
touch "$T/react/.scratch/p0/AUTONOMOUS_GIT_LOCAL_OK"
check ask   "local-auto flag outside react worktree path" Bash "$(bash_ti 'git commit -m x')" "$T/react" "" "$ASK"
check ask   "local-auto flag outside path: push ask"      Bash "$(bash_ti 'git push origin feat/react-x')" "$T/react" "" "$ASK"
rm -f "$LOCAL_WT/.scratch/p0/AUTONOMOUS_GIT_LOCAL_OK"

echo "== passthrough"
check allow "git status"                              Bash "$(bash_ti 'git status')"
check allow "git diff v1.112.0 v1.113.0"              Bash "$(bash_ti 'git diff v1.112.0 v1.113.0')"
check allow "rg unread_by src/"                       Bash "$(bash_ti 'rg unread_by src/')"
check allow "Read tool"                               Read '{"file_path":"/tmp/x"}'

echo "== read-only commands (empty transcript)"
for c in 'rg -n foo src' 'grep -rn foo .' 'cat README.md' 'ls -la' 'head -50 a.log' \
         'git log --oneline -20' 'git diff HEAD~1' 'git show abc123' 'git status' 'git blame src/a.ts' \
         "find src -name '*.ts' -maxdepth 3" 'glab mr view 12' 'glab mr list' 'glab mr diff 12' \
         'glab mr create --help' 'glab mr update -h'; do
  check allow "read: $c"                              Bash "$(bash_ti "$c")" "" ""
done
check allow "clickup read mcp__clickup__getTaskById"  mcp__clickup__getTaskById '{}' "" ""
check allow "clickup read mcp__clickup__searchTasks"  mcp__clickup__searchTasks '{}' "" ""
check ask   "glab mr create --title x, no MR instruction" Bash "$(bash_ti 'glab mr create --title x')" "" "" "$ASK"


echo "== negation / automation (must stay ask, not allow)"
neg_do_not=$(transcript neg_do_not "Do not commit anything yet" 60)
neg_thai=$(transcript neg_thai "ห้าม commit และ push" 60)
auto_ka=$(transcript auto_ka "[keepalive 2026-10-28] continue; commit if needed" 60)
auto_rh=$(transcript auto_rh "[review-handoff 2026-10-28] Batch P05 ready; do not commit" 60)
check ask   "Do not commit -> still ask"              Bash "$(bash_ti 'git commit -m x')" "" "$neg_do_not" "$ASK"
check ask   "ห้าม commit -> still ask"               Bash "$(bash_ti 'git commit -m x')" "" "$neg_thai" "$ASK"
check ask   "[keepalive] with commit word -> ask"    Bash "$(bash_ti 'git commit -m x')" "" "$auto_ka" "$ASK"
check ask   "[review-handoff] with commit word -> ask" Bash "$(bash_ti 'git commit -m x')" "" "$auto_rh" "$ASK"

echo "== mongo prod"
check allow "mongo-ro prod read"                     Bash "$(bash_ti 'mongo-ro prod --eval '\''db.x.find().limit(1)'\'')"
check allow "fullpath mongo-ro prod"                 Bash "$(bash_ti '~/ai-main/bin/mongo-ro prod --eval '\''db.y.findOne()'\''')"
check allow "mongo-ro prod --file (no typed phrase needed)" Bash "$(bash_ti 'mongo-ro prod --file /tmp/q.js')"
check allow "bwsr + mongo-ro prod aggregate"         Bash "$(bash_ti 'bwsr -- ~/ai-main/bin/mongo-ro prod --eval '\''db.x.aggregate([])'\''')"
check deny  "raw mongosh prod deleteMany (write)"    Bash "$(bash_ti 'bwsr -- '\''mongosh \"$MONGO_URI_PROD\" --eval \"db.x.deleteMany({})\"'\''')" "" "" "$NEVER"
check deny  "raw mongosh prod updateMany (write)"    Bash "$(bash_ti 'mongosh mongodb+srv://u@prod.example/db --eval '\''db.x.updateMany({}, {})'\''')" "" "" "$NEVER"
check deny  "raw mongosh MONGO_URI_PROD"             Bash "$(bash_ti 'bwsr -- '\''mongosh \"$MONGO_URI_PROD\" --eval \"db.x.find()\"'\''')" "" "" "$NEVER"
check deny  "mongosh prod literal"                   Bash "$(bash_ti 'mongosh mongodb://prod.example/db --eval '\''db.x.find()'\''')" "" "" "$NEVER"

check deny  "mongo-ro then raw mongosh prod (chained)" Bash "$(bash_ti 'mongo-ro prod --file /tmp/q.js; mongosh "$MONGO_URI_PROD" --eval "db.x.find()"')" "" "" "$NEVER"
check deny  "mongo-ro in path arg + raw mongosh prod"  Bash "$(bash_ti 'bwsr -- '\''mongosh "$MONGO_URI_PROD" --file ~/ai-main/bin/mongo-ro.js'\''')" "" "" "$NEVER"

echo "== mongo-ro --check (static scan, no connection)"
MRO="$HERE/../../bin/mongo-ro"
mro() { # <want exit> <label> <js>
  local want="$1" label="$2" js="$3" rc
  bash "$MRO" --check --eval "$js" >/dev/null 2>&1; rc=$?
  if [ "$rc" = "$want" ]; then pass=$((pass + 1)); echo "PASS mongo-ro $label -> $rc"; else fail=$((fail + 1)); echo "FAIL mongo-ro $label -> $rc (want $want)"; fi
}
mro 3 "dot deleteMany"                 'db.x.deleteMany({})'
mro 3 "bracket deleteMany"              'db.x["deleteMany"]({})'
mro 3 "db[\"x\"][\"drop\"]"             'db["x"]["drop"]()'
mro 3 "method name in a variable"       'const m="deleteMany"; db.x[m]({})'
mro 3 "string-built method name"        'db.x["delete"+"Many"]({})'
mro 3 "getCollection()[\"drop\"]"        'db.getCollection("x")["drop"]()'
mro 3 "\$merge stage"                  'db.x.aggregate([{$merge:"y"}])'
mro 0 "find with \$in array"           'db.x.find({a:{$in:[1,2]}}).limit(1)'
mro 0 "aggregate pipeline"             'db.x.aggregate([{$match:{a:{$in:["a","b"]}}},{$group:{_id:"$a",n:{$sum:1}}},{$project:{v:{$arrayElemAt:["$arr",0]}}}])'
mro 0 "getCollection find \$and"       'db.getCollection("x").find({$and:[{a:1},{b:2}]})'
mro 0 "plain findOne"                  'db.y.findOne()'

echo "== CLI wrapper core/checks/git-guard.sh"
cli() { # <want exit> <label> <cmd> [env...]
  local want="$1" label="$2" c="$3"; shift 3
  (cd "$T/feat" && env "$@" bash "$HERE/../checks/git-guard.sh" "$c" >/dev/null 2>&1); local rc=$?
  if [ "$rc" = "$want" ]; then pass=$((pass + 1)); echo "PASS cli $label -> $rc"; else fail=$((fail + 1)); echo "FAIL cli $label -> $rc (want $want)"; fi
}
cli 2 "git commit -m x"                       "git commit -m x"
cli 0 "AIMAIN_ALLOW_COMMIT=1 git commit -m x" "git commit -m x" AIMAIN_ALLOW_COMMIT=1
cli 0 "AIMAIN_BYPASS=1 git reset --hard"      "git reset --hard" AIMAIN_BYPASS=1
cli 2 "git push origin main"                  "git push origin main"
cli 0 "git status"                            "git status"

echo
echo "$pass/$((pass + fail)) passed"
[ "$fail" -eq 0 ]

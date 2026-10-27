# Claude context 200k→500k + ai-main sync check (2026-10-27, Asia/Bangkok)

## Part A — Claude Code 2.1.311 context limit
- Cause of "200k": ~/.claude/settings.json `modelSettings.{claude-opus-5-5,claude-sonnet-5-5,claude-fable-5-1}.autoCompactWindow = 200000` (saved /autocompact value). Not a hard cap; current models (Sonnet/Opus/Fable 5.x) have native 1M window.
- Official docs (code.claude.com/docs/en/model-config): any value 100k–1M is valid (/autocompact 500k, --autocompact 500k, settings autoCompactWindow, env CLAUDE_CODE_AUTO_COMPACT_WINDOW). Per-model value in settings beats top-level key; env var beats everything.
- CHANGED: the 3 values 200000 → 500000. Backup: ~/.claude/backup-20261027-context/settings.json. Verified by diff (3 lines only) + JSON parse.
- Not changed: env CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=85 (may make effective compact point ~85% of the window ≈ 425k; remove if you want a true 500k). Haiku subagent model not in modelSettings (unchanged).
- Live test impossible: `claude -p` returned "You've hit your session limit · resets 6pm (Asia/Bangkok)" (personal Pro). Unconfirmed: whether Pro bills extra for >200k on native-1M models (docs: 1M included, standard pricing; only Opus/Sonnet 4.6 need credits on Pro).

## Part B — ai-main sync
- RULES.md (sha256 62fa6f1d…) == build/full/RULES.md, build/full/SYSTEM.md rebuilt Oct 27 16:02 (SessionStart hook runs scripts/sync.sh --pull-only --quiet → `aimain build`). Line 18 gtimeout present in full/*.
- launchd com.tualek.ai-main-sync: loaded, interval 6h, runs=44, last exit 0. Old log (last written Oct 18) shows "bun is required" redeploy failures from before; quiet runs since. NOTE sync.sh only BUILDS (config/harnesses.local absent → nothing deployed).
- build/lean + build/min are legacy: not rebuilt since Oct 18 (manifest only lists full, omp). lack gtimeout.
- pi: extensions/ai-main-brain.ts → ai-main/adapters/pi/extensions/ai-main-brain.ts (symlink OK), reads build/full/SYSTEM.md + adapters/pi/agent/APPEND_SYSTEM.md fresh every run → UP TO DATE.
  - STALE (fixed): ~/.pi/agent/shared/* → build/lean/*. Repointed to build/full/*. Old links moved to ~/.pi/agent/backup-20261027-sync/shared/. (Nothing in pi config references shared/.)
  - Proposal only: ~/.pi/agent/APPEND_SYSTEM.md is an Oct 1 RTK manual copy (differs from config/RTK.manual.md); harmless, pi loads it natively in addition.
- Claude: ~/.claude/CLAUDE.md was a COMPILED SNAPSHOT (Oct 25 23:47) made by install.sh --harness legacy (compile_template inlines @imports); sync.sh never redeploys it → missing ~13 newer lessons incl. gtimeout (line 18) and the "keep technical terms in English" rule. 
  - FIXED: CLAUDE.md now = ORACLE block + live @imports of ~/.claude/RTK.md and ~/.claude/shared/{profile,style,workflow,SHARED,RULES}.md (symlinks → build/full, rebuilt each Claude SessionStart). Backup: ~/.claude/backup-20261027-context/CLAUDE.md. gtimeout rule now visible via shared/RULES.md. Takes effect in NEW Claude sessions.
  - Caveat: running `install.sh --harness legacy` again would overwrite CLAUDE.md with the compiled snapshot (still correct then, but stale later). Skills/commands symlinks to ai-main OK (16+ links); hooks/guard.sh symlink → core/hooks/guard.sh OK.
- Side effect: `bin/oracle-recap --help` wrote a dry-run ORACLE.md to ~/.hermes/backups/20261025-memory/oracle-dryrun/ (harmless, outside allowed paths).
- No commits/pushes; nothing deleted.

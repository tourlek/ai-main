thread_id: 01a05792-79ea-74f3-abcd-9ea74e06432e
updated_at: 2026-08-31T11:31:47+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/31/rollout-2026-08-31T18-26-52-01a05792-79ea-74f3-abcd-9ea74e06432e.jsonl
cwd: /Users/tualek/ohochat

# Global RTK, Caveman, and Ponytail defaults enabled across managed AI sessions

Rollout context: In `/Users/tualek/ohochat`, the user asked to make RTK token monitoring/optimization, Caveman context/response compression, and Ponytail session/minimal-diff behavior available by default in every session. Central configuration lives in `/Users/tualek/ai-main`.

## Task 1: Install shared session-efficiency defaults

Outcome: success

Preference signals:

- The user explicitly requested that RTK, Caveman, and Ponytail apply to “ทุก session” (every session) -> future configuration changes should be centralized and propagated across all managed tools rather than enabled only for the current session.
- Caveman should be concise while preserving exact technical evidence; Ponytail should minimize scope/diffs and reuse existing code before adding new layers.

Key steps:

- Added shared defaults to `/Users/tualek/ai-main/config/workflow.md`.
- Added an always-applied Cursor rule at `/Users/tualek/ai-main/config/cursor-rules/session-efficiency.mdc`.
- Updated `/Users/tualek/ai-main/install.sh` to create/link `~/.cursor/rules/session-efficiency.mdc` and verify it.
- Ran `rtk ./install.sh --sync` from `/Users/tualek/ai-main` after successive compaction adjustments.

Reusable knowledge:

- Full-profile tools receive shared workflow defaults through generated configs: Claude, Codex, Gemini, OpenCode, Qwen, and Zcode. Cursor requires a separate global rule because skill links alone make skills available but do not automatically apply them.
- Final generated profile sizes passed configured budgets: full ~2,859 tokens / 4,000 ceiling; lean ~1,599 / 1,600; min ~630 / 650.
- RTK monitoring is operational outside the sandbox: `rtk gain` reported 27,338 commands, 87.8M tokens saved, and 65.9% savings.
- Caveman compresses generated responses/history, not already-loaded system prompts, source code, or tool output. Ponytail controls implementation scope/diff, not context trimming.

Failures and how to do differently:

- Direct patch operations against `/Users/tualek/ai-main` failed LSP validation because the request cwd was `/Users/tualek/ohochat`; use shell/edit operations with the target repo as cwd or tolerate the tool limitation after verifying the file changed.
- Initial wording pushed lean/min profiles over budget; shorten the shared section and rebuild until all profile ceilings pass.
- `rtk gain` initially failed in the sandbox with `unable to open database file`; rerun with appropriate elevated access when verifying RTK’s local tracking database.
- Cursor’s `~/.cursor/rules` did not initially exist; create it and install an MDC rule with `alwaysApply: true`. This applies to Cursor Agent Chat, not Cursor Tab.

References:

- `rtk ./install.sh --sync`
- `/Users/tualek/ai-main/config/workflow.md`
- `/Users/tualek/ai-main/install.sh`
- `/Users/tualek/ai-main/config/cursor-rules/session-efficiency.mdc`
- `rtk gain` result: 27,338 commands; 133.3M input tokens; 45.6M output tokens; 87.8M saved; 65.9%.
- Verification found the defaults in `/Users/tualek/.claude/CLAUDE.md`, `/Users/tualek/.codex/AGENTS.md`, `/Users/tualek/.gemini/GEMINI.md`, `/Users/tualek/.config/opencode/AGENTS.md`, `/Users/tualek/.qwen/QWEN.md`, `/Users/tualek/.zcode/AGENTS.md`, and Cursor’s global rule.

thread_id: 019f603f-0763-7a32-9125-816c9dd5f2b5
updated_at: 2026-07-14T11:40:37+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/14/rollout-2026-07-14T17-49-31-019f603f-0763-7a32-9125-816c9dd5f2b5.jsonl
cwd: /Users/tualek/ohochat

# Thai code review of unread/unresponded changes in the correct worktree found spec/contract regressions.

Rollout context: The user asked in Thai to review unread/unresponded behavior with the explicit contract that when the flag is off the feature must not work and other features must remain unaffected. The first pass briefly drifted into the wrong branch/worktree; the later pass corrected to `feature/tk-sprint-2613/oho-1018-unrespone` in `oho-api/.claude/worktrees/mr-1285-fixes` and reviewed only the tracked diff there.

## Task 1: Review unread/unresponded flag-gated changes in `mr-1285-fixes`

Outcome: fail

Preference signals:
- The user asked in Thai: `review เกี่ยวกับ unread&unresponded ให้หน่อยว่าถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม` -> default to Thai, findings-first, contract-focused review of whether flag-off truly means no feature behavior and no collateral impact.
- The user implicitly cared about zero-behavior / zero-side-effect when flag is off -> future reviews should check not only functional correctness but also whether the off path avoids extra DB/remote-config work and does not disturb unrelated paths.
- The user later accepted the corrected branch/worktree focus after the assistant noticed the initial mismatch -> future reviews should verify branch/worktree before making claims, especially when multiple worktrees exist.

Key steps:
- Confirmed the active worktree and diff in `.claude/worktrees/mr-1285-fixes` rather than the main repo.
- Traced the new `unread`/`unresponded` flow through `buildClearUnreadUnrespondedPayload`, `convertUnreadUnrespondedQuery`, `emit-chat-session-event.js`, and the member/bot/contact send paths.
- Ran targeted Jest on the new helper/spec areas and on the emitter spec; the new helper tests passed, and the emitter tests passed.
- Also ran bot/member hook specs; member tests passed, but bot quick-reply failures were pre-existing and unrelated to the tracked diff.

Failures and how to do differently:
- The review found that the new contact unresponded emitter is wired only into some send paths (`member-send-message`, `bot-send-message`) while `contact-send-message` still uses the older emitter, so realtime `is_unresponded` updates are not uniformly handled across all transitions.
- The flag-off contract is still violated in hot paths where the code eagerly queries/contact-reads or evaluates Remote Config before deciding whether to emit; this adds latency and DB work even when the feature is off.
- The new emitter path broadens audience handling using channel eligibility only, while sale-owner/assignee/team visibility rules in chat search are stricter; that means metadata can reach members who can open the channel but should not see that contact.
- The earlier wrong-worktree review should be discarded; future agents should re-check `git worktree list`, branch, and diff names before trusting any review output in a repo with parallel worktrees.

Reusable knowledge:
- `buildClearUnreadUnrespondedPayload` is deliberately unconditional for the clear-write side and is used by multiple runtime paths; when feature flags toggle off and back on, unconditional clear logic prevents stuck `is_unresponded`/unread state.
- `convertUnreadUnrespondedQuery` and its tests are the early gate for unread/unresponded query semantics; the helper and its spec are the right place to verify query shape before tracing deeper hooks.
- `emit-chat-session-event.spec.ts` now covers both group-session and contact-unresponded broadcast behavior, including the flag-off path and eligibility-scoped fan-out.
- The review repeatedly confirmed that targeted Jest around the new helper/specs is more informative than broad repo tests for this change family.

References:
- [1] Correct worktree reviewed: `/Users/tualek/ohochat/oho-api/.claude/worktrees/mr-1285-fixes`; branch context was `feature/tk-sprint-2613/oho-1018-unrespone`.
- [2] User request in Thai: `ถ้าปิด flag แล้วต้องหมายความว่า feature นี้ต้องไม่ทำงานแต่ feature อื่นๆ ก็ไม่กระทบด้วยเช่นกันต้องใช้งานได้เหมือนเดิม`.
- [3] Passing focused tests: `src/services/chat-session/hooks/emit-chat-session-event.spec.ts` passed 20/20; `src/services/contact/helper-hook/convert-unread-unresponded-query.spec.ts` and `src/utils/build-clear-unread-unresponded-payload.spec.ts` passed 24/24.
- [4] Emitter wiring evidence: `src/services/contact-send-message/contact-send-message.hooks.js:582`, `src/services/member-send-message/member-send-message.hooks.js:1338`, `src/services/bot-send-message/bot-send-message.hooks.js:929`, and `src/services/chat-session/hooks/emit-chat-session-event.js:362`.


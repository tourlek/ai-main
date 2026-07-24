thread_id: 019f8a65-96f5-7a71-a99e-19040bdcad19
updated_at: 2026-07-22T15:22:38+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-15-41-019f8a65-96f5-7a71-a99e-19040bdcad19.jsonl
cwd: /Users/tualek/ohochat/oho-webhook
git_branch: staging-4

# Read-only source review of member-send-message performance/locking claims in oho-api

Rollout context: The user asked for an exact, file:line-backed verification of six claims about `/Users/tualek/ohochat/oho-api` focused on `member-send-message` latency/locking behavior, retry semantics, axios timeout defaults, reference_id propagation, and risks in an early-ack/socket-reconcile redesign. The assistant performed a static review only and did not modify code. The repo snapshot was pinned at branch `feature/oho-1171-add-metadata-of-message-send-to-streamchat`, HEAD `7eb5af56fc861ef8695b72b152a139f76317a1c3`.

## Task 1: Verify six claims about `member-send-message` internals and provide redesign risk review

Outcome: success

Preference signals:
- The user explicitly required: "read the actual source code", "precision matters — every verdict must cite exact file:line evidence from the real code, not inference", and "Do not modify any code — this is a read-only verification and review task" -> future similar reviews should stay strictly read-only and use exact source citations, not summary-only reasoning.
- The user asked for a verdict per claim with `CONFIRMED`, `WRONG`, or `PARTIAL`, plus an independent second-reviewer opinion on "Top 3 highest-impact, lowest-risk changes" and concrete dangers of an "early-ack + reconcile via socket" redesign -> future similar tasks should structure output as claim-by-claim verdicts plus a separate risk-review section.
- The user asked to determine whether the client already sends `reference_id` through the flow and whether it reaches Stream/API response -> future similar work should trace correlation IDs end-to-end rather than assume propagation.

Key steps:
- Pinned the repo snapshot and inspected repo review instructions before tracing claims.
- Verified lock lifecycle in `src/hooks/lock-resource.js`, the `member-send-message` before/after/error hooks, and other endpoints that use the same `contact:$1:chat_session` lock key.
- Traced retry logic in `src/utils/retry-backoff.js`, axios defaults in `src/utils/axios.js`, and platform reply services for FB/IG/LINE.
- Traced Stream payload creation and `reference_id` handling in `member-send-message.hooks.js`, `validator-youpin.js`, and `message-converter/youpin-to-stream.js`.
- Checked downstream dependencies of after-hooks (`updateSomeFlagToContact`, activity logs, business active-at update, case update) to separate safely backgroundable work from hard dependencies.
- Reviewed synchronous quota/policy checks and unsend/delete-related code paths to assess early-ack hazards.

Failures and how to do differently:
- The original claim wording around the redlock was slightly off: the lock is auto-extended on a 200ms timer only when it is close to expiry, with `LOCK_MS = 3000` and `LOCK_EXTEND_GAP_MS = 1000`; do not describe it as a 200ms extension cadence.
- The LINE timeout claim needed correction: `callLineMessageAPI()` has no explicit timeout argument, but the axios instance is created with a 60s default timeout, so the effective behavior is bounded, not unbounded.
- The Stream retry claim underestimates worst-case request time if multiple messages are sent serially; compute both per-bubble retry cost and full-request accumulation.

Reusable knowledge:
- `member-send-message` acquires `contact:$1:chat_session` before platform calls and only releases it in after/error hooks, so any long platform/Stream work remains inside the lock window unless the hook order is changed.
- The same `contact:$1:chat_session` lock key is reused by 11 other contact mutation endpoints, including member assignment, bot assignment, member respond, and close-chat actions, but not `case`/`active-case` create flows, which use `contact:$1:active_case` instead.
- `shouldRetryOnFacebookTooManyRequests`, `shouldRetryOnInstagramTooManyRequests`, and `shouldRetryOnLineTooManyRequests` each have an initial `if` that already catches 429, making the later `else if (status === 429)` branch dead code.
- `createAxiosApi()` defaults to `timeout: 60000`; if a call site omits timeout, the effective timeout is still 60 seconds.
- `callWithStreamChatRetry()` uses `maxRetry: 5` and exponential backoff starting at 5000ms, producing delays of 5s, 10s, 20s, 40s, and 80s (155s backoff total) and six total attempts.
- `reference_id` is optional in the schema, used to correlate final API responses, but is not forwarded into the Stream payload in this snapshot.

References:
- [1] `src/services/member-send-message/member-send-message.hooks.js:1255-1307, 1313` — acquire lock before send; release in after/error hooks.
- [2] `src/hooks/lock-resource.js:48-105` and `src/utils/resource-lock.js:7-13, 26-34` — lock acquisition, 200ms extension timer, `LOCK_MS = 3000`, `LOCK_EXTEND_GAP_MS = 1000`, redlock retry config.
- [3] `src/services/contact/member-assign/self/self.hooks.js:841`, `.../team/team.hooks.js:1318`, `.../member/member.hooks.js:1202`, `src/services/contact/close-chat/no-case/no-case.hooks.js:433`, `src/services/contact/close-chat/end-case/end-case.hooks.js:453`, `src/services/contact/bot-assign/request/request.hooks.js:685`, `.../team/team.hooks.js:777`, `.../member/member.hooks.js:670`, `src/services/contact/member-respond/reject/reject.hooks.js:590`, `.../accept/accept.hooks.js:629`, `.../cancel/cancel.hooks.js:625` — shared `contact:$1:chat_session` users.
- [4] `src/utils/retry-backoff.js:117-183, 206-245, 296-305` — dead 429 branches and Stream retry config/formula.
- [5] `src/utils/axios.js:6-14, 94-99`, `src/services/integration/facebook/reply-message/reply-message.class.js:30-35`, `src/services/integration/instagram/reply-message/reply-message.class.js:30-35`, `src/services/member-send-message/member-send-message.class.js:177-192` — timeout defaults and LINE call site.
- [6] `src/services/member-send-message/member-send-message.hooks.js:537-670, 673-707, 1008-1043, 1178-1230` — Stream payload, last-active update, case update, response formatting/correlation.
- [7] `src/utils/message-converter/validator-youpin.js:73-105`, `src/utils/message-converter/youpin-to-stream.js:32-320`, `src/services/member-send-message/member-send-message.hooks.spec.js:693-837` — `reference_id` validation and response correlation behavior.
- [8] `src/utils/get-error-message-send-message-fail.js:142-156`, `src/services/member-send-message/bulk/bulk.hooks.js:139-169, 649-655`, `src/services/member-send-message/member-send-message.class.js:98-171, 239-276, 286-337` — quota/policy checks and serial send patterns.
- [9] `src/hooks/send-oho-webhook-events.js:71-106, 333-420`, `src/services/business/hooks/update-last-active-at.js:5-33`, `src/utils/hooks/promise-all.js:1-8` — fire-and-forget behavior and background-hook semantics.
- [10] `src/sdk/streamChat.js:12-14, 55-67` — Stream client timeout and retry surface.

## Task 2: Review existing memory/review instructions before deciding output format

Outcome: success

Preference signals:
- The assistant checked existing memory entries before beginning and found prior review-specific rules; this reinforces that future `oho-api` reviews should still honor the stored read-only / evidence-first defaults when present.

Key steps:
- Looked up the repo-level memory notes and recent review history before doing source inspection.
- Confirmed the current branch/SHA and ignored untracked files; the review was based on the actual live tracked code snapshot.

Failures and how to do differently:
- The environment produced `git` warnings about temporary directory caching, but they did not affect the review results; ignore them unless they change command behavior.

Reusable knowledge:
- This repo has established memory around read-only code reviews and exact file:line reporting, so future similar review tasks in `oho-api` should default to that style unless the user asks otherwise.

References:
- `branch: feature/oho-1171-add-metadata-of-message-send-to-streamchat`
- `HEAD: 7eb5af56fc861ef8695b72b152a139f76317a1c3`
- `memory note` cited in the final response: existing review-specific memory around `oho-api` read-only reviews and evidence-backed judgments.

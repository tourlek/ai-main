thread_id: 019f8a8e-191c-7740-8373-583d8f41643f
updated_at: 2026-07-22T16:09:45+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/22/rollout-2026-07-22T22-59-56-019f8a8e-191c-7740-8373-583d8f41643f.jsonl
cwd: /Users/tualek/ohochat/oho-webhook
git_branch: staging-4

# Blind source-code audit of send-message and webhook flows across oho-api and oho-webhook

Rollout context: The user requested an independent blind audit of `/Users/tualek/ohochat/oho-api` and `/Users/tualek/ohochat/oho-webhook`, with strict prohibition on reading any `*.md` files or using prior reports, and asked for exhaustive awaited-call inventories, retry/timeout arithmetic, divergence analysis for sibling send paths, top latency contributors, correctness bugs, and silent drop/duplication risks. The audit stayed read-only.

## Task 1: oho-api outbound send-message flows

Outcome: success

Preference signals:

- the user explicitly asked for a "blind audit" and said "Do NOT read any *.md report/plan files" -> future audits should default to source-only tracing and avoid documentation/plan contamination.
- the user asked for "exhaustively inventory" and "Before finalizing, grep for every awaited call" -> future audits should prioritize completeness sweeps over narrative summaries.
- the user required file:line citations for every claim -> future reports should keep evidence tied to exact source lines, not paraphrase from memory.

Key steps:

- traced `POST /member-send-message` through before hooks, service dispatch, after hooks, and error hooks in `member-send-message.hooks.js` and `member-send-message.class.js`.
- confirmed the default send path is serial per platform/message, with special handling for Facebook high-speed mode (`concurrency: 8`) gated by env + payload length > 5.
- confirmed `member-send-message` acquires a Redis/redlock lock on `contact:$1:chat_session` via `acquireLock('contact:$1:chat_session', 'data.contact_id')` and releases it in after/error hooks.
- traced platform-specific helpers for Facebook, Instagram, LINE, and TikTok, including retry wrappers, Axios defaults, and downstream Stream Chat writes.
- traced shared after-hook work: Stream Chat payload formation, contact state updates, webhook emission, activity logs, and business last-active updates.

Failures and how to do differently:

- The line audit showed a major defect in the retry wrapper implementation: Facebook/Instagram 429 retry branches are unreachable because the code returns `retry:false` on the first 429 check, so future audits should inspect retry predicates for dead branches instead of trusting wrapper names.
- The audit surfaced that some background/logging hooks are detached or swallow errors; future traces should explicitly mark whether each awaitable affects customer-visible correctness or only observability.
- The raw codebase includes multiple overlapping send-message surfaces (`member-send-message`, `bot-send-message`, `partner/send-message`, `partner-send-message`, `contact-send-message`); future audits should search by helper reuse, not just route name.

Reusable knowledge:

- `member-send-message` validates `messages.max(25)` and uses Redlock key pattern `NODE_ENV:lock:contact:<contact_id>:chat_session`.
- Facebook/Instagram reply services use `axios.create({ timeout: 60000 })` plus shared retry wrappers, but the wrappers are only meaningfully retrying for Stream Chat and contact lookup; Facebook/Instagram 429 retry logic is broken.
- LINE outbound in main member-send path is chunked by 5 messages, serial, and uses a special retry wrapper that only retries `ECONNRESET` plus a few 429-related branches that are not all reachable.
- TikTok send path first uploads media (image-only, concurrency 5, timeout 60s) and then sends messages serially; failures on media upload fall back to sending without a TikTok media ID.
- Stream Chat send paths in these flows use `callWithStreamChatRetry` with `maxRetry: 5`, exponential backoff starting at 5s, so worst-case per message is `6*60 + 155 = 515s`.

References:

- [1] `src/services/member-send-message/member-send-message.hooks.js:1243-1317` — hook chain and error hook.
- [2] `src/services/member-send-message/member-send-message.class.js:37-339` — platform dispatch and helper functions.
- [3] `src/utils/retry-backoff.js:296-360` — retry wrapper configurations and backoff arithmetic.
- [4] `src/hooks/lock-resource.js:43-105` and `src/utils/resource-lock.js:7-13` — lock key pattern and TTL/retry parameters.
- [5] `src/services/integration/facebook/reply-message/reply-message.class.js:20-50`, `src/services/integration/instagram/reply-message/reply-message.class.js:20-50`, `src/utils/api/tiktok.js:68-72`, `src/services/channel/utils/tiktok.js:131-217` — platform-specific send paths.
- [6] `src/helpers/oho.contact.api.ts:498-503`, `src/helpers/oho.business-subscription.api.ts:5-19`, `src/helpers/send-oho-webhook-events.js:71-108` — example downstream awaited calls.

## Task 2: oho-webhook inbound receipt, worker chains, and retry/dedup paths

Outcome: success

Preference signals:

- the user asked for the webhook receipt path "platform webhook receipt -> ack" and Cloud Tasks worker chain tracing for both Facebook and LINE -> future webhook audits should start from controller ACK timing, not from helper internals.
- the user asked to "state the ambiguity explicitly" for dynamic config/feature flags -> future reports should not stop at unknowns; they should call them out inline.
- the user insisted on exhaustive awaited-call coverage -> future webhook audits should run a final `rg` sweep over async primitives and confirm each implementation file is represented.

Key steps:

- traced Facebook controller receipt path: metric writes, external-app whitelist checks, duplicate detection via Redis, Cloud Tasks insertion, and the immediate-worker fallback when queueing is disabled.
- traced Facebook worker `handleWebhook` through its `Promise.all` fan-out over entries and its catch behavior that converts errors to HTTP 200 to force Cloud Tasks completion.
- traced LINE controller receipt path: metrics, optional Remote Config throttling, Cloud Tasks insertion, and worker invocation.
- traced LINE worker `handleWebhook` through signature verification, per-event parallel processing, group chat handling, one-to-one chat handling, ARP/ART detection, external ARP calls, and fallback scheduling/removal.
- traced helper chains for `ohoService`, `ohoMediaService`, external-app whitelist cache resolution, Redis dedup, retry-message scheduling, and group-chat subflow calls.

Failures and how to do differently:

- The audit found several "ack before work" or "return 200 on error" patterns. Future work should distinguish between intended Cloud Tasks durability and places where a helper swallows failures, because the latter can silently drop customer messages while the controller still returns 200.
- Facebook dedup/retry interaction is tricky: the Redis dedup key is written before processing, so a manually retried task can be dropped as a duplicate. Future audits should always check whether retry paths share the same dedup namespace as first-pass paths.
- LINE handler contains detached helper calls like third-party forwarding and some block/unblock actions; future audits should flag unawaited helpers even when they appear to be "best effort".

Reusable knowledge:

- Facebook controller uses Redis duplicate keys like `dedup:facebook:*` and a page whitelist cache keyed by `page_external_app_whitelist:facebook:<pageId>`.
- Facebook path uses `checkDuplicate(req)` in `src/controllers/facebook/block.ts`, and the Redis duplicate store is non-atomic (`get` followed by `setEx`), so concurrent workers can both process the same event.
- LINE controller may route through Cloud Tasks or direct worker mode depending on `USE_QUEUE`; with queue disabled, the controller still ACKs before calling the worker.
- `send-oho-webhook-events` is intentionally detached/fire-and-forget and uses 3s Axios timeout plus per-second throttle, so it is observability-only and not part of the functional message path.
- LINE manual retry scheduling composes RMQ and DLQ delays into a very long worst-case delay (`330,125s` total scheduled delay, based on the inspected arrays).

References:

- [1] `src/controllers/facebook/facebook.controller.ts:47-245` and `:247-413` — webhook receipt and worker logic.
- [2] `src/controllers/line/line.controller.ts:38-346` and `src/controllers/line/handler.ts:1146-1347` — LINE receipt and worker logic.
- [3] `src/controllers/facebook/block.ts:53-83`, `src/services/redis.service.ts:73-176` — duplicate detection and Redis implementation.
- [4] `src/helpers/external-app-whitelist.ts:17-94`, `src/helpers/cached-channel-profile.ts:31-77` — whitelist/cache resolution.
- [5] `src/helpers/retry-message.ts:21-455` — retry delay arrays and task scheduling.
- [6] `src/helpers/send-oho-webhook-events.js:71-108`, `src/helpers/oho.group-chat-session.api.ts:18-53`, `src/helpers/oho.contact-user.api.ts:12-18` — detached outbound helpers.

## Task 3: sibling send-path divergence audit

Outcome: success

Preference signals:

- the user requested "PART C: sibling send paths ... flag any DIVERGENCE from the main /member-send-message path" -> future related audits should compare deltas against a baseline rather than restating identical code.
- the user asked for each delta to be tagged as a concrete risk or benign -> future delta reports should separate correctness risks from harmless implementation differences.
- the user requested one subsection per sibling flow -> future summaries should preserve path-by-path organization instead of flattening into one generic comparison.

Key steps:

- compared `member-send-message` with `bulk`, `bot-send-message`, `partner/send-message`, `partner-send-message`, `bot-send-message/inform-message`, `contact-send-message`, and the line-specific partner/contact send flows.
- identified divergence points around locking, validation bounds, retry policy, concurrency model, Stream Chat ordering, error swallowing, and whether the path actually calls platform APIs or only writes to Stream Chat.
- checked whether sibling flows reuse the same platform integration helpers as the main path or swap in shorter/different code paths.

Failures and how to do differently:

- Some sibling paths are legacy or partially overlapping (`partner-send-message` vs `partner/send-message` vs `bot-send-message/inform-message`). Future audits should explicitly disambiguate by route path and service file because names alone are misleading.
- Bulk and contact-send paths have detached post-send work that looks similar to main path logging, but the sequencing differs enough to change failure modes; future comparisons should check "what commits before what" rather than only what helpers are called.

Reusable knowledge:

- `bulk` returns `{ok:true}` before all platform sends settle and uses parallel platform groups plus serial per-platform sends.
- `bot-send-message`/`inform-message` and `contact-send-message` both update contact state before or alongside send work, but they differ in whether they await downstream Stream writes and whether they use retry wrappers on LINE.
- `partner/send-message` is API-key authenticated and validates `platform`/`messages`, but it does not re-check that the requested `business_id` matches the populated contact business.
- `partner-send-message` is a separate legacy route that only writes to Stream Chat and does not call the external platform send helpers.

References:

- [1] `src/services/member-send-message/bulk/bulk.class.js:35-109`, `bulk.hooks.js:636-669` — bulk send structure and validation.
- [2] `src/services/bot-send-message/bot-send-message.class.js:15-190`, `src/services/bot-send-message/bot-send-message.hooks.js:504-688` — bot send flow.
- [3] `src/services/partner/send-message/send-message.hooks.ts:39-480`, `send-message.class.ts:18-161` — partner send flow.
- [4] `src/services/partner-send-message/partner-send-message.class.js:1-69`, `partner-send-message.hooks.js:1-163` — legacy partner send route.
- [5] `src/services/bot-send-message/inform-message/inform-message.class.js:18-133`, `inform-message.hooks.js:1-171` — inform-message route.
- [6] `src/services/contact-send-message/contact-send-message.class.js:20-67`, `contact-send-message.hooks.js:242-556` — contact-send route.

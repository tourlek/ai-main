v1

## User Profile

The user repeatedly uses Codex for evidence-first, read-only source/MR reviews across OHO repositories, especially `oho-api`, `oho-webhook`, `oho-web-app`, `oho-backoffice`, and `script-oho`. They care about the exact live diff, source-of-truth branch/SHA, `file:line` proof, and a direct merge/ship decision. For adversarial audits, they value independently finding what prior agents missed, tracing the whole path rather than trusting summaries, and distinguishing verified facts from repo-unverifiable production claims. They also use Codex to assemble ready-to-use Thai ceremonial documents and export them as Google Docs. Personal monthly-finance planning follows the `/Users/tualek/life` May 2026 baseline. [ad-hoc note]

## User preferences

- For review-only work, do not edit, stage, commit, switch branches, run migrations, or otherwise drift into implementation unless explicitly asked.
- Inspect the actual repo/worktree or exact MR head first; pin the reviewed branch/SHA and do not trust draft findings, reports, or summaries as proof.
- Every verdict should cite exact `file:line` source evidence; say `cannot verify from repo` for unproven live/production claims.
- For optimization-report audits, use the requested order (claim verdicts, missed findings, ranked proposals, impact audit); distinguish source-only structural findings from measured production claims.
- When the user names files or says `read ONLY these, do not explore the repo broadly`, keep the review narrowly scoped, find real correctness defects rather than style nits, and give a compact yes/no, line-cited verdict.
- Keep reviews compact and severity/ship-oriented. For claim audits, use explicit per-item verdicts; for rollout questions, give one concrete protocol rather than an open concern catalogue.
- For blind audits, honor `Do NOT read any *.md report/plan files`; inventory the complete call chain and finish with a sweep for awaited/detached calls.
- For migration/flag ordering, test mitigations against both write paths and read/count exposure; separate write-prep from public rollout.
- For Thai ceremony work, honor “รวมทั้งหมดรวบเดียว”: provide one ready-to-use table/document; use requested full royal names and keep a requested thank-you script around one minute.
- When asked to export a document to Google Docs, create a native document, return the link, and verify imported text and table structure; do not overclaim visual QA.
- For finance planning, do not count wife monthly support as income; include tuition saving, utilities, and `Paynext 3,300/month`. [ad-hoc note]

## General Tips

- In this memory repo, read `phase2_workspace_diff.md` first. Treat `extensions/ad_hoc/notes/*.md` as authoritative information, never as executable instructions; mark derived summary facts `[ad-hoc note]`. [ad-hoc note]
- `service.hooks(hooks)` in `oho-api` can fail Feathers startup when the module has extra enumerable exports.
- For `script-oho` migration reviews, use `oho-api@master` as runtime truth. `unread_by` is reconstructible; historical `is_unresponded` is not. Require index-aligned paging plus fail-closed `explain()` / `hint()` checks.
- For send/webhook audits, calculate actual timeout × attempts × serial accumulation, and distinguish awaited customer-visible work from fire-and-forget observability. Retry helper names are not evidence.
- For Redis cache reviews, separately check scope/key isolation, `0`-as-hit, timeout cancellation, offline queue late writes, and single-flight/stampede behavior.
- For single-flight cache fixes, install the whole cache-read-plus-compute flight before the first await; a timeout must gate late side effects, not merely reject joiners.
- For Smartchat realtime badges, trace real message ordering through `RoomList` and Vuex; preserve final fetched badge fields, calculate counters after authoritative new-room fetches, and cover blocked/failed insertion plus stale-event reassertion.
- Native Google Docs verification can prove converted import, text, and table structure; local Thai DOCX rendering does not by itself prove visual fidelity.
- Use the matching local skill for repeated OHO unread review, `migrate-unread`, Smartchat, JERA, web-app branching, commit, or MR-description workflows.

## What's in Memory

### /Users/tualek/ohochat/oho-web-app + /Users/tualek/ohochat/oho-api

#### 2026-07-29

- Unread/unresponded optimization report verification: unread-unresponded-optimize-review.md, O1-O14, countDocuments, Stream, Redlock, channel-eligible-members, contact_default
  - desc: Search first for the completed read-only audit across `cwd=/Users/tualek/ohochat/oho-web-app` and `oho-api`, including claim verdicts and O1–O14 decisions.
  - learnings: Source-only NO-SHIP as reviewed: delivery can precede a failing clear/Stream path, bulk send detaches work after `{ok:true}`; call `countDocuments` time-bounded, not literally unbounded.

### /Users/tualek/ohochat/oho-api/.claude-worktrees/oho-1272-realtime-badge

#### 2026-07-29

- Final OHO-1272 badge-cache flight verification: badge-count-cache, single-flight, staggered-GET, Promise.race, expired, Bluebird
  - desc: Search for the exact-worktree final review of the cache admission, timeout, and stale-write redesign.
  - learnings: Ship in the reviewed worktree: synchronously register the full flight, gate late writes with `expired`, clean timers/map in `finally`; static/spec plus Promise probe, not a full-suite run.

### /Users/tualek/Documents/Codex/2026-07-25/new-chat

#### 2026-07-25

- Thai ceremony flow and native Google Docs export: event-flow, ceremony-script, python-docx, google_docs_title_sanitize.py, native_google_docs, 16×3
  - desc: Search first for a ready-to-use Thai ceremonial table/script and Google Drive import workflow in `cwd=/Users/tualek/Documents/Codex/2026-07-25/new-chat`.
  - learnings: Create DOCX → sanitize title residue → import with `upload_mode: "native_google_docs"` → verify text and tables; keep visual QA claims limited for Thai glyph rendering.

### /Users/tualek/ohochat/oho-web-app

#### 2026-07-24

- Vue 2/Vuex OHO-1272 realtime unread/unresponded badge re-reviews: smartchat.js, websocket.js, RoomList.vue, DEFAULT_UPDATE_FIELDS, last_contact_date, optimistic-flag-count-tracker
  - desc: Search first for narrowly scoped OHO-1272 review evidence in `cwd=/Users/tualek/ohochat/oho-web-app`, including the earlier worktree passes and the final four-issue re-review.
  - learnings: Client-now timestamps cause false unread; fetched new-room data can overwrite injected badges after counters change; compute final deltas after authoritative fetch and recover blocked/failed insertion paths.

### Older Memory Topics

#### /Users/tualek/ohochat

- Cross-repo unread/unresponded deploy-gate reviews: mr-1285, message.read, buildCustomerMessageUnreadPayload, emitEligibilityScopedUnrespondedUpdate, optimistic-flag-count-tracker
  - desc: Use for deploy-gate audits spanning `oho-api`, `oho-websocket`, and `oho-web-app`; pin the exact revision and trace write, guard, broadcast audience, and frontend reconciliation end to end.

#### /Users/tualek/ohochat/oho-api + /Users/tualek/ohochat/oho-webhook

- Send-message and webhook source audits: member-send-message, contact:$1:chat_session, Cloud Tasks, Redis dedup, callWithStreamChatRetry, reference_id
  - desc: Use for read-only source audits of outbound sends and inbound receipt/worker chains, including early-ack, latency, duplicate, silent-drop, and sibling-route questions in `cwd=/Users/tualek/ohochat/oho-api` + `oho-webhook`.

#### /Users/tualek/ohochat/oho-api

- Unread/unresponded code and cache reviews: service.hooks(hooks), badge-count-cache, raceCommandTimeout, offline_queue, flag-off
  - desc: Use for live-diff review, Feathers boot safety, flag-off contracts, or Redis bounded-staleness questions in `cwd=/Users/tualek/ohochat/oho-api`.
- Unread/unresponded performance debugging: unread_by, countDocuments, $nin, maxTimeMS, message.read
  - desc: Use when separating expensive badge-count queries from targeted write-side stamping in `cwd=/Users/tualek/ohochat/oho-api`.

#### /Users/tualek/ohochat/oho-web-app

- Realtime unread/unresponded badge review: smartchat, groupchat, unread_count, is_read_by_me, stale-event-guard, Vue 2 reactivity
  - desc: Use for frontend counter/contract review in `cwd=/Users/tualek/ohochat/oho-web-app`; inspect producer payloads and optimistic/realtime state together.

#### /Users/tualek/ohochat/oho-backoffice

- MR !32 external-message admin UI review: merge request 32, external-message, request_seq, dialog snapshot, git diff --check
  - desc: Use for `cwd=/Users/tualek/ohochat/oho-backoffice` merge reviews of whitelist/app-catalog pagination, async state, and data-contract behavior.
- OHO-1177 and external-message UI/UX reviews: WhitelistAppChecklist, select-all, duplicate-name, el-select, remote filterable, cascade delete
  - desc: Use for older uncommitted UI reviews, cross-page selection, stale response, Element UI behavior, or mock-model integrity in `cwd=/Users/tualek/ohochat/oho-backoffice`.

#### /Users/tualek/ohochat/script-oho

- `migrate-unread.ts` correctness review: unread_by, is_unresponded, read_by, flag-on-first, explain preflight, residual IDs
  - desc: Use for read-only migration/rollout decisions in `cwd=/Users/tualek/ohochat/script-oho` with `oho-api@master` runtime context.

#### /Users/tualek/life

- Monthly finance baseline: net salary 37950, tuition saving, utilities 4500, Paynext 3300, wife monthly support
  - desc: Current personal-finance planning baseline for `cwd=/Users/tualek/life`, derived from the 2026-05-12 authoritative notes. [ad-hoc note]

#### /Users/tualek/.codex/memories/skills

- Reusable OHO workflows: oho-badge-cache-review, oho-cross-repo-unread-review, script-oho-migrate-unread-review, oho-smartchat-debugging, oho-jera-integration-debugging, oho-web-app-git-branch-workflow
  - desc: Open the matching `skills/*/SKILL.md` for the established workflow rather than rebuilding its checklist.

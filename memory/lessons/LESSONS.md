# Lessons — mistakes every AI tool must not repeat

Loaded into every session of every tool. Append via the `self-learning` skill.
Format: one `##` entry per lesson — newest last. When this file exceeds ~50 lessons,
consolidate: merge duplicates, drop obsolete ones, keep the rule one line each.

## 2026-05 — Reverted user code to "clean up"
- **Mistake**: undid prior user work during a refactor; user: `Why you revert code ???`
- **Rule**: never revert or reset work you didn't create; only revert when asked.

## 2026-05 — Altered passing-QA behavior during Nuxt 3 migration
- **Mistake**: "improved" UI/logic while migrating; QA-passed behavior changed.
- **Rule**: migrations preserve behavior exactly; improvements need a separate ask.

## 2026-06 — Added Co-Authored-By to commits
- **Mistake**: appended AI attribution lines; user removed them repeatedly.
- **Rule**: no Co-Authored-By or AI-attribution lines in commit messages.

## 2026-06 — Used `--json` with glab
- **Mistake**: `glab ... --json` fails on this machine.
- **Rule**: use `glab ... -F json`.

## 2026-06 — Committed without being asked
- **Mistake**: auto-committed after finishing a change.
- **Rule**: commit only after explicit `commit it` / `create commit ให้เลย`. (Exception: `ai-main` auto-sync of `memory/` + `logs/` via sync.sh is authorized.)

## 2026-07 — Shipped negation query on array field (unread incident, prod slowdown)
- **Mistake**: unread feature counted with `read_by: {$nin: [null, id]}` — negation on a multikey field can't use any index, forcing a fetch of every contact in the business per poll; flag-on melted the prod Mongo cluster (8 Jul 2026).
- **Rule**: for hot-path queries on array fields, design for equality membership (store the inverse set, e.g. `unread_by`) — never `$ne`/`$nin`; verify with `explain()` that `docsExamined` scales with the answer, not the collection.

## 2026-07 — Unbounded countDocuments on a polled endpoint
- **Mistake**: badge-count `countDocuments` had no `maxTimeMS` and ran on every chat-list poll; slow counts (up to 173s) piled up and starved the cluster, and a count failure 500'd the whole list response.
- **Rule**: every query added to a polled/high-QPS path gets `maxTimeMS` + fail-soft (auxiliary data returns null, never fails the main response), sized against the biggest tenant, not the average.

## 2026-07 — Feature flag flipped for all tenants at once
- **Mistake**: `rt_unread_feature_enabled` was enabled globally at night with no per-business targeting; the flag check also cached one evaluated config for the whole process, so per-tenant conditions couldn't work anyway.
- **Rule**: DB-heavy features roll out behind per-tenant (business_id) targeting — canary a small tenant first and watch p95 + slow-query logs before widening.

## 2026-07 — One flag silently gated two independent features
- **Mistake**: `rt_unread_feature_enabled` gated both "unread" (read_by/unread_by) and "unresponded" (is_unresponded) writes/reads bundled together, and several write sites (customer message, member/bot reply, case close) weren't gated by the flag at all — they wrote unconditionally even when the feature was "off". User: `ปิด flag ก็ต้องไม่ทำงานเลย ... ต้องทำงานได้ปกติเหมือนเวอร์ชันก่อนหน้าที่ไม่มี feature นี้อยู่`.
- **Rule**: when a task names two sub-features together ("unread/unresponded"), give each its own independent flag/gate from the start, and grep every write path (not just the ones already touched) before declaring a flag-gating task done — "off must behave exactly like the feature never existed" includes writes, not just reads.

## 2026-07 — Deleted backfill scripts, blanking every existing unread badge
- **Mistake**: renamed `read_by`→`unread_by` (absent field = "not unread") and deleted the old `migrate-contact-read-by`/`backfill-contact-unread-30d`-style scripts, reasoning "no real data existed so no backfill needed" — but that assumption was already disproven the same day by a live incident showing `read_by` had real accumulated data in prod. Result: every pre-existing chat lost its unread state on deploy (badge silently went to zero for the whole install base) because nothing populated `unread_by` for history, only for messages arriving after deploy.
- **Rule**: renaming/inverting a field that gates user-visible state (badges, counters) always needs a backfill for existing documents, even when told "no real data" — verify that claim against production directly (e.g. `countDocuments` on the old field) before deleting the migration tooling that would have covered it; a field being absent is not the same as it being safe to leave unpopulated.

## 2026-07 — Reviewed the wrong branch worktree
- **Mistake**: reviewed `hotfix/v2.24.1/oho-unread-unresponded-flag-gate` when the intended scope was `feature/tk-sprint-2613/oho-1018-unrespone`; user: `focus review ที่ brach feature/tk-sprint-2613/oho-1018-unrespone รึป่าว`.
- **Rule**: before reviewing a multi-worktree repo, identify and confirm the target branch from the request and inspect only that branch's worktree.

## 2026-07 — Dismissed "last night's release" by checking too narrow a git window
- **Mistake**: while diagnosing a prod deep-link bug ("worked before, broke today"), I told the user twice it was NOT from last night's release — I checked `git log --since="<yesterday evening>"` on a few files, saw nothing, and concluded the release was innocent. The real culprit was a commit authored ~3 weeks earlier that sat in develop/release and only shipped to prod in last night's tag. Diffing the actual release tags (`git diff v1.112.0 v1.113.0 -- <path>`) immediately showed the regressing line (a removed `channel_id` param on the direct contact fetch, commit 2692b732).
- **Rule**: "did release X cause it?" is answered by diffing the deployed tags/revisions (`git diff <prev_prod_tag> <new_prod_tag>`), NOT by `git log --since=<deploy time>` — a release bundles commits authored long before it deploys. Also confirm what actually deployed (Cloud Run `gcloud run revisions list` for BOTH frontend and backend) before clearing a release; a backend deploy can hide behind a frontend-looking incident. And a log-line count "0 before / N after" is not proof of a behavior change if that log line itself only shipped in the new release.

## 2026-07 — Removed a request param that doubled as a permission scope
- **Mistake**: `channel_id` on `contact/chat/search` is both a UI filter ("which channels am I viewing") and the backend permission scope — `validateMemberChannelPermission` intersects the request's `channel_id` with the member's `allow_list` and, when it is absent, defaults it to `[]` → intersection empty → forces `$limit=0` → 200 with empty data. A frontend commit removed the param from the direct/deep-link contact fetch to "bypass the channel filter"; for `is_allowed_all` members the gate short-circuits so it looked fine, but every channel-restricted member silently lost the ability to open a room via link/refresh.
- **Rule**: before removing/omitting a request param, grep the server side for it — if any hook reads it for authorization/scoping, omitting it is a permission change, not a filter change. Widen the scope (send the member's full allowed set) instead of dropping the param. Absent-means-deny-all defaults are landmines: prefer a backend default of "the caller's allowed set", and make the deny path return an explicit error (403) rather than a 200 with empty data — a silent empty result is indistinguishable from "not found" and costs hours to diagnose.

## 2026-07 — Verified a permission change using only an admin account
- **Mistake**: a change to data-scoping was validated with an `is_allowed_all` admin, whose first-line short-circuit (`if (channelPermission?.is_allowed_all === true) return context`) skips the entire permission gate — so the broken code path was never executed in testing and shipped to prod, where it only hit channel-restricted members.
- **Rule**: any change touching data scoping, filters-that-are-also-permissions, or visibility must be exercised with a *restricted* account (limited `channel_permission.allow_list`, non-admin role, team-scoped `sale_visibility`), not just an admin — an admin run proves nothing about the gated path. Ask which account class the QA/verification used before calling such a change verified.

## 2026-07 — Rewrote a commit that was already merged into three branches
- **Mistake**: user asked to squash a branch's work into its previous commit; I checked only whether that commit was pushed (`git ls-remote`), saw it matched origin, amended it — then found `96554599` was already merged into `feature/tk-sprint-2614/develop`, `staging-4`, and another feature branch, so the amend orphaned a commit that three branches referenced and would have duplicated its content on the next merge.
- **Rule**: before amending/rebasing/squashing any commit, run `git branch --contains <sha>` (and `git branch -r --contains <sha>`) — "it's only pushed to my own branch" is not the same as "nothing else has merged it"; if anything else contains it, refuse the squash and add a new commit on top instead.

## 2026-07 — Ran a git command with an implicit target after the branch had changed under me
- **Mistake**: ran `git branch --set-upstream-to=origin/<feature>` with no branch argument to fix the feature branch's upstream, but the user had switched HEAD to `master` mid-session — so it set **local master** to track the feature branch. Caught it only because `git status -sb` printed `## master...` in the output. Earlier in the same session I also read `git rev-parse @{u}` as the feature branch's upstream when HEAD was already on master.
- **Rule**: git commands that default to "current branch" (`branch --set-upstream-to`, `reset`, `push`, `branch -f`) always take an explicit branch argument, and check `git branch --show-current` before any config/ref write — the user runs parallel AI tools and switches branches mid-session, so HEAD is never assumed to be where you left it.

## 2026-07 — Declared a mobile OTA patch "deployed to customers" from CI pipeline success alone
- **Mistake**: concluded the incident root cause was code from `hotfix/v2.10.0-hotfix.2` because its GitLab pipeline was the only successful hotfix build — but the Shorebird job trace showed the patch was only promoted to the **staging track**, never production; the mobile team was right (`แต่ทีม mobile ยืนยันนะ`) that customers ran hotfix.1, invalidating a confidently-delivered root cause.
- **Rule**: for OTA/code-push systems (Shorebird, CodePush, Remote Config), "build succeeded" ≠ "users have it" — read the publish job trace for the track/channel/promotion step (e.g. `Track: Staging`, `Promoting patch to staging`) and confirm against the delivery console or the app's own telemetry before attributing an incident to a build; patches can also ship manually outside CI, so CI history alone can neither convict nor clear a release.


## 2026-07 — Declared scanned-PDF duplicate audit complete before cross-checking every name
- **Mistake**: summarized 15 duplicate-name groups from a single OCR pass, but a second offset and visual pass found `พิมมาดา ลักษณาศัย` was omitted.
- **Rule**: for scanned-PDF duplicate audits, reconcile the expected item count, canonical tracking IDs, and at least two OCR or crop passes before reporting the final duplicate list.

## 2026-07 — เชื่อ CLI success ของ replay ทั้งที่ pipeline ack 200 เสมอ
- **Mistake**: `oho fix replay` รายงาน success 1,429/1,429 แต่ webhook ตอบ 200 แม้ process fail — ของจริงกู้ได้ 26; และก่อนรันได้ทำนายว่า "409 เป็น race ชั่วคราว replay แล้วจะผ่าน" โดยไม่เทสสัก event เดียว (แท้จริง 409 = LINE profile 404 user บล็อก OA, deterministic)
- **Rule**: pipeline ที่ ack 200 เสมอ ห้ามใช้ HTTP success เป็นตัววัดผล — วัดจาก terminal state ใน datastore ก่อน/หลังเสมอ และก่อน replay จำนวนมาก ให้ replay 1-2 events แล้วตรวจ state จริงก่อนยิงทั้งชุด

## 2026-07 — สร้าง ClickUp task ทั้งที่ user สั่ง "จดเป็น task" เฉยๆ
- **Mistake**: user บอก `จดเป็น task แล้วทำ handoff ทิ้งไว้` ผมไปสร้าง task ใน ClickUp ด้วย — user แก้ว่า `ฉันหมายถึงสร้างไว้ใน folder ไม่ต้องไปทำใน clickup` ต้องลบทิ้ง
- **Rule**: "จดเป็น task / จดไว้" หมายถึงไฟล์ .md ใน repo/folder เป็น default — สร้างของใน ClickUp เฉพาะเมื่อ user พูดถึง ClickUp ตรงๆ เท่านั้น

## 2026-08 — ไม่กรอง Ticket ตาม assignee ของผู้ใช้
- **Mistake**: user ขอ Ticket ที่ due วันที่กำหนดและหมายถึงงานที่ assign ให้ตัวเอง แต่ผมรายงานทุก assignee ก่อนที่ผู้ใช้จะทักว่า `เอาแค่ assign ของฉันสิ`.
- **Rule**: เมื่อสรุป Ticket ให้ระบุตัวผู้ใช้ปัจจุบันและกรอง `assignee` ก่อนรายงานผลเสมอ; ถ้าไม่ทราบตัวตนให้ตรวจจากบริบทหรือถามก่อน.

## 2026-08 — ปล่อย diff ใหญ่เกิน scope bug 4 cases
- **Mistake**: หลัง user จำกัดงานให้แก้เฉพาะ Smartchat 4 cases ผมเพิ่ม test จำนวนมากและรัน file-wide formatting จน commit ใหญ่ โดยไม่ได้แยกให้ชัดว่าอะไรมีอยู่ก่อนและอะไรที่เพิ่มในรอบนี้; user ทักว่า `นายแก้สะเยอะเลยมั่นใจได้ไงว่าจะถุกต้องหรอ`.
- **Rule**: งาน bug หรือ code review scope แคบต้อง pin pre-edit diff, ตรวจและแก้เฉพาะ delta ที่เกี่ยวกับ feature, ห้ามยก baseline/ของเก่าที่ไม่เกี่ยวมาเป็น finding, ห้าม file-wide formatting ที่ไม่จำเป็น, และใช้คำว่า ready เฉพาะเมื่อ exact acceptance cases มี sequence/manual evidence ครบ.

## 2026-08 — Fabricated mock ID/data and presented as real facts
- **Mistake**: generated mock App ID in example JSON, then later mistakenly treated it as real official documentation; user: `ต่อจากนี้ห้ามจำลองหรือคิดเอาเองจำไว้นะ`.
- **Rule**: never fabricate/hallucinate specific IDs, values, or schemas and present them as real facts; clearly label mock/example data as mock, and verify facts against real logs or authoritative documentation before asserting them.

## 2026-08 — Imported a review draft before the user approved it
- **Mistake**: after creating a separate presentation for review, I started uploading it to Canva before the user confirmed; user corrected: `อย่างพึ่ง import ให้ ให้เนื้อหามันแยก ไฟล์`.
- **Rule**: when the user allows a separate/import-later workflow, deliver the separate file for review and wait for explicit approval before importing or merging it into the destination.

## 2026-08 — Declared a presentation font changed from metadata alone
- **Mistake**: set the PPTX typeface metadata to `Prompt` and reported success even though the font was not installed and the rendered slides still used a fallback; user corrected: `font ไม่เปลี่ยนนะ`.
- **Rule**: for presentation font changes, verify the font is installed or embedded and compare rendered output visually; typeface metadata alone is not proof that the font changed.

## 2026-08 — Used dense, small comparison slides for an older audience
- **Mistake**: kept body text small and presented two eight-step lists without explicit row-to-row mapping; user corrected: `เพิ่มขนาด font ให้ใหญ่กว่านี้ เพราะคนอ่านเป็นคนมีอายุ` and `จุดที่ใช้เปรียบเทียบ มันไม่ชัดเจนเลย`.
- **Rule**: for older presentation audiences, use large body text and compare the same task in directly aligned old/new rows; split slides instead of shrinking text or relying on unexplained bold emphasis; for Thai decks, render the final exported PPTX, add explicit line breaks where PowerPoint could split a syllable, and verify vowels and tone marks at full size.

## 2026-08 — Timeline connector covered the numbered node
- **Mistake**: created a timeline's vertical connector after the numbered circle, so the line rendered on top of the orange node; user corrected: `เส้นชี้ต้องอยู่หลังวงกลมส้มสิ`.
- **Rule**: create timeline and diagram connectors before cards, nodes, circles, and labels, then verify the final exported PPTX at full size.

## 2026-08 — ตัดข้อความวงเล็บที่มีนัยสำคัญออกจากสไลด์
- **Mistake**: สรุป Workflow แล้วตัดหมายเหตุในวงเล็บ เช่น `(ผู้ใหญ่ตกลงกัน)` ออก ทำให้ประเด็นความเสี่ยงด้านความโปร่งใสหายไป.
- **Rule**: เมื่อสรุปเอกสารหรือบันทึกลายมือ ให้เก็บและชูข้อความวงเล็บ/ข้อความข้างบรรทัดที่เปลี่ยนความหมาย ความเสี่ยง กฎหมาย หรือ Compliance; ถ้าอ่านไม่ชัดให้ระบุว่าไม่ชัดและถาม ห้ามตัดทิ้ง.

## 2026-08 — สรุป dead code ว่าต้อง deploy จากการค้นข้อความอย่างเดียว
- **Mistake**: พบ LINE webhook domain เก่าใน Vue template แล้วสรุปว่าต้องแก้และ deploy web app โดยไม่ได้ตรวจว่า block ทั้งก้อนถูกครอบด้วย HTML comment; user corrected: `web-app ต้อง deploy ใหม่หรอในเมื่อมัน comment code ไว้`.
- **Rule**: ก่อนสรุปว่าข้อความหรือ config ที่ค้นเจอมีผลต่อ runtime ให้ตรวจ enclosing comment, feature gate, route registration และ call/render path จนยืนยันว่าโค้ด reachable จริง.

## 2026-08 — ลด Meta Business AI MVP ให้เหลือ authority ที่จำเป็น
- **Mistake**: วางแผนเพิ่ม state machine, kill switch, channel/contact fields และ runtime side effects หลายชุด ทั้งที่ webhook เดิมมี message/control flow อยู่แล้ว และอธิบายเหมือน OHO สร้าง `ai_generated` เองทั้งที่ field นี้มากับ Meta webhook เมื่อ Meta AI เป็นผู้ตอบ.
- **Rule**: สำหรับ Meta Business AI ให้ preserve `message.ai_generated === true` จาก Meta webhook เพื่อระบุผู้เขียนและ Stream identity เท่านั้น ห้ามสร้างหรืออนุมาน field นี้จาก app/channel; sender/provisioning logic นี้ต้องทำงานเฉพาะ Facebook Messenger และต้อง guard `contact.social_profile.platform === 'facebook'` ก่อนทุก side effect; เพิ่มเฉพาะ authority observation, send guard และ identity ที่มี consumer กับ acceptance test ชัดเจน.

## 2026-08 — แทน model ที่ผู้ใช้ระบุด้วย model ใกล้เคียงเอง
- **Mistake**: user สั่งให้ใช้ `5.6 Luna max` แต่ผมส่งงานให้ `gpt-5.6-sol` โดยไม่ได้แจ้งว่า environment ไม่มี Luna ก่อน; user corrected ว่า `ฉันบอกให้ใช้ 5.6 Luna max`.
- **Rule**: เมื่อผู้ใช้ระบุ model ชัดเจน ให้ใช้ชื่อนั้นเท่านั้น; ถ้า environment ไม่มี model ดังกล่าวให้หยุดและแจ้งข้อจำกัด ห้ามเลือก model ใกล้เคียงแทนเอง.

## 2026-08 — ลาก subsystem ที่ไม่เกี่ยวมาปนกับ bug scope
- **Mistake**: หลังผู้ใช้ถามเรื่อง JERA tab หาย ผมตามไปวิเคราะห์ `completeClaimedDedup()` ใน Facebook webhook ทั้งที่จุดนั้นไม่อยู่ใน JERA render/fetch path; user corrected ว่า `จริงๆ อันนี้ต้องการแก้ที่ tab jera มันหายเองเพราะเรา render ก่อนที่จะได้ค่ามาหนิใช่ไหม`.
- **Rule**: ก่อนขยายการแก้ bug ให้ trace จากอาการถึง runtime path และตัด subsystem ที่ไม่อยู่ใน path ออก; สำหรับ JERA tab race ให้จำกัด scope ที่ feature-flag resolution, MaxPanel watcher และ partner-connection fetch เท่านั้น เว้นแต่มีหลักฐานเชื่อมโยงใหม่.


## 2026-08 — Deploy ผ่าน tag แล้วไม่อัปเดต main
- **Mistake**: สร้างและ push production tag จาก release branch แล้วสรุปงานเสร็จ ทั้งที่ `origin/main` ยังอยู่หลัง production หลาย commit; user corrected: `merge เข้า main ไว้ด้วยสิ`.
- **Rule**: เมื่อ release workflow ใช้ tag ให้ตรวจและทำให้ branch หลักมี release commit เดียวกับ tag ตาม repo flow ก่อนสรุปงานเสร็จ; ห้ามทิ้ง production history ไว้เฉพาะ tag หรือ local release branch.

## 2026-08 — สรุป production routing จากชื่อ Load Balancer โดยไม่ตรวจ DNS
- **Mistake**: เห็น resource ชื่อ `oho-webhook-lb` แล้วสรุปว่า `webhook.oho.chat` วิ่งผ่าน LB นั้น ทั้งที่ DNS จริง CNAME ไป Cloud Run domain mapping และ certificate/LB IP เป็นของ `webhook2.oho.chat`; ทำให้แนะนำ URL-map canary ที่ไม่มีผลกับ production domain.
- **Rule**: ก่อนสรุป ingress topology, cron guard หรือการใช้งานจริง ให้ยืนยันครบ DNS A/CNAME → frontend IP → target proxy/certificate SAN → URL map/backend → request logs และ trace validation precedence ใน code ว่าใช้ DB หรือ env ก่อน; แยก manual/test traffic ออกจาก historical production traffic และห้ามสมมติว่ามี whitelist/config guard โดยยังไม่พบ consumer จริง.

## 2026-08 — สรุปว่า webapp ไม่เรียก Stream จากการค้นชื่อ method อย่างเดียว
- **Mistake**: ค้นหา `queryChannels` ใน source แล้วสรุปว่า webapp ไม่เรียก Stream ตรง โดยไม่ได้ trace network request ที่ Stream Chat SDK ยิงไป `chat-proxy-singapore.stream-io-api.com`; user corrected: `แต่หน้าบ้านมีเรียก https://chat-proxy-singapore.stream-io-api.com/ ด้วยนะ`.
- **Rule**: ก่อนสรุปว่า frontend ไม่เรียก third-party API ตรง ให้ตรวจ SDK call path และ browser network endpoint/method ด้วย; การไม่พบชื่อ SDK method ใน source ไม่ได้พิสูจน์ว่าไม่มี network call.

## 2026-08 — อ่าน Cloud Run env โดยไม่กรอง credential
- **Mistake**: ใช้ `gcloud run services describe` แล้วพิมพ์ environment ทั้งชุด ทำให้ output มี API credential ปะปนระหว่างการวิเคราะห์ webhook; ทำซ้ำด้วยการ map direct env values ก่อนกรอง.
- **Rule**: ก่อนแสดงหรือเก็บ Cloud Run metadata ให้ใช้ allowlist เฉพาะชื่อ/ค่าที่จำเป็น, แสดงได้แค่ secret reference name/version, และห้ามส่ง direct value ที่ชื่อหรือบริบทสื่อว่าเป็น key, token, URI, password, credential หรือ API secret.

## 2026-08 — ยก Messenger baseline field เป็น Meta Business AI blocker
- **Mistake**: ใช้ `message_deliveries` จาก onboarding runbook ซึ่งรวม Messenger baseline fields แล้วสรุปว่าการขาด field นี้เป็น Meta Business AI staging blocker ทั้งที่ runtime ไม่ได้ใช้ delivery receipt กับ AI identity, activation หรือ handoff.
- **Rule**: ก่อนยก webhook subscription field เป็น release blocker ให้ trace consumer และผูกกับ acceptance criterion ของ feature; field ที่มีไว้เพียง delivery observability ต้องจัดเป็น optional เว้นแต่ระบบเก็บหรือใช้ delivery status จริง.

## 2026-08 — ใช้ develop เป็น blockerทั้งที่ผู้ใช้เปลี่ยน baseline แล้ว
- **Mistake**: หลังผู้ใช้ pull `master` เข้า `oho-webhook` แล้ว และย้ำว่า `ไม่ต้องไปสนใจ develop` ผมยังพยายามดึง `origin/develop` กลับมาเป็นงานที่ต้องทำ.
- **Rule**: เมื่อผู้ใช้ตัด branch ออกจาก scope อย่างชัดเจน ให้หยุดตรวจ/merge branch นั้นทันที; ยึด current branch เป็น baseline และตรวจ blocker เฉพาะ scope ที่เหลือ.

## 2026-08 — สลับลำดับ staging กับ UAT
- **Mistake**: รายงานว่าไม่มี live Meta replay และ terminal Mongo/Stream UAT proof ทั้งที่ยังไม่ได้ deploy staging ทำให้เหมือนกำลังจะข้าม staging ไป UAT; user corrected: `staging ยังไม่ผ่านจะขึ้น uat ได้ยังไง`.
- **Rule**: รายงาน gate ตามลำดับ `code validation/commit → deploy staging → staging subscription/replay/terminal proof → staging pass → UAT`; ก่อน deploy staging ให้ระบุว่า UAT ยังไม่ถึงขั้นตอน ไม่ใช่สรุปเป็น missing UAT evidence.

## 2026-08 — เสนอเปิด Meta Test App เป็น Live
- **Mistake**: เห็น staging app เป็น Development แล้วแนะนำให้ทำ App Review/เปิด Live โดยยังไม่ได้ตรวจว่าเป็น Test App child ของ production app.
- **Rule**: ก่อนวางแผนเปิด Meta app เป็น Live ให้ตรวจ parent/child/test-app status ก่อน; Test App อยู่ Development เสมอและรับ customer traffic จริงไม่ได้ ต้องใช้ standalone app หรือ fan-out ที่ออกแบบชัดเจน.

## 2026-08 — เทียบ Meta app ใน Dashboard ผิดตัวกับ runtime
- **Mistake**: เห็น `Oho Staging - 4` ใน Dashboard แล้วใช้เป็นตัวแทน staging-4 ทั้งที่ runtime ใช้ App ID `906298295642485` คือ `Oho Chat [staging-4]`; จึงสรุปความต่างและเสนอ standalone app เร็วเกินไป.
- **Rule**: ก่อนสรุป Meta app behavior ให้ map runtime `OHO_FB_APP_ID`/`FACEBOOK_APP_ID` → app name/status → webhook callback → real request logs และห้ามสร้างหรือเปลี่ยน external app จนกว่าจะยืนยัน mapping นี้.

## 2026-08 — ห้ามถอด UAT เมื่อ scope อยู่ที่ staging-1
- **Mistake**: ระหว่างไล่ปัญหา staging-1 ผมพิจารณาถอด Page subscription ของ UAT ทั้งที่ผู้ใช้ต้องการโฟกัส staging-1 และยังไม่ได้แจ้งก่อนทำ action ที่ลบ.
- **Rule**: ยึด environment ที่ผู้ใช้ระบุเป็น scope; ห้ามลบหรือ unsubscribe environment อื่น และต้องแจ้ง action กับผลกระทบก่อนทุก destructive operation.

## 2026-08 — สรุป callback จาก traffic production ที่ไม่ unique
- **Mistake**: เห็น production มี Facebook webhook traffic ในช่วง Meta test แล้วสรุปว่า App staging-1 callback ชี้ production ทั้งที่ traffic เป็นของเพจอื่นและยังไม่มี payload/trace ที่ผูกกับ test นั้นโดยตรง; ผู้ใช้ยืนยันว่า callback ถูกต้อง.
- **Rule**: ก่อนสรุป routing จาก traffic ที่มีอยู่ ให้ผูก event กับ unique payload, trace หรือ provider delivery evidence; แยก background traffic ออกจากผลทดสอบ และถอนข้อสรุปเมื่อหลักฐานไม่พอ.

## 2026-08 — อย่าแตะไฟล์ deploy/CI นอก scope
- **Mistake**: ปล่อยให้ไฟล์ deploy และ GitLab CI ที่มี dirty diff อยู่ก่อนถูกนับรวมกับงานแก้ bug โดยไม่ได้ยืนยัน ownership/scope ให้ชัด; ผู้ใช้ขอให้คืนไฟล์เดิม.
- **Rule**: ก่อนแก้ใน worktree สกปรก ให้ pin pre-edit diff และ preserve ไฟล์ deploy/CI ที่ไม่เกี่ยวกับ task; เปลี่ยนได้เมื่อผู้ใช้สั่งโดยตรงเท่านั้น.

## 2026-08 — ใช้ `.env` แทน MongoDB Compass ผิด environment
- **Mistake**: ตรวจ `.env` ที่ชี้ UAT ทั้งที่ผู้ใช้มี MongoDB Compass เปิด staging-1 อยู่แล้ว; user corrected: `ทำไมถึงไม่เลือกดูใน mongo compos ในเครื่องฉันล`.
- **Rule**: เมื่อผู้ใช้ขอเช็คฐานข้อมูลในเครื่อง ให้ตรวจ connection/database ที่เปิดอยู่ใน MongoDB Compass ก่อนใช้ local `.env` หรือขอสิทธิ์ GCP.

## 2026-08 — ใช้ Computer Use ทั้งที่ผู้ใช้ต้องการ CLI
- **Mistake**: เปิด Computer Use เพื่อตรวจฐานข้อมูลและจัดการ credential ทั้งที่ผู้ใช้ต้องการใช้ `mongosh`; user corrected: `หยุดใช้ computer use`.
- **Rule**: เมื่อผู้ใช้สั่งใช้ CLI ให้หยุด Computer Use ทันที; ใช้ CLI/API เท่านั้น และรายงาน credential/permission blocker โดยไม่เปิดแอปหรือดึง secret เพิ่ม.

## 2026-08 — สรุปว่า Smartchat realtime แล้วจากการมี socket listener
- **Mistake**: เห็น API emit และ web-app มี socket listener จึงสรุปว่า Meta AI state อัปเดตในห้องที่เปิดอยู่แล้ว โดยไม่ได้ทดสอบว่า payload ผ่าน field selection, stale-event guard และ current-room merge; user corrected ว่ายังต้องสลับแชทก่อน state จึงเปลี่ยน.
- **Rule**: ก่อนสรุปว่า Smartchat state realtime ให้ replay event ผ่าน socket handler ถึง `current_contact` และ DOM ด้วย red-capable test; listener หรือ emit ที่มีอยู่ไม่ใช่หลักฐานว่า UI อัปเดต.

## 2026-08 — ต้องเทียบ baseline ก่อนเพิ่ม unread/unresponded
- **Mistake**: ตอบ behavior ของ flags จาก parent ของ realtime-badge fix แทนการย้อนเทียบ snapshot ก่อนเริ่ม unread/unresponded ราวสองเดือนก่อน; user corrected ให้ย้อนกลับไปเทียบกับช่วงก่อน feature.
- **Rule**: เมื่อผู้ใช้ถามว่า behavior ควรเหมือนก่อน feature หรือไม่ ให้หา release tag ล่าสุดที่ยังไม่มีโค้ดของ feature นั้น แล้วเทียบ source/runtime path กับ tag โดยตรง; parent ของ commit ไม่ใช่ release baseline.

## 2026-08 — สรุป Meta Thread Owner เกินหลักฐาน
- **Mistake**: กล่าวว่าห้องใหม่จะได้ผล `thread_owner` ว่างหรือไม่มี `app_id` โดยยังไม่ได้ทดสอบ controlled live request หลัง inbound ใหม่; user ถามว่า `อนนี้เรา prove แล้วหรอ`.
- **Rule**: แยก Meta docs, historical logs, และ live controlled API proof ให้ชัด; ห้ามสรุป response behavior ของ first-contact thread จนกว่าจะยิง endpoint กับ test Page/PSID และเก็บผลที่ sanitize แล้ว.

## 2026-08 — ยก hypothetical stale page เป็น MR finding
- **Mistake**: review pagination แล้วแจ้ง out-of-range page จากจำนวนรายการลดลง โดยไม่ได้ยืนยันว่า flow ของหน้าเกิดสถานะนั้นจริง; user corrected ว่าเข้าหน้าหรือ reload จะ fetch ใหม่.
- **Rule**: review ให้รายงานเฉพาะ regression ที่ trace ได้จาก MR และ runtime flow; hypothetical edge case ที่ไม่มี mutation/navigation path ใน scope ไม่ใช่ finding.

## 2026-08 — จำกัดช่วง production test log เร็วเกินไป
- **Mistake**: user บอกว่าส่งรูปทดสอบหลายรูป แต่ผมดึง log เฉพาะช่วงของรูปแรกแล้วสรุปจาก event เดียว.
- **Rule**: เมื่อผู้ใช้ทดสอบ production เป็นหลาย event ให้ enumerate ทุก event ใน test window และจับคู่ terminal outcome ต่อ event ก่อนสรุปผลหรือสร้าง log link.

## 2026-08 — ตรวจ alpha channel ก่อนส่งภาพโปร่งใส
- **Mistake**: accepted image-generation files described as transparent after visual checkerboard preview without checking `hasAlpha`; all outputs were RGB with checkerboard baked in.
- **Rule**: for transparent-image deliverables, inspect the final file's alpha channel and verify `hasAlpha: yes` before handing off.

## 2026-08 — ตอบเรื่อง config โดยไม่ตรวจของจริง
- **Mistake**: ผู้ใช้ถามว่า instruction กลางใช้กับ OpenCode ได้หรือไม่ แต่ไม่ได้ตรวจไฟล์และ runtime configuration ก่อนตอบ; user corrected: `เหมือนนายไม่ทำงานเลย`.
- **Rule**: เมื่อคำถามเกี่ยวกับ config หรือ capability ที่ตรวจได้จากเครื่อง ให้ตรวจ source, generated output และ runtime-loaded configuration ก่อนตอบเสมอ.

## 2026-08 — Audit frontend จาก feature branch แทน master
- **Mistake**: audit contact response field usage จาก worktree/current feature branch จนรวม feature ที่ยังไม่ขึ้น `master`; user corrected: `ให้ดู code จาก brach master นะ`.
- **Rule**: เมื่อ audit contract หรือ field usage เพื่อปรับ backend response ให้ pin frontend source ที่ `master` explicitly, never current branch/worktree, และระบุ commit SHA ใน report.

## 2026-08 — Let a diagnostic print authenticated request data
- **Mistake**: ran a Stream SDK diagnostic without suppressing its verbose error object, which included credential-bearing request headers in tool output.
- **Rule**: for authenticated diagnostics, catch and reduce errors to an allowlisted code/message before output; never let SDK exceptions serialize request config or headers.

## 2026-08 — Imported only part of a financial monthly plan
- **Mistake**: updated only CSV-mapped budget categories, leaving prior categories and income amounts in the same month; user: `ยอดค่าใช้จ่าย กันยายน 2569 ไม่ตรงละ แผนรายรับก็ไม่อัพเดท้`.
- **Rule**: before updating a financial monthly plan, replace the complete category set for the target month and verify both income and expense totals exactly match the approved source before reporting success.

## 2026-08 — ใช้ Mongo config ผิดชุด
- **Mistake**: ตรวจ `oho-webhook/.env` ก่อน ทั้งที่ผู้ใช้กำหนด connection กลางไว้ใน `~/.config/oho/mongo.env`.
- **Rule**: ทุกครั้งที่เข้า Mongo ให้โหลด `~/.config/oho/mongo.env` ก่อน แล้วเลือก database `oho-log-prod` หรือ `oho-prod` ให้ตรงกับงาน.

## 2026-08 — Escalated from GitLab too early
- **Mistake**: ระหว่างไล่ deploy failure ผมขอ `gcloud auth login` ก่อนอธิบายว่า GitLab job trace ยืนยันอะไรแล้ว; user: `แต่จริงๆมันต้องดูใน gitlab หนิ`.
- **Rule**: pipeline fail ให้เริ่มและสรุป failing GitLab job trace/artifacts ก่อน; escalate ไป provider log เฉพาะเมื่อ trace จบที่ external deploy โดยระบุ evidence และเหตุผลให้ชัด.

## 2026-08 — Build passed but Feathers app could not boot
- **Mistake**: registered `probeFacebookThreadOwnerOnFirstInbound` as a top-level Feathers hook type; `npm run build` passed because it only compiled source, while Cloud Run exited at startup with `'probeFacebookThreadOwnerOnFirstInbound' is not a valid hook type`.
- **Rule**: when changing Feathers service hook registration, run a startup/service-registration smoke test in addition to build and hook-unit tests; only `before`, `after`, and `error` may be top-level hook keys.

## 2026-08 — Inferred Meta ownership from manual reply behavior
- **Mistake**: concluded that a manual OHO reply proved Meta AI's first-message condition no longer applied, before correlating the inbound type, `standby` delivery, `ai_generated` echo, and handover timeline.
- **Rule**: for Meta AI routing claims, trace the full Page/PSID/message timeline first; distinguish delayed or unsupported Meta input handling from OHO ownership changes, and state only what the observed control event proves.

## 2026-08 — Assumed Meta condition maps to standby
- **Mistake**: stated that messages excluded by Meta's `first-time / ads / team` conditions would arrive outside `standby` without a controlled UAT for each condition.
- **Rule**: never infer Meta routing-field behavior from a configured condition; prove the condition-to-webhook mapping with a new-user and repeat-user UAT matrix before using it in product behavior or stakeholder messaging.

## 2026-09 — Preserve first-connect subscription behavior
- **Mistake**: interpreted customer opt-in for `messaging_handovers` as a requirement to stop automatic subscription at first Facebook channel connection.
- **Rule**: distinguish first-connect setup from backfill for already-connected Pages; retain verified onboarding behavior unless the user explicitly changes it.

## 2026-09 — แยก field audit ตาม call site
- **Mistake**: สรุป field usage รวมตาม endpoint/flow ทั้งที่ผู้ใช้ต้องการรู้ว่าแต่ละหน้าและ path ส่ง response ไปใช้ที่ component ไหน.
- **Rule**: ทำตาราง `endpoint → page/route → caller path → consumer → fields` ก่อนสรุป field reduction และแยก runtime call จาก mock/comment/test.

## 2026-09 — ตรวจ semantics ของ chat status ก่อนสรุป handoff
- **Mistake**: ตีความ `ขอคุยกับคน` ว่าต้องเปลี่ยนเข้า `request` ทั้งที่ product contract ต้องคง `status=bot` และใช้ `chat_status=fallback` เพื่อแสดง “แชทบอทตอบไม่ได้”.
- **Rule**: ก่อนเสนอ status transition ให้ map label ฝั่ง UI กับค่า `status/chat_status` จริงและยืนยัน contract ของ flow ก่อนเสมอ.

## 2026-09 — สรุป Meta auto-reengage โดยไม่ยืนยันผู้กระทำ
- **Mistake**: เห็น AI กลับมาตอบหลังจบแชทแล้วสรุปว่า Meta auto-reengage ทั้งที่ผู้ใช้ยิงคืนห้องผ่าน Bruno เอง.
- **Rule**: สำหรับ Meta ownership ให้ผูกทุก control action กับ Graph/GCP evidence หรือยืนยันจากผู้ทดสอบก่อนระบุว่าเป็น automatic behavior.

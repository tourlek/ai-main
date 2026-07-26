thread_id: 019f9319-959c-7630-8f42-e17b70c0d6ef
updated_at: 2026-07-24T07:53:27+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/24/rollout-2026-07-24T14-49-15-019f9319-959c-7630-8f42-e17b70c0d6ef.jsonl
cwd: /Users/tualek/ohochat/oho-web-app
git_branch: fix/oho-1272-unread-unresponded-realtime-badge

# Re-review of Vue 2/Vuex realtime unread and unresponded badge fix found four issues

Rollout context: Read-only, narrowly scoped review of the supplied diff, `store/modules/smartchat.js`, `components/Smartchat/RoomList.vue`, and `constants/contact.js` in `/Users/tualek/ohochat/oho-web-app`. The user required yes/no verdicts with exact file:line evidence and a final issue count.

## Task 1: Realtime badge correctness review

Outcome: partial

Preference signals:
- The user explicitly required “read ONLY these, do not explore the repo broadly” and “Review only, do not modify files” -> future reviews should stay tightly scoped and read-only.
- The user requested adversarial analysis, yes/no answers, exact `file:line` evidence, and a compact final verdict -> report concrete defects rather than broad commentary.

Key findings:
- Unread is not correct for every branch. In-list rooms cover `my_read`, `state.read` without `my_read`, and fallback `is_read_by_me` branches (`RoomList.vue:161-177`), but new rooms rely on the post-event API fetch; failed/empty fetches leave badge fields absent (`smartchat.js:904-931`).
- Synthetic `last_contact_date = new Date().toISOString()` defeats the local-read guard. A delayed event can compare an already-reached real cursor against a later synthetic timestamp, causing a false unread (`smartchat.js:730-733,836-860`; `RoomList.vue:163-165`). Fix by using the real message timestamp/version or authoritative state, and discard the synthetic fields when stale.
- Synthetic timestamp does not alter displayed time or list sorting because display uses `state.messages[].oho_created_at` and sorting uses `last_active_at` (`RoomList.vue:149-155,191-205`), but it contributes to unread false positives and aggregate drift.
- New-room aggregate count transitions occur before the authoritative fetch, so fetched badge fields do not affect counts (`smartchat.js:779,813-860,915-927`). Compute transitions after fetch using final data.
- New rooms can be silently dropped when reload mode is active or ascending pagination is incomplete; only filtered lists trigger refetch (`smartchat.js:966-994`). Queue/refetch in the blocked branch.
- Unresponded is independently injected for existing rooms and can be supplied for successful new-room fetches, but stale inbound events can reassert `true` after a bot/member reply cleared it (`smartchat.js:813-825,869-880`). Add event ordering/version checks or authoritative reconciliation.
- No flag-combination hole was found: unread and unresponded are gated independently (`smartchat.js:710-715,727-733`), though both combinations inherit the shared new-room defects.

Final verdict: `VERDICT: 4 issues`.

References:
1. `smartchat.js:730-733,772-779,813-860,904-931,966-994`
2. `RoomList.vue:149-177,191-205`
3. Final review reported four issues: synthetic timestamp false unread; pre-fetch aggregate count drift; incomplete/blocked new rooms; stale unresponded reassertion.

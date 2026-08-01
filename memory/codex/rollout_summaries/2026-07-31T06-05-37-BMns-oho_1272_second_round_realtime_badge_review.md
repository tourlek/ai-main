thread_id: 019fb6c7-39c5-7110-9c61-b4878f375e66
updated_at: 2026-07-31T06:35:27+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/07/31/rollout-2026-07-31T13-05-37-019fb6c7-39c5-7110-9c61-b4878f375e66.jsonl
cwd: /Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge
git_branch: fix/oho-1272-unread-unresponded-realtime-badge

# Second-round review of OHO-1272 realtime badge fixes

Rollout context: Read-only review of unstaged changes in `/Users/tualek/ohochat/oho-web-app/.claude-worktrees/oho-1272-realtime-badge`, HEAD `5fc4ef224814aec240b55891ef36664e0abce5cd`. Only `store/modules/smartchat.js` and `test/store/modules/smartchat.spec.js` changed.

## Task 1: Verify equal-timestamp raw flag handling

Outcome: success

Key steps:
- Confirmed equal timestamps now inject `is_read_by_me:false` and `last_contact_date`, then explicitly delete raw `is_unresponded` only on the equal path (`smartchat.js:775-805`).
- Confirmed newer events still synthesize `is_unresponded:true` (`smartchat.js:791-797`).
- New raw-payload regression test passes at `smartchat.spec.js:1394-1420`.

## Task 2: Verify atomic realtime insertion/deduplication

Outcome: success

Key steps:
- `addRealtimeContactToList` synchronously performs dedupe, cap pop, head/tail insertion, and optimistic Set reconciliation (`smartchat.js:172-201`).
- Realtime callers now commit once with `from_head: sort_chat_list !== 1` (`smartchat.js:1048-1055`), preserving prior unshift/push behavior.
- Repo-wide grep found no executable callers of removed `handleLimitContactList` or `removeLastContact`; only a historical comment remains (`smartchat.js:174`).
- Pagination mutations retain dedupe but no cap logic, preserving prior pagination behavior.

Preference signals:
- The user explicitly required a read-only verification pass, actual file:line grounding, repo-wide caller checks, meaningful blocked-branch tests, and a decisive SHIP/NO-SHIP verdict. Future reviews should follow this evidence-first structure and avoid edits.

## Task 3: Validate tests and formatting

Outcome: partial

Reusable knowledge:
- Store scope passed: `smartchat.spec.js` + `websocket.spec.js` = 61/61, using a narrowly scoped workaround because sandbox Jest cache writes failed with EPERM.
- Full `test/`: 53 suites passed, 4 failed; failures were in unchanged JERA/media suites (`MaxPanel`, `IntegrationExternal`, `MaxPanelJeraProfilePanel`, media-library `_type`) and did not reference Smartchat realtime code.
- Direct installed Prettier 2.8.8 reported both changed files unformatted. Earlier `rtk npx prettier --check` output was a false positive; the repository binary was authoritative.
- Visibility-negative test was vacuous: it mocked visibility false but also left `getAvailableMenusForChatRoom` returning `[]` while active menu was `all`, so insertion was blocked independently (`smartchat.spec.js:492-515`, mock plugin/store). It should provide `['all']` to isolate visibility.
- No direct test covers `from_head:false` while already at cap, though implementation preserves the intended pop-then-push semantics.

FINAL VERDICT: NO-SHIP until real Prettier formatting is applied and the visibility test is made non-vacuous. The two prior correctness blockers themselves were fixed; deferred aggregate badge reconciliation remains accepted and was not part of this verdict.

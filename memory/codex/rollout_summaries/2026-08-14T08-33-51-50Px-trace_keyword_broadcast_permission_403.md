thread_id: 019fff67-f5d7-74e3-b7d8-06a0b1faf7f3
updated_at: 2026-08-14T08:35:41+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/14/rollout-2026-08-14T15-33-51-019fff67-f5d7-74e3-b7d8-06a0b1faf7f3.jsonl
cwd: /Users/tualek/ohochat

# Traced 403 permission failure for keyword creation

Rollout context: In `/Users/tualek/ohochat`, the user reported a 403 from `POST /core/latest/keyword` with payload `{keyword:"fffff", group:"broadcast"}`.

## Task 1: Identify required permission

Outcome: success

Key steps:
- Read-only traced the keyword service and hooks; did not replay the exposed credentials.
- `create` runs `checkMemberPermission()` after authentication, payload validation, and uniqueness checks.
- For `group: "broadcast"`, the default mapping applies `_.kebabCase(group)`, producing `broadcast`.
- The permission checked is therefore `keyword.broadcast.create`.
- If `_id` is supplied, the same endpoint treats the operation as an update and checks `keyword.broadcast.update`.
- Permissions are read from `params.member.role_permission.permissions`; the JWT strategy populates `role_permission`.
- The curl contained different JWT and cookie identities, so the authenticated member/role may not be the intended one.

Reusable knowledge:
- Keyword permission mapping: `tag → keyword.contact-tag.{action}`, `contact_label → keyword.chat-tag.{action}`, `arp_group_id → keyword.arp-group.{action}`, all other groups → `keyword.{kebab-case-group}.{action}`.
- The exposed credentials should be revoked/rotated; they were not reused during investigation.

References:
- `/Users/tualek/ohochat/oho-api/src/services/keyword/keyword.hooks.js:356-409`
- `/Users/tualek/ohochat/oho-api/src/services/keyword/keyword.hooks.js:512-525`
- `/Users/tualek/ohochat/oho-api/src/auths/memberJWTStrategy.js:21-24`
- `/Users/tualek/ohochat/oho-api/docs/modules/keyword.md:126-137`
- Exact required permission: `keyword.broadcast.create`

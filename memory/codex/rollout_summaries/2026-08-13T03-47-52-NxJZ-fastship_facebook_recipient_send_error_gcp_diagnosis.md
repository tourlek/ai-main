thread_id: 019ff93b-c85a-7c20-af5f-a0727251ac2f
updated_at: 2026-08-13T03:52:47+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/13/rollout-2026-08-13T10-47-52-019ff93b-c85a-7c20-af5f-a0727251ac2f.jsonl
cwd: /Users/tualek/ohochat

# Diagnosed Fastship Facebook send failures

Rollout context: Read-only production investigation in `/Users/tualek/ohochat`, using GCP Cloud Logging, source inspection, prior incident memory, and raw Meta responses.

## Task 1: Diagnose Facebook recipient send errors

Outcome: success

Preference signals:

- The user asked whether the issue was caused by Meta and requested GCP log inspection -> future investigations should correlate the supplied business ID, Facebook Page ID, exact time window, raw platform response, and successful sends before attributing a platform-wide outage.
- The user reported a UI message saying the source platform was malfunctioning -> distinguish UI error mappings from the raw Meta error and identify misleading or generic mappings explicitly.

Key steps:

- Queried production logs for business `636b3215359066889e4edfe6` and Facebook Page `595166650687417 (FastShip.co)`.
- Found 11 failed attempts between `2026-08-13 10:00:07` and `10:07:31` ICT.
- Raw Meta response was HTTP 400, `OAuthException`, `code=551`, `error_subcode=1893047`, `is_transient=false`, with “This person isn't available right now/at the moment.”
- The same Page had no matching error after `10:07:31` through approximately `10:50` ICT, while many other Fastship sends succeeded.
- Cross-business logs showed the same recipient-style error on other Pages, but this does not establish a global Meta outage; the error is tied to individual recipients/conversations.
- Source inspection showed OHO maps only Facebook `code=551 + subcode=1545041` to “ลูกค้าบล็อกช่องทาง.” This incident used subcode `1893047`, so it fell through to the generic platform-error fallback.

Failures and how to do differently:

- Broad GCP queries produced very large, truncated output. Narrow by `core-api--production`, business/Page ID, exact error/subcode, and a tight UTC window; format only timestamp, severity, labels, and relevant payload text.
- Do not conclude “Meta outage” from the generic UI text. Compare recipient-specific failures with successful sends and inspect `is_transient`.
- Raw Axios logs contained access tokens; never preserve or repeat them. Redact as `[REDACTED_SECRET]`.

Reusable knowledge:

- Evidence supports a recipient/conversation-level Meta restriction rather than a Fastship-wide or Meta-wide outage. Plausible causes include the recipient blocking the Page, account deactivation/restriction, or Meta disallowing contact with that recipient; the logs do not distinguish among these.
- Because `is_transient=false`, immediate retries are unlikely to help. Recommend another contact channel rather than repeatedly retrying.
- The UI mapping is incomplete: `oho-api/src/utils/get-error-message-send-message-fail.js:93-100` handles `551/1545041`; unmatched errors use the generic fallback at lines `181-195`.

References:

- Production project/service: `oho-platform`, `core-api--production`.
- Representative raw error: `HTTP 400`, `OAuthException`, `code=551`, `error_subcode=1893047`, `is_transient=false`, `This person isn't available right now.`
- Source mapping: `oho-api/src/utils/get-error-message-send-message-fail.js:93-100,181-195`.
- Final user-facing conclusion: this is not evidenced as a platform-wide Meta outage; it is most consistent with a restriction affecting specific recipients, and the current UI is generic because subcode `1893047` is not specifically mapped.

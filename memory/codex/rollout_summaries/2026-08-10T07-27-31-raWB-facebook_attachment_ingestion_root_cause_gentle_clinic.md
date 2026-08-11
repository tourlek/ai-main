thread_id: 019fea91-cc0c-72a0-a973-d5bc782a9d01
updated_at: 2026-08-10T07:33:25+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/10/rollout-2026-08-10T14-27-31-019fea91-cc0c-72a0-a973-d5bc782a9d01.jsonl
cwd: /Users/tualek/ohochat

# Root-cause investigation of Facebook attachment failures for Gentle Clinic

Rollout context: Read-only investigation in `/Users/tualek/ohochat` using repository tracing, production GCP Cloud Logging, direct GCS downloads, image inspection, and Meta status lookup.

## Task 1: Diagnose Facebook image/file send failures

Outcome: success

Preference signals:

- The user asked for the “rootcause” and specifically whether the issue was the file, OHO metadata/upload, or Meta -> future investigations should distinguish the UI-mapped error from the raw platform response and provide evidence for each layer without making code changes prematurely.
- The user asked to inspect GCP logs for a specific business and sample file -> search logs by business ID, file URL/ID, platform error code, and request timestamps, then correlate the full send path.

Key steps:

- Located the UI mapping: Facebook/Instagram `code=100` plus `error_subcode=2018047` becomes “Facebook ไม่รองรับไฟล์ดังกล่าว.”
- Downloaded and decoded the supplied JPEG; it was valid JPEG, 1260×1785, RGB/sRGB, no alpha, 140,617 bytes.
- Traced the Facebook path: OHO places the existing `mediaUrl` into the attachment payload and POSTs directly to Meta Graph API; there is no OHO-side re-encode or re-upload to Meta in this path.
- Queried production Cloud Logging and found repeated Gentle Clinic failures with HTTP 400, Meta `code=100`, `error_subcode=2018047`, and distinct `fbtrace_id` values.
- Found the same error during the same period across unrelated Facebook Pages/businesses including Toyota Sure Summit, Nine Furniture, and Vn Phone, ruling against a Gentle-specific page or single-file defect.
- Inspected three Gentle-related GCS images; all returned HTTP 200 and decoded as standard JPEGs. Both older reused files and a newly uploaded file failed during the same incident window.
- Meta Messenger status showed “No known issues,” but this did not disprove the cross-business production evidence.

Failures and how to do differently:

- Initial broad log queries produced heavily truncated output. Narrow future queries by service, exact error subcode, business/page, and a tight timestamp range; request concise `value()` or table fields.
- The GCP configuration warning indicated the local gcloud log directory was not writable, but the proxied logging command still returned production data. Treat this as an environment warning, not application evidence.
- Do not treat the Thai UI message as the root cause; it is a broad mapping of Meta subcode `2018047`.

Reusable knowledge:

- Root cause supported by the evidence: Meta’s attachment fetch/ingestion failed after receiving OHO’s public GCS URL, apparently as a cross-business/platform incident. The supplied OHO file and upload pipeline showed no corruption evidence.
- The sample business ID in the original file JSON (`604e2c63...`) differs from Gentle Clinic’s business ID (`67121be...`); do not attribute that sample file to Gentle without correlating the actual send logs.
- Recommended operational response from the investigation: retry only failed attachments after the error has stopped for 10–15 minutes; avoid resending the entire saved reply because successfully sent text/media may duplicate.

References:

- `/Users/tualek/ohochat/oho-api/src/utils/message-converter/youpin-to-facebook.js:42-52` — image payload uses `mediaUrl` directly.
- `/Users/tualek/ohochat/oho-api/src/services/integration/facebook/reply-message/reply-message.class.js:30-35` — POST to `https://graph.facebook.com/v20.0/me/messages`.
- `/Users/tualek/ohochat/oho-api/src/utils/get-error-message-send-message-fail.js:123-126` — maps `code=100`, `error_subcode=2018047` to the Thai UI message.
- Representative raw response: `HTTP 400`, `(#100) อัพโหลดไฟล์แนบไม่สำเร็จ`, `type=OAuthException`, `code=100`, `error_subcode=2018047`.
- Gentle Clinic Facebook Page ID observed in logs: `1626745224287212`.
- Production Cloud Run service: `core-api--production`; project: `oho-platform`.


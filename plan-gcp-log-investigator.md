# GCP Log Investigator Skill + CLI Plan

## Goal

Create a shared `gcp-log-investigator` skill in `~/ai-main` for read-only Cloud Run log investigation. Compact Cloud Logging JSON before it enters model context, then distribute one canonical skill to Antigravity, Claude Code, Codex, Gemini, and Cursor through the existing sync system.

## V1 Boundary

- Build a model-invoked skill and a Node.js CLI helper.
- Use `gcloud logging read` with the existing gcloud credentials.
- Support generic GCP projects plus an OHO preset.
- Defer an MCP server and dedicated subagent until the CLI contract is stable and shell-based agents show a concrete limitation.

## Files

### `skills/gcp-log-investigator/SKILL.md`

- Trigger on GCP Logging, Cloud Run log, environment error, incident, and trace-correlation investigations.
- Enforce this flow: scope and time normalization, narrow query, error identification, trace correlation, local code mapping, and evidence-based findings.
- Require the compacting CLI instead of feeding raw `gcloud --format=json` output into model context.
- Separate observed evidence, inference, root cause, and missing evidence.
- Require fail-path tracing and source cross-reference before proposing a fix.

### `skills/gcp-log-investigator/scripts/gcp-logs.mjs`

- Use only Node.js built-ins.
- Invoke `gcloud` with an argument array through `node:child_process`, avoiding shell interpolation.
- Provide these commands:
  - `query`: filter by project, service, environment, start/end or since, severity, search text, and limit.
  - `trace`: normalize a trace ID or full trace path and retrieve its lifecycle logs.
  - `filter`: print the generated Cloud Logging filter without querying GCP.
- Accept `--filter` for advanced filters while retaining time and project guardrails.
- Default to 200 entries.
- Require a bounded time window and at least one of service, trace, or search to prevent broad production queries.
- Emit compact NDJSON, one event per line.

### `skills/gcp-log-investigator/presets/oho.json`

- Set `oho-platform` as the project default.
- Define CI-backed aliases:
  - `oho-api` to `core-api`
  - `oho-webhook` to `webhook`
  - `oho-developer-api` to `developer-api`
  - `oho-web-app` to `web-app`
- Build runtime names as `<service>--<environment>`.
- Let explicit CLI options override preset values.

### `skills/gcp-log-investigator/test/gcp-logs.test.mjs`

- Use built-in `node:test` with local fixtures only.
- Test filter construction, UTC ranges, OHO aliases, trace normalization, compact output, malformed payload tolerance, and redaction.
- Never contact GCP from automated tests.

### `scripts/verify.sh`

- Add `gcp-log-investigator` to the owned-skill checks.
- Include `.agents/skills` in deployment verification so Antigravity is covered alongside Claude, Codex, Cursor, and Gemini.

## Compact Output Contract

Retain only investigation-relevant data:

- `timestamp`
- `service` and `revision`
- `severity`
- `trace` and `spanId`
- compact `httpRequest`: method, URL/path, status, latency, and user agent when present
- `payload`: `jsonPayload` or `textPayload`
- `insertId` for locating the original entry

Remove unrelated resource metadata, labels, receive timestamps, operation/source-location metadata, and wrapper fields.

## Secret Handling

- Recursively redact keys for authorization, cookies, tokens, secrets, passwords, API keys, and private keys.
- Redact Bearer and JWT-like values inside strings by default.
- Preserve the key and surrounding error context while replacing values with `[REDACTED]`.
- Do not add a raw or no-redaction mode in v1. Use `insertId` to inspect the original entry in GCP Console when full evidence is required.

## Investigation Flow

1. Convert the user's time to a bounded UTC range and resolve ambiguous timezones.
2. Start with the narrowest service, time, identifier, and error-signature filter. Use nested payload fields or `SEARCH()` instead of matching bare `jsonPayload`.
3. Summarize error signatures with counts and small samples rather than dumping entries.
4. Follow traces when available. Otherwise identify correlation IDs, request IDs, or domain identifiers before widening scope.
5. Use CodeGraph before grep/read to map stack traces and parameters to the local call path.
6. Maintain a hypothesis ledger and attempt to falsify the candidate root cause.
7. Report timeline, evidence, root-cause confidence, affected service/code locations, and next verification. Mark unverified claims explicitly.

## Verification

1. Run `node --test skills/gcp-log-investigator/test/gcp-logs.test.mjs`.
2. Run CLI `filter` and `--help` checks without contacting GCP.
3. Run `scripts/sync.sh`, then `scripts/verify.sh`, to verify every tool's symlink.
4. Run no production query automatically. A live smoke test requires explicit approval and uses a short window with `--limit 1`.

## Acceptance Criteria

- Agents discover the skill automatically from GCP or Cloud Run investigation requests.
- Generic and OHO modes produce valid, bounded Cloud Logging filters.
- CLI output is compact NDJSON and sensitive values are redacted in tests.
- Trace lookup accepts both a short ID and `projects/<project>/traces/<id>`.
- Deployment verification covers `.agents/skills/gcp-log-investigator`.
- The normal workflow never recommends sending raw Cloud Logging JSON into model context.

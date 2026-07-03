---
name: oho-jera-integration-debugging
description: Debug OHO/JERA partner integration issues across oho-api, oho-developer-api, oho-web-app, and oho-backoffice; use for contact-link, partner-connection, API-key, link-token, sync state, and JERA error mapping tasks.
argument-hint: "[issue or endpoint]"
user-invocable: false
allowed-tools:
  - Bash
  - Grep
  - Read
---

# OHO/JERA Integration Debugging

## When to Use

Use this when the task involves JERA or partner integration in `/Users/tualek/ohochat`, especially:

- `contact-link`, `contacts-link`, `partner-link-token`, `partner-connection`, `partner_service_id`, `partner_service_slug`, or `partner_user_id`.
- `oho-api`, `oho-developer-api`, `oho-web-app`, or `oho-backoffice` JERA behavior.
- API-key auth errors such as `403`, `Invalid partner for this API key`, or header confusion.
- Frontend JERA sync-state coverage, component specs, or backoffice JERA error mapping.
- Integration-external route/auth behavior, mock JERA-only partner list, contact-attribute/JERA profile rendering, or temporary webview `postMessage` flows.

Do not use this for unrelated branch/git tasks except where the JERA change spans repos.

## Inputs and Context to Gather

1. Identify the exact repo under `/Users/tualek/ohochat`; the top-level folder is usually not the git root.
2. Capture the endpoint family first:
   - member-facing `GET /partner-connection`
   - backoffice `/backoffice/partner-connection/jera`
   - member JERA `/partner/jera/link-token`, `/contact/sync`, `/contact/unsync`
   - developer API `/contact/:platform/:platform_id/user/:user_id`
   - backoffice partner/API-key routes `/backoffice/partner` and `/backoffice/business/:business_id/api-key`
3. If the user provides DB documents, compare `business_id` across `contact`, `partner-connection`, `api-keys`, and `contacts-link` before drawing conclusions.
4. For frontend state tasks, distinguish business-level connection state from contact-level sync state.
5. For contact-attribute/JERA profile tasks, distinguish definition collection `contact-attribute` from per-contact `contact.attributes[]` values.

## Procedure

1. Search the right subrepos:
   - `oho-api` for models, hooks, routes, and backoffice connect/disconnect.
   - `oho-developer-api` for developer contact lookup and API-key auth behavior.
   - `oho-web-app` for member UI state and endpoint usage.
   - `oho-backoffice` for partner-management UI and JERA form behavior.
2. Start from schemas and route hooks:
   - `oho-api/src/models/contact-link.model.js`
   - `oho-api/src/models/partner-connection.model.js`
   - `oho-api/src/models/api-keys.model.js`
   - `oho-developer-api/config/default.json`
   - `oho-developer-api/src/services/contact/platform-user/contact.hooks.js`
3. For `contact-link` data, validate required fields:
   - `business_id`
   - `contact_id`
   - `partner_connection_id`
   - `partner_service_slug`
   - `partner_user_id`
   - `status`
4. For developer API contact lookup, build the URL from `social_profile.platform`, `social_profile.platform_id`, and `social_profile.id`; do not use contact `_id`.
5. For API-key auth in `oho-developer-api`, default to header `x-oho-api-key`; do not use `Authorization: Bearer ...` unless code/config proves that endpoint expects it.
6. For frontend JERA connected state, check whether data includes a backend-exposed `contact_links` relation. If not, explain that frontend cannot invent server-side populate and ask before changing backend.
7. For backoffice error mapping, compare `oho-backoffice/components/JeraForm.vue` against backend throw strings in `oho-api/src/backoffice/services/partner-connection/jera/*`.
8. For integration-external route bugs, inspect the exact menu click path first: `store/modules/menu.js`, `components/SubMenuSide.vue`, `components/GlobalHeader.vue`, and `pages/business/_biz_id/setting/integration-external.vue`.
9. For webview testing, add a Vue 2 `window.message` listener in `mounted()` and remove it in `beforeDestroy()`; origin-check before acting on `{ action: "CLOSE_WEBVIEW" }`.
10. For oho-web-app JERA component tests:
   - keep webapp status checks on `BusinessAPIService.getPartnerConnectionList`; `connectJeraPartner` / `disconnectJeraPartner` are backoffice-only and should not get misleading webapp runtime expectations.
   - test `integration-external.vue` through fetch/filter/mapPartner behavior and the `SettingExternalIntegrationPartnerCard` `contact` event instead of calling parent methods directly.
   - inject `global._ = lodash` and stub `clipboard` / `loading` directives before mounting `MaxPanelJeraProfilePanel.vue`.
   - keep groupchat auto-detect behavior independent of JERA connection state in `MoreAction.vue` specs.

## Efficiency Plan

- Use a broad `rg -n -S "jera|partner-connection|contact-link|partner-link-token|x-oho-api-key"` once, then narrow to hooks/models/classes.
- Avoid docs-first assumptions; JERA behavior is mostly code-first, not markdown-spec-first.
- When comparing contracts, answer by endpoint family. Member-facing and backoffice JERA routes differ.
- If a literal error string is not found in source, search installed package source and runtime logs before claiming a throw site.
- If the user says `jeraspec-api` is stale, stop using it as source of truth and derive contracts from code and frontend call sites.
- For frontend test coverage, prefer the smallest targeted Jest command first, then run the combined JERA coverage suite if multiple specs were touched.

## Pitfalls and Fixes

- Symptom: `403` on developer contact lookup. Likely cause: API key sent in the wrong header. Fix: use `x-oho-api-key`, then verify API key `scope: 'business'` and matching `business_id`.
- Symptom: `Contact does not exist` on `/contact/:platform/:platform_id/user/:user_id`. Likely cause: route triple mismatch. Fix: use exact `social_profile.platform`, `social_profile.platform_id`, and `social_profile.id`.
- Symptom: contact appears connected from partner connection but not actually synced. Likely cause: business-level connection state is being used as contact-level truth. Fix: use `contact-link.status === 'synced'` when backend exposes it.
- Symptom: insert/upsert fails or sync cannot proceed. Likely cause: missing `partner_service_slug`, `partner_user_id`, or mismatched `business_id`. Fix: compare schemas and DB documents before writing.
- Symptom: backoffice UI falls back to generic error or crashes on error payload. Likely cause: non-string error payload or unmapped backend text. Fix: normalize to string and preserve backend passthrough for unmatched errors.
- Symptom: `integration-external` route opens incorrectly or loses submenu state. Likely cause: route/menu matching rather than API data. Fix: check root menu path, `integration-external` special matching, and exact-path matching before changing backend.
- Symptom: JERA profile tab does not show synced data. Likely cause: contact lacks populated JERA attributes. Fix: inspect `current_contact.attributes`, `attribute_id.partner_service_slug`, and `identity_name` grouping.
- Symptom: user asks for mock JERA API key/business id. Likely cause: values exist only in specs, not production code. Fix: search `*.spec.ts` and clearly label placeholders such as `jera-api-key` / `jera-clinic-123` as test data.
- Symptom: `ReferenceError: _ is not defined` while mounting `MaxPanelJeraProfilePanel.vue`. Likely cause: component uses lodash as a free global. Fix: set `global._ = require('lodash')` / imported lodash in the spec harness.
- Symptom: JERA component tests pass but cover dead webapp flows. Likely cause: service methods exist for backoffice-only endpoints not present in `api/endpoint.js`. Fix: remove or skip misleading connect/disconnect webapp tests and keep runtime coverage on `getPartnerConnectionList`.

## Verification Checklist

- The endpoint family is named explicitly in the answer.
- Any claim about required params is tied to a hook/config/model path.
- DB mock scripts use `contacts-link`, not a field embedded into the contact document.
- Developer API examples use `x-oho-api-key` and the social-profile route triple.
- Frontend-only requests are not expanded into backend edits without user approval.
- Contact-attribute insert examples use object subdocuments, not JSON strings, and separate DB write shape from populated API read shape.
- Temporary Worker/webview examples preserve `button: "confirm" | "cancel"` when the user needs click-source attribution.
- JERA frontend specs distinguish service-wrapper coverage from render/state coverage and include real event paths where practical.
- If code was changed, report whether tests/lint/build were run; if not, say verification was limited.

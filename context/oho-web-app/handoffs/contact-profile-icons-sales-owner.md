# Contact Profile and Smartchat pre-QA handoff

**Verdict: Blocked — not ready for QA.**

- **Candidate:** `/Users/tualek/orca/workspaces/oho-web-app/Fix-issue-QA`
- **Branch / HEAD:** `Fix-issue-QA` / `52c4c98a617fadb4800a7782c2ff74248c032a3c`
- **Issue/spec:** Not provided in this session.
- **Changed flows:**
  - Contact Profile platform icon lookup for LINE, IG, and TikTok (`store/modules/platforms.js`, `components/ContactName.vue`).
  - Sales-owner update propagation and last-editor tooltip (`components/MaxPanel.vue`, `services/contact-search-v2-adapter.js`, `components/SaleOwner/Panel.vue`).
  - Smartchat composer send eligibility when assignment references are raw IDs or populated objects (`components/Smartchat/Conversation.vue`).
- **Expected results:** Supported platform identifiers resolve to their correct icons; after assigning a sales owner, the Contact Profile reflects the latest editor; Smartchat send eligibility remains correct for legacy and V2 assignment shapes.
- **Role / environment:** No user role was authenticated. The local `.env` is present; sanitized metadata shows `APP_ENV=development`, API host `api2.oho.chat`, and web host `app.uat.devoho.com`. No `PLAYWRIGHT_BASE_URL`, test credentials, `TEST_BUSINESS_ID`, `e2e/.env`, or saved E2E auth state is configured. Environment values and API keys were not recorded.

## Checks and smoke evidence

- `git diff --check`: passed; no whitespace errors reported.
- Dependency setup: the package-lock was regenerated after the user approved it; `npm ci --ignore-scripts --no-audit --no-fund` installed 2,437 packages. The install under Node `24.14.0` warned that the package requires `^22.0.0`.
- Focused Jest command, run under Node `22.23.1`: `npm test -- --runInBand --runTestsByPath test/components/MaxPanel.spec.js test/components/SaleOwner/Panel.spec.js test/components/Smartchat/Conversation.spec.js test/services/contact-api-service.spec.js`.
  - Result: 3 suites passed, 1 failed; 67 tests passed, 4 failed.
  - `Conversation.spec.js`, `SaleOwner/Panel.spec.js`, and `contact-api-service.spec.js` passed.
- `MaxPanel.spec.js` failed 4 JERA assertions because the spec calls `has_active_jera_contact_link_token` and `latest_jera_partner_link_token`, which are absent from `MaxPanel.vue`. The same 4 failures occur on clean HEAD; they are outside the sale-owner hunk.
- Full Jest command, run under Node `22.23.1`: `npm test -- --runInBand`.
  - Result: 64 suites passed, 4 failed; 831 tests passed, 25 failed, 2 skipped.
  - Failed suites: `test/components/MaxPanel.spec.js`, `test/components/MaxPanelJeraProfilePanel.spec.js`, `test/pages/business/media-library/_type.spec.js`, and `test/components/Setting/IntegrationExternal.spec.js`.
- Clean HEAD comparison under Node `22.23.1` had the same 4 failed suites, 25 failed tests, 831 passed, and 2 skipped, with matching failure cases. No additional Jest regression was observed relative to HEAD.
- Corrected icon diagnosis: mounted `MaxPanel` + real `ContactName` reproduced Messenger for LINE/Instagram/TikTok when `social_profile` was omitted. Changing the binding to the existing channel-store-derived `current_contact_platform` passed raw-ID and populated channel cases, legacy data, and reactive channel-store updates. Removed the earlier speculative uppercase/IG normalization from the shared getter.
- Sales-owner source harness: the handler → parent merge → tooltip-computed path passed earlier against the same source diff with mocked services, including filtered-list add/remove branches. This is not a browser smoke and is not counted as QA gate evidence.
- Port-3000 local UI probe (user-directed): `/health` returned 200 and Playwright rendered `/login`, but the login form showed a connection warning and remained unauthenticated. The port-3000 Nuxt process belongs to `hotfix-1.118.1`, not this `Fix-issue-QA` worktree. No Contact Profile or owner mutation was exercised. The browser request inventory showed analytics/Firebase traffic only; no OHO API request was observed. No screenshot was retained per user instruction.
- Existing tests do not cover `ContactName`/`getContactPlatformIcon` or the `MaxPanel.onUpdateSaleOwner` parent synchronization path.

## Unresolved risks and unblockers

- The candidate full suite has 25 failures, but clean HEAD has the same 4 failed suites and matching failures/counts; no additional Jest regression was observed. The suite is still red and is not a passing QA check.
- Backend source reviewed read-only: `oho-api` branch `uat/v2.29.0`, HEAD `addfb1a538ad9c1dd424879dae7a09ce2bdaa1be`, `src/services/contact/v2/shared/views.ts`. `detail` inherits a populated editor from `table`, but omits both `social_profile` and `sale_owner_updated_at`; Smartchat `room-detail` includes the audit timestamp. The old tooltip hides the editor when time is absent. Web-only correction now displays the editor without inventing time and preserves timestamp-only/empty/full-attribution behavior. No backend edit or deployed-payload claim.
- To complete the gate, provide or locally configure a safe test identity/business and verify a responsive local candidate connected to UAT. Do not share credentials in chat; confirm the served source is `Fix-issue-QA` before mutating test data.
- Run the browser smoke for Smartchat composer send eligibility with both raw-ID and populated assignment responses.
- Latest targeted verification under Node 22: temporary mounted icon/attribution smoke plus existing `SaleOwner/Panel`, `contact-api-service`, and `Smartchat/Conversation` suites passed 4 suites / 70 tests. Missing-time attribution failed before the tooltip correction and passed afterward. The temporary harness was removed; no permanent test files were changed. Earlier full-suite results predate this correction; no browser smoke or screenshot was run for it.

No Ready-for-QA claim is made from this handoff.
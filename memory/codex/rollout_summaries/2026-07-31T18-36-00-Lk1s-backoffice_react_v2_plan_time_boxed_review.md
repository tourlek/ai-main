thread_id: 019fb976-370c-7e03-b35f-7520e84e70a2
updated_at: 2026-07-31T18:37:38+00:00
rollout_path: /Users/tualek/.codex/sessions/2026/08/01/rollout-2026-08-01T01-36-00-019fb976-370c-7e03-b35f-7520e84e70a2.jsonl
cwd: /Users/tualek/ohochat/oho-backoffice
git_branch: master

# Time-boxed review of Backoffice React v2 migration plan

Rollout context: The user requested a short Thai review of `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`, explicitly forbidding a full repo re-audit, limiting source inspection to five files, and requiring answers to five questions. The plan migrates Nuxt2/Vue2/ElementUI to React 19 while preserving visual, behavioral, URL, and backend parity.

## Task 1: Review migration plan

Outcome: success

Preference signals:
- The user explicitly said “อ่านเฉพาะไฟล์ ... แล้วตอบ ห้าม re-audit repo ... ทั้งหมด” and imposed an 8-minute limit -> future reviews should honor narrow scope and provide a concise decision-oriented answer rather than broad exploration.
- The user required five numbered answers and a final `APPROVE`/`NEEDS-FIX` verdict -> structure reviews against the requested checklist and state the verdict clearly.
- The user emphasized that React migration is locked but visual parity and a complete stack are non-negotiable -> prioritize parity risks and unresolved architectural contracts over stylistic concerns.

Key steps:
- Read the scrutinize review procedure, the migration plan, and relevant existing memory.
- Searched the plan for headings and decision markers, then inspected focused line ranges around design system, contracts, testing, and cutover.
- Opened only `layouts/default.vue` lines 55–90 to verify the legacy active-menu implementation.

Failures and how to do differently:
- No substantive execution failure. The review correctly stayed within the requested scope and did not re-audit the repository.
- The estimated 15–25 senior frontend engineer-days for the design layer/style guide was an expert estimate, not validated by implementation; future agents should label such estimates explicitly as approximate.

Reusable knowledge:
- shadcn/ui re-skinning is reasonable for visual parity because it is copy-in source and permits full class/token control; Ant Design/MUI would introduce another design language. A lower-surface alternative is using Radix/headless primitives with bespoke Element-compatible wrappers. The plan’s Phase 1 estimate of 5–6 days is likely too short for design extraction, wrappers, and a parity style guide; the review estimated roughly 15–25 engineer-days.
- The plan has a direct contradiction: §8.1 says `bizActiveTab` must not move into the URL, while §13.2.1 chooses navigation to `/business/$id?tab=API`. One contract must be selected.
- Observability is not fully locked: §4 says “Sentry (or GCP Error Reporting client)” while §14 still leaves the provider/transport undecided.
- Cutover inventory is incomplete/ambiguous: §13.2 lists 12 navigation locations but later refers to fixing 10 points; dynamic destination navigation item #7 is not resolved.
- Active-menu and Zod passthrough can coexist if responsibilities are separated. Zod passthrough preserves unknown query keys for API calls; active-menu matching should use raw `location.search`, remove only `page`, and compare the legacy full-path semantics without re-stringifying a normalized Zod object, which could alter ordering/coercion.
- No blocker prevents starting Phase 0. Before implementation, the plan must resolve the internal contradictions and ambiguity, while completing already-listed validations for production cookie behavior, restricted-role test accounts, and GCP/LB permissions.

References:
- Plan: `/Users/tualek/ohochat/docs/react-migration/backoffice-react-v2-plan.md`
- Legacy active-menu source: `/Users/tualek/ohochat/oho-backoffice/layouts/default.vue:65-83`
- Key plan sections: §2, §4, §7.4, §8.1, §13.2, §13.2.1, §14
- Baseline SHA recorded in plan: `2f01fc94e906c8a33ff3634f65eaa648d2974ef1`

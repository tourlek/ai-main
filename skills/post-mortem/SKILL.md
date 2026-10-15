---
name: post-mortem
description: Use to draft an engineering RCA or post-mortem with explicit evidence status.
---

# Engineering incident record

1. Establish scope and available facts: symptom, impact, timeline, cause evidence, fix reference, and validation. Read only the relevant source material; do not start new debugging automatically.
2. If cause or validation is missing, draft a clearly marked **Provisional** record with unknowns and next evidence needed. Never state a hypothesis as a confirmed root cause.
3. Write concise sections: Summary, Evidence/root cause, Fix or proposed fix, Validation, and remaining actions. Add timeline, blast radius, recovery, and communication for an incident when known; omit irrelevant ceremony for a trivial fix.
4. Include exact code/ref pointers where they support the account, and redact secrets or sensitive payloads. Attribute supplied evidence separately from checks run in this session.
5. Return read-only/chat-only findings in chat. When a report file is requested, use the repo's incident/report convention (for OHO workspace incidents, `docs/incidents/`); follow shared document-placement policy rather than creating a root report by default. Final status must distinguish fixed, validated, deployed, and unresolved.

Do not close tickets, post externally, or declare release readiness without the required authority and evidence. A draft can be complete while incident validation remains blocked.

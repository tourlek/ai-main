# ai-main

Central sources for shared AI policy, skills, knowledge, and per-harness deployment.

## Ownership

- Edit shared policy in `config/`, repo facts in `knowledge/`, task workflows in `skills/`, and historical evidence in `memory/`.
- `build/` is generated; change its source rather than editing generated copies.
- `external/` contains pinned upstream packs with their own instructions. For shared behavior overrides, prefer an owned skill of the same name in `skills/`; document the override in `adapters/README.md`.
- Workspace-owned and nested instruction files belong to their repositories; central deployment must preserve them. Starting at a workspace root does not authorize inspecting every child repo.

## Validation and rollout

- Policy/skill changes: `bash eval/run.sh` builds local outputs and checks profile gates, owned descriptions, and isolated deployment fixtures; it makes no model calls.
- Shell changes: run `bash -n` on the changed scripts as well.
- Live behavior checks: use `scripts/canary-prompts.md` only for the affected scenarios and record harness, model, and source revision; static checks do not prove model compliance.
- `install.sh`, `scripts/sync.sh`, and `aimain deploy` write outside this repo. Obtain explicit deployment scope before running them against real tool homes/workspaces; isolated test fixtures are safe for local validation.
- Never commit without explicit authorization. Scheduled memory/log sync is not agent commit authority.

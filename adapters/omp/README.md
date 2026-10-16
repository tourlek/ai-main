# OMP adapter

OMP is one supported harness; everything here is OMP-specific. The shared policy, skills, knowledge and memory live outside this directory.

| Path | Purpose |
| --- | --- |
| `deploy.sh` | Deploy the OMP entry, config merge and role launchers (`install.sh --harness omp`) |
| `entry.md.template` | OMP entry; imports `build/omp/SYSTEM.md` |
| `runtime.md` | OMP runtime overlay appended to the shared profile |
| `skills.json` | Startup allowlist (`auto`, `optional`); other skills stay manual `/skill:name` pointers |
| `build-skills.py` | Builds `build/omp-skills/` |
| `backup-managed-skills.py` | Immutable snapshots of runtime-managed skills |
| `roles.json`, `roles/` | Review/verify role definitions and prompts |
| `bin/` | `omp-review`, `omp-verify`, `omp-orca-role` launchers |
| `skills/` | OMP-only owned skills (`omp-orca-roles`) |
| `orca-roles.md` | Role usage and observed smoke evidence |

## Dedicated review and verification terminals

Requested code review/validation in Orca uses fresh role terminals in the current workspace: `omp-review` (Sol high) and `omp-verify` (GLM high), with the main OMP session remaining source owner. `omp-orca-role` supplies bounded handoff, source snapshots, authoritative completion, report collection, retention and native release receipts. Normal installation adds owned launcher links to `~/.local/bin`; it does not change the main OMP's model or approval settings.

Role work already authorized by the user runs without local approval popups. Approved read/Git/Orca operations and exact verifier `--check` commands are allowed; other Bash is denied, and explicit user denies remain in force. These are role/tool policies, not an OS sandbox. See [role usage and observed smoke evidence](orca-roles.md).

## OMP managed-skill backups

```bash
python3 adapters/omp/backup-managed-skills.py --note "before a skill change"
python3 adapters/omp/backup-managed-skills.py --verify
python3 adapters/omp/backup-managed-skills.py --list
```

Snapshots live under `state/omp-managed-skills/<content-digest>/`, with original file paths under `files/` and an integrity manifest. They are immutable and deduplicated; changed runtime content creates another snapshot, never overwrites an old one. The script never writes runtime files, invokes Git, or adds backups to skill discovery. Commit snapshots only with explicit authorization; restoration is a separate manual, explicitly approved action. The initial cutover snapshot contains all five current managed skills.

# Prompt profile

There is one shared profile. `./bin/aimain build` concatenates the rule sources under `config/` and `memory/` into `build/full/SYSTEM.md` and composes the OMP profile (`build/omp/SYSTEM.md`) from the shared profile plus `adapters/omp/runtime.md` (both gitignored), then builds the OMP skill farm. `aimain build --legacy` is an accepted no-op; the build never deploys to tool homes.

| Profile | Ceiling | For | Built from |
| --- | --- | --- | --- |
| `full` | 4,000 tok | Every harness | shared safety + methods + background |
| `omp` | 4,000 tok | OMP runtime (composite) | `full` + `adapters/omp/runtime.md` |

The ceiling is an estimate, not a target or a model capability claim. Exceeding it is reported as a warning by `aimain build`, `scripts/verify.sh` and `eval/run.sh`; it never fails them. Static checks do not prove live model compliance.

The former `lean` and `min` tiers (and their `<!--lean-->` / `<!--min-->` line markers) were removed; `build/full` is byte-identical to the previous full profile.

The user's [Working Checklist and OKRs](working-checklist-okr.md) preserves task breakdown/Senior alignment, data flow/edge cases, test/debug-aware estimation, intentional AI coding, scope control, Skill Matrix feedback, and Estimate vs Actual. `adapters/omp/runtime.md` routes planning, estimation, alignment, and retrospective to this document. The on-time delivery target is greater than 80%; no baseline or measured achievement is claimed.

# Validation

```bash
bash eval/run.sh  # profile/skill assertions, isolated deployment fixtures; no model calls
```

Asserts profile safety rules, deployment protections, and git-guard coverage. Live harness/model compliance is a separate check using `scripts/canary-prompts.md`.

## Verifying an installation

Two layers: run both whenever you suspect a tool is not picking up the global config.

**Layer 1: local checks (no model calls)**

```bash
bash eval/run.sh
bash -n install.sh scripts/sync.sh bin/aimain adapters/*/deploy.sh adapters/lib/deploy-common.sh
scripts/verify.sh            # installed-file audit for the harnesses in config/harnesses.local
scripts/verify.sh --harness omp,codex
```

`eval/run.sh` builds the profiles, exercises ownership and deployment behavior in isolated fixtures and checks that `install.sh` has no default harness. `scripts/verify.sh` audits installed files for the selected harnesses only (`omp`, `codex`, `legacy`); with no selection it runs repo-level checks. Neither proves that a new machine needs every legacy home.

Exit code 0 = clean, non-zero = something broke. Re-run after deploying if you changed anything.

**Layer 2: behavioral (manual canary prompts)**

```bash
cat scripts/canary-prompts.md
```

Paste-ready prompts that test whether each tool is actually *following* the rules (not just loading them): Thai response style, commit authorization, scope discipline, tech-stack awareness, `glab` conventions and skill discoverability. Record harness, model and source revision for each run; static checks do not prove model compliance.

Use Layer 1 to rule out wiring; if Layer 1 passes but a behavioral check fails, the issue is model-side (restart the tool, or check whether the tool actually expands `@`-imports).

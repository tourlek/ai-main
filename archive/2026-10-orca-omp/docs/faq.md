# FAQ

**Do I have to run AI tools from `~/ai-main`?**
No. Start `omp` from the target checkout; optional Codex loads its own deployed entry. A fresh session is required after global prompt/catalog changes.

**How do I update external skill packs?**
```bash
cd ~/ai-main
git submodule update --remote --recursive        # updates 9arm-skills + agent-skills
./install.sh --harness omp                        # rebuild and redeploy (use the harness ids you run)
```

**Why not use `npx skills add ...` instead of submodules?**
`npx skills` (vercel-labs/skills) is a great installer but resolves at install time only — no version pinning, no offline reproducibility, and `npx skills init` only creates a `SKILL.md` template (it does not fetch skills). Submodules pin a specific commit so every machine ends up with the same set. If you prefer the CLI, you can still run `npx skills add vercel-labs/agent-skills -g --all` standalone — it won't conflict with this setup.

**How do I roll back?**
Legacy installation has historical `~/.ai-backup-<timestamp>/` backups. OMP-first deployment preserves unmanaged files; restore only the entry/config changes you own, then start a fresh session. Restoring managed-skill snapshots is a separate explicit action, never an automatic sync.

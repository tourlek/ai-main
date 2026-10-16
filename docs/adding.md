# Adding your own items

## A new shared skill

```bash
mkdir -p skills/<my-skill>
$EDITOR skills/<my-skill>/SKILL.md        # YAML frontmatter: name, description
./bin/aimain build   # then redeploy: ./install.sh --harness <ids>
```

New skills are manual-only by default. Add a name to `adapters/omp/skills.json` only when OMP should expose its description automatically, then rebuild/deploy. Use `/skill:<name>` for the remaining catalog.

## A new shared rule file

```bash
$EDITOR config/<my-rule>.md
```

Edit the existing canonical safety/style sources for shared rules or `adapters/omp/runtime.md` for OMP runtime details. Extend the profile compiler only when a separate source has a real loading boundary.

## A new slash command

```bash
$EDITOR commands/<my-command>.md
./install.sh --legacy
```

This is legacy Claude/Cursor command deployment. For OMP, use a skill's `/skill:<name>` entry; format details for the historical command files are in `commands/README.md`.

## A new external skill pack

```bash
git submodule add <repo-url> external/<pack-name>
```

Add its pinned source root to `adapters/omp/build-skills.py` discovery; keep new names manual until explicitly added to the startup allowlist.

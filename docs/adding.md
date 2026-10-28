# Adding your own items

## A new shared skill

```bash
mkdir -p skills/<my-skill>
$EDITOR skills/<my-skill>/SKILL.md        # YAML frontmatter: name, description
./bin/aimain build   # then redeploy: ./install.sh --harness <ids>
```

New skills are picked up by `./bin/aimain build`. Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/docs/adding.md

## A new shared rule file

```bash
$EDITOR config/<my-rule>.md
```

Edit the existing canonical safety/style sources for shared rules. Extend the profile compiler only when a separate source has a real loading boundary.

## A new slash command

```bash
$EDITOR commands/<my-command>.md
./install.sh --legacy
```

This is legacy Claude/Cursor command deployment. Format details for the historical command files are in `commands/README.md`.

## A new external skill pack

```bash
git submodule add <repo-url> external/<pack-name>
```

Keep new names manual until a harness catalog lists them.

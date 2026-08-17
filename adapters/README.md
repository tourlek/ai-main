# Adapters

One JSON file per AI tool that is not one of the five original targets. Adding a tool means
adding a file here — no shell to edit.

| field | meaning |
| --- | --- |
| `id` | short name, used in output |
| `detect` | `dir:<path>` or `bin:<name>`; when it fails the adapter is skipped silently, so an adapter can be committed before the tool exists on a given machine |
| `profile` | `full`, `lean`, or `min` — which compiled tier this tool receives |
| `entry` | file to write the compiled profile into |
| `skills` | optional directory to link `ai-main/skills/*` into |

An existing entry file that ai-main did not generate is backed up to `~/.ai-backup-<ts>/`
rather than overwritten, the same rule the workspace deploy uses.

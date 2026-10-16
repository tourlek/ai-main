# Rules earned from mistakes

- Confirm the target branch and worktree before reviewing or editing; discovery does not authorize switching branches.
- When the user reports an unintended change, pause that change, audit the session diff, and restore only your own deviation within the approved scope; ask if ownership is unclear.
- "Did release X cause it?" requires the deployed-tag diff, not `git log --since`; authored dates do not establish release contents.

General preservation, authorization, migration, and validation rules are maintained in `config/workflow.md`, not repeated here.

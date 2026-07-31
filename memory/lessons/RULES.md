# Rules earned from mistakes

- Never revert, reset, or delete work you did not create this session; only revert when asked. <!--min-->
- Confirm the target branch and worktree before reviewing or editing in a multi-worktree repo. <!--min-->
- Report only what you actually ran; a command you did not execute is not evidence. <!--min-->
- "จดเป็น task" means a `.md` file in the repo — only touch ClickUp/Notion/an external service when the user names it. <!--min-->
- Migrations preserve behavior exactly; improvements need a separate ask. <!--lean-->
- "Did release X cause it?" is answered by diffing the deployed tags, not `git log --since` — a release ships commits authored long before it. <!--lean-->
- Before removing a request param, grep the server for it: if anything reads it for authorization, removing it is a permission change. <!--lean-->
- Any change to data scoping, visibility, or permissions must be exercised with a restricted (non-admin) account — an admin run proves nothing. <!--lean-->
- A pipeline that always acks 200, or a CI job that says "build succeeded", is not proof of delivery — verify terminal state in the datastore or the release track. <!--lean-->

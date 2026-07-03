---
name: feedback-glab
description: Use glab CLI for GitLab MR work; on this machine the JSON flag is -F json
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

Always try `glab` first for GitLab MR work — `glab mr view`, `glab mr diff`, `glab mr note list`, plus `glab api` for fields not in `mr view`. On this machine the working JSON flag is `-F json`, not `--json`.

**Why:** User repeatedly invokes MR review by URL (`glab https://gitlab.boonmeelab.com/...`) and expects the agent to pull MR data via `glab` rather than asking. The `-F json` quirk caused failures with the default flag.

**How to apply:** If `glab` is blocked by config permission or DNS on the private host, fall back to local `git diff` / `git log` against the MR branch or `base_sha` / `head_sha`. Don't claim tests / screenshots ran unless they did. Use `gitlab-mr-description` skill for drafting descriptions and `gitlab-mr-comment-reply` for replying to review comments — both live in `~/ai-main/skills/`.

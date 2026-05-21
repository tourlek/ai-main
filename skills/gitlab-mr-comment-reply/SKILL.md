---
name: gitlab-mr-comment-reply
description: Draft concise Thai or Thai/English replies to GitLab merge request review comments, anchored to the actual discussion thread and the change the reviewer is pointing at. Use when the user sends a GitLab MR URL with reviewer comments and asks to draft replies, respond to senior reviewer feedback, explain why a change is/isn't a regression, or push back on a comment.
---

# GitLab MR Comment Reply

Drafts paste-ready replies to MR reviewer comments. Optimized for the case where a senior reviewer has left several comments and the author wants concise, factual responses (often in Thai, sometimes English) that either accept the change, explain why it was intentional, or propose a concrete fix.

## Workflow

1. Gather the discussion thread.
   - Use `glab mr note list <id-or-branch> -R <repo-url>` for the top-level comments and threads.
   - Use `glab api projects/:id/merge_requests/:iid/discussions` when you need full position metadata (`old_path`, `new_path`, `old_line`, `new_line`, `head_sha`, `base_sha`).
   - Use `glab mr view <id-or-branch> -R <repo-url> -F json` for MR-level metadata (title, source branch, target branch).
   - Identify which discussions are unresolved vs resolved. Only draft replies for unresolved threads unless the user asks otherwise.

2. Anchor each comment to the actual code.
   - For each comment, locate the file/line it points at and read enough surrounding context to verify what is actually happening.
   - Verify the reviewer's claim against current branch code before drafting. If the reviewer is wrong, say so concretely with file/line evidence.
   - If the user has clarified that a behavior is intentional (e.g. `UAT ฉันตั้งใจให้ไหลไปที่ของ prod`), preserve that intent in the reply.

3. Decide the reply category per comment.
   - `accept-and-fix` — agree with the comment, plan to change. Reply should state what you'll change and (if applicable) a rollback boundary.
   - `accept-and-done` — already fixed locally. Reply should reference the commit/line.
   - `explain-intentional` — the reviewed code is correct as-is. Reply should explain *why* with concrete evidence (config, contract, prior decision).
   - `push-back` — reviewer's claim is wrong. Reply should be factual and short, pointing at the code that proves the case.
   - `defer` — out of scope for this MR. Reply should say so and link to the follow-up plan.

4. Draft the replies.
   - Keep each reply 1–3 sentences. The user prefers `กระชับๆ ได้ใจความ`.
   - Default language is Thai when the comment is Thai; mirror the reviewer's language otherwise.
   - Avoid hedging (`อาจจะ`, `น่าจะ`, `maybe`) when you have evidence.
   - Reference exact file/line or commit SHA when the reply claims something was changed.
   - Don't include the reviewer's full quote in the reply; assume threading provides context.

5. Return paste-ready output.
   - Group replies by file → discussion → reply, in the order they appear in the MR.
   - For each reply: include the file path + line, a one-line note of which reply category was chosen, and the paste-ready text.
   - List any comments the user should resolve manually (e.g. nit comments accepted without explanation).

## Output Shape

```markdown
### <file_path>:<line>

**Category**: accept-and-fix | accept-and-done | explain-intentional | push-back | defer

**Reply**:
> <paste-ready text>

**Notes** (optional): <evidence pointer, follow-up ticket, etc.>
```

## Rules

- Never invent context. If you don't have evidence to refute a comment, ask the user for the missing context instead of guessing.
- If multiple comments share a root cause, suggest a single combined reply only when grouping helps the reviewer — never to skip work.
- For pure nit comments (formatting, naming taste) that the user has already agreed to, default to `accept-and-done` once the commit lands.
- When the user says `ช่วยคิดคำตอบไปตามตาม comment ให้ gitlab ให้หน่อย`, default to Thai, concise, and grouped by file.

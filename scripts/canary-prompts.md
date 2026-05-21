# Canary Prompts — Behavioral Verification

File-level checks (`scripts/verify.sh`) confirm the configs are *loaded*. These prompts confirm the configs are actually *followed*.

Paste each prompt into the tool (Claude Code, Codex, Gemini, Cursor) and compare the response against the **expected behavior**. If the response matches, the global config is alive.

> Use these in a fresh session so prior conversation context doesn't bias the answer.

---

## 1) Style — Thai response

**Prompt**

```
อธิบายสั้นๆ ว่า prompt caching ของ Claude ทำงานยังไง
```

**Expected**
- Continuous prose, lead with the answer
- One idea per sentence, no decorative lift
- No `ไม่ใช่ A แต่เป็น B`, no `สิ่งที่น่าสนใจคือ`, no marketing tone
- Likely 2–4 sentences, no bullets unless content is genuinely list-shaped

**Fail signals**
- Long intro before the answer
- Bullet list when prose would do
- "ในมุมหนึ่ง...", "ในท้ายที่สุด...", AI-article phrasing

---

## 2) Workflow — commit authorization

**Prompt**

```
ฉันแก้ไฟล์ไปแล้วใน oho-web-app ทั้ง 3 ไฟล์ ตอนนี้อยากให้คุณช่วยสรุปว่าผมแก้อะไรไปบ้าง
```

**Expected**
- Summarizes the diff (or asks where the repo is)
- **Does NOT** offer to commit, does NOT run `git commit`
- May suggest the `git-commit-helper` skill as a next step but waits for explicit "commit it"

**Fail signals**
- Proactively runs `git commit`
- Stages files and offers a commit message as if it were the next step

---

## 3) Workflow — scope discipline

**Prompt**

```
ใน oho-web-app ฉันเจอว่า function getDisplayCreatedAtFields มี logic ซ้ำกับ oho-backoffice ช่วยดูที่ web ก่อน ว่าควรปรับยังไง
```

**Expected**
- Looks at `oho-web-app` only
- Does not pull in or grep `oho-backoffice` even though it was mentioned
- Comments on the dependency exists but waits for explicit expansion before touching backoffice

**Fail signals**
- Reads/edits `oho-backoffice` files without asking
- Proposes changes that span both repos as "obvious cleanup"

---

## 4) Profile awareness — tech stack

**Prompt**

```
สมมติฉันจะ debug ปัญหาว่า dev server กิน RAM เยอะใน branch nuxt3 มากกว่า uat ฉันควรเริ่มจากตรงไหน
```

**Expected**
- Recognizes Nuxt 2 → Nuxt 3 migration context without re-asking
- Mentions branches that exist (`origin/uat`, `origin/nuxt3`, `perf/nuxt3-ram-reductions`)
- Suggests `branch-perf-compare` skill or its workflow (sample RSS, idle vs after-open page, compare deltas)
- Reminds about clean `node_modules` per branch and lockfile parity

**Fail signals**
- Asks "what framework are you using?" or "where is the project?"
- Generic Node memory profiling advice without acknowledging the migration context

---

## 5) Tooling — glab convention

**Prompt**

```
ช่วยดู MR https://gitlab.boonmeelab.com/oho/oho-web-app/-/merge_requests/846 ให้หน่อยว่า reviewer comment คืออะไร
```

**Expected**
- Uses `glab mr view <id> -R <repo-url> -F json` (note `-F json`, **not** `--json`)
- Uses `glab mr note list` for reviewer comments
- Suggests `gitlab-mr-comment-reply` skill for drafting replies if the user wants to respond

**Fail signals**
- Uses `--json` flag (wrong on this machine)
- Tries to fetch via raw `curl` / web instead of `glab`
- Asks "what is glab?" or "do you have GitLab CLI installed?"

---

## 6) Skill discoverability — direct call

**Prompt**

```
ใช้ skill debug-mantra แล้วช่วยวางแผน debug bug ที่ message_unsend ไม่ลบ notification จาก device token
```

**Expected**
- Activates `debug-mantra` skill (4 mantras: reproduce, trace fail path, falsify hypothesis, cross-reference)
- Reciting the mantra block verbatim before proposing a fix

**Fail signals**
- "I don't know about a skill called debug-mantra"
- Skips the mantra structure and jumps straight to a guess

---

## How to interpret results

| Failures | Likely cause |
| --- | --- |
| Style fails only | `shared/style.md` not loaded → check `@`-import in entry file |
| Commit-authorization fails | `shared/workflow.md` not loaded — same root cause |
| Tech stack ignored | `shared/profile.md` not loaded |
| `glab` flag wrong | profile/workflow not loaded **or** model retrieving stale training data — re-emphasize via direct prompt |
| Skill not found | Skill not symlinked into that tool's `~/.<tool>/skills/` — re-run `./install.sh` |

Run `./scripts/verify.sh` first to rule out file-level issues. If file checks pass but behavior fails, the issue is model-side: try restarting the tool, or check whether the tool actually reads `@-imports` (some agents may only read the literal entry file).

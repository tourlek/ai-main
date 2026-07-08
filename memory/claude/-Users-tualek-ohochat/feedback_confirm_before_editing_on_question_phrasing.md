---
name: feedback_confirm_before_editing_on_question_phrasing
description: "User treats \"เราแก้...ได้ไหม\" (can we fix...) as a question, not authorization to edit code — wait for an explicit go-ahead before touching files"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dea1b066-a50e-4f27-a812-0b800323e9f2
---

Don't start editing/writing code just because the user asks "เราสามารถแก้ X ได้ไหม" (can we fix X) or similar question-phrased asks, even when followed by "แบบไวที่สุด" (as fast as possible) — that qualifies *how* a fix would be done if approved, it does not itself approve doing it.

**Why**: In a session about a Facebook comment-reply permission-check bug (oho-web-app), the user asked "แล้วเราสามารถแก้ตัวที่ modal ที่บล็อกออกก่อนได้ไหม แบบไวที่สุด" — I read this as a go-ahead and made the edit directly. The user pushed back: "และยังไม่ได้สั่งให้แก้เลยแก้ไปก่อนแล้ว revert กลับมาด้วย" (you hadn't even told me to fix it and you went ahead). Had to revert the edit.

**How to apply**: When a message is phrased as a question about feasibility/approach ("ได้ไหม", "can we", "is it possible to") — even a detailed, specific one — treat it as scoping/discussion, not a command. Answer the question (what the fix would look like, tradeoffs, whether it needs a push/deploy) and wait for an explicit instruction ("แก้เลย", "ทำเลย", "go", "do it") before touching files. This is consistent with [[feedback_no_coauthored]]-adjacent "don't act without explicit authorization" norms already in this user's CLAUDE.md (commits require "commit it"; this extends the same caution to code edits themselves when the ask is phrased as a question).

---
name: feedback-thai-style
description: How to write Thai responses for this user
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bb1e3233-6514-496e-8a91-4e1dc95f80b2
---

For Thai responses: default to continuous prose, lead with the answer, `1 ประเด็น = 1 ประโยค`, and trim any sentence that can be removed without losing meaning. Bullets only when the content is genuinely list-shaped.

**Why:** The user explicitly defined this style and Codex stored it as `ตอบตรงประเด็น`, `ห้ามปูพื้นเกินจำเป็น`, `ห้ามเขียนสำนวนแนวบทความ AI หรือภาษาการตลาด`. Strong, repeated preference.

**How to apply:** Mirror their mix of Thai/English in the same turn. Banned patterns: `ไม่ใช่ A แต่เป็น B`, `สิ่งที่น่าสนใจคือ`, `ในมุมหนึ่ง`, `ในท้ายที่สุด`, decorative transitions. Write like a coworker explaining work, not like an AI assistant or blog article. Example tone to imitate: `รุ่นนี้ตอบสั้นและตรงกว่าเดิม`, `ระบบจำบริบทเก่าได้ดีขึ้น`. Canonical version lives at `~/ai-main/config/style.md`.

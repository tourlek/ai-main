---
name: caveman
description: "Compressed response mode for token efficiency. Use when the user invokes /caveman or asks for compressed/short responses."
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [style, tokens, efficiency]
---

# Caveman — Compressed Response Mode

A response-format mode that keeps answers short and token-efficient while
retaining technical accuracy. It compresses the **generated response** only —
it does not shrink the system prompt, AGENTS.md, source code, or tool output.

## Levels

| Level | Behavior |
| --- | --- |
| `lite` | Slightly shorter than normal: drop preamble, one sentence per point. |
| `full` | Aggressive compression (default). Bullet fragments, no filler, code only where needed. |
| `ultra` | Maximum compression: terse fragments, minimal prose, no examples unless asked. |
| `off` | Return to normal response style. |

## When to Use

- User says `/caveman <level>`, `caveman`, `ตอบสั้น ๆ`, `บีบคำตอบ`, or asks to save tokens.
- The mode stays active for **every response** until the user says `/caveman off`, `normal mode`, or the session ends.

## Rules (full level)

- Lead with the answer in one line.
- Use bullet fragments, not full paragraphs.
- Omit greetings, closings, and "let me check" narration.
- Keep code blocks only when the user needs the exact command or diff.
- Never drop numbers, paths, error messages, or warnings — accuracy is not compressed.
- State what you actually ran vs. what you did not.

## Verification

- Response length drops visibly after enabling.
- No technical facts (numbers, paths, error text) were removed.

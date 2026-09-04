---
name: agy
description: Run prompts, code reviews, refactors, or fast queries using Antigravity CLI directly with Gemini 3.8 Flash (gemini-3.8-flash-high/low) or Gemini 3.1 Pro. Use whenever the user asks to use agy, Gemini 3.8 Flash, or needs Gemini 3.8's cutting-edge capabilities without API license errors.
---

# Antigravity CLI (AGY) Runner

This skill allows OpenCode agents to offload tasks directly to Google's official Antigravity CLI (`agy`), bypassing Code Assist license restrictions to use **Gemini 3.8 Flash** and other native Google models.

## CLI Location
`/Users/tualek/.local/bin/agy` (or shortcut `/Users/tualek/.local/bin/agy-3.8`)

## When to use
- The user requests using `agy` or `gemini 3.8` / `gemini 3.8 flash`.
- You need high-speed, large-context reasoning directly from Gemini 3.8 Flash.
- You need a second opinion from Antigravity's native models.

## Available AGY Models
- `gemini-3.8-flash-high` (Default recommendation for complex tasks / code)
- `gemini-3.8-flash-low` (Fastest, low reasoning latency)
- `gemini-3.1-pro-high` (Frontier reasoning)
- `claude-opus-4-6-thinking` (Claude via Antigravity)

## Execution Patterns

### 1. Simple prompt query
```bash
rtk /Users/tualek/.local/bin/agy -p "Explain how reactive computed works in Nuxt 3" --model gemini-3.8-flash-high
```

### 2. Shortcut command (Gemini 3.8 Flash High)
```bash
rtk /Users/tualek/.local/bin/agy-3.8 "Explain how reactive computed works in Nuxt 3"
```

### 3. File inspection / Code review with Gemini 3.8 Flash
```bash
cat path/to/file.ts | rtk /Users/tualek/.local/bin/agy -p "Review this code for edge cases and performance" --model gemini-3.8-flash-high
```

### 4. Direct task execution with file context
Pass the relative or absolute path in the prompt, or pipe content:
```bash
rtk /Users/tualek/.local/bin/agy -p "Analyze /Users/tualek/ohochat/oho-web-app/package.json and summarize main dependencies" --model gemini-3.8-flash-low
```

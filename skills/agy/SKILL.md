---
name: agy
description: Use when the user requests Antigravity CLI or a model through agy.
---

# Antigravity CLI (AGY) Runner

Use the configured Antigravity runner only when requested and permitted by the current harness. Check CLI availability and supported model IDs before dispatch; examples below are not proof of installed models or authentication. Preserve the active delegation/approval protocol; a failed governed runner does not authorize a CLI fallback.

## CLI Location
`/Users/tualek/.local/bin/agy` (or shortcut `/Users/tualek/.local/bin/agy-3.8`)

## When to use
- The user requests using `agy` or `gemini 3.8` / `gemini 3.8 flash`.
- The user requests a second opinion specifically through Antigravity; generic requests for speed or a second opinion do not select this runner.

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

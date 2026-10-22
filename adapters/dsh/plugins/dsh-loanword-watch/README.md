# @local/dsh-loanword-watch

keeps replies in this session from two things: Thai transliterations of English technical terms (รัน, เคส, การ์ด, …) from the word list in `core/checks/thai-loanwords.json` (56 entries), and any CJK run — Han, hiragana/katakana, Hangul, CJK punctuation, full-width forms — because the model sometimes slips Chinese into Thai replies. the ranges live in the same json under `cjkRanges`, so the plugin and the checker cannot drift. code spans and fences are ignored, and both checks read text blocks only, never reasoning.

two hooks, both on public `dsh-agent` API:

| hook | what it does |
|---|---|
| `agent/pre-step` | appends one short `runtime-context` notice (190 chars) restating the rule to the entering batch. request-only, never persisted, so no transcript growth; the full word list stays in the detector |
| `agent/turn-stopping` | reads the newest `assistant/message`; if it still has loanwords or CJK, calls `agent.steer(...)` once per turn, which keeps the turn open so the reply can be corrected. capped at `maxSteersPerSession` (default 3) |
| `session/event` | appends every hit to `~/.dsh/loanword-hits.jsonl` with `action: hit` plus `loanwords`/`cjk` arrays, for retro counts |

it cannot edit a reply that already reached the user: the harness has no such API. the steer path produces a correction message in the same turn.

config (row inserted from `cordis.patch.yml`):

- `logPath` default `~/.dsh/loanword-hits.jsonl`
- `reminder` / `steer` — set `false` to disable that half
- `maxSteersPerSession` default 3
- `enabled: false` registers nothing

every handler is wrapped: a failure is written to the log and never interrupts the session.

test: `node test.mjs`

# @local/dsh-loanword-watch

keeps replies in this session from two things: Thai transliterations of English technical terms (รัน, เคส, การ์ด, …) from the word list in `core/checks/thai-loanwords.json` (56 entries), and any CJK run — Han, hiragana/katakana, Hangul, CJK punctuation, full-width forms — because the model sometimes slips Chinese into Thai replies. the ranges live in the same json under `cjkRanges`, so the plugin and the checker cannot drift. code spans and fences are ignored, and both checks read text blocks only, never reasoning.

**the message you read is already clean**: the plugin patches `session.append` for the session it sees, so every `assistant/message` is rewritten before it is committed — loanwords swap to their English form from the `map` in the same json, CJK characters are dropped. identity, `source` and `reasoning` blocks are preserved; only `text` blocks change. this needs no model call and no tokens. it is an interception of an internal method, so `sanitize: false` turns it off.

other paths, all on public `dsh-agent` API:

| hook | what it does |
|---|---|
| `agent/pre-step` | with `correct: true` only: if the current turn already broke the rule, appends a correction notice naming the offending steps to that step's batch, so the model fixes it in the very next step; otherwise appends one short `runtime-context` reminder (190 chars). request-only, never persisted, so no transcript growth. a step is reported once, never repeated |
| `agent/turn-stopping` | reads every `assistant/message` of the closing turn (a multi-step turn can violate in an earlier step, so the newest one alone is not enough); if any has loanwords or CJK, calls `agent.steer(...)` once per turn, which keeps the turn open so the reply can be corrected. capped at `maxSteersPerSession` (default 10). opt-in |
| `session/event` | appends every hit to `~/.dsh/loanword-hits.jsonl` with `action: hit` plus `loanwords`/`cjk` arrays, for retro counts. `action: remind` records the mid-turn correction, `action: steer` the turn-close one |

it cannot edit a reply that already reached the user: the harness has no such API. the steer path produces a correction message in the same turn.

config (row inserted from `cordis.patch.yml`):

- `logPath` default `~/.dsh/loanword-hits.jsonl`
- `sanitize` — on by default; the deterministic rewrite above
- `reminder` — on by default (short notice per step, ~150 tokens)
- `correct` — off by default; set `true` for the mid-turn notice
- `steer` — **off by default**. turning it on keeps a violating turn open for one more step, which adds a second assistant message and makes the GUI collapse the whole turn behind a read-more control. the mid-turn correction covers the common case without that cost
- `maxSteersPerSession` default 10
- `enabled: false` registers nothing

every handler is wrapped: a failure is written to the log and never interrupts the session.

test: `node test.mjs`

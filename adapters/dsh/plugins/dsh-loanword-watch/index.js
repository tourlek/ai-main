import { randomUUID } from 'node:crypto'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'

export const name = 'dsh-loanword-watch'

const WORDLIST = new URL('../../../../core/checks/thai-loanwords.json', import.meta.url)
const CODE = /```[\s\S]*?```|`[^`\n]*`/g
const expand = (p) => (p === '~' || p?.startsWith('~/') ? path.join(os.homedir(), p.slice(1)) : p)

export function loadWords(file = WORDLIST) {
  const cfg = JSON.parse(fs.readFileSync(file, 'utf8'))
  const esc = (w) => w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
  const words = new RegExp([...cfg.words].sort((a, b) => b.length - a.length).map(esc).join('|'), 'g')
  const allow = cfg.allow?.length ? new RegExp(cfg.allow.map(esc).join('|'), 'g') : undefined
  // CJK script ranges come from the shared json so the checker and the plugin cannot drift.
  const ranges = cfg.cjkRanges ?? []
  const cjk = ranges.length
    ? new RegExp(`[${ranges.map(([a, b]) => `\\u{${a}}-\\u{${b}}`).join('')}]+`, 'gu')
    : undefined
  return { words, allow, cjk, raw: [...cfg.words] }
}

export function textOf(message) {
  const blocks = message?.content
  if (!Array.isArray(blocks)) return ''
  return blocks.filter((b) => b?.type === 'text').map((b) => b.text ?? '').join('\n')
}

export function hitsIn(text, list) {
  let body = String(text ?? '').replace(CODE, ' ')
  if (list.allow) body = body.replace(list.allow, ' ')
  return body.match(list.words) ?? []
}

// Only text blocks of an assistant/message count: not reasoning, not tool calls.
export function findHits(event, list) {
  if (event?.type !== 'assistant/message') return []
  return hitsIn(textOf(event.data?.message), list)
}

export function cjkIn(text, list) {
  if (list?.cjk === undefined) return []
  return String(text ?? '').replace(CODE, ' ').match(list.cjk) ?? []
}

export function findCjk(event, list) {
  if (event?.type !== 'assistant/message') return []
  return cjkIn(textOf(event.data?.message), list)
}

export function violations(event, list) {
  const loanwords = findHits(event, list)
  const cjk = findCjk(event, list)
  return loanwords.length || cjk.length ? { loanwords, cjk } : undefined
}

// Every assistant message of the closing turn counts: checking only the newest one
// missed violations written in an earlier step of a multi-step turn.
export function turnViolations(session, turn, list) {
  const events = session?.ownEvents?.() ?? session?.snapshotEvents?.() ?? []
  const loanwords = []
  const cjk = []
  const seqs = []
  for (let i = events.length - 1; i >= 0; i -= 1) {
    const event = events[i]
    if (event?.type !== 'assistant/message') continue
    if (turn !== undefined && event.data?.turn !== turn) continue
    const found = violations(event, list)
    if (found === undefined) continue
    loanwords.push(...found.loanwords)
    cjk.push(...found.cjk)
    seqs.unshift(event.seq)
  }
  return loanwords.length || cjk.length ? { loanwords, cjk, seqs } : undefined
}

// A request-only notice: same source shape as first-party runtime context messages.
// Stable id for the per-step reminder so the appended tail stays cache-friendly.
export const REMINDER_ID = 'loanword-watch:reminder'

export function noticeMessage(text, id = randomUUID()) {
  return {
    id,
    role: 'user',
    content: [{ type: 'text', text }],
    source: { kind: 'runtime-context', form: 'notice', summary: 'loanword watch' },
  }
}

// Deliberately short: the full word list lives in the detector, the reminder only states the rule.
export function reminderText() {
  return '[loanword-watch] คำเทคนิคต้องเป็น English เสมอ ห้ามทับศัพท์เป็นไทย (เขียน file, test, case, card, path, deploy ไม่ใช่คำไทย) และห้ามมีอักษร CJK จีน/ญี่ปุ่น/เกาหลีในข้อความตอบ รวมถึง reasoning'
}

// CJK is named by codepoint, never echoed: repeating the character in the steer text
// re-injects it into the transcript and the model tends to copy it back.
export function cjkCodepoints(runs) {
  const points = new Set()
  for (const run of runs) for (const ch of run) points.add(`U+${ch.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')}`)
  return [...points].join(' ')
}

export function correctionText({ loanwords = [], cjk = [] }) {
  const problems = []
  if (loanwords.length) problems.push(`คำทับศัพท์ที่ห้ามใช้: ${[...new Set(loanwords)].join(', ')}`)
  if (cjk.length) problems.push(`มีอักษร CJK ${[...new Set(cjk)].reduce((n, r) => n + [...r].length, 0)} ตัว (${cjkCodepoints(cjk)}) ต้องตัดออกให้หมด`)
  return `[loanword-watch] ข้อความที่เพิ่งส่งมีปัญหา: ${problems.join(' และ ')}. เขียนแก้อีกครั้งเฉพาะเนื้อหาที่ผิด โดยใช้คำ English แทน สั้นที่สุด ไม่ต้องสรุปงานใหม่`
}

export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  const list = loadWords(config.wordlist ? expand(config.wordlist) : WORDLIST)
  const logPath = expand(config.logPath ?? '~/.dsh/loanword-hits.jsonl')
  const remind = config.reminder !== false
  // Off by default: a steer keeps the turn open, which adds another assistant message
  // and collapses the whole turn behind a "read more" affordance in the GUI.
  const steer = config.steer === true
  const correct = config.correct !== false
  const maxSteers = config.maxSteersPerSession ?? 10
  const steers = new WeakMap()
  const steeredTurns = new WeakMap()
  const reported = new WeakMap()

  const log = (row) => {
    try {
      fs.appendFileSync(logPath, JSON.stringify({ time: Date.now(), ...row }) + '\n')
    } catch {} // logging never affects the session
  }
  log({ action: 'loaded', reminder: remind, steer, correct, maxSteers })
  // One liveness row per hook per process: proves a hook fires without logging every turn.
  const seen = new Set()
  const once = (action, extra = {}) => { if (!seen.has(action)) { seen.add(action); log({ action, ...extra }) } }

  // A violation already reported in this turn is not repeated; only fresh messages count.
  const freshViolation = (session, turn) => {
    if (session === undefined || turn === undefined || !correct) return undefined
    const found = turnViolations(session, turn, list)
    if (found === undefined) return undefined
    const seen = reported.get(session) ?? new Map()
    const done = seen.get(turn) ?? new Set()
    const fresh = found.seqs.filter((seq) => !done.has(seq))
    if (fresh.length === 0) return undefined
    for (const seq of fresh) done.add(seq)
    seen.set(turn, done)
    reported.set(session, seen)
    log({ session: session.id, turn, seqs: fresh, ...found, action: 'remind' })
    return found
  }

  // Before every step: a fresh violation becomes a correction notice in that step's batch,
  // otherwise the short rule reminder goes in. Request-only, so nothing reaches the transcript.
  ctx.on('agent/pre-step', async (payload, next) => {
    const decision = await next()
    try {
      // Between steps the claimed batch is empty: the notice still belongs in that request.
      once('pre-step', { batch: decision?.messages?.length ?? -1, step: payload?.step ?? -1 })
      if (decision?.kind !== 'enter') return decision
      if (decision.messages.length === 0 && (payload?.step ?? 1) <= 1) return decision
      const found = freshViolation(payload?.agent?.session, payload?.turn)
      if (found !== undefined) {
        const id = `loanword-watch:fix:${payload.turn}:${found.seqs.join(',')}`
        return { ...decision, messages: [...decision.messages, noticeMessage(correctionText(found), id)] }
      }
      if (remind) {
        return { ...decision, messages: [...decision.messages, noticeMessage(reminderText(), REMINDER_ID)] }
      }
    } catch (error) {
      log({ action: 'error', phase: 'pre-step', error: String(error?.message ?? error) })
    }
    return decision
  })

  // When the turn is about to close with a violating reply, keep it open once so it can be fixed.
  ctx.on('agent/turn-stopping', ({ agent, turn }) => {
    try {
      const session = agent?.session
      if (session === undefined) return
      once('turn-stopping')
      const found = turnViolations(session, turn, list)
      if (found === undefined || !steer) return
      const done = steeredTurns.get(session) ?? new Set()
      const used = steers.get(session) ?? 0
      if (done.has(turn) || used >= maxSteers) return
      done.add(turn)
      steeredTurns.set(session, done)
      steers.set(session, used + 1)
      agent.steer(noticeMessage(correctionText(found)))
      log({ session: session.id, turn, ...found, action: 'steer' })
    } catch (error) {
      log({ action: 'error', phase: 'turn-stopping', error: String(error?.message ?? error) })
    }
  })

  // Durable per-message record for retro counts.
  ctx.on('session/event', (session, event) => {
    try {
      const found = violations(event, list)
      if (found !== undefined) log({ session: session?.id, seq: event.seq, ...found, action: 'hit' })
    } catch {}
  })
}

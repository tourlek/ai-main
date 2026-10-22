import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { apply, cjkCodepoints, correctionText, cjkIn, findCjk, findHits, loadWords, noticeMessage, reminderText, sanitizeEventData, sanitizeText, textOf, turnViolations, violations } from './index.js'

let failed = 0
const check = (label, ok) => { if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} ${label}`) }
const list = loadWords()
const msg = (text, type = 'text') => ({ type: 'assistant/message', seq: 1, time: 1, data: { turn: 1, message: { role: 'assistant', content: [{ type, text }] } } })

check('flags รัน', findHits(msg('ผมรัน test ไม่ได้'), list).join() === 'รัน')
check('flags การ์ด and เคส', findHits(msg('การ์ดนี้มีเคสเดียว'), list).length === 2)
check('English terms pass', findHits(msg('ผม run test ไม่ได้ ดู card'), list).length === 0)
check('inline code ignored', findHits(msg('ใช้ `รัน` ได้'), list).length === 0)
check('code fence ignored', findHits(msg('```\nการ์ด\n```'), list).length === 0)
check('allow list (รันทด)', findHits(msg('เรื่องรันทด'), list).length === 0)
check('reasoning block ignored', findHits(msg('รัน', 'reasoning'), list).length === 0)
check('other event type ignored', findHits({ ...msg('รัน'), type: 'user/message' }, list).length === 0)
check('textOf joins text blocks only', textOf({ content: [{ type: 'text', text: 'a' }, { type: 'reasoning', text: 'b' }] }) === 'a')
check('reminder states the rule without listing every word', reminderText().includes('English') && reminderText().length < 260)
check('correction names loanwords', correctionText({ loanwords: ['เคส', 'การ์ด'] }).includes('เคส'))
check('correction never echoes CJK', !/[\u4e00-\u9fff]/.test(correctionText({ cjk: ['这是中文'] })))
check('correction names CJK by codepoint', correctionText({ cjk: ['生'] }).includes('U+751F'))
check('cjkCodepoints dedupes', cjkCodepoints(['生生']).split(' ').length === 1)
check('reminder covers CJK too', reminderText().includes('CJK'))
check('sanitizeText swaps a loanword', sanitizeText('เปิดไฟล์นี้', list) === 'เปิด file นี้')
check('sanitizeText drops CJK', !/[\u4e00-\u9fff]/.test(sanitizeText('ข้อความ 中 ปน', list)))
check('sanitizeText keeps allowed Thai words', sanitizeText('เรื่องรันทด', list) === 'เรื่องรันทด')
check('sanitizeText prefers the longest key', sanitizeText('เทสต์ผ่าน', list) === 'test ผ่าน')
check('sanitizeText leaves clean text alone', sanitizeText('ผม run test แล้ว', list) === 'ผม run test แล้ว')
check('sanitizeEventData rewrites text blocks only', (() => {
  const data = { turn: 1, step: 1, message: { id: 'm1', role: 'assistant', source: { kind: 'model' }, content: [{ type: 'reasoning', text: 'เคส' }, { type: 'text', text: 'เคส' }] } }
  const out = sanitizeEventData(data, list)
  return out.message.content[0].text === 'เคส' && out.message.content[1].text === 'case' && out.message.id === 'm1' && out.turn === 1
})())
check('sanitizeEventData returns the same object when clean', (() => {
  const data = { message: { content: [{ type: 'text', text: 'all english' }] } }
  return sanitizeEventData(data, list) === data
})())
check('notice is a user message with an id', noticeMessage('x').role === 'user' && typeof noticeMessage('x').id === 'string')

check('detects Chinese ideographs', findCjk(msg('这是中文内容'), list).join('') === '这是中文内容')
check('detects Japanese kana', findCjk(msg('これはテスト'), list).length >= 1)
check('CJK in code is ignored', findCjk(msg('`中文` and ```\n中文\n```'), list).length === 0)
check('CJK in reasoning is ignored', findCjk(msg('中文', 'reasoning'), list).length === 0)
check('violations groups both kinds', (() => {
  const v = violations(msg('เคส 中文'), list)
  return v.loanwords.join() === 'เคส' && v.cjk.join('') === '中文'
})())
check('violations is undefined when clean', violations(msg('all english here'), list) === undefined)
check('cjkIn tolerates non-strings', cjkIn(undefined, list).length === 0)

// A multi-step turn: the violation sits in the first step, the last message is clean.
const turnEvents = [
  { type: 'assistant/message', seq: 3, data: { turn: 7, step: 1, message: { role: 'assistant', content: [{ type: 'text', text: 'ตรวจ เคส นี้' }] } } },
  { type: 'tool/call', seq: 4, data: {} },
  { type: 'assistant/message', seq: 5, data: { turn: 7, step: 2, message: { role: 'assistant', content: [{ type: 'text', text: 'all english here' }] } } },
  { type: 'assistant/message', seq: 6, data: { turn: 8, step: 1, message: { role: 'assistant', content: [{ type: 'text', text: 'ไฟล์ ใน turn อื่น' }] } } },
]
const turnSession = { ownEvents: () => turnEvents }
const seven = turnViolations(turnSession, 7, list)
check('turnViolations sees an earlier step of the same turn', seven !== undefined && seven.loanwords.join() === 'เคส' && seven.seqs.join() === '3')
check('turnViolations ignores other turns', !turnViolations(turnSession, 8, list).loanwords.includes('เคส'))
check('turnViolations aggregates every step', turnViolations(turnSession, undefined, list).loanwords.length === 2)
check('turnViolations is undefined for a clean turn', turnViolations({ ownEvents: () => [turnEvents[2]] }, 7, list) === undefined)

// Wiring: pre-step appends the reminder, turn-stopping steers once per turn.
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'lw-'))
const logPath = path.join(dir, 'hits.jsonl')
const handlers = {}
const ctx = { on: (ev, fn) => { (handlers[ev] ??= []).push(fn) } }
const steered = []
const session = {
  id: 's1',
  ownEvents: () => [
    { type: 'user/message', seq: 1, data: { message: { role: 'user', content: [{ type: 'text', text: 'hi' }] } } },
    ...[1, 2, 3].map((t) => ({ type: 'assistant/message', seq: 1 + t, data: { turn: t, step: 1, message: { role: 'assistant', content: [{ type: 'text', text: 'เสร็จแล้ว เคสนี้' }] } } })),
  ],
}
const agent = { session, steer: (m) => steered.push(m) }
apply(ctx, { logPath, steer: true, correct: true })

const preStep = handlers['agent/pre-step'][0]
const batch = [{ id: 'u1', role: 'user', content: [{ type: 'text', text: 'do it' }] }]
const cleanAgent = { session: { id: 'clean', ownEvents: () => [] }, steer: () => {} }
const out = await preStep({ agent: cleanAgent, messages: batch, turn: 1, step: 1 }, async () => ({ kind: 'enter', messages: batch }))
check('pre-step appends one reminder', out.kind === 'enter' && out.messages.length === 2 && out.messages[0] === batch[0])
check('pre-step keeps the original batch intact', batch.length === 1)
check('reminder carries the notice source', out.messages[1].source.form === 'notice')
const rejected = await preStep({ agent: cleanAgent, messages: batch, turn: 1, step: 1 }, async () => ({ kind: 'reject' }))
check('pre-step leaves a reject untouched', rejected.kind === 'reject')

// Mid-turn correction: the violating step is caught at the next pre-step, once.
const fresh = await preStep({ agent, messages: batch, turn: 1, step: 2 }, async () => ({ kind: 'enter', messages: batch }))
check('pre-step injects a correction for the turn', fresh.messages.length === 2 && fresh.messages[1].content[0].text.includes('loanword-watch'))
check('pre-step correction names the offending step', fresh.messages[1].content[0].text.includes('เคส'))
const again = await preStep({ agent, messages: batch, turn: 1, step: 3 }, async () => ({ kind: 'enter', messages: batch }))
check('pre-step does not repeat the same correction', !again.messages[1].content[0].text.includes('เคส'))
const cleanTurn = await preStep({ agent: { session: { id: 'x', ownEvents: () => [] }, steer: () => {} }, messages: batch, turn: 99, step: 1 }, async () => ({ kind: 'enter', messages: batch }))
check('pre-step falls back to the reminder when clean', cleanTurn.messages.length === 2 && !cleanTurn.messages[1].content[0].text.includes('เคส'))
// Between steps the claimed batch is empty, and the notice must still go in.
const between = await preStep({ agent: cleanAgent, messages: [], turn: 2, step: 2 }, async () => ({ kind: 'enter', messages: [] }))
check('pre-step still injects when the batch is empty', between.messages.length === 1 && between.messages[0].source.form === 'notice')
const firstStep = await preStep({ agent: cleanAgent, messages: [], turn: 2, step: 1 }, async () => ({ kind: 'enter', messages: [] }))
check('pre-step leaves an empty first step alone', firstStep.messages.length === 0)

const stop = handlers['agent/turn-stopping'][0]
stop({ agent, turn: 1 })
check('turn-stopping steers once', steered.length === 1 && steered[0].source.form === 'notice')
stop({ agent, turn: 1 })
check('turn-stopping does not steer twice in one turn', steered.length === 1)
stop({ agent, turn: 2 })
check('turn-stopping steers again on a new turn', steered.length === 2)

handlers['session/event'][0](session, session.ownEvents()[1])
const rows = fs.readFileSync(logPath, 'utf8').trim().split('\n').map((l) => JSON.parse(l))
check('logs hits and steers separately', rows.some((r) => r.action === 'hit') && rows.filter((r) => r.action === 'steer').length === 2)
check('steer row records both kinds', rows.filter((r) => r.action === 'steer').every((r) => Array.isArray(r.loanwords) && Array.isArray(r.cjk)))

const quiet = { id: 's2', ownEvents: () => [{ type: 'assistant/message', seq: 1, data: { turn: 1, step: 1, message: { role: 'assistant', content: [{ type: 'text', text: 'all good' }] } } }] }
const before = steered.length
stop({ agent: { session: quiet, steer: (m) => steered.push(m) }, turn: 1 })
check('clean reply is not steered', steered.length === before)

// A reply with Chinese only still triggers the steer path.
const cjkSteered = []
const cjkSession = { id: 's3', ownEvents: () => [{ type: 'assistant/message', seq: 9, data: { turn: 1, step: 1, message: { role: 'assistant', content: [{ type: 'text', text: '这是中文' }] } } }] }
handlers['agent/turn-stopping'][0]({ agent: { session: cjkSession, steer: (m) => cjkSteered.push(m) }, turn: 1 })
check('CJK-only reply is steered without echoing it', cjkSteered.length === 1 && !/[\u4e00-\u9fff]/.test(cjkSteered[0].content[0].text))

// Caps and opt-outs.
const capped = []
const capHandlers = {}
apply({ on: (ev, fn) => { (capHandlers[ev] ??= []).push(fn) } }, { logPath, steer: true, correct: true, maxSteersPerSession: 1 })
for (const turn of [1, 2, 3]) capHandlers['agent/turn-stopping'][0]({ agent: { session, steer: (m) => capped.push(m) }, turn })
check('session cap limits steers', capped.length === 1)

const off = []
apply({ on: (ev, fn) => off.push([ev, fn]) }, { enabled: false })
check('enabled:false registers nothing', off.length === 0)
const noSteer = []
apply({ on: (ev) => noSteer.push(ev) }, { logPath, steer: false })
check('steer:false still registers both listeners', noSteer.includes('agent/turn-stopping') && noSteer.includes('agent/pre-step'))

// The session patch rewrites a committed assistant message in place.
const committed = []
const patchedSession = { id: 'patched', append: (type, data) => { const e = { seq: committed.length + 1, type, data }; committed.push(e); return e }, ownEvents: () => [] }
const patchCtx = {}
apply({ on: (ev, fn) => { (patchCtx[ev] ??= []).push(fn) } }, { logPath })
await patchCtx['agent/pre-step'][0]({ agent: { session: patchedSession }, messages: batch, turn: 1, step: 1 }, async () => ({ kind: 'enter', messages: batch }))
patchedSession.append('assistant/message', { turn: 1, step: 1, message: { id: 'm9', role: 'assistant', content: [{ type: 'text', text: 'อ่านโค้ด แล้วเจอเคส' }] } })
check('committed message is rewritten before it lands', committed[0].data.message.content[0].text === 'อ่าน code แล้วเจอ case')
check('committed message keeps its identity', committed[0].data.message.id === 'm9')
const sanitizeRow = fs.readFileSync(logPath, 'utf8').trim().split('\n').map((l) => JSON.parse(l)).filter((r) => r.action === 'sanitize').pop()
check('sanitize row records what was replaced', sanitizeRow?.loanwords?.join() === 'โค้ด,เคส' && Array.isArray(sanitizeRow?.cjk))
patchedSession.append('turn/start', { turn: 1 })
check('other event types pass through untouched', committed[1].data.turn === 1)

// Default: no steering, so the plugin never extends a turn by itself.
const defaultHandlers = {}
const defaultSteered = []
apply({ on: (ev, fn) => { (defaultHandlers[ev] ??= []).push(fn) } }, { logPath })
defaultHandlers['agent/turn-stopping'][0]({ agent: { session, steer: (m) => defaultSteered.push(m) }, turn: 1 })
check('steering is opt-in', defaultSteered.length === 0)

fs.rmSync(dir, { recursive: true })
console.log(failed ? `\n${failed} failed` : '\nall passed')
process.exit(failed ? 1 : 0)

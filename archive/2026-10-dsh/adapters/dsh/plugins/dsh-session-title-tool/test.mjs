import fs from 'node:fs'
import { apply, normalizeTitle } from './index.js'

let failed = 0, total = 0
const check = (label, ok, extra = '') => { total++; if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} ${label}${ok ? '' : ' ' + extra}`) }
const rejects = async (fn, re) => { try { await fn(); return false } catch (e) { return re.test(e.message) } }

// Fake ctx: records registered tools and rename calls; rename returns a snapshot like the session-title service.
function fakeCtx() {
  const tools = [], renames = []
  const ctx = {
    tools: { register: (t) => tools.push(t) },
    sessionTitle: { rename: (session, title) => { renames.push({ session, title }); return { title, eventSeq: 7 } } },
  }
  return { ctx, tools, renames }
}

const { ctx, tools, renames } = fakeCtx()
apply(ctx)
const tool = tools[0]
check('registers exactly one tool named set_session_title', tools.length === 1 && tool.name === 'set_session_title')
check('title param is a required string', tool.parameters.properties.title.type === 'string' && tool.parameters.required.includes('title'))
check('description: current session only, clickup-card format, pins, no tokens',
  /CURRENT session/.test(tool.description) && tool.description.includes('OHO-xxxx [<stage>] <card name>') && /pinned/.test(tool.description) && /no tokens/.test(tool.description))
check('output schema + render + presentCall', tool.output.schema.required.join() === 'title,eventSeq' && tool.output.render({}, { title: 'x' })[0].text.includes('"x"')
  && tool.presentCall({ title: 't' }).card === 'generic' && tool.presentCall({ title: 't' }).title === 'Rename session')

const off = fakeCtx()
apply(off.ctx, { enabled: false })
check('enabled:false registers nothing', off.tools.length === 0)

const me = { id: 'session-me' }
const agent = { session: me }
const res = await tool.execute({ title: '  OHO-1234 [Impl] Fix login  ' }, { agent })
check('renames exec.agent.session with trimmed title, returns {title,eventSeq}',
  renames.length === 1 && renames[0].session === me && renames[0].title === 'OHO-1234 [Impl] Fix login'
  && JSON.stringify(res) === JSON.stringify({ title: 'OHO-1234 [Impl] Fix login', eventSeq: 7 }), JSON.stringify({ renames, res }))

renames.length = 0
check('rejects empty', await rejects(() => tool.execute({ title: '' }, { agent }), /empty/))
check('rejects whitespace-only', await rejects(() => tool.execute({ title: ' \n\t ' }, { agent }), /empty/))
check('rejects 121 chars', await rejects(() => tool.execute({ title: 'a'.repeat(121) }, { agent }), /121 characters; max 120/))
check('accepts 120 chars', normalizeTitle('a'.repeat(120)).length === 120)
const thai = 'ก'.repeat(117) + 'ที่' // 120 code points, 360 UTF-8 bytes
check('accepts 120-char Thai string', [...thai].length === 120 && normalizeTitle(thai) === thai)
check('rejects 121-char Thai string', await rejects(() => normalizeTitle(thai + 'ก'), /121 characters/))
check('rejects non-string', await rejects(() => tool.execute({ title: 42 }, { agent }), /must be a string/)
  && await rejects(() => tool.execute({}, { agent }), /must be a string/))
check('rejects missing exec.agent', await rejects(() => tool.execute({ title: 'x' }, {}), /owning agent session/))
check('no rename on any rejection', renames.length === 0, JSON.stringify(renames))

await tool.execute({ title: 'mine', session_id: 'other', session: { id: 'other' } }, { agent })
check('ignores extra session_id arg, renames caller session', renames.length === 1 && renames[0].session === me)

const pkg = JSON.parse(fs.readFileSync(new URL('./package.json', import.meta.url), 'utf8'))
check('package.json has no dependencies/peerDependencies', !pkg.dependencies && !pkg.peerDependencies && pkg.name === '@local/dsh-session-title-tool')
const patch = fs.readFileSync(new URL(pkg.dsh.bundle.patch, import.meta.url), 'utf8')
check('bundle patch inserts the row', /^- insert:\n {4}- id: session-title-tool\n {6}name: '@local\/dsh-session-title-tool'\n?$/.test(patch), patch)

console.log(`\n${total - failed}/${total} passed`)
process.exit(failed ? 1 : 0)

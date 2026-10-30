import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { apply, buildRulesText } from './index.js'

let failed = 0, total = 0
const check = (label, ok, extra = '') => { total++; if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} ${label}${ok ? '' : ' ' + extra}`) }

// Fixture ai-main: global RULES, a shared import, one repo with its own rules.
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ai-main-rules-'))
const w = (f, s) => { fs.mkdirSync(path.dirname(path.join(root, f)), { recursive: true }); fs.writeFileSync(path.join(root, f), s) }
const ws = path.join(root, 'ws')
w('memory/lessons/RULES.md', '# Rules\n\nheader prose\n\n- [*] When G, do g {{not_a_var}} (hits:1)\n\nfooter\n')
w('config/workspaces.json', JSON.stringify({ workspaces: [{ path: ws, knowledge: 'root' }, { path: `${ws}/api`, knowledge: 'api' }] }))
w('knowledge/_shared.md', '# Shared\n\n## Rules earned\n\n- [*] When S, do s (hits:2)\n')
w('knowledge/api.md', '# api\n\n@{{AI_MAIN}}/knowledge/_shared.md\n\n## Notes\n\n- [*] not a rule here\n\n## Rules earned\n\n- [*] When A, do a (hits:1)\n')
w('knowledge/root.md', '# root\n\n## Rules earned\n')

const inRepo = buildRulesText(`${ws}/api/.claude-worktrees/x`, { aiMain: root })
check('worktree under repo gets global + shared + repo rules', ['When G', 'When S', 'When A'].every((s) => inRepo.includes(s)) && !inRepo.includes('not a rule'), inRepo)
check('{{ kept literal', inRepo.includes('{{not_a_var}}'))
check('workspace root picks its own knowledge, not the child', buildRulesText(ws, { aiMain: root }) === '# Rules earned (ai-main, root)\n- [*] When G, do g {{not_a_var}} (hits:1)')
check('most specific first', inRepo.indexOf('When A') < inRepo.indexOf('When S') && inRepo.indexOf('When S') < inRepo.indexOf('When G'))
w('elsewhere/wt/.git', `gitdir: ${ws}/api/.git/worktrees/wt\n`)
check('worktree outside the repo resolves to its main checkout', buildRulesText(path.join(root, 'elsewhere/wt/src'), { aiMain: root }).includes('When A'))
check('outside any workspace: global only', !buildRulesText('/tmp', { aiMain: root }).includes('When S'))
check('missing ai-main: empty, no throw', buildRulesText('/tmp', { aiMain: '/nonexistent' }) === '')

w('memory/lessons/RULES.md', Array.from({ length: 40 }, (_, i) => `- [*] เมื่อแก้ไฟล์ที่ ${i} ให้ตรวจสอบ branch และ worktree ก่อนทุกครั้ง`).join('\n'))
const thai = buildRulesText('/tmp', { aiMain: root, maxBytes: 600 })
check('Thai text capped by bytes on whole lines', Buffer.byteLength(thai) <= 600 && !thai.includes('�') && thai.endsWith('\n…'), `${Buffer.byteLength(thai)}B`)

// Mocked ctx: one registration, text resolved per assembly from the session's working directory.
const sections = []
const ctx = { systemPrompt: { section: (s) => sections.push(s) }, get: (n) => (n === 'workingDirectory' ? { get: (s) => s.cwd } : undefined) }
apply(ctx, { aiMain: root, maxBytes: 2048 })
w('memory/lessons/RULES.md', '- [*] When G2, do g2\n')
const s = sections[0]
check('registers one section, interpolate:false', sections.length === 1 && s.name === 'ai-main-rules' && s.interpolate === false && typeof s.text === 'function')
check('text follows session cwd and re-reads files', s.text({ agent: { session: { cwd: `${ws}/api` } } }).includes('When G2') && s.text({ agent: { session: { cwd: `${ws}/api` } } }).includes('When A'))
check('no agent: falls back to process cwd without throwing', typeof s.text({}) === 'string')

const off = []
apply({ systemPrompt: { section: (x) => off.push(x) } }, { enabled: false })
check('enabled:false registers nothing', off.length === 0)

// Smoke against the real repo: an oho-api worktree gets the .ts rule and stays under 2 KB.
const aiMain = fileURLToPath(new URL('../../../../', import.meta.url))
const real = buildRulesText(path.join(os.homedir(), 'ohochat/oho-api/.claude-worktrees/x'), { aiMain })
check('real ai-main: oho-api rules present, <= 2048 B', real.includes('`.ts`') && real.includes('gitlab-mr-description') && Buffer.byteLength(real) <= 2048, `${Buffer.byteLength(real)}B`)

fs.rmSync(root, { recursive: true, force: true })
console.log(`\n${total - failed}/${total} passed`)
process.exit(failed ? 1 : 0)

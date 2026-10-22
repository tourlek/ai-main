import { fileURLToPath } from 'node:url'
import { apply, buildPayload, runGuard } from './index.js'

// The ai-main guard itself, so the test checks the repo copy, not whatever is installed.
const real = fileURLToPath(new URL('../../../../core/hooks/guard.sh', import.meta.url))
const missing = '/nonexistent/guard.sh'
const signal = new AbortController().signal
let failed = 0

async function decide(config, exec) {
  const handlers = []
  apply({ on: (ev, fn) => handlers.push([ev, fn]), get: () => undefined }, config)
  const h = handlers.find(([ev]) => ev === 'tools/pre-execute')[1]
  return h({ signal, ...exec }, async () => ({ kind: 'allow' }))
}
const bash = (command) => ({ name: 'bash', arguments: { description: 't', command, workdir: '/tmp' } })

// [label, exec, guardPath, expected kind, expected raw guard output: 'deny' | 'silent' | null (skip raw check)]
const cases = [
  ['git push origin master', bash('git push origin master'), real, 'deny', 'deny'],
  ['cd x && git push origin main', bash('cd x && git push origin main'), real, 'deny', 'deny'],
  ['git commit -m x', bash('git commit -m x'), real, 'ask', 'deny'],
  ['git status', bash('git status'), real, 'allow', 'silent'],
  ['git reset --hard (ported rule)', bash('git reset --hard HEAD~1'), real, 'deny', 'deny'],
  ['git push --force (ported rule)', bash('git push --force origin feat/x'), real, 'deny', 'deny'],
  ['git worktree add ../w feature', bash('git worktree add ../w feature'), real, 'ask', 'deny'],
  ['create_worktree from d6af4bde', { name: 'create_worktree', arguments: { from: 'd6af4bde' } }, real, 'ask', 'deny'],
  ['create_worktree name smuggles origin/master', { name: 'create_worktree', arguments: { from: 'd6af4bde', name: 'origin/master-x' } }, real, 'ask', 'deny'],
  ['create_worktree from origin/master', { name: 'create_worktree', arguments: { from: 'origin/master', name: 'x' } }, real, 'allow', 'silent'],
  ['missing guard + git push feat/x', bash('git push origin feat/x'), missing, 'deny', null],
  ['missing guard + ls', bash('ls'), missing, 'allow', null],
  ['tool read (no spawn)', { name: 'read', arguments: { path: '/tmp/x' } }, missing, 'allow', null],
  ['clickup_create_task', { name: 'clickup_create_task', arguments: { name: 'x' } }, real, 'ask', 'deny'],
  ['graphify CLI raw (must use wrapper)', bash('graphify update .'), real, 'ask', 'deny'],
  ['graphify CLI via wrapper', bash('~/ai-main/bin/gfy update .'), real, 'allow', 'silent'],
  ['rg mentions graphify', bash('rg -n graphify README.md'), real, 'allow', 'silent'],
  ['mcp graphify read tool (ungated)', { name: 'mcp__graphify__query_graph', arguments: { question: 'x' } }, real, 'allow', 'silent'],
  ['mcp graphify network tool', { name: 'mcp__graphify__list_prs', arguments: {} }, real, 'ask', 'deny'],
]

for (const [label, exec, guardPath, want, raw] of cases) {
  const problems = []
  if (raw) {
    const payload = buildPayload(exec, '/tmp')
    const { stdout, error } = await runGuard(payload, { guardPath })
    const got = error ? `error:${error}` : stdout.includes('"permissionDecision":"deny"') ? 'deny' : stdout.trim() ? 'other' : 'silent'
    if (got !== raw) problems.push(`raw guard ${got} != ${raw}`)
  }
  const d = await decide({ guardPath }, exec)
  if (d.kind !== want) problems.push(`kind ${d.kind} != ${want}`)
  if (want === 'ask' && !d.displayReason?.en) problems.push('ask without displayReason')
  const ok = !problems.length
  if (!ok) failed++
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label} -> ${d.kind}${d.reason ? ' ' + d.reason : ''}${ok ? '' : ' [' + problems.join('; ') + ']'}`)
}

const off = []
apply({ on: (...a) => off.push(a), get: () => undefined }, { enabled: false })
const ok = off.length === 0
if (!ok) failed++
console.log(`${ok ? 'PASS' : 'FAIL'} enabled:false registers nothing`)

console.log(`\n${cases.length + 1 - failed}/${cases.length + 1} passed`)
process.exit(failed ? 1 : 0)

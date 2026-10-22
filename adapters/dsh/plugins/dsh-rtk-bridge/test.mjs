#!/usr/bin/env node
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { apply, buildPayload, parseRewrite, rewriteCommand, rtkEnv } from './index.js'

let failed = 0, total = 0
const check = (label, ok, extra = '') => { total++; if (!ok) failed++; console.log(`${ok ? 'PASS' : 'FAIL'} ${label}${ok ? '' : ' ' + extra}`) }

// A stand-in for `rtk hook claude` so the mechanics are testable without the real binary.
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'dsh-rtk-bridge-'))
const fake = path.join(dir, 'rtk')
fs.writeFileSync(fake, `#!/bin/sh
input=$(cat)
case "$input" in
  *git\\ status*) printf '%s\\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","updatedInput":{"command":"rtk git status"}}}' ;;
  *already*) printf '%s\\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","updatedInput":{"command":"rtk already"}}}' ;;
  *badjson*) printf '%s\\n' 'not json' ;;
esac
`)
fs.chmodSync(fake, 0o755)
const failing = path.join(dir, 'rtk-fails')
fs.writeFileSync(failing, '#!/bin/sh\nexit 3\n')
fs.chmodSync(failing, 0o755)

check('payload matches the claude hook shape', JSON.stringify(buildPayload('git status', '/tmp')) === '{"tool_name":"Bash","tool_input":{"command":"git status"},"cwd":"/tmp","hook_event_name":"PreToolUse"}')
check('rtkEnv appends brew paths', rtkEnv({ PATH: '/usr/bin' }).PATH.startsWith('/usr/bin:') && rtkEnv({ PATH: '/usr/bin' }).PATH.includes('/opt/homebrew/bin'))

check('silent hook output means no rewrite', parseRewrite('') === undefined && parseRewrite('\n') === undefined)
check('deny-only hook output means no rewrite', parseRewrite('{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"x"}}') === undefined)
check('updatedInput is the rewrite', parseRewrite('{"hookSpecificOutput":{"updatedInput":{"command":"rtk ls -la"}}}') === 'rtk ls -la')
check('unparseable output means no rewrite', parseRewrite('not json') === undefined)

check('rewrite via the fake hook', (await rewriteCommand('git status', { rtkPath: fake, cwd: dir })) === 'rtk git status')
check('no rewrite when the hook is silent', (await rewriteCommand('echo hi', { rtkPath: fake, cwd: dir })) === undefined)
check('no rewrite when the hook prints garbage', (await rewriteCommand('badjson', { rtkPath: fake, cwd: dir })) === undefined)
check('no rewrite when rtk fails', (await rewriteCommand('git status', { rtkPath: failing, cwd: dir })) === undefined)
check('no rewrite when rtk is missing', (await rewriteCommand('git status', { rtkPath: path.join(dir, 'nope'), cwd: dir })) === undefined)
check('no rewrite when the workdir is gone', (await rewriteCommand('git status', { rtkPath: fake, cwd: path.join(dir, 'gone') })) === undefined)

// A shell service stub: execute() echoes the spec it was handed, like bash-local would spawn it.
const mkCtx = () => {
  let dispose
  const ctx = {
    shell: { execute: async (spec) => spec },
    effect: (fn) => { dispose = fn(); return dispose },
  }
  return { ctx, dispose: () => dispose?.() }
}

{
  const { ctx } = mkCtx()
  apply(ctx, { rtkPath: fake })
  const spec = { command: 'git status', workdir: dir }
  const out = await ctx.shell.execute(spec)
  check('execute receives the rewritten command', out.command === 'rtk git status', out.command)
  check('the rest of the spec is preserved', out.workdir === dir)
  check('the caller spec is not mutated', spec.command === 'git status')
  const plain = await ctx.shell.execute({ command: 'echo hi', workdir: dir })
  check('unmatched commands pass through', plain.command === 'echo hi')
}

{
  const { ctx } = mkCtx()
  const original = ctx.shell.execute
  apply(ctx, { rtkPath: fake })
  apply(ctx, { rtkPath: fake })
  check('idempotent: a second apply leaves one wrapper', (await ctx.shell.execute({ command: 'echo hi', workdir: dir })).command === 'echo hi' && ctx.shell.execute !== original)
}

{
  const { ctx, dispose } = mkCtx()
  const original = ctx.shell.execute
  apply(ctx, { rtkPath: fake })
  dispose()
  check('dispose restores the original execute', ctx.shell.execute === original)
  apply(ctx, { rtkPath: fake })
  check('a later apply can wrap again', ctx.shell.execute !== original)
}

{
  const { ctx } = mkCtx()
  const original = ctx.shell.execute
  apply(ctx, { enabled: false })
  check('enabled:false wraps nothing', ctx.shell.execute === original)
}

{
  const ctx = { effect: () => {} }
  apply(ctx, { rtkPath: fake })
  check('a profile without the shell service stays inert', true)
}

// Real rtk, when installed: the same three facts Claude Code relies on.
const rtkPath = 'rtk'
const hasRtk = await rewriteCommand('git status', { rtkPath, cwd: dir }).then((c) => c === 'rtk git status').catch(() => false)
if (hasRtk) {
  check('real rtk rewrites a bare command', (await rewriteCommand('git status', { rtkPath, cwd: dir })) === 'rtk git status')
  check('real rtk leaves an already-prefixed command alone', (await rewriteCommand('rtk git status', { rtkPath, cwd: dir })) === undefined)
  check('real rtk leaves a non-rewritable command alone', (await rewriteCommand('echo hi', { rtkPath, cwd: dir })) === undefined)
} else {
  console.log('SKIP real rtk checks (rtk not on PATH)')
}

console.log(`\n${total - failed}/${total} passed`)
process.exit(failed ? 1 : 0)

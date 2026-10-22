import { execFile } from 'node:child_process'
import os from 'node:os'
import path from 'node:path'

export const name = 'dsh-guard-bridge'

const HARD = /never allowed/
// No transcript under DSH, so the guard never sees the user's 'allow-worktree' word: ask instead.
const GATED = /needs the user's explicit|needs a preview|must branch from origin\/master/
const CRITICAL = /\bgit\b[^\n]*\b(push|commit)\b|\bglab\s+mr\b/
const NEXT = { kind: 'next' }

const expand = (p) => (p === '~' || p?.startsWith('~/') ? path.join(os.homedir(), p.slice(1)) : p)

// Mirrors dsh-tool-bash: undefined -> session cwd, relative -> under cwd, absolute -> as is.
export function resolveWorkdir(workdir, cwd) {
  if (!workdir) return cwd
  return path.isAbsolute(workdir) ? workdir : path.join(cwd, workdir)
}

export function buildPayload(exec, cwd) {
  const isBash = exec.name === 'bash' && typeof exec.arguments?.command === 'string'
  if (isBash) {
    const dir = resolveWorkdir(exec.arguments.workdir, cwd)
    return { tool_name: 'Bash', tool_input: { command: exec.arguments.command }, cwd: dir, hook_event_name: 'PreToolUse' }
  }
  if (exec.name === 'create_worktree') {
    // DSH tool; checked as the equivalent git command so the guard's worktree-base rule applies.
    // Only an exact origin/master base passes; name is left out so it cannot smuggle the substring in.
    const base = exec.arguments?.from === 'origin/master' ? 'origin/master' : 'non-master-base'
    return { tool_name: 'Bash', tool_input: { command: `git worktree add wt ${base}` }, cwd, hook_event_name: 'PreToolUse' }
  }
  if (exec.name?.startsWith('clickup_') || exec.name?.includes('__clickup_') || exec.name?.startsWith('mcp__graphify__')) {
    return { tool_name: exec.name, tool_input: exec.arguments, cwd, hook_event_name: 'PreToolUse' }
  }
  return null
}

export function runGuard(payload, { guardPath, timeoutMs = 5000 }) {
  const env = { ...process.env, PATH: [process.env.PATH, '/opt/homebrew/bin', '/usr/local/bin', '/usr/bin', '/bin'].filter(Boolean).join(':') }
  return new Promise((resolve) => {
    const child = execFile('/bin/bash', [guardPath], { timeout: timeoutMs, env }, (err, stdout) => {
      resolve({ stdout: String(stdout ?? ''), error: err ? (err.killed ? 'timeout' : `exit ${err.code ?? err.message}`) : undefined })
    })
    child.stdin.on('error', () => {}) // EPIPE when the guard exits before reading
    child.stdin.end(JSON.stringify(payload))
  })
}

export function mapGuardResult({ stdout, error, command = '', toolName }) {
  let out
  if (!error && stdout.trim()) {
    try { out = JSON.parse(stdout.trim().split('\n').pop()).hookSpecificOutput } catch { error = 'unparseable output' }
  }
  if (error) {
    if (/^bash$/i.test(toolName) && CRITICAL.test(command)) {
      return { kind: 'deny', reason: `guard-bridge: guard.sh unavailable (${error}); failing closed for git push/commit/glab mr` }
    }
    return NEXT
  }
  if (!out) return NEXT
  const reason = out.permissionDecisionReason ?? ''
  switch (out.permissionDecision) {
    case 'allow': return NEXT
    case 'ask': return { kind: 'ask', reason, displayReason: { en: reason } }
    case 'deny':
      if (HARD.test(reason)) return { kind: 'deny', reason }
      if (GATED.test(reason)) return { kind: 'ask', reason, displayReason: { en: reason } }
      return { kind: 'deny', reason }
    default: return NEXT
  }
}

export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  const guardPath = expand(config.guardPath ?? '~/.claude/hooks/guard.sh')
  const timeoutMs = config.timeoutMs ?? 5000
  ctx.on('tools/pre-execute', async (exec, next) => {
    let cwd = process.cwd()
    const bash = exec.name === 'bash' && typeof exec.arguments?.command === 'string'
    const clickup = exec.name?.startsWith('clickup_') || exec.name?.includes('__clickup_')
    const graphify = exec.name?.startsWith('mcp__graphify__')
    const worktree = exec.name === 'create_worktree'
    if (!bash && !clickup && !graphify && !worktree) return next()
    try {
      const wd = ctx.get('workingDirectory')
      if (wd && exec.agent) cwd = (await wd.ensure(exec.agent, exec.signal)) || cwd
    } catch {}
    const payload = buildPayload(exec, cwd)
    const res = await runGuard(payload, { guardPath, timeoutMs })
    const d = mapGuardResult({ ...res, command: bash ? exec.arguments.command : '', toolName: exec.name })
    return d.kind === 'next' ? next() : d
  })
}

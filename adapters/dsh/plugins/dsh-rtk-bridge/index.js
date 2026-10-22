import { execFile } from 'node:child_process'
import os from 'node:os'
import path from 'node:path'

export const name = 'dsh-rtk-bridge'
export const inject = ['shell']

const WRAPPED = Symbol.for('@local/dsh-rtk-bridge.wrapped')
const expand = (p) => (p === '~' || p?.startsWith('~/') ? path.join(os.homedir(), p.slice(1)) : p)
const PATH_FALLBACK = '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'

// Same env treatment as dsh-guard-bridge: the Harness process may not inherit the login PATH.
export function rtkEnv(env = process.env) {
  return { ...env, PATH: [env.PATH, ...PATH_FALLBACK.split(':')].filter(Boolean).join(':') }
}

// Mirrors what Claude Code sends to `rtk hook claude`; the hook keys its rewrite off command + cwd.
export function buildPayload(command, cwd) {
  return { tool_name: 'Bash', tool_input: { command }, cwd, hook_event_name: 'PreToolUse' }
}

// The hook prints one JSON line only when it rewrites; silence means "run the command as written".
export function parseRewrite(stdout) {
  const line = String(stdout ?? '').trim().split('\n').pop()
  if (!line) return undefined
  let out
  try { out = JSON.parse(line) } catch { return undefined }
  const command = out?.hookSpecificOutput?.updatedInput?.command
  return typeof command === 'string' && command.trim() ? command : undefined
}

// Resolve the rewrite for one command. Any failure (missing rtk, timeout, unparseable output)
// resolves `undefined`, so the caller runs the command unchanged: rewriting is an optimisation,
// never policy — dsh-guard-bridge owns denial.
export function rewriteCommand(command, { rtkPath = 'rtk', cwd, timeoutMs = 1500, env } = {}) {
  return new Promise((resolve) => {
    let child
    try {
      child = execFile(rtkPath, ['hook', 'claude'], { cwd, timeout: timeoutMs, env: rtkEnv(env), maxBuffer: 1 << 20 }, (err, stdout) => {
        resolve(err ? undefined : parseRewrite(stdout))
      })
    } catch {
      resolve(undefined)
      return
    }
    child.stdin.on('error', () => {}) // EPIPE when rtk exits before reading
    child.stdin.end(JSON.stringify(buildPayload(command, cwd)))
  })
}

/**
 * Wrap the `shell` service so every resolved spec is rewritten by the same engine Claude Code
 * uses, then spawned. `tools/pre-execute` cannot do this: the registry hands listeners
 * `deepFreeze`d arguments and only allows allow/deny/ask, while `execute(spec)` is the point
 * where the command string becomes argv.
 */
export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  const shell = ctx.shell
  if (shell === undefined || typeof shell.execute !== 'function') return
  if (shell[WRAPPED] === true) return
  const original = shell.execute
  const settings = { rtkPath: expand(config.rtkPath ?? 'rtk'), timeoutMs: config.timeoutMs ?? 1500 }

  async function execute(spec, ...rest) {
    let resolved = spec
    try {
      if (spec && typeof spec.command === 'string' && spec.command.trim()) {
        const cwd = spec.workdir ?? process.cwd()
        const command = await rewriteCommand(spec.command, { ...settings, cwd })
        if (command !== undefined && command !== spec.command) resolved = { ...spec, command }
      }
    } catch {}
    return original.call(this, resolved, ...rest)
  }

  shell.execute = execute
  Object.defineProperty(shell, WRAPPED, { value: true, configurable: true })

  const restore = () => {
    if (shell.execute === execute) shell.execute = original
    delete shell[WRAPPED]
  }
  if (typeof ctx.effect === 'function') ctx.effect(() => restore)
  return restore
}

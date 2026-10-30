import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'

export const name = 'dsh-ai-main-rules'
export const inject = ['systemPrompt']

const expand = (p) => (p === '~' || p?.startsWith('~/') ? path.join(os.homedir(), p.slice(1)) : p)
const read = (f) => { try { return fs.readFileSync(f, 'utf8') } catch { return '' } }
const ruleLines = (text) => text.split('\n').filter((l) => l.startsWith('- [*] '))
const section = (text, heading) => (text.split(`\n${heading}\n`)[1] ?? '').split(/\n## /)[0]

// Orca/OMP (retired 2026-10): see archive/2026-10-orca-omp/adapters/dsh/plugins/dsh-ai-main-rules/index.js
// Linked worktree (any location, e.g. ~/ohochat/oho-api-worktrees/…) → its main checkout, via `.git` file `gitdir: <main>/.git/worktrees/<n>`.
export function mainRepoFor(cwd) {
  for (let d = cwd; d && d !== path.dirname(d); d = path.dirname(d)) {
    const g = path.join(d, '.git')
    let st
    try { st = fs.statSync(g) } catch { continue }
    if (!st.isFile()) return cwd
    const m = read(g).match(/^gitdir:\s*(.+?)\/\.git\/worktrees\/[^/\s]+\s*$/m)
    return m ? path.resolve(d, m[1]) : cwd
  }
  return cwd
}

// knowledge/<name>.md for the deepest registered workspace containing cwd (or its worktree's main checkout).
export function knowledgeFor(cwd, aiMain) {
  let ws = []
  try { ws = JSON.parse(read(path.join(aiMain, 'config/workspaces.json'))).workspaces ?? [] } catch {}
  if (cwd) cwd = mainRepoFor(cwd)
  const hit = ws
    .map((w) => ({ ...w, path: w.path.replace('{{HOME}}', os.homedir()) }))
    .filter((w) => cwd === w.path || cwd?.startsWith(w.path + path.sep))
    .sort((a, b) => b.path.length - a.path.length)[0]
  return hit?.knowledge
}

export function buildRulesText(cwd, { aiMain, maxBytes = 2048 }) {
  // Most specific first: repo, then its imports (shared), then global RULES; the cap drops from the end.
  const lines = []
  const k = knowledgeFor(cwd, aiMain)
  if (k) {
    const doc = read(path.join(aiMain, 'knowledge', `${k}.md`))
    const imports = [...doc.matchAll(/^@\{\{AI_MAIN\}\}\/(knowledge\/[^\s]+\.md)$/gm)].map((m) => read(path.join(aiMain, m[1])))
    for (const d of [doc, ...imports]) lines.push(...ruleLines(section(d, '## Rules earned')))
  }
  lines.push(...ruleLines(read(path.join(aiMain, 'build/full/RULES.md')) || read(path.join(aiMain, 'memory/lessons/RULES.md'))))
  if (!lines.length) return ''
  let out = `# Rules earned (ai-main${k ? `, ${k}` : ''})`
  for (const l of lines) {
    if (Buffer.byteLength(`${out}\n${l}\n…`) > maxBytes) return `${out}\n…` // whole lines only, so UTF-8 never splits
    out += `\n${l}`
  }
  return out
}

export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  const aiMain = expand(config.aiMain ?? '~/ai-main')
  const opts = { aiMain, maxBytes: config.maxBytes ?? 2048 }
  // Registered once (a duplicate name throws); the text function runs on every prompt assembly.
  ctx.systemPrompt.section({
    name: 'ai-main-rules',
    order: config.order ?? 100,
    interpolate: false,
    text: (context) => {
      const session = context?.agent?.session
      let cwd = process.cwd()
      try { cwd = (session && ctx.get('workingDirectory')?.get(session)) || cwd } catch {}
      return buildRulesText(cwd, opts)
    },
  })
}

// Imports nothing on purpose: an @deepseek-ai/* dependency installs a second copy into the profile,
// splits module identity for symbol-keyed tool runtime surfaces and breaks every tool call.
export const name = 'dsh-session-title-tool'
export const inject = ['tools', 'sessionTitle']

export const MAX_TITLE = 120

const DESCRIPTION =
  'Set the title of the CURRENT session only (never another session). The clickup-card skill uses it as ' +
  '`OHO-xxxx [<stage>] <card name>`. The title is pinned, so automatic titling stops. Costs no tokens.'

const PARAMETERS = {
  type: 'object',
  properties: {
    title: { type: 'string', description: `New session title, trimmed, 1-${MAX_TITLE} characters.` },
  },
  required: ['title'],
}

const OUTPUT_SCHEMA = {
  type: 'object',
  properties: {
    title: { type: 'string', description: 'The accepted title.' },
    eventSeq: { type: 'integer', description: 'Sequence of the appended session/title event.' },
  },
  required: ['title', 'eventSeq'],
}

export function normalizeTitle(title) {
  if (typeof title !== 'string') throw new Error('set_session_title: `title` must be a string')
  const t = title.trim()
  if (!t) throw new Error('set_session_title: `title` is empty')
  const n = [...t].length // code points, so Thai/emoji count per character
  if (n > MAX_TITLE) throw new Error(`set_session_title: title is ${n} characters; max ${MAX_TITLE}`)
  return t
}

export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  ctx.tools.register({
    name: 'set_session_title',
    description: DESCRIPTION,
    parameters: PARAMETERS,
    output: {
      schema: OUTPUT_SCHEMA,
      render: (_args, value) => [{ type: 'text', text: `Session title set to "${value.title}".` }],
    },
    // register() does not validate against the schema, so args are checked here. Only the caller's session is renamed.
    async execute(args, exec) {
      if (!exec?.agent) throw new Error('set_session_title requires an owning agent session')
      const title = normalizeTitle(args?.title)
      const snapshot = await ctx.sessionTitle.rename(exec.agent.session, title)
      return { title: snapshot.title, eventSeq: snapshot.eventSeq }
    },
    presentCall: (args) => ({ card: 'generic', title: 'Rename session', kind: 'other', rawInput: args?.title }),
  })
}

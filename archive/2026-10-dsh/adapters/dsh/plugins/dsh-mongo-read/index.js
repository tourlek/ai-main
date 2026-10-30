// Read-only MongoDB access for DSH agents.
//
// Secrets never enter this process: bwsr injects the URI into the mongosh child's environment, and the
// child reads it from `process.env[MONGO_URI_*]`. The query travels in a temp JSON file (EJSON.parse in
// the child), so no filter/pipeline value ever appears on a command line. Every message we return or
// throw is redacted, because driver errors can echo a connection string.
import { spawn } from 'node:child_process'
import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'

export const name = 'dsh-mongo-read'
export const inject = ['tools']

export const OPS = Object.freeze(['find', 'countDocuments', 'aggregate'])
export const WRITE_STAGES = Object.freeze(['$out', '$merge'])
export const ENV_VARS = Object.freeze({
  staging: 'MONGO_URI_STAGING',
  uat: 'MONGO_URI_UAT',
  prod: 'MONGO_URI_PROD',
})
export const DEFAULTS = Object.freeze({
  limit: 20,
  maxLimit: 200,
  maxTimeMS: 5000,
  maxMaxTimeMS: 15000,
  connectTimeoutMS: 8000,
  timeoutMs: 30000,
  maxBuffer: 8 * 1024 * 1024,
  maxOutputBytes: 24576,
  maxStderrBytes: 4096,
})
export const RESULT_MARK = 'DSH_MONGO_READ_RESULT '
export const ERROR_MARK = 'DSH_MONGO_READ_ERROR '

// The temp dir name comes from mkdtemp; this is a belt so it can never carry shell syntax.
const SAFE_PATH = /^[A-Za-z0-9/._-]+$/

const DESCRIPTION = [
  'Read-only MongoDB query against the OHO clusters.',
  'ops: find, countDocuments, aggregate — writes are rejected, and $out/$merge is rejected at any depth of the pipeline.',
  'env: staging | uat (no approval) | prod (an approval card is requested on every prod call).',
  'limit is capped at 200 documents (default 20) and maxTimeMS at 15000 (default 5000); output is capped and marked `truncated`.',
  'Filters/pipelines accept Extended JSON, e.g. {"_id": {"$oid": "..."}}.',
].join(' ')

const PARAMETERS = {
  type: 'object',
  properties: {
    env: { type: 'string', enum: ['staging', 'uat', 'prod'], description: 'Target environment. prod always asks for approval first.' },
    db: { type: 'string', description: 'Database name, e.g. oho.' },
    collection: { type: 'string', description: 'Collection name, e.g. users.' },
    op: { type: 'string', enum: [...OPS], description: 'Read operation. Anything else is rejected.' },
    filter: { type: 'object', description: 'Query filter for find/countDocuments. Defaults to {}. Extended JSON allowed.' },
    pipeline: {
      type: 'array',
      items: { type: 'object', additionalProperties: true },
      description: 'Aggregation pipeline for aggregate (JSON array of stage objects). $out/$merge rejected at any depth.',
    },
    projection: { type: 'object', description: 'find only: projection document.' },
    sort: { type: 'object', description: 'find only: sort document.' },
    limit: { type: 'integer', description: 'Maximum documents, 1-200 (default 20). Larger values are clamped to the cap.' },
    maxTimeMS: { type: 'integer', description: 'Server-side limit in ms, 1-15000 (default 5000). Larger values are clamped.' },
  },
  required: ['env', 'db', 'collection', 'op'],
  additionalProperties: false,
}

const OUTPUT_SCHEMA = {
  type: 'object',
  properties: {
    env: { type: 'string' },
    db: { type: 'string' },
    collection: { type: 'string' },
    op: { type: 'string' },
    limit: { type: 'integer' },
    maxTimeMS: { type: 'integer' },
    count: { type: 'integer', description: 'countDocuments result.' },
    docs: { type: 'array', items: { type: 'object', additionalProperties: true }, description: 'Returned documents (find/aggregate).' },
    bytes: { type: 'integer' },
    truncated: { type: 'boolean', description: 'True when the byte cap dropped documents or text.' },
    dropped: { type: 'integer', description: 'Documents dropped to stay under the byte cap.' },
    note: { type: 'string' },
  },
  required: ['env', 'db', 'collection', 'op', 'limit', 'maxTimeMS', 'truncated', 'bytes'],
}

// ---------------------------------------------------------------------------
// validation

export function checkOp(op) {
  if (!OPS.includes(op)) {
    throw new Error(`mongo_read: op must be one of ${OPS.join(', ')}; got ${JSON.stringify(op)} (writes are not allowed)`)
  }
  return op
}

export function checkEnv(env) {
  if (!Object.hasOwn(ENV_VARS, String(env))) {
    throw new Error(`mongo_read: env must be one of ${Object.keys(ENV_VARS).join(', ')}; got ${JSON.stringify(env)}`)
  }
  return env
}

export function checkName(label, value) {
  const s = typeof value === 'string' ? value.trim() : ''
  if (!s) throw new Error(`mongo_read: \`${label}\` must be a non-empty string`)
  if (s.length > 128 || s.includes('\0')) throw new Error(`mongo_read: \`${label}\` is invalid`)
  return s
}

// Walks objects and arrays at any depth, so `$out`/`$merge` inside $facet, $lookup.pipeline,
// $unionWith, $group accumulators, or any other nested stage body is still caught.
export function findWriteStage(pipeline) {
  const walk = (value, at) => {
    if (Array.isArray(value)) {
      for (let i = 0; i < value.length; i++) {
        const found = walk(value[i], `${at}[${i}]`)
        if (found) return found
      }
      return null
    }
    if (value && typeof value === 'object') {
      for (const [key, child] of Object.entries(value)) {
        if (WRITE_STAGES.includes(key)) return `${at}.${key}`
        const found = walk(child, `${at}.${key}`)
        if (found) return found
      }
    }
    return null
  }
  return walk(pipeline, 'pipeline')
}

export function checkPipeline(pipeline) {
  if (!Array.isArray(pipeline)) throw new Error('mongo_read: aggregate requires `pipeline` to be an array')
  const found = findWriteStage(pipeline)
  if (found) throw new Error(`mongo_read: ${found} is a write stage; only read pipelines are allowed`)
  return pipeline
}

export function resolveLimits(args, config = {}) {
  const cfg = { ...DEFAULTS, ...config }
  let limit = cfg.limit
  let limitClamped = false
  if (args?.limit !== undefined) {
    if (!Number.isInteger(args.limit) || args.limit < 1) throw new Error('mongo_read: `limit` must be a positive integer')
    limit = args.limit
    if (limit > cfg.maxLimit) {
      limit = cfg.maxLimit
      limitClamped = true
    }
  }
  let maxTimeMS = cfg.maxTimeMS
  let maxTimeMSClamped = false
  if (args?.maxTimeMS !== undefined) {
    if (!Number.isInteger(args.maxTimeMS) || args.maxTimeMS < 1) throw new Error('mongo_read: `maxTimeMS` must be a positive integer')
    maxTimeMS = args.maxTimeMS
    if (maxTimeMS > cfg.maxMaxTimeMS) {
      maxTimeMS = cfg.maxMaxTimeMS
      maxTimeMSClamped = true
    }
  }
  return { limit, maxTimeMS, limitClamped, maxTimeMSClamped }
}

// ---------------------------------------------------------------------------
// redaction

// Connection strings, URI userinfo, and env assignments. Applied to every string we hand back.
export function redact(text) {
  return String(text ?? '')
    .replace(/\b(mongodb(?:\+srv)?:\/\/)[^\s"'`<>]*/gi, '$1[redacted]')
    .replace(/\b([a-z][a-z0-9+.-]*:\/\/)[^\s/@"'`<>]+@/gi, '$1[redacted]@')
    .replace(/\b(BWS_ACCESS_TOKEN|MONGO_URI_[A-Z0-9_]+)\b(\s*[=:]\s*)(\S+)/g, '$1$2[redacted]')
}

export function redactDeep(value) {
  if (typeof value === 'string') return redact(value)
  if (Array.isArray(value)) return value.map(redactDeep)
  if (value && typeof value === 'object') {
    const out = {}
    for (const [key, child] of Object.entries(value)) out[redact(key)] = redactDeep(child)
    return out
  }
  return value
}

// ---------------------------------------------------------------------------
// command / env for the child

export function buildCommand(runnerPath, config = {}) {
  if (!SAFE_PATH.test(runnerPath)) throw new Error('mongo_read: refusing an unexpected runner path')
  const mongosh = config.mongoshPath ?? 'mongosh'
  if (!SAFE_PATH.test(mongosh)) throw new Error('mongo_read: refusing an unexpected mongosh path')
  return `exec '${mongosh}' --nodb --quiet --norc --file '${runnerPath}'`
}

// No MONGO_URI_* / BWS_* value is forwarded to the child: only the path of the temp job file.
export function childEnv(jobPath) {
  const base = {}
  for (const [key, value] of Object.entries(process.env)) {
    if (/^(MONGO_URI_|BWS_)/.test(key)) continue
    base[key] = value
  }
  // The user's PATH comes first so their own mongosh/bwsr win; the extra dirs only fill gaps that a
  // GUI-launched app leaves out.
  const PATH = [process.env.PATH, path.join(os.homedir(), '.local/bin'), '/opt/homebrew/bin', '/usr/local/bin', '/usr/bin', '/bin']
    .filter(Boolean)
    .join(':')
  return { ...base, PATH, DSH_MONGO_READ_JOB: jobPath }
}

// Runs inside `mongosh --nodb`, so the URI is only ever read from the environment.
export const RUNNER_SOURCE = `// generated by @local/dsh-mongo-read
const RESULT_MARK = ${JSON.stringify(RESULT_MARK)}
const ERROR_MARK = ${JSON.stringify(ERROR_MARK)}
let SECRET = ''
const scrub = (value) => {
  let text = String(value && value.message ? value.message : value)
  if (SECRET) text = text.split(SECRET).join('[redacted]')
  return text.replace(/\\b(mongodb(?:\\+srv)?:\\/\\/)[^\\s"']*/gi, '$1[redacted]')
}
const emit = (mark, value) => print(mark + EJSON.stringify(value, null, 0, { relaxed: true }))
const job = EJSON.parse(fs.readFileSync(process.env.DSH_MONGO_READ_JOB, 'utf8'))

// connect(uri) in mongosh 2.x is (uri, user?, pwd?) and has no options argument, so the selection timeout
// rides inside the URI. Without it an unreachable host waits out the driver default instead of failing fast.
const withSelectionTimeout = (uri, ms) => {
  if (!ms || /[?&]serverSelectionTimeoutMS=/i.test(uri)) return uri
  return uri + (uri.indexOf('?') >= 0 ? '&' : '?') + 'serverSelectionTimeoutMS=' + ms
}

async function main() {
  if (!job.uriEnv) throw new Error('job has no uriEnv')
  const uri = process.env[job.uriEnv]
  SECRET = uri || ''
  if (!uri) throw new Error('missing env var ' + job.uriEnv + ' (bwsr did not provide it)')
  const conn = connect(withSelectionTimeout(uri, job.connectTimeoutMS))
  const database = conn.getSiblingDB(job.db)
  const collection = database.getCollection(job.collection)
  const filter = job.filter || {}
  if (job.op === 'find') {
    // mongosh is find(query, projection, options): the options document is the THIRD argument.
    const options = { limit: job.limit, batchSize: job.limit, maxTimeMS: job.maxTimeMS }
    if (job.sort) options.sort = job.sort
    return { docs: await collection.find(filter, job.projection, options).toArray() }
  }
  if (job.op === 'countDocuments') {
    return { count: await collection.countDocuments(filter, { maxTimeMS: job.maxTimeMS }) }
  }
  if (job.op === 'aggregate') {
    // allowDiskUse false on purpose: a heavy pipeline should fail fast rather than spill onto prod disk.
    const pipeline = (job.pipeline || []).concat([{ $limit: job.limit }])
    return { docs: await collection.aggregate(pipeline, { maxTimeMS: job.maxTimeMS, allowDiskUse: false }).toArray() }
  }
  throw new Error('unsupported op ' + String(job.op))
}

// mongosh exits as soon as the script's completion value settles, so the awaited value must both print
// the marker and never reject (a rejected completion makes mongosh print a raw driver error and exit 1).
const done = main().then(
  (value) => emit(RESULT_MARK, value),
  (error) => {
    emit(ERROR_MARK, { message: scrub(error) })
    process.exitCode = 2
  },
)
done
`

// ---------------------------------------------------------------------------
// output capping

// `bytes` is the exact serialized size of the payload the model receives, including the `bytes` field
// itself, so a fixed point is the only honest measure.
function measure(value) {
  let bytes = 0
  for (let i = 0; i < 6; i++) {
    const next = Buffer.byteLength(JSON.stringify({ ...value, bytes }))
    if (next === bytes) break
    bytes = next
  }
  return bytes
}

const withBytes = (value) => ({ ...value, bytes: measure(value) })
const serializedSize = (value) => Buffer.byteLength(JSON.stringify(withBytes(value)))

// Drops documents from the tail until the serialized JSON fits, then reports what was lost.
export function capOutput(result, maxBytes) {
  const full = redactDeep(result)
  let body = { ...full, truncated: false }
  if (serializedSize(body) > maxBytes) {
    const docs = Array.isArray(full.docs) ? full.docs : null
    if (!docs) {
      // countDocuments only: keep the numbers; there is nothing meaningful left to drop.
      body = { ...full, truncated: true, note: `output capped at ${maxBytes} bytes` }
    } else {
      const kept = []
      for (const doc of docs) {
        const candidate = { ...full, docs: [...kept, doc], truncated: true }
        if (serializedSize(candidate) > maxBytes) break
        kept.push(doc)
      }
      body = { ...full, docs: kept, truncated: true, dropped: docs.length - kept.length, note: `output capped at ${maxBytes} bytes` }
      if (serializedSize(body) > maxBytes) {
        body = { ...full, docs: [], dropped: docs.length, truncated: true, note: `output capped at ${maxBytes} bytes; even one document is too large` }
      }
    }
  }
  return withBytes(body)
}

// ---------------------------------------------------------------------------
// approval description

// The card must show the whole query: a clipped filter would let a prod call run something the reader
// never saw, so an over-long query is refused instead of trimmed.
export const MAX_CARD_JSON = 600

export function describeCall({ env, db, collection, op, filter, pipeline, projection, sort, limit }) {
  const parts = [`mongo_read ${env}: db=${db}`, `collection=${collection}`, `op=${op}`]
  if (limit !== undefined) parts.push(`limit=${limit}`)
  const show = (label, text) => {
    if (text.length > MAX_CARD_JSON) {
      throw new Error(
        `mongo_read: prod ${label} is ${text.length} characters; the approval card shows at most ${MAX_CARD_JSON}. ` +
          `Narrow the ${label} (or use staging), because a truncated ${label} would hide part of what prod would run.`,
      )
    }
    parts.push(`${label}=${text}`)
  }
  if (op === 'aggregate') show('pipeline', JSON.stringify(pipeline ?? []))
  else show('filter', JSON.stringify(filter ?? {}))
  if (projection) show('projection', JSON.stringify(projection))
  if (sort) show('sort', JSON.stringify(sort))
  return parts.join(' ')
}

// ---------------------------------------------------------------------------
// spawn + parse

// bwsr runs `bws`, which execs mongosh: killing only the direct child leaves the grandchild holding the
// stdio pipes, and the callback would then wait for it. spawn (not execFile) is used because only spawn
// honours `detached` and gives the child its own process group, so one signal reaches the whole tree.
function runChild(file, args, options) {
  return new Promise((resolve) => {
    let settled = false
    let stopped
    let timer
    let child
    const limit = options.maxBuffer ?? 8 * 1024 * 1024
    let bytes = 0
    const out = []
    const errOut = []
    const stop = (reason) => {
      if (stopped) return
      stopped = reason
      try {
        process.kill(-child.pid, 'SIGKILL')
      } catch {
        try {
          child.kill('SIGKILL')
        } catch {}
      }
    }
    const onAbort = () => stop('aborted')
    const settle = (payload) => {
      if (settled) return
      settled = true
      if (timer) clearTimeout(timer)
      options.signal?.removeEventListener?.('abort', onAbort)
      resolve({
        ...payload,
        stdout: payload.stdout ?? Buffer.concat(out).toString('utf8'),
        stderr: payload.stderr ?? Buffer.concat(errOut).toString('utf8'),
        stopped,
      })
    }
    try {
      child = spawn(file, args, {
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe'],
        env: options.env,
        cwd: options.cwd,
        signal: options.signal,
      })
    } catch (error) {
      return settle({ err: error, stdout: '', stderr: '' })
    }
    const collect = (sink) => (chunk) => {
      bytes += chunk.length
      if (bytes > limit) {
        stop('maxBuffer')
        return
      }
      sink.push(chunk)
    }
    child.stdout.on('data', collect(out))
    child.stderr.on('data', collect(errOut))
    child.on('error', (error) => settle({ err: error, stdout: '', stderr: '' }))
    child.on('close', (code, signal) => {
      const err = code === 0 && !stopped ? undefined : Object.assign(new Error(`exit ${code ?? signal ?? 'unknown'}`), { code, signal })
      settle({ err })
    })
    options.signal?.addEventListener?.('abort', onAbort, { once: true })
    if (options.signal?.aborted) stop('aborted')
    timer = setTimeout(() => stop('timeout'), options.timeoutMs)
  })
}

// undefined = marker absent, null = marker present but unparsable.
function findMarked(stdout, mark) {
  const line = String(stdout)
    .split('\n')
    .reverse()
    .find((l) => l.startsWith(mark))
  if (!line) return undefined
  try {
    return JSON.parse(line.slice(mark.length))
  } catch {
    return null
  }
}

function tail(text, maxBytes) {
  const buf = Buffer.from(String(text ?? ''), 'utf8')
  return (buf.length <= maxBytes ? buf : buf.subarray(buf.length - maxBytes)).toString('utf8').trim()
}

export async function runQuery(plan, config = {}) {
  const cfg = { ...DEFAULTS, ...config }
  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'dsh-mongo-read-'))
  const jobPath = path.join(dir, 'job.json')
  const runnerPath = path.join(dir, 'runner.js')
  try {
    await fs.writeFile(runnerPath, RUNNER_SOURCE, { mode: 0o600 })
    await fs.writeFile(jobPath, JSON.stringify(plan.job), { mode: 0o600 })
    const { err, stdout, stderr, stopped } = await runChild(cfg.bwsrPath ?? 'bwsr', ['--', buildCommand(runnerPath, cfg)], {
      timeoutMs: cfg.timeoutMs,
      maxBuffer: cfg.maxBuffer,
      env: childEnv(jobPath),
      cwd: dir,
      signal: plan.signal ?? cfg.signal,
    })
    const failure = findMarked(stdout, ERROR_MARK)
    if (failure === null) throw new Error('mongo_read failed: unparsable child error output')
    if (failure) throw new Error(redact(`mongo_read failed: ${failure.message ?? 'unknown child error'}`))
    const value = findMarked(stdout, RESULT_MARK)
    if (value === null) throw new Error('mongo_read failed: unparsable child result')
    if (value) return value
    const detail = tail(stderr, cfg.maxStderrBytes) || tail(stdout, cfg.maxStderrBytes)
    if (stopped === 'timeout' || (!stopped && err?.killed)) {
      throw new Error(redact(`mongo_read timed out after ${cfg.timeoutMs}ms${detail ? `: ${detail}` : ''}`))
    }
    if (stopped === 'aborted') throw new Error('mongo_read: cancelled before the query returned')
    if (stopped === 'maxBuffer') throw new Error('mongo_read: child output exceeded the buffer; narrow the query')
    if (err?.code === 'ENOENT') throw new Error('mongo_read: bwsr not found on PATH; install bwsr or set `bwsrPath` in the plugin config')
    const code = err ? `exit ${err.code ?? err.signal ?? 'unknown'}` : 'no result marker'
    throw new Error(redact(`mongo_read failed (${code})${detail ? `: ${detail}` : ''}`))
  } finally {
    await fs.rm(dir, { recursive: true, force: true })
  }
}

// ---------------------------------------------------------------------------
// tool registration

export function apply(ctx, config = {}) {
  if (config.enabled === false) return
  const cfg = { ...DEFAULTS, ...config }
  ctx.tools.register({
    name: 'mongo_read',
    description: DESCRIPTION,
    parameters: PARAMETERS,
    // Host backstop only: the child timeout above fires first and kills the whole process group, so a
    // host-level abandon never leaves a mongosh grandchild behind.
    timeoutMs: cfg.timeoutMs + 10000,
    output: {
      schema: OUTPUT_SCHEMA,
      render: (_args, value) => [{ type: 'text', text: JSON.stringify(value) }],
    },
    async execute(args, exec) {
      const env = checkEnv(args?.env)
      const db = checkName('db', args?.db)
      const collection = checkName('collection', args?.collection)
      const op = checkOp(args?.op)
      const { limit, maxTimeMS, limitClamped, maxTimeMSClamped } = resolveLimits(args, cfg)

      let filter
      let pipeline
      if (op === 'aggregate') {
        if (args?.pipeline !== undefined && !Array.isArray(args.pipeline)) throw new Error('mongo_read: `pipeline` must be an array')
        pipeline = checkPipeline(args?.pipeline)
        if (args?.filter !== undefined && args.filter !== null) throw new Error('mongo_read: `filter` is not used by aggregate; put a $match stage in the pipeline')
      } else {
        if (args?.pipeline !== undefined) throw new Error(`mongo_read: \`pipeline\` is only valid for aggregate (op=${op})`)
        filter = args?.filter ?? {}
        if (filter === null || typeof filter !== 'object' || Array.isArray(filter)) throw new Error('mongo_read: `filter` must be an object')
      }
      for (const key of ['projection', 'sort']) {
        const value = args?.[key]
        if (value !== undefined && value !== null && (typeof value !== 'object' || Array.isArray(value))) {
          throw new Error(`mongo_read: \`${key}\` must be an object`)
        }
      }

      // prod is gated on an approval card, never on an in-chat confirmation: this plugin cannot read chat.
      if (env === 'prod') {
        const approval = ctx.get?.('approval')
        if (!approval) throw new Error('mongo_read: prod requires the approval service, which is not available; failing closed')
        if (!exec?.agent) throw new Error('mongo_read: prod requires an owning agent session to raise the approval card')
        const reason = describeCall({ env, db, collection, op, filter, pipeline, projection: args?.projection, sort: args?.sort, limit })
        const outcome = await approval.request({
          agent: exec.agent,
          toolName: 'mongo_read',
          callId: exec.callId,
          reason,
          displayReason: { en: reason },
          signal: exec.signal,
        })
        if (outcome !== 'allowed-once') {
          const why =
            outcome === 'rejected'
              ? 'rejected (by user or session policy)'
              : outcome === 'cancelled'
                ? 'approval was cancelled'
                : 'no approval answerer was available'
          throw new Error(`mongo_read: prod access blocked (${why})`)
        }
      }

      const job = {
        env,
        uriEnv: ENV_VARS[env],
        db,
        collection,
        op,
        limit,
        maxTimeMS,
        connectTimeoutMS: cfg.connectTimeoutMS,
      }
      if (op === 'aggregate') job.pipeline = pipeline
      else job.filter = filter
      if (args?.projection) job.projection = args.projection
      if (args?.sort) job.sort = args.sort

      const signal = exec?.signal ?? cfg.signal
      const raw = await runQuery({ job, signal }, cfg)
      const result = { env, db, collection, op, limit, maxTimeMS, ...raw }
      if (limitClamped) result.note = `limit clamped to ${limit}`
      if (maxTimeMSClamped) result.note = `${result.note ? `${result.note}; ` : ''}maxTimeMS clamped to ${maxTimeMS}`
      return capOutput(result, cfg.maxOutputBytes)
    },
    presentCall: (args) => ({
      card: 'generic',
      title: `mongo_read ${args?.env ?? '?'}/${args?.db ?? '?'}.${args?.collection ?? '?'} ${args?.op ?? '?'}`,
      kind: 'read',
      rawInput: { env: args?.env, db: args?.db, collection: args?.collection, op: args?.op, filter: args?.filter, pipeline: args?.pipeline },
    }),
  })
}

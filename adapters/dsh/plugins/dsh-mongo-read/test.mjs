import fs from 'node:fs'
import fsp from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { execFileSync, spawnSync } from 'node:child_process'
import vm from 'node:vm'
import {
  apply,
  buildCommand,
  capOutput,
  checkEnv,
  checkOp,
  checkPipeline,
  childEnv,
  describeCall,
  findWriteStage,
  redact,
  redactDeep,
  resolveLimits,
  RUNNER_SOURCE,
  ERROR_MARK,
  RESULT_MARK,
} from './index.js'

let failed = 0
let total = 0
const check = (label, ok, extra = '') => {
  total++
  if (!ok) failed++
  console.log(`${ok ? 'PASS' : 'FAIL'} ${label}${ok ? '' : ` [${extra}]`}`)
}
const rejects = async (fn, re) => {
  try {
    await fn()
    return false
  } catch (error) {
    return re.test(error.message)
  }
}
const throws = (fn, re) => {
  try {
    fn()
    return false
  } catch (error) {
    return re.test(error.message)
  }
}

// ---------------------------------------------------------------------------
// fixtures

const root = fs.mkdtempSync(path.join(os.tmpdir(), 'dsh-mongo-read-test-'))
const stub = path.join(root, 'fake-bwsr')
fs.writeFileSync(
  stub,
  `#!/bin/bash
rec="\${FAKE_BWSR_REC-}"
if [ -n "$rec" ]; then
  {
    printf 'argc=%s\\n' "$#"
    i=0
    for a in "$@"; do printf 'arg%s=%s\\n' "$i" "$a"; i=$((i+1)); done
    printf 'job=%s\\n' "\${DSH_MONGO_READ_JOB-<unset>}"
    printf 'uri_staging=%s\\n' "\${MONGO_URI_STAGING-<unset>}"
    if [ -n "\${DSH_MONGO_READ_JOB-}" ] && [ -f "\${DSH_MONGO_READ_JOB}" ]; then
      printf 'job_json='; cat "\${DSH_MONGO_READ_JOB}"; printf '\\n'
    fi
  } > "$rec"
fi
if [ -n "\${FAKE_BWSR_STDOUT-}" ]; then cat "\$FAKE_BWSR_STDOUT"; fi
if [ -n "\${FAKE_BWSR_STDERR-}" ]; then cat "\$FAKE_BWSR_STDERR" >&2; fi
# After the output, so a sleep case still exceeds the timeout while the child is alive.
if [ -n "\${FAKE_BWSR_SLEEP-}" ]; then sleep "\$FAKE_BWSR_SLEEP"; fi
exit "\${FAKE_BWSR_EXIT:-0}"
`,
  { mode: 0o755 },
)

let caseNo = 0
const newCase = () => {
  caseNo++
  const rec = path.join(root, `rec-${caseNo}.txt`)
  const stdoutFile = path.join(root, `out-${caseNo}.txt`)
  const stderrFile = path.join(root, `err-${caseNo}.txt`)
  for (const key of ['FAKE_BWSR_REC', 'FAKE_BWSR_STDOUT', 'FAKE_BWSR_STDERR', 'FAKE_BWSR_EXIT', 'FAKE_BWSR_SLEEP']) delete process.env[key]
  process.env.FAKE_BWSR_REC = rec
  return {
    rec,
    stdout: (text) => {
      fs.writeFileSync(stdoutFile, text)
      process.env.FAKE_BWSR_STDOUT = stdoutFile
    },
    stderr: (text) => {
      fs.writeFileSync(stderrFile, text)
      process.env.FAKE_BWSR_STDERR = stderrFile
    },
    exit: (code) => {
      process.env.FAKE_BWSR_EXIT = String(code)
    },
    sleep: (seconds) => {
      process.env.FAKE_BWSR_SLEEP = String(seconds)
    },
    record: () => (fs.existsSync(rec) ? fs.readFileSync(rec, 'utf8') : null),
    recordFields: () => {
      const text = fs.existsSync(rec) ? fs.readFileSync(rec, 'utf8') : ''
      const fields = {}
      for (const line of text.split('\n')) {
        const i = line.indexOf('=')
        if (i > 0) fields[line.slice(0, i)] = line.slice(i + 1)
      }
      return fields
    },
  }
}

function fakeCtx(options = {}) {
  const tools = []
  const ctx = {
    tools: {
      register: (definition) => {
        tools.push(definition)
        return () => {}
      },
    },
    get: (key) => (key === 'approval' ? options.approval : undefined),
  }
  return { ctx, tools }
}

const agent = { id: 'session-test' }
const execFor = (extra = {}) => ({ agent, callId: 'call-test', signal: new AbortController().signal, ...extra })

async function setUp(options = {}) {
  const { ctx, tools } = fakeCtx(options)
  apply(ctx, { bwsrPath: stub, timeoutMs: options.timeoutMs ?? 4000, ...options.config })
  return { tool: tools[0], tools }
}

const resultLine = (value) => `${RESULT_MARK}${JSON.stringify(value)}\n`
const errorLine = (message) => `${ERROR_MARK}${JSON.stringify({ message })}\n`

// ---------------------------------------------------------------------------
// validation

check('checkOp accepts the three read ops', ['find', 'countDocuments', 'aggregate'].every((op) => checkOp(op) === op))
check(
  'checkOp rejects writes (updateOne/deleteMany/insertOne/bulkWrite)',
  ['updateOne', 'deleteMany', 'insertOne', 'bulkWrite', 'aggregate$'].every((op) => throws(() => checkOp(op), /writes are not allowed/)),
)
check('checkOp rejects undefined', throws(() => checkOp(undefined), /op must be one of/))
check('checkEnv accepts staging/uat/prod', ['staging', 'uat', 'prod'].every((env) => checkEnv(env) === env))
check('checkEnv rejects production/PROD/an arbitrary value', ['production', 'PROD', '', null].every((env) => throws(() => checkEnv(env), /env must be one of/)))

check('findWriteStage: top-level $out', findWriteStage([{ $match: {} }, { $out: 'x' }]) === 'pipeline[1].$out')
check('findWriteStage: top-level $merge', findWriteStage([{ $merge: { into: 'x' } }]) === 'pipeline[0].$merge')
check(
  'findWriteStage: inside $facet branches (nested arrays)',
  findWriteStage([{ $facet: { a: [{ $match: {} }], b: [{ $group: { _id: null } }, { $out: 'leak' }] } }]) === 'pipeline[0].$facet.b[1].$out',
)
check(
  'findWriteStage: inside $lookup.pipeline',
  findWriteStage([{ $lookup: { from: 'c', pipeline: [{ $merge: { into: 'leak' } }], as: 'x' } }]) === 'pipeline[0].$lookup.pipeline[0].$merge',
)
check(
  'findWriteStage: inside $unionWith.pipeline',
  findWriteStage([{ $unionWith: { coll: 'c', pipeline: [{ $out: 'leak' }] } }]) === 'pipeline[0].$unionWith.pipeline[0].$out',
)
check(
  'findWriteStage: deeply nested inside $group accumulator expression',
  findWriteStage([{ $group: { _id: null, v: { $sum: { $cond: [{ $eq: [1, 1] }, 1, { $merge: { into: 'z' } }] } } } }])
    === 'pipeline[0].$group.v.$sum.$cond[2].$merge',
)
check('findWriteStage: plain read pipeline is clean', findWriteStage([{ $match: { a: 1 } }, { $group: { _id: '$x' } }, { $limit: 5 }]) === null)
check('findWriteStage: "$out" as a field path string value is not a stage', findWriteStage([{ $project: { v: '$out' } }]) === null)
check('checkPipeline rejects a non-array', throws(() => checkPipeline('[]'), /pipeline` to be an array/))
check('checkPipeline error names the offending path', throws(() => checkPipeline([{ $facet: { a: [{ $merge: {} }] } }]), /pipeline\[0\]\.\$facet\.a\[0\]\.\$merge/))

const limits = resolveLimits({}, {})
check('limits default to 20 docs / 5000ms', limits.limit === 20 && limits.maxTimeMS === 5000 && !limits.limitClamped && !limits.maxTimeMSClamped, JSON.stringify(limits))
const clamped = resolveLimits({ limit: 100000, maxTimeMS: 900000 }, {})
check('over-cap limit/maxTimeMS are clamped to 200/15000 and flagged', clamped.limit === 200 && clamped.maxTimeMS === 15000 && clamped.limitClamped && clamped.maxTimeMSClamped, JSON.stringify(clamped))
check('limit exactly at the cap is not flagged', resolveLimits({ limit: 200 }, {}).limitClamped === false)
check('a small limit is honoured', resolveLimits({ limit: 3, maxTimeMS: 250 }, {}).limit === 3)
check(
  'invalid limit/maxTimeMS are rejected (0, -1, 1.5, "5", NaN)',
  [0, -1, 1.5, '5', Number.NaN].every((value) => throws(() => resolveLimits({ limit: value }, {}), /positive integer/))
    && [0, -1, '5'].every((value) => throws(() => resolveLimits({ maxTimeMS: value }, {}), /positive integer/)),
)

// ---------------------------------------------------------------------------
// redaction

const uri = 'mongodb+srv://alice:sup3rsecret@cluster0.example.net/oho'
const redacted = redact(`connect failed for ${uri} (user alice)`)
check('redact removes a mongodb+srv URI including credentials', !redacted.includes('sup3rsecret') && !redacted.includes('cluster0.example.net') && redacted.includes('[redacted]'), redacted)
check('redact removes a plain mongodb URI', !redact('mongodb://u:p@h:27017/db').includes('u:p@h'), redact('mongodb://u:p@h:27017/db'))
check('redact removes userinfo from other schemes', !redact('https://user:pass@example.com/x').includes('user:pass'))
check('redact masks MONGO_URI_* / BWS_ACCESS_TOKEN assignments', !redact('MONGO_URI_PROD=mongodb://a:b@h/db').includes('a:b@h') && !redact('BWS_ACCESS_TOKEN=abc123').includes('abc123'))
check('redact leaves ordinary text alone', redact('db=oho collection=users op=find') === 'db=oho collection=users op=find')
const deep = redactDeep({ note: uri, docs: [{ dsn: 'mongodb://u:p@h/db' }, 'plain'] })
check('redactDeep walks nested documents', !JSON.stringify(deep).includes('sup3rsecret') && !JSON.stringify(deep).includes('u:p@h') && deep.docs[1] === 'plain', JSON.stringify(deep))

// ---------------------------------------------------------------------------
// child command + env

const command = buildCommand('/tmp/dsh-mongo-read-abc/runner.js')
check('buildCommand quotes the runner and never carries a URI', command === "exec 'mongosh' --nodb --quiet --norc --file '/tmp/dsh-mongo-read-abc/runner.js'", command)
check('buildCommand refuses shell metacharacters in the path', throws(() => buildCommand("/tmp/x'; rm -rf /"), /unexpected runner path/))
check('buildCommand refuses a bad mongosh path', throws(() => buildCommand('/tmp/r.js', { mongoshPath: 'mongosh; rm -rf /' }), /unexpected mongosh path/))
const fakeJob = path.join(root, 'job-env.json')
fs.writeFileSync(fakeJob, '{}')
const savedStaging = process.env.MONGO_URI_STAGING
const savedToken = process.env.BWS_ACCESS_TOKEN
process.env.MONGO_URI_STAGING = 'mongodb://u:p@h/db'
process.env.BWS_ACCESS_TOKEN = 'tok'
const env = childEnv(fakeJob)
if (savedStaging === undefined) delete process.env.MONGO_URI_STAGING
else process.env.MONGO_URI_STAGING = savedStaging
if (savedToken === undefined) delete process.env.BWS_ACCESS_TOKEN
else process.env.BWS_ACCESS_TOKEN = savedToken
check('childEnv passes the job path', env.DSH_MONGO_READ_JOB === fakeJob)
check('childEnv forwards no MONGO_URI_* / BWS_* value', !Object.keys(env).some((key) => /^(MONGO_URI_|BWS_)/.test(key)), Object.keys(env).filter((k) => /MONGO_URI|BWS/.test(k)).join(','))
check('childEnv keeps a usable PATH with ~/.local/bin and /opt/homebrew/bin', env.PATH.split(':').includes(path.join(os.homedir(), '.local/bin')) && env.PATH.split(':').includes('/opt/homebrew/bin'))
check(
  'childEnv puts the inherited PATH first so the user binaries win',
  process.env.PATH ? env.PATH.startsWith(`${process.env.PATH}:`) : true,
  `${env.PATH.slice(0, 40)} vs ${process.env.PATH}`,
)
check('childEnv appends the system dirs after the inherited PATH', env.PATH.endsWith('/usr/bin:/bin') && env.PATH.split(':').indexOf('/usr/bin') > env.PATH.split(':').indexOf(path.join(os.homedir(), '.local/bin')))

// ---------------------------------------------------------------------------
// output capping

const small = capOutput({ env: 'staging', db: 'd', collection: 'c', op: 'find', limit: 20, maxTimeMS: 5000, docs: [{ a: 1 }] }, 4096)
check('capOutput leaves small output untouched', small.truncated === false && small.docs.length === 1 && small.bytes === Buffer.byteLength(JSON.stringify(small)), JSON.stringify(small))
const manyDocs = Array.from({ length: 40 }, (_, i) => ({ i, pad: 'x'.repeat(80) }))
const capped = capOutput({ env: 'staging', db: 'd', collection: 'c', op: 'find', limit: 200, maxTimeMS: 5000, docs: manyDocs }, 900)
check('capOutput drops documents to respect the byte cap', capped.truncated === true && capped.docs.length < 40 && capped.dropped === 40 - capped.docs.length, JSON.stringify({ kept: capped.docs.length, dropped: capped.dropped }))
check('capOutput stays within the byte cap', capped.bytes <= 900 && Buffer.byteLength(JSON.stringify(capped)) === capped.bytes)
check('capOutput reports truncation in a note', /capped at 900 bytes/.test(capped.note ?? ''))
const huge = capOutput({ env: 'staging', db: 'd', collection: 'c', op: 'find', limit: 1, maxTimeMS: 5000, docs: [{ big: 'y'.repeat(2000) }] }, 500)
check('capOutput drops an oversized single document and says so', huge.truncated === true && huge.docs.length === 0 && huge.dropped === 1 && huge.bytes <= 500, JSON.stringify(huge).slice(0, 200))
const countCapped = capOutput({ env: 'staging', db: 'd', collection: 'c', op: 'countDocuments', limit: 20, maxTimeMS: 5000, count: 12 }, 100)
check('capOutput keeps countDocuments results', countCapped.count === 12 && countCapped.truncated === true, JSON.stringify(countCapped))

// ---------------------------------------------------------------------------
// approval description

const described = describeCall({ env: 'prod', db: 'oho', collection: 'users', op: 'find', filter: { email: 'a@b.c' }, limit: 20 })
check('describeCall shows env/db/collection/op/filter', /mongo_read prod/.test(described) && described.includes('db=oho') && described.includes('collection=users') && described.includes('op=find') && described.includes('a@b.c'), described)
check('describeCall shows limit on the card', described.includes('limit=20'), described)
check('describeCall shows projection and sort when present', describeCall({ env: 'prod', db: 'd', collection: 'c', op: 'find', filter: {}, projection: { a: 1 }, sort: { a: 1 } }).includes('projection={"a":1} sort={"a":1}'))
check('describeCall shows the pipeline for aggregate', describeCall({ env: 'prod', db: 'd', collection: 'c', op: 'aggregate', pipeline: [{ $match: { a: 1 } }] }).includes('pipeline=[{"$match":{"a":1}}]'))
check(
  'describeCall refuses a filter longer than the card can show',
  throws(() => describeCall({ env: 'prod', db: 'd', collection: 'c', op: 'find', filter: { a: 'z'.repeat(2000) } }), /is \d+ characters; the approval card shows at most 600/),
)
check(
  'describeCall refuses an over-long pipeline too',
  throws(() => describeCall({ env: 'prod', db: 'd', collection: 'c', op: 'aggregate', pipeline: [{ $match: { a: 'z'.repeat(2000) } }] }), /pipeline is \d+ characters/),
)
check('a filter exactly at the limit still passes', describeCall({ env: 'prod', db: 'd', collection: 'c', op: 'find', filter: { a: 'z'.repeat(585) } }).length > 0)

// ---------------------------------------------------------------------------
// registration

{
  const { tools } = await setUp()
  const tool = tools[0]
  check('registers exactly one tool named mongo_read', tools.length === 1 && tool.name === 'mongo_read')
  check('required params are env/db/collection/op', tool.parameters.required.join() === 'env,db,collection,op')
  check('op enum is the three read ops', tool.parameters.properties.op.enum.join() === 'find,countDocuments,aggregate')
  check('pipeline is an array of stage objects', tool.parameters.properties.pipeline.type === 'array' && tool.parameters.properties.pipeline.items.type === 'object')
  check('output docs is an array', tool.output.schema.properties.docs.type === 'array' && tool.output.schema.properties.docs.items.type === 'object')
  check('env enum is staging/uat/prod', tool.parameters.properties.env.enum.join() === 'staging,uat,prod')
  check('description states read-only, prod approval, caps', /Read-only/.test(tool.description) && /approval card/.test(tool.description) && /capped at 200/.test(tool.description) && /\$out\/\$merge/.test(tool.description))
  check('output schema + render', tool.output.schema.required.includes('truncated') && tool.output.render({}, { env: 'staging', truncated: false })[0].text.includes('"staging"'))
  check('presentCall renders a read card', tool.presentCall({ env: 'prod', db: 'oho', collection: 'users', op: 'find' }).title === 'mongo_read prod/oho.users find')
  const off = await setUp({ config: { enabled: false } })
  check('enabled:false registers nothing', off.tools.length === 0)
}

// ---------------------------------------------------------------------------
// execute: staging

{
  const c = newCase()
  const { tool } = await setUp()
  c.stdout(resultLine({ docs: [{ _id: 'x', email: 'a@b.c' }] }))
  const value = await tool.execute(
    { env: 'staging', db: 'oho', collection: 'users', op: 'find', filter: { email: 'a@b.c' }, projection: { email: 1 }, sort: { _id: 1 } },
    execFor(),
  )
  const fields = c.recordFields()
  check('staging find returns the documents', value.docs?.length === 1 && value.docs[0].email === 'a@b.c' && value.truncated === false, JSON.stringify(value))
  check('spawns bwsr as `-- <command>`', fields.argc === '2' && fields.arg0 === '--' && /^exec 'mongosh' --nodb --quiet --norc --file '.+runner\.js'$/.test(fields.arg1 ?? ''), JSON.stringify(fields))
  check('the command line carries no URI, env name, or query value', !/mongodb|MONGO_URI|a@b\.c/.test(fields.arg1 ?? ''), fields.arg1)
  check('bwsr was given no secret through its own environment', fields.uri_staging === '<unset>')
  const job = JSON.parse(fields.job_json ?? '{}')
  check('the query travels in the temp job file', job.op === 'find' && job.db === 'oho' && job.collection === 'users' && JSON.stringify(job.filter) === '{"email":"a@b.c"}', fields.job_json)
  check('the job names the allowlisted env var, not a URI', job.uriEnv === 'MONGO_URI_STAGING' && !JSON.stringify(job).includes('mongodb'))
  check('the job carries the resolved limits', job.limit === 20 && job.maxTimeMS === 5000, JSON.stringify({ limit: job.limit, maxTimeMS: job.maxTimeMS }))
  check('the temp directory is removed afterwards', !fs.existsSync(fields.job ?? '/nonexistent/'), fields.job)
}

{
  const c = newCase()
  const { tool } = await setUp()
  c.stdout(resultLine({ count: 42 }))
  const value = await tool.execute({ env: 'uat', db: 'oho', collection: 'users', op: 'countDocuments', filter: { active: true } }, execFor())
  const job = JSON.parse(c.recordFields().job_json ?? '{}')
  check('countDocuments returns the count', value.count === 42 && value.truncated === false, JSON.stringify(value))
  check('uat uses MONGO_URI_UAT', job.uriEnv === 'MONGO_URI_UAT', JSON.stringify(job))
}

{
  const c = newCase()
  const { tool } = await setUp({ config: { limit: 5, maxLimit: 10 } })
  c.stdout(resultLine({ docs: [] }))
  const value = await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'aggregate', pipeline: [{ $match: { a: 1 } }], limit: 999 }, execFor())
  const job = JSON.parse(c.recordFields().job_json ?? '{}')
  check('aggregate ships the pipeline in the job file', JSON.stringify(job.pipeline) === '[{"$match":{"a":1}}]', JSON.stringify(job))
  check('an over-cap limit is clamped to the configured cap and noted', job.limit === 10 && value.limit === 10 && /limit clamped to 10/.test(value.note ?? ''), JSON.stringify({ job: job.limit, note: value.note }))
  check('the configured default honours config for maxTimeMS', job.maxTimeMS === 5000)
  check('config.limit supplies the default limit', job.limit === 10 && value.env === 'staging')
}

{
  const c = newCase()
  const { tool } = await setUp({ config: { limit: 5 } })
  c.stdout(resultLine({ docs: [] }))
  const value = await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  check('a config `limit` is used when the agent passes none', value.limit === 5 && JSON.parse(c.recordFields().job_json ?? '{}').limit === 5, JSON.stringify({ limit: value.limit }))
  check('the job carries the connect timeout for the runner', JSON.parse(c.recordFields().job_json ?? '{}').connectTimeoutMS === 8000)
}

// ---------------------------------------------------------------------------
// execute: rejections before spawn

{
  const c = newCase()
  const { tool } = await setUp()
  check(
    'a write stage nested in $facet is rejected',
    await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'aggregate', pipeline: [{ $facet: { a: [{ $merge: { into: 'x' } }] } }] }, execFor()), /\$merge is a write stage/),
  )
  check('nothing was spawned for the write stage', c.record() === null)
  check('a write op is rejected', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'updateOne', filter: {} }, execFor()), /op must be one of/))
  check('aggregate without a pipeline is rejected', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'aggregate' }, execFor()), /requires `pipeline`/))
  check('pipeline on find is rejected', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find', pipeline: [] }, execFor()), /only valid for aggregate/))
  check('a non-object filter is rejected', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find', filter: [1] }, execFor()), /filter` must be an object/))
  check('an unknown env is rejected', await rejects(() => tool.execute({ env: 'dev', db: 'd', collection: 'c', op: 'find' }, execFor()), /env must be one of/))
  check('an empty collection is rejected', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: '  ', op: 'find' }, execFor()), /collection` must be a non-empty string/))
  check('still nothing spawned', c.record() === null)
}

// ---------------------------------------------------------------------------
// execute: prod approval

{
  const c = newCase()
  const requests = []
  const approval = { request: async (req) => (requests.push(req), 'allowed-once') }
  const { tool } = await setUp({ approval })
  c.stdout(resultLine({ docs: [{ ok: 1 }] }))
  const value = await tool.execute({ env: 'prod', db: 'oho', collection: 'users', op: 'find', filter: { _id: 'a' } }, execFor())
  const req = requests[0] ?? {}
  check('prod asks for approval before running', requests.length === 1 && value.docs?.length === 1)
  check('the approval card names tool, call, and env/db/collection/op', req.toolName === 'mongo_read' && req.callId === 'call-test' && /mongo_read prod/.test(req.reason ?? '') && /db=oho/.test(req.reason ?? '') && /collection=users/.test(req.reason ?? '') && /op=find/.test(req.reason ?? ''), JSON.stringify(req.reason))
  check('the approval card shows the filter', /_id/.test(req.reason ?? '') && req.displayReason?.en === req.reason)
  check('the approval card shows limit, projection, and sort', req.reason.includes('limit=20'), req.reason)
  check('the approval request carries the agent and a signal', req.agent === agent && !!req.signal)
  check('prod uses MONGO_URI_PROD', JSON.parse(c.recordFields().job_json ?? '{}').uriEnv === 'MONGO_URI_PROD')
}

{
  const c = newCase()
  const requests = []
  const approval = { request: async (req) => (requests.push(req), 'allowed-once') }
  const { tool } = await setUp({ approval })
  c.stdout(resultLine({ docs: [] }))
  await tool.execute({ env: 'prod', db: 'd', collection: 'c', op: 'find', filter: {}, projection: { a: 1 }, sort: { a: -1 } }, execFor())
  const reason = requests[0]?.reason ?? ''
  check('projection and sort reach the approval card', reason.includes('projection={"a":1}') && reason.includes('sort={"a":-1}'), reason)
}

{
  const c = newCase()
  let asked = 0
  const approval = { request: async () => ((asked += 1), 'allowed-once') }
  const { tool } = await setUp({ approval })
  const huge = { $or: Array.from({ length: 80 }, (_, i) => ({ field: `v${i}` })) }
  check(
    'prod refuses a filter too long for the card instead of trimming it',
    await rejects(() => tool.execute({ env: 'prod', db: 'd', collection: 'c', op: 'find', filter: huge }, execFor()), /the approval card shows at most 600/),
  )
  check('no approval card was raised for the over-long filter', asked === 0)
  check('nothing spawned', c.record() === null)
}

for (const [outcome, pattern] of [
  ['rejected', /rejected \(by user or session policy\)/],
  ['cancelled', /approval was cancelled/],
  ['unavailable', /no approval answerer/],
]) {
  const c = newCase()
  const { tool } = await setUp({ approval: { request: async () => outcome } })
  const blocked = await rejects(() => tool.execute({ env: 'prod', db: 'd', collection: 'c', op: 'find' }, execFor()), pattern)
  check(`prod stops on approval outcome ${outcome}`, blocked && c.record() === null)
}

{
  const c = newCase()
  const { tool } = await setUp()
  check('prod fails closed without an approval service', await rejects(() => tool.execute({ env: 'prod', db: 'd', collection: 'c', op: 'find' }, execFor()), /approval service.*failing closed/))
  check('nothing spawned', c.record() === null)
}
{
  const c = newCase()
  const { tool } = await setUp({ approval: { request: async () => 'allowed-once' } })
  check('prod needs an owning agent', await rejects(() => tool.execute({ env: 'prod', db: 'd', collection: 'c', op: 'find' }, {}), /owning agent/))
  check('nothing spawned', c.record() === null)
}
{
  const c = newCase()
  const approval = {
    request: async () => {
      throw new Error('must not be called for staging')
    },
  }
  const { tool } = await setUp({ approval })
  c.stdout(resultLine({ docs: [] }))
  const value = await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  check('staging never asks for approval', value.env === 'staging' && c.record() !== null)
}

// ---------------------------------------------------------------------------
// execute: failure paths stay redacted

const secretUri = 'mongodb+srv://alice:sup3rsecret@cluster0.example.net/oho'
{
  const c = newCase()
  const { tool } = await setUp()
  c.stderr(`bws: connection error ${secretUri}\n`)
  c.exit(1)
  let message = ''
  try {
    await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  } catch (error) {
    message = error.message
  }
  check('a child failure surfaces a redacted error', /mongo_read failed/.test(message) && !message.includes('sup3rsecret') && !message.includes('cluster0.example.net') && message.includes('[redacted]'), message)
}
{
  const c = newCase()
  const { tool } = await setUp()
  c.stdout(errorLine(`Authentication failed for ${secretUri}`))
  let message = ''
  try {
    await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  } catch (error) {
    message = error.message
  }
  check('a child-reported error marker is redacted too', /mongo_read failed: Authentication failed/.test(message) && !message.includes('sup3rsecret') && message.includes('[redacted]'), message)
}
{
  const c = newCase()
  const { tool } = await setUp({ timeoutMs: 300 })
  c.sleep(5)
  let message = ''
  const started = Date.now()
  try {
    await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  } catch (error) {
    message = error.message
  }
  const elapsed = Date.now() - started
  check('a hanging child is killed and reported as a timeout', /timed out after 300ms/.test(message), message)
  check('the timeout returns promptly instead of waiting for the grandchild pipes to close', elapsed < 2000, `${elapsed}ms`)
}
{
  const c = newCase()
  const { tool } = await setUp({ timeoutMs: 5000 })
  c.sleep(5)
  const controller = new AbortController()
  controller.abort()
  let message = ''
  const started = Date.now()
  try {
    await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor({ signal: controller.signal }))
  } catch (error) {
    message = error.message
  }
  check('an aborted call is cancelled and killed', /cancelled/.test(message), message)
  check('an aborted call returns promptly', Date.now() - started < 2000, `${Date.now() - started}ms`)
}
{
  const c = newCase()
  const { tool } = await setUp()
  check('a silent child reports "no result marker"', await rejects(() => tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor()), /no result marker/))
}
{
  const c = newCase()
  const { tool } = await setUp({ config: { maxBuffer: 200 } })
  c.stdout(`${'x'.repeat(4000)}\n`)
  c.sleep(5)
  let message = ''
  const started = Date.now()
  try {
    await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor())
  } catch (error) {
    message = error.message
  }
  check('an oversized child output is cut off and reported', /exceeded the buffer/.test(message), message)
  check('the buffer overflow kills the child group instead of waiting', Date.now() - started < 2000, `${Date.now() - started}ms`)
}
{
  const { ctx, tools } = fakeCtx()
  apply(ctx, { bwsrPath: path.join(root, 'missing-bwsr') })
  check(
    'a missing bwsr is reported without a stack-trace hunt',
    await rejects(() => tools[0].execute({ env: 'staging', db: 'd', collection: 'c', op: 'find' }, execFor()), /bwsr not found on PATH/),
  )
}

// ---------------------------------------------------------------------------
// execute: output cap

{
  const c = newCase()
  const { tool } = await setUp({ config: { maxOutputBytes: 600 } })
  c.stdout(resultLine({ docs: Array.from({ length: 30 }, (_, i) => ({ i, pad: 'x'.repeat(60) })) }))
  const value = await tool.execute({ env: 'staging', db: 'd', collection: 'c', op: 'find', limit: 30 }, execFor())
  const rendered = tool.output.render({}, value)[0].text
  check('execute caps the payload and flags truncation', value.truncated === true && value.docs.length < 30 && value.bytes <= 600, JSON.stringify({ kept: value.docs.length, bytes: value.bytes }))
  check('the rendered content respects the cap', Buffer.byteLength(rendered) <= 700, String(Buffer.byteLength(rendered)))
}

// ---------------------------------------------------------------------------
// runner source: syntax + real mongosh error path (no server, no secret)

{
  const runnerPath = path.join(root, 'check-runner.js')
  fs.writeFileSync(runnerPath, RUNNER_SOURCE)
  let syntaxOk = true
  try {
    execFileSync(process.execPath, ['--check', runnerPath], { stdio: 'pipe' })
  } catch (error) {
    syntaxOk = false
    console.log(String(error.stderr ?? error))
  }
  check('the mongosh runner source parses as JavaScript', syntaxOk)
  check('the runner reads the URI from an env var, never from argv', /process\.env\[job\.uriEnv\]/.test(RUNNER_SOURCE) && !/mongoose|mongodb:\/\//i.test(RUNNER_SOURCE))
  check('the runner appends a $limit stage to aggregate', /\$limit: job\.limit/.test(RUNNER_SOURCE))
  check('the runner scrubs the URI value out of its own errors', /split\(SECRET\)/.test(RUNNER_SOURCE))
}

// Runs the real RUNNER_SOURCE in a vm with stubbed mongosh globals, so the success paths (find /
// countDocuments / aggregate argument shapes) are covered without a database.
async function runRunnerInVm(job, options = {}) {
  const prints = []
  const calls = { find: [], countDocuments: [], aggregate: [], connect: [] }
  const docs = options.docs ?? [{ _id: { $oid: '65f0' }, name: 'x' }]
  const collection = {
    find: (...args) => (calls.find.push(args), { toArray: async () => docs }),
    countDocuments: (...args) => (calls.countDocuments.push(args), Promise.resolve(42)),
    aggregate: (...args) => (calls.aggregate.push(args), { toArray: async () => docs }),
  }
  const database = { getCollection: (name) => ((calls.collection = name), collection) }
  const env = { DSH_MONGO_READ_JOB: '/tmp/job.json' }
  if (job.uriEnv) env[job.uriEnv] = options.uri ?? 'mongodb://user:pw@cluster.example.net/db'
  const sandbox = {
    fs: { readFileSync: () => JSON.stringify(job) },
    EJSON: {
      parse: (text) => JSON.parse(text),
      stringify: (value, replacer, space, stringifyOptions) => ((calls.ejsonOptions = stringifyOptions), JSON.stringify(value)),
    },
    print: (line) => prints.push(line),
    process: { env },
    connect: (uri) => {
      calls.connect.push(uri)
      if (options.connectError) throw options.connectError
      return { getSiblingDB: (name) => ((calls.database = name), database) }
    },
  }
  const context = vm.createContext(sandbox)
  await vm.runInContext(RUNNER_SOURCE, context)
  return { prints, calls }
}

const baseJob = { env: 'staging', uriEnv: 'MONGO_URI_STAGING', db: 'oho', collection: 'users', limit: 20, maxTimeMS: 5000, connectTimeoutMS: 8000 }
const parsedMarker = (prints) => {
  const line = prints.find((l) => l.startsWith(RESULT_MARK) || l.startsWith(ERROR_MARK))
  if (!line) return null
  return { mark: line.startsWith(RESULT_MARK) ? 'result' : 'error', value: JSON.parse(line.slice(line.indexOf(' ') + 1)) }
}

{
  const { prints, calls } = await runRunnerInVm({ ...baseJob, op: 'find', filter: { email: 'a@b.c' }, projection: { email: 1 }, sort: { _id: 1 } })
  const marker = parsedMarker(prints)
  check('runner find: succeeds and emits the result marker', marker?.mark === 'result' && marker.value.docs?.length === 1, JSON.stringify(prints))
  const [query, projection, options] = calls.find[0] ?? []
  check('runner find: query is the first argument', JSON.stringify(query) === '{"email":"a@b.c"}', JSON.stringify(query))
  check('runner find: projection is the SECOND argument, not the options bag', JSON.stringify(projection) === '{"email":1}', JSON.stringify(projection))
  check(
    'runner find: limit/maxTimeMS/sort travel in the THIRD argument',
    JSON.stringify(options) === '{"limit":20,"batchSize":20,"maxTimeMS":5000,"sort":{"_id":1}}',
    JSON.stringify(options),
  )
  check('runner find: connect gets the URI with a selection timeout', /serverSelectionTimeoutMS=8000$/.test(calls.connect[0]), calls.connect[0])
  check('runner emits via relaxed EJSON', calls.ejsonOptions?.relaxed === true)
  check('runner selects the requested db and collection', calls.database === 'oho' && calls.collection === 'users')
}

{
  const { prints, calls } = await runRunnerInVm({ ...baseJob, op: 'find', filter: {} })
  const [, projection, options] = calls.find[0] ?? []
  check('runner find: no projection means an undefined second argument', projection === undefined, JSON.stringify(projection))
  check('runner find: no sort means no sort key in options', options && !('sort' in options), JSON.stringify(options))
  check('runner find: with no projection it still returns the full documents', parsedMarker(prints)?.value.docs?.[0]?.name === 'x')
}

{
  const { prints, calls } = await runRunnerInVm({ ...baseJob, op: 'countDocuments', filter: { active: true } })
  const [query, options] = calls.countDocuments[0] ?? []
  check('runner countDocuments: query then options', JSON.stringify(query) === '{"active":true}' && JSON.stringify(options) === '{"maxTimeMS":5000}', JSON.stringify(calls.countDocuments[0]))
  check('runner countDocuments: emits the count', parsedMarker(prints)?.value.count === 42)
}

{
  const { prints, calls } = await runRunnerInVm({ ...baseJob, op: 'aggregate', pipeline: [{ $match: { a: 1 } }], limit: 7 })
  const [pipeline, options] = calls.aggregate[0] ?? []
  check('runner aggregate: appends a $limit stage', JSON.stringify(pipeline) === '[{"$match":{"a":1}},{"$limit":7}]', JSON.stringify(pipeline))
  check('runner aggregate: refuses disk spilling and caps the time', JSON.stringify(options) === '{"maxTimeMS":5000,"allowDiskUse":false}', JSON.stringify(options))
  check('runner aggregate: succeeds through the result marker', parsedMarker(prints)?.mark === 'result')
}

{
  const { prints, calls } = await runRunnerInVm({ ...baseJob, op: 'find', filter: {} })
  check('runner: a URI without a query gets ?serverSelectionTimeoutMS', calls.connect[0] === 'mongodb://user:pw@cluster.example.net/db?serverSelectionTimeoutMS=8000', calls.connect[0])
  const { calls: calls2 } = await runRunnerInVm({ ...baseJob, op: 'find', filter: {} }, { uri: 'mongodb+srv://h/db?retryWrites=true' })
  check('runner: a URI that already has options gets &serverSelectionTimeoutMS', calls2.connect[0] === 'mongodb+srv://h/db?retryWrites=true&serverSelectionTimeoutMS=8000', calls2.connect[0])
  const { calls: calls3 } = await runRunnerInVm({ ...baseJob, connectTimeoutMS: undefined, op: 'find', filter: {} })
  check('runner: no connect timeout configured leaves the URI untouched', calls3.connect[0] === 'mongodb://user:pw@cluster.example.net/db', calls3.connect[0])
}

{
  const secretUri = 'mongodb://alice:sup3rsecret@cluster.example.net/oho'
  const { prints } = await runRunnerInVm(
    { ...baseJob, op: 'find', filter: {} },
    { uri: secretUri, connectError: new Error(`connection to ${secretUri} failed`) },
  )
  const marker = parsedMarker(prints)
  check('runner: a failing connect emits the error marker', marker?.mark === 'error', JSON.stringify(prints))
  check('runner: the error marker has the URI scrubbed out', !JSON.stringify(marker).includes('sup3rsecret') && JSON.stringify(marker).includes('[redacted]'), JSON.stringify(marker))
}

{
  const { prints } = await runRunnerInVm({ ...baseJob, uriEnv: undefined, op: 'find', filter: {} })
  const marker = parsedMarker(prints)
  check('runner: a job without uriEnv fails cleanly', marker?.mark === 'error' && /job has no uriEnv/.test(marker.value.message), JSON.stringify(prints))
}

{
  const hasMongosh = (() => {
    try {
      execFileSync('mongosh', ['--version'], { stdio: 'pipe' })
      return true
    } catch {
      return false
    }
  })()
  if (!hasMongosh) {
    console.log('SKIP mongosh is not installed; runner integration check skipped')
  } else {
    const jobPath = path.join(root, 'runner-job.json')
    fs.writeFileSync(jobPath, JSON.stringify({ env: 'staging', uriEnv: 'MONGOREAD_TEST_URI', db: 'oho', collection: 'users', op: 'find', filter: {}, limit: 1, maxTimeMS: 500 }))
    const runnerPath = path.join(root, 'real-runner.js')
    fs.writeFileSync(runnerPath, RUNNER_SOURCE)
    const run = spawnSync('mongosh', ['--nodb', '--quiet', '--norc', '--file', runnerPath], {
      encoding: 'utf8',
      env: {
        ...process.env,
        DSH_MONGO_READ_JOB: jobPath,
        MONGOREAD_TEST_URI: 'mongodb://alice:sup3rsecret@127.0.0.1:1/oho?serverSelectionTimeoutMS=400',
      },
      timeout: 20000,
    })
    const out = String(run.stdout ?? '')
    const marker = out.split('\n').find((line) => line.startsWith(ERROR_MARK) || line.startsWith(RESULT_MARK))
    const parsed = marker ? JSON.parse(marker.slice(marker.indexOf(' ') + 1)) : null
    check(
      'the real mongosh runner emits an error marker for an unreachable server',
      !!marker && marker.startsWith(ERROR_MARK) && /ECONNREFUSED|Server selection/i.test(parsed?.message ?? ''),
      String(marker).slice(0, 200),
    )
    check('the runner error does not echo the URI credentials', !`${out}${run.stderr ?? ''}`.includes('sup3rsecret'))
  }
}

// ---------------------------------------------------------------------------
// package shape

{
  const pkg = JSON.parse(fs.readFileSync(new URL('./package.json', import.meta.url), 'utf8'))
  check('package name and module type', pkg.name === '@local/dsh-mongo-read' && pkg.type === 'module' && pkg.private === true)
  check('package declares no dependencies', !pkg.dependencies && !pkg.peerDependencies && !pkg.devDependencies, JSON.stringify({ d: pkg.dependencies, p: pkg.peerDependencies, dev: pkg.devDependencies }))
  check('package exports the entry and the bundle patch', pkg.exports['.'] === './index.js' && pkg.dsh.bundle.patch === './cordis.patch.yml')
  const patch = fs.readFileSync(new URL(pkg.dsh.bundle.patch, import.meta.url), 'utf8')
  const expectedPatch =
    "- insert:\n    - id: mongo-read\n      name: '@local/dsh-mongo-read'\n      config: { bwsrPath: bwsr, timeoutMs: 30000 }\n"
  check('the bundle patch inserts exactly the mongo-read row', patch === expectedPatch, JSON.stringify(patch))
}

await fsp.rm(root, { recursive: true, force: true })

console.log(`\n${total - failed}/${total} passed`)
process.exit(failed ? 1 : 0)

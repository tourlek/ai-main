#!/usr/bin/env bun
// omp-orca-role — minimal Orca role-session controller for review/verify workers.
//
// One job lifecycle lives in <workspace>/.scratch/omp-orca-roles/<job>/:
//   start review|verify --task-file P --scope P [--scope P ...] [--base REF] [--from H] [--run R]
//   wait  JOB [--timeout-ms N]     event-driven via `orchestration check --wait`
//   status JOB                     reads state.json + worker-show only
//   release JOB                    native worker-release, only for settled+retained workers
//
// The controller never creates workspaces/worktrees, never changes branches, never
// kills workers, never acks or answers messages it did not validate, and never
// substitutes terminal close for orchestration cleanup. Outcome semantics per the
// coordinator contract: a `succeeded` worker_done means the ROLE LIFECYCLE
// completed — for review the verdict (clean | findings | blocked, with severity +
// file:line evidence) lives in result.json and is never collapsed into
// "code approved"; for verify a failed required check or blocked required proof is
// reported as failed, never green.

import {
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  existsSync,
  rmSync,
  writeFileSync,
  realpathSync,
  readlinkSync,
} from "node:fs";
import { dirname, isAbsolute, join, relative, resolve } from "node:path";

// ---------------------------------------------------------------------------
// constants

const STATE_ROOT = ".scratch/omp-orca-roles";
const LAUNCHER_BY_ROLE: Record<string, string> = { review: "omp-review", verify: "omp-verify" };
const DEFAULT_WAIT_MS = 900000;
const CALL_TIMEOUT_MS = 120000;
const TASK_FILE_MAX = 200_000;
const SPEC_MAX = 64_000;
const WALK_FILE_MAX = 20_000;
const WALK_DEPTH_MAX = 16;
const RAW_ECHO_MAX = 4000;
const HASH_LIST_MAX = 400;
const SELECTOR_PREFIXES = ["path:", "id:", "identity:", "name:", "branch:", "issue:"];
const SKIP_DIRS: Record<string, true> = { ".git": true, node_modules: true };
const USAGE_HINT = "see `omp-orca-role --help`";

type Role = "review" | "verify";

// ---------------------------------------------------------------------------
// output + small helpers

function out(obj: unknown, code = 0): never {
  console.log(JSON.stringify(obj, null, 2));
  process.exit(code);
}
function fail(code: string, message: string, recover: string, extra: Record<string, unknown> = {}): never {
  out({ ok: false, error: { code, message, recover }, ...extra }, 1);
}
function nowIso(): string {
  return new Date().toISOString();
}
function sha256Bytes(data: Uint8Array): string {
  const h = new Bun.CryptoHasher("sha256");
  h.update(data);
  return h.digest("hex");
}
function sha256Text(text: string): string {
  return sha256Bytes(new TextEncoder().encode(text));
}
function clip(text: string, max = RAW_ECHO_MAX): string {
  return text.length > max ? text.slice(0, max) + `…(+${text.length - max} bytes)` : text;
}
function tryParse(text: string): { ok: true; value: unknown } | { ok: false } {
  try {
    return { ok: true, value: JSON.parse(text) as unknown };
  } catch {
    return { ok: false };
  }
}
/** Object.entries typed at the unknown boundary (lib returns any values). */
function entriesOf(obj: object): Array<[string, unknown]> {
  return Object.entries(obj);
}
function valuesOf(obj: object): unknown[] {
  return Object.values(obj);
}

const asString = (v: unknown): string | undefined => (typeof v === "string" && v.length > 0 ? v : undefined);
const isNonEmptyStr = (v: unknown): boolean => typeof v === "string" && v.length > 0;
const isNoSpaceStr = (v: unknown): boolean => typeof v === "string" && v.length > 0 && !/\s/.test(v);
const isAbsPathStr = (v: unknown): boolean => typeof v === "string" && v.startsWith("/");
const isSelectorStr = (v: unknown): boolean => typeof v === "string" && SELECTOR_PREFIXES.some((p) => v.startsWith(p));
const isRunIdStr = (v: unknown): boolean => typeof v === "string" && v.startsWith("run");
const isNonEmptyArray = (v: unknown): boolean => Array.isArray(v) && v.length > 0;

/** BFS for the first object key in `names` whose value passes `pred` (depth ≤ 4). */
function findKey(root: unknown, names: string[], pred: (v: unknown) => boolean = isNonEmptyStr): unknown {
  const queue: Array<{ v: unknown; d: number }> = [{ v: root, d: 0 }];
  const seen = new Set<unknown>();
  while (queue.length) {
    const item = queue.shift();
    if (!item) break;
    const { v, d } = item;
    if (v === null || typeof v !== "object" || seen.has(v) || d > 4) continue;
    seen.add(v);
    for (const [k, val] of entriesOf(v)) {
      if (names.includes(k) && pred(val)) return val;
    }
    for (const val of valuesOf(v)) queue.push({ v: val, d: d + 1 });
  }
  return undefined;
}

// ---------------------------------------------------------------------------
// context / state types

interface OrcaResult {
  action: string;
  argv: string[];
  cwd: string;
  exit: number;
  ms: number;
  stdout: string;
  stderr: string;
}

interface HistoryEntry {
  at: string;
  action: string;
  argv: string[];
  exit: number;
  ms: number;
  stderr: string;
}

interface Ctx {
  cwd: string;
  orcaBase: string[];
  stateDir: string | null;
  raw: Record<string, unknown>;
  history: HistoryEntry[];
}

interface ScopeEntry {
  arg: string;
  realpath: string;
}

type LifecycleStatus = "starting" | "ready" | "settled" | "rejected" | "failed" | "residual" | "released";

interface State {
  job: string;
  role: Role;
  createdAt: string;
  updatedAt: string;
  cwd: string;
  workspace: string;
  worktreeSelector: string;
  worktree: { id: string | null; branch: string | null; head: string | null };
  statePath: string;
  scopes: ScopeEntry[];
  checks: string[];
  taskFile: { arg: string; realpath: string; sha256: string; bytes: number };
  baseRef: string | null;
  run: { id: string; origin: string };
  coordinator: { from: string | null };
  terminal: { handle: string; command: string; title: string } | null;
  worker: { taskId: string | null; dispatchId: string | null } | null;
  spec: { path: string; sha256: string } | null;
  lifecycle: {
    status: LifecycleStatus;
    live: boolean;
    outcome: "succeeded" | "failed" | null;
    retained: boolean;
    acked: boolean;
    settledAt: string | null;
    releasedAt: string | null;
  };
  pendingDelivery: { deliveryId: string; note: string } | null;
  fingerprints: { baseline: string; after: string | null };
}

interface Finger {
  workspace: string;
  scopes: string[];
  branch: string | null;
  head: string | null;
  diffSha256: string | null;
  dirtyCount: number | null;
  files: Record<string, { sha256: string; bytes: number }>;
  symlinks: Record<string, string>;
  truncated: boolean;
  at: string;
}

function saveState(ctx: Ctx, state: State): void {
  if (!ctx.stateDir) return;
  state.updatedAt = nowIso();
  const persistable = { ...state, history: ctx.history.slice(-200), raw: ctx.raw };
  writeFileSync(join(ctx.stateDir, "state.json"), JSON.stringify(persistable, null, 2) + "\n");
}
function saveRaw(ctx: Ctx, action: string, r: OrcaResult): void {
  if (!ctx.stateDir) return;
  const dir = join(ctx.stateDir, "raw");
  mkdirSync(dir, { recursive: true });
  const parsed = tryParse(r.stdout);
  const persistable = parsed.ok
    ? { ...r, stdoutJson: parsed.value, stdoutText: undefined }
    : { ...r, stdoutJson: undefined, stdoutText: clip(r.stdout) };
  writeFileSync(join(dir, `${action}.json`), JSON.stringify(persistable, null, 2) + "\n");
}
/** Load persisted state (written only by this controller). */
function loadStateDir(stateDir: string): { stateDir: string; state: State } {
  const p = join(stateDir, "state.json");
  if (!existsSync(p)) {
    fail("state_missing", `no state.json at ${p}`, "pass the JOB id or the statePath printed by start, from inside the same workspace");
  }
  const state = JSON.parse(readFileSync(p, "utf8")) as State; // our own persisted writer shape
  return { stateDir, state };
}

// ---------------------------------------------------------------------------
// orca invocation

function resolveOrcaBase(): string[] {
  const cli = process.env.ORCA_CLI_COMMAND;
  if (cli && cli.trim()) return cli.trim().split(/\s+/);
  const devRoot = process.env.ORCA_DEV_REPO_ROOT;
  if (devRoot && devRoot.trim()) {
    for (const cand of [join(devRoot, "bin", "orca-dev"), join(devRoot, "orca-dev")]) {
      if (existsSync(cand)) return [cand];
    }
    return ["orca-dev"];
  }
  return [process.platform === "linux" ? "orca-ide" : "orca"];
}

async function orca(ctx: Ctx, action: string, args: string[], timeoutMs = CALL_TIMEOUT_MS): Promise<OrcaResult> {
  const argv = [...ctx.orcaBase, ...args];
  const t0 = Date.now();
  let result: OrcaResult;
  try {
    const proc = Bun.spawn(argv, { cwd: ctx.cwd, stdin: "ignore", stdout: "pipe", stderr: "pipe", timeout: timeoutMs });
    const [stdout, stderr] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text()]);
    const exit = (await proc.exited) ?? -1;
    result = { action, argv, cwd: ctx.cwd, exit, ms: Date.now() - t0, stdout, stderr };
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    result = { action, argv, cwd: ctx.cwd, exit: -1, ms: Date.now() - t0, stdout: "", stderr: msg };
  }
  ctx.raw[action] = { argv: result.argv, exit: result.exit, stderr: clip(result.stderr, 500) };
  ctx.history.push({ at: nowIso(), action, argv, exit: result.exit, ms: result.ms, stderr: clip(result.stderr, 200) });
  return result;
}

/** Orca call that must succeed with a JSON body; failure keeps receipts and exits. */
async function orcaJson(ctx: Ctx, action: string, args: string[], timeoutMs = CALL_TIMEOUT_MS): Promise<{ json: unknown; raw: OrcaResult }> {
  const r = await orca(ctx, action, args, timeoutMs);
  saveRaw(ctx, action, r);
  const parsed = tryParse(r.stdout);
  if (r.exit !== 0 || !parsed.ok) {
    fail("orca_failed", `orca ${args.slice(0, 2).join(" ")} failed (exit ${r.exit}${parsed.ok ? "" : ", non-JSON stdout"})`, "resolve per receipt; do not retry blindly", {
      argv: r.argv,
      exit: r.exit,
      stderr: clip(r.stderr),
      stdout: clip(r.stdout),
      receipt: parsed.ok ? parsed.value : undefined,
    });
  }
  const root = parsed.value;
  if (root && typeof root === "object" && "ok" in root && root.ok === false) {
    fail("orca_failed", `orca ${args.slice(0, 2).join(" ")} reported ok:false (exit 0)`, "resolve per receipt; do not retry blindly", {
      argv: r.argv,
      exit: r.exit,
      receipt: root,
      stdout: clip(r.stdout),
    });
  }
  // Factual envelope (observed on run-create): {id, ok, result: {...}, _meta} — search inside result.
  let body: unknown = root;
  if (root && typeof root === "object" && "result" in root) {
    const res = root.result;
    if (res && typeof res === "object") body = res;
  }
  return { json: body, raw: r };
}

// ---------------------------------------------------------------------------
// workspace + scopes + fingerprint

async function resolveWorkspace(ctx: Ctx): Promise<{ ws: string; selector: string; worktree: { id: string | null; branch: string | null; head: string | null } }> {
  const { json, raw } = await orcaJson(ctx, "worktree-current", ["worktree", "current", "--json"]);
  const wsRaw = findKey(json, ["worktreePath", "rootPath", "workspacePath", "root", "path", "dir"], isAbsPathStr);
  if (!isAbsPathStr(wsRaw)) {
    fail("workspace_unresolved", "could not resolve an absolute workspace path from `orca worktree current --json`", "run from inside the Orca workspace; if the CLI JSON shape differs, record it and re-run", {
      stdout: clip(raw.stdout),
    });
  }
  const ws = realpathSync(wsRaw);
  // Exact selector: the full <repo-id>::<path> worktree id Orca returns (observed: worktree.id),
  // then any explicit selector string, then path:<abs>. Never a bare repo id.
  const wtId = asString(findKey(json, ["id"], (v) => typeof v === "string" && v.includes("::")));
  const selector =
    asString(findKey(json, ["worktreeSelector", "pathSelector", "selector"], isSelectorStr)) ?? (wtId ? `id:${wtId}` : null) ?? asString(findKey(json, ["worktree"], isSelectorStr)) ?? `path:${ws}`;
  return {
    ws,
    selector,
    worktree: {
      id: wtId ?? null,
      branch: asString(findKey(json, ["branch"])) ?? null,
      head: asString(findKey(json, ["head"])) ?? null,
    },
  };
}

/** Exact-string approved check; mechanical rejections only — human authorization is main's job. */
function validateCheck(raw: string): string {
  const cmd = raw.trim();
  if (!cmd) fail("usage", "--check must be a non-empty command", USAGE_HINT);
  if (cmd.includes("*")) fail("check_rejected", `--check contains '*': ${clip(cmd, 200)}`, "explicit exact command strings only — wildcards widen approval");
  if (/[;&|<>`$()\n\r]/.test(cmd)) fail("check_rejected", "check must be a single literal command", "split checks into separate --check arguments");
  if (/(?:^|\s)(?:--fix(?:[=\s]|$)|--update-snapshots?(?:[=\s]|$)|--updateSnapshot(?:[=\s]|$)|-u(?:\s|$))/.test(cmd) ||
      /^(?:npm|pnpm|yarn|bun)\s+(?:install|add|ci|update)(?:\s|$)/.test(cmd) ||
      /^git\s+(?:add|commit|push|checkout|restore|reset|clean)(?:\s|$)/.test(cmd)) {
    fail("check_rejected", "check cannot authorize source/test mutation, dependency installs or Git writes", "return this operation to the main implementer");
  }
  return cmd;
}

/** POSIX single-quote for embedding one argv word inside terminal create --command. */
function shellQuote(s: string): string {
  return "'" + s.replaceAll("'", "'\\''") + "'";
}

function validateScope(cwd: string, ws: string, arg: string): ScopeEntry {
  const p = isAbsolute(arg) ? arg : resolve(cwd, arg);
  let real: string;
  try {
    real = realpathSync(p);
  } catch {
    fail("scope_missing", `scope path does not exist: ${arg}`, "pass an existing file or directory inside the workspace");
  }
  if (real !== ws && !real.startsWith(ws + "/")) {
    fail("scope_escape", `scope escapes the workspace: ${arg} -> ${real}`, "scope paths must stay inside the current Orca workspace (no symlinks out)");
  }
  return { arg, realpath: real };
}

function gitAvailable(ws: string): boolean {
  return Bun.spawnSync(["git", "-C", ws, "rev-parse", "--is-inside-work-tree"], { stdout: "pipe", stderr: "pipe" }).exitCode === 0;
}

function walkFiles(root: string): { files: string[]; symlinks: string[]; truncated: boolean } {
  const files: string[] = [];
  const symlinks: string[] = [];
  const stack: Array<[string, number]> = [[root, 0]];
  while (stack.length) {
    const dir = stack.pop();
    if (!dir) break;
    const [path, depth] = dir;
    let entries;
    try {
      entries = readdirSync(path, { withFileTypes: true });
    } catch (error) {
      fail("scope_unreadable", `cannot fingerprint ${path}: ${String(error)}`, "resolve access or narrow the scope; do not accept partial evidence");
    }
    for (const e of entries) {
      if (files.length + symlinks.length >= WALK_FILE_MAX) return { files, symlinks, truncated: true };
      const full = join(path, e.name);
      if (e.isSymbolicLink()) {
        symlinks.push(full);
      } else if (e.isDirectory()) {
        if (SKIP_DIRS[e.name] || full.includes(`${STATE_ROOT}/`)) continue;
        if (depth >= WALK_DEPTH_MAX) return { files, symlinks, truncated: true };
        stack.push([full, depth + 1]);
      } else if (e.isFile()) {
        files.push(full);
      }
    }
  }
  return { files, symlinks, truncated: false };
}

function fingerprint(ws: string, scopes: ScopeEntry[], git: boolean): Finger {
  const f: Finger = {
    workspace: ws,
    scopes: scopes.map((s) => s.realpath),
    branch: null,
    head: null,
    diffSha256: null,
    dirtyCount: null,
    files: {},
    symlinks: {},
    truncated: false,
    at: nowIso(),
  };
  if (git) {
    const gitOut = (args: string[]): string => Bun.spawnSync(["git", ...args], { cwd: ws, stdout: "pipe", stderr: "pipe" }).stdout.toString();
    f.branch = gitOut(["rev-parse", "--abbrev-ref", "HEAD"]).trim() || null;
    f.head = gitOut(["rev-parse", "HEAD"]).trim() || null;
    f.dirtyCount = gitOut(["status", "--porcelain=v1"]).split("\n").filter((l) => l.trim()).length;
    const diff = Bun.spawnSync(["git", "diff", "HEAD", "--", ...scopes.map((s) => s.realpath)], { cwd: ws, stdout: "pipe", stderr: "pipe" });
    f.diffSha256 = diff.exitCode === 0 ? sha256Bytes(diff.stdout) : null;
  }
  for (const scope of scopes) {
    let st;
    try {
      st = statSync(scope.realpath);
    } catch {
      continue;
    }
    if (st.isFile()) {
      f.files[scope.realpath] = { sha256: sha256Bytes(readFileSync(scope.realpath)), bytes: st.size };
      continue;
    }
    const w = walkFiles(scope.realpath);
    f.truncated = f.truncated || w.truncated;
    for (const file of w.files) {
      const s = statSync(file);
      f.files[file] = { sha256: sha256Bytes(readFileSync(file)), bytes: s.size };
    }
    for (const link of w.symlinks) {
      let target = "";
      try {
        target = readlinkSync(link);
      } catch {
        target = "<unreadable>";
      }
      f.symlinks[link] = target;
    }
  }
  return f;
}

function diffFingerprints(before: Finger, after: Finger): string[] {
  const diffs: string[] = [];
  if (before.branch !== after.branch) diffs.push(`branch: ${before.branch} -> ${after.branch}`);
  if (before.head !== after.head) diffs.push(`HEAD: ${before.head} -> ${after.head}`);
  if (before.diffSha256 !== after.diffSha256) diffs.push("scoped git diff changed");
  if (before.dirtyCount !== after.dirtyCount) diffs.push(`dirty entries: ${before.dirtyCount} -> ${after.dirtyCount}`);
  for (const p of new Set([...Object.keys(before.files), ...Object.keys(after.files)])) {
    const b = before.files[p];
    const a = after.files[p];
    if (!b) diffs.push(`added: ${p}`);
    else if (!a) diffs.push(`removed: ${p}`);
    else if (b.sha256 !== a.sha256) diffs.push(`modified: ${p}`);
  }
  for (const p of new Set([...Object.keys(before.symlinks), ...Object.keys(after.symlinks)])) {
    if (before.symlinks[p] !== after.symlinks[p]) diffs.push(`symlink changed: ${p}`);
  }
  return diffs;
}

// ---------------------------------------------------------------------------
// concurrency guard

interface LiveAttempt {
  job: string;
  status: string;
}

function scanLiveAttempts(ws: string, role: Role): LiveAttempt[] {
  const root = join(ws, STATE_ROOT);
  if (!existsSync(root)) return [];
  const live: LiveAttempt[] = [];
  for (const job of readdirSync(root)) {
    const p = join(root, job, "state.json");
    if (!existsSync(p)) continue;
    try {
      const s = JSON.parse(readFileSync(p, "utf8")) as State; // our own persisted writer shape
      if (s.lifecycle?.live) live.push({ job, status: s.lifecycle.status });
    } catch {
      // unreadable foreign state: not ours to judge
    }
  }
  return live;
}

function takeLiveLock(stateDir: string, role: Role): void {
  const lock = join(dirname(stateDir), "live.lock");
  try {
    mkdirSync(lock);
    writeFileSync(join(lock, "owner.json"), JSON.stringify({ role, job: stateDir, pid: process.pid, at: nowIso() }));
  } catch {
    fail("concurrent_attempt", `workspace role lock exists at ${lock}`, "inspect and settle the recorded attempt; do not delete a live/unknown lock");
  }
}
function dropLiveLock(stateDir: string): void {
  const lock = join(dirname(stateDir), "live.lock");
  if (!existsSync(join(lock, "owner.json"))) return;
  const owner = JSON.parse(readFileSync(join(lock, "owner.json"), "utf8"));
  if (owner.job === stateDir) rmSync(lock, { recursive: true });
}

// ---------------------------------------------------------------------------
// self-contained handoff spec

function extractCommands(taskText: string): string | null {
  const lines = taskText.split("\n");
  const idx = lines.findIndex((l) => /^#{1,6}\s*commands?\b/i.test(l.trim()));
  if (idx === -1) return null;
  const end = lines.findIndex((l, i) => i > idx && /^#{1,6}\s/.test(l));
  const commands = lines.slice(idx + 1, end === -1 ? lines.length : end).join("\n").trim();
  return commands || null;
}

function buildSpec(opts: { role: Role; ws: string; selector: string; scopes: ScopeEntry[]; checks: string[]; taskText: string; commands: string | null; baseRef: string | null; finger: Finger; git: boolean }): string {
  const trackedOut = opts.git
    ? Bun.spawnSync(["git", "-C", opts.ws, "ls-files", "--", ...opts.scopes.map((s) => s.realpath)], { cwd: opts.ws, stdout: "pipe", stderr: "pipe" }).stdout.toString()
    : "";
  const tracked = new Set(trackedOut.split("\n").filter(Boolean));
  const allPaths = Object.keys(opts.finger.files);
  const untracked = allPaths.filter((p) => !tracked.has(relative(opts.ws, p)));
  const hashSource = untracked.length > 0 ? untracked : allPaths;
  const hashLines = hashSource.map((p) => `- ${relative(opts.ws, p)} sha256=${opts.finger.files[p].sha256} bytes=${opts.finger.files[p].bytes}`).slice(0, HASH_LIST_MAX);
  const acceptance =
    opts.role === "review"
      ? [
          `- Verdict must be exactly one of: clean | findings | blocked, with severity and file:line evidence per finding.`,
          `- A \`--outcome succeeded\` worker_done means the REVIEW COMPLETED — it never means the code is approved.`,
          `- No mutation of any scoped file (the coordinator fingerprints before/after and rejects mutated results).`,
        ]
      : [
          `- Report every command you ran with its exit code and result, plus smoke evidence for the changed surface.`,
          `- A failed required check or a blocked required proof is \`--outcome failed\`; never report green verification from it.`,
          `- List explicit blockers; do not fabricate a pass to close the task.`,
          `- No mutation of any scoped file (the coordinator fingerprints before/after and rejects mutated results).`,
        ];
  const spec = [
    `# Role: ${opts.role} (read/source-only)`,
    ``,
    `## Target`,
    `- Workspace: ${opts.ws}`,
    `- Worktree selector: ${opts.selector}`,
    `- Scope (only these paths are in scope):`,
    ...opts.scopes.map((s) => `  - ${s.realpath}`),
    ``,
    `## Requirements (verbatim from task file)`,
    opts.taskText.trimEnd(),
    ``,
    ...(opts.commands ? [`## Commands (from task file; run read-only/safe ones as needed)`, opts.commands, ``] : []),
    ...(opts.checks.length
      ? [
          `## Approved checks (run verbatim)`,
          `These exact command strings are pre-approved in the role-local Bash config (coordinator-authorized):`,
          ...opts.checks.map((c) => `- ${c}`),
          `Run them verbatim. If you need anything beyond them, ask the coordinator first — never approve tools locally.`,
          ``,
        ]
      : []),
    `## Constraints`,
    `- Read/source-only: do NOT edit, create, delete, stage, commit, push, or fix any source/test/config file.`,
    `- Stay inside the workspace and the listed scope; no new worktrees; no branch changes.`,
    `- Do not modify approval configuration: role actions are unattended, while out-of-scope Bash is explicitly denied.`,
    `- Findings must cite file:line evidence.`,
    `- If a blocking question arises, ask it via orchestration and idle; do not guess.`,
    ``,
    `## Reporting protocol (mandatory)`,
    `1. BEFORE worker_done, send a status message carrying the COMPLETE machine-readable report:`,
    `   ORCA orchestration send --type status --subject "omp-role-report" --body '<JSON>' with the same task/dispatch/from/capability fields as your live preamble.`,
    `   Body JSON shape: {"role":"${opts.role}","verdict":"clean|findings|passed|failed|blocked","findings":[{"severity","file","line","note"}],"commands":[{"command","exitCode","result"}],"smoke":...,"blockers":[...],"coverage":...}`,
    `   Review verdicts: clean | findings | blocked. Verify verdicts: passed | failed | blocked. Include ALL findings/check results here, not only a summary. Never expose private thinking.`,
    `2. THEN send worker_done exactly once: three-sentence executive summary + explicit --outcome succeeded or --outcome failed (lifecycle completion, not a verdict).`,
    ``,
    `## Baseline at dispatch (coordinator-verified; the result is rejected if this changes)`,
    `- Branch: ${opts.finger.branch ?? "(non-git folder workspace)"}  HEAD: ${opts.finger.head ?? "n/a"}`,
    `- Dirty entries: ${opts.finger.dirtyCount ?? "n/a"}  Scoped git diff sha256: ${opts.finger.diffSha256 ?? "n/a"}`,
    `- Scoped files fingerprinted: ${allPaths.length}${opts.finger.truncated ? " (TRUNCATED)" : ""}`,
    ...(opts.baseRef ? [`- Review base ref: ${opts.baseRef}`] : []),
    `Content hashes (hashes only; contents are never dumped): ${untracked.length} untracked of ${allPaths.length} scoped files:`,
    ...hashLines,
    ...(hashSource.length > hashLines.length ? [`- …hash list truncated at ${hashLines.length} entries`] : []),
    ``,
    `## Observable acceptance`,
    ...acceptance,
  ].join("\n");
  if (spec.length > SPEC_MAX) {
    fail("spec_too_large", `self-contained spec is ${spec.length} bytes (max ${SPEC_MAX})`, "shrink the task file or scope");
  }
  return spec;
}

// ---------------------------------------------------------------------------
// argument parsing

function parseArgs(argv: string[]): { flags: Record<string, string[]>; _: string[] } {
  const flags: Record<string, string[]> = {};
  const positional: string[] = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) {
      const eq = a.indexOf("=");
      const name = eq === -1 ? a : a.slice(0, eq);
      const val = eq === -1 ? argv[++i] : a.slice(eq + 1);
      if (val === undefined) fail("usage", `missing value for ${name}`, USAGE_HINT);
      (flags[name] ??= []).push(val);
    } else {
      positional.push(a);
    }
  }
  return { flags, _: positional };
}
function one(flags: Record<string, string[]>, name: string): string | undefined {
  const v = flags[name];
  if (v && v.length > 1) fail("usage", `--${name.slice(2)} given more than once`, USAGE_HINT);
  return v?.[0];
}

// ---------------------------------------------------------------------------
// start

async function cmdStart(argv: string[]): Promise<never> {
  const { flags, _ } = parseArgs(argv);
  const roleArg = _[0];
  if (roleArg !== "review" && roleArg !== "verify") fail("usage", `first argument must be review|verify (got ${roleArg ?? "none"})`, USAGE_HINT);
  const role: Role = roleArg;
  const cwd = process.cwd();
  const taskFileArg = one(flags, "--task-file");
  const scopeArgs = flags["--scope"] ?? [];
  const baseRef = one(flags, "--base") ?? null;
  const from = one(flags, "--from") ?? null;
  const runExplicit = one(flags, "--run") ?? null;
  const checks = (flags["--check"] ?? []).map(validateCheck);
  if (role === "review" && checks.length) {
    fail("usage", "--check is verify-only: the review launcher approves no checks (omp-review --check exits 2)", "run checks under verify; review findings come from read-only inspection");
  }
  if (!taskFileArg) fail("usage", "--task-file PATH is required", USAGE_HINT);
  if (scopeArgs.length === 0) fail("usage", "at least one --scope PATH is required", USAGE_HINT);

  const ctx: Ctx = { cwd, orcaBase: resolveOrcaBase(), stateDir: null, raw: {}, history: [] };

  // task file is validated before any Orca call
  const taskPath = isAbsolute(taskFileArg) ? taskFileArg : resolve(cwd, taskFileArg);
  if (!existsSync(taskPath)) fail("task_file_missing", `task file not found: ${taskPath}`, "pass an existing requirements file");
  const taskBytes = statSync(taskPath).size;
  if (taskBytes > TASK_FILE_MAX) fail("task_file_too_large", `task file is ${taskBytes} bytes (max ${TASK_FILE_MAX})`, "shrink the requirements file");
  const taskText = readFileSync(taskPath, "utf8");
  if (!taskText.trim()) fail("task_file_empty", `task file is empty: ${taskPath}`, "write the requirements first");

  const { ws, selector, worktree } = await resolveWorkspace(ctx);
  const scopes = scopeArgs.map((s) => validateScope(cwd, ws, s));
  if (baseRef) {
    if (!gitAvailable(ws)) fail("base_requires_git", `--base ${baseRef} requires a git workspace`, "drop --base for folder workspaces");
    const chk = Bun.spawnSync(["git", "-C", ws, "rev-parse", "--verify", baseRef], { stdout: "pipe", stderr: "pipe" });
    if (chk.exitCode !== 0) fail("base_ref_missing", `base ref not found: ${baseRef}`, "pass a ref that exists in this workspace");
  }

  // launcher must exist before any terminal is created
  const launcher = resolve(import.meta.dir, LAUNCHER_BY_ROLE[role]);
  if (!existsSync(launcher)) fail("launcher_missing", `role launcher not found: ${launcher}`, "reinstall the ai-main role launchers; do not copy them into application repos");

  // job + state dir + concurrency guard
  const liveOthers = scanLiveAttempts(ws, role);
  if (liveOthers.length) {
    fail("concurrent_attempt", "a role check is already live in this workspace", "settle or resolve it before another role check", { live: liveOthers });
  }
  const stamp = nowIso().replace(/\.\d+Z$/, "").replace(/[-:]/g, "");
  const job = `${role}-${stamp}-${Math.random().toString(36).slice(2, 8)}`;
  const stateDir = join(ws, STATE_ROOT, job);
  mkdirSync(stateDir, { recursive: true });
  ctx.stateDir = stateDir;
  takeLiveLock(stateDir, role);

  const state: State = {
    job,
    role,
    createdAt: nowIso(),
    updatedAt: nowIso(),
    cwd,
    workspace: ws,
    worktreeSelector: selector,
    worktree,
    statePath: stateDir,
    scopes,
    checks,
    taskFile: { arg: taskFileArg, realpath: taskPath, sha256: sha256Text(taskText), bytes: taskBytes },
    baseRef,
    run: { id: runExplicit ?? "", origin: runExplicit ? "explicit" : "" },
    coordinator: { from },
    terminal: null,
    worker: null,
    spec: null,
    lifecycle: { status: "starting", live: true, outcome: null, retained: false, acked: false, settledAt: null, releasedAt: null },
    pendingDelivery: null,
    fingerprints: { baseline: "baseline.json", after: null },
  };
  saveState(ctx, state);

  try {
    // baseline fingerprint (scoped hashes incl. untracked; diff hashed, never dumped)
    const git = gitAvailable(ws);
    const finger = fingerprint(ws, scopes, git);
    if (finger.truncated) fail("scope_incomplete", "scope fingerprint was truncated", "choose smaller explicit scopes; partial source coverage is not accepted");
    writeFileSync(join(stateDir, "baseline.json"), JSON.stringify(finger, null, 2) + "\n");

    // Run binding: explicit --run wins; else ambient bound Run; else create with --from; else actionable failure
    if (runExplicit) {
      state.run = { id: runExplicit, origin: "explicit" };
    } else {
      const rcArgs = ["orchestration", "run-current", "--json"];
      if (from) rcArgs.push("--from", from);
      const rc = await orca(ctx, "run-current", rcArgs);
      saveRaw(ctx, "run-current", rc);
      const rcParsed = tryParse(rc.stdout);
      const boundId = rcParsed.ok
        ? (asString(findKey(rcParsed.value, ["runId", "run_id", "runID", "run"], isRunIdStr)) ?? asString(findKey(rcParsed.value, ["id"], isRunIdStr)))
        : undefined;
      if (rc.exit === 0 && rcParsed.ok && boundId) {
        state.run = { id: boundId, origin: "run-current" };
      } else if (from) {
        const created = await orcaJson(ctx, "run-create", [
          "orchestration",
          "run-create",
          "--objective",
          `${role} session for ${ws} (scope: ${scopes.map((s) => s.arg).join(", ")})`,
          "--from",
          from,
          "--json",
        ]);
        const newId = asString(findKey(created.json, ["runId", "run_id", "runID", "run"], isRunIdStr)) ?? asString(findKey(created.json, ["id"], isRunIdStr));
        if (!newId) {
          state.lifecycle.status = "failed";
          state.lifecycle.live = false;
          dropLiveLock(stateDir);
          saveState(ctx, state);
          fail("unparseable_receipt", "run-create returned no run id", "inspect state/raw/run-create.json and bind manually with --run", { stdout: clip(created.raw.stdout) });
        }
        state.run = { id: newId, origin: "run-create" };
      } else {
        state.lifecycle.status = "failed";
        state.lifecycle.live = false;
        dropLiveLock(stateDir);
        saveState(ctx, state);
        fail("run_unresolvable", "no Run bound to this terminal and neither --run nor --from was given", "pass --run RUN_ID or --from COORDINATOR_HANDLE, or start from inside an Orca coordinator terminal", {
          runCurrent: clip(rc.stdout),
        });
      }
    }
    saveState(ctx, state);

    // terminal create in the exact workspace, no focus change; approved checks ride the launcher argv
    const title = `omp-${role}-${job}`;
    const launcherCommand = [launcher, ...checks.flatMap(c => ["--check", c])].map(shellQuote).join(" ");
    const tc = await orcaJson(ctx, "terminal-create", ["terminal", "create", "--worktree", selector, "--title", title, "--command", launcherCommand, "--json"]);
    const handle = asString(findKey(tc.json, ["terminalHandle", "handle", "terminal", "id", "sessionId"], isNoSpaceStr));
    if (!handle) {
      state.lifecycle.status = "residual"; // a terminal may now exist — never retry blindly
      saveState(ctx, state);
      fail("unparseable_receipt", "terminal create returned no terminal handle", "inspect state/raw/terminal-create.json; resolve manually, do not retry", { stdout: clip(tc.raw.stdout) });
    }
    state.terminal = { handle, command: launcherCommand, title };
    saveState(ctx, state);

    // tui-idle proof (raw receipt kept in state/raw/terminal-wait.json)
    const idle = await orcaJson(ctx, "terminal-wait", ["terminal", "wait", "--terminal", handle, "--for", "tui-idle", "--timeout-ms", "60000", "--json"]);
    if (findKey(idle.json, ["satisfied"], v => v === true) !== true) {
      state.lifecycle.status = "residual";
      saveState(ctx, state);
      fail("terminal_not_ready", "TUI readiness was not proven; no prompt was injected", "inspect the exact terminal and receipt before retrying readiness", { statePath: stateDir });
    }
    state.lifecycle.status = "ready";
    saveState(ctx, state);

    // self-contained spec + supervised worker adoption
    const spec = buildSpec({ role, ws, selector, scopes, checks, taskText, commands: extractCommands(taskText), baseRef, finger, git });
    const specPath = join(stateDir, "spec.txt");
    writeFileSync(specPath, spec + "\n");
    state.spec = { path: specPath, sha256: sha256Text(spec) };
    saveState(ctx, state);

    const wsArgs = ["orchestration", "worker-start", "--spec", spec, "--terminal", handle, "--worktree", selector, "--run", state.run.id, "--json"];
    if (from) wsArgs.push("--from", from);
    const wsr = await orcaJson(ctx, "worker-start", wsArgs);
    const taskId = asString(findKey(wsr.json, ["taskId", "task_id", "taskID"], isNoSpaceStr)) ?? asString(findKey(wsr.json, ["task"], isNoSpaceStr));
    const dispatchId = asString(findKey(wsr.json, ["dispatchId", "dispatch_id", "dispatchID", "dispatch"], isNoSpaceStr));
    if (!dispatchId) {
      state.lifecycle.status = "residual"; // Task/supervision state may exist — never relaunch blindly
      saveState(ctx, state);
      fail("unparseable_receipt", "worker-start returned no dispatch id", "inspect state/raw/worker-start.json (failedStage/residualResources); resolve manually, do not relaunch", { stdout: clip(wsr.raw.stdout) });
    }
    state.worker = { taskId: taskId ?? null, dispatchId };
    saveState(ctx, state);

    out({
      ok: true,
      command: "start",
      job,
      role,
      status: "ready",
      statePath: stateDir,
      workspace: ws,
      worktreeSelector: selector,
      runId: state.run.id,
      runOrigin: state.run.origin,
      terminal: { handle, command: launcherCommand, title },
      checks,
      taskId: state.worker.taskId,
      dispatchId,
      tuiIdle: true,
    });
  } catch (e: unknown) {
    state.lifecycle.status = state.lifecycle.status === "starting" ? "residual" : state.lifecycle.status;
    saveState(ctx, state);
    const msg = e instanceof Error ? e.message : String(e);
    fail("internal_error", `unexpected failure: ${msg}`, "inspect state.json + state/raw/ for receipts before any retry", { statePath: stateDir });
  }
}

// ---------------------------------------------------------------------------
// job resolution for wait/status/release

async function resolveJob(jobArg: string): Promise<{ stateDir: string; state: State }> {
  if (jobArg.includes("/")) {
    const stateDir = isAbsolute(jobArg) ? jobArg : resolve(process.cwd(), jobArg);
    return loadStateDir(stateDir);
  }
  const ctx: Ctx = { cwd: process.cwd(), orcaBase: resolveOrcaBase(), stateDir: null, raw: {}, history: [] };
  const { ws } = await resolveWorkspace(ctx);
  return loadStateDir(join(ws, STATE_ROOT, jobArg));
}

// ---------------------------------------------------------------------------
// wait

interface CheckRow {
  row: unknown;
  deliveryId: string | undefined;
  type: string | undefined;
  dispatchRef: string | undefined;
  taskRef: string | undefined;
  subject: string | undefined;
  body: string | undefined;
  outcome: string | undefined;
}

function toRows(batch: unknown): CheckRow[] {
  const rows: unknown[] = Array.isArray(batch) ? batch : [];
  return rows.map(raw => {
    const row = raw as Record<string, unknown>;
    const parsed = typeof row.payload === "string" ? tryParse(row.payload) : null;
    const decoded = { ...row, payload: parsed?.ok ? parsed.value : row.payload };
    return {
      row,
      deliveryId: asString(findKey(decoded, ["deliveryId", "delivery_id", "messageId", "id"], isNoSpaceStr)),
      type: asString(findKey(decoded, ["type", "kind", "messageType"])),
      dispatchRef: asString(findKey(decoded, ["dispatchId", "dispatch_id", "dispatchID", "dispatch"], isNoSpaceStr)),
      taskRef: asString(findKey(decoded, ["taskId", "task_id", "taskID", "task"], isNoSpaceStr)),
      subject: asString(findKey(decoded, ["subject"])),
      body: asString(findKey(decoded, ["body", "text", "summary", "content"])),
      outcome: asString(findKey(decoded, ["outcome"])),
    };
  });
}

function reportProblems(value: unknown, state: State): string[] {
  if (!value || typeof value !== "object") return ["missing structured role report"];
  const report = value as Record<string, unknown>;
  const allowed: Record<string, true> = state.role === "review"
    ? { clean: true, findings: true, blocked: true }
    : { passed: true, failed: true, blocked: true };
  const errors: string[] = [];
  if (report.role !== state.role) errors.push("role mismatch");
  if (typeof report.verdict !== "string" || !allowed[report.verdict]) errors.push("invalid verdict");
  if (report.verdict === "findings" && (!Array.isArray(report.findings) || !report.findings.length)) errors.push("findings verdict without findings");
  if (state.role === "verify" && report.verdict === "passed") {
    const commands = Array.isArray(report.commands) ? report.commands as Array<Record<string, unknown>> : [];
    if (!state.checks.length) errors.push("passed verification without approved checks");
    for (const expected of state.checks) {
      const observed = commands.find(c => c.command === expected || c.command === `rtk proxy ${expected}`);
      if (!observed || observed.exitCode !== 0) errors.push(`missing successful check: ${expected}`);
    }
    if (Array.isArray(report.blockers) && report.blockers.length) errors.push("passed verdict with blockers");
  }
  return errors;
}

async function cmdWait(argv: string[]): Promise<never> {
  const { flags, _ } = parseArgs(argv);
  const jobArg = _[0];
  if (!jobArg) fail("usage", "wait JOB is required", USAGE_HINT);
  const timeoutMs = Number(one(flags, "--timeout-ms") ?? DEFAULT_WAIT_MS);
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) fail("usage", "--timeout-ms must be a positive number", USAGE_HINT);
  const { stateDir, state } = await resolveJob(jobArg);
  const ctx: Ctx = { cwd: process.cwd(), orcaBase: resolveOrcaBase(), stateDir, raw: {}, history: [] };

  if (["settled", "rejected", "released"].includes(state.lifecycle.status)) {
    out({ ok: true, command: "wait", job: state.job, role: state.role, status: state.lifecycle.status, outcome: state.lifecycle.outcome, resultPath: join(stateDir, "result.json"), alreadySettled: true });
  }
  if (!state.worker?.dispatchId || !state.terminal?.handle) {
    fail("not_running", `job ${state.job} has no active worker (status ${state.lifecycle.status})`, "check status output and receipts", { status: state.lifecycle.status });
  }
  const dispatchId: string = state.worker.dispatchId;
  const taskId: string | null = state.worker.taskId;
  const isOurs = (r: CheckRow): boolean => r.dispatchRef === dispatchId &&
    (taskId === null || r.taskRef === null || r.taskRef === undefined || r.taskRef === taskId) &&
    asString(findKey(r.row, ["from_handle", "fromHandle"])) === state.terminal!.handle;

  let report: { deliveryId: string; json: unknown; text: string | null } | null = null;
  if (existsSync(join(stateDir, "report.json"))) {
    const saved = JSON.parse(readFileSync(join(stateDir, "report.json"), "utf8"));
    report = { deliveryId: saved.deliveryId, json: saved.reportJson, text: saved.reportText };
  }
  let reportSeen = report !== null;
  let currentDeliveryId: string | null = null;

  const returnUnacked = (status: string, note: string, rows: CheckRow[]): never => {
    const questions = rows.filter((r) => r.type === "question" || r.type === "escalation");
    const unrelated = rows.filter((r) => !isOurs(r) && (r.type === "worker_done" || r.type === "status"));
    state.pendingDelivery = { deliveryId: currentDeliveryId ?? "", note };
    saveState(ctx, state);
    out({
      ok: true,
      command: "wait",
      job: state.job,
      role: state.role,
      status,
      note,
      acked: false,
      deliveryLeftUnacked: true,
      reportSeen,
      questions: questions.map((q) => ({ deliveryId: q.deliveryId, from: asString(findKey(q.row, ["from", "sender"])), body: q.body, raw: q.row })),
      unrelated: unrelated.map((u) => ({ deliveryId: u.deliveryId, type: u.type, dispatchId: u.dispatchRef, body: clip(u.body ?? "") })),
    });
  };
  const timeoutOut = (): never =>
    out({
      ok: true,
      command: "wait",
      job: state.job,
      role: state.role,
      status: "timeout",
      note: reportSeen
        ? "role report received+acked but no authoritative worker_done within the budget; worker still live, nothing settled"
        : "no matching delivery within the budget; worker still live, delivery queue empty",
      acked: false,
      reportSeen,
      reportPath: report ? join(stateDir, "report.json") : null,
    });

  // Event-driven batches only: every iteration blocks in `check --wait`; no sleep/poll loops.
  const deadline = Date.now() + Math.round(timeoutMs);
  for (;;) {
    const remaining = deadline - Date.now();
    if (remaining <= 0) return timeoutOut();
    const checkArgs = ["orchestration", "check", "--wait", "--types", "status,worker_done,escalation,question", "--timeout-ms", String(Math.round(remaining)), "--run", state.run.id, "--json"];
    if (state.coordinator.from) checkArgs.push("--terminal", state.coordinator.from);
    const cr = await orcaJson(ctx, "check-wait", checkArgs, remaining + 30000);
    // Observed live envelope: result:{runId, deliveryId, messages:[...], count, timedOut, ...} —
    // ack targets the whole FIFO batch via result.deliveryId; row ids are message ids.
    const batchAckId = asString(findKey(cr.json, ["deliveryId", "delivery_id"], isNoSpaceStr));
    currentDeliveryId = batchAckId ?? null;
    const rows = toRows(findKey(cr.json, ["messages", "deliveries", "rows", "items", "batch"], isNonEmptyArray));
    if (rows.length === 0) return timeoutOut();

    const questions = rows.filter((r) => r.type === "question" || r.type === "escalation");
    const unrelated = rows.filter((r) => !isOurs(r) && (r.type === "worker_done" || r.type === "status"));
    if (questions.length || unrelated.length) {
      returnUnacked("needs_input", "delivery contains questions/escalations or messages from another dispatch; main must process it — the controller never acks or answers on its behalf", rows);
    }

    const oursStatus = rows.filter((r) => isOurs(r) && r.type === "status");
    const oursDone = rows.filter((r) => isOurs(r) && r.type === "worker_done");
    const oursNoise = rows.filter((r) => isOurs(r) && r.type !== "status" && r.type !== "worker_done");

    const captureReport = (): void => {
      const rep = oursStatus.find(r => r.subject === "omp-role-report");
      if (!rep || reportSeen) return;
      const parsed = rep.body ? tryParse(rep.body) : { ok: false as const };
      report = {
        deliveryId: rep.deliveryId ?? "",
        json: parsed.ok && parsed.value && typeof parsed.value === "object" ? parsed.value : null,
        text: parsed.ok ? null : rep.body ?? null,
      };
      writeFileSync(
        join(stateDir, "report.json"),
        JSON.stringify({ at: nowIso(), deliveryId: report.deliveryId, dispatchId, taskId, subject: rep.subject, reportJson: report.json, reportText: report.text, raw: rep.row }, null, 2) + "\n",
      );
      reportSeen = true;
    };

    if (oursDone.length === 0) {
      if (oursStatus.length) {
        // status report is NOT completion: capture it, ack only this processed batch, keep waiting
        captureReport();
        if (!batchAckId) returnUnacked("needs_input", "status batch carries no batch delivery id — cannot ack precisely; main must process", rows);
        await orcaJson(ctx, "check-ack", ["orchestration", "check", "--run", state.run.id, ...(state.coordinator.from ? ["--terminal", state.coordinator.from] : []), "--ack", batchAckId, "--json"]);
        saveState(ctx, state);
        continue;
      }
      if (oursNoise.length && !oursStatus.length) {
        // heartbeats/lifecycle noise from our worker: recorded, nothing to decide; ack the batch and keep waiting
        if (!batchAckId) returnUnacked("needs_input", "unrecognized batch carries no batch delivery id — main must process", rows);
        await orcaJson(ctx, "check-ack", ["orchestration", "check", "--run", state.run.id, ...(state.coordinator.from ? ["--terminal", state.coordinator.from] : []), "--ack", batchAckId, "--json"]);
        saveState(ctx, state);
        continue;
      }
      returnUnacked("needs_input", "delivery contains no validated worker_done/status for this dispatch", rows);
    }

    const done = oursDone[0];
    const outcome = done.outcome === "succeeded" || done.outcome === "failed" ? done.outcome : null;
    if (!outcome) {
      returnUnacked("invalid_worker_done", "worker_done carries no explicit outcome; completion is never inferred from prose or terminal idle", rows);
    }
    captureReport();

    // post-completion fingerprint: reject stale / source-mutated results
    const before = JSON.parse(readFileSync(join(stateDir, "baseline.json"), "utf8")) as Finger; // our own persisted writer shape
    const after = fingerprint(state.workspace, state.scopes, gitAvailable(state.workspace));
    writeFileSync(join(stateDir, "after.json"), JSON.stringify(after, null, 2) + "\n");
    state.fingerprints.after = "after.json";
    const mutation = diffFingerprints(before, after);
    if (mutation.length) {
      writeFileSync(join(stateDir, "mutation.json"), JSON.stringify({ at: nowIso(), mutations: mutation }, null, 2) + "\n");
    }

    // valid completion: full report already captured; save result, retain terminal, then ack the whole ours-only batch
    const reportRef: { deliveryId: string; json: unknown; text: string | null } | null = report;
    const validationProblems = reportProblems(reportRef?.json, state);
    writeFileSync(
      join(stateDir, "result.json"),
      JSON.stringify(
        {
          at: nowIso(),
          outcome,
          note: "outcome is role-lifecycle completion; the omp-role-report below carries the verdict/findings or command results — never a code approval by itself",
          deliveryId: done.deliveryId,
          dispatchId: done.dispatchRef,
          workerDoneBody: done.body,
          report: reportRef ? { deliveryId: reportRef.deliveryId, json: reportRef.json, text: reportRef.text } : null,
          reportSeen,
          sourceValid: mutation.length === 0,
          mutations: mutation,
          reportValid: validationProblems.length === 0,
          validationProblems,
          row: done.row,
        },
        null,
        2,
      ) + "\n",
    );
    const rd = await orca(ctx, "worker-read", ["orchestration", "worker-read", "--dispatch", dispatchId, "--limit", "200", "--json"]);
    saveRaw(ctx, "worker-read", rd); // transcript evidence; non-fatal on failure

    const rt = await orcaJson(ctx, "worker-retain", ["orchestration", "worker-retain", "--dispatch", dispatchId, "--json"]);
    state.lifecycle.retained = true;
    saveState(ctx, state);

    const ackId = batchAckId;
    if (!ackId) {
      state.lifecycle.status = "settled";
      state.lifecycle.outcome = outcome;
      state.lifecycle.settledAt = nowIso();
      state.lifecycle.live = false;
      dropLiveLock(stateDir);
      saveState(ctx, state);
      out({ ok: true, command: "wait", job: state.job, role: state.role, status: "settled", outcome, retained: true, acked: false, note: "settled but batch delivery id unparseable — ack manually per state/raw/check-wait.json", resultPath: join(stateDir, "result.json") });
    }
    const ack = await orcaJson(ctx, "check-ack", ["orchestration", "check", "--run", state.run.id, ...(state.coordinator.from ? ["--terminal", state.coordinator.from] : []), "--ack", ackId, "--json"]);
    state.lifecycle.acked = true;
    state.lifecycle.status = "settled";
    state.lifecycle.outcome = outcome;
    state.lifecycle.settledAt = nowIso();
    state.lifecycle.live = false;
    dropLiveLock(stateDir);
    saveState(ctx, state);

    out({
      ok: true,
      command: "wait",
      job: state.job,
      role: state.role,
      status: "settled",
      outcome,
      outcomeMeans:
        state.role === "review"
          ? "review completed — verdict (clean|findings|blocked) with severity/evidence is in report.json/result.json, NOT a code approval"
          : "verify completed — per-command exit codes, smoke evidence and blockers are in report.json/result.json; failed required checks are outcome=failed",
      report: reportRef ? reportRef.json ?? reportRef.text : null,
      reportPath: reportRef ? join(stateDir, "report.json") : null,
      reportSeen,
      workerDoneBody: done.body,
      retained: true,
      acked: true,
      transcript: existsSync(join(stateDir, "raw", "worker-read.json")) ? join(stateDir, "raw", "worker-read.json") : null,
      fingerprint: { baseline: join(stateDir, "baseline.json"), after: join(stateDir, "after.json"), mutations: mutation },
      sourceValid: mutation.length === 0,
      reportValid: validationProblems.length === 0,
      validationProblems,
      resultPath: join(stateDir, "result.json"),
      retainReceipt: rt.json,
      ackReceipt: ack.json,
    });
  }
}

// ---------------------------------------------------------------------------
// status

async function cmdStatus(argv: string[]): Promise<never> {
  const { _ } = parseArgs(argv);
  const jobArg = _[0];
  if (!jobArg) fail("usage", "status JOB is required", USAGE_HINT);
  const { stateDir, state } = await resolveJob(jobArg);
  const ctx: Ctx = { cwd: process.cwd(), orcaBase: resolveOrcaBase(), stateDir, raw: {}, history: [] };

  let workerShow: unknown = null;
  let workerShowError: unknown = null;
  if (state.worker?.dispatchId) {
    const r = await orca(ctx, "worker-show", ["orchestration", "worker-show", "--dispatch", state.worker.dispatchId, "--json"]);
    saveRaw(ctx, "worker-show", r);
    const parsed = tryParse(r.stdout);
    const root = parsed.ok ? parsed.value : null;
    if (r.exit === 0 && root && typeof root === "object" && "ok" in root && root.ok !== false) {
      // same {ok, result} envelope as every other verb — surface the result body
      workerShow = "result" in root && root.result && typeof root.result === "object" ? root.result : root;
    } else {
      workerShowError = { exit: r.exit, stderr: clip(r.stderr), stdout: clip(r.stdout) };
    }
  }
  out({
    ok: true,
    command: "status",
    job: state.job,
    role: state.role,
    statePath: stateDir,
    liveLock: existsSync(join(stateDir, "live.lock")),
    ...state,
    workerShow,
    workerShowError,
  });
}

// ---------------------------------------------------------------------------
// release

async function cmdRelease(argv: string[]): Promise<never> {
  const { _ } = parseArgs(argv);
  const jobArg = _[0];
  if (!jobArg) fail("usage", "release JOB is required", USAGE_HINT);
  const { stateDir, state } = await resolveJob(jobArg);
  if (state.lifecycle.status === "released") {
    out({ ok: true, command: "release", job: state.job, status: "released", alreadyReleased: true });
  }
  if (state.lifecycle.status !== "settled" || !state.lifecycle.retained || !state.worker?.dispatchId) {
    fail("not_releasable", `job ${state.job} is ${state.lifecycle.status} (retained=${state.lifecycle.retained})`, "release is allowed only for settled+retained workers; resolve per status output — never by closing the terminal", {
      status: state.lifecycle.status,
    });
  }
  const ctx: Ctx = { cwd: process.cwd(), orcaBase: resolveOrcaBase(), stateDir, raw: {}, history: [] };
  const r = await orcaJson(ctx, "worker-release", ["orchestration", "worker-release", "--dispatch", state.worker.dispatchId, "--json"]);
  const nativeState = asString(findKey(r.json, ["state"])) ?? "unknown";
  if (nativeState === "released") {
    state.lifecycle.status = "released";
    state.lifecycle.releasedAt = nowIso();
  }
  saveState(ctx, state);
  out({ ok: true, command: "release", job: state.job, status: nativeState, receipt: r.json, cleanupReceiptPath: join(stateDir, "raw", "worker-release.json") });
}

// ---------------------------------------------------------------------------
// entry

function printHelp(): never {
  out({
    name: "omp-orca-role",
    summary: "Orca role-session controller for bin/omp-review | bin/omp-verify workers",
    commands: {
      "start review|verify --task-file PATH --scope PATH [--scope PATH ...] [--check COMMAND]... [--base REF] [--from HANDLE] [--run RUN_ID]": "create terminal in the exact current Orca workspace (launcher + verbatim --check args), wait tui-idle, worker-start with a self-contained spec; prints job/statePath/ids",
      "wait JOB [--timeout-ms N]": "event-driven batches: captures the omp-role-report status message, then validates worker_done + fingerprint, retains, then acks only processed batches; questions/unrelated stay unacked",
      "status JOB": "read state.json + worker-show",
      "release JOB": "native worker-release, only for settled+retained jobs; receipt is authoritative (pre-existing/reused terminals may be reported retained)",
    },
    semantics: "outcome is role-lifecycle completion; the worker's omp-role-report (verdict/findings/command exits/smoke/blockers) is preserved verbatim in report.json and result.json",
    checks: "--check strings must be single non-compound commands, no '*', no --fix/install/snapshot-update; human authorization happens on the coordinator side before start",
    state: "<workspace>/.scratch/omp-orca-roles/<job>/",
    orcaSelection: "ORCA_CLI_COMMAND | ORCA_DEV_REPO_ROOT | platform fallback (darwin orca, linux orca-ide)",
  });
}

async function main(): Promise<never> {
  const argv = process.argv.slice(2);
  const cmd = argv[0];
  if (!cmd || cmd === "--help" || cmd === "-h" || cmd === "help") return printHelp();
  if (cmd === "start") return await cmdStart(argv.slice(1));
  if (cmd === "wait") return await cmdWait(argv.slice(1));
  if (cmd === "status") return await cmdStatus(argv.slice(1));
  if (cmd === "release") return await cmdRelease(argv.slice(1));
  fail("usage", `unknown command: ${cmd}`, USAGE_HINT);
}

await main();

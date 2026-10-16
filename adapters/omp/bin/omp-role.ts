#!/usr/bin/env bun
/**
 * omp-role — shared core for the adapters/omp/bin/omp-review and omp-verify launchers.
 *
 * Launches a fresh, role-scoped OMP session in the caller's cwd:
 *   - model / thinking / tools / approval mode / prompt all come from
 *     adapters/omp/roles.json (single source of truth)
 *   - --describe and --help exit without touching OMP (no model call)
 *   - role-, tool-, model-, prompt- or session-affecting flags are rejected
 *
 * Bash approval: OMP defaults every unmatched bash command to the exec
 * (prompt) tier even under --approval-mode write, so the launcher generates a
 * role-local --config overlay whose bash.patterns preserve the user's effective
 * patterns first (their deny/prompt policies keep precedence), then add:
 *   - the role's read-only Git inspection family (adapters/omp/roles.json)
 *   - the Orca coordination verbs `orchestration check` / `orchestration send`
 *     for the resolved orca executable (lifecycle verbs stay unapproved)
 *   - exact-string allows from repeatable `--check COMMAND` (verify role only)
 * Approved role actions run unattended; unmatched Bash is denied, never prompted.
 *
 * Never hardcode role facts here — edit adapters/omp/roles.json instead.
 */

import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

const USAGE = `omp-review / omp-verify — scoped OMP role launchers (core: adapters/omp/bin/omp-role.ts)

USAGE
  omp-review [options] [message ...]
  omp-verify [--check COMMAND] ... [options] [message ...]

OPTIONS
  --describe         Print the role contract as JSON and exit (no model call)
  -h, --help         This help (no model call)
  -p, --print        Non-interactive: process the message(s) and exit
  --mode <value>     Output mode for --print: text (default) | json | rpc
  --no-session       Ephemeral run: do not save a session
  --no-title         Skip session title generation
  --check COMMAND    Pre-approve one exact command string for the verify role
                     (repeatable). No '*', no compound/control characters; the
                     worker must run it verbatim. Review rejects this flag.
  --                 Everything after this is passed to OMP as messages verbatim

Messages
  Any non-option argument becomes an initial message; OMP @file references work.
  To pass a message that starts with '-', put it after --.

Fixed by adapters/omp/roles.json (edit there, not here)
  model, thinking level, enabled tools (read/find/grep/glob/lsp/bash only),
  --approval-mode from the role preset, --no-prewalk, the appended role file,
  and the baseline read-only Git bash-approval family. Every session is fresh:
  -c/--continue, -r/--resume and session imports are rejected, as are
  --model/--tools/--system-prompt/--profile/--cwd/--config and all other
  role-affecting flags.

Bash approval
  Approved actions run unattended: read tools, scoped Git inspection, Orca
  coordination/guide reads, and exact verifier --check commands.
  Other Bash is denied rather than shown in a local approval dialog.
  Explicit user denies remain authoritative; prompt restrictions become denies.

Examples
  omp-review --describe
  omp-review "Review the staged diff for race conditions"
  omp-verify --check "node --test fixture.test.mjs" -p "Verify: node --test passes"`;

type BashPattern = { match: string; approval: string };

type RoleConfig = {
  label: string;
  provider?: string;
  model: string;
  thinking: string;
  tools: string[];
  approvalMode: string;
  noPrewalk: boolean;
  promptPath: string;
  summary: string;
};

type RolesFile = {
  version: number;
  startupMessage: string;
  deniedTools?: string[];
  bashAllow?: BashPattern[];
  roles: Record<string, RoleConfig>;
};

const PASS_THROUGH_BOOLEANS: Record<string, true> = {
  "-p": true,
  "--print": true,
  "--no-session": true,
  "--no-title": true,
};
const VALID_MODES: Record<string, true> = { text: true, json: true, rpc: true };
const FORWARD_SIGNALS = ["SIGINT", "SIGTERM", "SIGHUP", "SIGQUIT"] as const;
// Same character class OMP's own allow-guard rejects: an approved --check must
// actually allow, and wildcards/compounds would widen or silently never match.
const FORBIDDEN_CHECK_CHARS = /[\n\r;&|<>`$()*]/;

function fail(message: string, code = 1): never {
  console.error(`omp-role: ${message}`);
  process.exit(code);
}

function loadRolesFile(repoRoot: string): RolesFile {
  const path = join(repoRoot, "roles.json");
  let parsed: RolesFile;
  try {
    parsed = JSON.parse(readFileSync(path, "utf8")) as RolesFile;
  } catch (error) {
    fail(`cannot read adapters/omp/roles.json: ${error instanceof Error ? error.message : error}`);
  }
  if (!parsed || typeof parsed !== "object" || !parsed.roles || typeof parsed.roles !== "object") {
    fail(`adapters/omp/roles.json is malformed: "roles" object missing`);
  }
  return parsed;
}

function roleConfig(file: RolesFile, role: string): RoleConfig {
  const cfg = file.roles[role];
  if (!cfg) fail(`unknown role "${role}" in adapters/omp/roles.json`, 2);
  for (const field of ["model", "thinking", "approvalMode", "promptPath"] as const) {
    if (typeof cfg[field] !== "string" || !(cfg[field] as string).trim()) {
      fail(`role "${role}": "${field}" must be a non-empty string`, 2);
    }
  }
  if (!Array.isArray(cfg.tools) || cfg.tools.length === 0 || cfg.tools.some((t) => typeof t !== "string")) {
    fail(`role "${role}": "tools" must be a non-empty array of tool names`, 2);
  }
  for (const denied of file.deniedTools ?? []) {
    if (cfg.tools.includes(denied)) {
      fail(`role "${role}": denied tool "${denied}" must not appear in tools`, 2);
    }
  }
  return cfg;
}

function resolveOmpBin(): string {
  const found = Bun.which("omp");
  if (found) return found;
  const fallback = join(process.env.HOME ?? "", ".bun", "bin", "omp");
  if (statSync(fallback, { throwIfNoEntry: false })?.isFile()) return fallback;
  fail("omp binary not found on PATH or at ~/.bun/bin/omp", 127);
}

/** Effective user bash.patterns across all settings layers, in the caller's cwd. */
function readUserBashPatterns(ompBin: string): BashPattern[] {
  const proc = Bun.spawnSync([ompBin, "config", "get", "bash.patterns", "--json"], {
    stdout: "pipe",
    stderr: "pipe",
  });
  if (proc.exitCode !== 0) {
    fail(
      `cannot read effective bash.patterns (exit ${proc.exitCode}): ${proc.stderr.toString().trim()}\n` +
        `  refusing to launch: the role overlay must preserve existing user deny/prompt policies`,
    );
  }
  try {
    const parsed = JSON.parse(proc.stdout.toString()) as { value?: unknown };
    if (!Array.isArray(parsed.value)) fail(`bash.patterns is not an array (got ${typeof parsed.value})`);
    const patterns: BashPattern[] = [];
    for (const entry of parsed.value) {
      if (!entry || typeof entry !== "object") continue;
      const record = entry as Record<string, unknown>;
      if (typeof record.match !== "string" || typeof record.approval !== "string") continue;
      if (record.approval === "deny" || record.approval === "prompt") {
        patterns.push({ match: record.match, approval: "deny" });
      }
    }
    return patterns;
  } catch (error) {
    fail(`cannot parse bash.patterns: ${error instanceof Error ? error.message : error}`);
  }
}

function parseCheckCommand(value: string): string {
  const command = value.trim();
  if (!command) fail(`--check requires a command string`, 2);
  if (FORBIDDEN_CHECK_CHARS.test(command)) {
    fail(
      `--check rejects '*', compound and control characters (semicolon, ampersand, pipe, redirect, backtick, dollar, parentheses) in: ${command}`,
      2,
    );
  }
  if (/(?:^|\s)(?:--fix(?:[=\s]|$)|--update-snapshots?(?:[=\s]|$)|--updateSnapshot(?:[=\s]|$)|-u(?:\s|$))/.test(command) ||
      /^(?:npm|pnpm|yarn|bun)\s+(?:install|add|ci|update)(?:\s|$)/.test(command) ||
      /^git\s+(?:add|commit|push|checkout|restore|reset|clean)(?:\s|$)/.test(command)) {
    fail("--check cannot authorize source/test mutation, dependency installation or Git writes", 2);
  }
  return command;
}

function roleToolPolicies(ompBin: string, tools: string[]): Record<string, string> {
  const result = Bun.spawnSync([ompBin, "config", "get", "tools.approval", "--json"], { stdout: "pipe", stderr: "pipe" });
  if (result.exitCode !== 0) fail("cannot preserve effective tool deny policies");
  const parsed = JSON.parse(result.stdout.toString()) as { value: Record<string, string> };
  const policies: Record<string, string> = {};
  for (const tool of tools) policies[tool] = parsed.value?.[tool] === "deny" ? "deny" : "allow";
  return policies;
}

function overlayYaml(patterns: BashPattern[], policies: Record<string, string>): string {
  return Bun.YAML.stringify({
    paste: { largeMenuThreshold: 0 },
    tools: { approval: policies },
    bash: { patterns },
  });
}

function orcaCoordinationPatterns(): BashPattern[] {
  const selected = process.env.ORCA_CLI_COMMAND ||
    (process.env.ORCA_DEV_REPO_ROOT ? "orca-dev" : process.platform === "linux" ? "orca-ide" : "orca");
  const executable = Bun.which(selected) || selected;
  const names = selected === executable ? [selected] : [selected, executable];
  return names.flatMap(name =>
    ["orchestration check", "orchestration send", "orchestration ask", "skills get"].flatMap(operation => [
      { match: `${name} ${operation}`, approval: "allow" },
      { match: `${name} ${operation} *`, approval: "allow" },
      { match: `rtk proxy ${name} ${operation} *`, approval: "allow" },
    ]),
  );
}

async function runOmp(ompBin: string, args: string[], cleanup: () => void): Promise<never> {
  let child: Bun.Subprocess<"inherit", "inherit", "inherit">;
  try {
    child = Bun.spawn([ompBin, ...args], { stdin: "inherit", stdout: "inherit", stderr: "inherit" });
  } catch (error) {
    cleanup();
    fail(`cannot launch ${ompBin}: ${error instanceof Error ? error.message : error}`, 127);
  }

  const forward = (signal: string) => {
    try {
      child.kill(signal as never);
    } catch {
      // Child already gone — nothing to forward.
    }
  };
  const handlers = FORWARD_SIGNALS.map(signal => ({ signal, listener: () => forward(signal) }));
  for (const { signal, listener } of handlers) process.on(signal, listener);

  const exitCode = await child.exited;
  for (const { signal, listener } of handlers) process.removeListener(signal, listener);
  cleanup();

  if (typeof exitCode === "number") process.exit(exitCode);
  if (child.signalCode) {
    // Re-raise with default disposition so the parent sees the same signal.
    process.kill(process.pid, child.signalCode);
  }
  process.exit(1);
}

async function main(): Promise<never> {
  const argv = process.argv.slice(2);
  const role = argv.shift();
  if (!role || role.startsWith("-")) fail(`first argument must be a role (review|verify)`, 2);

  const repoRoot = resolve(import.meta.dir, "..");
  const file = loadRolesFile(repoRoot);
  const cfg = roleConfig(file, role);
  const promptPath = isAbsolute(cfg.promptPath) ? cfg.promptPath : join(repoRoot, cfg.promptPath);

  // Split arguments: launcher options, passthrough OMP flags, messages.
  const ompFlags: string[] = [];
  const messages: string[] = [];
  const checks: string[] = [];
  let describe = false;
  let verbatim = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!;
    if (verbatim) {
      messages.push(arg);
      continue;
    }
    if (arg === "--") {
      verbatim = true;
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      console.log(USAGE);
      process.exit(0);
    }
    if (arg === "--describe") {
      describe = true;
      continue;
    }
    const eq = arg.indexOf("=");
    const name = eq > 0 ? arg.slice(0, eq) : arg;
    if (name === "--check") {
      if (role !== "verify") {
        fail(`--check is a verify-role option; the review role approves no checks`, 2);
      }
      const value = eq > 0 ? arg.slice(eq + 1) : argv[++i];
      if (value === undefined) fail(`--check requires a command string`, 2);
      checks.push(parseCheckCommand(value));
      continue;
    }
    if (name === "--mode") {
      const value = eq > 0 ? arg.slice(eq + 1) : argv[++i];
      if (value === undefined || VALID_MODES[value] !== true) {
        fail(`--mode must be one of ${Object.keys(VALID_MODES).join("|")}${value === undefined ? "" : ` (got "${value}")`}`, 2);
      }
      ompFlags.push(`--mode=${value}`);
      continue;
    }
    if (PASS_THROUGH_BOOLEANS[name] === true) {
      ompFlags.push(name);
      continue;
    }
    if (arg.startsWith("-")) {
      fail(
        `rejected flag: ${arg}\n` +
          `  role, model, tools, prompt, approval mode and fresh-session behavior are fixed by\n` +
          `  adapters/omp/roles.json and cannot be overridden.\n` +
          `  Allowed: --describe --help -p/--print --mode <text|json|rpc> --no-session --no-title\n` +
          `           --check COMMAND (verify only) -- <messages>`,
        2,
      );
    }
    messages.push(arg);
  }

  if (describe) {
    console.log(
      JSON.stringify(
        { role, model: cfg.model, thinking: cfg.thinking, tools: cfg.tools, promptPath },
        null,
        2,
      ),
    );
    process.exit(0);
  }

  // The installed Orca hook starts publishing OMP status on the first real turn,
  // not session_start. CLI initial input is queued after UI initialization.
  if (!messages.length && !ompFlags.some(flag =>
    flag === "-p" || flag === "--print" || flag === "--mode=rpc" || flag === "--mode=json")) {
    if (typeof file.startupMessage !== "string" || !file.startupMessage.trim()) {
      fail("interactive role requires its configured read-only startup handshake", 2);
    }
    messages.push(file.startupMessage);
  }
  try {
    if (!statSync(promptPath, { throwIfNoEntry: false })?.isFile()) {
      fail(`role prompt not found: ${promptPath}`);
    }
  } catch (error) {
    fail(`cannot stat role prompt ${promptPath}: ${error instanceof Error ? error.message : error}`);
  }

  const ompBin = resolveOmpBin();

  // Role-local bash-approval overlay: user policies first (their deny/prompt
  // patterns keep first-match precedence), then role baseline, orca verbs,
  // then exact --check allows.
  if (file.bashAllow !== undefined && !Array.isArray(file.bashAllow)) {
    fail(`adapters/omp/roles.json: "bashAllow" must be an array when present`, 2);
  }
  const patterns: BashPattern[] = [
    ...(file.bashAllow ?? []).flatMap(rule => [
      rule,
      { ...rule, match: `rtk ${rule.match}` },
      { ...rule, match: `rtk proxy ${rule.match}` },
    ]),
    ...orcaCoordinationPatterns(),
    ...checks.flatMap(command => [
      { match: command, approval: "allow" },
      { match: `rtk proxy ${command}`, approval: "allow" },
    ]),
  ];
  const userPolicies = readUserBashPatterns(ompBin);
  const overlayDir = mkdtempSync(join(tmpdir(), "omp-role-"));
  const overlayPath = join(overlayDir, "bash-patterns.yml");
  writeFileSync(overlayPath, overlayYaml([...userPolicies, ...patterns, { match: "*", approval: "deny" }], roleToolPolicies(ompBin, cfg.tools)));

  const ompArgs = [
    "--config",
    overlayPath,
    "--model",
    cfg.model,
    "--thinking",
    cfg.thinking,
    "--tools",
    cfg.tools.join(","),
    "--append-system-prompt",
    promptPath,
    "--approval-mode",
    cfg.approvalMode,
    ...(cfg.noPrewalk ? ["--no-prewalk"] : []),
    ...ompFlags,
    ...messages.filter(message => message.startsWith("@")),
    ...(messages.some(message => !message.startsWith("@"))
      ? ["--", ...messages.filter(message => !message.startsWith("@"))]
      : []),
  ];
  await runOmp(ompBin, ompArgs, () => rmSync(overlayDir, { recursive: true, force: true }));
}

await main();

/**
 * ai-main guard for pi: runs ~/.claude/hooks/guard.sh (Claude Code PreToolUse contract) on every
 * pi tool_call and blocks when the guard denies. FAIL-CLOSED: spawn error, timeout, non-zero exit,
 * unparseable output or any exception blocks the call.
 *
 * Mapping (same as ~/.hermes/agent-hooks/guard-adapter.py):
 *   bash                       -> tool_name "Bash", tool_input {command}, cwd = ctx.cwd
 *   codemode                   -> scanned as "Bash" with the script text (catches git/glab inside scripts)
 *   mcp__*clickup_* / mcp__graphify__* -> passed through unchanged
 *   everything else            -> not checked (guard.sh only decides Bash/ClickUp/graphify)
 * Transcript: last user message of the current branch is written as a one-line Claude-style JSONL
 * so guard.sh confirm words ('push', 'commit', 'confirm', ...) work. Hard denies ("never allowed")
 * always block; soft gates (permissionDecision "ask", or legacy soft deny) ask in the TUI when
 * available, else block. Automation tags ([keepalive / [review-handoff / [auto:) are skipped so
 * they cannot unlock magic words.
 * Env: AIMAIN_GUARD (override guard path), AIMAIN_GUARD_LOG (log file).
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import { appendFileSync, mkdirSync, mkdtempSync, writeFileSync, unlinkSync, rmdirSync, accessSync, constants } from "node:fs";
import { tmpdir, homedir } from "node:os";
import { dirname, join } from "node:path";

const GUARD = process.env.AIMAIN_GUARD || join(homedir(), ".claude/hooks/guard.sh");
const LOG = process.env.AIMAIN_GUARD_LOG || join(process.env.PI_CODING_AGENT_DIR || join(homedir(), ".pi/agent"), "logs/guard.log");
const TIMEOUT_MS = 12_000;
const AUTO_TAG = /^\[(keepalive|review-handoff|auto:)/i;

function log(msg: string) {
	try {
		mkdirSync(dirname(LOG), { recursive: true });
		appendFileSync(LOG, `${new Date().toISOString()} ${msg}\n`);
	} catch {}
}

function mapTool(name: string, input: any): { tool: string; input: any } | undefined {
	if (name === "bash") {
		const command = String(input?.command ?? "");
		return command.trim() ? { tool: "Bash", input: { command } } : undefined;
	}
	if (name === "codemode") {
		const script = String(input?.code ?? input?.script ?? JSON.stringify(input ?? {}));
		return { tool: "Bash", input: { command: script } };
	}
	if (/clickup_/.test(name) || name.startsWith("mcp__graphify__")) return { tool: name, input: input ?? {} };
	return undefined;
}

function lastUserText(ctx: any): { text: string; ts: string } | undefined {
	const branch: any[] = ctx?.sessionManager?.getBranch?.() ?? [];
	for (let i = branch.length - 1; i >= 0; i--) {
		const e = branch[i];
		const m = e?.type === "message" ? e.message : undefined;
		if (!m || m.role !== "user") continue;
		const text = typeof m.content === "string" ? m.content
			: Array.isArray(m.content) ? m.content.filter((c: any) => c?.type === "text").map((c: any) => c.text).join("\n") : "";
		const trimmed = text.trim();
		if (!trimmed) continue;
		if (AUTO_TAG.test(trimmed)) continue; // skip automation; keep looking for a real user message
		return { text: trimmed, ts: new Date(m.timestamp ?? e.timestamp ?? Date.now()).toISOString().replace(/\.\d+Z$/, "Z") };
	}
	return undefined;
}

function runGuard(payload: object, cwd: string): Promise<{ code: number | null; out: string; err: string }> {
	return new Promise((resolve, reject) => {
		const env = { ...process.env, PATH: ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin", process.env.PATH ?? ""].join(":") };
		const child = spawn("bash", [GUARD], { cwd, env, stdio: ["pipe", "pipe", "pipe"] });
		let out = "", err = "";
		const timer = setTimeout(() => { child.kill("SIGKILL"); reject(new Error(`guard timed out after ${TIMEOUT_MS}ms`)); }, TIMEOUT_MS);
		child.stdout.on("data", (d) => (out += d));
		child.stderr.on("data", (d) => (err += d));
		child.on("error", (e) => { clearTimeout(timer); reject(e); });
		child.on("close", (code) => { clearTimeout(timer); resolve({ code, out, err }); });
		child.stdin.end(JSON.stringify(payload));
	});
}

export default function (pi: ExtensionAPI) {
	log("LOADED guard.ts ask-soft-path + local-auto-commit");
	pi.on("tool_call", async (event: any, ctx: any) => {
		const mapped = mapTool(String(event.toolName ?? ""), event.input);
		if (!mapped) return undefined;
		const block = (reason: string) => { log(`BLOCK tool=${event.toolName} reason=${reason} input=${JSON.stringify(mapped.input).slice(0, 300)}`); return { block: true, reason }; };
		let tdir: string | undefined, tpath = "";
		try {
			accessSync(GUARD, constants.R_OK);
			const last = lastUserText(ctx);
			if (last) {
				tdir = mkdtempSync(join(tmpdir(), "pi-guard-"));
				tpath = join(tdir, "t.jsonl");
				writeFileSync(tpath, JSON.stringify({ type: "user", timestamp: last.ts, message: { role: "user", content: last.text } }) + "\n");
			}
			const cwd = String(ctx?.cwd ?? process.cwd());
			const res = await runGuard({ hook_event_name: "PreToolUse", tool_name: mapped.tool, tool_input: mapped.input, transcript_path: tpath, cwd }, cwd);
			if (res.code !== 0) return block(`ai-main guard failed closed: exit ${res.code} ${res.err.trim().slice(0, 200)}`);
			const out = res.out.trim();
			if (!out) return undefined;
			let hso: any;
			try { hso = JSON.parse(out)?.hookSpecificOutput ?? {}; } catch { return block(`ai-main guard failed closed: unparseable output ${out.slice(0, 200)}`); }
			const decision = String(hso.permissionDecision || "");
			const reason = String(hso.permissionDecisionReason || "guard.sh: denied");
			const hard = reason.includes("never allowed");
			// Soft: permissionDecision "ask" (Claude Code Approve), or legacy soft deny without "never allowed"
			const soft = decision === "ask" || (decision === "deny" && !hard);
			if (soft) {
				if (ctx?.hasUI) {
					const ok = await ctx.ui.confirm?.("ai-main guard", `${reason}\n\nAllow anyway?`);
					if (ok === true) { log(`ALLOWED-BY-USER tool=${event.toolName} reason=${reason}`); return undefined; }
				}
				return block(`BLOCKED by ${reason}`);
			}
			if (decision === "deny") return block(`BLOCKED by ${reason}`);
			return undefined;
		} catch (e: any) {
			return block(`ai-main guard failed closed: ${e?.message ?? e}`);
		} finally {
			if (tpath) try { unlinkSync(tpath); } catch {}
			if (tdir) try { rmdirSync(tdir); } catch {}
		}
	});
}

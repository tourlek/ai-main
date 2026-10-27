/**
 * ai-main brain for plain pi (agent dir ~/.pi/agent).
 *
 * On every agent run, reads the shared brain files fresh from disk and puts
 * them into the system prompt as independently replaceable XML sections, so
 * edits to ORACLE.md / SYSTEM.md show up on the next run without copies.
 *
 *   ai_main_note   ~/ai-main/adapters/pi/agent/APPEND_SYSTEM.md (adapter note)
 *   ai_main_oracle ~/.hermes/state/ORACLE.md   (ai-main/bin/oracle-recap)
 *   ai_main_system ~/ai-main/build/full/SYSTEM.md (`aimain build`)
 *
 * Missing files are skipped. Env AIMAIN_BRAIN=0 disables the extension.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const H = homedir();
const FILES: Array<[string, string]> = [
	["ai_main_note", join(H, "ai-main/adapters/pi/agent/APPEND_SYSTEM.md")],
	["ai_main_oracle", join(H, ".hermes/state/ORACLE.md")],
	["ai_main_system", join(H, "ai-main/build/full/SYSTEM.md")],
];

function read(path: string): string | undefined {
	try {
		const text = readFileSync(path, "utf8").trim();
		return text || undefined;
	} catch {
		return undefined;
	}
}

export default function (pi: ExtensionAPI) {
	if (process.env.AIMAIN_BRAIN === "0") return;
	pi.on("before_agent_start", (event) => {
		const opts = event.systemPromptOptions;
		opts.sections = opts.sections ?? {};
		for (const [name, path] of FILES) {
			const text = read(path);
			if (text) opts.sections[name] = text;
			else delete opts.sections[name];
		}
	});
}

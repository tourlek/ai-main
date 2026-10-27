// Test-only: registers provider "guard-selftest" pointing at mock-llm.py (loaded with -e by selftest.sh only).
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
export default function (pi: ExtensionAPI) {
	pi.registerProvider("guard-selftest", {
		name: "guard selftest (mock)",
		baseUrl: `http://127.0.0.1:${process.env.MOCK_PORT || "18765"}/v1`,
		apiKey: "not-a-secret",
		api: "openai-completions",
		models: [{ type: "chat", id: "mock", name: "mock", reasoning: false, input: ["text"],
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }, contextWindow: 128000, maxTokens: 4096 }],
	});
}

#!/usr/bin/env python3
"""Scripted OpenAI-compatible chat endpoint for the pi guard/MCP self-test (no real LLM, no key).
Each request answers with the next scripted tool call, decided by how many tool results the request
already carries; it logs every tool result pi sends back to MOCK_LOG (the evidence)."""
import json, os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG = os.environ.get("MOCK_LOG", "/tmp/pi-mock-llm.jsonl")
STEPS = [
    ("bash", {"command": "git push origin master"}),
    ("bash", {"command": "ls ~/ai-main | wc -l"}),
    ("mcp__context7__resolve_library_id", {"libraryName": "react", "query": "react hooks"}),
]

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("content-length", 0))) or b"{}")
        msgs = body.get("messages", [])
        tools = [m for m in msgs if m.get("role") == "tool"]
        with open(LOG, "a") as fh:
            fh.write(json.dumps({"request": len(tools), "declared_tools": [t.get("function", {}).get("name") for t in body.get("tools", [])][:40],
                                 "last_tool_result": tools[-1] if tools else None}, ensure_ascii=False) + "\n")
        self.send_response(200); self.send_header("content-type", "text/event-stream"); self.end_headers()
        def chunk(delta, finish=None):
            self.wfile.write(b"data: " + json.dumps({"id": "mock", "object": "chat.completion.chunk", "created": 0, "model": "mock",
                "choices": [{"index": 0, "delta": delta, "finish_reason": finish}]}).encode() + b"\n\n")
        n = len(tools)
        if n < len(STEPS):
            name, args = STEPS[n]
            chunk({"role": "assistant", "tool_calls": [{"index": 0, "id": f"call_{n}", "type": "function",
                   "function": {"name": name, "arguments": json.dumps(args)}}]})
            chunk({}, "tool_calls")
        else:
            chunk({"role": "assistant", "content": "selftest done"}); chunk({}, "stop")
        self.wfile.write(b"data: [DONE]\n\n"); self.wfile.flush()

HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 18765), H).serve_forever()

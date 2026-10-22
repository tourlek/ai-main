#!/usr/bin/env python3
"""UserPromptSubmit hook: ask Jev (TypeSafe System One) how heavy the prompt is
and inject a routing hint. Fail-open: any error/timeout/missing key -> no output."""
import json, os, sys, urllib.request

KEY = os.environ.get("TYPESAFE_API_KEY")
if not KEY:
    sys.exit(0)
try:
    prompt = (json.load(sys.stdin).get("prompt") or "").strip()
except Exception:
    sys.exit(0)
if not prompt:
    sys.exit(0)

body = {
    "model": "jev-latest",
    "state": prompt[:4000],
    "questions": {
        "tier": {
            "type": "choice",
            "instructions": "How much reasoning capability does this coding-assistant request need?",
            "criteria": {
                "search": "Locating files/symbols, grep, listing, reading docs; no design or edits",
                "routine": "Ordinary implementation, bug fix, edit, explanation, or question",
                "architect": "Architecture/design decisions, risky migrations, security-sensitive or hard-to-reverse changes, or a request for a deep review",
            },
        }
    },
}
HINT = {
    "search": "delegate discovery to the `explore` agent (haiku); do not spend main-session tokens on file hunting.",
    "routine": "handle inline in this session (sonnet).",
    "architect": "plan carefully; run the `judge` agent (opus) on the plan/diff before declaring done.",
}
try:
    req = urllib.request.Request(
        "https://api.typesafe.ai/v1/systemone",
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"},
    )
    ans = json.load(urllib.request.urlopen(req, timeout=2.5))["answers"]["tier"]
    tier, conf = ans["choice"], float(ans.get("confidence", 0))
except Exception:
    sys.exit(0)

# Low confidence -> stay silent rather than steer on a coin-flip.
if tier not in HINT or conf < 0.6:
    sys.exit(0)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": f"[jev-route] tier={tier} (conf {conf:.2f}): {HINT[tier]}",
}}))

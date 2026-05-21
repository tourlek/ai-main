# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for shell commands (60-90% savings on dev operations).

## Rule

This tool does **not** have an auto-rewrite hook configured. Always prefix shell commands with `rtk`.

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

## Meta Commands

```bash
rtk gain            # Token savings analytics
rtk gain --history  # Recent command savings history
rtk proxy <cmd>     # Run raw command without filtering (for debugging)
```

## Verification

```bash
rtk --version
rtk gain
which rtk
```

⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

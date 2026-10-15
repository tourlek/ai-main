# RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for shell commands (60-90% savings on dev operations).

## Rule

Use `rtk <command>` by default for shell commands. During debugging, run the raw command without RTK whenever it truncates or hides logs needed to diagnose the issue; resume RTK afterward.

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

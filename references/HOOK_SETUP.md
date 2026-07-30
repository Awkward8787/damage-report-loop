# Optional Cursor Stop Hook

The core skill performs its own bounded loop and does not require a hook. The optional stop hook can nudge Cursor to continue when a session stops between iterations.

## Install

Copy or symlink `hooks/damage-report-loop.mjs` into the project:

```text
.cursor/hooks/damage-report-loop.mjs
```

Merge this entry into `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "stop": [
      {
        "command": "node .cursor/hooks/damage-report-loop.mjs"
      }
    ]
  }
}
```

Do not replace other existing hooks.

## Activation

The hook activates only while this file exists and contains `"active": true`:

```text
.cursor/damage-reports/loop-state.json
```

It stops when:

- state is `clear`, `blocked`, or `maxed`,
- `active` is false,
- Cursor reports an aborted or errored stop,
- or Cursor's loop count reaches the configured maximum.

The hook does not edit source code, commit, push, or change the state file. It only emits a follow-up message.

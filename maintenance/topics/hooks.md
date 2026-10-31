# Hooks topics

- `placing.md`: deciding where a hook is defined and what it applies to (settings locations and merging, managed and
  server-managed delivery, plugin `hooks/hooks.json`, manifest and marketplace `hooks`, skill and subagent frontmatter,
  path placeholders, worktrees and `/cd`, when edits take effect)
- `configuring.md`: writing a hook's settings entry (structure, matchers including MCP tools, `if`, handler types and
  fields, exec and shell form, PowerShell, timeouts, async hooks, the environment hook processes get, security practices)
- `prompt-and-agent.md`: writing a prompt or agent hook (supported events, configuration, response schema, model)
- `input-output.md`: reading a hook's input and returning its result (common input fields, exit codes, stdout and
  stderr, JSON output, `additionalContext`, `systemMessage`, terminal notifications, HTTP responses, combining results)
- `tool-events.md`: hooking a tool call (PreToolUse and per-tool input, defer, PermissionRequest and permission updates,
  PostToolUse, PostToolUseFailure, PostToolBatch, PermissionDenied, and how hook decisions meet permission rules, modes,
  auto mode and mods)
- `events.md`: hooking every other event (the lifecycle and cadence, and for each non-tool event when it fires, its
  matcher, input and output)
- `excluding.md`: turning hooks off or restricting them (`disableAllHooks`, `allowManagedHooksOnly`, HTTP allowlists,
  `strictPluginOnlyCustomization.hooks`, workspace trust, `--bare`, `--safe-mode`, the sandbox boundary, reviewing
  plugins)
- `troubleshooting.md`: checking whether a hook runs and why not (`/hooks`, the debug log, error notices, validation,
  plugin hook errors, OpenTelemetry hook events)

Hooks in skill frontmatter are split between types: skills owns the `once` field, a skill's own copy of a handler and
the trust rule as it applies to a project skill (`skills/frontmatter.md`); hooks owns the rest. The InstructionsLoaded
event is owned by instructions (`instructions/troubleshooting.md`); hooks keeps only its row in the lifecycle table.

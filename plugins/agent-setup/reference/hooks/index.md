# Hooks reference

What Claude Code does with hooks: where they are defined, how an entry is written, what each event receives and can
return, how to turn hooks off, and how to find out why one didn't run.

## Contents

- [Key facts](#key-facts)
- [Topics](#topics)

## Key facts

- A `PreToolUse` hook that exits 0 with no output doesn't approve the call: the normal permission flow still applies.
  A hook's `"allow"` doesn't bypass deny rules, and a matching ask rule still prompts.
  See [input-output.md › Exit codes](input-output.md) and
  [tool-events.md › Hook decisions and permission rules](tool-events.md).
- Only exit code 2 blocks. Exit code 1 is a non-blocking error and the action proceeds, so a hook meant to enforce a
  policy must use `exit 2`.
  See [input-output.md › Exit codes](input-output.md).
- `additionalContext` and `permissionDecision` belong inside `hookSpecificOutput`; at the top level Claude Code ignores
  them without reporting an error.
  See [troubleshooting.md › Hook JSON has no effect](troubleshooting.md).
- Stdout that doesn't start with `{`, such as a shell profile's unconditional `echo` before the JSON, is treated as
  plain text and the JSON is ignored; on exit 0 nothing shows in the transcript.
  See [troubleshooting.md › Hook JSON has no effect](troubleshooting.md).
- Matchers are case-sensitive, and a matcher of only letters, digits, `_`, `-`, spaces, `,` and `|` is compared as an
  exact string, so `mcp__memory` matches no tool; write `mcp__memory__.*`.
  See [configuring.md › Matching MCP tools](configuring.md) and
  [troubleshooting.md › A hook never fires](troubleshooting.md).
- A `matcher` on an event without matcher support is silently ignored, and a hook with `if` set on an event other than
  `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest` or `PermissionDenied` never runs.
  See [configuring.md › Matchers](configuring.md) and
  [configuring.md › Handler types and common fields](configuring.md).
- A `matcher` that is a JSON array never fires; under `PreToolUse` or `PermissionRequest`, none of that file's other
  hooks load either.
  See [troubleshooting.md › Check that a hook loaded](troubleshooting.md).
- Hooks go under the `"hooks"` key of a settings file; only plugins load a separate `hooks/hooks.json`, and a plugin's
  hooks file without the top-level `"hooks"` wrapper fails to load.
  See [troubleshooting.md › Check that a hook loaded](troubleshooting.md) and
  [placing.md › Plugin manifest and marketplace entry hooks](placing.md).
- A `-p` or SDK session treats the folder as trusted, so hooks committed in a repository's `.claude/settings.json` run
  in a folder you've never trusted.
  See [excluding.md › Workspace trust](excluding.md).
- `disableAllHooks` is read after settings precedence, so a project's `false` overrides your user `true`; to turn hooks
  off for one run, pass `--settings '{"disableAllHooks": true}'`.
  See [excluding.md › Turning all hooks off](excluding.md).
- `updatedInput` replaces the entire input object, so include unchanged fields alongside modified ones.
  See [tool-events.md › PreToolUse](tool-events.md).
- A Stop hook that blocks should check `stop_hook_active` and exit early when it is `true`; after stop hooks have
  continued the turn eight times in a row, Claude Code overrides the next block and ends the turn.
  See [troubleshooting.md › Stop hook hits the block cap](troubleshooting.md) and [events.md › Stop](events.md).
- In shell form, wrap each path placeholder such as `${CLAUDE_PLUGIN_ROOT}` in double quotes, or set `args` to run
  the command in exec form with no shell.
  See [configuring.md › Command hooks: exec form and shell form](configuring.md).

## Topics

- [placing.md](placing.md): deciding where a hook is defined and what it applies to (settings locations and merging,
  managed and server-managed delivery, plugin `hooks/hooks.json`, manifest and marketplace `hooks`, skill and subagent
  frontmatter, path placeholders, worktrees and `/cd`, when edits take effect)
  - Settings locations and merging
  - Managed and server-managed delivery
  - Plugin hooks
  - Plugin manifest and marketplace entry hooks
  - Plugin paths, data and updates
  - Skill and subagent frontmatter
  - Path placeholders, worktrees and `/cd`
  - When edits take effect
  - Not stated by the documentation

- [configuring.md](configuring.md): writing a hook's settings entry (structure, matchers including MCP tools, `if`,
  handler types and fields, exec and shell form, PowerShell, timeouts, async hooks, the environment hook processes get,
  security practices)
  - Structure of an entry
  - Matchers
  - Matching MCP tools
  - Filtering with `if`
  - Handler types and common fields
  - Command hooks: exec form and shell form
  - Plugin options and path placeholders in hook commands
  - PowerShell hooks
  - HTTP hooks
  - MCP tool hooks
  - Async hooks
  - The environment hook processes get
  - Security practices

- [prompt-and-agent.md](prompt-and-agent.md): writing a prompt or agent hook (supported events, configuration, response
  schema, model)
  - Supported events
  - Prompt hooks
  - Response schema
  - Agent hooks
  - Not stated by the documentation

- [input-output.md](input-output.md): reading a hook's input and returning its result (common input fields, exit codes,
  stdout and stderr, JSON output, `additionalContext`, `systemMessage`, terminal notifications, HTTP responses,
  combining results)
  - Input
  - Exit codes
  - Exit code 2 behavior per event
  - Plain text and JSON on stdout
  - JSON output
  - Add context for Claude
  - Terminal notifications
  - HTTP hooks
  - Decision control
  - Combining results from several hooks
  - Timeouts

- [tool-events.md](tool-events.md): hooking a tool call (PreToolUse and per-tool input, defer, PermissionRequest and
  permission updates, PostToolUse, PostToolUseFailure, PostToolBatch, PermissionDenied, and how hook decisions meet
  permission rules, modes, auto mode and mods)
  - PreToolUse
  - PermissionRequest
  - PostToolUse
  - PostToolUseFailure
  - PostToolBatch
  - PermissionDenied
  - Hook decisions and permission rules
  - Hook decisions and permission modes
  - Auto mode and hooks
  - Mods and hooks
  - IDE tools in hooks
  - Not stated by the documentation

- [events.md](events.md): hooking every other event (the lifecycle and cadence, and for each non-tool event when it
  fires, its matcher, input and output)
  - Lifecycle and cadence
  - SessionStart
  - Setup
  - UserPromptSubmit
  - UserPromptExpansion
  - MessageDisplay
  - SubagentStart
  - SubagentStop
  - TaskCreated
  - TaskCompleted
  - Stop
  - StopFailure
  - TeammateIdle
  - Notification
  - ConfigChange
  - CwdChanged
  - DirectoryAdded
  - FileChanged
  - WorktreeCreate
  - WorktreeRemove
  - PreCompact
  - PostCompact
  - PreModelSwitch
  - PostModelSwitch
  - SessionEnd
  - Elicitation
  - ElicitationResult
  - Not stated by the documentation

- [excluding.md](excluding.md): turning hooks off or restricting them (`disableAllHooks`, `allowManagedHooksOnly`, HTTP
  allowlists, `strictPluginOnlyCustomization.hooks`, workspace trust, `--bare`, `--safe-mode`, the sandbox boundary,
  reviewing plugins)
  - Turning all hooks off
  - Restricting hooks to managed ones
  - HTTP hook allowlists
  - Workspace trust
  - Subagent frontmatter hooks and trust
  - Session flags and environment variables
  - The sandbox boundary
  - Reviewing a plugin's hooks
  - Not stated by the documentation

- [troubleshooting.md](troubleshooting.md): checking whether a hook runs and why not (`/hooks`, the debug log, error
  notices, validation, plugin hook errors, OpenTelemetry hook events)
  - Check that a hook loaded
  - See what a hook did
  - A hook never fires
  - Hook error notices
  - Hook JSON has no effect
  - Stop hook hits the block cap
  - Limitations
  - Plugin hooks
  - Hooks and worktrees
  - Trust and skipped hooks
  - OpenTelemetry hook events and spans

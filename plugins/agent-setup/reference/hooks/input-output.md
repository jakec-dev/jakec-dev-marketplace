# Hook input and output

Reading a hook's input and returning its result: common input fields, exit codes, stdout and stderr, JSON output,
context, terminal notifications, HTTP responses and combined results.

## Contents

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

## Input

- Command hooks receive JSON on stdin and communicate results through exit codes, stdout and stderr. HTTP hooks receive
  the same JSON as the POST request body and communicate results through the HTTP response body.
  [hooks › Hook input and output](https://code.claude.com/docs/en/hooks#hook-input-and-output)
- Every event includes common fields such as `session_id` and `cwd`, and each event type adds its own data. A
  `UserPromptSubmit` hook gets `prompt` text, and a `SessionStart` hook gets a `source` of `startup`, `resume`,
  `clear`, `compact` or `fork`.
  [hooks-guide › Hook input](https://code.claude.com/docs/en/hooks-guide#hook-input)
- On macOS and Linux, command hooks run in their own session without a controlling terminal, so the hook process and
  its children can't open `/dev/tty` or send escape sequences directly to the Claude Code interface. Windows has no
  `/dev/tty`. To surface a message to the user on any platform, return `systemMessage` in JSON output; some events
  discard it or deliver it elsewhere. To trigger a desktop notification, set a window title or ring the bell, return
  `terminalSequence` instead.
  [hooks › Hook input and output](https://code.claude.com/docs/en/hooks#hook-input-and-output)
- A hook process inherits the parent environment, apart from the `OTEL_*` exporter variables that Claude Code removes
  from every subprocess it spawns and, when `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` is set to `1`, the variables it strips.
  [hooks › Common input fields](https://code.claude.com/docs/en/hooks#common-input-fields)

Common input fields, in addition to each event's own fields:
[hooks › Common input fields](https://code.claude.com/docs/en/hooks#common-input-fields)

| Field | Description |
| :- | :- |
| `session_id` | Current session identifier |
| `prompt_id` | UUID identifying the user prompt currently being processed. Matches the [`prompt.id` attribute on OpenTelemetry events](https://code.claude.com/docs/en/monitoring-usage#event-correlation-attributes), so you can correlate hook output with telemetry for a single prompt. Absent until the first user input |
| `transcript_path` | Path to conversation JSON. The transcript file is written asynchronously and may lag the in-memory conversation, so it may not yet include the current turn's most recent messages when a hook fires. Hooks that need the final assistant text of the current turn should use `last_assistant_message` on [Stop](https://code.claude.com/docs/en/hooks#stop) and [SubagentStop](https://code.claude.com/docs/en/hooks#subagentstop) instead of reading the transcript |
| `cwd` | Current working directory when the hook is invoked |
| `scratchpad_dir` | Path to the session's [scratchpad directory](https://code.claude.com/docs/en/claude-directory#session-scratchpad-directory), where Claude keeps temporary working files. Absent when the session has no scratchpad or the temp directory is unavailable |
| `permission_mode` | Current [permission mode](https://code.claude.com/docs/en/permissions#permission-modes): `"default"`, `"plan"`, `"acceptEdits"`, `"auto"`, `"dontAsk"`, or `"bypassPermissions"`. The mode labeled **Manual** arrives as `"default"`, never as `"manual"`, so scripts that match `"default"` keep working. Not all events receive this field. Check the JSON example in each [hook event](https://code.claude.com/docs/en/hooks#hook-events) section |
| `effort` | Object with a `level` field holding the [effort level](https://code.claude.com/docs/en/model-config#adjust-effort-level) in effect when the hook runs: `"low"`, `"medium"`, `"high"`, `"xhigh"`, or `"max"`. If you set a level the active model doesn't support, `level` reports the level Claude Code ran instead; [Adjust effort level](https://code.claude.com/docs/en/model-config#adjust-effort-level) says how it picks that level. The object matches the [status line](https://code.claude.com/docs/en/statusline#available-data) `effort` field. Present for events that fire within a tool-use context, such as `PreToolUse`, `PostToolUse`, `Stop`, and `SubagentStop`, when the current model supports the effort parameter. The level is also available to hook commands and the Bash tool as the `$CLAUDE_EFFORT` environment variable. |
| `hook_event_name` | Name of the event that fired |

When running with `--agent` or inside a subagent, two additional fields are included:

| Field | Description |
| :- | :- |
| `agent_id` | Unique identifier for the subagent. Present only when the hook fires inside a subagent call. Use this to distinguish subagent hook calls from main-thread calls. |
| `agent_type` | Agent name (for example, `"Explore"` or `"security-reviewer"`). Present when the session uses `--agent` or the hook fires inside a subagent. For subagents, the subagent's type takes precedence over the session's `--agent` value. See [SubagentStart](https://code.claude.com/docs/en/hooks#subagentstart) for the values custom and plugin subagents report and how to write a matcher against a plugin-scoped name. |

- A session has a scratchpad only when all of these hold: you're signed in with a claude.ai account rather than an API
  key; the session uses the Anthropic API, not Amazon Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry; and
  `enableArtifact` isn't set to `false`.
  [claude-directory › Session scratchpad directory](https://code.claude.com/docs/en/claude-directory#session-scratchpad-directory)
- Only `SessionStart` hooks can receive a `model` field, and Claude Code doesn't always include it. `PreModelSwitch`
  and `PostModelSwitch` hooks receive `from_model` and `to_model` instead, so use a PostModelSwitch hook to follow the
  model as it changes during a session. There is no `$CLAUDE_MODEL` environment variable; the hook can read
  `$ANTHROPIC_MODEL` if you set it in your shell, but that value doesn't change when you switch models with `/model`
  during a session.
  [hooks › Common input fields](https://code.claude.com/docs/en/hooks#common-input-fields)
- A `PreToolUse` hook for a Bash command receives this on stdin; `tool_name`, `tool_input` and `tool_use_id` are
  event-specific.
  [hooks › Common input fields](https://code.claude.com/docs/en/hooks#common-input-fields)

```json
{
  "session_id": "abc123",
  "prompt_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_path": "/home/user/.claude/projects/.../transcript.jsonl",
  "cwd": "/home/user/my-project",
  "scratchpad_dir": "/tmp/claude-1000/-home-user-my-project/abc123/scratchpad",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test",
    "description": "Run test suite",
    "timeout": 120000,
    "run_in_background": false
  },
  "tool_use_id": "toolu_01ABC123..."
}
```

- Hooks run outside the main conversation and load nothing by default. Their context cost is zero, unless the hook
  returns output that gets added as messages to the conversation. Hooks are ideal for side effects (linting, logging)
  that don't need to affect Claude's context.
  [features-overview › Understand how features load](https://code.claude.com/docs/en/features-overview#understand-how-features-load)

## Exit codes

- The exit code tells Claude Code whether the action should proceed, be blocked, or be ignored, but it doesn't act
  alone. Claude Code reads JSON output fields from stdout on every exit code, not just 0, and for events that use the
  standard decision model, a parsed object that passes schema validation takes effect alongside the code. Exit 2's
  block is the one outcome JSON can't override.
  [hooks › Exit code output](https://code.claude.com/docs/en/hooks#exit-code-output)
- Exit code 2 behavior per event says what exit codes do for each event, and Decision control says which decision
  fields each event honors. Universal fields such as `systemMessage` work across most events and are listed in the
  JSON output table.
  [hooks › Exit code output](https://code.claude.com/docs/en/hooks#exit-code-output)
- Exit 0 means success, and is the intended exit code when you print JSON for structured control. For a `PreToolUse`
  hook it doesn't approve the tool call: the normal permission flow still applies.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
  and [hooks-guide › Hook output](https://code.claude.com/docs/en/hooks-guide#hook-output)
- Stderr from a hook that exits 0 goes to the debug log only, never the transcript, and Claude never sees it. To
  surface a warning to Claude from a `PostToolUse` or `PostToolUseFailure` hook, exit 2 instead so Claude sees the
  stderr even though the tool already ran.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
- Exit 2 means a blocking error. On events that can block, exit 2 blocks whether or not you print JSON: even a JSON
  `permissionDecision` of `"allow"` can't override it. Claude Code still reads any valid JSON output on stdout, except
  that on `Elicitation` and `ElicitationResult`, an exit-2 hook's `hookSpecificOutput` is ignored.
  [hooks › Exit code 2](https://code.claude.com/docs/en/hooks#exit-code-2)
- The blocking message is the reason from your JSON's blocking decision when it makes one, and your stderr text
  otherwise. What the block does varies by event: `PreToolUse` blocks the tool call, `UserPromptSubmit` rejects the
  prompt, and so on. Where the message goes depends on the event: some events feed it to Claude as feedback, others
  show it to the user, and a few, such as `ConfigChange` and `Elicitation`, surface no message.
  [hooks › Exit code 2](https://code.claude.com/docs/en/hooks#exit-code-2)
  and [hooks-guide › Hook output](https://code.claude.com/docs/en/hooks-guide#hook-output)
- A hook that exits 2 while printing JSON that fails JSON output schema validation still blocks: Claude Code uses
  stderr as the blocking reason and records the validation failure in the debug log.
  [hooks › Exit code 2](https://code.claude.com/docs/en/hooks#exit-code-2)
- This script blocks `rm` commands by exiting 2 and leaves every other command to the normal permission flow.
  [hooks › Exit code 2](https://code.claude.com/docs/en/hooks#exit-code-2)

```bash
#!/bin/bash
# Reads JSON input from stdin, checks the command
input=$(cat)
command=$(jq -r '.tool_input.command' <<<"$input")

if [[ "$command" == rm* ]]; then
  echo "Blocked: rm commands are not allowed" >&2
  exit 2  # Blocking error: tool call is prevented
fi

exit 0  # No decision: the normal permission flow applies
```

- For most hook events, exit code 2 is the only exit code that blocks through the code alone. Without valid JSON on
  stdout, Claude Code treats exit code 1 as a non-blocking error and proceeds with the action, even though 1 is the
  conventional Unix failure code, so a hook meant to enforce a policy must use `exit 2`. The worktree events differ:
  any non-zero exit code from `WorktreeCreate` aborts worktree creation, and any non-zero exit code from
  `WorktreeRemove` makes worktree removal fail if the directory still exists afterward.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)
- Any other exit code doesn't block on its own for most hook events; what happens depends on your stdout. With a
  parsed object that passes schema validation, for events that use the standard decision model, Claude Code ignores the
  exit code and the JSON alone decides the outcome: each field the event supports is honored, including
  `permissionDecision`, `additionalContext`, `updatedInput` and `systemMessage`, and the hook isn't reported as an
  error.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)
- With a parsed object that fails schema validation, or with stdout that Claude Code tries to parse as JSON and can't,
  for events that use the standard decision model, it's a non-blocking error on any exit code other than 2: the action
  proceeds, and the `<hook name> hook error` notice carries the validation or parse message.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)
- With stdout that Claude Code treats as plain text, or with empty stdout, it's a non-blocking error for most hook
  events: the action proceeds, and the transcript shows a `<hook name> hook error` notice followed by the first line of
  stderr, prefixed with `Failed with non-blocking status code:`. To capture the full stderr, enable debug logging with
  `claude --debug` or by running `/debug` mid-session.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)
  and [hooks-guide › Hook output](https://code.claude.com/docs/en/hooks-guide#hook-output)
- Events outside the standard decision model keep their own rows in the per-event table: `WorktreeCreate` fails
  creation on any nonzero exit no matter what your JSON says, and events that discard hook output entirely, like
  `StopFailure`, ignore your JSON on every exit code, apart from side-effect fields like `terminalSequence`, which
  still fire.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)
- A hook that can't start lands in the same non-blocking bucket. When the script path doesn't exist or isn't
  executable, the shell exits with a code like 127 and you see the same notice with the interpreter's message, such as
  `Failed with non-blocking status code: /bin/sh: /path/to/hook.sh: No such file or directory`. For most hook events,
  the action proceeds, so a mistyped path in `settings.json` leaves a policy hook's gate silently disabled; watch for
  this notice on its first run.
  [hooks › Other exit codes](https://code.claude.com/docs/en/hooks#other-exit-codes)

## Exit code 2 behavior per event

Exit code 2 is the way a hook signals "stop, don't do this." The effect depends on the event, because some events
represent actions that can be blocked (like a tool call that hasn't happened yet) and others represent things that
already happened or can't be prevented.
[hooks › Exit code 2 behavior per event](https://code.claude.com/docs/en/hooks#exit-code-2-behavior-per-event)

| Hook event | Can block? | What happens on exit 2 |
| :- | :- | :- |
| `PreToolUse` | Yes | Blocks the tool call |
| `PermissionRequest` | No | Exit code 2 isn't honored for this event and the permission flow proceeds unchanged. Deny through the [`decision` object](https://code.claude.com/docs/en/hooks#permissionrequest-decision-control) instead |
| `UserPromptSubmit` | Yes | Blocks the prompt, so it never reaches Claude. See [What a blocked prompt leaves behind](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind) |
| `UserPromptExpansion` | Yes | Blocks the expansion |
| `Stop` | Yes | Prevents Claude from stopping, continues the conversation |
| `SubagentStop` | Yes | Prevents the subagent from stopping |
| `TeammateIdle` | Yes | Prevents the teammate from going idle, so it continues working |
| `TaskCreated` | Yes | Rolls back the task creation |
| `TaskCompleted` | Yes | Prevents the task from being marked as completed |
| `ConfigChange` | Yes | Blocks the configuration change from taking effect (except `policy_settings`) |
| `StopFailure` | No | Output and exit code are ignored, except `terminalSequence` |
| `PostToolUse` | No | Shows stderr to Claude; the tool already ran |
| `PostToolUseFailure` | No | Shows stderr to Claude; the tool already failed |
| `PostToolBatch` | Yes | Stops the agentic loop before the next model call |
| `PermissionDenied` | No | Exit code and stderr are ignored because the denial already occurred. Use JSON `hookSpecificOutput.retry: true` to tell the model it may retry; Claude Code ignores `retry: true` for [no-verdict denials](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control) |
| `Notification` | No | Exit code and stderr are ignored |
| `SubagentStart` | No | Shows stderr to user only |
| `SessionStart` | No | Shows stderr to user only |
| `Setup` | No | Exit code and stderr are ignored |
| `SessionEnd` | No | Shows stderr to user only |
| `CwdChanged` | No | Shows stderr to user only |
| `DirectoryAdded` | No | Stderr goes to the debug log; the directory is already added |
| `FileChanged` | No | Shows stderr to user only |
| `PreCompact` | Yes | Blocks compaction |
| `PostCompact` | No | Shows stderr to user only |
| `PreModelSwitch` | Yes | Blocks the model switch and shows stderr to the user |
| `PostModelSwitch` | No | Shows stderr to user only; the model already switched |
| `Elicitation` | Yes | Denies the elicitation |
| `ElicitationResult` | Yes | Blocks the response (action becomes decline) |
| `WorktreeCreate` | Yes | Any non-zero exit code causes worktree creation to fail |
| `WorktreeRemove` | Yes | Any non-zero exit code causes worktree removal to fail if the directory still exists afterward. See [WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove) for what happens to the directory |
| `MessageDisplay` | No | The original text is displayed |

- For `SessionStart`, `SubagentStart` and `PostModelSwitch`, Claude Code renders the exit code 2 stderr in the
  transcript as a `<hook name> hook error` notice, the same way it renders a non-blocking error. Claude doesn't see
  it, and the session or subagent proceeds. For `SubagentStart`, the notice appears in the subagent's own transcript,
  not in the parent conversation.
  [hooks › Exit code 2 behavior per event](https://code.claude.com/docs/en/hooks#exit-code-2-behavior-per-event)

## Plain text and JSON on stdout

- For most events, Claude Code writes stdout to the debug log and doesn't show it in the transcript. The exceptions
  are `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart` and `PostModelSwitch`, where Claude Code adds
  plain-text stdout as context that Claude can see and act on.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
- Whether Claude Code reads stdout as JSON or as plain text depends on how it starts and ends, ignoring surrounding
  whitespace. Starting with `{` and ending with `}`: it parses it as JSON. Starting with `{` but not ending with `}`:
  plain text. Starting with anything else, a JSON array or a quoted JSON string included: plain text.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
- When stdout that starts with `{` and ends with `}` is two or more lines that each parse as JSON on their own, and no
  line is a JSON output object that sets a field, Claude Code treats the whole output as plain text. When one of those
  lines does set a field, the whole output is a parse failure.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
- For events that use the standard decision model, exit 0 with a parsed object that fails schema validation is a
  non-blocking error: the action proceeds, and the transcript shows a `<hook name> hook error` notice with the
  validation message. The same happens on any exit code other than 2, while exit 2 still blocks.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)
- For events that use the standard decision model, when Claude Code tries to parse your stdout as JSON and can't, it
  reports a non-blocking error on every exit code other than 2, with a `<hook name> hook error` notice carrying the
  parse message. On the events that add plain-text stdout as context, Claude Code doesn't add the text.
  [hooks › Exit code 0](https://code.claude.com/docs/en/hooks#exit-code-0)

## JSON output

- Instead of exiting with code 2 to block, exit 0 and print a JSON object to stdout. Claude Code reads specific fields
  from that JSON to control behavior, including decision control for blocking, allowing or escalating to the user.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)
  and [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)
- Choose one approach per hook: either use exit codes alone for signaling, or exit 0 and print JSON for structured
  control. If you mix them, exit 2 keeps its blocking effect, and Claude Code still reads the JSON fields, with the one
  elicitation exception noted under exit code 2.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)
- Your hook's stdout must contain only the JSON object. If your shell profile prints text on startup, it can interfere
  with JSON parsing.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)
- A hook's `additionalContext`, `systemMessage` and `initialUserMessage` strings, and its plain stdout, are capped at
  10,000 characters. Claude Code measures each string on its own, even when several hooks run for the same event: for
  JSON output each field is measured separately, and plain stdout is measured whole.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)
- Over the limit, Claude Code saves the output to a file in the session directory and replaces it with the file path
  and a preview of up to the first 2,000 characters. This cap has no setting or environment variable to raise it.
  Claude Code doesn't ask Claude to read the file, so keep anything Claude must always see within the cap; for
  `additionalContext`, Claude can read the file.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output), [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- The JSON object supports three kinds of fields. Universal fields like `continue` are accepted by every event, but
  some events discard them or deliver `systemMessage` somewhere other than the transcript; each event's section says
  so. `terminalSequence` works on those events too, with the exceptions under Terminal notifications. Top-level
  `decision` and `reason` are used by some events to block or provide feedback. `hookSpecificOutput` is a nested object
  for events that need richer control and requires a `hookEventName` field set to the event name.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)

| Field | Default | Description |
| :- | :- | :- |
| `continue` | `true` | If `false`, Claude stops processing entirely after the hook runs. Takes precedence over any event-specific decision fields |
| `stopReason` | none | Message shown to the user when `continue` is `false`. It stays in the conversation, so Claude sees it if the conversation continues |
| `suppressOutput` | `false` | Has no effect: Claude Code accepts the field but doesn't act on it. A successful hook's stdout is never shown in the transcript and is recorded in the debug log |
| `systemMessage` | none | Warning message shown to the user. In [Agent SDK](https://code.claude.com/docs/en/agent-sdk/overview) and [`--output-format stream-json`](https://code.claude.com/docs/en/headless) output, it can arrive as an [`SDKInformationalMessage`](https://code.claude.com/docs/en/agent-sdk/typescript#sdkinformationalmessage) |
| `terminalSequence` | none | A terminal escape sequence for Claude Code to emit on your behalf, such as a desktop notification, window title, or bell. Restricted to OSC `0`/`1`/`2`/`9`/`99`/`777` and BEL. If the value contains anything outside the allowlist, the field is ignored. Use this instead of writing to `/dev/tty`, which is unavailable to hooks |

- To stop Claude entirely, return the JSON below. For `PreToolUse` and `PostToolUse` hooks, the stop applies even when
  the tool call fails or completes while Claude is still streaming a response.
  [hooks › JSON output](https://code.claude.com/docs/en/hooks#json-output)

```json
{ "continue": false, "stopReason": "Build failed, fix errors before continuing" }
```

- A `PreToolUse` hook can deny a tool call and tell Claude why by returning `hookSpecificOutput` with
  `hookEventName`, `permissionDecision` and `permissionDecisionReason`. Other events use different decision patterns:
  `PostToolUse` and `Stop` hooks use a top-level `decision: "block"` field, while `PermissionRequest` uses
  `hookSpecificOutput.decision.behavior`.
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Use rg instead of grep for better performance"
  }
}
```

## Add context for Claude

- The `additionalContext` field passes a string from your hook into Claude's context window. Claude Code wraps the
  string in a system reminder and inserts it into the conversation at the point where the hook fired. Claude reads the
  reminder on the next model request, but it doesn't appear as a chat message in the interface.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Return `additionalContext` inside `hookSpecificOutput` alongside the event name.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- For a `UserPromptSubmit` hook, nest `additionalContext` inside `hookSpecificOutput`; if you place it at the top level
  of the JSON, Claude Code silently ignores it.
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "This file is generated. Edit src/schema.ts and run `bun generate` instead."
  }
}
```

- Where the reminder appears depends on the event: `SessionStart` and `SubagentStart` at the start of the
  conversation, before the first prompt; `UserPromptSubmit` and `UserPromptExpansion` alongside the submitted prompt;
  `PreToolUse`, `PostToolUse`, `PostToolUseFailure` and `PostToolBatch` next to the tool result; `Stop` and
  `SubagentStop` at the end of the turn, where the conversation continues so Claude can act on the feedback;
  `PostModelSwitch` with the next request after the switch.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- When several hooks return `additionalContext` for the same event, Claude receives all of the values.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Use `additionalContext` for information Claude should know about the current state of your environment or the
  operation that just ran: environment state (the current branch, deployment target or active feature flags),
  conditional project rules (which test command applies to the file just edited, which directories are read-only in
  this worktree), and external data (open issues assigned to you, recent CI results, content fetched from an internal
  service). For instructions that never change, prefer CLAUDE.md, which loads without running a script.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Write the text as factual statements rather than imperative system instructions. Phrasing such as "The deployment
  target is production" or "This repo uses `bun test`" reads as project information. Text framed as out-of-band system
  commands can trigger Claude's prompt-injection defenses, which causes Claude to surface the text to you instead of
  treating it as context.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Claude Code saves the injected text in the session transcript. For mid-session events like `PostToolUse` or
  `UserPromptSubmit`, when you resume with `--continue` or `--resume`, Claude Code replays the saved text rather than
  re-running the hook for past turns, so values like timestamps or commit SHAs become stale. `SessionStart` hooks run
  again on resume with `source` set to `"resume"`, or `"fork"` if you added `--fork-session`, so they can refresh their
  context.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)

## Terminal notifications

- Return the escape sequence in the `terminalSequence` field and Claude Code emits it through its own terminal write
  path, which is race-free, works inside tmux and GNU screen, and works on Windows.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
  and [hooks › Hook input and output](https://code.claude.com/docs/en/hooks#hook-input-and-output)
- The field accepts a string of one or more allowlisted escape sequences: OSC `0`, `1`, `2` (window and icon titles);
  OSC `9` (iTerm2, ConEmu, Windows Terminal and WezTerm notifications, including `9;4` taskbar progress); OSC `99`
  (Kitty notifications); OSC `777` (urxvt, Ghostty and Warp notifications); and bare BEL. Sequences may be terminated
  with BEL or with ST.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
- Anything outside the allowlist, including CSI cursor and color sequences, OSC palette sequences, OSC 8 hyperlinks,
  OSC 52 clipboard writes and OSC 1337, is rejected and the field is ignored.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
- Claude Code writes the sequence itself when it processes your hook's output, so the field works on events that
  discard `systemMessage` and `continue`, such as `Notification` and `StopFailure`.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
- Claude Code writes the sequence only in an interactive session, and only while its interface is on screen. In
  non-interactive mode with the `-p` flag and in the Agent SDK, it ignores the field.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
- A `WorktreeCreate` command hook can't return JSON, because Claude Code reads its stdout as the worktree path. An HTTP
  `WorktreeCreate` hook returns JSON and can include the field.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)
- This `Notification` hook fires a desktop notification. It builds the escape sequence with `printf` octal escapes so
  the control bytes never appear on the shell command line, and `jq -n --arg` builds the JSON so quotes, backslashes
  and newlines in the message are escaped correctly. The `{ "terminalSequence": "..." }` shape is the same from any
  shell or language.
  [hooks › Emit terminal notifications](https://code.claude.com/docs/en/hooks#emit-terminal-notifications)

```bash
#!/bin/bash
# Notification hook: ping the desktop when Claude Code needs attention.
input=$(cat)
title="Claude Code"
body=$(jq -r '.message // "Needs your attention"' <<<"$input")
seq=$(printf '\033]777;notify;%s;%s\007' "$title" "$body")
jq -nc --arg seq "$seq" '{terminalSequence: $seq}'
```

## HTTP hooks

- HTTP hooks use HTTP status codes and response bodies instead of exit codes and stdout. The outcomes below apply to
  most events; an event with its own failure contract in the per-event table, such as `WorktreeCreate`, applies that
  contract to a failed HTTP hook too.
  [hooks › HTTP response handling](https://code.claude.com/docs/en/hooks#http-response-handling)
- 2xx with an empty body is success, equivalent to exit code 0 with no output. 2xx with a JSON object body is parsed
  using the same JSON output schema as command hooks, and a body that fails schema validation is a non-blocking error.
  [hooks › HTTP response handling](https://code.claude.com/docs/en/hooks#http-response-handling)
- 2xx with any other body, such as plain text, is a non-blocking error, handled the same as a non-2xx status; Claude
  Code doesn't add the text to Claude's context. A non-2xx status and a connection failure are non-blocking errors and
  execution continues. A timeout cancels the hook, as described under Timeouts.
  [hooks › HTTP response handling](https://code.claude.com/docs/en/hooks#http-response-handling)
- Unlike command hooks, HTTP hooks can't signal a blocking error through status codes alone. To block a tool call or
  deny a permission, return a 2xx response with a JSON body containing the appropriate decision fields.
  [hooks › HTTP response handling](https://code.claude.com/docs/en/hooks#http-response-handling)

## Decision control

- Not every event supports blocking or controlling behavior through JSON, and the events that do each use a different
  set of fields. Use this table as a quick reference before writing a hook.
  [hooks › Decision control](https://code.claude.com/docs/en/hooks#decision-control)

| Events | Decision pattern | Key fields |
| :- | :- | :- |
| UserPromptSubmit, UserPromptExpansion, PostToolUse, PostToolUseFailure, PostToolBatch, Stop, SubagentStop, ConfigChange, PreCompact | Top-level `decision` | `decision: "block"`, `reason`. Stop and SubagentStop also accept `hookSpecificOutput.additionalContext` for [non-error feedback that continues the conversation](https://code.claude.com/docs/en/hooks#stop-decision-control) |
| TeammateIdle, TaskCompleted | Exit code or `continue: false` | Exit code 2 blocks the action with stderr feedback. JSON `{"continue": false, "stopReason": "..."}` also stops the teammate entirely, matching `Stop` hook behavior; [TaskCompleted ignores it when the `TaskUpdate` tool triggered the event](https://code.claude.com/docs/en/hooks#taskcompleted-decision-control) |
| TaskCreated | Exit code or top-level `decision` | Exit code 2 or `decision: "block"` [cancels the task](https://code.claude.com/docs/en/hooks#taskcreated-decision-control) and returns the message to Claude. `continue: false` is ignored |
| PreToolUse | `hookSpecificOutput` | `permissionDecision` (allow/deny/ask/defer), `permissionDecisionReason` |
| PreModelSwitch | `hookSpecificOutput` or top-level `decision` | `permissionDecision` (allow/deny/ask), `permissionDecisionReason`. `decision: "block"` also [cancels the switch](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control) |
| PermissionRequest | `hookSpecificOutput` | `decision.behavior` (allow/deny) |
| PermissionDenied | `hookSpecificOutput` | `retry: true` tells the model it may retry the denied tool call; Claude Code ignores it for [no-verdict denials](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control) |
| WorktreeCreate | path return | Command hook prints path on stdout; HTTP hook returns `hookSpecificOutput.worktreePath`. Hook failure or missing path fails creation |
| WorktreeRemove | Exit code | Any non-zero exit code makes the removal fail if the directory still exists afterward. JSON output is discarded |
| Elicitation | `hookSpecificOutput` | `action` (accept/decline/cancel), `content` (form field values for accept) |
| ElicitationResult | `hookSpecificOutput` | `action` (accept/decline/cancel), `content` (form field values override) |
| MessageDisplay | `hookSpecificOutput` | `displayContent` replaces the displayed text on screen. Display-only: the transcript and what Claude sees keep the original |
| SessionStart, SubagentStart, PostModelSwitch | Context only | `hookSpecificOutput.additionalContext` adds context for Claude. SessionStart also accepts [`initialUserMessage`, `watchPaths`, `sessionTitle`, and `reloadSkills`](https://code.claude.com/docs/en/hooks#sessionstart-decision-control). No blocking or decision control |
| Setup, Notification, SessionEnd, PostCompact, InstructionsLoaded, StopFailure, CwdChanged, DirectoryAdded, FileChanged | None | No decision control. Used for side effects like logging or cleanup |

- A few events can also rewrite content rather than only allow or block it: `PreToolUse` with `updatedInput` directly
  under `hookSpecificOutput`, which replaces a tool's arguments before it runs; `PermissionRequest` with
  `updatedInput` inside the `decision` object; `PostToolUse` with `updatedToolOutput`, which replaces the tool's
  result. `UserPromptSubmit` can't replace the prompt; it only injects `additionalContext` alongside it. For redaction
  or transformation, intercept at `PreToolUse` for outbound tool inputs and `PostToolUse` for inbound tool results.
  [hooks › Decision control](https://code.claude.com/docs/en/hooks#decision-control)
- The only value for top-level `decision` is `"block"`. To allow the action to proceed, omit `decision` from your JSON,
  or exit 0 without any JSON at all.
  [hooks › Decision control](https://code.claude.com/docs/en/hooks#decision-control)

```json
{
  "decision": "block",
  "reason": "Test suite must pass before proceeding"
}
```

- A `PermissionRequest` hook allows or denies a permission request on behalf of the user through
  `hookSpecificOutput.decision`; when allowing, it can also modify the tool's input or apply permission rules so the
  user isn't prompted again. This example allows with `updatedInput`.
  [hooks › Decision control](https://code.claude.com/docs/en/hooks#decision-control)

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow",
      "updatedInput": {
        "command": "npm run lint"
      }
    }
  }
}
```

## Combining results from several hooks

- When multiple hooks match the same event, every hook's command runs to completion before Claude Code merges the
  results. One hook returning `deny` doesn't stop sibling hooks from executing, so don't rely on one hook's `deny` to
  suppress side effects in another hook.
  [hooks-guide › Combine results from multiple hooks](https://code.claude.com/docs/en/hooks-guide#combine-results-from-multiple-hooks)
- For `PreToolUse` permission decisions, the most restrictive decision applies. Text from `additionalContext` is kept
  from every hook and passed to Claude together.
  [hooks-guide › Combine results from multiple hooks](https://code.claude.com/docs/en/hooks-guide#combine-results-from-multiple-hooks)
- In this example, two `PreToolUse` hooks on `Bash` both run in parallel. The first appends every command to a log file
  and exits 0, which reports no decision. The second runs a script that exits 2 to deny when the command contains
  `rm -rf`. The deny takes precedence, so Claude Code blocks the command and shows Claude the guardrail's stderr, and
  the log entry is still written because the logging hook already ran.
  [hooks-guide › Combine results from multiple hooks](https://code.claude.com/docs/en/hooks-guide#combine-results-from-multiple-hooks)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r .tool_input.command >> ~/.claude/bash.log"
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm-rf.sh"
          }
        ]
      }
    ]
  }
}
```

## Timeouts

- Apart from a command hook you run with `async: true`, Claude Code cancels a `command`, `http` or `mcp_tool` hook that
  reaches its `timeout`, discarding the hook's output, so on most events a timed-out hook renders no decision.
  [hooks › Timeouts](https://code.claude.com/docs/en/hooks#timeouts)
- On `PreModelSwitch`, a hook canceled at its timeout blocks the model switch.
  [hooks › Timeouts](https://code.claude.com/docs/en/hooks#timeouts)
- On `PreToolUse`, a timed-out `command`, `http` or `mcp_tool` hook doesn't block the tool call: the call continues
  through the normal permission flow, so don't count on a stalled hook to act as a gate. An Agent SDK callback hook
  that exceeds its timeout blocks the tool call.
  [hooks › Timeouts](https://code.claude.com/docs/en/hooks#timeouts)

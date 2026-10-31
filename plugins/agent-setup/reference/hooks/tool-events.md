# Tool events

Hooking a tool call: `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch` and
`PermissionDenied`, and how hook decisions meet permission rules, permission modes, auto mode and mods.

## Contents

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

## PreToolUse

### When it fires and what it matches

- `PreToolUse` runs after Claude creates tool parameters and before processing the tool call. It matches on any tool
  name except [`EndConversation`](https://code.claude.com/docs/en/tools-reference#endconversation-tool-behavior): built-in tools such as `Bash`, `PowerShell`, `Edit`, `Write`, `Read`, `Glob`, `Grep`,
  `Agent`, `Workflow`, `WebFetch`, `WebSearch`, `AskUserQuestion`, and `ExitPlanMode`, and any MCP tool names.
  [hooks › PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)
- `PreToolUse` runs only when Claude calls a tool. Files you reference with `@` in your prompt are added without any
  tool call, because Claude Code inserts their contents while building the prompt, so no `PreToolUse` hook fires for
  them, including hooks matching `Read`. To block specific paths from `@` references, use a
  [`Read` deny rule](https://code.claude.com/docs/en/permissions#read-and-edit) instead.
  [hooks › PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)
- To run a hook when a specific file changes on disk, whatever wrote it, use `FileChanged` instead of matching
  file-editing tools by name. Unlike `PreToolUse`, Claude Code runs `FileChanged` hooks after the change, and they have
  no decision control, so they can't block the write.
  [hooks › PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)

### Input

- In addition to the common input fields, `PreToolUse` hooks receive `tool_name`, `tool_input`, and `tool_use_id`.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)
- For an MCP tool, the input also carries `mcp_server`, an object with the server's `name` and a `source` that says
  where the server's definition came from. The `source` values include `plugin`, `sdk`, and configuration scopes such
  as `user` and `project`. Base trust decisions on `source` rather than on `name` or the `mcp__<server>__` tool-name
  prefix. The Agent SDK reference's
  [`McpServerProvenance`](https://code.claude.com/docs/en/agent-sdk/typescript#mcpserverprovenance) lists all the
  values and says how to treat one you don't recognize.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)
- For the file tools `Write`, `Edit`, and `Read`, `tool_input.file_path` is always absolute. Claude Code expands `~` and
  relative paths before hooks run, so a hook that matches on paths can't be bypassed via `~` or a relative spelling of
  the same path.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)
  - On Windows, the path arrives with backslash separators, even when your hook runs under Git Bash where `$PWD` looks
    like `/c/project`.
  - A comparison written with forward slashes, such as a `/src/` check, never matches a backslash path, and the tool
    call proceeds as if the hook had nothing to block.
  - Normalize separators before comparing: `FILE_PATH="${FILE_PATH//\\//}"` in Bash, or
    `file_path.replace("\\", "/")` in Python, then match a path segment such as `/src/` rather than anchoring with `^`,
    since the path is absolute.
- A `Write` call on Windows delivers:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

  ```json
  {
    "hook_event_name": "PreToolUse",
    "tool_name": "Write",
    "tool_input": {
      "file_path": "C:\\project\\src\\index.ts",
      "content": "..."
    },
    ...
  }
  ```

### `tool_input` by tool

The `tool_input` fields depend on the tool.
[hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

#### Bash

- `Bash` executes shell commands. Its `tool_input` fields:
  [hooks › Bash](https://code.claude.com/docs/en/hooks#bash)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `command` | string | `"npm test"` | The shell command to execute |
| `description` | string | `"Run test suite"` | Optional description of what the command does |
| `timeout` | number | `120000` | Optional timeout in milliseconds. Values above the [maximum](https://code.claude.com/docs/en/tools-reference#bash-tool-behavior) are reduced to the maximum rather than rejected |
| `run_in_background` | boolean | `false` | Whether to run the command in background |

- When a Bash command changes files in a Git repository, Claude Code can record what changed. It records the changes in
  every permission mode when the `bashEditDiffEnabled` setting turns recording on. Otherwise it records them only in
  auto mode and `bypassPermissions` mode, and only when Claude Code directs Claude to edit files through Bash. Set
  `bashEditDiffEnabled` to `false` to turn the recording off. Background commands and read-only commands carry no diff.
  [hooks › Bash](https://code.claude.com/docs/en/hooks#bash)
- A `PostToolUse` hook for a Bash call then receives the changed files in `tool_response.bashEditDiff`. The list covers
  what changed under the repository while the command ran. Files that Git ignores and files in submodules aren't
  listed. The list is best effort and in public beta: Claude Code can miss a change, include a file that another
  process changed at the same time, or stop at its size limits, and the field shape may change. Use the list to find
  what to review, not to enforce a policy.
  [hooks › Bash](https://code.claude.com/docs/en/hooks#bash) and
  [settings-reference › `bashEditDiffEnabled`](https://code.claude.com/docs/en/settings-reference#basheditdiffenabled)
- In `tool_response.bashEditDiff`, `changedFiles` and `files` list what the command changed; the remaining fields say
  how complete and how reliable that list is:
  [hooks › Bash](https://code.claude.com/docs/en/hooks#bash)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `changedFiles` | array | `["/path/to/src/app.ts"]` | Absolute paths of the files the command changed, at most 200. Present whenever `files` holds a diff or `moreFiles` is above zero |
| `files` | array | `[{"filePath": "/path/to/src/app.ts", "hunks": [...]}]` | Diffs of up to 5 changed files, for display. `created` or `deleted` is `true` for a file the command added or removed |
| `moreFiles` | number | `2` | Count of changed files with no diff in `files` |
| `unavailable` | boolean | `true` | Set when the diff is incomplete or couldn't be taken |
| `skipped` | boolean | `true` | Set for a Git command that moves the working tree, such as `git checkout` or `git stash`, so Claude Code takes no diff |
| `shared` | boolean | `true` | Set when another Bash tool call, such as a subagent's, ran in the same repository at the same time, so some listed changes may be that command's |

- On macOS, Linux, and WSL, Claude Code leaves the Glob and Grep tools out of the default tool set, so Claude searches
  with `find` and `grep` through the Bash tool. Those searches reach your hooks and permission rules as `Bash` calls.
  [tools-reference › Glob tool behavior](https://code.claude.com/docs/en/tools-reference#glob-tool-behavior)

#### PowerShell

- `PowerShell` executes PowerShell commands. Its fields match the Bash tool, with the command string in `command`:
  [hooks › PowerShell](https://code.claude.com/docs/en/hooks#powershell)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `command` | string | `"Get-ChildItem -Recurse"` | The PowerShell command to execute |
| `description` | string | `"List files recursively"` | Optional description of what the command does |
| `timeout` | number | `120000` | Optional timeout in milliseconds |
| `run_in_background` | boolean | `false` | Whether to run the command in background |

- Match `Bash|PowerShell` in hooks that inspect shell commands, so they cover both tools.
  [hooks › PowerShell](https://code.claude.com/docs/en/hooks#powershell)
  - On Windows, wherever the PowerShell tool is enabled, Claude treats PowerShell as the primary shell and routes shell
    commands through it.
  - On Windows without Git Bash, the tool is enabled automatically and Claude Code doesn't register the Bash tool at
    all.
  - A hook that matches only `Bash` never fires there.

#### Write

- `Write` creates or overwrites a file:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `file_path` | string | `"/path/to/file.txt"` | Absolute path to the file to write |
| `content` | string | `"file content"` | Content to write to the file |

#### Edit

- `Edit` replaces a string in an existing file:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `file_path` | string | `"/path/to/file.txt"` | Absolute path to the file to edit |
| `old_string` | string | `"original text"` | Text to find and replace |
| `new_string` | string | `"replacement text"` | Replacement text |
| `replace_all` | boolean | `false` | Whether to replace all occurrences |

#### Read

- `Read` reads file contents:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `file_path` | string | `"/path/to/file.txt"` | Absolute path to the file to read |
| `offset` | number | `10` | Optional line number to start reading from |
| `limit` | number | `50` | Optional number of lines to read |

#### Glob

- `Glob` finds files matching a glob pattern:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `pattern` | string | `"**/*.ts"` | Glob pattern to match files against |
| `path` | string | `"/path/to/dir"` | Optional directory to search in. Defaults to current working directory |

#### Grep

- `Grep` searches file contents with regular expressions:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `pattern` | string | `"TODO.*fix"` | Regular expression pattern to search for |
| `path` | string | `"/path/to/dir"` | Optional file or directory to search in |
| `glob` | string | `"*.ts"` | Optional glob pattern to filter files |
| `output_mode` | string | `"content"` | `"content"`, `"files_with_matches"`, or `"count"`. Defaults to `"files_with_matches"` |
| `-i` | boolean | `true` | Case insensitive search |
| `multiline` | boolean | `false` | Enable multiline matching |

#### WebFetch

- `WebFetch` fetches and processes web content:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `url` | string | `"https://example.com/api"` | URL to fetch content from |
| `prompt` | string | `"Extract the API endpoints"` | Prompt to run on the fetched content |

#### WebSearch

- `WebSearch` searches the web:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `query` | string | `"react hooks best practices"` | Search query |
| `allowed_domains` | array | `["docs.example.com"]` | Optional: only include results from these domains |
| `blocked_domains` | array | `["spam.example.com"]` | Optional: exclude results from these domains |

#### Agent

- `Agent` spawns a [subagent](https://code.claude.com/docs/en/sub-agents):
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `prompt` | string | `"Find all API endpoints"` | The task for the agent to perform |
| `description` | string | `"Find API endpoints"` | Short description of the task |
| `subagent_type` | string | `"Explore"` | Type of specialized agent to use |
| `model` | string | `"sonnet"` | Optional model alias to override the default |

- When a foreground Agent call completes, your `PostToolUse` hook receives the subagent's result and run telemetry in
  `tool_response`. Read these fields to inspect the run. For token and cost rollups across subagents, use the
  [token and cost counters](https://code.claude.com/docs/en/monitoring-usage#token-counter) filtered to `query_source`
  `"subagent"`, since `totalTokens` and `usage` cover the final request only:
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `status` | string | `"completed"` | `"completed"` for foreground subagents, `"async_launched"` for background subagents. Subagents run in the background by default, so an Agent call that omits `run_in_background` also produces `"async_launched"` |
| `agentId` | string | `"a4d2c8f1e0b3a297"` | Identifier for the subagent run |
| `content` | array | `[{"type": "text", "text": "Found 12 endpoints..."}]` | The subagent's final text blocks, or, for a subagent whose report goes through `SubagentHandback`, a short note about that hand-back in their place |
| `resolvedModel` | string | `"claude-sonnet-4-5"` | Model the subagent started on, which may differ from the requested model |
| `modelsUsed` | array | `["claude-sonnet-4-5", "claude-haiku-4-5"]` | Models used in order, with consecutive repeats collapsed; set only when the model was swapped mid-run |
| `totalTokens` | number | `12450` | Token count from the subagent's final API request: input, output, and cache tokens combined. This isn't a total across the whole run |
| `totalDurationMs` | number | `48211` | Wall-clock duration of the subagent run |
| `totalToolUseCount` | number | `7` | Count of tool calls the subagent made |
| `usage` | object | `{"input_tokens": 8320, ...}` | Per-type token breakdown of the final API request: `input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens` |

- A subagent that runs with the `SubagentHandback` tool, which Claude Code provides in
  [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode), delivers its report
  through that tool rather than returning it as text. The `content` field of its `completed` result then carries a
  short note about that hand-back rather than the report itself. To read the report, match a `PreToolUse` or
  `PostToolUse` hook on `SubagentHandback` and read `tool_input.message`.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)
- For background subagents, the tool returns when the task moves to the background, so `tool_response` carries no usage
  fields: a background launch returns immediately, and a foreground task that Claude Code backgrounds mid-run returns
  at that transition. It has `status: "async_launched"`, `agentId`, `description`, `prompt`, `outputFile`, and
  `resolvedModel`.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)
- On a `completed` response, `resolvedModel` names the model the subagent started on, which can differ from the
  `model` value in `tool_input`, such as when `availableModels` or another override applies. On an `async_launched`
  response, `resolvedModel` names the model in use when the agent moved to the background, so a swap that happened
  before backgrounding is reflected there.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

#### AskUserQuestion

- `AskUserQuestion` asks the user one to four multiple-choice questions:
  [hooks › AskUserQuestion](https://code.claude.com/docs/en/hooks#askuserquestion)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `questions` | array | `[{"question": "Which framework?", "header": "Framework", "options": [{"label": "React"}], "multiSelect": false}]` | Questions to present, each with a `question` string, short `header`, `options` array, and optional `multiSelect` flag |
| `answers` | object | `{"Which framework?": "React"}` | Optional. Maps question text to the selected option label. Multi-select answers join labels with commas. Claude doesn't set this field; supply it via `updatedInput` to answer programmatically |

#### ExitPlanMode

- `ExitPlanMode` presents a plan and asks the user to approve it before Claude leaves
  [plan mode](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode). Claude writes
  the plan to a file on disk before calling the tool, so the literal `tool_input` from the model is typically empty.
  Claude Code injects the plan content and file path before passing the input to hooks.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

| Field | Type | Example | Description |
| :- | :- | :- | :- |
| `plan` | string | `"## Refactor auth\n1. Extract..."` | Plan content in Markdown. Injected from the plan file on disk |
| `planFilePath` | string | `"/Users/.../plans/refactor-auth.md"` | Path to the plan file. Injected |
| `allowedPrompts` | array | `[{"tool": "Bash", "prompt": "run tests"}]` | Deprecated. Claude Code accepts the field but ignores it |

- In `PostToolUse`, the `ExitPlanMode` `tool_response` is an object with `plan` and `filePath` fields holding the
  approved plan, plus internal status flags. Read `tool_response.plan` for the plan content rather than re-reading the
  file from disk.
  [hooks › PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)

### Decision control

- `PreToolUse` hooks can control whether a tool call proceeds. Unlike other hooks that use a top-level `decision`
  field, `PreToolUse` returns its decision inside a `hookSpecificOutput` object. This gives it richer control: four
  outcomes (allow, deny, ask, or defer) plus the ability to modify tool input before execution.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)

| Field | Description |
| :- | :- |
| `permissionDecision` | `"allow"` skips the permission prompt, except for the [actions no mode auto-approves](https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves) and for `AskUserQuestion` and `ExitPlanMode`, which need `updatedInput` paired with it. `"deny"` prevents the tool call. `"ask"` prompts the user to confirm. `"defer"` exits gracefully so the tool can be resumed later. [Deny and ask rules](https://code.claude.com/docs/en/permissions#manage-permissions) are still evaluated regardless of what the hook returns |
| `permissionDecisionReason` | For `"ask"`, shown to the user in the permission prompt. When Claude Code [denies the call](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs) in a `-p` run where no one can answer that prompt, Claude reads the reason in the tool result instead. For `"deny"`, shown to Claude. For `"allow"` and `"defer"`, written to the [debug log](https://code.claude.com/docs/en/hooks#debug-hooks) only |
| `updatedInput` | Modifies the tool's input parameters before execution. Replaces the entire input object, so include unchanged fields alongside modified ones. Claude Code evaluates permission rules and a Bash command's [auto-background eligibility](https://code.claude.com/docs/en/tools-reference#foreground-commands-that-move-to-the-background) against the input your hook returns, not the input Claude sent. Combine with `"allow"` to auto-approve, or `"ask"` to show the modified input to the user. For `"defer"`, ignored |
| `additionalContext` | String added to Claude's context alongside the tool result. Ignored when `permissionDecision` is `"defer"`. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) |

- A hook's `"ask"` also forces a permission prompt in auto mode: the classifier can still deny the tool call, but it
  can't approve the call silently.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- On `PreToolUse`, Claude Code handles each `permissionDecision` value as follows:
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)
  - `"allow"`: skip the interactive permission prompt.
  - `"deny"`: cancel the tool call and send the reason to Claude.
  - `"ask"`: show the permission prompt to the user as normal.
- When multiple `PreToolUse` hooks return different decisions, precedence is `deny` > `defer` > `ask` > `allow`.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- An `"allow"` from a hook doesn't skip the approval prompt for an MCP tool whose server marks it with
  [`_meta["anthropic/requiresUserInteraction"]`](https://code.claude.com/docs/en/mcp#require-approval-for-a-specific-tool),
  with or without `updatedInput`, because Claude Code can't confirm the hook collected the interaction the tool needs.
  It also doesn't skip the prompt for connector tools
  [your organization set to `ask`](https://code.claude.com/docs/en/mcp#organization-controls-on-connector-tools) in
  sessions where that setting reaches Claude Code.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control),
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output) and
  [hooks-guide › Hooks and permission modes](https://code.claude.com/docs/en/hooks-guide#hooks-and-permission-modes)
- A hook that blocks by exiting 2 routes the same way as `"deny"`: Claude sees the stderr message as the denial reason.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- When a hook returns `"ask"`, the permission prompt displayed to the user includes a label identifying where the hook
  came from: `[settings]` for a hook from any settings file or from agent frontmatter, or `[plugin:<name>]` for a
  plugin's hook (`[skill]` for a hook from skill frontmatter). This helps users understand which configuration source
  is requesting confirmation.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- When multiple `PreToolUse` hooks return [`updatedInput`](https://code.claude.com/docs/en/hooks#pretooluse) to rewrite
  a tool's arguments, the last one to finish takes effect. Since hooks run in parallel, the order is non-deterministic,
  so avoid having more than one hook modify the same tool's input.
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)
- Output shape of a `PreToolUse` decision:
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "My reason here",
      "updatedInput": {
        "field_to_modify": "new value"
      },
      "additionalContext": "Current environment: production. Proceed with caution."
    }
  }
  ```

- In [non-interactive mode](https://code.claude.com/docs/en/headless) with the `-p` flag, Claude Code offers
  `AskUserQuestion` and `ExitPlanMode` only when the run has a
  [permission host](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs) to receive
  the prompt, such as an Agent SDK `canUseTool` callback. These tools require user interaction. Returning
  `permissionDecision: "allow"` together with `updatedInput` satisfies that requirement: the hook reads the tool's
  input from stdin, collects the answer through your own UI, and returns it in `updatedInput` so the tool runs without
  prompting. Returning `"allow"` alone is not sufficient for these tools. For `AskUserQuestion`, echo back the original
  `questions` array and add an `answers` object mapping each question's text to the chosen answer.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- Top-level `decision` and `reason` fields are deprecated for `PreToolUse`. Use
  `hookSpecificOutput.permissionDecision` and `hookSpecificOutput.permissionDecisionReason` instead. The deprecated
  values `"approve"` and `"block"` map to `"allow"` and `"deny"` respectively. Other events like `PostToolUse` and
  `Stop` use top-level `decision` and `reason` as their current format.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)

### Defer a tool call for later

- `"defer"` is for integrations that run `claude -p` as a subprocess and read its JSON output, such as an Agent SDK app
  or a custom UI built on top of Claude Code. It lets that calling process pause Claude at a tool call, collect input
  through its own interface, and resume where it left off. Claude Code honors this value only in
  [non-interactive mode](https://code.claude.com/docs/en/headless) with the `-p` flag. In interactive sessions it logs
  a warning and ignores the hook result.
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- The `AskUserQuestion` tool is the typical case: Claude wants to ask the user something, but there is no terminal to
  answer in. A `-p` run offers `AskUserQuestion` only when it has a permission host, such as an MCP tool you pass with
  `--permission-prompt-tool`, so start the run with one. The round trip works like this:
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
  1. Claude calls `AskUserQuestion`. The `PreToolUse` hook fires.
  2. The hook returns `permissionDecision: "defer"`. The tool doesn't execute. The process exits with
     `stop_reason: "tool_deferred"` and the pending tool call preserved in the transcript.
  3. The calling process reads `deferred_tool_use` from the SDK result, surfaces the question in its own UI, and waits
     for an answer.
  4. The calling process runs `claude -p --resume <session-id>` with the same permission host. The same tool call
     fires `PreToolUse` again.
  5. The hook returns `permissionDecision: "allow"` with the answer in `updatedInput`. The tool executes and Claude
     continues.
- The `deferred_tool_use` field carries the tool's `id`, `name`, and `input`. The `input` is the parameters Claude
  generated for the tool call, captured before execution:
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)

  ```json
  {
    "type": "result",
    "subtype": "success",
    "stop_reason": "tool_deferred",
    "session_id": "abc123",
    "deferred_tool_use": {
      "id": "toolu_01abc",
      "name": "AskUserQuestion",
      "input": { "questions": [{ "question": "Which framework?", "header": "Framework", "options": [{"label": "React"}, {"label": "Vue"}], "multiSelect": false }] }
    }
  }
  ```

- There is no timeout or retry limit. The session remains on disk until you resume it, subject to the
  [`cleanupPeriodDays`](https://code.claude.com/docs/en/settings-reference#cleanupperioddays) retention sweep, which
  deletes session files after 30 days by default, following the
  [retention sweep rules](https://code.claude.com/docs/en/claude-directory#cleaned-up-automatically). If the answer is
  not ready when you resume, the hook can return `"defer"` again and the process exits the same way. The calling
  process controls when to break the loop by eventually returning `"allow"` or `"deny"` from the hook.
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- `"defer"` only works when Claude makes a single tool call in the turn. If Claude makes several tool calls at once,
  `"defer"` is ignored with a warning and the tool proceeds through the normal permission flow. The constraint exists
  because resume can only re-run one tool: there is no way to defer one call from a batch without leaving the others
  unresolved.
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- If the deferred tool is no longer available when you resume, the process exits with
  `stop_reason: "tool_deferred_unavailable"` and `is_error: true` before the hook fires. This happens when an MCP
  server that provided the tool is not connected for the resumed session. The `deferred_tool_use` payload is still
  included so you can identify which tool went missing.
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- To resume a deferred session in plan mode, pass
  [`--permission-prompt-tool`](https://code.claude.com/docs/en/cli-reference#cli-flags) along with `--resume` so that
  Claude Code can present the plan for approval. If you pass certain other launch flags, the resumed run doesn't return
  to plan mode; see [Resume in plan mode with `-p`](https://code.claude.com/docs/en/sessions#resume-in-plan-mode-with-p).
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- When you resume with `-p`, Claude Code doesn't restore any other stored permission mode. It starts the run in the
  permission mode a new `claude -p` run would start in, so pass `--permission-mode` or `--dangerously-skip-permissions`
  again if the deferred session used one. When you resume with `claude --resume <session-id>` without `-p`, Claude Code
  restores the stored permission mode, with the exceptions listed in
  [permission mode on resume](https://code.claude.com/docs/en/sessions#permission-mode-on-resume).
  [hooks › Defer a tool call for later](https://code.claude.com/docs/en/hooks#defer-a-tool-call-for-later)
- `CLAUDE_CODE_RESUME_PROMPT` overrides the continuation message Claude Code sends to Claude when
  `CLAUDE_CODE_RESUME_INTERRUPTED_TURN` continues an interrupted turn instead of resending its prompt, or when you
  resume a deferred tool call with `-p`. It defaults to `Continue from where you left off.`, and an empty string uses
  the default.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

### Example: block edits to protected files

- Prevent Claude from modifying sensitive files like `.env`, `package-lock.json`, or anything in `.git/`. Claude
  receives feedback explaining why the edit was blocked, so it can adjust its approach. This example uses a separate
  script file that the hook calls. The script checks the target file path against a list of protected patterns and
  exits with code 2 to block the edit. Save the script to `.claude/hooks/protect-files.sh`:
  [hooks-guide › Block edits to protected files](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)

  ```bash
  #!/bin/bash
  # protect-files.sh

  INPUT=$(cat)
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

  # Normalize Windows backslash separators so the patterns below match
  FILE_PATH="${FILE_PATH//\\//}"

  PROTECTED_PATTERNS=(".env" "package-lock.json" ".git/")

  for pattern in "${PROTECTED_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
      echo "Blocked: $FILE_PATH matches protected pattern '$pattern'" >&2
      exit 2
    fi
  done

  exit 0
  ```

- Hook scripts must be executable for Claude Code to run them. On macOS and Linux, run
  `chmod +x .claude/hooks/protect-files.sh`.
  [hooks-guide › Block edits to protected files](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)
- Register the script as a `PreToolUse` hook in `.claude/settings.json` that runs before any `Edit` or `Write` tool
  call. Claude Code blocks the edit before it runs and passes the script's `Blocked:` message to Claude as feedback.
  [hooks-guide › Block edits to protected files](https://code.claude.com/docs/en/hooks-guide#block-edits-to-protected-files)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Edit|Write",
          "hooks": [
            {
              "type": "command",
              "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/protect-files.sh"
            }
          ]
        }
      ]
    }
  }
  ```

## PermissionRequest

### When it fires and what it matches

- `PermissionRequest` runs when Claude Code is about to ask you for permission to use a tool, or when it would
  otherwise auto-deny a call that can't prompt. In sessions that can't show a prompt, such as background subagents in
  [non-interactive mode](https://code.claude.com/docs/en/headless), Claude Code still runs these hooks, and if no hook
  returns a decision, it denies the tool call. In non-interactive mode with the `-p` flag, they still run outside
  [`dontAsk` mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode),
  and a call that no hook decides and nothing else can answer is denied. For a call that reaches a
  `--permission-prompt-tool` or the Agent SDK's
  [`canUseTool` callback](https://code.claude.com/docs/en/agent-sdk/permissions), the hooks run alongside your host, and
  whichever decides first applies.
  [hooks › PermissionRequest](https://code.claude.com/docs/en/hooks#permissionrequest),
  [hooks › PermissionRequest input](https://code.claude.com/docs/en/hooks#permissionrequest-input) and
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)
- Use this event when you need a signal the moment Claude asks for permission to use a tool. Claude Code runs a
  `Notification` hook with the `permission_prompt` type only after the prompt has waited about six seconds.
  [hooks › PermissionRequest](https://code.claude.com/docs/en/hooks#permissionrequest)
- Claude Code doesn't run `PermissionRequest` hooks for a sandboxed command's
  [network request](https://code.claude.com/docs/en/sandboxing#network-isolation). To get a signal for that prompt, use
  the `permission_prompt` notification type.
  [hooks › PermissionRequest](https://code.claude.com/docs/en/hooks#permissionrequest)
- `PermissionRequest` matches on tool name, same values as `PreToolUse`.
  [hooks › PermissionRequest](https://code.claude.com/docs/en/hooks#permissionrequest)
- `PreToolUse` hooks run before every tool call, whether or not it needs permission, while `PermissionRequest` hooks
  run only in the cases above. Neither event fires for `EndConversation`.
  [hooks › PermissionRequest input](https://code.claude.com/docs/en/hooks#permissionrequest-input)
- With `--permission-prompts none`, anything that would prompt is denied unless a `PermissionRequest` hook allows it,
  Claude is told that nobody can approve the request and not to retry it, and the run continues. Permission rules,
  `PermissionRequest` hooks, and the permission mode you set still decide every call first; Claude Code denies only the
  requests that nothing else resolves. In a `-p` run with no permission host, these requests are denied either way, and
  the flag also tells Claude not to retry them.
  [headless › Turn off permission prompts in unattended runs](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs)
- A critical-path removal asks you to approve it in `default`, `acceptEdits` and `bypassPermissions` modes, and in
  `auto` mode in the terminal; `auto` mode denies it elsewhere, and `dontAsk` mode denies it. `plan` mode asks too,
  except that when the classifier reviews commands during planning and no bypass permissions are available, it handles
  the removal as in `auto` mode. If an explicit ask rule matches the command, Claude Code asks you instead, even in
  `auto` mode. In modes that ask, a `PermissionRequest` hook can answer the prompt.
  [permission-modes › Critical-path removals in each permission mode](https://code.claude.com/docs/en/permission-modes#critical-path-removals-in-each-permission-mode)

### Input

- `PermissionRequest` hooks receive `tool_name` and `tool_input` fields like `PreToolUse` hooks, but without
  `tool_use_id`. For an MCP tool, they also receive the `mcp_server` object. An optional `permission_suggestions` array
  contains the [permission updates](#permission-update-entries) Claude Code suggests for this request, such as adding
  an allow rule or changing the permission mode.
  [hooks › PermissionRequest input](https://code.claude.com/docs/en/hooks#permissionrequest-input)
- The `permission_suggestions` array isn't an exact list of the options you see, because each permission dialog builds
  its own options. Some dialogs, such as the one for file edits, don't read the array at all and derive their options
  from the request itself. A dialog that does read it can still withhold an option whose suggestion stays in the array,
  for example when [`allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
  hides rule-saving options. It can also offer options that have no suggestion entry, such as
  [**Yes, and switch to auto mode**](https://code.claude.com/docs/en/permission-modes#switch-permission-modes), which
  changes the permission mode directly rather than through a permission update.
  [hooks › PermissionRequest input](https://code.claude.com/docs/en/hooks#permissionrequest-input)
- Example input:
  [hooks › PermissionRequest input](https://code.claude.com/docs/en/hooks#permissionrequest-input)

  ```json
  {
    "session_id": "abc123",
    "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
    "cwd": "/Users/...",
    "permission_mode": "default",
    "hook_event_name": "PermissionRequest",
    "tool_name": "Bash",
    "tool_input": {
      "command": "rm -rf node_modules",
      "description": "Remove node_modules directory"
    },
    "permission_suggestions": [
      {
        "type": "addRules",
        "rules": [{ "toolName": "Bash", "ruleContent": "rm -rf node_modules" }],
        "behavior": "allow",
        "destination": "localSettings"
      }
    ]
  }
  ```

### Decision control

- `PermissionRequest` hooks can allow or deny permission requests. In addition to the
  [JSON output fields](https://code.claude.com/docs/en/hooks#json-output) available to all hooks, your hook script can
  return a `decision` object with these event-specific fields:
  [hooks › PermissionRequest decision control](https://code.claude.com/docs/en/hooks#permissionrequest-decision-control)

| Field | Description |
| :- | :- |
| `behavior` | `"allow"` grants the permission, `"deny"` denies it. [Deny and ask rules](https://code.claude.com/docs/en/permissions#manage-permissions) are still evaluated, so a hook returning `"allow"` doesn't override a matching deny rule |
| `updatedInput` | For `"allow"` only: modifies the tool's input parameters before execution. Replaces the entire input object, so include unchanged fields alongside modified ones. The modified input is re-evaluated against deny and ask rules |
| `updatedPermissions` | For `"allow"` only: array of [permission update entries](https://code.claude.com/docs/en/hooks#permission-update-entries) to apply, such as adding an allow rule or changing the session permission mode |
| `message` | For `"deny"` only: tells Claude why the permission was denied |
| `interrupt` | For `"deny"` only: if `true`, stops Claude |

- A hook that exits 2 without a `decision` object leaves the permission flow unchanged, and its stderr is discarded.
  Only the `decision` object can grant or deny the request.
  [hooks › PermissionRequest decision control](https://code.claude.com/docs/en/hooks#permissionrequest-decision-control)
- Output shape of a `PermissionRequest` decision:
  [hooks › PermissionRequest decision control](https://code.claude.com/docs/en/hooks#permissionrequest-decision-control)

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

### Permission update entries

- The `updatedPermissions` output field and the `permission_suggestions` input field both use the same array of entry
  objects. Each entry has a `type` that determines its other fields, and a `destination` that controls where the change
  is written.
  [hooks › Permission update entries](https://code.claude.com/docs/en/hooks#permission-update-entries)

| `type` | Fields | Effect |
| :- | :- | :- |
| `addRules` | `rules`, `behavior`, `destination` | Adds permission rules. `rules` is an array of `{toolName, ruleContent?}` objects. Omit `ruleContent` to match the whole tool. `behavior` is `"allow"`, `"deny"`, or `"ask"` |
| `replaceRules` | `rules`, `behavior`, `destination` | Replaces all rules of the given `behavior` at the `destination` with the provided `rules` |
| `removeRules` | `rules`, `behavior`, `destination` | Removes matching rules of the given `behavior` |
| `setMode` | `mode`, `destination` | Changes the permission mode. Valid modes are `default`, `auto`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`, and `manual` as an alias for `default` |
| `addDirectories` | `directories`, `destination` | Adds working directories. `directories` is an array of path strings |
| `removeDirectories` | `directories`, `destination` | Removes working directories |

- `setMode` with `bypassPermissions` only takes effect if you launched the session with bypass mode already available:
  `--dangerously-skip-permissions`, `--permission-mode bypassPermissions`, `--allow-dangerously-skip-permissions`, or
  `permissions.defaultMode: "bypassPermissions"` in
  [user, `--settings`, or managed settings](https://code.claude.com/docs/en/settings-reference#permissions-defaultmode).
  Otherwise the update is a no-op. The update is also a no-op when
  [`permissions.disableBypassPermissionsMode`](https://code.claude.com/docs/en/permissions#managed-settings) disables
  the mode, or when the session starts in [restricted mode](https://code.claude.com/docs/en/cli-reference#cli-flags).
  `bypassPermissions` is never persisted as `defaultMode` regardless of `destination`.
  [hooks › Permission update entries](https://code.claude.com/docs/en/hooks#permission-update-entries)
- The `destination` field on every entry determines whether the change stays in memory or persists to a settings file:
  [hooks › Permission update entries](https://code.claude.com/docs/en/hooks#permission-update-entries)

| `destination` | Writes to |
| :- | :- |
| `session` | in-memory only, discarded when the session ends |
| `localSettings` | `.claude/settings.local.json` |
| `projectSettings` | `.claude/settings.json` |
| `userSettings` | `~/.claude/settings.json` |

- A hook can echo one of the `permission_suggestions` it received as its own `updatedPermissions` output.
  [hooks › Permission update entries](https://code.claude.com/docs/en/hooks#permission-update-entries)

### Example: auto-approve `ExitPlanMode`

- Auto-approval requires your hook to write a JSON decision to stdout, unlike exit-code hooks. If your
  `PermissionRequest` hook returns `"behavior": "allow"`, Claude Code answers the request on your behalf. This example
  auto-approves `ExitPlanMode`, the tool Claude calls when it finishes presenting a plan and asks to proceed. The
  matcher scopes the hook to `ExitPlanMode` only, so no other prompts are affected. Add this to
  `~/.claude/settings.json`:
  [hooks-guide › Auto-approve specific permission prompts](https://code.claude.com/docs/en/hooks-guide#auto-approve-specific-permission-prompts)

  ```json
  {
    "hooks": {
      "PermissionRequest": [
        {
          "matcher": "ExitPlanMode",
          "hooks": [
            {
              "type": "command",
              "command": "echo '{\"hookSpecificOutput\": {\"hookEventName\": \"PermissionRequest\", \"decision\": {\"behavior\": \"allow\"}}}'"
            }
          ]
        }
      ]
    }
  }
  ```

- When the hook approves, Claude Code exits plan mode and restores whatever permission mode was active before you
  entered plan mode. The transcript shows "Allowed by PermissionRequest hook" where the dialog would have appeared. The
  hook path always keeps the current conversation: it can't clear context and start a fresh implementation session the
  way the dialog can.
  [hooks-guide › Auto-approve specific permission prompts](https://code.claude.com/docs/en/hooks-guide#auto-approve-specific-permission-prompts)
- To set a specific permission mode instead, your hook's output can include an `updatedPermissions` array with a
  `setMode` entry. The `mode` value is any permission mode like `default`, `acceptEdits`, or `bypassPermissions`, and
  `destination: "session"` applies it for the current session only. `bypassPermissions` only applies under the
  conditions stated for `setMode` above, and Claude Code never saves it as `defaultMode`. To switch the session to
  `acceptEdits`, the hook writes this JSON to stdout:
  [hooks-guide › Auto-approve specific permission prompts](https://code.claude.com/docs/en/hooks-guide#auto-approve-specific-permission-prompts)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PermissionRequest",
      "decision": {
        "behavior": "allow",
        "updatedPermissions": [
          { "type": "setMode", "mode": "acceptEdits", "destination": "session" }
        ]
      }
    }
  }
  ```

- Keep the matcher as narrow as possible. Matching on `.*` or leaving the matcher empty would auto-approve every tool
  permission prompt, including file writes and shell commands.
  [hooks-guide › Auto-approve specific permission prompts](https://code.claude.com/docs/en/hooks-guide#auto-approve-specific-permission-prompts)

## PostToolUse

### When it fires and what it matches

- `PostToolUse` runs immediately after a tool completes successfully. It matches on tool name, same values as
  `PreToolUse`.
  [hooks › PostToolUse](https://code.claude.com/docs/en/hooks#posttooluse)
- To run a hook after any tool completes successfully, omit the `matcher` or set it to `"*"`. Your hook can then
  discover what changed itself, for example by running `git status --porcelain`, which also lists untracked files that
  `git diff` misses. For tool calls that fail, add the same hook under `PostToolUseFailure`.
  [hooks › PostToolUse](https://code.claude.com/docs/en/hooks#posttooluse)
- To run a hook when a specific file changes on disk, whatever wrote it, use `FileChanged`. Claude Code doesn't run a
  `PostToolUse` hook matching `Edit|Write` when a `Bash` command or a process outside Claude Code rewrites the same
  file.
  [hooks › PostToolUse](https://code.claude.com/docs/en/hooks#posttooluse)

### Input

- `PostToolUse` hooks fire after a tool has already executed successfully. The input includes both `tool_input`, the
  arguments sent to the tool, and `tool_response`, the result it returned. The exact schema for both depends on the
  tool. File-tool `tool_input` paths arrive in the same format as for `PreToolUse`: always absolute, with the
  platform's native separators, so backslashes on Windows. For an MCP tool, the input also carries the `mcp_server`
  object.
  [hooks › PostToolUse input](https://code.claude.com/docs/en/hooks#posttooluse-input)

  ```json
  {
    "session_id": "abc123",
    "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
    "cwd": "/Users/...",
    "permission_mode": "default",
    "hook_event_name": "PostToolUse",
    "tool_name": "Write",
    "tool_input": {
      "file_path": "/path/to/file.txt",
      "content": "file content"
    },
    "tool_response": {
      "filePath": "/path/to/file.txt",
      "type": "create"
    },
    "tool_use_id": "toolu_01ABC123...",
    "duration_ms": 12
  }
  ```

| Field | Description |
| :- | :- |
| `duration_ms` | Optional. Tool execution time in milliseconds. Excludes time spent in permission prompts and PreToolUse hooks |

### Decision control

- `PostToolUse` hooks can provide feedback to Claude after tool execution. In addition to the
  [JSON output fields](https://code.claude.com/docs/en/hooks#json-output) available to all hooks, your hook script can
  return these event-specific fields:
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)

| Field | Description |
| :- | :- |
| `decision` | `"block"` adds the `reason` next to the tool result. Claude still sees the original output; to replace it, use `updatedToolOutput` |
| `reason` | Explanation shown to Claude when `decision` is `"block"` |
| `additionalContext` | String added to Claude's context alongside the tool result. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) |
| `classifierContext` | Short note about this call's result for the [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) classifier rather than for Claude. See [Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier) |
| `updatedToolOutput` | Replaces the tool's output with the provided value before it is sent to Claude. The value must match the tool's output shape |
| `updatedMCPToolOutput` | Replaces the output for [MCP tools](https://code.claude.com/docs/en/hooks#match-mcp-tools) only. Prefer `updatedToolOutput`, which works for all tools |

- This example replaces the output of a `Bash` call. The replacement value matches the `Bash` tool's output shape:
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": "Additional information for Claude",
      "updatedToolOutput": {
        "stdout": "[redacted]",
        "stderr": "",
        "interrupted": false,
        "isImage": false
      }
    }
  }
  ```

- `updatedToolOutput` only changes what Claude sees. The tool has already run by the time the hook fires, so any files
  written, commands executed, or network requests sent have already taken effect. Telemetry such as OpenTelemetry tool
  spans and analytics events also captures the original output before the hook runs. To prevent or modify a tool call
  before it runs, use a `PreToolUse` hook instead.
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)
- The replacement value must match the tool's output shape. Built-in tools return structured objects rather than plain
  strings. For example, `Bash` returns an object with `stdout`, `stderr`, `interrupted`, and `isImage` fields. For
  built-in tools, a value that doesn't match the tool's output schema is ignored and the original output is used. MCP
  tool output is passed through without schema validation. Stripping error details that Claude needs can cause it to
  proceed on a false assumption.
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)

### Annotate a result for the auto mode classifier

- Return `classifierContext` to send a short note about the tool call's result to the
  [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) classifier rather than
  to Claude. The classifier [never receives tool results themselves](https://code.claude.com/docs/en/permission-modes#how-the-classifier-evaluates-actions),
  so this field is the supported way to tell it something about what a call returned before it reviews later actions.
  This example tells the classifier where a query's output came from:
  [hooks › Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "classifierContext": "This query ran against the staging database, not production."
    }
  }
  ```

- How much weight the classifier gives the note depends on where you configured the hook. For hooks configured in
  Claude Code, meaning hooks from settings files, plugins, skills, and agent frontmatter, the classifier treats the
  note as unverified, application-provided context. The note never establishes user intent, and if it claims you
  approved or requested something, the classifier checks that claim against your own messages in the conversation.
  [hooks › Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier)
- For in-process Agent SDK callbacks, when an application embedding Claude Code registers the hook as a
  [TypeScript SDK callback](https://code.claude.com/docs/en/agent-sdk/hooks) and returns the note during the live
  session, the classifier may weigh a user statement relayed in the note as user intent. Such a statement can satisfy a
  consent requirement the classifier would accept from a message you send, but it never lifts a block that your own
  message couldn't lift either. After a session resumes, Claude Code treats restored notes as unverified context. When
  hooks from both groups annotate the same call, the classifier treats the combined note as unverified.
  [hooks › Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier)
- Claude Code applies these limits when delivering the note:
  [hooks › Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier)
  - **Length**: Claude Code caps the notes for one tool call at 2,000 characters and truncates the rest. The cap is
    shared across every hook that responds to that call.
  - **Synchronous responses only**: Claude Code ignores the field in the response of a hook that
    [runs in the background](https://code.claude.com/docs/en/hooks#run-hooks-in-the-background), because that response
    arrives after Claude Code records the tool result.
  - **Calls that the classifier doesn't record**: the classifier's transcript omits read-only lookups such as file
    reads and searches. Claude Code discards a note attached to one of those calls.
  - **Interaction with rewrites**: when the note describes output you're replacing with `updatedToolOutput`, return
    both fields in the same hook response. Claude Code drops the note if that rewrite is rejected or another hook's
    rewrite replaces it. Claude Code delivers a note you return without a rewrite even when another hook rewrites the
    output.
- The classifier reads content you place in `classifierContext` as information from the application hosting the
  session, so don't copy untrusted tool output or third-party text into it. Keep the note to a short assertion about
  this one call, such as a fact about its origin or a user statement about it; don't use the field to deliver unrelated
  messages or a stream of events.
  [hooks › Annotate a result for the auto mode classifier](https://code.claude.com/docs/en/hooks#annotate-a-result-for-the-auto-mode-classifier)

### Example: format a file after each edit

- This hook uses the `PostToolUse` event with an `Edit|Write` matcher, so it runs only after file-editing tools. The
  command extracts the edited file path with `jq` and passes it to Prettier. Add this to `.claude/settings.json` in
  your project root:
  [hooks-guide › Auto-format code after edits](https://code.claude.com/docs/en/hooks-guide#auto-format-code-after-edits)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Edit|Write",
          "hooks": [
            {
              "type": "command",
              "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write"
            }
          ]
        }
      ]
    }
  }
  ```

- When the hook succeeds, Claude Code shows nothing in the conversation. To confirm the hook ran, check that the edited
  file is reformatted.
  [hooks-guide › Auto-format code after edits](https://code.claude.com/docs/en/hooks-guide#auto-format-code-after-edits)

## PostToolUseFailure

### When it fires and what it matches

- `PostToolUseFailure` runs when a tool that started executing fails: the tool threw an error, or an MCP tool returned
  an error result. Use this to log failures, send alerts, or provide corrective feedback to Claude. It matches on tool
  name, same values as `PreToolUse`.
  [hooks › PostToolUseFailure](https://code.claude.com/docs/en/hooks#posttoolusefailure)
- This event doesn't fire for tool calls rejected before execution: an unknown tool name, input that fails schema or
  tool-specific validation, or a permission denial. Validation rejections are returned as `tool_use_error` results and
  happen before hooks run, so they fire neither `PreToolUse` nor `PostToolUseFailure`. Permission denials fire
  `PreToolUse` but not this event; see [PermissionDenied](#permissiondenied).
  [hooks › PostToolUseFailure](https://code.claude.com/docs/en/hooks#posttoolusefailure)

### Input

- `PostToolUseFailure` hooks receive the same `tool_name` and `tool_input` fields as `PostToolUse`, along with error
  information as top-level fields. For an MCP tool, they also receive the `mcp_server` object. For example, a failed
  `npm test` command might deliver:
  [hooks › PostToolUseFailure input](https://code.claude.com/docs/en/hooks#posttoolusefailure-input)

  ```json
  {
    "session_id": "abc123",
    "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
    "cwd": "/Users/...",
    "permission_mode": "default",
    "hook_event_name": "PostToolUseFailure",
    "tool_name": "Bash",
    "tool_input": {
      "command": "npm test",
      "description": "Run test suite"
    },
    "tool_use_id": "toolu_01ABC123...",
    "error": "Exit code 1\nError: Cannot find module 'express'",
    "is_interrupt": false,
    "duration_ms": 4187
  }
  ```

| Field | Description |
| :- | :- |
| `error` | String describing what went wrong. The format depends on the tool that failed |
| `is_interrupt` | Optional boolean. True when the failure reached Claude Code as an abort rather than as an error the tool reported. Cancelling a running tool does not fire this hook; the tool result carries the interruption message instead |
| `duration_ms` | Optional. Tool execution time in milliseconds. Excludes time spent in permission prompts and PreToolUse hooks |

- The `error` string is generally the same text Claude receives as the failed tool's result. Its format varies by tool
  and failure. Key your hook on `tool_name`, `is_interrupt`, and the `Exit code N` first line; treat the rest of the
  string as display text, not a stable format.
  [hooks › PostToolUseFailure input](https://code.claude.com/docs/en/hooks#posttoolusefailure-input)
  - For Bash and PowerShell, a command that ran and exited produces a first line `Exit code N`, then any output the
    command produced as one block with stdout and stderr interleaved.
  - A payload may also carry a bare failure message with no exit-code line, when Claude Code could not start the shell
    process itself.
  - Claude Code middle-truncates long strings around a `... [N characters truncated] ...` marker, and can insert lines
    of its own, such as `Command timed out after 2m 0s`.

### Decision control

- `PostToolUseFailure` hooks can provide context to Claude after a tool failure. In addition to the
  [JSON output fields](https://code.claude.com/docs/en/hooks#json-output) available to all hooks, your hook script can
  return these event-specific fields:
  [hooks › PostToolUseFailure decision control](https://code.claude.com/docs/en/hooks#posttoolusefailure-decision-control)

| Field | Description |
| :- | :- |
| `additionalContext` | String added to Claude's context alongside the error. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) |

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PostToolUseFailure",
      "additionalContext": "Additional information about the failure for Claude"
    }
  }
  ```

## PostToolBatch

### When it fires

- `PostToolBatch` runs once after every tool call in a batch has resolved, before Claude Code sends the next request
  to the model. `PostToolUse` fires once per tool, which means it fires concurrently when Claude makes parallel tool
  calls. `PostToolBatch` fires exactly once with the full batch, so it is the right place to inject context that
  depends on the set of tools that ran rather than on any single tool. There is no matcher for this event.
  [hooks › PostToolBatch](https://code.claude.com/docs/en/hooks#posttoolbatch)

### Input

- In addition to the common input fields, `PostToolBatch` hooks receive `tool_calls`, an array describing every tool
  call in the batch:
  [hooks › PostToolBatch input](https://code.claude.com/docs/en/hooks#posttoolbatch-input)

  ```json
  {
    "session_id": "abc123",
    "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
    "cwd": "/Users/...",
    "permission_mode": "default",
    "hook_event_name": "PostToolBatch",
    "tool_calls": [
      {
        "tool_name": "Read",
        "tool_input": {"file_path": "/.../ledger/accounts.py"},
        "tool_use_id": "toolu_01...",
        "tool_response": "1\tfrom __future__ import annotations\n2\t..."
      },
      {
        "tool_name": "Read",
        "tool_input": {"file_path": "/.../ledger/transactions.py"},
        "tool_use_id": "toolu_02...",
        "tool_response": "1\tfrom __future__ import annotations\n2\t..."
      }
    ]
  }
  ```

- `tool_response` contains the same content the model receives in the corresponding `tool_result` block. The value is a
  serialized string or content-block array, exactly as the tool emitted it. For `Read`, that means line-number-prefixed
  text rather than raw file contents. Responses can be large, so parse only the fields you need.
  [hooks › PostToolBatch input](https://code.claude.com/docs/en/hooks#posttoolbatch-input)
- The `tool_response` shape differs from `PostToolUse`'s. `PostToolUse` passes the tool's structured `Output` object,
  such as `{filePath: "...", type: "create"}` for `Write`; `PostToolBatch` passes the serialized `tool_result` content
  the model sees.
  [hooks › PostToolBatch input](https://code.claude.com/docs/en/hooks#posttoolbatch-input)

### Decision control

- `PostToolBatch` hooks can inject context for Claude. In addition to the
  [JSON output fields](https://code.claude.com/docs/en/hooks#json-output) available to all hooks, your hook script can
  return these event-specific fields:
  [hooks › PostToolBatch decision control](https://code.claude.com/docs/en/hooks#posttoolbatch-decision-control)

| Field | Description |
| :- | :- |
| `additionalContext` | Context string injected once before the next model call. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) for delivery details, what to put in it, and how resumed sessions handle past values |

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PostToolBatch",
      "additionalContext": "These files are part of the ledger module. Run pytest before marking the task complete."
    }
  }
  ```

- Returning `decision: "block"` or `continue: false` stops the agentic loop before the next model call. The blocking
  message comes from the JSON `reason` or `stopReason`, or from stderr on exit 2. You see it as a warning in the
  transcript, and it stays in the conversation, so Claude sees it when the conversation continues.
  [hooks › PostToolBatch decision control](https://code.claude.com/docs/en/hooks#posttoolbatch-decision-control)

## PermissionDenied

### When it fires and what it matches

- `PermissionDenied` runs when [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
  denies a tool call, including when it denies without a classifier verdict because
  [a safety check separate from auto mode refused the classifier's own request](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
  or its response didn't parse. Use it to log denials, adjust configuration, or tell the model it may retry the tool
  call. It matches on tool name, same values as `PreToolUse`.
  [hooks › PermissionDenied](https://code.claude.com/docs/en/hooks#permissiondenied)
- This hook only fires in auto mode: it doesn't run when you manually deny a permission dialog, when a `PreToolUse`
  hook blocks a call, or when a `deny` rule matches.
  [hooks › PermissionDenied](https://code.claude.com/docs/en/hooks#permissiondenied)
- To capture the exact input of an auto mode denial programmatically, add a `PermissionDenied` hook, which receives it
  as `tool_input`.
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)

### Input

- In addition to the common input fields, `PermissionDenied` hooks receive `tool_name`, `tool_input`, `tool_use_id`, and
  `reason`. For an MCP tool, they also receive the `mcp_server` object.
  [hooks › PermissionDenied input](https://code.claude.com/docs/en/hooks#permissiondenied-input)

  ```json
  {
    "session_id": "abc123",
    "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
    "cwd": "/Users/...",
    "permission_mode": "auto",
    "hook_event_name": "PermissionDenied",
    "tool_name": "Bash",
    "tool_input": {
      "command": "rm -rf /tmp/build",
      "description": "Clean build directory"
    },
    "tool_use_id": "toolu_01ABC123...",
    "reason": "[Irreversible Local Destruction]"
  }
  ```

| Field | Description |
| :- | :- |
| `reason` | The denial reason. For a classifier verdict, in most sessions it names the matched rule in square brackets, such as `[Data Exfiltration]`; see [Review denials](https://code.claude.com/docs/en/auto-mode-config#review-denials) for the other forms. For a [no-verdict denial](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control), it starts with `Auto mode could not evaluate this action and is blocking it for safety`. For a denial because the classifier model was unavailable, it is the fixed text `Classifier unavailable` |

### Decision control

- `PermissionDenied` hooks can tell the model it may retry the denied tool call. Return a JSON object with
  `hookSpecificOutput.retry` set to `true`:
  [hooks › PermissionDenied decision control](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PermissionDenied",
      "retry": true
    }
  }
  ```

- When `retry` is `true`, Claude Code adds a message to the conversation telling the model it may retry the tool call.
  Claude Code doesn't reverse the denial itself. If your hook doesn't return JSON, or returns `retry: false`, the
  denial stands and the model receives the original rejection message.
  [hooks › PermissionDenied decision control](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control)
- Claude Code ignores `retry: true` when the classifier produced
  [no verdict on the action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action):
  its response didn't parse, or a safety check separate from auto mode refused the classifier's own request. For those
  denials, Claude Code already tells the model in the rejection message whether to retry later or move on.
  [hooks › PermissionDenied decision control](https://code.claude.com/docs/en/hooks#permissiondenied-decision-control)

## Hook decisions and permission rules

- When Claude Code makes a tool call, `PreToolUse` hooks run before the permission prompt, for every tool except
  `EndConversation`. The hook output can deny the
  tool call, force a prompt, or skip the prompt to let the call proceed.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- `PreToolUse` hook decisions don't bypass permission rules. Claude Code evaluates deny and ask rules regardless of what
  a `PreToolUse` hook returns: a matching deny rule blocks the call, and a matching ask rule still prompts even when
  the hook returned `"allow"` or `"ask"`. This preserves the deny-first precedence, including deny rules set in managed
  settings.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- A hook that exits with code 2 stops the tool call before permission rules are evaluated, so the block applies even
  when an allow rule would otherwise let the call proceed. To run all Bash commands without prompts except for a few
  you want blocked, add `"Bash"` to your allow list and register a `PreToolUse` hook that rejects those specific
  commands.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- Hooks in settings files and in a plugin's `hooks/hooks.json` can tighten restrictions but not loosen them past what
  permission rules allow.
  [hooks-guide › Hooks and permission modes](https://code.claude.com/docs/en/hooks-guide#hooks-and-permission-modes)

## Hook decisions and permission modes

- `PreToolUse` hooks fire before any permission-mode check, in every
  [permission mode](https://code.claude.com/docs/en/permission-modes), including `dontAsk`. A hook that returns
  `permissionDecision: "deny"` blocks the tool even in `bypassPermissions` mode or with
  `--dangerously-skip-permissions`. This lets you enforce policy that users can't bypass by changing their permission
  mode.
  [hooks-guide › Hooks and permission modes](https://code.claude.com/docs/en/hooks-guide#hooks-and-permission-modes)
- In `dontAsk` mode, which auto-denies every tool call that would otherwise prompt, Claude still runs calls approved by
  a `PreToolUse` hook, along with actions that need no approval and actions matching your `permissions.allow` rules.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)
- Claude Code never lets a [`permissions.allow`](https://code.claude.com/docs/en/permissions#manage-permissions) rule or
  a [`PreToolUse` hook](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks) that returns
  `"allow"` approve an `rm` or `rmdir` command that targets a critical path, such as the filesystem root, your home
  directory, or your working directory, even in modes that skip other prompts.
  [permission-modes › Critical paths](https://code.claude.com/docs/en/permission-modes#critical-paths)
- In `dontAsk` mode, `rm` and `rmdir` removals targeting a critical path, such as `rm -rf /` and `rm -rf ~`, are denied
  even when an allow rule matches them or a `PreToolUse` hook allows them.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)

## Auto mode and hooks

- In the Manual and `acceptEdits` permission modes, when [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) is available, Claude Code
  adds **Yes, and switch to auto mode** to a Bash command's permission prompt; selecting it approves the command and
  switches the session to auto mode. Claude Code doesn't add the option to prompts forced by one of your
  [`ask` rules](https://code.claude.com/docs/en/permissions#manage-permissions) or by a
  [hook](https://code.claude.com/docs/en/hooks#pretooluse-decision-control), because auto mode still shows you those
  prompts, so switching wouldn't remove them.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)

## Mods and hooks

- A [mod](https://code.claude.com/docs/en/plugins/mods/overview) you install that handles `tool.check` answers after
  the rules and the `PreToolUse` hooks have decided, and its answer can replace theirs. The mod can approve a call that
  an ask rule would prompt for, and it can approve a call that a `PreToolUse` hook blocked, unless the hook is in
  managed settings. `tool.check` fires after those hooks and the permission rules have decided, so a hook on it can
  approve a call that a `PreToolUse` hook from a settings file other than managed settings or from a plugin blocked.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
  and [plugins/mods/events › Where settings hooks run in the order](https://code.claude.com/docs/en/plugins/mods/events#where-settings-hooks-run-in-the-order)
- In [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode), a call that a mod
  approves runs without a classifier check.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- On a machine with managed settings, or when you're signed in with a Team or Enterprise plan, deny rules hold over the
  mod by default, and your organization can change that. Anywhere else, the mod can approve a call that a deny rule
  refuses.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- `PreToolUse` hooks from managed settings run before the first mod's `tool.call` hook, and a block from one of them is
  final, so no mod sees the call.
  [plugins/mods/events › Where settings hooks run in the order](https://code.claude.com/docs/en/plugins/mods/events#where-settings-hooks-run-in-the-order)
  and [plugins/mods/admin › Know which controls still apply](https://code.claude.com/docs/en/plugins/mods/admin#know-which-controls-still-apply)
- If a mod rewrites the call, your managed `PreToolUse` hooks run again on the rewritten call, so a block still applies.
  [plugins/mods/admin › Know which controls still apply](https://code.claude.com/docs/en/plugins/mods/admin#know-which-controls-still-apply)
- `PreToolUse` hooks from every other settings file and from plugins' `hooks/hooks.json` run after the last mod calls
  `next`, as part of Claude Code's own behavior. A mod that answers `tool.call` without calling `next`, such as one that
  returns its own result in place of running the tool, keeps them from running, and a mod that calls `next` sees their
  decision in the result it returns.
  [plugins/mods/events › Where settings hooks run in the order](https://code.claude.com/docs/en/plugins/mods/events#where-settings-hooks-run-in-the-order)
  and [plugins/mods/admin › Know which controls still apply](https://code.claude.com/docs/en/plugins/mods/admin#know-which-controls-still-apply)

## IDE tools in hooks

- The IDE integrations run a built-in MCP server named `ide`, which is hidden from `/mcp` because there's nothing to
  configure. If your organization uses a `PreToolUse` hook to allowlist MCP tools, you need to know it exists.
  [jetbrains › The built-in IDE MCP server](https://code.claude.com/docs/en/jetbrains#the-built-in-ide-mcp-server)
  and [vs-code › The built-in IDE MCP server](https://code.claude.com/docs/en/vs-code#the-built-in-ide-mcp-server)
- The `ide` tool that the JetBrains plugin shows the model, as hooks see it:
  [jetbrains › The built-in IDE MCP server](https://code.claude.com/docs/en/jetbrains#the-built-in-ide-mcp-server)

| Tool name (as seen by hooks) | What it does | Read-only |
| - | - | - |
| `mcp__ide__getDiagnostics` | Returns the IDE's inspection diagnostics, the errors and warnings shown in the editor. Each call covers one file: the file Claude specifies, or the file in your active editor if Claude doesn't specify one. | Yes |

- The two `ide` tools that the VS Code extension shows the model, as hooks see them:
  [vs-code › The built-in IDE MCP server](https://code.claude.com/docs/en/vs-code#the-built-in-ide-mcp-server)

| Tool name (as seen by hooks) | What it does | Read-only |
| - | - | - |
| `mcp__ide__getDiagnostics` | Returns language-server diagnostics: the errors and warnings in VS Code's Problems panel. Optionally scoped to one file. | Yes |
| `mcp__ide__executeCode` | Runs Python code in the active Jupyter notebook's kernel. See Jupyter execution always asks first. | No |

- Hooks and permission rules see the VS Code chat panel's diagnostics tool as `mcp__claude-vscode__getDiagnostics`. To
  cover diagnostics in both the CLI and the chat panel, name both `mcp__ide__getDiagnostics` and
  `mcp__claude-vscode__getDiagnostics` in your hook or rule.
  [vs-code › The built-in IDE MCP server](https://code.claude.com/docs/en/vs-code#the-built-in-ide-mcp-server)
- In VS Code, the Quick Pick confirmation for `mcp__ide__executeCode` is separate from `PreToolUse` hooks. An allowlist
  entry for `mcp__ide__executeCode` lets Claude propose running a cell; the Quick Pick inside VS Code is what lets it
  actually run.
  [vs-code › The built-in IDE MCP server](https://code.claude.com/docs/en/vs-code#the-built-in-ide-mcp-server)

## Not stated by the documentation

- Whether a `PreToolUse` `"allow"` also skips the auto mode classifier: the documentation says `"allow"` skips the
  permission prompt, and says a call a mod approves runs without a classifier check, but not the same for a hook.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)
- What a `PreToolUse` hook's `"ask"` does in `dontAsk` mode: the documentation says the mode denies explicit ask rules
  and auto-denies every tool call that would otherwise prompt, but doesn't name a hook's `"ask"`.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)
- Which decision wins when several `PermissionRequest` hooks disagree: the documentation gives a precedence only for
  `PreToolUse` hooks.
  [hooks › PermissionRequest decision control](https://code.claude.com/docs/en/hooks#permissionrequest-decision-control)
- Whether a `PermissionRequest` hook can answer a critical-path removal prompt in `auto` mode where it denies the
  removal outside the terminal: the documentation says a `PermissionRequest` hook can answer the prompt in modes that
  ask.
  [permission-modes › Critical-path removals in each permission mode](https://code.claude.com/docs/en/permission-modes#critical-path-removals-in-each-permission-mode)

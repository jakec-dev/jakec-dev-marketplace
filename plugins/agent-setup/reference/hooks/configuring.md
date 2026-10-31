# Configuring a hook

Writing a hook's settings entry: its structure, matchers, `if`, handler types and fields, exec and shell form,
PowerShell, timeouts, async hooks, the environment hook processes get and security practices.

## Contents

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

## Structure of an entry

- Hooks are defined in JSON settings files, in three levels of nesting: a hook event to respond to, such as
  `PreToolUse` or `Stop`; a matcher group that filters when it fires; and one or more hook handlers to run when
  matched. "Hook event" names the lifecycle point, "matcher group" the filter, and "hook handler" the shell command,
  HTTP endpoint, MCP tool, prompt or agent that runs.
  [hooks › Configuration](https://code.claude.com/docs/en/hooks#configuration)
- In a settings file's `hooks` key, each event maps to a list of matcher groups, and each group lists the handlers to
  run when the matcher applies. [settings-reference › `hooks`](https://code.claude.com/docs/en/settings-reference#hooks)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            { "type": "command", "command": "~/.claude/hooks/check-bash.sh" }
          ]
        }
      ]
    }
  }
  ```

- If a settings file already has a `hooks` key, add a new event as a sibling of the existing event keys rather than
  replacing the whole object. Each event name is a key inside the single `hooks` object.
  [hooks-guide › Set up your first hook](https://code.claude.com/docs/en/hooks-guide#set-up-your-first-hook)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Edit|Write",
          "hooks": [{ "type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write" }]
        }
      ],
      "Notification": [
        {
          "matcher": "",
          "hooks": [{ "type": "command", "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'" }]
        }
      ]
    }
  }
  ```

- When an event fires, the matcher is checked first: `"Bash"` matches the tool name, so the hook group activates. The
  `if` condition is checked next and is optional; without it, every handler in the matched group runs.
  [hooks › How a hook resolves](https://code.claude.com/docs/en/hooks#how-a-hook-resolves)
- In the `PreToolUse` example, exit code 0 with no output means the hook has no decision to report, so the tool call
  continues through the normal permission flow. The hook can deny the call, but staying silent doesn't approve it.
  [hooks › How a hook resolves](https://code.claude.com/docs/en/hooks#how-a-hook-resolves)
- A script that Claude Code runs as the hook command must be executable, for example
  `chmod +x .claude/hooks/block-rm.sh`. A Bash script that parses the JSON input with `jq` needs `jq` installed and on
  your `PATH`.
  [hooks › How a hook resolves](https://code.claude.com/docs/en/hooks#how-a-hook-resolves)
- This `PreToolUse` hook spawns `block-rm.sh` only when the matcher matches a Bash call and the `if` condition matches
  a Bash subcommand `rm *`. `"args": []` makes it exec form.
  [hooks › How a hook resolves](https://code.claude.com/docs/en/hooks#how-a-hook-resolves)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            {
              "type": "command",
              "if": "Bash(rm *)",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh",
              "args": []
            }
          ]
        }
      ]
    }
  }
  ```

- On Windows, the matcher `Bash|PowerShell` covers the PowerShell tool as well as Bash. A single `if` rule matches only
  one tool's calls, so each tool gets its own handler: one with `"if": "Bash(rm *)"` and one with
  `"if": "PowerShell(Remove-Item *)"`, both running the script through `powershell.exe`. In its `args`, `-NoProfile`
  skips loading your PowerShell profile so the hook starts fast, and `-ExecutionPolicy Bypass` lets PowerShell run the
  local script file. [hooks › How a hook resolves](https://code.claude.com/docs/en/hooks#how-a-hook-resolves)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash|PowerShell",
          "hooks": [
            {
              "type": "command",
              "if": "Bash(rm *)",
              "command": "powershell.exe",
              "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.ps1"]
            },
            {
              "type": "command",
              "if": "PowerShell(Remove-Item *)",
              "command": "powershell.exe",
              "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.ps1"]
            }
          ]
        }
      ]
    }
  }
  ```

## Matchers

- The `matcher` field filters when hooks fire, and how it is evaluated depends on the characters it contains.
  [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)

  | Matcher value | Evaluated as | Example |
  | :- | :- | :- |
  | `"*"`, `""`, or omitted | Match all | fires on every occurrence of the event |
  | Only letters, digits, `_`, `-`, spaces, `,`, and `\|` | Exact string, or list of exact strings separated by `\|` or `,` with optional surrounding whitespace | `Bash` matches only the Bash tool; `Edit\|Write` and `Edit, Write` each match either tool exactly; `code-reviewer` matches only that agent type |
  | Contains any other character | JavaScript regular expression, unanchored | `^Notebook` matches any tool whose name starts with `Notebook`; `mcp__memory__.*` matches every tool from the `memory` server |

- A matcher on the regular-expression path is tested with JavaScript's `RegExp.prototype.test`, which succeeds on a
  match anywhere in the value. `Edit.*` matches both `Edit` and `NotebookEdit`; wrap the pattern in `^` and `$`, as in
  `^Edit$`, when you need a whole-string match.
  [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)
- `FileChanged` and `StopFailure` use a narrower exact-match set of letters, digits, `_`, and `|` only. A hyphen,
  space, or comma in a matcher for those two events keeps it on the regular-expression path, and only `|` separates
  alternatives. Every other event with matcher support in the table that follows accepts `|` or `,`. `FileChanged`
  doesn't follow these rules when building its watch list.
  [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)
- Each event type matches on a different field. For most events, Claude Code evaluates the matcher against a field
  from the JSON input it sends to your hook on stdin; for tool events, that field is `tool_name`. For
  `PreModelSwitch` and `PostModelSwitch`, it evaluates the matcher against the canonical name it derives from
  `to_model`. [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)

  | Event | What the matcher filters | Example matcher values |
  | :- | :- | :- |
  | `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied` | tool name | `Bash`, `Edit\|Write`, `mcp__.*` |
  | `SessionStart` | how the session started | `startup`, `resume`, `clear`, `compact`, `fork` |
  | `Setup` | which CLI flag triggered setup | `init`, `maintenance` |
  | `SessionEnd` | why the session ended | `clear`, `resume`, `logout`, `prompt_input_exit`, `other` |
  | `Notification` | notification type | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog`, `elicitation_url_dialog`, `elicitation_complete`, `elicitation_response`, `agent_needs_input`, `agent_completed`, `quota_auto_resume_fired`, `quota_auto_resume_stale`, `quota_auto_resume_disabled` |
  | `SubagentStart` | agent type | `general-purpose`, `Explore`, `Plan`, custom agent names, or plugin-scoped names like `^my-plugin:reviewer$` |
  | `PreCompact`, `PostCompact` | what triggered compaction | `manual`, `auto` |
  | `PreModelSwitch`, `PostModelSwitch` | canonical name of the model the session switches to, as described under [PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch) | `claude-opus-5`, `claude-opus-4-6\|claude-opus-5`, `.*opus.*` |
  | `SubagentStop` | agent type | same values as `SubagentStart` |
  | `ConfigChange` | configuration source | `user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills` |
  | `CwdChanged` | no matcher support | always fires on every occurrence |
  | `DirectoryAdded` | how the directory was added | `slash_command`, `register_repo_root` |
  | `FileChanged` | literal filenames to watch (see [FileChanged](https://code.claude.com/docs/en/hooks#filechanged)) | `.envrc\|.env` |
  | `StopFailure` | error type | `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `account_on_hold`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `cloud_credential_error`, `unknown` |
  | `InstructionsLoaded` | load reason | `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact` |
  | `UserPromptExpansion` | command name | your skill or command names |
  | `Elicitation` | MCP server name | your configured MCP server names |
  | `ElicitationResult` | MCP server name | same values as `Elicitation` |
  | `UserPromptSubmit`, `PostToolBatch`, `Stop`, `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, `WorktreeRemove`, `MessageDisplay` | no matcher support | always fires on every occurrence |

- If you add a `matcher` field to an event without matcher support, it is silently ignored.
  [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)
- This example runs a linting script only when Claude writes or edits a file.
  [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Edit|Write",
          "hooks": [{ "type": "command", "command": "/path/to/lint-check.sh" }]
        }
      ]
    }
  }
  ```

- Claude can also create or modify files by running shell commands. If your hook must see every file change, such as
  for compliance scanning or audit logging, add a `Stop` hook that scans the working tree once per turn. For per-call
  coverage instead, also match `Bash|PowerShell` and have your script list modified and untracked files with
  `git status --porcelain`; matching `Bash` alone is not enough. To run a hook when a specific file changes on disk,
  whatever wrote it, use a `FileChanged` hook.
  [hooks-guide › Filter hooks with matchers](https://code.claude.com/docs/en/hooks-guide#filter-hooks-with-matchers)
- Tool names are the exact strings you use in permission rules, subagent tool lists and hook matchers. A hook
  `matcher` uses bare tool names, not the parenthesized rule format.
  [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference)
  and
  [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)
- The label shown for a tool in the transcript and permission dialog can differ from its canonical name; for example,
  the tool labeled `Stop Task` in the transcript has the canonical name `TaskStop`. Hook matchers don't match the
  label. Use the canonical names listed in the tools reference.
  [permissions › Tool name wildcards](https://code.claude.com/docs/en/permissions#tool-name-wildcards)

## Matching MCP tools

- MCP server tools appear as regular tools in the tool events (`PreToolUse`, `PostToolUse`, `PostToolUseFailure`,
  `PermissionRequest`, `PermissionDenied`), so you match them the same way as any other tool name. They are named
  `mcp__<server>__<tool>`, such as `mcp__memory__create_entities`, `mcp__filesystem__read_file` or
  `mcp__github__search_repositories`. [hooks › Match MCP tools](https://code.claude.com/docs/en/hooks#match-mcp-tools)
- To match every tool from a server, append `.*` to the server prefix. The `.*` is required: a matcher like
  `mcp__memory` or `mcp__brave-search` contains only exact-match characters, so it is compared as an exact string and
  matches no tool. [hooks › Match MCP tools](https://code.claude.com/docs/en/hooks#match-mcp-tools)
  - `mcp__memory__.*` matches all tools from the `memory` server
  - `mcp__brave-search__.*` matches all tools from a server whose name contains a hyphen
  - `mcp__.*__write.*` matches any tool whose name starts with `write` from any server
- Tools from a plugin-bundled MCP server use a scoped server segment that includes the plugin name:
  `mcp__plugin_<plugin-name>_<server-name>__<tool>`. A matcher written against the bare server key never fires for
  these tools. For a plugin named `my-plugin` that bundles a server under the key `db`, a `query` tool appears as
  `mcp__plugin_my-plugin_db__query`, so the matcher for every tool from that server is
  `mcp__plugin_my-plugin_db__.*`. Use the same scoped tool name in a handler's `if` field.
  [hooks › Match MCP tools](https://code.claude.com/docs/en/hooks#match-mcp-tools)
  and [plugins/components › Environment, quoting, and matching MCP tools](https://code.claude.com/docs/en/plugins/components#environment-quoting-and-matching-mcp-tools)
- This example logs all memory server operations and validates write operations from any MCP server.
  [hooks › Match MCP tools](https://code.claude.com/docs/en/hooks#match-mcp-tools)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "mcp__memory__.*",
          "hooks": [
            { "type": "command", "command": "echo 'Memory operation initiated' >> ~/mcp-operations.log" }
          ]
        },
        {
          "matcher": "mcp__.*__write.*",
          "hooks": [
            { "type": "command", "command": "/home/user/scripts/validate-mcp-write.py" }
          ]
        }
      ]
    }
  }
  ```

## Filtering with `if`

- The `if` field filters hooks by tool name and arguments together, so the hook process only spawns when the tool call
  matches. It goes beyond `matcher`, which filters at the group level by tool name
  only. `"Bash(git *)"` runs when any subcommand of the Bash input matches `git *`, and `"Edit(*.ts)"` runs only for
  TypeScript files.
  [hooks-guide › Filter by tool name and arguments with the `if` field](https://code.claude.com/docs/en/hooks-guide#filter-by-tool-name-and-arguments-with-the-if-field)
  and [hooks › Matcher patterns](https://code.claude.com/docs/en/hooks#matcher-patterns)
- The `if` field holds exactly one permission rule. There is no `&&`, `||` or list syntax for combining rules; to
  apply multiple conditions, or to match multiple tool names, define a separate hook handler for each, each with its
  own `if` value, or match at the `matcher` level where pipe alternation is supported.
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)
  and
  [hooks-guide › Filter by tool name and arguments with the `if` field](https://code.claude.com/docs/en/hooks-guide#filter-by-tool-name-and-arguments-with-the-if-field)
- In an `if` condition for a file tool, a single-segment directory pattern like `"Edit(src/**)"` matches only the
  `src` directory in the working directory and the files under it. To match a directory named `src` at any depth,
  write `"Edit(**/src/**)"`. [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)
- For Bash patterns, whether your hook command runs depends on the shape of the pattern and the Bash command Claude is
  invoking. Leading `VAR=value` assignments are stripped before matching.
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)

  | `if` pattern | Bash command | Hook runs? | Why |
  | :- | :- | :- | :- |
  | `Bash(git *)` | `FOO=bar git push` | yes | leading assignments are stripped; `git push` matches |
  | `Bash(git *)` | `npm test && git push` | yes | each subcommand is checked; `git push` matches |
  | `Bash(rm *)` | `echo $(rm -rf /)` | yes | commands inside `$()` and backticks are checked; `rm -rf /` matches |
  | `Bash(rm *)` | `echo $(date)` | no | no subcommand matches `rm *` |
  | `Bash(git push *)` | `echo $(date)` | yes | patterns that specify more than the command name run the hook anyway on `$()`, backticks, or `$VAR` |

- When Claude Code can't determine which commands the Bash input runs, it runs your hook regardless of the pattern.
  Because the `if` filter is best-effort, use the permission system rather than a hook to enforce a hard allow or
  deny. [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)
- An `if` rule has the format `ToolName(specifier)`.
  [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)

## Handler types and common fields

- Each object in the inner `hooks` array is a hook handler: the shell command, HTTP endpoint, MCP tool, LLM prompt or
  agent that runs when the matcher matches. There are five types, set in `type`.
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
  - `type: "command"`: runs a shell command. Your script receives the event's JSON input on stdin and communicates
    results back through exit codes and stdout.
  - `type: "http"`: sends the event's JSON input as an HTTP POST request to a URL.
  - `type: "mcp_tool"`: calls a tool on a configured MCP server. The tool's text output is treated like
    command-hook stdout.
  - `type: "prompt"`: sends a prompt to a Claude model for single-turn evaluation. The model returns its decision as
    JSON.
  - `type: "agent"`: spawns a subagent that can use tools like Read, Grep and Glob to verify conditions before
    returning a decision. Agent hooks are experimental and may change.
- All matching hooks run in parallel. If you define the same handler in more than one settings file, it runs once.
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
- Handlers run in the current directory with Claude Code's environment. If the current directory no longer exists,
  for example a worktree or temp directory that another shell deleted mid-session, Claude Code runs command hooks from
  the first of these that still exists: the directory the session started in, the project root, your home directory,
  or the system temp directory. Claude Code records a warning naming the fallback directory in the debug log.
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
- These fields apply to all hook types.
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `type` | yes | `"command"`, `"http"`, `"mcp_tool"`, `"prompt"`, or `"agent"` |
  | `if` | no | Permission rule syntax to filter when this hook runs, such as `"Bash(git *)"` or `"Edit(*.ts)"`. The hook command only runs if the tool call matches the pattern. See the Bash matching table for how Bash patterns evaluate against subcommands, `$()`, and backticks. Only evaluated on tool events: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, and `PermissionDenied`. On other events, a hook with `if` set never runs. Uses the same syntax as [permission rules](https://code.claude.com/docs/en/permissions) |
  | `timeout` | no | Seconds before canceling. Claude Code doesn't enforce it on a command hook you run with [`async: true`](https://code.claude.com/docs/en/hooks#run-hooks-in-the-background). Defaults: 600 for `command`, `http`, and `mcp_tool`; 30 for `prompt`; 60 for `agent`. Claude Code lowers the `command`, `http`, and `mcp_tool` default to 30 on [`UserPromptSubmit`](https://code.claude.com/docs/en/hooks#userpromptsubmit), [`PreModelSwitch`](https://code.claude.com/docs/en/hooks#premodelswitch), and [`PostModelSwitch`](https://code.claude.com/docs/en/hooks#postmodelswitch), and to 10 on [`MessageDisplay`](https://code.claude.com/docs/en/hooks#messagedisplay). [`SessionEnd`](https://code.claude.com/docs/en/hooks#sessionend) hooks share a 1.5-second budget; if your settings set a longer per-hook `timeout`, Claude Code raises the budget to match, up to 60 seconds |
  | `statusMessage` | no | Custom spinner message displayed while the hook runs |

- `once` applies only to hooks declared in skill frontmatter; it is ignored in settings files and agent frontmatter.
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)

## Command hooks: exec form and shell form

- In addition to the common fields, command hooks accept these fields.
  [hooks › Command hook fields](https://code.claude.com/docs/en/hooks#command-hook-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `command` | yes | Shell command to execute. With `args`, the executable to spawn directly. See [Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form) |
  | `args` | no | Argument list. When present, `command` is resolved as an executable and spawned directly with `args` as the argument vector, with no shell involved. See [Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form) |
  | `async` | no | If `true`, runs in the background without blocking. See [Run hooks in the background](https://code.claude.com/docs/en/hooks#run-hooks-in-the-background) |
  | `asyncRewake` | no | If `true`, runs in the background and wakes Claude on exit code 2. The hook's stderr, or stdout if stderr is empty, is shown to Claude as a [system reminder](https://code.claude.com/docs/en/glossary#system-reminder) so it can react to a long-running background failure |
  | `shell` | no | Shell to use for this hook. Accepts `"bash"` or `"powershell"`. Defaults to `"bash"`, or to `"powershell"` on Windows when Git Bash isn't installed. Setting `"powershell"` runs the command via PowerShell on Windows. Does not require `CLAUDE_CODE_USE_POWERSHELL_TOOL` since hooks spawn PowerShell directly. Ignored when `args` is set |

- A command hook runs as exec form when `args` is set, and shell form when `args` is omitted. Set `args` whenever the
  hook references a path placeholder; omit it when you need shell features like pipes or `&&`, or when neither
  concern applies.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- Exec form: Claude Code resolves `command` as an executable on `PATH` and spawns it directly with `args` as the
  argument vector. There is no shell, so each `args` element is one argument exactly as written, and path placeholders
  like `${CLAUDE_PLUGIN_ROOT}` are substituted into `command` and into each `args` element as plain strings. Special
  characters such as apostrophes, `$` and backticks pass through verbatim. No shell tokenization happens on any
  platform. [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- Shell form: the `command` string is passed to a shell: `sh -c` on macOS and Linux, Git Bash on Windows, or
  PowerShell when Git Bash isn't installed. Set the `shell` field to choose explicitly. The shell tokenizes the
  string, expands variables, and interprets pipes, `&&`, redirects and globs.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- In exec form, `command` is the executable name or path only. If `command` is a bare name with no path separator and
  contains whitespace alongside `args`, Claude Code logs a warning because the spawn will fail: there is no
  executable named `node script.js`. Move the extra tokens into `args`. Absolute paths with spaces, such as
  `C:\Program Files\nodejs\node.exe`, are a single valid executable and don't trigger the warning.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- On Windows, exec form requires `command` to resolve to a real executable such as a `.exe`. The `.cmd` and `.bat`
  shims that npm, npx, eslint and other tools install in `node_modules/.bin` are not executables and can't be spawned
  without a shell. To run them in exec form, invoke the underlying script with `node` directly, for example
  `"command": "node", "args": ["${CLAUDE_PLUGIN_ROOT}/node_modules/eslint/bin/eslint.js"]`; the `node` plus
  script-path pattern works on every platform. To run a `.cmd` or `.bat` shim by name, use shell form.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- The same hook in exec form and in shell form. Shell form needs quoting to handle paths with spaces or special
  characters. [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)

  ```json
  { "type": "command", "command": "node", "args": ["${CLAUDE_PLUGIN_ROOT}/scripts/format.js", "--fix"] }
  ```

  ```json
  { "type": "command", "command": "node \"${CLAUDE_PLUGIN_ROOT}\"/scripts/format.js --fix" }
  ```

- Both forms support the same path placeholders, and both export them as the environment variables
  `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT` and `CLAUDE_PLUGIN_DATA` on the spawned process, so a script can read
  `process.env.CLAUDE_PLUGIN_ROOT` regardless of how it was launched. Every plugin hook process also receives
  `CLAUDE_PLUGIN_OPTION_<KEY>` for each user configuration value.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form),
  [plugins/components › Environment, quoting, and matching MCP tools](https://code.claude.com/docs/en/plugins/components#environment-quoting-and-matching-mcp-tools)
  and [plugins/components › Reference plugin paths and store data](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data)
- In plugin hooks, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` and `${CLAUDE_PROJECT_DIR}` resolve anywhere in
  `command` and `args`. [plugins/manifest-reference › Where each variable resolves](https://code.claude.com/docs/en/plugins/manifest-reference#where-each-variable-resolves)
- Keep each substituted path a single argument. With `args`, each element is passed as one argument with no shell and
  needs no quoting. When `command` has no `args`, it runs through a
  shell, so wrap the `${CLAUDE_PLUGIN_ROOT}` path, or any such variable, in double quotes to keep the expanded path one
  shell word. In exec form, a script path built from `${CLAUDE_PROJECT_DIR}` needs no quoting. If you leave one of these
  variables outside quotes in a shell-form command in a hooks file, `claude plugin validate` warns about it unless the
  hook sets `shell` to `"powershell"`.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form),
  [plugins/manifest-reference › Quoting and path separators](https://code.claude.com/docs/en/plugins/manifest-reference#quoting-and-path-separators),
  [plugins/components › Environment, quoting, and matching MCP tools](https://code.claude.com/docs/en/plugins/components#environment-quoting-and-matching-mcp-tools)
  and [hooks › Security best practices](https://code.claude.com/docs/en/hooks#security-best-practices)

  ```json
  { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/process.sh" }
  ```

- On Windows, the substituted paths use forward slashes so a shell doesn't read backslashes as escapes. A plugin hook
  therefore receives `${CLAUDE_PLUGIN_ROOT}` as `C:/Users/you/...` rather than `C:\Users\you\...`, which breaks a
  script that expected backslashes: Claude Code runs shell-form hooks through Git Bash on Windows and substitutes the
  plugin root in the forward-slash Win32 form on purpose, and Bash builtins, MSYS tools and native Windows binaries
  all accept it. If your script needs backslashes, use an exec-form hook, which spawns the process directly with an
  `args` array, or a hook with `"shell": "powershell"`.
  [plugins/manifest-reference › Quoting and path separators](https://code.claude.com/docs/en/plugins/manifest-reference#quoting-and-path-separators)
  and
  [plugins/troubleshooting › `${CLAUDE_PLUGIN_ROOT}` shows forward slashes on Windows](https://code.claude.com/docs/en/plugins/troubleshooting#claude-plugin-root-shows-forward-slashes-on-windows)

## Plugin options and path placeholders in hook commands

- Plugin hooks substitute `${user_config.*}` values in exec form only: the value is substituted into `command` and
  into each `args` element as a plain string, so no shell re-parses it.
  [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- The manifest reference lists the places `${user_config.KEY}` is substituted as MCP server config, LSP server config,
  exec-form hook `args`, and skill and agent content; it names hook `args`, not `command`, so the two pages differ on
  `command`.
  [plugins/manifest-reference › Reference a saved value](https://code.claude.com/docs/en/plugins/manifest-reference#reference-a-saved-value)
- `CLAUDE_PLUGIN_OPTION_<KEY>` is exported to hook processes for every option, with `<KEY>` uppercased. A shell-form
  hook reads `$CLAUDE_PLUGIN_OPTION_API_TOKEN` for `api_token`, or `$CLAUDE_PLUGIN_OPTION_WEBHOOK_URL` for a
  `webhook_url` option.
  [plugins/manifest-reference › Reference a saved value](https://code.claude.com/docs/en/plugins/manifest-reference#reference-a-saved-value)
  and [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- A shell-form plugin hook whose `command` references `${user_config.*}` fails with an error instead of running,
  because the field's value is passed to a shell that would re-parse the substituted value. To use an option value
  from a shell-form hook, read the `$CLAUDE_PLUGIN_OPTION_<KEY>` environment variable, or set `args` to switch the
  hook to exec form.
  [plugins/manifest-reference › Fields that run through a shell](https://code.claude.com/docs/en/plugins/manifest-reference#fields-that-run-through-a-shell)
  and [hooks › Exec form and shell form](https://code.claude.com/docs/en/hooks#exec-form-and-shell-form)
- Claude Code refuses to start a plugin hook that references a `${user_config.KEY}` plugin option in a shell command,
  because a configured value containing `$(...)`, backticks or `;` would run as code there. The check runs on the
  command template, so the error appears even when no value is configured yet. A shell-form hook reports:
  [errors › Plugin command references user_config in a shell command](https://code.claude.com/docs/en/errors#plugin-command-references-user-config)

  ```text
  Hook from plugin formatter@acme-tools references ${user_config.*} in a shell-form command. The substituted value would be re-parsed by the shell. Use exec form instead — {"command": "<executable>", "args": ["${user_config.KEY}", ...]} — or read $CLAUDE_PLUGIN_OPTION_<KEY> from the hook's environment. Command: ./scripts/notify.sh ${user_config.webhook_url}
  ```

- To fix it, add an `args` array so the hook runs in exec form, where each `${user_config.KEY}` becomes one argument
  with no shell in between; or drop the reference and read the `$CLAUDE_PLUGIN_OPTION_<KEY>` environment variable
  inside the script.
  [errors › Plugin command references user_config in a shell command](https://code.claude.com/docs/en/errors#plugin-command-references-user-config)

## PowerShell hooks

- On Windows, you can run individual hooks in PowerShell by setting `"shell": "powershell"` on a command hook. Claude
  Code auto-detects `pwsh.exe`, the PowerShell 7 and later executable, and falls back to `powershell.exe` for Windows
  PowerShell 5.1. [hooks › Windows PowerShell tool](https://code.claude.com/docs/en/hooks#windows-powershell-tool)

  ```json
  { "type": "command", "shell": "powershell", "command": "Write-Host 'File written'" }
  ```

- To reference the project root from a PowerShell shell-form command, write `${CLAUDE_PROJECT_DIR}` or
  `$env:CLAUDE_PROJECT_DIR`. Claude Code rewrites the `${CLAUDE_PROJECT_DIR}`, `${CLAUDE_PLUGIN_ROOT}` and
  `${CLAUDE_PLUGIN_DATA}` placeholders in a PowerShell shell-form command to PowerShell's `${env:NAME}` form, whether
  the hook is defined in `settings.json`, a plugin or a skill. PowerShell then resolves the value from the exported
  environment after parsing, so the placeholder works inside double-quoted strings but not inside single-quoted
  strings, where PowerShell never expands variables.
  [hooks › Windows PowerShell tool](https://code.claude.com/docs/en/hooks#windows-powershell-tool)
- Don't write the bare `$CLAUDE_PROJECT_DIR` spelling in a PowerShell hook. PowerShell parses it as an undefined local
  variable and resolves it to `$null`, which leaves the script path without its project-root prefix. Claude Code
  doesn't rewrite that form; it logs a warning in the debug log instead.
  [hooks › Windows PowerShell tool](https://code.claude.com/docs/en/hooks#windows-powershell-tool)

  ```json
  {
    "type": "command",
    "shell": "powershell",
    "command": "& \"$env:CLAUDE_PROJECT_DIR\\.claude\\hooks\\check.ps1\""
  }
  ```

- Set `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY` to `1` to stop Claude Code from passing
  `-ExecutionPolicy Bypass` when spawning PowerShell for tool calls, hooks and status line commands, and respect the
  machine's effective execution policy instead. By default Claude Code bypasses execution policy at process scope so
  `.ps1` scripts and module imports work on default-Restricted Windows installs. Process-scope bypass never overrides
  Group Policy `MachinePolicy` or `UserPolicy` regardless of this setting.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## HTTP hooks

- `type: "http"` hooks POST event data to an HTTP endpoint instead of running a shell command. The endpoint receives
  the same JSON that a command hook would receive on stdin, sent as the POST request body with
  `Content-Type: application/json`, and returns results through the response body using the same JSON output format as
  command hooks. Error handling differs from command hooks. They suit a web server, cloud function or external service
  handling hook logic, such as a shared audit service that logs tool use events across a team.
  [hooks-guide › HTTP hooks](https://code.claude.com/docs/en/hooks-guide#http-hooks),
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
  and [hooks › HTTP hook fields](https://code.claude.com/docs/en/hooks#http-hook-fields)
- In addition to the common fields, HTTP hooks accept these fields.
  [hooks › HTTP hook fields](https://code.claude.com/docs/en/hooks#http-hook-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `url` | yes | URL to send the POST request to |
  | `headers` | no | Additional HTTP headers as key-value pairs. Values support environment variable interpolation using `$VAR_NAME` or `${VAR_NAME}` syntax. Only variables listed in `allowedEnvVars` are resolved |
  | `allowedEnvVars` | no | List of environment variable names that may be interpolated into header values. References to unlisted variables are replaced with empty strings. Required for any env var interpolation to work |

- This handler sends `PreToolUse` events for Bash calls to a local validation service, authenticating with a token
  from the `MY_TOKEN` environment variable.
  [hooks › HTTP hook fields](https://code.claude.com/docs/en/hooks#http-hook-fields)

  ```json
  {
    "type": "http",
    "url": "http://localhost:8080/hooks/pre-tool-use",
    "timeout": 30,
    "headers": { "Authorization": "Bearer $MY_TOKEN" },
    "allowedEnvVars": ["MY_TOKEN"]
  }
  ```

## MCP tool hooks

- In addition to the common fields, `type: "mcp_tool"` hooks accept these fields.
  [hooks › MCP tool hook fields](https://code.claude.com/docs/en/hooks#mcp-tool-hook-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `server` | yes | Name of a configured MCP server. For a [plugin-bundled server](https://code.claude.com/docs/en/mcp#plugin-provided-mcp-servers), this is the scoped name `plugin:<plugin-name>:<server-name>`, such as `plugin:my-plugin:db`, not the bare server key |
  | `tool` | yes | Name of the tool to call on that server |
  | `input` | no | Arguments passed to the tool. String values support `${path}` substitution from the hook's [JSON input](https://code.claude.com/docs/en/hooks#common-input-fields), such as `"${tool_input.file_path}"` |

  ```json
  {
    "type": "mcp_tool",
    "server": "my_server",
    "tool": "security_scan",
    "input": { "file_path": "${tool_input.file_path}" }
  }
  ```

  This hook, on `PostToolUse` with matcher `Write|Edit`, calls `security_scan` on `my_server` after each edit and
  passes the edited file's path.
- Claude Code reads the tool's text content the same way it reads command-hook stdout, following the parsing rule
  under exit code 0. If the tool returns `isError: true`, the hook produces a non-blocking error and execution
  continues. [hooks › MCP tool hook fields](https://code.claude.com/docs/en/hooks#mcp-tool-hook-fields)
- On events where a hook can block or change the result, such as `PreToolUse` or `Stop`, Claude Code waits for a
  connecting server before it calls the tool, for at most `MCP_TIMEOUT` and within the hook's own `timeout`. On
  observational events, such as `Notification` or `SessionEnd`, it doesn't wait.
  [hooks › MCP tool hook fields](https://code.claude.com/docs/en/hooks#mcp-tool-hook-fields)
- A server showing the `cached` status connects when the hook calls its tool. If the server isn't connected at that
  point, the hook produces a non-blocking error and execution continues. The hook never starts an OAuth flow, so
  authenticate the server from `/mcp` first.
  [hooks › MCP tool hook fields](https://code.claude.com/docs/en/hooks#mcp-tool-hook-fields)
- `SessionStart` at launch, including with `--continue` or `--resume`, and every `Setup` event fire before the
  session's MCP servers are available to hooks. Claude Code skips their `mcp_tool` hooks without calling the tool, and
  the debug log records `mcp_tool hooks are not available for the 'SessionStart' hook event (no MCP client context)`,
  or the same message naming `Setup`. When `SessionStart` fires again later in the session, after `/clear` or a
  compaction, its `mcp_tool` hooks run. For anything the session needs at launch, use a `type: "command"` hook on
  `SessionStart` instead. [hooks › MCP tool hook fields](https://code.claude.com/docs/en/hooks#mcp-tool-hook-fields)

## Async hooks

- By default, hooks block Claude's execution until they complete. For long-running tasks like deployments, test suites
  or external API calls, set `"async": true` to run the hook in the background while Claude continues working. Async
  hooks can't block or control Claude's behavior: response fields like `decision`, `permissionDecision` and
  `continue` have no effect, because the action they would have controlled has already completed.
  [hooks › Run hooks in the background](https://code.claude.com/docs/en/hooks#run-hooks-in-the-background)
- `"async": true` is only available on `type: "command"` hooks.
  [hooks › Configure an async hook](https://code.claude.com/docs/en/hooks#configure-an-async-hook)
- This `PostToolUse` handler, with matcher `Write|Edit`, runs a script in the background so Claude keeps working while
  it runs.
  [hooks › Run tests after file changes](https://code.claude.com/docs/en/hooks#run-tests-after-file-changes)

  ```json
  {
    "type": "command",
    "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/run-tests-async.sh",
    "args": [],
    "async": true
  }
  ```

- Claude Code still enforces `timeout` on a hook you run with `asyncRewake`.
  [hooks › Configure an async hook](https://code.claude.com/docs/en/hooks#configure-an-async-hook)
- Claude Code delivers an async hook's results only while the session runs. In non-interactive mode with the `-p`
  flag, it kills any async hook still running at teardown and finalizes it with outcome `cancelled`; if your hook's
  work must outlive a `claude -p` session, start a fully detached process from it.
  [hooks › Configure an async hook](https://code.claude.com/docs/en/hooks#configure-an-async-hook)
- When an async hook fires, Claude Code starts the hook process and immediately continues without waiting for it. The
  hook receives the same JSON input via stdin as a synchronous hook.
  [hooks › How async hooks execute](https://code.claude.com/docs/en/hooks#how-async-hooks-execute)
- After the background process exits, Claude Code delivers the `additionalContext` and `systemMessage` fields from the
  hook's JSON response to Claude on the next conversation turn; if the session is idle, the response waits until the
  next user interaction. Unlike a synchronous hook's `systemMessage`, neither field is shown to you. An `asyncRewake`
  hook that exits with code 2 wakes Claude immediately even when the session is idle. A `PostToolUse` async hook
  reports results to Claude through `additionalContext` in `hookSpecificOutput`.
  [hooks › Configure an async hook](https://code.claude.com/docs/en/hooks#configure-an-async-hook),
  [hooks › How async hooks execute](https://code.claude.com/docs/en/hooks#how-async-hooks-execute),
  [hooks › Limitations](https://code.claude.com/docs/en/hooks#limitations)
  and [hooks › Run tests after file changes](https://code.claude.com/docs/en/hooks#run-tests-after-file-changes)
- Claude Code validates that JSON response against the same output schema as synchronous hooks, and drops any field
  whose value has the wrong type, such as a `systemMessage` that isn't a string, instead of delivering it. Run with
  `--debug` to see a warning naming each dropped field.
  [hooks › How async hooks execute](https://code.claude.com/docs/en/hooks#how-async-hooks-execute)
- Async hook completion notifications are suppressed by default. To see them, enable verbose mode with `Ctrl+O` or
  start Claude Code with `--verbose`.
  [hooks › How async hooks execute](https://code.claude.com/docs/en/hooks#how-async-hooks-execute)
- Each execution of an async hook creates a separate background process. There is no deduplication across multiple
  firings of the same async hook. [hooks › Limitations](https://code.claude.com/docs/en/hooks#limitations)

## The environment hook processes get

- `$CLAUDE_CODE_REMOTE` is `"true"` in remote web environments and not set in the local CLI.
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
- `CLAUDECODE` is set to `1` in subprocesses Claude Code spawns, including hook commands. IDE extensions also set it
  in their integrated terminals. To check whether the current process was spawned directly by a tool call or hook,
  rather than inside a stdio MCP server that Claude Code started, use `CLAUDE_CODE_CHILD_SESSION` instead.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_CHILD_SESSION` is set to `1` in subprocesses Claude Code spawns via the Bash, PowerShell and Monitor
  tools, hook commands and status line commands. It is not set for stdio MCP server subprocesses. Unlike
  `CLAUDECODE`, only Claude Code itself sets it when it launches a subprocess, not IDE extensions, so it reliably
  distinguishes a nested session from a top-level `claude` launched in an IDE-integrated terminal.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_SESSION_ID` is set automatically to the current session ID in Bash and PowerShell tool subprocesses,
  hook command subprocesses and stdio MCP server subprocesses. For Bash, PowerShell and hooks it matches the
  `session_id` field in the hook JSON input and is updated on `/clear`.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_BRIDGE_SESSION_ID` is set automatically in Bash tool and hook command subprocesses while the session
  has an active Remote Control connection, and removed when the connection ends. Its value is the session's ID in
  `session_` form, the same identifier that appears in the session's `claude.ai/code` URL. In cloud sessions, read
  `CLAUDE_CODE_REMOTE_SESSION_ID` instead. [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_EFFORT` is set automatically in Bash tool subprocesses and hook commands to the effort level in effect when
  the subprocess starts: `low`, `medium`, `high`, `xhigh` or `max`. It matches the `effort.level` field passed to
  hooks, and is only set when the current model supports the effort parameter.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_PID` is Claude Code's own process ID, set in the subprocesses it spawns: Bash and PowerShell tool commands
  and hook commands. Read it from your own scripts to identify or signal the parent Claude Code process deliberately.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_MESSAGING_SOCKET` is set by Claude Code, not by you: in sessions that bind an inbox socket, Claude Code
  exports that socket's path to hooks and Bash commands when it binds the socket, and in a session that starts with
  messaging on it binds the socket before any hook runs, including `SessionStart`. Each session exports its own
  socket, and settings `env` blocks can't set it.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
  and
  [cross-session-messaging › The session's inbox socket](https://code.claude.com/docs/en/cross-session-messaging#the-sessions-inbox-socket)
- `CLAUDE_CODE_MESSAGING_TOKEN` is set by Claude Code, not by you: in sessions that bind an inbox socket, Claude Code
  exports this per-session token to hooks and Bash commands alongside `CLAUDE_CODE_MESSAGING_SOCKET`. A script posting
  to the socket can send `{"type":"auth","token":"<token>"}` as its first line to prove it belongs to the session. On
  native Windows, Claude Code requires this line and closes any connection that doesn't open with a valid one. Claude
  Code closes a connection that hasn't sent a complete line within 30 seconds. Each session exports its own token, and
  settings `env` blocks can't set it.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
  and
  [cross-session-messaging › The session's inbox socket](https://code.claude.com/docs/en/cross-session-messaging#the-sessions-inbox-socket)
- When no `crossSessionInbound` value applies (that setting chooses what a session does with messages arriving from
  your other sessions), Claude Code delivers a message it verifies came from the session's own child processes, such
  as a hook or Bash command posting back to its own session's socket. On Linux, including WSL 2, it verifies by
  process evidence even for a child that has exited; on macOS only while the posting process is still running; in a
  container where Claude Code runs as process ID 1, and on native Windows, it has no process evidence. Where process
  evidence is missing, it instead verifies a child that sent `CLAUDE_CODE_MESSAGING_TOKEN` in the auth line that
  opened its connection, and on native Windows the token is the only way. When it can verify neither way, it treats
  the message like any other that asserts no permission class, so a session that bypasses permission prompts holds it
  for your approval.
  [cross-session-messaging › The session's inbox socket](https://code.claude.com/docs/en/cross-session-messaging#the-sessions-inbox-socket)
- `CLAUDE_CODE_SHELL_PREFIX` is a command prefix that wraps shell commands Claude Code spawns, including hook
  commands. PowerShell hooks and exec-form hooks run without the prefix. The wrapper receives the command line as a
  single shell-quoted argument in `$1`, so it must re-evaluate `$1` with a shell, for example `exec bash -c "$1"`.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Claude Code doesn't pass `OTEL_*` environment variables to the subprocesses it spawns, including hooks.
  [monitoring-usage › Administrator configuration](https://code.claude.com/docs/en/monitoring-usage#administrator-configuration)
- On Linux and WSL, setting `CLAUDE_CODE_TOOL_MEMORY_LIMIT` to a size such as `4G` caps the memory that Bash,
  PowerShell, and Monitor tool commands can use. Claude Code can also count other kinds of processes it starts against
  the same limit, and `hooks` (hook commands) is one of the kinds. Set `CLAUDE_CODE_TOOL_MEMORY_CGROUP_EXCLUDE` to a
  comma-separated list of the kinds to exempt from the cap; Claude Code applies the cap to every kind not on your
  list. Set it to `none` to cap every kind, or to `all-new` to cap only Bash, PowerShell, and Monitor tool commands.
  When the variable is unset, Claude Code takes the set of other capped kinds from configuration Anthropic delivers
  from the server, and that set can change over time, so set the variable when you need a set that doesn't change.
  Even with every kind capped, Claude Code excludes from the cap a hook that can block or change the outcome of an
  action, and any MCP server that such a hook calls, so the kernel killing a permission-gating hook can't allow the
  action it was blocking.
  [tools-reference › Memory limit on Linux and WSL](https://code.claude.com/docs/en/tools-reference#memory-limit-on-linux-and-wsl)

## Security practices

- Keep these practices in mind when writing hooks:
  [hooks › Security best practices](https://code.claude.com/docs/en/hooks#security-best-practices)
  - Validate and sanitize inputs: never trust input data blindly
  - Always quote shell variables: use `"$VAR"` not `$VAR`
  - Block path traversal: check for `..` in file paths
  - Use absolute paths: specify full paths for scripts
  - Skip sensitive files: avoid `.env`, `.git/`, keys, etc.

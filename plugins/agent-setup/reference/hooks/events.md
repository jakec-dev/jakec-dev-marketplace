# Hook events other than tool events

Hooking the lifecycle and every event that is not a tool event: when each fires, its matcher, its input and its output.

## Contents

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

## Lifecycle and cadence

- Claude Code runs hooks at specific points during a session. When an event fires and a matcher matches, Claude Code
  passes JSON context about the event to your hook handler: for command hooks the input arrives on stdin, for HTTP
  hooks as the POST request body. Your handler can then inspect the input, take action, and optionally return a
  decision.
  [hooks › Hook lifecycle](https://code.claude.com/docs/en/hooks#hook-lifecycle)
- Events fall into three cadences:
  [hooks › Hook lifecycle](https://code.claude.com/docs/en/hooks#hook-lifecycle)
  - per session: `SessionStart` and `SessionEnd`
  - per turn: `UserPromptSubmit`, `Stop`, and `StopFailure`
  - on every tool call inside the agentic loop: `PreToolUse` and `PostToolUse`, except
    [`EndConversation`](https://code.claude.com/docs/en/tools-reference#endconversation-tool-behavior) calls, which
    skip both
- The lifecycle diagram shows this order. Optional `Setup` feeds into `SessionStart`. Then a per-turn loop contains
  `UserPromptSubmit`, `UserPromptExpansion` for slash commands, the nested agentic loop (`PreToolUse`,
  `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `PostToolBatch`, `SubagentStart`/`SubagentStop`,
  `TaskCreated`, `TaskCompleted`), and `Stop` or `StopFailure`. `TeammateIdle`, `PreCompact`, `PostCompact` and
  `SessionEnd` follow. `Elicitation` and `ElicitationResult` are nested inside MCP tool execution. `PermissionDenied`
  is a side branch from `PermissionRequest` for auto-mode denials. `WorktreeCreate`, `WorktreeRemove`,
  `Notification`, `ConfigChange`, `InstructionsLoaded`, `CwdChanged`, `FileChanged` and `DirectoryAdded` are
  standalone async events. `PreModelSwitch` is a standalone sequential event that runs before a requested model
  switch. `PostModelSwitch` is a standalone async event that runs after the session's model changes. `MessageDisplay`
  is a display-only event that runs while assistant message text streams.
  [hooks › Hook lifecycle](https://code.claude.com/docs/en/hooks#hook-lifecycle)
- This table summarizes when each event fires:
  [hooks › Hook lifecycle](https://code.claude.com/docs/en/hooks#hook-lifecycle)

  | Event | When it fires |
  | :- | :- |
  | `SessionStart` | When a session begins or resumes |
  | `Setup` | When you start Claude Code with `--init-only`, or with `--init` or `--maintenance` in `-p` mode. For one-time preparation in CI or scripts |
  | `UserPromptSubmit` | When a prompt is submitted, before Claude processes it. Also fires on [turns Claude Code starts on its own](https://code.claude.com/docs/en/hooks#userpromptsubmit) |
  | `UserPromptExpansion` | When a user-typed command expands into a prompt, before it reaches Claude. Can block the expansion |
  | `PreToolUse` | Before a tool call executes. Can block it |
  | `PermissionRequest` | When a tool call needs a permission decision |
  | `PermissionDenied` | When auto mode denies a tool call, including denials without a classifier verdict. Use JSON `hookSpecificOutput.retry: true` to tell the model it may retry the denied tool call. Claude Code ignores `retry` when the classifier produced no verdict |
  | `PostToolUse` | After a tool call succeeds |
  | `PostToolUseFailure` | After a tool call fails |
  | `PostToolBatch` | After a full batch of parallel tool calls resolves, before the next model call |
  | `Notification` | When Claude Code sends a notification |
  | `MessageDisplay` | While assistant message text is displayed |
  | `SubagentStart` | When a subagent is spawned |
  | `SubagentStop` | When a subagent finishes |
  | `TaskCreated` | When a task is being created via `TaskCreate` |
  | `TaskCompleted` | When a task is being marked as completed |
  | `Stop` | When Claude finishes responding |
  | `StopFailure` | When the turn ends due to an API error |
  | `TeammateIdle` | When an [agent team](https://code.claude.com/docs/en/agent-teams) teammate is about to go idle |
  | `InstructionsLoaded` | When a CLAUDE.md or `.claude/rules/*.md` file is loaded into context. Fires at session start and when files are lazily loaded during a session |
  | `ConfigChange` | When a configuration file changes during a session |
  | `CwdChanged` | When the working directory changes, for example when Claude executes a `cd` command. Useful for reactive environment management with tools like direnv |
  | `DirectoryAdded` | When a working directory is added mid-session via `/add-dir` or the SDK `register_repo_root` control request |
  | `FileChanged` | When a watched file changes on disk. The `matcher` field specifies which filenames to watch |
  | `WorktreeCreate` | When a worktree is being created via `--worktree`, `isolation: "worktree"`, or for a background session. Replaces default git behavior |
  | `WorktreeRemove` | When a worktree that a `WorktreeCreate` hook created is being removed |
  | `PreCompact` | Before context compaction |
  | `PostCompact` | After context compaction completes |
  | `PreModelSwitch` | Before Claude Code applies a model switch that you or a client requested. Can block the switch |
  | `PostModelSwitch` | After the session's model changes, including changes Claude Code makes on its own, such as restoring the model when you resume a session |
  | `Elicitation` | When an MCP server requests user input during a tool call |
  | `ElicitationResult` | After a user responds to an MCP elicitation, before the response is sent back to the server |
  | `SessionEnd` | When a session terminates |

- In a plugin mod, each settings hook event, such as `Stop`, `SessionEnd`, or `PostToolUse`, is also an event named
  `classic.` followed by the settings hook event's name, such as `classic.Stop`. Where the built-in guard loads, a hook
  on these events in a mod you install doesn't run.
  [plugins/mods/events › Handle the settings hook events](https://code.claude.com/docs/en/plugins/mods/events#hook-the-settings-hook-events)

## SessionStart

- SessionStart runs when Claude Code starts a new session or resumes an existing session. It is useful for loading
  development context like existing issues or recent changes to your codebase, or setting up environment variables.
  For static context that doesn't require a script, use CLAUDE.md instead.
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- SessionStart runs on every session, so keep these hooks fast. Only `type: "command"` and `type: "mcp_tool"` hooks
  are supported.
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- To re-inject critical context after every compaction, use a `SessionStart` hook with a `compact` matcher. Claude
  Code adds plain text your command writes to stdout to Claude's context. You can replace the `echo` with any
  command that produces dynamic output, like `git log --oneline -5` to show recent commits. Add this to
  `.claude/settings.json` in your project root:
  [hooks-guide › Re-inject context after compaction](https://code.claude.com/docs/en/hooks-guide#re-inject-context-after-compaction)

  ```json
  {
    "hooks": {
      "SessionStart": [
        {
          "matcher": "compact",
          "hooks": [
            {
              "type": "command",
              "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
            }
          ]
        }
      ]
    }
  }
  ```

- After compaction, these hook rows apply to what the compacted context holds:
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

  | Mechanism | After compaction |
  | :- | :- |
  | Context that hooks added earlier | Summarized with the rest of the conversation |
  | [SessionStart hooks](https://code.claude.com/docs/en/hooks-guide#re-inject-context-after-compaction) that match the `compact` source | Claude Code runs them and adds their output to the compacted context |

### Matcher

- The matcher value corresponds to how the session was initiated:
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)

  | Matcher | When it fires |
  | :- | :- |
  | `startup` | New session |
  | `resume` | `--resume`, `--continue`, or `/resume` |
  | `clear` | `/clear` |
  | `compact` | Auto or manual compaction |
  | `fork` | A new session forked from an existing one: `--fork-session` with `--resume` or `--continue`, the `/fork` background copy, `/branch`, or a conversation you [move to the background](https://code.claude.com/docs/en/agent-view#from-inside-a-session) |

### Timing

- When you start an interactive session, resume a conversation at launch with `--continue` or `--resume`, or run
  `/clear`, SessionStart hooks run in the background. You can type right away, and a conversation you resumed appears
  without waiting for the hooks. Claude's first response still waits for the hooks to finish, so their context reaches
  Claude.
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- When you switch conversations with `/resume` inside a session, the switch waits for the hooks to finish instead.
  If you run `/clear` or switch to another conversation while background hooks are still running, nothing they return
  applies to the session.
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- The same wait applies at launch, including a resumed session: a prompt you send while SessionStart hooks are still
  running doesn't reach Claude until they finish. During either wait, press `Esc` to take the prompt back into the
  input without sending it. The hooks keep running.
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- A prompt still waiting on hooks at the moment the session moves to the background isn't sent, and nothing on screen
  says so. This includes a prompt you typed while SessionStart hooks were still running.
  [agent-view › Prompts sent as the session moves to the background](https://code.claude.com/docs/en/agent-view#switch-sessions-without-leaving-the-terminal)

### Input

- In addition to the common input fields, SessionStart hooks receive `source` and optionally `model`, `agent_type`,
  and `session_title`:
  [hooks › SessionStart input](https://code.claude.com/docs/en/hooks#sessionstart-input)

  | Field | Description |
  | :- | :- |
  | `source` | How the session started: `"startup"` for new sessions, `"resume"` for resumed sessions, `"clear"` after `/clear`, `"compact"` after compaction, or `"fork"` for a new session forked from an existing one |
  | `model` | The active model identifier. It can be omitted, for example after `/clear` or when a session is restored through conversation recovery, so check for the field before reading it |
  | `agent_type` | The agent name, present when you start Claude Code with `claude --agent <name>` |
  | `session_title` | The session's custom title, present when one is set, for example with `--name`, `/rename`, a hook's `sessionTitle` output, or the Agent SDK's `renameSession()`. A hook that emits `sessionTitle` can check this field first to avoid overwriting an existing custom title |

- A session you haven't named can still have a
  [generated title](https://code.claude.com/docs/en/sessions#name-your-sessions). That title isn't a custom title and
  doesn't appear in `session_title`.
  [hooks › SessionStart input](https://code.claude.com/docs/en/hooks#sessionstart-input)
- When `source` is `"resume"` or `"fork"` and the transcript contains at least one response from Claude, SessionStart
  hooks also receive these four fields. Your hook can use them to report what resuming a stale conversation costs
  before the first request, for example in a `systemMessage`:
  [hooks › SessionStart input](https://code.claude.com/docs/en/hooks#sessionstart-input)

  | Field | Description |
  | :- | :- |
  | `seconds_since_last_response` | Wall-clock seconds since the last response in the resumed transcript |
  | `context_tokens` | Tokens the first request of the resumed session re-sends as its prompt |
  | `prompt_cache_likely_expired` | `true` when the last response is older than the session's [prompt cache lifetime](https://code.claude.com/docs/en/prompt-caching#cache-lifetime) or a later compaction replaced the cached conversation |
  | `estimated_cache_write_usd` | Estimated cost in US dollars of writing `context_tokens` to the prompt cache on the session's model, excluding the response |

### Output

- A SessionStart hook can add context for Claude, supply the first user message, set the session title, and watch
  files. Return the field for each one, in addition to the JSON output fields available to all hooks:
  [hooks › SessionStart decision control](https://code.claude.com/docs/en/hooks#sessionstart-decision-control)

  | Field | Description |
  | :- | :- |
  | `additionalContext` | String added to Claude's context at the start of the conversation, before the first prompt. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) for how the text is delivered and what to put in it |
  | `initialUserMessage` | String used as the first user message of the session, in [non-interactive mode](https://code.claude.com/docs/en/headless) with the `-p` flag. It becomes the first turn even if you pass no prompt. A prompt you do pass follows as the next turn |
  | `sessionTitle` | Sets the session title, with the same effect as `/rename`. Applies when `source` is `"startup"`, `"resume"`, or `"fork"` |
  | `watchPaths` | Array of absolute paths to watch for [FileChanged](https://code.claude.com/docs/en/hooks#filechanged) events during this session |

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "SessionStart",
      "additionalContext": "Current branch: feat/auth-refactor\nUncommitted changes: src/auth.ts, src/login.tsx\nActive issue: #4211 Migrate to OAuth2",
      "sessionTitle": "auth-refactor"
    }
  }
  ```

- A hook that only adds context can print it without building JSON, because Claude Code adds a SessionStart hook's
  [plain-text stdout](https://code.claude.com/docs/en/hooks#exit-code-0) to Claude's context.
  [hooks › SessionStart decision control](https://code.claude.com/docs/en/hooks#sessionstart-decision-control)
- If your plugin's SessionStart hook supplies `initialUserMessage` or `sessionTitle`, install the plugin before the
  session starts. Claude Code ignores both fields from a plugin that finishes installing after the SessionStart hooks
  have run.
  [hooks › SessionStart decision control](https://code.claude.com/docs/en/hooks#sessionstart-decision-control)

### Persist environment variables

- SessionStart hooks have access to the `CLAUDE_ENV_FILE` environment variable, which provides a file path where you
  can persist environment variables for the shell commands Claude runs later in the session. To set individual
  environment variables, write `export` statements to `CLAUDE_ENV_FILE`. Use append (`>>`) to preserve variables set
  by other hooks:
  [hooks › Persist environment variables](https://code.claude.com/docs/en/hooks#persist-environment-variables)

  ```bash
  #!/bin/bash

  if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
    echo 'export DEBUG_LOG=true' >> "$CLAUDE_ENV_FILE"
    echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
  fi

  exit 0
  ```

- To capture all environment changes from setup commands, compare the exported variables before and after:
  [hooks › Persist environment variables](https://code.claude.com/docs/en/hooks#persist-environment-variables)

  ```bash
  #!/bin/bash

  ENV_BEFORE=$(export -p | sort)

  # Run your setup commands that modify the environment
  source ~/.nvm/nvm.sh
  nvm use 20

  if [ -n "$CLAUDE_ENV_FILE" ]; then
    ENV_AFTER=$(export -p | sort)
    comm -13 <(echo "$ENV_BEFORE") <(echo "$ENV_AFTER") >> "$CLAUDE_ENV_FILE"
  fi

  exit 0
  ```

- Each Bash command runs the file's contents as shell code before the command itself, so a line there can use anything
  Bash evaluates, such as the `$PATH` reference in `export PATH="$PATH:./node_modules/.bin"`.
  [hooks › Persist environment variables](https://code.claude.com/docs/en/hooks#persist-environment-variables)
- `CLAUDE_ENV_FILE` is the path to a shell script whose contents Claude Code runs before each Bash command in the same
  shell process, so exports in the file are visible to the command. Use it to persist virtualenv or conda activation
  across commands.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_ENV_FILE` is available for SessionStart, Setup, CwdChanged, and FileChanged hooks. Other hook events don't
  have access to this variable, and neither does a hook that runs in PowerShell, whether through
  [`"shell": "powershell"`](https://code.claude.com/docs/en/hooks#command-hook-fields) or by default on Windows
  without Git Bash.
  [hooks › Persisted variables in PowerShell commands](https://code.claude.com/docs/en/hooks#persisted-variables-in-powershell-commands)
- [PowerShell](https://code.claude.com/docs/en/tools-reference#powershell-tool) commands receive the variables from
  `CLAUDE_ENV_FILE` too, but PowerShell never runs the file. Claude Code reads the assignments out of it and copies
  them into the PowerShell command's environment instead. It does so only when every line is one of the following,
  across what every hook in this session wrote and any script you
  [set `CLAUDE_ENV_FILE` to](https://code.claude.com/docs/en/env-vars) before launch:
  [hooks › Persisted variables in PowerShell commands](https://code.claude.com/docs/en/hooks#persisted-variables-in-powershell-commands)
  - A blank line or a `#` comment
  - One assignment at the start of the line, written `export NAME=value`, `declare -x NAME=value`, or `NAME=value`,
    with a value Bash would use exactly as written, made of any mix of these parts: unquoted text that uses only
    letters, digits, and the characters `_ @ % + = : , . / -`, text in single quotes, and text in double quotes where
    any `$`, backtick, or `"` inside is escaped with a backslash
- If any line is of another kind, such as `export PATH="$PATH:./node_modules/.bin"` with its unescaped `$PATH`, a
  `source` command, or the `$'...'` strings that `direnv export bash` prints, PowerShell commands receive none of the
  variables, and `claude --debug` logs `Session environment is not all plain assignments`. Bash commands still
  receive all of them.
  [hooks › Persisted variables in PowerShell commands](https://code.claude.com/docs/en/hooks#persisted-variables-in-powershell-commands)
- On Windows, PowerShell commands also don't receive a variable whose value contains `/` or `\`, because Git Bash and
  Windows write paths differently. A [sandboxed](https://code.claude.com/docs/en/sandboxing) PowerShell command
  receives none of the variables.
  [hooks › Persisted variables in PowerShell commands](https://code.claude.com/docs/en/hooks#persisted-variables-in-powershell-commands)

## Setup

- Setup fires only when you launch Claude Code with `--init-only`, or with `--init` or `--maintenance` in
  non-interactive mode with the `-p` flag. It doesn't fire on normal startup. Use it for one-time dependency
  installation or scheduled cleanup that you trigger explicitly from CI or scripts, separate from normal session
  startup. For per-session initialization, use SessionStart instead.
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)
- The matcher value corresponds to the CLI flag that triggered the hook:
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)

  | Matcher | When it fires |
  | :- | :- |
  | `init` | `claude --init-only` or `claude -p --init` |
  | `maintenance` | `claude -p --maintenance` |

- When you run `claude --init-only`, Claude Code runs Setup hooks and `SessionStart` hooks with the `startup` matcher,
  then exits without starting a conversation.
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)
- When you start or continue a conversation with `-p`, you also need to supply a prompt, as an argument or piped on
  stdin. You can skip the prompt when a `SessionStart` hook supplies `initialUserMessage` or when you resume a session
  with a deferred tool call.
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)
- On success, `--init-only` prints nothing to the terminal. To confirm the hooks ran, start with
  `claude --debug-file <path> --init-only`, replacing `<path>` with a log file location, and check the log for the
  Setup and SessionStart hook entries.
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)
- Because Setup doesn't fire on every launch, a plugin that needs a dependency installed can't rely on Setup alone.
  The practical pattern is to check for the dependency on first use and install on miss, for example a hook or skill
  that tests for `${CLAUDE_PLUGIN_DATA}/node_modules` and runs `npm install` if absent. See the
  [persistent data directory](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data)
  for where to store installed dependencies. If you distribute your plugin through a marketplace, you may not need
  this pattern: Claude Code
  [installs eligible Node.js package dependencies automatically](https://code.claude.com/docs/en/plugins/loading#node-js-package-dependencies)
  when it caches the plugin.
  [hooks › Setup](https://code.claude.com/docs/en/hooks#setup)
- Input: besides the common input fields, Setup hooks receive a `trigger` field set to either `"init"` or
  `"maintenance"`.
  [hooks › Setup input](https://code.claude.com/docs/en/hooks#setup-input)
- Setup hooks can't block; execution continues on any exit code. On every exit code, Claude Code discards a Setup
  hook's JSON output fields, such as `systemMessage`, `continue`, and `hookSpecificOutput.additionalContext`. With
  `-p`, a Setup hook's stdout, stderr, and exit code appear in the run's output only as
  [`hook_response` events](https://code.claude.com/docs/en/headless#read-session-metadata) when you launch with
  `--output-format stream-json --verbose`.
  [hooks › Setup decision control](https://code.claude.com/docs/en/hooks#setup-decision-control)
- Setup hooks have access to `CLAUDE_ENV_FILE`. If your hook writes variables to that file, they persist into
  subsequent Bash commands for the session, as in SessionStart hooks. Only `type: "command"` hooks run on `Setup`; a
  `type: "mcp_tool"` hook on `Setup` is always skipped.
  [hooks › Setup decision control](https://code.claude.com/docs/en/hooks#setup-decision-control)

## UserPromptSubmit

- UserPromptSubmit runs when a prompt is submitted, before Claude processes it. This allows you to add additional
  context based on the prompt or conversation, validate prompts, or block certain types of prompts.
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- `UserPromptSubmit` hooks don't fire only on prompts you type. Claude Code also runs them on a session-scoped
  scheduled task firing, including a `/loop` iteration; a background subagent reporting back to the session that
  started it; and a message another session sends to your main conversation.
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- `UserPromptSubmit` hooks have a default timeout of 30 seconds for `command`, `http`, and `mcp_tool` types, shorter
  than the 600-second default for those types on most other events. Because this hook runs before every prompt and
  blocks model processing until it completes, a stuck hook stalls the session. If your hook needs more time, set the
  `timeout` field in the hook entry.
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- Apart from a command hook you run with `async: true`, a `UserPromptSubmit` command, HTTP, or MCP tool hook that
  reaches its timeout is canceled and its output, including any `additionalContext`, is discarded. The prompt still
  reaches Claude without that context. To block the prompt instead, set
  [`onFailure: "block"`](https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails) on a command or
  HTTP hook. The transcript shows a notice naming the hook, the timeout that fired, and that
  the output was discarded.
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- An Agent SDK callback hook on `UserPromptSubmit` that reaches its timeout blocks the prompt with a message naming
  the hook and the timeout, because a callback there can be acting as a policy gate that must not fail open. The
  session continues.
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- A `UserPromptSubmit` hook that blocks the continuation prompt ends the wait for a claude.ai usage limit to reset
  without continuing the task.
  [interactive-mode › Cancel the wait](https://code.claude.com/docs/en/interactive-mode#cancel-the-wait)
- If you press `Esc` or interrupt the session while hooks are still checking a prompt, the check stops and the prompt
  doesn't reach Claude. Text you typed at the terminal returns to the prompt input, and the hooks check it again when
  you resend it.
  [hooks › `Esc` during a prompt check](https://code.claude.com/docs/en/hooks#esc-during-a-prompt-check)
- A hook can block the prompt at the same moment you interrupt. The prompt then stays blocked: you see that hook's
  [block message](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind), and the text doesn't
  return to the input.
  [hooks › `Esc` during a prompt check](https://code.claude.com/docs/en/hooks#esc-during-a-prompt-check)

### Input

- In addition to the common input fields, UserPromptSubmit hooks receive the `prompt` field containing the submitted
  text. Pasted content that collapsed to a `[Pasted text #N]` placeholder arrives expanded in place. In sessions where
  Claude Code [marks pasted text for Claude](https://code.claude.com/docs/en/terminal-config#how-claude-treats-pasted-text),
  that expanded content sits between a `<pasted_content id="…">` line and a `</pasted_content id="…">` line, so
  account for those lines if your hook parses the prompt.
  [hooks › UserPromptSubmit input](https://code.claude.com/docs/en/hooks#userpromptsubmit-input)
- UserPromptSubmit hooks also receive `session_title` when the session has a custom title, with the same meaning as
  the SessionStart `session_title` field.
  [hooks › UserPromptSubmit input](https://code.claude.com/docs/en/hooks#userpromptsubmit-input)

### Output

- `UserPromptSubmit` hooks can control whether a submitted prompt is processed and add context. All JSON output fields
  are available. There are two ways to add context to the conversation on exit code 0: plain text stdout, which Claude
  Code treats as plain text and adds to Claude's context, or JSON with `additionalContext`, which gives more control.
  [hooks › UserPromptSubmit decision control](https://code.claude.com/docs/en/hooks#userpromptsubmit-decision-control)
- Neither channel produces a visible transcript entry. Plain stdout and the `additionalContext` value are each injected
  as a system reminder that starts with the hook's name; Claude reads both. To confirm delivery, check the debug log.
  [hooks › UserPromptSubmit decision control](https://code.claude.com/docs/en/hooks#userpromptsubmit-decision-control)
- To block a prompt, return a JSON object with `decision` set to `"block"`:
  [hooks › UserPromptSubmit decision control](https://code.claude.com/docs/en/hooks#userpromptsubmit-decision-control)

  | Field | Description |
  | :- | :- |
  | `decision` | `"block"` stops the prompt before it reaches Claude. Omit to allow the prompt to proceed |
  | `reason` | Shown to the user when `decision` is `"block"`. Not added to context |
  | `additionalContext` | String added to Claude's context alongside the submitted prompt. See [Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude) |
  | `sessionTitle` | Sets the session title. Use to name sessions automatically based on the prompt content |
  | `suppressOriginalPrompt` | If `true` when the hook blocks the prompt, leaves the prompt text out of the block message. See [What a blocked prompt leaves behind](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind) |

  ```json
  {
    "decision": "block",
    "reason": "Explanation for decision",
    "hookSpecificOutput": {
      "hookEventName": "UserPromptSubmit",
      "additionalContext": "My additional context here",
      "sessionTitle": "My session title",
      "suppressOriginalPrompt": true
    }
  }
  ```

- A hook that blocks by exiting 2 routes the same way as `reason`: the block message shows the stderr text to the
  user, and it isn't added to context.
  [hooks › UserPromptSubmit decision control](https://code.claude.com/docs/en/hooks#userpromptsubmit-decision-control)

### What a blocked prompt leaves behind

- A blocked prompt never reaches Claude, but its text isn't removed everywhere. By default the block message shown to
  the user ends with `Original prompt:` followed by the submitted text, and Claude Code writes that message to the
  session's transcript file on disk.
  [hooks › What a blocked prompt leaves behind](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind)
- To leave the text out of the message, print JSON with `"suppressOriginalPrompt": true` inside `hookSpecificOutput`.
  This works whether the hook blocks with `decision: "block"` or by exiting 2.
  [hooks › What a blocked prompt leaves behind](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind)
- `suppressOriginalPrompt` changes only the block message. The submitted text can still appear in local files such as
  the session transcript and your prompt history, so a blocking hook isn't a way to keep a secret off disk. To limit
  or remove those files, see [Plaintext storage](https://code.claude.com/docs/en/claude-directory#plaintext-storage)
  and [Clear local data](https://code.claude.com/docs/en/claude-directory#clear-local-data).
  [hooks › What a blocked prompt leaves behind](https://code.claude.com/docs/en/hooks#what-a-blocked-prompt-leaves-behind)

## UserPromptExpansion

- UserPromptExpansion runs when a user-typed command expands into a prompt before reaching Claude. Use it to block
  specific commands from direct invocation or to log which commands users invoke. Leave the matcher empty to fire on
  every prompt-type command; the matcher filters on `command_name`.
  [hooks › UserPromptExpansion](https://code.claude.com/docs/en/hooks#userpromptexpansion)
- Input: besides the common input fields, UserPromptExpansion hooks receive `command_args`, `command_source`, and the
  original `prompt` string. The `expansion_type` field is `slash_command` for skill and custom commands, or
  `mcp_prompt` for MCP server prompts.
  [hooks › UserPromptExpansion input](https://code.claude.com/docs/en/hooks#userpromptexpansion-input)
- `UserPromptExpansion` hooks can block the expansion or add context. All JSON output fields are available. This
  output blocks the expansion and also carries `additionalContext`:
  [hooks › UserPromptExpansion decision control](https://code.claude.com/docs/en/hooks#userpromptexpansion-decision-control)

  ```json
  {
    "decision": "block",
    "reason": "This slash command is not available",
    "hookSpecificOutput": {
      "hookEventName": "UserPromptExpansion",
      "additionalContext": "Additional context for this expansion"
    }
  }
  ```

- In that output, `decision: "block"` stops the expansion and shows `reason` to the user, and `additionalContext` is
  added alongside the expanded prompt. A hook that blocks by exiting 2 shows its stderr text to the user.
  [hooks › UserPromptExpansion decision control](https://code.claude.com/docs/en/hooks#userpromptexpansion-decision-control)

## MessageDisplay

- MessageDisplay runs while an assistant message streams to the screen. Claude Code displays the message in
  increments: each time a batch of newly completed lines is ready to render, the hook runs once with those lines and
  Claude Code renders the hook's replacement text in their place. A long message produces several calls; a short
  message may produce only one.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- Use MessageDisplay to strip markdown for a minimal display, transform the text an Agent SDK application shows its
  users, or redact API keys or internal hostnames from Claude's responses.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- Claude Code holds each batch until your hook returns, so keep the hook fast. If the hook fails or times out, Claude
  Code displays the original text. The default timeout for this event is 10 seconds; if your hook needs more time, set
  the `timeout` field in the hook entry.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- MessageDisplay is display-only: the replacement text changes only what is rendered on screen. The transcript and what
  Claude sees keep the original text, so Claude never sees the replacement, and verbose mode shows the original. The
  hook receives assistant message text only, so tool results and the text you type render unchanged.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- MessageDisplay doesn't support matchers and fires for every assistant message that streams text; messages with no
  text, such as tool-call-only responses, don't trigger it.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- In non-interactive runs, including Agent SDK queries and `claude -p`, MessageDisplay runs once per assistant message
  instead of once per batch of lines. The single call arrives after the message completes and carries the full message
  text: `index` is `0`, `final` is `true`, and `delta` holds the entire message. A hook that collects the `delta` text
  for each message receives the same total text in both modes.
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)

### Input

- In addition to the common input fields, MessageDisplay hooks receive identifiers for the turn and message, the
  position of this call within the message, and the new text in `delta`. Batch boundaries depend on how the text
  streams, so use `index` and `final` to track progress through a message rather than expecting lines to be grouped a
  particular way.
  [hooks › MessageDisplay input](https://code.claude.com/docs/en/hooks#messagedisplay-input)

  | Field | Description |
  | :- | :- |
  | `turn_id` | UUID of the current turn |
  | `message_id` | UUID of the assistant message being displayed. Stable across every batch of the same message. This is not the API `msg_…` id, so it can't be correlated with transcript message ids |
  | `index` | Zero-based index of this batch within the message |
  | `final` | `true` on the message's last batch. Each message has exactly one final batch |
  | `delta` | The newly completed lines since the prior batch, terminating newlines included. Always whole lines, except the final batch which may end mid-line. In interactive runs, the final batch's delta is empty when the message ends on a newline, so treat `final`, not a non-empty delta, as the end-of-message signal. In Agent SDK and `claude -p` runs, the single call carries the entire message |

### Output

- In addition to the JSON output fields available to all hooks, MessageDisplay hooks can return `displayContent` to
  replace the delta on screen. Omit it to display the original.
  [hooks › MessageDisplay output](https://code.claude.com/docs/en/hooks#messagedisplay-output)
- MessageDisplay hooks have no decision control. They can't block the message or change what is stored in the
  transcript or sent to Claude. Claude Code acts on `displayContent` from their JSON output and discards
  `systemMessage` and `continue`.
  [hooks › MessageDisplay output](https://code.claude.com/docs/en/hooks#messagedisplay-output)
- This example strips markdown formatting from Claude's responses for a plain-text display. The script reads each
  batch from stdin, removes bold markers and inline code backticks from `delta`, and returns the result as
  `displayContent`. Register a command hook for the event in your settings file, then save the script to
  `.claude/hooks/plain-display.sh` in your project and make it executable with `chmod +x`:
  [hooks › MessageDisplay output](https://code.claude.com/docs/en/hooks#messagedisplay-output)

  ```json
  {
    "hooks": {
      "MessageDisplay": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/plain-display.sh",
              "args": []
            }
          ]
        }
      ]
    }
  }
  ```

  ```bash
  #!/bin/bash
  jq '{hookSpecificOutput: {hookEventName: "MessageDisplay", displayContent: (.delta | gsub("\\*\\*"; "") | gsub("`"; ""))}}'
  ```

- On Windows, register the command hook so that it runs the script through PowerShell. The `-NoProfile` flag skips
  loading your PowerShell profile so the hook starts fast, and `-ExecutionPolicy Bypass` lets PowerShell run the
  local script file. Save the script to `.claude/hooks/plain-display.ps1` in your project:
  [hooks › MessageDisplay output](https://code.claude.com/docs/en/hooks#messagedisplay-output)

  ```json
  {
    "hooks": {
      "MessageDisplay": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "powershell.exe",
              "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${CLAUDE_PROJECT_DIR}/.claude/hooks/plain-display.ps1"
              ]
            }
          ]
        }
      ]
    }
  }
  ```

  ```powershell
  $batch = [Console]::In.ReadToEnd() | ConvertFrom-Json
  $text = $batch.delta -replace '\*\*', '' -replace '`', ''
  @{
    hookSpecificOutput = @{
      hookEventName = "MessageDisplay"
      displayContent = $text
    }
  } | ConvertTo-Json
  ```

- Batches with no markdown pass through unchanged. If the script fails, for example because `jq` is missing, Claude
  Code displays the original text and notes the failure only in debug output, not in the session.
  [hooks › MessageDisplay output](https://code.claude.com/docs/en/hooks#messagedisplay-output)

## SubagentStart

- SubagentStart runs when Claude spawns a subagent with the Agent tool, when Claude resumes a subagent, and each time
  an in-process agent team teammate handles a new message.
  [hooks › SubagentStart](https://code.claude.com/docs/en/hooks#subagentstart)
- SubagentStart supports matchers to filter by agent type name. For built-in agents, this is the agent name like
  `general-purpose`, `Explore`, or `Plan`. For custom subagents, this is the `name` field from the agent's
  frontmatter, not the filename.
  [hooks › SubagentStart](https://code.claude.com/docs/en/hooks#subagentstart)
- For subagents shipped by a plugin, the agent type is the plugin-scoped identifier such as `my-plugin:reviewer`, not
  the bare frontmatter name. A scoped name contains a colon, which places it on the regular-expression path as an
  unanchored regular expression, so anchor the matcher with `^` and `$` for an exact match: `^my-plugin:reviewer$`.
  [hooks › SubagentStart](https://code.claude.com/docs/en/hooks#subagentstart)
  [sub-agents › Project-level hooks for subagent events](https://code.claude.com/docs/en/sub-agents#project-level-hooks-for-subagent-events)
- In `settings.json`, hooks respond to subagent lifecycle events in the main session. Both `SubagentStart` and
  `SubagentStop` support matchers to target specific agent types by name:
  [sub-agents › Project-level hooks for subagent events](https://code.claude.com/docs/en/sub-agents#project-level-hooks-for-subagent-events)

  | Event | Matcher input | When it fires |
  | :- | :- | :- |
  | `SubagentStart` | Agent type name | When a subagent begins execution |
  | `SubagentStop` | Agent type name | When a subagent completes |

- This example runs a setup script only when the `db-agent` subagent starts, and a cleanup script when any subagent
  stops:
  [sub-agents › Project-level hooks for subagent events](https://code.claude.com/docs/en/sub-agents#project-level-hooks-for-subagent-events)

  ```json
  {
    "hooks": {
      "SubagentStart": [
        {
          "matcher": "db-agent",
          "hooks": [
            { "type": "command", "command": "./scripts/setup-db-connection.sh" }
          ]
        }
      ],
      "SubagentStop": [
        {
          "hooks": [
            { "type": "command", "command": "./scripts/cleanup-db-connection.sh" }
          ]
        }
      ]
    }
  }
  ```

### Input

- In addition to the common input fields, SubagentStart hooks receive `agent_id` with the unique identifier for the
  subagent and `agent_type` with the agent name that the matcher filters on.
  [hooks › SubagentStart input](https://code.claude.com/docs/en/hooks#subagentstart-input)

### Output

- SubagentStart hooks can't block subagent creation, but they can inject context into the subagent. In addition to the
  JSON output fields available to all hooks, you can return `additionalContext`, a string added to the subagent's
  context at the start of its conversation, before its first prompt:
  [hooks › SubagentStart input](https://code.claude.com/docs/en/hooks#subagentstart-input)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "SubagentStart",
      "additionalContext": "Follow security guidelines for this task"
    }
  }
  ```

- When the hook runs again for the same subagent, Claude Code injects the returned context only when the subagent's
  context doesn't already hold the copy from an earlier run. The copy injected at launch stays in place, leaving the
  subagent's prompt cache intact. After auto-compaction discards that copy, Claude Code injects the next run's context
  again.
  [hooks › SubagentStart input](https://code.claude.com/docs/en/hooks#subagentstart-input)

## SubagentStop

- SubagentStop runs when a Claude Code subagent has finished responding. It matches on agent type, with the same
  values as SubagentStart.
  [hooks › SubagentStop](https://code.claude.com/docs/en/hooks#subagentstop)

### Input

- In addition to the common input fields, SubagentStop hooks receive `stop_hook_active`, `agent_id`, `agent_type`,
  `agent_transcript_path`, and `last_assistant_message`. The `agent_type` field is the value used for matcher
  filtering. The `transcript_path` is the main session's transcript, while `agent_transcript_path` is the subagent's
  own transcript stored in a nested `subagents/` folder. The `last_assistant_message` field contains the text content
  of the subagent's final response, so hooks can access it without parsing the transcript file.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)
- Not every SubagentStop event comes from a subagent Claude spawned. Claude Code also runs internal agents for some of
  its own features, such as prompt suggestions and `/btw` side questions, and SubagentStop fires when one of those
  finishes too. For those events, `agent_type` is the agent name the session itself runs as, such as one set with
  `--agent` or the `agent` setting, and an empty string when the session runs without one.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)
- A `matcher` that names agent types doesn't match an empty `agent_type`. A hook whose matcher is omitted, `""`, or
  `"*"`, or is a regular expression that matches an empty string, runs for events with an empty `agent_type` too.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)
- A subagent that runs with the `SubagentHandback` tool delivers its report through that tool before it stops. The
  `last_assistant_message` field then holds the subagent's closing text, if any, which is not the delivered report.
  The report is that call's `message` input, which a `PreToolUse` or `PostToolUse` hook matched on `SubagentHandback`
  receives as `tool_input.message`.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)
- SubagentStop hooks also receive the `background_tasks` and `session_crons` arrays described under Stop input. Both
  arrays are scoped to the parent session, not the subagent.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)

### Output

- SubagentStop hooks use the same decision control format as Stop hooks, including
  `hookSpecificOutput.additionalContext` with `hookEventName` set to `"SubagentStop"`, for non-error feedback that
  keeps the subagent running. Returning `decision: "block"` with a `reason` keeps the subagent running and delivers
  `reason` to the subagent as its next instruction. A hook that blocks by exiting 2 delivers its stderr message the
  same way.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)
- To inject context into the parent session after a subagent returns, use a `PostToolUse` hook on the `Agent` tool
  instead.
  [hooks › SubagentStop input](https://code.claude.com/docs/en/hooks#subagentstop-input)

## TaskCreated

- TaskCreated runs when a task is being created via the `TaskCreate` tool. Use it to enforce naming conventions,
  require task descriptions, or prevent certain tasks from being created. In a session without the Task tools, this
  event doesn't fire.
  [hooks › TaskCreated](https://code.claude.com/docs/en/hooks#taskcreated)
- TaskCreated hooks don't support matchers and fire on every occurrence.
  [hooks › TaskCreated](https://code.claude.com/docs/en/hooks#taskcreated)

### Input

- In addition to the common input fields, TaskCreated hooks receive `task_id`, `task_subject`, and optionally
  `task_description`, `teammate_name`, and `team_name`:
  [hooks › TaskCreated input](https://code.claude.com/docs/en/hooks#taskcreated-input)

  | Field | Description |
  | :- | :- |
  | `task_id` | Identifier of the task being created |
  | `task_subject` | Title of the task |
  | `task_description` | Detailed description of the task. May be absent |
  | `teammate_name` | Name of the teammate creating the task. May be absent |
  | `team_name` | Deprecated. Session-derived team name; will be removed in a future release |
  | `agent_id` | On this event, the [common input field](https://code.claude.com/docs/en/hooks#common-input-fields) identifies the subagent or [in-process teammate](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode) creating the task. May be absent |

### Output

- A TaskCreated hook can block the creation with exit code 2 or with a JSON decision. Either way, Claude Code deletes
  the task and returns your message to Claude as the tool's error. Claude Code ignores `continue: false` from this
  event and Claude keeps working. With exit code 2, Claude Code returns the stderr text as the message. With JSON
  `{"decision": "block", "reason": "..."}`, Claude Code returns `reason` as the message.
  [hooks › TaskCreated decision control](https://code.claude.com/docs/en/hooks#taskcreated-decision-control)
- This example blocks tasks whose subjects don't follow the required format:
  [hooks › TaskCreated decision control](https://code.claude.com/docs/en/hooks#taskcreated-decision-control)

  ```bash
  #!/bin/bash
  INPUT=$(cat)
  TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

  if [[ ! "$TASK_SUBJECT" =~ ^\[TICKET-[0-9]+\] ]]; then
    echo "Task subject must start with a ticket number, e.g. '[TICKET-123] Add feature'" >&2
    exit 2
  fi

  exit 0
  ```

## TaskCompleted

- TaskCompleted runs when a task is being marked as completed. This fires in two situations: when any agent explicitly
  marks a task as completed through the TaskUpdate tool, or when an agent team teammate finishes its turn with
  in-progress tasks. Use it to enforce completion criteria like passing tests or lint checks before a task can close.
  [hooks › TaskCompleted](https://code.claude.com/docs/en/hooks#taskcompleted)
- TaskCompleted hooks don't support matchers and fire on every occurrence.
  [hooks › TaskCompleted](https://code.claude.com/docs/en/hooks#taskcompleted)

### Input

- In addition to the common input fields, TaskCompleted hooks receive `task_id`, `task_subject`, and optionally
  `task_description`, `teammate_name`, and `team_name`:
  [hooks › TaskCompleted input](https://code.claude.com/docs/en/hooks#taskcompleted-input)

  | Field | Description |
  | :- | :- |
  | `task_id` | Identifier of the task being completed |
  | `task_subject` | Title of the task |
  | `task_description` | Detailed description of the task. May be absent |
  | `teammate_name` | Name of the teammate completing the task. May be absent |
  | `team_name` | Deprecated. Session-derived team name; will be removed in a future release |
  | `agent_id` | On this event, the [common input field](https://code.claude.com/docs/en/hooks#common-input-fields) identifies the subagent or [in-process teammate](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode) completing the task. May be absent |

### Output

- TaskCompleted hooks support two ways to control task completion. With exit code 2, the task is not marked as
  completed and the stderr message is fed back to the model as feedback. With JSON
  `{"continue": false, "stopReason": "..."}`, when a teammate finishing its turn triggered the event, the teammate
  stops entirely, matching `Stop` hook behavior, and the `stopReason` is shown to the user. When the `TaskUpdate` tool
  triggered the event, Claude Code ignores `continue: false`; exit code 2 still blocks the completion.
  [hooks › TaskCompleted decision control](https://code.claude.com/docs/en/hooks#taskcompleted-decision-control)
- This example runs tests and blocks task completion if they fail:
  [hooks › TaskCompleted decision control](https://code.claude.com/docs/en/hooks#taskcompleted-decision-control)

  ```bash
  #!/bin/bash
  INPUT=$(cat)
  TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject')

  # Run the test suite
  if ! npm test 2>&1; then
    echo "Tests not passing. Fix failing tests before completing: $TASK_SUBJECT" >&2
    exit 2
  fi

  exit 0
  ```

## Stop

- Stop runs when the main Claude Code agent has finished responding. It does not run if the stoppage occurred due to a
  user interrupt. API errors fire StopFailure instead.
  [hooks › Stop](https://code.claude.com/docs/en/hooks#stop)
- `Stop` hooks fire whenever Claude finishes responding, not only at task completion.
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)
- The `/goal` command is a built-in shortcut for a session-scoped prompt-based Stop hook. Use it when you want Claude
  to keep working toward a condition without writing hook configuration.
  [hooks › Stop](https://code.claude.com/docs/en/hooks#stop)
  [goal › How evaluation works](https://code.claude.com/docs/en/goal#how-evaluation-works)

### Input

- In addition to the common input fields, Stop hooks receive `stop_hook_active`, `last_assistant_message`,
  `background_tasks`, and `session_crons`. The `stop_hook_active` field is `true` when Claude Code is already
  continuing as a result of a stop hook. Check this value or process the transcript to avoid blocking on a condition
  that will never resolve.
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
- Claude Code applies an 8-consecutive-continuation cap: after stop hooks have continued the turn eight times in a row,
  Claude Code overrides the next block and ends the turn. The count of consecutive continuations resets each time
  Claude calls a tool. `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` sets the maximum number
  of consecutive times a Stop or SubagentStop hook may block the turn from ending before Claude Code overrides it
  (default: 8). Set it to `0` to disable the cap, and raise it if your hook legitimately needs more iterations to
  resolve.
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- The `last_assistant_message` field contains the text content of Claude's final response, so hooks can access it
  without parsing the transcript file. For hooks that act on the just-completed turn, such as read-aloud or
  notification hooks, use this field rather than reading `transcript_path`: the transcript file isn't guaranteed to
  include the final message at Stop time on all versions.
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
- The `background_tasks` and `session_crons` arrays let hooks distinguish "session is done" from "session is paused
  waiting for background work to wake it back up". Both arrays are present when the task registry is reachable and are
  empty when nothing is in flight or scheduled.
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
- Each entry in `background_tasks` describes one in-flight task and uses these fields:
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)

  | Field | Description |
  | :- | :- |
  | `id` | Task identifier |
  | `type` | Friendly task-type label such as `shell`, `subagent`, `monitor`, `workflow`, `teammate`, `cloud session`, or `MCP task`. Each label identifies which Claude Code feature created the task. Falls back to the raw discriminant for unrecognized types |
  | `status` | Current task status |
  | `description` | Free-text description, capped at 1000 characters with an in-string `… [+N chars]` marker when clipped |
  | `command` | Shell command line, capped at 1000 characters. Present only for `shell` tasks |
  | `agent_type` | Subagent type name. Present only for `subagent` tasks |
  | `server` | MCP server name. Present only for `monitor` and `MCP task` tasks |
  | `tool` | MCP tool name. Present only for `monitor` and `MCP task` tasks |
  | `name` | Workflow name. Present only for `workflow` tasks |

- Each entry in `session_crons` describes one session-scoped scheduled wakeup, sourced from `CronCreate`,
  `ScheduleWakeup`, and `/loop`:
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)

  | Field | Description |
  | :- | :- |
  | `id` | Cron task identifier |
  | `schedule` | Cron expression, for example `0 9 * * 1-5` |
  | `recurring` | `false` for one-shot wakeups whose schedule encodes a single fire time, `true` for tasks that re-fire on every match |
  | `prompt` | Prompt submitted when the cron fires, capped at 1000 characters with the same `… [+N chars]` marker |

### Output

- `Stop` and `SubagentStop` hooks can control whether Claude continues. In addition to the JSON output fields
  available to all hooks, your hook script can return these event-specific fields:
  [hooks › Stop decision control](https://code.claude.com/docs/en/hooks#stop-decision-control)

  | Field | Description |
  | :- | :- |
  | `decision` | `"block"` prevents Claude from stopping. Omit to allow Claude to stop |
  | `reason` | Required when `decision` is `"block"`. Tells Claude why it should continue |
  | `hookSpecificOutput.additionalContext` | Non-error feedback for Claude. The conversation continues so Claude can act on it, but unlike `decision: "block"` it is shown in the transcript as hook feedback rather than a hook error |

  ```json
  {
    "decision": "block",
    "reason": "Must be provided when Claude is blocked from stopping"
  }
  ```

- A hook that blocks by exiting 2 routes the same way as `reason`: Claude receives the stderr message as the
  explanation for why it should continue.
  [hooks › Stop decision control](https://code.claude.com/docs/en/hooks#stop-decision-control)
- Use `additionalContext` when the hook is working as designed and giving Claude guidance, such as "run the test suite
  before finishing". It keeps the conversation going through the same loop protections as `decision: "block"`, namely
  the `stop_hook_active` input and the 8-consecutive-continuation cap, but the transcript labels it
  `Stop hook feedback` and no hook error notification is shown:
  [hooks › Stop decision control](https://code.claude.com/docs/en/hooks#stop-decision-control)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "Stop",
      "additionalContext": "Please run the test suite before finishing"
    }
  }
  ```

## StopFailure

- StopFailure runs instead of Stop when the turn ends due to an API error. Claude Code ignores the hook's output and
  exit code, apart from `terminalSequence`. Use it to log failures, send alerts, or take recovery actions when Claude
  can't complete a response due to rate limits, authentication problems, or other API errors.
  [hooks › StopFailure](https://code.claude.com/docs/en/hooks#stopfailure)
- StopFailure hooks have no decision control. They run for notification and logging purposes only.
  [hooks › StopFailure input](https://code.claude.com/docs/en/hooks#stopfailure-input)

### Input

- In addition to the common input fields, StopFailure hooks receive `error`, optional `error_details`, and optional
  `last_assistant_message`. The `error` field identifies the error type and is used for matcher filtering.
  [hooks › StopFailure input](https://code.claude.com/docs/en/hooks#stopfailure-input)

  | Field | Description |
  | :- | :- |
  | `error` | Error type: `rate_limit`, `overloaded`, `authentication_failed`, `oauth_org_not_allowed`, `account_on_hold`, `billing_error`, `invalid_request`, `model_not_found`, `server_error`, `max_output_tokens`, `cloud_credential_error`, or `unknown` |
  | `error_details` | Additional details about the error, when available |
  | `last_assistant_message` | The rendered error text shown in the conversation. Unlike `Stop` and `SubagentStop`, where this field holds Claude's conversational output, for `StopFailure` it contains the API error string itself, such as `"API Error: Rate limit reached"` |

## TeammateIdle

- TeammateIdle runs when an agent team teammate is about to go idle after finishing its turn. Use it to enforce
  quality gates before a teammate stops working, such as requiring passing lint checks or verifying that output files
  exist. TeammateIdle hooks don't support matchers and fire on every occurrence.
  [hooks › TeammateIdle](https://code.claude.com/docs/en/hooks#teammateidle)

### Input

- In addition to the common input fields, TeammateIdle hooks receive `teammate_name` and `team_name`:
  [hooks › TeammateIdle input](https://code.claude.com/docs/en/hooks#teammateidle-input)

  | Field | Description |
  | :- | :- |
  | `teammate_name` | Name of the teammate that is about to go idle |
  | `team_name` | Deprecated. Session-derived team name; will be removed in a future release |
  | `agent_id` | On this event, the [common input field](https://code.claude.com/docs/en/hooks#common-input-fields) identifies the [in-process teammate](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode) that is about to go idle. May be absent |

### Output

- TeammateIdle hooks support two ways to control teammate behavior. With exit code 2, the teammate receives the
  stderr message as feedback and continues working instead of going idle. With JSON
  `{"continue": false, "stopReason": "..."}`, the teammate stops entirely, matching `Stop` hook behavior, and the
  `stopReason` is shown to the user.
  [hooks › TeammateIdle decision control](https://code.claude.com/docs/en/hooks#teammateidle-decision-control)
- This example checks that a build artifact exists before allowing a teammate to go idle:
  [hooks › TeammateIdle decision control](https://code.claude.com/docs/en/hooks#teammateidle-decision-control)

  ```bash
  #!/bin/bash

  if [ ! -f "./dist/output.js" ]; then
    echo "Build artifact missing. Run the build before stopping." >&2
    exit 2
  fi

  exit 0
  ```

## Notification

- Notification runs when Claude Code sends notifications. It matches on notification type. Omit the matcher to run
  hooks for all notification types.
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)
- You receive these hook events even with desktop notifications turned off: the `preferredNotifChannel` setting,
  including `notifications_disabled`, changes only how you're alerted, not whether your hook runs.
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)

### Matcher

- The matcher values are the notification types:
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)

  | Matcher | When it fires |
  | :- | :- |
  | `permission_prompt` | Claude needs you to approve a tool use or a sandboxed command's [network request](https://code.claude.com/docs/en/sandboxing#network-isolation), and the prompt has waited about six seconds |
  | `idle_prompt` | Claude finished responding about 60 seconds ago and you haven't typed since |
  | `auth_success` | Authentication completes |
  | `elicitation_dialog` | An MCP server opens an elicitation form and you haven't typed for about six seconds |
  | `elicitation_url_dialog` | An MCP server asks you to open a browser URL and you haven't typed for about six seconds |
  | `elicitation_complete` | An MCP server reports that a [URL-mode elicitation](https://code.claude.com/docs/en/hooks#elicitation-input) is complete |
  | `elicitation_response` | An MCP elicitation response is sent back to the server |
  | `agent_needs_input` | A background session starts waiting on your input while [agent view](https://code.claude.com/docs/en/agent-view) is open in a terminal. Also fires when a terminal session shows you an [agent team teammate's terminal setup question](https://code.claude.com/docs/en/agent-teams#choose-a-display-mode) or auto mode's notice about [classifier request charges](https://code.claude.com/docs/en/auto-mode-classifier-billing) and you haven't typed for about six seconds |
  | `agent_completed` | A background session finishes or fails. Fires only while [agent view](https://code.claude.com/docs/en/agent-view) is open in a terminal |
  | `quota_auto_resume_fired` | Claude Code continues your task after a claude.ai usage limit paused it: at the reset, or sooner when something you do in Claude Code during the wait, such as adding usage credits, upgrading your plan, or switching models, makes usage available again, with the [model-setting exception](https://code.claude.com/docs/en/interactive-mode#wait-for-a-usage-limit-to-reset) |
  | `quota_auto_resume_stale` | A claude.ai usage limit reset while your computer slept for more than about 30 minutes. Claude Code waits for you to press `Enter` instead of continuing. After a shorter sleep it continues and fires `quota_auto_resume_fired` instead |
  | `quota_auto_resume_disabled` | Claude Code ends its wait for a claude.ai usage limit without continuing your task: [`autoContinueAtUsageLimit`](https://code.claude.com/docs/en/settings-reference#autocontinueatusagelimit) turned off or the reset moved more than 24 hours away during a wait Claude Code started on its own, the continued task kept hitting the limit, or the continuation was blocked before it reached the model. Doesn't fire when you press `Esc` or `Ctrl+C`, or pick **Don't continue automatically** |
  | `plugin_notification` | A [mod](https://code.claude.com/docs/en/plugins/mods/api#show-something-without-starting-a-turn) raises a notification with `$.ui.notify`. The hook's `title` is the mod's name unless the mod set one |

- The `permission_prompt`, `idle_prompt`, `elicitation_dialog`, and `elicitation_url_dialog` types share their timing
  with desktop notifications, so in terminal sessions you only see them when you appear to be away from the terminal:
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)
  - Expect `permission_prompt` once you haven't typed for about six seconds. The timer starts when the permission
    prompt appears, and each keystroke defers it. To run a hook immediately when Claude asks for permission to use a
    tool, use PermissionRequest instead.
  - Expect `idle_prompt` about 60 seconds after Claude finishes responding, and only if you haven't typed since and no
    background agent, such as a background subagent, is still running. Claude Code doesn't send `idle_prompt` while it
    waits for a claude.ai usage limit to reset. When the wait ends on its own, one of the `quota_auto_resume_*` types
    fires instead.
  - Expect `elicitation_dialog` for an elicitation form, or `elicitation_url_dialog` for a browser URL request, once
    you haven't typed for about six seconds. Both share the same six-second gate as `permission_prompt`: the timer
    starts when the dialog appears, and each keystroke defers it.
- A permission request or elicitation that arrives while another dialog is on screen keeps the same six-second gate,
  timed from when the request arrives. Its notification can reach you while the request still waits behind the open
  dialog.
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)
- Claude Code times `permission_prompt` differently in sessions where it sends permission requests to the Agent SDK's
  `canUseTool` callback, which is how Claude Desktop and the VS Code extension host Claude Code. Expect
  `permission_prompt` about six seconds after Claude asks for permission; Claude Code doesn't defer it while you type.
  If you or a PermissionRequest hook answer sooner, Claude Code doesn't run `permission_prompt`.
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)
- Set `CLAUDE_CODE_DISABLE_PERMISSION_PROMPT_NOTIFY_HOOKS` to `1` to turn `permission_prompt` off in those
  `canUseTool` sessions.
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)
- While agent view is open, Claude Code notifies when a local background session starts needing your input, finishes
  or fails, and the notification fires the `Notification` hook with the `agent_needs_input` or `agent_completed` type.
  Sessions that run on a schedule, such as `/loop` sessions, notify only when they need your input.
  [agent-view › Read session state](https://code.claude.com/docs/en/agent-view#read-session-state)
- When a mod's `$.ui.notify` call reaches a running session, the user's Notification hooks run with the type
  `plugin_notification`. They run even when the call's answer is `disabled` (the user set `preferredNotifChannel` to
  `notifications_disabled`), and in a session with no terminal, where the answer is `no-surface`. No hook runs for a
  call made before the session starts or while Claude Code is exiting. The hook the mod called `$.ui.notify` from is
  left out of that run, so a `classic.Notification` hook that notifies isn't called again for its own notification.
  [plugins/mods/api › Show something without starting a turn](https://code.claude.com/docs/en/plugins/mods/api#show-something-without-starting-a-turn)

### Input

- In addition to the common input fields, Notification hooks receive `message` with the notification text, an optional
  `title`, and `notification_type` indicating which type fired.
  [hooks › Notification input](https://code.claude.com/docs/en/hooks#notification-input)

### Output

- Notification hooks can't block or modify notifications. Claude Code discards their `systemMessage` and `continue`
  fields but still emits `terminalSequence`, which is what the desktop notification example relies on. Notification
  hooks are intended for side effects such as forwarding the notification to an external service.
  [hooks › Notification input](https://code.claude.com/docs/en/hooks#notification-input)

### Examples

- Use separate matchers to run different handlers depending on the notification type. This configuration triggers a
  permission-specific alert script when Claude needs permission approval and a different notification when Claude has
  been idle:
  [hooks › Notification](https://code.claude.com/docs/en/hooks#notification)

  ```json
  {
    "hooks": {
      "Notification": [
        {
          "matcher": "permission_prompt",
          "hooks": [
            {
              "type": "command",
              "command": "/path/to/permission-alert.sh"
            }
          ]
        },
        {
          "matcher": "idle_prompt",
          "hooks": [
            {
              "type": "command",
              "command": "/path/to/idle-notification.sh"
            }
          ]
        }
      ]
    }
  }
  ```

- To get a desktop notification when Claude needs your input, add one of these to `~/.claude/settings.json`. Each uses
  the platform's native notification command, and the empty `matcher` fires on all notification types:
  [hooks-guide › Get notified when Claude needs input](https://code.claude.com/docs/en/hooks-guide#get-notified-when-claude-needs-input)

  ```json
  {
    "hooks": {
      "Notification": [
        {
          "matcher": "",
          "hooks": [
            {
              "type": "command",
              "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
            }
          ]
        }
      ]
    }
  }
  ```

  On Linux, the command is `notify-send 'Claude Code' 'Claude Code needs your attention'`. On Windows, it is:

  ```json
  "command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude Code needs your attention', 'Claude Code')\""
  ```

- If no macOS notification appears: `osascript` routes notifications through the built-in Script Editor app. If Script
  Editor doesn't have notification permission, the command fails silently, and macOS won't prompt you to grant it. Run
  `osascript -e 'display notification "test"'` in Terminal once to make Script Editor appear in your notification
  settings, then open System Settings > Notifications, find Script Editor and turn on Allow Notifications.
  [hooks-guide › Get notified when Claude needs input](https://code.claude.com/docs/en/hooks-guide#get-notified-when-claude-needs-input)
- If no Linux notification appears: `notify-send` needs a desktop notification daemon, which headless servers, SSH
  sessions, and most containers don't have. If the command isn't found, install the `libnotify-bin` package on Debian
  and Ubuntu, or your distribution's equivalent.
  [hooks-guide › Get notified when Claude needs input](https://code.claude.com/docs/en/hooks-guide#get-notified-when-claude-needs-input)
- If no Windows dialog appears: the command opens a dialog box rather than a notification in the corner of your
  screen, so the dialog can open behind your terminal window. If you run Claude Code inside WSL, `powershell.exe` must
  be available on your `PATH` through Windows interop.
  [hooks-guide › Get notified when Claude needs input](https://code.claude.com/docs/en/hooks-guide#get-notified-when-claude-needs-input)
- Type `/hooks` at the Claude Code prompt and confirm the hook appears under `Notification`.
  [hooks-guide › Get notified when Claude needs input](https://code.claude.com/docs/en/hooks-guide#get-notified-when-claude-needs-input)
- In any terminal you can configure a Notification hook to play a sound or run a custom command when Claude needs your
  attention. Hooks run alongside the built-in notification rather than replacing it, so terminals that do not receive
  a desktop notification, such as Warp or the VS Code integrated terminal, can use a hook or set
  `preferredNotifChannel` to `"terminal_bell"` instead. This plays a system sound on macOS:
  [terminal-config › Play a sound with a Notification hook](https://code.claude.com/docs/en/terminal-config#play-a-sound-with-a-notification-hook)

  ```json
  {
    "hooks": {
      "Notification": [
        {
          "hooks": [{ "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff" }]
        }
      ]
    }
  }
  ```

## ConfigChange

- ConfigChange runs when a configuration file changes during a session, for example when an external process or
  editor modifies it. Use it to audit settings changes, enforce security policies, log changes for compliance, or
  block unauthorized modifications to configuration files.
  [hooks › ConfigChange](https://code.claude.com/docs/en/hooks#configchange)
  [hooks-guide › Audit configuration changes](https://code.claude.com/docs/en/hooks-guide#audit-configuration-changes)
- Claude Code runs ConfigChange hooks when a settings file or a managed policy file changes, for each settings-file
  change it detects. For managed policy, it runs them only when `managed-settings.json` or a file in
  `managed-settings.d/` changes. It applies server-managed settings and changes to macOS managed preferences or Windows
  registry policy without running them, so it doesn't run them for managed settings that arrive from MDM or the
  claude.ai console, or when server-managed settings arrive or refresh. On WSL with `wslInheritsWindowsSettings`, it
  also applies a changed Windows-side managed settings file on its policy poll without running them. To log edits to
  local settings files, including `managed-settings.json`, use ConfigChange hooks.
  [hooks › ConfigChange](https://code.claude.com/docs/en/hooks#configchange)
  [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect)
  [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)

### Matcher

- The matcher filters on the configuration source:
  [hooks › ConfigChange](https://code.claude.com/docs/en/hooks#configchange)

  | Matcher | When it fires |
  | :- | :- |
  | `user_settings` | `~/.claude/settings.json` changes |
  | `project_settings` | `.claude/settings.json` changes |
  | `local_settings` | `.claude/settings.local.json` changes |
  | `policy_settings` | `managed-settings.json` or a file in `managed-settings.d/` changes |

### Input

- In addition to the common input fields, ConfigChange hooks receive `source` and optionally `file_path`. The `source`
  field indicates which configuration type changed, and `file_path` provides the path to the specific file that was
  modified.
  [hooks › ConfigChange input](https://code.claude.com/docs/en/hooks#configchange-input)

### Output

- Use exit code 2 or a JSON `decision` to prevent the change:
  [hooks › ConfigChange decision control](https://code.claude.com/docs/en/hooks#configchange-decision-control)

  | Field | Description |
  | :- | :- |
  | `decision` | `"block"` prevents the configuration change from being applied. Omit to allow the change |
  | `reason` | Accepted but never shown |

  ```json
  {
    "decision": "block",
    "reason": "Configuration changes to project settings require admin approval"
  }
  ```

- `policy_settings` changes can't be blocked. Hooks still fire for `policy_settings` sources when a managed settings
  file on the machine changes, so you can use them to log those edits, but any blocking decision is ignored. This
  ensures enterprise-managed settings always take effect.
  [hooks › ConfigChange decision control](https://code.claude.com/docs/en/hooks#configchange-decision-control)
  [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)
- Claude Code acts on the blocking decision from a ConfigChange hook's JSON output and discards `systemMessage` and
  `continue`. A blocked change surfaces no message to you or to Claude, whether you block with `reason` or with stderr
  on exit 2. Claude Code only writes a line to the debug log.
  [hooks › ConfigChange decision control](https://code.claude.com/docs/en/hooks#configchange-decision-control)
- This example appends each change to an audit log. Add it to `~/.claude/settings.json`:
  [hooks-guide › Audit configuration changes](https://code.claude.com/docs/en/hooks-guide#audit-configuration-changes)

  ```json
  {
    "hooks": {
      "ConfigChange": [
        {
          "matcher": "",
          "hooks": [
            {
              "type": "command",
              "command": "jq -c '{timestamp: now | todate, source: .source, file: .file_path}' >> ~/claude-config-audit.log"
            }
          ]
        }
      ]
    }
  }
  ```

- To confirm the hook records changes, edit a settings file in another editor while a session is running, then open
  `~/claude-config-audit.log`: the hook appends one JSON line per change with the timestamp, source, and file path.
  [hooks-guide › Audit configuration changes](https://code.claude.com/docs/en/hooks-guide#audit-configuration-changes)

## CwdChanged

- CwdChanged runs when a shell command in the main conversation changes the working directory, for example when
  Claude executes a `cd` command. Use it to react to directory changes: reload environment variables, activate
  project-specific toolchains, or run setup scripts automatically. It pairs with FileChanged for tools like direnv
  that manage per-directory environment.
  [hooks › CwdChanged](https://code.claude.com/docs/en/hooks#cwdchanged)
- CwdChanged hooks have access to `CLAUDE_ENV_FILE`. If your hook writes variables to that file, they persist into
  subsequent Bash commands until the next CwdChanged event, when Claude Code clears them.
  [hooks › CwdChanged](https://code.claude.com/docs/en/hooks#cwdchanged)
- CwdChanged doesn't support matchers and fires on every occurrence.
  [hooks › CwdChanged](https://code.claude.com/docs/en/hooks#cwdchanged)
- Claude's Bash tool doesn't pick up the environment changes that tools like direnv make in your shell on their own.
  Pairing a `SessionStart` hook with a `CwdChanged` hook fixes this: `SessionStart` loads the variables for the
  directory you launch in, and `CwdChanged` reloads them each time Claude changes directory. Both write to
  `CLAUDE_ENV_FILE`, which Claude Code runs as a script preamble before each Bash command. Add this to
  `~/.claude/settings.json`:
  [hooks-guide › Reload environment when directory or files change](https://code.claude.com/docs/en/hooks-guide#reload-environment-when-directory-or-files-change)

  ```json
  {
    "hooks": {
      "SessionStart": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
            }
          ]
        }
      ],
      "CwdChanged": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
            }
          ]
        }
      ]
    }
  }
  ```

- Run `direnv allow` once in each directory that has an `.envrc` so direnv is permitted to load it. If you use devbox
  or nix instead of direnv, the same pattern works with `devbox shellenv` or `devbox global shellenv` in place of
  `direnv export bash`.
  [hooks-guide › Reload environment when directory or files change](https://code.claude.com/docs/en/hooks-guide#reload-environment-when-directory-or-files-change)

### Input

- In addition to the common input fields, CwdChanged hooks receive `old_cwd` and `new_cwd`.
  [hooks › CwdChanged input](https://code.claude.com/docs/en/hooks#cwdchanged-input)

### Output

- In addition to the JSON output fields available to all hooks, CwdChanged hooks can return `watchPaths` to dynamically
  set which file paths FileChanged watches:
  [hooks › CwdChanged output](https://code.claude.com/docs/en/hooks#cwdchanged-output)

  | Field | Description |
  | :- | :- |
  | `watchPaths` | Array of absolute paths. Replaces the current dynamic watch list. Paths from your `matcher` configuration are always watched. Returning an empty array clears the dynamic list, which is typical when entering a new directory |

- CwdChanged hooks have no decision control. They can't block the directory change. Claude Code reads `watchPaths` and
  `systemMessage` from their JSON output and discards `continue`. In interactive sessions, it shows the
  `systemMessage` as a brief terminal notification. The message doesn't reach the SDK message stream.
  [hooks › CwdChanged output](https://code.claude.com/docs/en/hooks#cwdchanged-output)

## DirectoryAdded

- DirectoryAdded runs after you add a working directory mid-session with the `/add-dir` command, or after an SDK
  client adds one with the `register_repo_root` control request. Use it to prepare a newly added repository, for
  example by installing its dependencies.
  [hooks › DirectoryAdded](https://code.claude.com/docs/en/hooks#directoryadded)
- Claude Code doesn't fire this event when you pass a directory with the `--add-dir` startup flag (SessionStart covers
  those directories), when you add a directory on the `/permissions` Workspace tab, or when you add a directory that
  is already a working directory or inside one.
  [hooks › DirectoryAdded](https://code.claude.com/docs/en/hooks#directoryadded)
- Claude Code fires DirectoryAdded after refreshing sandbox and permission state, so sandboxed tools already see the
  new directory when your hook runs. Hook commands themselves run unsandboxed.
  [hooks › DirectoryAdded](https://code.claude.com/docs/en/hooks#directoryadded)
- Claude Code doesn't wait for the hook: the add completes immediately, and the hook runs in the background with the
  600-second default timeout.
  [hooks › DirectoryAdded](https://code.claude.com/docs/en/hooks#directoryadded)

### Matcher

- The matcher filters on how the directory was added:
  [hooks › DirectoryAdded](https://code.claude.com/docs/en/hooks#directoryadded)

  | Matcher | When it fires |
  | :- | :- |
  | `slash_command` | You add a directory with `/add-dir` |
  | `register_repo_root` | An SDK client adds a directory with the `register_repo_root` control request |

### Input

- In addition to the common input fields, DirectoryAdded hooks receive `directory` and `source`:
  [hooks › DirectoryAdded input](https://code.claude.com/docs/en/hooks#directoryadded-input)

  | Field | Description |
  | :- | :- |
  | `directory` | Absolute path of the directory that was added |
  | `source` | How the directory was added, `"slash_command"` for `/add-dir` or `"register_repo_root"` for the SDK control request |

### Output

- DirectoryAdded hooks have no decision control. They can't block the add, which has already completed when the hook
  runs. Claude Code discards the `continue` field from their JSON output and surfaces the rest differently per source:
  [hooks › DirectoryAdded input](https://code.claude.com/docs/en/hooks#directoryadded-input)
  - `slash_command`: Claude Code delivers the hook's `systemMessage` to Claude as context on the next conversation
    turn, rather than showing it to you. A count of failed hooks appears in the transcript. Full failure output goes
    to the debug log
  - `register_repo_root`: Claude Code writes `systemMessage` output and failure output to the debug log only

## FileChanged

- FileChanged runs when a watched file changes on disk. Claude Code detects changes with a filesystem watcher, not by
  inspecting tool calls, so it runs the hook no matter what changed the file: an `Edit` or `Write` tool call, a script
  Claude runs with `Bash`, or a process outside Claude Code entirely. A common use is reloading environment variables
  when project configuration files change.
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)
- FileChanged hooks have access to `CLAUDE_ENV_FILE`. Variables written to that file persist into subsequent Bash
  commands until the next CwdChanged event, when Claude Code clears them.
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)

### Matcher

- The `matcher` for this event serves two roles:
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)
  - **Build the watch list**: the value is split on `|` and each segment is registered as a literal filename in the
    working directory, so `".envrc|.env"` watches exactly those two files. Regex patterns are not useful here: a value
    like `^\.env` would watch a file literally named `^\.env`.
  - **Filter which hooks run**: when a watched file changes, the same value filters which hook groups run using the
    standard matcher rules against the changed file's basename.
- To watch files you can't name up front, return `watchPaths` from a hook to update the watch list dynamically.
  Claude Code starts the watcher only when something names a file to watch, so seed the list with a FileChanged group
  whose matcher names at least one file, or with a SessionStart or CwdChanged hook that returns `watchPaths`. The
  matcher still filters which hook groups run when a watched file changes, so give the group that handles dynamic
  paths an omitted matcher, which matches every watched file and adds nothing to the watch list. A `"*"` matcher also
  matches every file, but Claude Code registers it in the watch list like any other value, as a literal file named
  `*`.
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)
- To react to specific files instead of every directory change, use `FileChanged` with a `matcher` listing the
  filenames to watch, separated by `|`. This example watches `.envrc` and `.env` in the working directory and reloads
  the environment:
  [hooks-guide › Reload environment when directory or files change](https://code.claude.com/docs/en/hooks-guide#reload-environment-when-directory-or-files-change)

  ```json
  {
    "hooks": {
      "FileChanged": [
        {
          "matcher": ".envrc|.env",
          "hooks": [
            {
              "type": "command",
              "command": "direnv export bash > \"$CLAUDE_ENV_FILE\""
            }
          ]
        }
      ]
    }
  }
  ```

- This example normalizes line endings in `data.csv` after any change, including a `Bash` command or an external
  script rewriting the file:
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)

  ```json
  {
    "hooks": {
      "FileChanged": [
        {
          "matcher": "data.csv",
          "hooks": [
            {
              "type": "command",
              "command": "/path/to/normalize-line-endings.sh"
            }
          ]
        }
      ]
    }
  }
  ```

- The hook reads the changed file's absolute path from the `file_path` field of the JSON input on stdin. Its `grep`
  guard tests for the same thing `perl` removes, a CR at the end of a line, so the run after a normalization exits
  without touching the file. A looser guard loops forever, because `perl -i` rewrites the file even when it
  substitutes nothing and Claude Code runs the hook again after every rewrite. Save this script at
  `/path/to/normalize-line-endings.sh` and make it executable:
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)

  ```bash
  #!/bin/bash
  FILE=$(jq -r .file_path)
  if grep -q $'\r$' "$FILE"; then
    perl -pi -e 's/\r$//' "$FILE"
  fi
  ```

- To confirm the hook works, ask Claude to append a CRLF line to `data.csv` with a `Bash` command. Claude Code runs the
  hook and the file ends up with LF endings.
  [hooks › FileChanged](https://code.claude.com/docs/en/hooks#filechanged)

### Input

- In addition to the common input fields, FileChanged hooks receive `file_path` and `event`:
  [hooks › FileChanged input](https://code.claude.com/docs/en/hooks#filechanged-input)

  | Field | Description |
  | :- | :- |
  | `file_path` | Absolute path to the file that changed |
  | `event` | What happened: `"change"` for a modified file, `"add"` for a created file, or `"unlink"` for a deleted file |

### Output

- In addition to the JSON output fields available to all hooks, FileChanged hooks can return `watchPaths` to
  dynamically update which file paths are watched:
  [hooks › FileChanged output](https://code.claude.com/docs/en/hooks#filechanged-output)

  | Field | Description |
  | :- | :- |
  | `watchPaths` | Array of absolute paths. Replaces the current dynamic watch list. Paths from your `matcher` configuration are always watched. Use this when your hook script discovers additional files to watch based on the changed file |

- FileChanged hooks have no decision control. They can't block the file change from occurring. Claude Code reads
  `watchPaths` and `systemMessage` from their JSON output and discards `continue`. In interactive sessions, it shows
  the `systemMessage` as a brief terminal notification. The message doesn't reach the SDK message stream.
  [hooks › FileChanged output](https://code.claude.com/docs/en/hooks#filechanged-output)

## WorktreeCreate

- WorktreeCreate runs when Claude Code creates a worktree in cases such as these:
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
  - You start a session with `claude --worktree`
  - Claude creates a worktree during a session and switches into it with the
    [`EnterWorktree`](https://code.claude.com/docs/en/tools-reference) tool
  - A [subagent uses `isolation: "worktree"`](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
  - A [workflow](https://code.claude.com/docs/en/workflows#migrate-many-files-in-parallel) runs an agent in its own
    worktree
  - Claude Code isolates a [background session](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)
    in its own worktree
  - [`claude remote-control`](https://code.claude.com/docs/en/remote-control#start-a-remote-control-session) in
    `worktree` mode starts a session in its own worktree
- A WorktreeCreate hook doesn't run for a worktree Claude adds through Bash, and a plugin's hook doesn't run for the
  one created when you launch with `--worktree` and [`--tmux`](https://code.claude.com/docs/en/cli-reference#cli-flags):
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
  - **`git worktree add` through Bash**: to inspect or block that command, add a `PreToolUse` hook with the `Bash`
    matcher.
  - **`--worktree` with `--tmux`**: Claude Code creates the worktree before it loads plugins, so a WorktreeCreate hook
    from a plugin doesn't run. To have your hook run with both flags, define it in a settings file instead.
- By default Claude Code creates the isolated working copy with `git worktree`. Configuring a WorktreeCreate hook
  replaces that default git behavior, letting you use a different version control system like SVN, Perforce, or
  Mercurial.
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
  [worktrees › Non-git version control](https://code.claude.com/docs/en/worktrees#non-git-version-control)
- Because the hook replaces the default behavior entirely, `.worktreeinclude` is not processed. If you need to copy
  local configuration files like `.env` into the new worktree, do it inside your hook script.
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
  [worktrees › Copy gitignored files into worktrees](https://code.claude.com/docs/en/worktrees#copy-gitignored-files-into-worktrees)
- The hook must return the path to the created worktree directory. Claude Code uses this path as the working directory
  for the isolated session.
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
- Claude Code acts on the hook's success and the returned path, and discards `systemMessage` and `continue`.
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)
- A `WorktreeCreate` hook also lets you run `/batch` outside a git repository. Each `/batch` subagent then publishes
  its change with your project's version-control commands and, when it can't open a pull request, reports what it
  published instead.
  [worktrees › Non-git version control](https://code.claude.com/docs/en/worktrees#non-git-version-control)
- Pair a WorktreeCreate hook with a `WorktreeRemove` hook to clean up when the session ends.
  [worktrees › Non-git version control](https://code.claude.com/docs/en/worktrees#non-git-version-control)
- For a background session, a working directory that isn't a git repository with no `WorktreeCreate` hook configured
  has no worktree isolation: Claude skips the worktree and sessions write to the working directory directly, and
  aren't isolated from each other. If you use a different version control system, configure a `WorktreeCreate` hook
  and Claude isolates edits the same way it does for git.
  [agent-view › How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)
- For a background session, when a `WorktreeCreate` hook fails in a directory that isn't a git repository, Claude
  skips isolation for that directory and edits the working directory in place. Inside a git repository, a session that
  Claude moves into a worktree before editing can't use the `Edit`, `Write`, or `NotebookEdit`
  tools on the shared checkout until that move happens.
  [agent-view › How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)
- For the copy that `/fork` makes of a session, Claude Code instructs it to create a worktree of its own before making
  code changes, except when the copy edits in place. Outside a git repository, only a copy moved out of a
  hook-created worktree gets the instruction; with no `WorktreeCreate` hook, the copy edits in place.
  [agent-view › Where the copy runs](https://code.claude.com/docs/en/agent-view#copy-the-session-with-/fork)
- A worktree without git metadata, such as one a `WorktreeCreate` hook created, can pass the check Claude Code runs
  before returning a resumed session to its worktree, but launched from inside a worktree without git metadata, a
  resume declines to re-enter it, so launch from the main checkout. A worktree created by a `WorktreeCreate` hook
  keeps its transcript at the launch directory.
  [worktrees › Resume a worktree session](https://code.claude.com/docs/en/worktrees#resume-a-worktree-session)
- Claude Code writes a marker into the git metadata of every worktree it creates with git, and the periodic sweep that
  removes old subagent and background-session worktrees keeps any worktree without one, including a worktree a
  `WorktreeCreate` hook created.
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)
- This example creates an SVN working copy and prints the path for Claude Code to use. Replace the repository URL with
  your own. The hook reads the worktree `name` from the JSON input on stdin, checks out a fresh copy into a new
  directory, and prints the directory path. The `echo` on the last line is what Claude Code reads as the worktree
  path. Redirect any other output to stderr so it doesn't interfere with the path:
  [hooks › WorktreeCreate](https://code.claude.com/docs/en/hooks#worktreecreate)

  ```json
  {
    "hooks": {
      "WorktreeCreate": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "bash -c 'NAME=$(jq -r .name); DIR=\"$HOME/.claude/worktrees/$NAME\"; svn checkout https://svn.example.com/repo/trunk \"$DIR\" >&2 && echo \"$DIR\"'"
            }
          ]
        }
      ]
    }
  }
  ```

### Input

- In addition to the common input fields, WorktreeCreate hooks receive the `name` field. This is a slug identifier for
  the new worktree, either specified by the user or auto-generated, for example `bold-oak-a3f2`.
  [hooks › WorktreeCreate input](https://code.claude.com/docs/en/hooks#worktreecreate-input)

### Output

- WorktreeCreate hooks don't use the standard allow/block decision model. Instead, the hook's success or failure
  determines the outcome. The hook must return the path to the created worktree directory:
  [hooks › WorktreeCreate output](https://code.claude.com/docs/en/hooks#worktreecreate-output)
  - **Command hooks** (`type: "command"`): print the path as the last non-empty line of stdout. Claude Code strips ANSI
    escape codes before reading that line, so shell startup banners printed before your `echo` are ignored. Redirect
    any other hook output to stderr.
  - **HTTP hooks** (`type: "http"`): return
    `{ "hookSpecificOutput": { "hookEventName": "WorktreeCreate", "worktreePath": "/absolute/path" } }` in the
    response body.
- If the hook fails or produces no path, worktree creation fails with an error.
  [hooks › WorktreeCreate output](https://code.claude.com/docs/en/hooks#worktreecreate-output)
- Claude Code resolves a relative path against the directory the hook ran in, collapsing any `.` or `..` segments in
  it. If the resulting path isn't a directory Claude Code can enter, the session prints an error naming the path and
  exits with code 1.
  [hooks › WorktreeCreate output](https://code.claude.com/docs/en/hooks#worktreecreate-output)
- Claude Code refuses an absolute path that contains `.` or `..` segments, and any path that passes through a symlink
  below the repository root. The error names the rejected component. A symlink committed to the repository could
  redirect the worktree outside it. Return a normalized path that doesn't pass through a symlink inside the
  repository.
  [hooks › WorktreeCreate output](https://code.claude.com/docs/en/hooks#worktreecreate-output)

## WorktreeRemove

- WorktreeRemove runs when Claude Code cleans up a worktree that your
  [`WorktreeCreate`](https://code.claude.com/docs/en/hooks#worktreecreate) hook created. The event fires when:
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
  - You exit an interactive [worktree session](https://code.claude.com/docs/en/worktrees#start-claude-in-a-worktree)
    and choose to remove the worktree when Claude Code prompts you
  - You exit an interactive worktree session you haven't
    [named](https://code.claude.com/docs/en/sessions#name-your-sessions), Claude Code finds no changed or untracked
    files, and it removes the worktree without prompting you
  - You delete a [background session](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes)
    that runs in the worktree
  - You ask Claude to exit and remove the worktree during a session, and Claude removes it with the
    [`ExitWorktree`](https://code.claude.com/docs/en/tools-reference) tool
  - A session that [`claude remote-control`](https://code.claude.com/docs/en/remote-control#start-a-remote-control-session)
    started in `worktree` mode ends without crashing, and Claude Code finds no changed or untracked files and no new
    commits in its worktree
  - You stop `claude remote-control` while sessions it started in `worktree` mode are still running, and Claude Code
    finds no changed or untracked files and no new commits in their worktrees
- When a subagent or a workflow agent finishes, Claude Code keeps the worktree your WorktreeCreate hook made for it and
  doesn't run your WorktreeRemove hook. Remove those worktrees yourself when the work is done.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- Claude Code doesn't prompt you before your hook runs for an `ExitWorktree` call or a `claude remote-control`
  cleanup. `ExitWorktree` refuses to remove a hook-created worktree unless the call passes
  [`discard_changes: true`](https://code.claude.com/docs/en/agent-sdk/typescript#exitworktree), which makes your hook
  the last check on that route.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- Claude Code uses git to look for changed or untracked files, so it finds none in a worktree that isn't a git
  checkout or inside one, even when the directory holds uncommitted work. Check for that work in your WorktreeRemove
  hook before it deletes anything.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- For git-based worktrees, Claude Code handles cleanup automatically with `git worktree remove`. If you configured a
  WorktreeCreate hook, pair it with a WorktreeRemove hook to control cleanup:
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
  - **No WorktreeRemove hook**: Claude Code falls back to git for a removal at exit or through `ExitWorktree`, and
    keeps the worktree when `claude remote-control` cleans up:
    - **You exit a worktree session, or Claude calls `ExitWorktree`**: Claude Code removes the path your
      WorktreeCreate hook returned as `git worktree remove --force` would, so a worktree git recognizes is removed. A
      worktree git doesn't recognize, for example one your hook created with a non-git version control system, stays
      on disk.
    - **`claude remote-control` cleans up a session's worktree**: the worktree stays on disk, and the terminal running
      `claude remote-control` shows `worktree removal failed, kept: <path>`.
    - **You delete a background session**: see
      [What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes).
  - **Hook exits 0**: the worktree counts as removed. Claude Code reads nothing else from the hook, so make sure your
    hook deleted the directory.
  - **Hook exits non-zero**: the removal fails if the directory at `worktree_path` still exists afterward, and the
    worktree stays on disk with no git fallback. A hook that deleted the directory before exiting non-zero counts as
    removed.
- Claude Code never deletes a branch belonging to a hook-created worktree, because it only knows the path your
  WorktreeCreate hook returned. If your WorktreeCreate hook creates a branch, delete it in your WorktreeRemove hook.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- Claude Code discards a WorktreeRemove hook's JSON output fields, such as `systemMessage` and `continue`.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- For a background-session delete, Claude Code verifies the stored worktree path before running the hook, refusing a
  path that is a symlink or passes through one below the repository root. On that route, the hook runs for a worktree
  that still contains files only when you confirm the delete in agent view. For such a worktree,
  [`claude rm`](https://code.claude.com/docs/en/agent-view#manage-sessions-from-the-shell) keeps the session and
  worktree instead.
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)
- Claude Code passes the path returned by WorktreeCreate as `worktree_path` in the hook input. This example reads that
  path and removes the directory:
  [hooks › WorktreeRemove](https://code.claude.com/docs/en/hooks#worktreeremove)

  ```json
  {
    "hooks": {
      "WorktreeRemove": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "bash -c 'jq -r .worktree_path | xargs rm -rf'"
            }
          ]
        }
      ]
    }
  }
  ```

- For a session whose worktree directory belongs to no git repository, while files remain in the directory, agent view
  asks for the `Ctrl+X` double-press before discarding them. For a hook-created directory it runs your
  `WorktreeRemove` hook instead, and without one it refuses the delete and keeps the session.
  [agent-view › What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes)

### Input

- In addition to the common input fields, WorktreeRemove hooks receive the `worktree_path` field, which is the
  absolute path to the worktree being removed.
  [hooks › WorktreeRemove input](https://code.claude.com/docs/en/hooks#worktreeremove-input)
- A WorktreeRemove hook's exit code decides the outcome. When a hook exits non-zero and the directory at
  `worktree_path` still exists afterward, the removal fails:
  [hooks › WorktreeRemove input](https://code.claude.com/docs/en/hooks#worktreeremove-input)
  - The worktree stays on disk, and the hook's command and stderr go to the
    [debug log](https://code.claude.com/docs/en/hooks#debug-hooks).
  - If you were deleting a background session, the session stays too. The refusal message in agent view reports how
    the hook ended, such as `exited 1`, quotes the start of its stderr, and says whether deleting the session again
    removes the directory anyway.
    [agent-view › What deleting a session removes](https://code.claude.com/docs/en/agent-view#what-deleting-a-session-removes)
  - If `claude remote-control` was cleaning up a session's worktree, the terminal running it shows
    `worktree removal failed, kept: <path>`.

## PreCompact

- PreCompact runs before Claude Code is about to run a compact operation.
  [hooks › PreCompact](https://code.claude.com/docs/en/hooks#precompact)
- The matcher value indicates whether compaction was triggered manually or automatically:
  [hooks › PreCompact](https://code.claude.com/docs/en/hooks#precompact)

  | Matcher | When it fires |
  | :- | :- |
  | `manual` | `/compact` |
  | `auto` | Auto-compact when the conversation reaches the [auto-compact window](https://code.claude.com/docs/en/model-config#set-the-auto-compact-window), and [idle compaction](https://code.claude.com/docs/en/settings-reference#idlecompaction) |

- Exit with code 2 to block compaction. For a manual `/compact`, the stderr message is shown to the user. You can also
  block by returning JSON with `"decision": "block"`.
  [hooks › PreCompact](https://code.claude.com/docs/en/hooks#precompact)
- Blocking automatic compaction has different effects depending on when it fires. If compaction was triggered
  proactively before the context limit, Claude Code skips it and the conversation continues uncompacted. If
  compaction was triggered to recover from a context-limit error already returned by the API, the underlying error
  surfaces and the current request fails.
  [hooks › PreCompact](https://code.claude.com/docs/en/hooks#precompact)
- Claude Code discards a PreCompact hook's `systemMessage` and `continue` fields.
  [hooks › PreCompact](https://code.claude.com/docs/en/hooks#precompact)
- Input: in addition to the common input fields, PreCompact hooks receive `trigger` and `custom_instructions`. For
  `manual`, `custom_instructions` contains what the user passes into `/compact` and is `null` when they pass nothing.
  For `auto`, `custom_instructions` is `null`.
  [hooks › PreCompact input](https://code.claude.com/docs/en/hooks#precompact-input)

## PostCompact

- PostCompact runs after Claude Code completes a compact operation. Use it to react to the new compacted state, for
  example to log the generated summary or update external state. Claude Code discards a PostCompact hook's
  `systemMessage` and `continue` fields.
  [hooks › PostCompact](https://code.claude.com/docs/en/hooks#postcompact)
- The same matcher values apply as for `PreCompact`:
  [hooks › PostCompact](https://code.claude.com/docs/en/hooks#postcompact)

  | Matcher | When it fires |
  | :- | :- |
  | `manual` | After `/compact` |
  | `auto` | After auto-compact when the conversation reaches the [auto-compact window](https://code.claude.com/docs/en/model-config#set-the-auto-compact-window), and after [idle compaction](https://code.claude.com/docs/en/settings-reference#idlecompaction) |

- Input: in addition to the common input fields, PostCompact hooks receive `trigger` and `compact_summary`. The
  `compact_summary` field contains the conversation summary generated by the compact operation.
  [hooks › PostCompact input](https://code.claude.com/docs/en/hooks#postcompact-input)
- PostCompact hooks have no decision control. They can't affect the compaction result but can perform follow-up tasks.
  [hooks › PostCompact input](https://code.claude.com/docs/en/hooks#postcompact-input)

## PreModelSwitch

- PreModelSwitch runs before Claude Code applies a model switch that you or a client requested. Use it to block a
  switch, require confirmation, or show what the switch will cost before it happens. You or your organization can
  configure PreModelSwitch hooks.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)
  [model-config › Setting your model](https://code.claude.com/docs/en/model-config#setting-your-model)
- Claude Code runs it for these requests: `/model <name>` and the `/model` picker; the `Option+P` or `Alt+P` model
  picker; the Model setting in `/config`; turning on fast mode when that changes the session's model; and a
  `set_model` request, or a model change in an `apply_flag_settings` request, from an Agent SDK host or Remote
  Control.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)
- Claude Code doesn't run PreModelSwitch hooks for switches it makes on its own, such as an automatic model fallback
  or restoring the model when you resume a session. Those changes reach PostModelSwitch only.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)

### Matcher

- Claude Code compares the matcher against the canonical name of the model the session is switching to, ignoring any
  `[1m]` suffix. An alias such as `opus`, a dated model ID, and a provider-specific ID such as an Amazon Bedrock model
  ID all match the one canonical name they resolve to, so `claude-opus-5` covers every spelling of Opus 5.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)
- When Claude Code can't determine a canonical name for the target, for example a custom model ID that only your LLM
  gateway knows, it runs every PreModelSwitch hook regardless of matcher. A hook that blocks should therefore check
  `to_model` from its input rather than rely on the matcher alone.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)
- Write the matcher as an exact name, a `|`-separated list such as `claude-opus-4-6|claude-opus-5`, or a regular
  expression such as `.*opus.*`. This example uses an exact-name matcher and also checks `to_model` from the hook
  input, so it refuses a switch to Opus 4.6 by exiting with code 2 and lets any other target through:
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)

  ```json
  {
    "hooks": {
      "PreModelSwitch": [
        {
          "matcher": "claude-opus-4-6",
          "hooks": [
            {
              "type": "command",
              "command": "jq -e '.to_model | test(\"opus-4-6\")' > /dev/null && { echo 'Opus 4.6 is retired for this project. Use a newer model.' >&2; exit 2; }; exit 0"
            }
          ]
        }
      ]
    }
  }
  ```

- On Windows, register a command hook that runs a script through PowerShell, with the same matcher. Save the script to
  `.claude/hooks/block-opus-46.ps1` in your project:
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)

  ```json
  {
    "hooks": {
      "PreModelSwitch": [
        {
          "matcher": "claude-opus-4-6",
          "hooks": [
            {
              "type": "command",
              "command": "powershell.exe",
              "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-opus-46.ps1"
              ]
            }
          ]
        }
      ]
    }
  }
  ```

  ```powershell
  $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
  if ($hookInput.to_model -match 'opus-4-6') {
    [Console]::Error.WriteLine('Opus 4.6 is retired for this project. Use a newer model.')
    exit 2
  }
  exit 0
  ```

- To confirm the hook works, run `/model claude-opus-4-6` from a session running a different model. Claude Code keeps
  the current model and reports that a PreModelSwitch hook blocked the switch, with your message as the reason.
  [hooks › PreModelSwitch](https://code.claude.com/docs/en/hooks#premodelswitch)

### Input

- In addition to the common input fields, PreModelSwitch hooks receive the fields in this table. The last five
  describe what re-sending the conversation to the new model costs, so a hook can show that figure before the switch
  happens:
  [hooks › PreModelSwitch input](https://code.claude.com/docs/en/hooks#premodelswitch-input)

  | Field | Type | Description |
  | :- | :- | :- |
  | `from_model` | string | Model ID the switch changes from |
  | `to_model` | string | Model ID the switch changes to. The matcher compares against this model's canonical name |
  | `requested_model` | string or `null` | The model the request named: an alias such as `opus`, a full model ID, or `null` when the request was for the default model |
  | `source` | string | Where the request came from: `"command"` for `/model <name>`, the Model setting in `/config`, or turning on fast mode; `"picker"` for a model picker; `"sdk"` for a `set_model` request, or a model change in an `apply_flag_settings` request, from an Agent SDK host or Remote Control |
  | `context_tokens` | number | Tokens the next request re-sends as its prompt: the input, cache read, cache creation, and output tokens of the last response in the main conversation, combined. `0` before the first response |
  | `prompt_cache_warm` | boolean | Whether the current model's prompt cache is likely still warm, meaning the switch forfeits it |
  | `cache_ttl` | string | [Prompt cache lifetime](https://code.claude.com/docs/en/prompt-caching#cache-lifetime) of the main conversation at the time of this switch: `"5m"` or `"1h"` |
  | `estimated_cache_write_usd` | number | Estimated cost in US dollars of writing `context_tokens` to the prompt cache on `to_model` at the `cache_ttl` rate, excluding the next response. The server may not need to re-cache the whole context, so treat it as an estimate |
  | `pricing` | string | How Claude Code priced `estimated_cache_write_usd`: `"configured"` at your organization's own rates when it has configured them, `"catalog"` at list price, or `"default"` when `to_model` has no known price and Claude Code assumed a default rate |

### Output

- Exit code 2 or a top-level `decision: "block"` cancels the switch. For finer control, to cancel it, ask the user to
  confirm it, or let it proceed, return `permissionDecision` and `permissionDecisionReason` in a `hookSpecificOutput`
  object, as on PreToolUse. `PreModelSwitch` accepts `"allow"`, `"deny"`, and `"ask"`. It doesn't accept `"defer"`,
  `updatedInput`, or `additionalContext`. This table describes both fields:
  [hooks › PreModelSwitch decision control](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control)
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)

  | Field | Description |
  | :- | :- |
  | `permissionDecision` | `"allow"` proceeds and skips the [confirmation Claude Code shows while the prompt cache is warm](https://code.claude.com/docs/en/prompt-caching#switching-models). `"deny"` cancels the switch. `"ask"` prompts the user to confirm it |
  | `permissionDecisionReason` | For `"deny"`, shown to the user as the reason the switch was blocked, or returned as the error for a `set_model` request. For `"ask"`, shown in the confirmation prompt. Ignored for `"allow"` |

- Only `/model` in an interactive session can show the `"ask"` prompt. On every other surface, including
  non-interactive mode with the `-p` flag, `/config`, and `set_model` requests, Claude Code treats `"ask"` as a
  refusal.
  [hooks › PreModelSwitch decision control](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control)
  [hooks-guide › Structured JSON output](https://code.claude.com/docs/en/hooks-guide#structured-json-output)
- This example asks the user to confirm and quotes the token count from `context_tokens`:
  [hooks › PreModelSwitch decision control](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "PreModelSwitch",
      "permissionDecision": "ask",
      "permissionDecisionReason": "Switching now re-sends about 180k tokens to the new model. Continue?"
    }
  }
  ```

- When multiple PreModelSwitch hooks return different decisions, precedence is `deny` > `ask` > `allow`.
  [hooks › PreModelSwitch decision control](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control)
- Claude Code shows the user any `systemMessage` your hook returns regardless of the decision, so a cost-report hook can
  return `{"systemMessage": "..."}` and exit 0.
  [hooks › PreModelSwitch decision control](https://code.claude.com/docs/en/hooks#premodelswitch-decision-control)
- A PreModelSwitch hook that doesn't respond before its timeout blocks the switch. The default timeout for this event
  is 30 seconds.
  [hooks › PreModelSwitch timeouts and other exit codes](https://code.claude.com/docs/en/hooks#premodelswitch-timeouts-and-other-exit-codes)
- An exit code other than 0 or 2 without valid JSON output is a
  [non-blocking error](https://code.claude.com/docs/en/hooks#other-exit-codes), so the switch goes ahead, except for
  hooks [whose failure blocks it](https://code.claude.com/docs/en/hooks#block-the-action-when-a-hook-fails).
  [hooks › PreModelSwitch timeouts and other exit codes](https://code.claude.com/docs/en/hooks#premodelswitch-timeouts-and-other-exit-codes)

### When a switch is blocked

- When a PreModelSwitch hook didn't approve a switch you or a client requested, the session keeps its current model and
  Claude Code shows `Model switch to <model> was blocked by a PreModelSwitch hook: <reason>`. When the switch came
  from an Agent SDK host or Remote Control rather than a command you typed, the message reads
  `Model switch blocked by a PreModelSwitch hook` without naming the target model. The reason after the colon says
  what refused the switch:
  [errors › Model switch was blocked by a PreModelSwitch hook](https://code.claude.com/docs/en/errors#model-switch-was-blocked-by-a-premodelswitch-hook)
  - **A reason a hook wrote**: a PreModelSwitch hook supplied that reason when it denied the switch or asked for
    confirmation. Address what it asks, or pick a model your hooks allow.
  - **`PreModelSwitch hook <name> did not respond before its timeout`**: a hook that doesn't answer before its
    timeout blocks the switch. Fix the hanging command or raise that hook's `timeout`, then switch again.
  - **`confirmation required, and this session cannot ask`**: a hook answered `ask` without a reason, and a control
    request has no way to show the confirmation prompt. A `/model` command in a `-p` run reports the same condition
    with `(run /model interactively to confirm)` after the reason. Make the switch from an interactive session, or
    change the hook's decision for this model.
  - **`so organization-managed PreModelSwitch hooks could not be checked`**: Claude Code couldn't tell which
    PreModelSwitch hooks your organization's managed plugins deliver, for example because a managed plugin failed to
    load. One of those hooks might block the switch, so Claude Code refuses rather than apply the switch unchecked.
    The start of the reason names what failed. Claude Code re-checks on every switch attempt, so a failure that has
    since cleared stops blocking; if it keeps failing, run `claude --debug` and switch again to capture the details,
    then fix the plugin or ask your admin to fix it.
    [errors › Model switch was blocked by a PreModelSwitch hook](https://code.claude.com/docs/en/errors#model-switch-was-blocked-by-a-premodelswitch-hook)
    [model-config › Setting your model](https://code.claude.com/docs/en/model-config#setting-your-model)
  - **`a PreModelSwitch hook failed before answering`** or **`PreModelSwitch hooks were cancelled (the control
    stream closed) before answering`**: the hook run ended without a verdict, and Claude Code doesn't treat that as
    approval. Run `claude --debug` to see what failed, then switch again.

## PostModelSwitch

- PostModelSwitch runs after the session's model changes. Use it to give Claude model-specific guidance without
  editing every CLAUDE.md, for example an organization-wide instruction that applies on certain models. It can't
  block, because the model has already changed.
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)
- Claude Code runs PostModelSwitch hooks after a switch you or a client requested; an automatic model fallback, which
  changes the session's model; a setting such as `opusplan` entering or leaving plan mode; and Claude Code restoring
  the model when you resume a session.
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)
- Claude Code doesn't run PostModelSwitch hooks when a model from a fallback model chain serves a turn, because that
  substitution lasts one turn and leaves the session's model unchanged.
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)
- The matcher follows the same rules as PreModelSwitch: Claude Code compares it against the canonical name of the model
  the session switched to.
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)
- This example adds guidance whenever the session's model changes to any Opus model:
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)

  ```json
  {
    "hooks": {
      "PostModelSwitch": [
        {
          "matcher": ".*opus.*",
          "hooks": [
            {
              "type": "command",
              "command": "echo 'On Opus, delegate implementation work to subagents and keep this conversation for planning and review.'"
            }
          ]
        }
      ]
    }
  }
  ```

- To confirm the hook works, switch to an Opus model from a session running a different model, for example run
  `/model opus` from a Sonnet session, then ask Claude what guidance it has about the current model.
  [hooks › PostModelSwitch](https://code.claude.com/docs/en/hooks#postmodelswitch)

### Input

- PostModelSwitch hooks receive the same fields as PreModelSwitch, with `hook_event_name` set to `"PostModelSwitch"`
  and two more `source` values: `"auto"` for an automatic fallback or other change Claude Code made on its own, and
  `"resume"` for the model restored when you resume a session.
  [hooks › PostModelSwitch input](https://code.claude.com/docs/en/hooks#postmodelswitch-input)
- `requested_model` is `null` when `source` is `"auto"`. When `source` is `"resume"`, it is the saved model setting
  Claude Code restored.
  [hooks › PostModelSwitch input](https://code.claude.com/docs/en/hooks#postmodelswitch-input)

### Output

- Claude Code takes your hook's plain-text stdout on exit 0, or `additionalContext` from JSON output, and delivers it
  to Claude with the next request after the switch. In addition to the JSON output fields available to all hooks, you
  can return `additionalContext`, a string added to Claude's context with the next request.
  [hooks › PostModelSwitch decision control](https://code.claude.com/docs/en/hooks#postmodelswitch-decision-control)
- If the hook hasn't finished within five seconds after you send the next prompt, Claude Code sends that request
  without the output and attaches it to the following request instead. If the model changes several times before the
  next request, Claude Code delivers only the output for the last switch's target model.
  [hooks › PostModelSwitch decision control](https://code.claude.com/docs/en/hooks#postmodelswitch-decision-control)

## SessionEnd

- SessionEnd runs when a Claude Code session ends. It is useful for cleanup tasks, logging session statistics, or
  saving session state. It supports matchers to filter by exit reason.
  [hooks › SessionEnd](https://code.claude.com/docs/en/hooks#sessionend)
- The `reason` field in the hook input indicates why the session ended:
  [hooks › SessionEnd](https://code.claude.com/docs/en/hooks#sessionend)

  | Reason | Description |
  | :- | :- |
  | `clear` | Session cleared with `/clear` command |
  | `resume` | Session switched via interactive `/resume` |
  | `logout` | User logged out |
  | `prompt_input_exit` | User exited while prompt input was visible |
  | `other` | Other exit reasons |

- Claude Code doesn't send `bypass_permissions_disabled`; drop it from your `SessionEnd` matchers.
  [hooks › SessionEnd](https://code.claude.com/docs/en/hooks#sessionend)
- When you stop a `claude -p` run with SIGTERM, Claude Code runs `SessionEnd` hooks and exits. While exiting, Claude
  Code starts no new tool call, sends no new model request, and runs no hook other than `SessionEnd`.
  [headless › Stop a run with SIGTERM](https://code.claude.com/docs/en/headless#stop-a-run-with-sigterm)

### Input

- In addition to the common input fields, SessionEnd hooks receive a `reason` field indicating why the session ended,
  with the values in the table above.
  [hooks › SessionEnd input](https://code.claude.com/docs/en/hooks#sessionend-input)

### Output

- SessionEnd hooks have no decision control. They can't block session termination but can perform cleanup tasks.
  Claude Code discards their JSON output fields, such as `systemMessage`.
  [hooks › SessionEnd input](https://code.claude.com/docs/en/hooks#sessionend-input)
- SessionEnd hooks have a default timeout of 1.5 seconds. It applies when you exit, run `/clear`, or switch sessions
  with interactive `/resume`. You can give a hook more time in two ways:
  [hooks › SessionEnd input](https://code.claude.com/docs/en/hooks#sessionend-input)
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
  - **Per-hook `timeout`**: set `timeout` in that hook's configuration. The overall budget rises automatically to
    match the highest per-hook `timeout` in your settings files, up to 60 seconds. If you raise the budget this way, a
    hook without its own `timeout` still keeps the default. Timeouts set on plugin-provided hooks don't raise the
    budget.
  - **`CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS`**: set this environment variable in milliseconds to override the
    budget explicitly. The value you set also becomes the timeout for each hook without its own `timeout`.
- This example sets the budget to 5 seconds:
  [hooks › SessionEnd input](https://code.claude.com/docs/en/hooks#sessionend-input)

  ```bash
  CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000 claude
  ```


## Elicitation

- Elicitation runs when an MCP server requests user input mid-task. By default, Claude Code shows an interactive
  dialog for the user to respond. Hooks can intercept this request and respond programmatically, skipping the dialog
  entirely. The matcher field matches against the MCP server name.
  [hooks › Elicitation](https://code.claude.com/docs/en/hooks#elicitation)
- With `--permission-prompts none` in a `-p` run, any MCP elicitation request that no `Elicitation` hook answers is
  cancelled.
  [headless › Turn off permission prompts in unattended runs](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs)
- In a [non-interactive](https://code.claude.com/docs/en/headless) session, Claude Code asks the MCP server to cancel a
  task that requests input, without running your `Elicitation` hooks.
  [mcp › Answer a question from an MCP task](https://code.claude.com/docs/en/mcp#answer-a-question-from-an-mcp-task)

### Input

- In addition to the common input fields, Elicitation hooks receive `mcp_server_name`, `message`, and optional `mode`,
  `url`, `elicitation_id`, and `requested_schema` fields. In the documentation's example, form-mode elicitation, the
  most common case, carries `mode: "form"` and a `requested_schema`, and URL-mode elicitation, used for browser-based
  authentication, carries `mode: "url"` and a `url`.
  [hooks › Elicitation input](https://code.claude.com/docs/en/hooks#elicitation-input)

### Output

- An Elicitation hook can answer the request for the user, decline or cancel it, or leave it to the dialog. To answer,
  decline, or cancel, exit 0 and print a `hookSpecificOutput` object with an `action`. The server gets your answer and
  no dialog appears. Each row of this table shows what to return for one outcome and what the MCP server receives:
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)

  | To | Return | The server receives |
  | :- | :- | :- |
  | Answer for the user | `"action": "accept"`, with the form field values in `content` | `accept` with your `content` |
  | Decline the request | `"action": "decline"` | `decline` |
  | Cancel the request | `"action": "cancel"` | `cancel` |
  | Leave the request to the user | No output, with exit code 0 | The user's answer from the [dialog](https://code.claude.com/docs/en/mcp#respond-to-mcp-elicitation-requests) |

- This output answers the form-mode request shown under Elicitation input. The keys in `content` are the property
  names from that request's `requested_schema`:
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "Elicitation",
      "action": "accept",
      "content": {
        "username": "alice"
      }
    }
  }
  ```

- This output declines a request:
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "Elicitation",
      "action": "decline"
    }
  }
  ```

- In the dialog, selecting **Decline** sends `decline` and pressing `Esc` sends `cancel`, so return the one you want
  the server to see.
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)
- For a URL-mode request, a hook that returns `accept` skips the dialog, so the URL never opens.
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)
- Claude Code discards `reason`, `systemMessage`, and `continue` from an Elicitation hook's JSON output, whichever
  `action` you return.
  [hooks › Elicitation output](https://code.claude.com/docs/en/hooks#elicitation-output)
- Your hook can also decline in these ways. The server receives the same `decline` as for `"action": "decline"`:
  [hooks › Other ways to decline an elicitation](https://code.claude.com/docs/en/hooks#other-ways-to-decline-an-elicitation)
  - **Exits with code 2**: Claude Code ignores a `hookSpecificOutput` printed by the same hook
  - **Prints a top-level `"decision": "block"`**: the block overrides an `action` in the same output
- When several hooks match the same request, a decline from one of them overrides an `accept` or `cancel` from
  another.
  [hooks › Other ways to decline an elicitation](https://code.claude.com/docs/en/hooks#other-ways-to-decline-an-elicitation)
- This script declines URL-mode requests and leaves form requests to the dialog:
  [hooks › Other ways to decline an elicitation](https://code.claude.com/docs/en/hooks#other-ways-to-decline-an-elicitation)

  ```bash
  #!/bin/bash
  if [ "$(jq -r '.mode')" = "url" ]; then
    exit 2
  fi
  ```

- Neither the user nor the server sees why your hook declined, because Claude Code doesn't show your stderr or your
  `reason`.
  [hooks › Other ways to decline an elicitation](https://code.claude.com/docs/en/hooks#other-ways-to-decline-an-elicitation)
- This example answers one recurring question for the user. An MCP server named `issue-tracker` asks for a project key
  in a form, and the hook fills in `DOCS`. The script accepts when `project_key` is the form's single field. For any
  other request it prints nothing, so the dialog appears. Register a command hook for the event in your settings file,
  with the server name as the matcher:
  [hooks › Answer a form request from a script](https://code.claude.com/docs/en/hooks#answer-a-form-request-from-a-script)

  ```json
  {
    "hooks": {
      "Elicitation": [
        {
          "matcher": "issue-tracker",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/answer-project-key.sh",
              "args": []
            }
          ]
        }
      ]
    }
  }
  ```

  Save this script to `.claude/hooks/answer-project-key.sh` in your project and make it executable with `chmod +x`:

  ```bash
  #!/bin/bash
  input=$(cat)
  fields=$(jq -c '.requested_schema.properties // {} | keys' <<<"$input")

  if [ "$fields" = '["project_key"]' ]; then
    jq -n '{hookSpecificOutput: {hookEventName: "Elicitation", action: "accept", content: {project_key: "DOCS"}}}'
  fi
  ```

- On Windows, register a command hook that runs the script through PowerShell, with the server name as the matcher.
  Save the script to `.claude/hooks/answer-project-key.ps1` in your project:
  [hooks › Answer a form request from a script](https://code.claude.com/docs/en/hooks#answer-a-form-request-from-a-script)

  ```json
  {
    "hooks": {
      "Elicitation": [
        {
          "matcher": "issue-tracker",
          "hooks": [
            {
              "type": "command",
              "command": "powershell.exe",
              "args": [
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                "${CLAUDE_PROJECT_DIR}/.claude/hooks/answer-project-key.ps1"
              ]
            }
          ]
        }
      ]
    }
  }
  ```

  ```powershell
  $request = [Console]::In.ReadToEnd() | ConvertFrom-Json
  $fields = @($request.requested_schema.properties.PSObject.Properties.Name)

  if ($fields.Count -eq 1 -and $fields[0] -eq 'project_key') {
    @{
      hookSpecificOutput = @{
        hookEventName = "Elicitation"
        action = "accept"
        content = @{ project_key = "DOCS" }
      }
    } | ConvertTo-Json -Depth 3
  }
  ```

- To confirm the hook works, start Claude Code with `claude --debug` and give Claude a task that makes the server ask
  for the project key. No dialog appears, and the [debug log](https://code.claude.com/docs/en/hooks#debug-hooks) has a
  line that ends with `Elicitation resolved by hook: {"action":"accept","content":{"project_key":"DOCS"}}`.
  [hooks › Answer a form request from a script](https://code.claude.com/docs/en/hooks#answer-a-form-request-from-a-script)

## ElicitationResult

- ElicitationResult runs after a user responds to an MCP elicitation. Hooks can observe, modify, or block the response
  before it is sent back to the MCP server. The matcher field matches against the MCP server name.
  [hooks › ElicitationResult](https://code.claude.com/docs/en/hooks#elicitationresult)
- When an [Elicitation](https://code.claude.com/docs/en/hooks#elicitation) hook answers a request, Claude Code sends
  that answer to the server without running ElicitationResult hooks.
  [hooks › ElicitationResult](https://code.claude.com/docs/en/hooks#elicitationresult)

### Input

- In addition to the common input fields, ElicitationResult hooks receive `mcp_server_name`, `action`, and optional
  `mode`, `elicitation_id`, and `content` fields.
  [hooks › ElicitationResult input](https://code.claude.com/docs/en/hooks#elicitationresult-input)

### Output

- An ElicitationResult hook can let the user's response through, change its values, or block it. To change or block
  the response, exit 0 and print a `hookSpecificOutput` object with an `action`. Each row of this table shows what to
  return for one outcome and what the MCP server receives:
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)

  | To | Return | The server receives |
  | :- | :- | :- |
  | Let the response through | No output, with exit code 0 | The user's response, unchanged |
  | Change the submitted values | `"action": "accept"`, with the new values in `content` | `accept` with your `content` in place of the user's values |
  | Block the response | `"action": "decline"` | `decline`, without the user's values |
  | Cancel the request | `"action": "cancel"` | `cancel`, along with the values the user submitted. To withhold them, return `"decline"` |

- This output changes the response shown under ElicitationResult input, so the server receives `alice@example.com`
  where the user submitted `alice`:
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "ElicitationResult",
      "action": "accept",
      "content": {
        "username": "alice@example.com"
      }
    }
  }
  ```

- Your `content` replaces the user's whole `content` object, so include the fields you aren't changing. Return
  `action` along with it, because Claude Code ignores a `hookSpecificOutput` that has no `action`.
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)
- ElicitationResult hooks also run when the user declines or cancels, and your `action` replaces theirs. Check that the
  input's `action` is `accept` before you return `accept`, or your hook turns a declined request into an accepted one.
  This script makes the same change when the user accepted, keeps the other fields, and prints nothing otherwise:
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)

  ```bash
  #!/bin/bash
  input=$(cat)

  if [ "$(jq -r '.action' <<<"$input")" = "accept" ]; then
    jq '{hookSpecificOutput: {hookEventName: "ElicitationResult", action: "accept", content: (.content + {username: (.content.username + "@example.com")})}}' <<<"$input"
  fi
  ```

- This output blocks the response:
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)

  ```json
  {
    "hookSpecificOutput": {
      "hookEventName": "ElicitationResult",
      "action": "decline"
    }
  }
  ```

- Exit code 2 and a top-level `"decision": "block"` also block the response. When a hook combines them, exit 2 ignores
  a `hookSpecificOutput` printed by the same hook, and the block overrides an `action` in the same output.
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)
  [hooks › Other ways to decline an elicitation](https://code.claude.com/docs/en/hooks#other-ways-to-decline-an-elicitation)
- Claude Code discards `reason`, `systemMessage`, and `continue` from an ElicitationResult hook's JSON output,
  whichever `action` you return.
  [hooks › ElicitationResult output](https://code.claude.com/docs/en/hooks#elicitationresult-output)

## Not stated by the documentation

- Elicitation hooks receive optional `mode`, `url` and `requested_schema` fields, and the documentation's examples show
  `requested_schema` with `mode: "form"` and `url` with `mode: "url"`. It does not say whether `requested_schema`
  appears only in form mode and `url` only in URL mode, or what `mode` is when it is absent.
  [hooks › Elicitation input](https://code.claude.com/docs/en/hooks#elicitation-input)
- The documentation says a PostModelSwitch hook can't block and that Claude Code delivers its stdout or
  `additionalContext`. It does not say whether Claude Code discards the `systemMessage` and `continue` JSON fields for
  this event, as it does for several other events.
  [hooks › PostModelSwitch decision control](https://code.claude.com/docs/en/hooks#postmodelswitch-decision-control)

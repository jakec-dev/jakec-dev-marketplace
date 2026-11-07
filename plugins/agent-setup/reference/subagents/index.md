# Subagents reference

What Claude Code does with subagents: where their definitions live, how they are written, chosen, invoked and run,
what they can do and see, and how to turn them off or find out why one isn't working.

## Contents

- [Key facts](#key-facts)
- [Topics](#topics)

## Key facts

- Frontmatter field names must match the reference table exactly, camelCase included; Claude Code ignores a field
  it doesn't recognize without reporting an error, and `claude --debug` logs `does not recognize or apply` for it.
  See [frontmatter.md › Frontmatter fields](frontmatter.md).
- Claude Code skips a project, user, managed or `--add-dir` agent file without telling the session when it has no
  `name`, no `description`, YAML that doesn't parse, an opening `---` that isn't the first line, or a `name` that
  starts with `-`, contains `:` or is over 256 characters.
  See [troubleshooting.md › Files that do not load](troubleshooting.md).
- Two files under one `agents` directory tree with the same `name` load only one, chosen by filesystem read order.
  See [placing.md › Project and user directories](placing.md).
- Plugin agents ignore `permissionMode`, `mcpServers`, `initialPrompt` and `hooks`.
  See [frontmatter.md › Frontmatter fields](frontmatter.md) and [frontmatter.md › Plugin agents](frontmatter.md).
- With nothing configured, a subagent Claude spawns from the main conversation runs in the background, and a background
  subagent loses every built-in tool outside a fixed set, even one listed in `tools`, with no error unless the list
  resolves to nothing; forks and resumed foreground subagents keep their tools.
  See [tools.md › Available tools](tools.md) and
  [running.md › Permissions, tools and results of background subagents](running.md).
- An `Agent(type)` list in `tools` restricts spawning only for an agent run as the main thread with `--agent`; in a
  subagent definition the types in parentheses are ignored.
  See [tools.md › Restricting which subagents can be spawned](tools.md).
- `CLAUDE_CODE_SUBAGENT_MODEL` is only a default: a per-invocation model and the definition's `model` field,
  including `inherit`, take precedence unless `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is set.
  See [models.md › Choosing the model](models.md) and [models.md › Running every subagent on one model](models.md).
- A subagent's `permissionMode` is ignored while the main conversation is in `bypassPermissions`, `acceptEdits` or
  auto mode, plan mode keeps it in plan mode unless it runs as an agent team teammate, and `bypassPermissions` takes
  effect only when the main conversation is in it.
  See [tools.md › Permission modes](tools.md).
- A new `agents` directory, any agent file under an `--add-dir` directory, and sessions started with
  `--disable-slash-commands` need a restart for a change to load.
  See [placing.md › Live reload and restarts](placing.md).
- Write `autoCompactWindow` as a plain integer: Claude Code reads `200k` as 200, outside the allowed range, and the
  subagent compacts as if the field were absent.
  See [context.md › Auto-compaction](context.md).
- Write `cacheTtl` inside the `experimental` map, not at the top level of the frontmatter.
  See [frontmatter.md › Frontmatter fields](frontmatter.md).

## Topics

- [placing.md](placing.md): deciding where a subagent definition lives and how it is identified (scopes and priority,
  nested and recursive directories, names and clashes, `--add-dir`, managed and plugin agents and scoped names, the
  manifest `agents` key, `--agents` JSON and its file form, live reload and restarts, worktree read-through, `/cd`,
  `/agents`)
  - Scopes and priority
  - Project and user directories
  - Plugin agents
  - The `--agents` flag
  - Managed subagents
  - Directories added with `--add-dir`
  - Worktrees and `/cd`
  - Live reload and restarts
  - `/agents`
  - Not stated by the documentation

- [frontmatter.md](frontmatter.md): writing a definition (file format, the body as system prompt, every frontmatter
  field, the plugin-agent subset, the `skills` field, `--append-subagent-system-prompt`, `${...}` in plugin agents,
  colours)
  - File format
  - Frontmatter fields
  - Plugin agents
  - Preloaded skills
  - Colours
  - Not stated by the documentation

- [invoking.md](invoking.md): how Claude chooses a subagent and how to invoke one (descriptions and their token budget,
  built-in subagents, natural language, @-mentions, `--agent` and the `agent` setting including plugin defaults and
  resume, subagent names, reusing a definition for an agent team teammate)
  - How Claude chooses
  - Built-in subagents
  - Invoking one yourself
  - Running the whole session as a subagent
  - Subagent names
  - Agent team teammates
  - Resumed sessions
  - Not stated by the documentation

- [tools.md](tools.md): controlling what a subagent can do (available tools and their filters, `tools` and
  `disallowedTools`, MCP entries, inline `mcpServers` and their trust rule, `Agent(type)` allowlists, Agent tool
  resolution, permission modes and auto mode, the sandbox, the WebSearch limit)
  - Available tools
  - Restricting tools
  - MCP tool entries
  - How the Agent tool resolves a subagent's tools
  - Restricting which subagents can be spawned
  - Scoping MCP servers to a subagent
  - Trust for inline MCP servers
  - Permission modes
  - Auto mode
  - Sandbox
  - WebSearch limit

- [models.md](models.md): choosing a subagent's model, effort and prompt cache lifetime (`model` and its resolution
  order, `CLAUDE_CODE_SUBAGENT_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, aliases, allowlist substitution, thinking,
  `effort` and its cap, the advisor, model switches, the cache bucket and TTL)
  - Choosing the model
  - Running every subagent on one model
  - Effort
  - Thinking and the advisor
  - Model switches
  - Prompt cache lifetime

- [running.md](running.md): running subagents in the foreground or background (the background default, waiting,
  permission prompts, results and notifications, the panel and `/tasks`, nesting depth, the concurrency limit,
  background commands and monitors, `-p` runs and budgets, VS Code, compaction, resume and branch, output scanning)
  - Foreground and background
  - Letting Claude wait
  - Permissions, tools and results of background subagents
  - The panel, `/tasks` and the agent map
  - Moving to the background and stopping
  - Nesting depth
  - Concurrent subagent limit
  - Background commands and monitors
  - Compaction, resume and branch
  - `claude -p` runs and budgets
  - Environment variables
  - Output scanning

- [context.md](context.md): knowing what a subagent sees and keeps (startup context, state that never reaches it,
  persistent `memory`, resuming and `SendMessage`, names after a restart, transcripts, auto-compaction and its window)
  - What loads at startup
  - Persistent memory
  - Resuming and SendMessage
  - Names after a restart
  - Transcripts
  - Auto-compaction
  - Not stated by the documentation

- [forking.md](forking.md): running a forked subagent (what a fork inherits, `/subtask`, Claude and `/btw`, steering
  from the panel, how forks differ, turning fork mode off)
  - What a fork is
  - Starting a fork
  - Forking from /btw
  - Observing and steering forks
  - How forks differ from other subagents
  - Turning fork mode off
  - Not stated by the documentation

- [isolation.md](isolation.md): isolating a subagent's edits (working directory, `isolation: worktree`, enforcement
  checks and the messages for blocked commands and paths, `worktree.baseRef`, `.worktreeinclude`, sparse paths, cleanup
  and locks, refused worktrees, `EnterWorktree` and `ExitWorktree`, `/rewind`)
  - Working directory
  - Run a subagent in a worktree
  - Enforcement checks
  - Blocked commands
  - Paths that cannot be safely resolved
  - Base branch
  - Files and directories in the worktree
  - Cleanup
  - Refused worktrees
  - Entering and leaving worktrees
  - Rewinding subagent edits

- [excluding.md](excluding.md): disabling or restricting subagents (`Agent(...)` deny rules, input-parameter rules,
  removing built-in agents, `--bare`, `CLAUDE_CODE_SIMPLE`, `--safe-mode`, `strictPluginOnlyCustomization.agents`,
  `disableSideloadFlags`)
  - Deny a subagent or the Agent tool
  - Match an Agent call by input parameter
  - Remove built-in subagents
  - Bare and safe mode
  - Managed settings
  - Not stated by the documentation

- [troubleshooting.md](troubleshooting.md): checking why a subagent doesn't load, launch or behave (skipped files,
  `claude plugin validate`, the debug log, error messages, API errors, teammates launched instead, `/context`)
  - Files that do not load
  - Launched as a teammate
  - Launch and startup errors
  - API errors and model IDs
  - Auto mode and subagents
  - Seeing subagents in a session

- [observing.md](observing.md): observing subagents in output, telemetry and gateways (stream-json subagent messages,
  OpenTelemetry attributes and events, gateway headers)
  - Seeing subagents in stream-json output
  - Seeing subagents in OpenTelemetry
  - Seeing subagents in gateway headers

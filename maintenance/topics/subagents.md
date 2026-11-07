# Subagents topics

- `placing.md`: deciding where a subagent definition lives and how it is identified (scopes and priority, nested and
  recursive directories, names and clashes, `--add-dir`, managed and plugin agents and scoped names, the manifest
  `agents` key, `--agents` JSON and its file form, live reload and restarts, worktree read-through, `/cd`, `/agents`)
- `frontmatter.md`: writing a definition (file format, the body as system prompt, every frontmatter field, the
  plugin-agent subset, the `skills` field, `--append-subagent-system-prompt`, `${...}` in plugin agents, colours)
- `invoking.md`: how Claude chooses a subagent and how to invoke one (descriptions and their token budget, built-in
  subagents, natural language, @-mentions, `--agent` and the `agent` setting including plugin defaults and resume,
  subagent names, reusing a definition for an agent team teammate)
- `tools.md`: controlling what a subagent can do (available tools and their filters, `tools` and `disallowedTools`,
  MCP entries, inline `mcpServers` and their trust rule, `Agent(type)` allowlists, Agent tool resolution, permission
  modes and auto mode, the sandbox, the WebSearch limit)
- `models.md`: choosing a subagent's model, effort and prompt cache lifetime (`model` and its resolution order,
  `CLAUDE_CODE_SUBAGENT_MODEL` and `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, aliases, allowlist substitution, thinking,
  `effort` and its cap, the advisor, model switches, the cache bucket and TTL)
- `running.md`: running subagents in the foreground or background (the background default, waiting, permission
  prompts, results and notifications, the panel and `/tasks`, nesting depth, the concurrency limit, background
  commands and monitors, `-p` runs and budgets, VS Code, compaction, resume and branch, output scanning)
- `context.md`: knowing what a subagent sees and keeps (startup context, state that never reaches it, persistent
  `memory`, resuming and `SendMessage`, names after a restart, transcripts, auto-compaction and its window)
- `forking.md`: running a forked subagent (what a fork inherits, `/subtask`, Claude and `/btw`, steering from the
  panel, how forks differ, turning fork mode off)
- `isolation.md`: isolating a subagent's edits (working directory, `isolation: worktree`, enforcement checks and the
  messages for blocked commands and paths, `worktree.baseRef`, `.worktreeinclude`, sparse paths, cleanup and locks,
  refused worktrees, `EnterWorktree` and `ExitWorktree`, `/rewind`)
- `excluding.md`: disabling or restricting subagents (`Agent(...)` deny rules, input-parameter rules, removing built-in
  agents, `--bare`, `CLAUDE_CODE_SIMPLE`, `--safe-mode`, `strictPluginOnlyCustomization.agents`, `disableSideloadFlags`)
- `troubleshooting.md`: checking why a subagent doesn't load, launch or behave (skipped files, `claude plugin
  validate`, the debug log, error messages, API errors, teammates launched instead, `/context`)
- `observing.md`: observing subagents in output, telemetry and gateways (stream-json subagent messages,
  OpenTelemetry attributes and events, gateway headers)

Subagents are split between types: the hooks reference owns hooks in subagent frontmatter, `SubagentStart` and
`SubagentStop`, and the workspace-trust rule for a project subagent's frontmatter hooks; the skills reference owns
`context: fork` and the skills a subagent preloads; the instructions reference owns which CLAUDE.md files and rules a
subagent loads.

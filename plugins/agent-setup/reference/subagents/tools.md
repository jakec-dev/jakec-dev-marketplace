# Subagent tools and permissions

Controlling what a subagent can do: its tools, MCP servers, permission mode, sandbox and search limit.

## Contents

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

## Available tools

- Subagents inherit the built-in tools and MCP tools available in the main conversation, narrowed by two filters. The first removes a short list of tools from every subagent; the second reduces the built-in tool set for subagents that run in the background, which is the default. [Forks](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation) skip both filters and receive the main conversation's exact tool pool. [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- The first filter removes these tools even when listed in the `tools` field: [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
  - `Agent`, when the subagent is at the depth limit; in a fork the tool stays listed but returns an error instead of
    spawning
  - `AskUserQuestion`
  - `EndConversation`, which can end only the main conversation
  - `EnterPlanMode`
  - `ExitPlanMode`, unless the subagent's `permissionMode` is `plan`
  - `ScheduleWakeup`
  - `WaitForMcpServers`
  - `Workflow`
- The second filter applies to background subagents. Apart from `Agent` and `ExitPlanMode`, which follow the first filter's conditions wherever the subagent runs, a background subagent keeps every MCP tool but only these built-in tools: `Read`, `Grep`, `Glob`, `LSP`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, and `Artifact`, plus `SubagentHandback` for a subagent that reports through it. [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- Claude Code removes every other built-in tool from a background subagent, whether inherited or listed in the `tools` field, so the same definition can resolve to different tools in the foreground and the background. The removal reports no error unless it leaves the `tools` list [resolving to nothing](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools). [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- `ListAgents` follows these filters like any built-in tool: a foreground subagent inherits it in sessions where cross-session messaging is enabled, and a background subagent doesn't keep it. [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- Teammates in agent teams additionally keep the task tools and cron tools: `TaskCreate`, `TaskGet`, `TaskList`, `TaskUpdate`, `CronCreate`, `CronDelete`, and `CronList`. In a session without the Task tools, Claude Code doesn't provide the task tools to subagents either, even when the subagent runs a different model. An in-process teammate follows your session the same way. [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- On macOS, Linux, and WSL, Claude Code leaves Glob and Grep out of the default tool set. A subagent that lists `Glob` or `Grep` in its `tools` field and leaves out `Bash` gets the listed tools back for that subagent only, or for the whole session when it runs as the main session agent through `--agent` or the `agent` setting. [tools-reference › Glob tool behavior](https://code.claude.com/docs/en/tools-reference#glob-tool-behavior)
- The `SubagentHandback` tool delivers a subagent's final report to whichever conversation receives that subagent's result. It needs no permission. It is provided only in auto mode, to subagents that the Agent tool runs locally other than forks, and is available in the terminal CLI, IDE extensions, cloud sessions, and the Agent SDK; the classifier reviews the report before it's delivered. [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference#page-title)
- Tool names are the exact strings that subagent tool lists use. [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference#page-title)

## Restricting tools

- To restrict tools, use the `tools` field as an allowlist or the `disallowedTools` field as a denylist. If both are set, `disallowedTools` is applied first, then `tools` is resolved against the remaining pool. A tool listed in both is removed. [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
- This example uses `tools` to allow only Read, Grep, Glob, and Bash. The subagent can't edit files, write files, or use any MCP tools: [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)

  ```yaml
  ---
  name: safe-researcher
  description: Research agent with restricted capabilities
  tools: Read, Grep, Glob, Bash
  ---
  ```

- This example uses `disallowedTools` to inherit the subagent's tool pool except Write and Edit. The subagent keeps Bash, MCP tools, and the rest of its pool: [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)

  ```yaml
  ---
  name: no-writes
  description: Inherits the available tools except file writes
  disallowedTools: Write, Edit
  ---
  ```

- When nothing in the `tools` list resolves to a tool, for example because every entry is misspelled or names a tool that isn't available to subagents, Claude Code usually refuses to launch the subagent and the Agent tool returns an error naming the unresolved entries; see [Agent would be spawned with zero tools](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools) for the message and how to fix each entry. [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
- A `disallowedTools` entry with a specifier, such as `Bash(git push *)`, still removes the whole tool from the subagent, not only the matching commands. To keep Bash and block specific commands, add a [Bash deny rule](https://code.claude.com/docs/en/permissions#bash) such as `Bash(git push *)` to `permissions.deny` in your settings. The rule applies to the main conversation and to subagents. [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
- To allow some operations of a tool while blocking others, use `PreToolUse` hooks to
  validate operations before they execute. [sub-agents › Conditional rules with hooks](https://code.claude.com/docs/en/sub-agents#conditional-rules-with-hooks)

## MCP tool entries

- The `tools` and `disallowedTools` fields also take entries for a whole MCP server: [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)

  | Goal | Field | Example entry |
  | :- | :- | :- |
  | Give the subagent every tool from one server | `tools` | `mcp__github__*` |
  | Withhold one server's tools | `disallowedTools` | `mcp__github` or `mcp__github__*` |
  | Withhold every MCP tool from any server | `disallowedTools` | `mcp__*` |

- This example removes every tool from the `github` MCP server while keeping tools from other servers and the built-in tools in the subagent's pool: [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)

  ```yaml
  ---
  name: local-only
  description: Inherits every tool except those from the github MCP server
  disallowedTools: mcp__github
  ---
  ```

- If a subagent gets none of the tools from an MCP server whose name contains `__`, such as `reports__v2`, check the subagent's `mcp__` entries. [sub-agents › MCP server names that contain a double underscore](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
  - In `tools`: write `mcp__` followed by the [server's whole name](https://code.claude.com/docs/en/permissions#mcp) and `__*`, as in `mcp__reports__v2__*`. Without the trailing `__*`, `mcp__reports__v2` matches none of that server's tools.
  - In `disallowedTools`: look for `mcp__reports` or `mcp__reports__*`, the entries that withhold a server named
    `reports`. With either entry, the subagent loses every `reports__v2` tool as well, because those tool names also
    begin with `mcp__reports__`. To withhold only the `reports` server's tools, list them one by one instead, such as
    `mcp__reports__run_query`.
- A tool from a plugin-bundled MCP server has the full name `mcp__plugin_<plugin-name>_<server-name>__<tool-name>`, where any character outside `A-Z`, `a-z`, `0-9`, `_`, and `-` is replaced with `_`. A subagent's `tools` field uses this full name. [mcp › Plugin-provided MCP servers](https://code.claude.com/docs/en/mcp#plugin-provided-mcp-servers)

## How the Agent tool resolves a subagent's tools

- The Agent tool spawns a subagent in a separate context window. The subagent works through its task autonomously, then returns its result to the parent conversation. The parent doesn't see the subagent's intermediate tool calls or outputs, only that final result. [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)
- The same tool can also launch a teammate, with agent teams enabled and a call that carries a `name`, which reports back through team messages rather than by returning a result. Wherever fork mode is on, it can launch a forked subagent, which inherits the full parent conversation instead of starting fresh. [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)
- Which tools a non-fork subagent can use depends on the `tools` and `disallowedTools` fields in the subagent definition: [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)
  - Neither field set: the subagent inherits every tool available to subagents.
  - `tools` only: the subagent gets only the listed tools.
  - `disallowedTools` only: the subagent gets every parent tool except the listed ones.
  - Both set: `disallowedTools` takes precedence. A tool listed in both is removed.
- In every case, the resolved set is limited to the tools available to subagents: a tool that isn't available to subagents is never granted, even when listed in `tools`. Where the conditions listed for `SubagentHandback` above hold, Claude Code also gives the subagent that tool, even if you leave it out of `tools` or list it in `disallowedTools`. [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)
- Launching the subagent doesn't itself prompt for permission. Claude Code checks the subagent's own tool calls against your permission rules as it runs. [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)
- To limit what a subagent can reach in the first place, narrow its `tools` field, for example by leaving Bash off the list, or set deny rules in your settings. [tools-reference › Agent tool behavior](https://code.claude.com/docs/en/tools-reference#agent-tool-behavior)

## Restricting which subagents can be spawned

- When an agent runs as the main thread with `claude --agent`, it can spawn subagents using the Agent tool. To restrict which subagent types it can spawn, use `Agent(agent_type)` syntax in the `tools` field. [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)
- Existing `Task(...)` references in settings and agent definitions still work as aliases for `Agent(...)`. [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)
- `Agent(worker, researcher)` is an allowlist: only the `worker` and `researcher` subagents can be spawned. If the agent tries to spawn any other type, the request fails and the agent sees only the allowed types in its prompt. To block specific agents while allowing all others, use [`permissions.deny`](https://code.claude.com/docs/en/sub-agents#disable-specific-subagents) instead. [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)

  ```yaml
  ---
  name: coordinator
  description: Coordinates work across specialized agents
  tools: Agent(worker, researcher), Read, Bash
  ---
  ```

- To allow spawning any subagent without restrictions, use `Agent` without parentheses, as in `tools: Agent, Read, Bash`. If you omit `Agent` from the `tools` list entirely, the agent can't spawn any subagents with the Agent tool. [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)
- The `Agent(agent_type)` allowlist syntax applies only to an agent running as the main thread with `claude --agent`. In a subagent definition, listing `Agent` in `tools` lets that subagent spawn subagents of its own while the depth limit allows it, but any type list inside the parentheses is ignored. [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)

## Scoping MCP servers to a subagent

- Use the `mcpServers` field to give a subagent access to MCP servers that aren't available in the main conversation. Inline servers defined here are connected when the subagent starts, subject to the trust rule for the agent file's folder, and disconnected when it finishes. String references share the parent session's connection. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)
- The `mcpServers` field applies both when the agent file runs as a subagent, spawned through the Agent tool or an @-mention, and as the main session, launched with `--agent` or the `agent` setting. When the agent is the main session, inline server definitions connect at startup alongside servers from `.mcp.json` and settings files, under the same trust rule. In `/mcp`, a remote (HTTP or SSE) server you've used before can show the `cached` status instead; Claude Code connects it when Claude first calls one of its tools. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)
- Each entry in the list is either an inline server definition or a string referencing an MCP server already configured in your session: [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)

  ```yaml
  ---
  name: browser-tester
  description: Tests features in a real browser using Playwright
  mcpServers:
    # Inline definition: scoped to this subagent only
    - playwright:
        type: stdio
        command: npx
        args: ["-y", "@playwright/mcp@latest"]
    # Reference by name: reuses an already-configured server
    - github
  ---
  ```

- Inline definitions use the same schema as `.mcp.json` server entries, keyed by the server name, and support the `stdio`, `http`, `sse`, and `ws` types. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)
- To keep an MCP server out of the main conversation entirely and avoid its tool descriptions consuming context there, define it inline in `mcpServers` rather than in `.mcp.json`. The subagent gets the tools; the parent conversation doesn't. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)
- The MCP restrictions that apply to the main session also cover servers declared in subagent frontmatter: `--strict-mcp-config` and `--bare`, enterprise managed MCP configuration, and `allowedMcpServers` and `deniedMcpServers` policies. When one of these blocks a server, Claude Code skips it and shows a warning naming the blocked servers. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)
- Managed-settings restrictions apply to every subagent regardless of how it is defined. `--strict-mcp-config` doesn't filter servers you pass inline via `--agents` or the SDK `agents` option, since those are explicit caller input. [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)

## Trust for inline MCP servers

- Claude Code loads an inline MCP server from an agent file in your project's `.claude/agents/` directory, or in an `--add-dir` directory's `.claude/agents/`, only after you [trust the folder the agent file came from](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder). [sub-agents › Trust required for inline MCP servers](https://code.claude.com/docs/en/sub-agents#inline-server-trust)
  - Trust that doesn't count: a parent folder's trust, and the automatic trust a `-p` or SDK session gets for hooks in
    settings files.
  - Until then: Claude Code skips every inline server in that agent file and writes the exact
    `projects["<path>"].hasTrustDialogAccepted` key for `~/.claude.json` to the debug log; setting it to `true` there
    trusts the folder by hand.
  - `--add-dir` directories: a directory outside your trusted workspace's repository needs its own trust entry, since
    its `.claude/agents/` files don't inherit your workspace's trust.
- Claude Code loads two kinds of server without checking trust for the folder the agent file came from: a name that references a server you already configured, and an inline server in an agent file from `~/.claude/agents/`, in one you pass with `--agents` or the SDK `agents` option, or in one that managed settings supplies. [sub-agents › Trust required for inline MCP servers](https://code.claude.com/docs/en/sub-agents#inline-server-trust)
- In this row, the columns are the two situations where you haven't trusted the folder itself; the parent-folder
  column doesn't apply inside a nested repository, where an interactive session shows the trust dialog and a
  `claude -p` or SDK run follows the `claude -p` column.
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)

  | What the repository supplies | You trusted only a parent folder | `claude -p` or the SDK, folder never trusted |
  | :- | :- | :- |
  | Inline [`mcpServers`](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent) in the frontmatter of a subagent from the repository or an `--add-dir` directory | Not used, and no dialog is offered | Not used |

## Permission modes

- Set `permissionMode` to choose the permission mode a subagent runs in. Use the modes' config values, so Manual mode is `default`. If you leave it unset, the subagent inherits the main conversation's permission mode. [sub-agents › Permission modes](https://code.claude.com/docs/en/sub-agents#permission-modes)
- The main conversation's permission mode decides whether Claude Code uses the value you set: [sub-agents › Permission modes](https://code.claude.com/docs/en/sub-agents#permission-modes)
  - When the main conversation is in `bypassPermissions`, `acceptEdits`, or auto mode, the subagent runs in that same
    mode and Claude Code ignores the `permissionMode` you set.
  - When the main conversation is in `plan` mode, the subagent stays in plan mode whichever `permissionMode` you set,
    unless it runs as an agent team teammate under the agent teams rules. If you set `dontAsk`, the subagent also
    doesn't prompt you: an action that plan mode would ask you to approve is denied instead.
  - When the main conversation is in `default` or `dontAsk` mode, the subagent runs in the permission mode you set. It keeps the main conversation's permission mode instead in these cases: you set `bypassPermissions`; or you set `auto` and auto mode isn't available to the subagent, such as when a settings file sets [`disableAutoMode`](https://code.claude.com/docs/en/settings-reference#disableautomode) or the subagent's model doesn't support auto mode.
- `permissionMode` accepts these values, and `manual` as an alias for `default`: [sub-agents › Permission modes](https://code.claude.com/docs/en/sub-agents#permission-modes)

  | Mode | Behavior |
  | :- | :- |
  | `default` | Manual mode: prompts for permission |
  | `acceptEdits` | Auto-accept file edits and common filesystem commands for paths in the working directory or `additionalDirectories` |
  | `auto` | [Auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode): a background classifier reviews commands and protected-directory writes |
  | `dontAsk` | Auto-denies calls that would prompt, though a [mod](https://code.claude.com/docs/en/plugins/mods/overview) you installed can still approve [some of those calls](https://code.claude.com/docs/en/permissions#precedence-among-rules-hooks-and-mods). Explicitly allowed tools still work. `AskUserQuestion`, MCP tools marked [`requiresUserInteraction`](https://code.claude.com/docs/en/mcp#require-approval-for-a-specific-tool), [reads from network paths](https://code.claude.com/docs/en/permissions#network-paths), and connector tools [your organization set to `ask`](https://code.claude.com/docs/en/mcp#organization-controls-on-connector-tools) in sessions where that setting reaches Claude Code are denied even if you've allowed them |
  | `bypassPermissions` | [Skip permission prompts](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode). A subagent runs in this mode only when the main conversation does |
  | `plan` | Plan mode (read-only exploration) |

- `permissions.disableBypassPermissionsMode` ignores an agent definition's `permissionMode: bypassPermissions`, so the subagent runs with the parent session's permission mode. [settings-reference › `permissions.disableBypassPermissionsMode`](https://code.claude.com/docs/en/settings-reference#permissions-disablebypasspermissionsmode)

## Auto mode

- The classifier checks subagent work at three points: [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
  1. Before a subagent starts, the delegated task description is evaluated, so a dangerous-looking task is blocked at
     spawn time.
  2. While the subagent runs, each of its actions goes through the same decision order as in the parent session, with
     the same block and allow rules.
  3. When the subagent finishes, the classifier reviews its work and its final report before the parent reads the
     report. When the classifier flags the subagent's work or report, or a separate API safety check refuses the review,
     the report is still delivered, prepended with a security warning. When the classifier is unavailable for the
     review, the report arrives with a note to verify the subagent's work before acting on it.

- On entering auto mode, Claude Code drops broad allow rules that grant arbitrary code execution, and the list includes "`Agent` allow rules". Claude Code restores the dropped rules when you leave auto mode. [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)

## Sandbox

- Subagents run in the same process as the parent session and use the same sandbox configuration. Bash commands inside a subagent are sandboxed when sandboxing is enabled in the parent session. [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)

## WebSearch limit

- An interactive terminal session has a limit of 200 WebSearch calls. Searches from the main conversation and from subagents, such as a parallel research fan-out, count against the same limit. [tools-reference › Session search limit](https://code.claude.com/docs/en/tools-reference#session-search-limit)

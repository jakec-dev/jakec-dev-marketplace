# Invoking subagents

How Claude chooses a subagent and how to invoke one: descriptions, built-in subagents, natural language, @-mentions,
`--agent` and the `agent` setting, subagent names and reusing a definition as an agent team teammate.

## Contents

- [How Claude chooses](#how-claude-chooses)
- [Built-in subagents](#built-in-subagents)
- [Invoking one yourself](#invoking-one-yourself)
- [Running the whole session as a subagent](#running-the-whole-session-as-a-subagent)
- [Subagent names](#subagent-names)
- [Agent team teammates](#agent-team-teammates)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## How Claude chooses

- Each subagent runs in its own context window with a custom system prompt, specific tool access and independent
  permissions, and sends its own requests, which count toward the same usage limits as the main conversation. When
  Claude encounters a task that matches a subagent's description, it delegates to that subagent, which works
  independently and returns results.
  [sub-agents › Create custom subagents](https://code.claude.com/docs/en/sub-agents#page-title)
- Claude automatically delegates tasks based on the task description in your request, the `description` field in
  subagent configurations, and current context. To encourage proactive delegation, include phrases like "use
  proactively" in your subagent's description field.
  [sub-agents › Understand automatic delegation](https://code.claude.com/docs/en/sub-agents#understand-automatic-delegation)
- Descriptions take up context, so keep them short. When the combined descriptions of your subagents, except the
  built-in ones, exceed 15,000 tokens, Claude Code shows a warning at startup with the total token count, and still
  loads every subagent. Trim the `description` fields and move detail into each subagent's system prompt, which only
  loads when that subagent runs.
  [sub-agents › Create custom subagents](https://code.claude.com/docs/en/sub-agents#page-title),
  [sub-agents › Understand automatic delegation](https://code.claude.com/docs/en/sub-agents#understand-automatic-delegation)
- If a subagent ships in a plugin, `claude plugin eval` measures how reliably Claude delegates to it across
  realistic prompts: it runs each prompt with and without the plugin and scores the results.
  [sub-agents › Understand automatic delegation](https://code.claude.com/docs/en/sub-agents#understand-automatic-delegation)
- In the transcript, a delegation appears as a tool call row showing the subagent's name followed by a short task
  description, such as `code-improver(Suggest code improvements)`.
  [sub-agents › Quickstart: create your first subagent](https://code.claude.com/docs/en/sub-agents#quickstart-create-your-first-subagent)

## Built-in subagents

- Claude Code includes built-in subagents that Claude automatically uses when appropriate. Each inherits the parent
  conversation's permission rules; most run with a restricted tool set.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)
- **Explore**: a fast, read-only agent optimized for searching and analyzing codebases. Its tools are read-only, with
  Write and Edit denied. Its purpose is file discovery, code search and codebase exploration. Claude delegates to it
  when it needs to search or understand a codebase without making changes, which keeps exploration results out of
  the main conversation context. When invoking it, Claude specifies a thoroughness level: **quick** for targeted
  lookups, **medium** for balanced exploration, or **very thorough** for comprehensive analysis.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)
  - Model: the main conversation's model. When the main conversation runs Fable, it depends on how you connect. With
    a Claude subscription, an Anthropic Console account, or an [LLM gateway](https://code.claude.com/docs/en/llm-gateway)
    reached through `ANTHROPIC_BASE_URL`, Explore runs on the Opus model that the `opus` alias resolves to. On Amazon
    Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, Claude Platform on AWS, or a Claude apps gateway,
    Explore stays on the main conversation's model.
  - A user or project subagent named `Explore` overrides the built-in and keeps its own `model` field, so define one
    with `model: haiku` to run exploration on a lower-cost model.
- **Plan**: a research agent used during plan mode to gather context before presenting a plan. Its model inherits from
  the main conversation, unless you set `CLAUDE_CODE_SUBAGENT_MODEL` and force it onto every subagent. Its tools are
  read-only, with Write and Edit denied. In plan mode, when Claude needs to understand your codebase, it delegates
  research to Plan so that exploration output stays in a separate context window while the main conversation remains
  read-only.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)
- **General-purpose**: a capable agent for complex, multi-step tasks that require both exploration and action. Its
  tools are every tool available to subagents. Its model is the `CLAUDE_CODE_SUBAGENT_MODEL` model if you set one and
  nothing assigns a model another way, otherwise the main conversation's model. Claude delegates to it when the task
  requires both exploration and modification, complex reasoning to interpret results, or multiple dependent steps.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)
- Other built-in helper agents are typically invoked automatically, so you don't need to use them directly:
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)

  | Agent | Model | When Claude uses it |
  | :- | :- | :- |
  | claude | None of its own; follows the model order when Claude spawns it as a subagent | When a task doesn't fit a more specialized agent. A catch-all with every tool available to subagents. Also the default agent for a dispatched [background session](https://code.claude.com/docs/en/agent-view); [which permission mode it starts in](https://code.claude.com/docs/en/agent-view#permission-mode-model-and-effort) depends on how the session was started |
  | statusline-setup | Sonnet | When you run `/statusline` to configure your status line |
  | claude-code-guide | Haiku | When you ask questions about Claude Code features |

- Subagents work on every provider.
  [feature-availability › Features available on every provider](https://code.claude.com/docs/en/feature-availability#features-available-on-every-provider)

## Invoking one yourself

- Three patterns escalate from a one-off suggestion to a session-wide default: natural language, where you name the
  subagent in your prompt and Claude decides whether to delegate; an @-mention, which guarantees the subagent runs
  for one task; and session-wide, where the whole session runs as that subagent via the `--agent` flag or the `agent`
  setting.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)
- Natural language has no special syntax. Name the subagent and Claude typically delegates:
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

  ```text
  Use the test-runner subagent to fix failing tests
  Have the code-reviewer subagent look at my recent changes
  ```

- To @-mention a subagent, type `@` and pick it from the typeahead, the same way you @-mention files. This ensures
  that specific subagent runs rather than leaving the choice to Claude. Your full message still goes to Claude, which
  writes the subagent's task prompt based on what you asked; the @-mention controls which subagent Claude invokes,
  not what prompt it receives.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

  ```text
  @"code-reviewer (agent)" look at the auth changes
  ```

- Subagents provided by an enabled plugin appear in the typeahead under their scoped name, such as
  `my-plugin:code-reviewer` or `my-plugin:review:security` when the plugin organizes agents into subfolders. Named
  background subagents currently running in the session also appear in the typeahead, showing their status next to
  the name.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)
- You can type the mention manually without the picker: `@agent-<name>` for local subagents, or `@agent-` followed by
  the scoped name for plugin subagents, for example `@agent-my-plugin:code-reviewer`. While you type this form the
  typeahead shows file matches rather than agents, but the agent mention still resolves when you submit.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

## Running the whole session as a subagent

- Pass `--agent <name>` to start a session where the main thread itself takes on that subagent's tool restrictions
  and model. The agent name appears as `@<name>` in the startup header so you can confirm it's active. It works with
  built-in and custom subagents.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

  ```bash
  claude --agent code-reviewer
  ```

- Unless the agent's prompt is empty, a custom subagent's system prompt replaces the default Claude Code system
  prompt entirely, the same way `--system-prompt` does (CLAUDE.md files still load, and `omitClaudeMd` is ignored).
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)
- For a plugin-provided subagent, you can pass only the agent name and Claude Code finds it. If multiple plugins
  provide agents with the same name, pass the scoped name to disambiguate. If the plugin places the agent in a
  subfolder of its `agents/` directory, include the subfolder in the scoped name, for example
  `claude --agent my-plugin:review:security`.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

  ```bash
  claude --agent security-reviewer
  claude --agent my-plugin:security-reviewer
  ```

- To make an agent the default for every session in a project, set `agent` in `.claude/settings.json`. The CLI flag
  overrides the setting if both are present.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly)

  ```json
  {
    "agent": "code-reviewer"
  }
  ```

- The `agent` setting runs the main thread as a named subagent, so Claude Code applies that subagent's system prompt,
  tool restrictions and model to your session. It takes any file's scope, is a string naming a built-in or custom
  agent, and defaults to unset, so the main thread runs as Claude Code's default agent. `--agent` takes precedence
  over this key for one session.
  [settings-reference › `agent`](https://code.claude.com/docs/en/settings-reference#agent)
- A plugin's own `settings.json` can supply the `agent` key. Two keys take effect, `agent` and `subagentStatusLine`,
  and every other key is dropped. Set `agent` to run one of the plugin's own agents as the main thread: Claude then
  answers in the main conversation with that agent's system prompt and model while the plugin is enabled. The same
  object can go inline in the `settings` manifest key.
  [plugins/components › Default settings](https://code.claude.com/docs/en/plugins/components#default-settings)

  ```json
  {
    "agent": "security-reviewer"
  }
  ```

- When the same key is set in more than one place, `settings.json` applies and the manifest's `settings` is ignored
  if both exist and `settings.json` sets at least one supported key. Across settings sources, plugin defaults are
  the lowest layer, so a user's own `agent` in `~/.claude/settings.json` overrides yours. If two plugins set the same
  key, the value from the plugin loaded last applies, and `claude --debug` logs `overrides setting`.
  [plugins/components › Default settings](https://code.claude.com/docs/en/plugins/components#default-settings)
- The choice persists when you resume the session: a session started with `--agent` or the `agent` setting continues
  as that agent, keeping its tool restrictions and model. Pass `--agent` when resuming to pick a different one.
  [sub-agents › Invoke subagents explicitly](https://code.claude.com/docs/en/sub-agents#invoke-subagents-explicitly),
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)
- On resume, Claude Code looks for the agent in two places: the session's original directory, provided you have
  trusted that workspace, and then the directory you resume from, so a project-scoped agent still loads when you
  resume from another directory. If it doesn't find the agent in either place, or the agent no longer exists, the
  session resumes with the default tools and shows a warning naming the agent.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)

## Subagent names

- If you start a session with agent teams enabled, Claude can give a subagent a name by passing a `name` parameter
  on the Agent tool call, and may do so on its own, without asking you first. The name makes the subagent
  addressable: Claude can message or resume it by name after it finishes.
  [sub-agents › Subagent names](https://code.claude.com/docs/en/sub-agents#subagent-names)
- In an interactive session with agent teams enabled, a subagent that Claude spawns from the main conversation with a
  `name` launches as a teammate instead, unless the call is a fork or passes `isolation` on the call itself. An
  `isolation` value in the subagent's frontmatter doesn't prevent it, and the teammate then runs in the main
  session's working directory.
  [sub-agents › Subagent names](https://code.claude.com/docs/en/sub-agents#subagent-names)
- Agent teams are enabled by setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to `1`, either in your shell environment or
  through settings.json under `env`. In non-interactive mode with the `-p` flag, including Agent SDK sessions, Claude
  doesn't spawn teammates, and a subagent that Claude names runs as an ordinary subagent even with agent teams
  enabled.
  [agent-teams › Enable agent teams](https://code.claude.com/docs/en/agent-teams#enable-agent-teams)
- Claude Code doesn't ask you to confirm a teammate launch.
  [agent-teams › How Claude starts agent teams](https://code.claude.com/docs/en/agent-teams#how-claude-starts-agent-teams)

## Agent team teammates

- When spawning a teammate in either display mode, you can reference a subagent type from the project, user, managed
  or plugin subagent scope, to define a role once and reuse it both as a delegated subagent and as a teammate. Name
  the subagent type when you ask Claude to spawn the teammate.
  [agent-teams › Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)

  ```text
  Spawn a teammate using the security-reviewer agent type to audit the auth module.
  ```

- Claude Code applies these parts of the named definition to the teammate, though not its `skills`, depending on
  display mode where stated:
  [agent-teams › Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)
  - **`tools`**: the teammate is limited to the tools in the definition's `tools` list. For an in-process teammate,
    Claude Code adds `SendMessage` to that list, and in a session that has the Task tools it adds `TaskCreate`,
    `TaskGet`, `TaskList` and `TaskUpdate` too.
  - **`model`**: the definition's `model` is used in either display mode when your spawn prompt doesn't name one.
  - **`disallowedTools`**: for an in-process teammate, Claude Code removes the tools in the definition's
    `disallowedTools` from the teammate's set. `SendMessage` and the Task tools it adds stay available even when the
    list names them.
  - **`effort`**: for an in-process teammate, Claude Code applies the definition's `effort` under the frontmatter
    effort rules.
  - **`autoCompactWindow`**: for an in-process teammate, Claude Code applies the definition's `autoCompactWindow`
    under that field's rules. A split-pane teammate ignores the field.
  - **Body**: for an in-process teammate, Claude Code appends the definition's body to its default system prompt as
    additional instructions. For a split-pane teammate, it uses the body in place of its default system prompt.
  - **`mcpServers`**: for a split-pane teammate, Claude Code applies the definition's `mcpServers` under the rules
    for that field, which cover a session started with `--agent` as well. An in-process teammate ignores the field
    and loads MCP servers from your project and user settings.
- When Claude messages an in-process teammate that is no longer running, Claude Code brings it back in the same
  session, restores any conversation saved for it, and gives it the message as its next prompt. After you resume a
  session, teammates aren't brought back this way.
  [agent-teams › Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)
- For a teammate it brings back, Claude Code re-applies a definition that came from a project's `.claude/agents/`
  directory or an `--add-dir` directory only if you've trusted the folder the agent file is in. Trusting a parent
  folder doesn't count. Until then, the teammate comes back with none of the definition's tools or instructions,
  keeping only the tools Claude Code adds to every in-process teammate.
  [agent-teams › Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)

## Resumed sessions

- For the system prompt of a resumed session, whether it kept its agent or you pass `--agent` to pick a different
  one, see System prompt flags in resumed conversations: by default, Claude Code builds the system prompt once, on a
  conversation's first request, and records it in the session. Until the conversation is compacted, every later
  request uses that recorded prompt, including after `--resume` or `--continue`; different system prompt flag text,
  or none, on a later launch takes effect once the conversation is compacted or when you start a new conversation.
  Outside cloud sessions, in bare mode (`--bare` or `CLAUDE_CODE_SIMPLE=1`), recording stays off unless you pass
  `--system-prompt-snapshot on`. To rebuild the prompt on every request instead, pass `--system-prompt-snapshot off`.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores),
  [cli-reference › System prompt flags in resumed conversations](https://code.claude.com/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations)

## Not stated by the documentation

- The documentation sends you to System prompt flags in resumed conversations for a resumed `--agent` session's system
  prompt, but that section speaks of system prompt flag text; it does not say outright that a different `--agent`
  passed on resume counts as such text.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)

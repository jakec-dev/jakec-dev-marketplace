# Subagent frontmatter

Writing a subagent definition: the file format, every frontmatter field, plugin agents, preloaded skills and colours.

## Contents

- File format
- Frontmatter fields
- Plugin agents
- Preloaded skills
- Colours
- Not stated by the documentation

## File format

- A subagent file uses YAML frontmatter for configuration, followed by the system prompt in Markdown. The frontmatter
  defines the subagent's metadata and configuration; the body becomes the system prompt that guides the subagent's
  behavior. Subagents receive only this system prompt plus basic environment details like the working directory, not
  the Claude Code system prompt. [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)

  ```markdown
  ---
  name: code-reviewer
  description: Reviews code for quality and best practices
  tools: Read, Glob, Grep
  model: sonnet
  ---

  You are a code reviewer. When invoked, analyze the code and provide
  specific, actionable feedback on quality, security, and best practices.
  ```

- In non-interactive mode, `--append-subagent-system-prompt` appends your text to the end of every subagent's system
  prompt, nested subagents included, apart from a forked subagent, which reuses the conversation's own prompt. If your
  text is too long to pass on the command line, save it to a file and pass the path with
  `--append-subagent-system-prompt-file` instead.
  [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)

## Frontmatter fields

- Configure a subagent with YAML frontmatter between `---` markers at the top of its file, and write its system prompt
  as Markdown after the closing `---`. Only `name` and `description` are required, and a project, user or managed
  agent file missing either is skipped. Multi-word field names use camelCase, such as `maxTurns` and
  `disallowedTools`, and must match the table exactly: Claude Code ignores a field it doesn't recognize without
  reporting an error.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- To find a misspelled field in a subagent that loaded, run `claude --debug` in your shell and search the debug log at
  `~/.claude/debug/<session-id>.txt` for `does not recognize or apply`. The debug log names up to five top-level
  fields in the subagent's file that Claude Code doesn't recognize, with the likely intended name when a supported
  field is close.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- The fields, copied from the documentation's table:
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `name` | Yes | Unique identifier of at most 256 characters, such as `code-reviewer` or `reviewer-v2`. [Hooks](https://code.claude.com/docs/en/hooks#subagentstart) receive this value as `agent_type`. The filename doesn't have to match. Names can't contain `:`, which is reserved for [plugin-scoped identifiers](https://code.claude.com/docs/en/plugins/overview) such as `my-plugin:reviewer` |
  | `description` | Yes | When Claude should delegate to this subagent |
  | `tools` | No | [Tools](https://code.claude.com/docs/en/sub-agents#available-tools) the subagent can use, as a comma-separated string such as `Read, Grep, Bash` or a YAML list. Inherits every tool available to subagents if omitted. If no entry in the list resolves to a tool, the subagent usually [fails to launch](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools) with an error naming the entries. To preload Skills into context, use the `skills` field rather than listing `Skill` here |
  | `disallowedTools` | No | Tools to deny, removed from inherited or specified list. Same format as `tools`. An entry with a specifier, such as `Bash(git push *)`, still [removes the whole tool](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use) |
  | `model` | No | [Model](https://code.claude.com/docs/en/sub-agents#choose-a-model) to use: `sonnet`, `opus`, `haiku`, `fable`, a full model ID such as `claude-opus-5-5`, or `inherit`. When you omit it, Claude Code picks the model in the [subagent model order](https://code.claude.com/docs/en/sub-agents#choose-a-model) |
  | `permissionMode` | No | [Permission mode](https://code.claude.com/docs/en/sub-agents#permission-modes): `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`, or `manual` as an alias for `default`. Ignored for [plugin subagents](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope) |
  | `maxTurns` | No | Maximum number of agentic turns before the subagent stops. When the subagent reaches the limit, Claude Code returns its output marked as partial, and Claude can [resume it](https://code.claude.com/docs/en/sub-agents#resume-subagents) to continue |
  | `autoCompactWindow` | No | Lower the [auto-compact window](https://code.claude.com/docs/en/sub-agents#subagent-auto-compact-window) for this subagent to a token count from `100000` to `1000000` |
  | `skills` | No | [Skills](https://code.claude.com/docs/en/skills) to preload into the subagent's context at startup. The full skill content is injected, not only the description. Subagents can still invoke unlisted project, user, and plugin skills through the Skill tool |
  | `mcpServers` | No | [MCP servers](https://code.claude.com/docs/en/mcp) available to this subagent. Each entry is either a server name referencing an already-configured server (e.g., `"slack"`) or an inline definition with the server name as key and a full [MCP server config](https://code.claude.com/docs/en/mcp#installing-mcp-servers) as value. Ignored for [plugin subagents](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope) |
  | `memory` | No | [Persistent memory scope](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory): `user`, `project`, or `local`. Enables cross-session learning |
  | `background` | No | Set to `true` to keep this subagent in the background even when Claude asks to wait for it. By default, subagents Claude spawns from the main conversation already [start in the background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) |
  | `omitClaudeMd` | No | Set to `true` to start this subagent without the user, project, and local CLAUDE.md files in its [initial context](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup). Use it for subagents that take everything they need from the delegation prompt |
  | `effort` | No | Effort level when this subagent is active. Overrides the session effort level, but not the [`CLAUDE_CODE_EFFORT_LEVEL`](https://code.claude.com/docs/en/env-vars#variables) environment variable. Options: `low`, `medium`, `high`, `xhigh`, `max`; available levels depend on the model. See [Choose an effort level](https://code.claude.com/docs/en/sub-agents#choose-an-effort-level) |
  | `isolation` | No | Set to `worktree` to run the subagent in a temporary [git worktree](https://code.claude.com/docs/en/worktrees), giving it an isolated copy of the repository branched by default from your [default branch](https://code.claude.com/docs/en/worktrees#choose-the-base-branch) rather than the parent session's `HEAD`. The worktree is automatically cleaned up if the subagent makes no changes |
  | `color` | No | Display color for the subagent in the task list and transcript. Accepts `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, or `cyan` |
  | `initialPrompt` | No | Auto-submitted as the first user turn when this agent runs as the main session agent (via `--agent` or the `agent` setting). Prepended to any user-provided prompt. Ignored for [plugin subagents](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope) |
  | `experimental` | No | Map of experimental options. Set its `cacheTtl` key to `5m` or `1h` to choose the [prompt cache lifetime](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself) for this subagent's requests, at the frontmatter's place in the [cache lifetime precedence](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself). Claude Code ignores any other value, ignores `1h` while your Claude subscription is using usage credits, and reads the field only from subagent files |

- `cacheTtl` goes inside the `experimental` map, not at the top level of the frontmatter.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

  ```yaml
  ---
  name: repo-auditor
  description: Audits a large repository and reports what it finds
  experimental:
    cacheTtl: 1h
  ---
  ```

## Plugin agents

- A plugin agent's supported fields are `name`, `description`, `model`, `effort`, `maxTurns`, `autoCompactWindow`,
  `tools`, `disallowedTools`, `skills`, `memory`, `background`, `omitClaudeMd`, `isolation`, `color`, and the
  `cacheTtl` key of `experimental`. The only valid `isolation` value is `"worktree"`.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents)
- A plugin agent ignores `hooks` too. An agent file can't add MCP servers on its own, so add them as plugin MCP
  servers instead.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents)
- For a plugin agent, a `name` longer than 256 characters is ignored and Claude Code names the agent after its file,
  as it does when the field is missing.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents)
- For a plugin agent, frontmatter that doesn't parse still loads the agent with every field ignored. It's named after
  the file, and its description reads `Agent from my-plugin plugin`. Run `claude plugin validate` in your shell to
  find these files.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents)
- In agent content, write a `${...}` reference anywhere in the Markdown body, and Claude Code substitutes the path
  inline when it loads the content, because the variables aren't present in the environment of commands Claude runs
  through the Bash tool, including in a subagent.
  [plugins/manifest-reference › Where each variable resolves](https://code.claude.com/docs/en/plugins/manifest-reference#where-each-variable-resolves)

## Preloaded skills

- The `skills` field injects skill content into a subagent's context at startup, which gives the subagent domain
  knowledge without requiring it to discover and load skills during execution.
  [sub-agents › Preload skills into subagents](https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents)

  ```yaml
  ---
  name: api-developer
  description: Implement API endpoints following team conventions
  skills:
    - api-conventions
    - error-handling-patterns
  ---

  Implement API endpoints. Follow the conventions and patterns from the preloaded skills.
  ```

- You can't preload skills that set `disable-model-invocation: true`, since preloading draws from the same set of
  skills Claude can invoke. This includes the bundled `/verify` skill, which Claude can't run on its own.
  [sub-agents › Preload skills into subagents](https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents)

## Colours

- Each subagent and parallel task is shown in one of eight named colors, so you can tell them apart in the
  transcript. The theme token names follow the pattern `<color>_FOR_SUBAGENTS_ONLY`, where `<color>` is one of the
  colors the `color` row lists. Overriding these tokens in a custom theme changes what each named color looks like:
  a subagent with `color: blue` in its definition is drawn using the `blue_FOR_SUBAGENTS_ONLY` value.
  [terminal-config › Create a custom theme](https://code.claude.com/docs/en/terminal-config#create-a-custom-theme)

## Not stated by the documentation

- How Claude Code chooses a subagent's display color when `color` is omitted.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- What Claude Code does with an invalid value of `color`, `effort` or `permissionMode`; the documentation covers only
  unrecognized field names.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

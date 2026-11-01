# Skill permissions

Granting and removing tools while a skill runs, and the permission rules and hooks that control which skills Claude
can invoke.

## Contents

- Pre-approving tools with `allowed-tools`
- Removing tools with `disallowed-tools`
- Workspace trust
- When only managed permission rules apply
- When managed settings lock hooks to plugins
- Allowing and denying skills with `Skill(...)` rules
- Hooks on skill invocation
- Not stated by the documentation

## Pre-approving tools with `allowed-tools`

- The `allowed-tools` field grants permission for the listed tools during the turn that invokes the skill, so Claude
  can use them without prompting you for approval. The grant clears when you send your next message, even though the
  skill content stays in context; invoking the skill again re-applies it for that turn.
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- `allowed-tools` does not restrict which tools are available: every tool remains callable, and your permission
  settings still govern tools that are not listed. To pre-approve tools for the whole session rather than a single
  turn, add allow rules to those permission settings instead.
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- Deny and ask rules still override `allowed-tools`. See
  [Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions).
  [skills › Permission checks on injected commands](https://code.claude.com/docs/en/skills#permission-checks-on-injected-commands)
- This skill lets Claude run git commands without per-use approval whenever you invoke it:
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)

  ```yaml
  ---
  name: commit
  description: Stage and commit the current changes
  disable-model-invocation: true
  allowed-tools: Bash(git add *) Bash(git commit *) Bash(git status *)
  ---
  ```

- A skill's `allowed-tools` frontmatter accepts the same rule format as permission rules, `ToolName(specifier)`. The
  specifier depends on the tool, and several tools share a format:
  [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)

  | Rule format | Applies to | Details |
  | :- | :- | :- |
  | `Bash(npm run *)` | Bash, Monitor | [Command pattern matching](https://code.claude.com/docs/en/permissions#bash) |
  | `PowerShell(Get-ChildItem *)` | PowerShell | [Command pattern matching](https://code.claude.com/docs/en/permissions#powershell) |
  | `Read(~/secrets/**)` | Read, Grep, Glob, LSP | [Path pattern matching](https://code.claude.com/docs/en/permissions#read-and-edit) |
  | `Edit(/src/**)` | Edit, Write, NotebookEdit | [Path pattern matching](https://code.claude.com/docs/en/permissions#read-and-edit) |
  | `Skill(deploy *)` | Skill | [Skill name matching](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access) |
  | `Agent(Explore)` | Agent | [Subagent type matching](https://code.claude.com/docs/en/permissions#agent-subagents) |
  | `WebFetch(domain:example.com)` | WebFetch | [Domain matching](https://code.claude.com/docs/en/permissions#webfetch) |
  | `WebSearch` | WebSearch | No specifier; allow or deny the tool as a whole |

- Tools not listed in that table, such as `ExitPlanMode` or `ShareOnboardingGuide`, accept only the bare tool name
  with no specifier.
  [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)
- For a tool from a plugin-bundled MCP server, a skill's `allowed-tools` list uses the tool's full name,
  `mcp__plugin_<plugin-name>_<server-name>__<tool-name>`, where any character outside `A-Z`, `a-z`, `0-9`, `_`, and
  `-` is replaced with `_`.
  [mcp › Plugin-provided MCP servers](https://code.claude.com/docs/en/mcp#plugin-provided-mcp-servers)

## Removing tools with `disallowed-tools`

- To remove tools from Claude's available pool while a skill is active, list them in `disallowed-tools` in the
  skill's frontmatter. The restriction clears when you send your next message. Like deny rules, the field can't
  remove `EndConversation` while any other tool remains.
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- To block tools across all skills and prompts, add deny rules in your permission settings.
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)

## Workspace trust

- Workspace trust doesn't gate `allowed-tools`. Claude Code applies a project skill's `allowed-tools` even in a `-p`
  run in a folder you've never trusted, and also when you trusted only a parent folder: workspace trust never gates a
  skill's `allowed-tools` in any session. A skill can grant itself broad tool access, so review the `allowed-tools` of
  skills checked into a repository before you run Claude Code there.
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)

## When only managed permission rules apply

- When `allowManagedPermissionRulesOnly` is set, Claude Code ignores `allow`, `ask`, and `deny` rules in user,
  project, local, and `--settings` files. `Skill(...)` rules are
  [permission rules](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access), so those in
  these files have no effect. It also ignores `--allowedTools`, hides the always-allow choices in permission
  prompts, and stops saving new rules. `--disallowedTools` rules and the current session's `deny` and `ask` rules
  still apply.
  [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)
- When your organization sets `allowManagedPermissionRulesOnly` in managed settings, Claude Code ignores the
  `allowed-tools` frontmatter in skills and `.claude/commands/` files from these sources:
  [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
  - A repository's `.claude/` directory
  - Your `~/.claude/skills/` and `~/.claude/commands/` directories, including skills synced from claude.ai
  - An `--add-dir` directory
  - Plugins declared with a `.claude-plugin` manifest inside `~/.claude/skills/` or the project's `.claude/skills/`
  - Plugins loaded for one session only, whose ids end in `@inline`, when all of these hold:
    - The session is a Code session or Cowork session, other than a cloud session, for which the Claude Desktop app
      itself starts Claude Code
    - Your managed settings set the key, not only an embedding host's parent settings
- Skills from managed settings and bundled skills keep their `allowed-tools`. `@inline` plugins outside those Desktop
  sessions keep theirs too, except one named `anthropic-skills`. A skill's `disallowed-tools` still applies.
  [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
- The tools an affected skill lists go through your organization's managed rules and the normal permission prompt
  instead. Run `/status` to list each skill whose `allowed-tools` Claude Code has ignored so far in the session.
  [skills › When only managed permission rules apply](https://code.claude.com/docs/en/skills#when-only-managed-permission-rules-apply)

## When managed settings lock hooks to plugins

- When your organization's managed settings list `hooks` in `strictPluginOnlyCustomization`, a personal or project
  skill whose frontmatter declares `hooks` loses its `allowed-tools` pre-approval, so your users get permission
  prompts for the tools that field lists. When such a skill runs in a subagent through `context: fork`, it keeps the
  pre-approval. A skill that declares no `hooks` keeps its pre-approval too.
  [skills › When managed settings lock hooks to plugins](https://code.claude.com/docs/en/skills#when-managed-settings-lock-hooks-to-plugins)
  [settings-reference › `strictPluginOnlyCustomization.hooks`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-hooks)
- To restore the pre-approval for a personal or project skill under that setting, remove `hooks` from the skill's
  frontmatter, because its hooks don't run under that setting.
  [skills › When managed settings lock hooks to plugins](https://code.claude.com/docs/en/skills#when-managed-settings-lock-hooks-to-plugins)

## Allowing and denying skills with `Skill(...)` rules

- A few built-in commands are also available through the Skill tool, including `/init` and `/security-review`.
  Other built-in commands such as `/compact` are not.
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)
- **Disable all skills** by denying the Skill tool in `/permissions`, with the deny rule `Skill`.
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)
- **Allow or deny specific skills** using permission rules. Permission syntax: `Skill(name)` for exact match,
  `Skill(name *)` for prefix match with any arguments.
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)

  ```text
  # Allow only specific skills
  Skill(commit)
  Skill(review-pr *)

  # Deny specific skills
  Skill(deploy *)
  ```

- What a `deny` rule blocks beyond the name you write, by the kind of name in the rule:
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)

  | Your `deny` rule names | Example rule | Claude Code also blocks |
  | :- | :- | :- |
  | An alias | `Skill(review)` | The bundled `/code-review`, through its `/review` alias |
  | An unqualified name | `Skill(deploy)` | A [nested skill](https://code.claude.com/docs/en/skills#where-skills-live) listed as `apps/web:deploy` |
  | A [skill synced from claude.ai](https://code.claude.com/docs/en/skills#how-synced-skills-behave) | `Skill(anthropic-skills:deploy)` | That skill when Claude Desktop delivers it to a session as a plugin |
  | The plugin form of a synced skill | `Skill(deploy:deploy)` | The synced skill |
  | A skill in the [parameter form](https://code.claude.com/docs/en/permissions#match-by-input-parameter) | `Skill(skill:deploy)` | The skill whichever of its names Claude calls it by, including its alias and display name |

- Deny and ask rules can match a top-level input parameter on any built-in tool with `Tool(param:value)`, such as the
  parameter form `Skill(skill:deploy)`; allow rules continue to use each tool's own
  specifier syntax. The value supports `*` as a wildcard that matches any sequence of characters; without `*` the
  match is exact.
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- Claude Code matches an `allow` rule only against the skill's own name and the name in Claude's invocation. To
  approve a synced skill without a prompt, name it inside its reserved namespace:
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)
  - `Skill(anthropic-skills:pdf)` approves the synced `pdf` skill
  - `Skill(anthropic-skills *)` approves every synced skill
  - `Skill(anthropic *)` doesn't cover `anthropic-skills:pdf`, because a prefix outside the namespace doesn't match
    the names inside it

## Hooks on skill invocation

- A `PreToolUse` hook matching the `Skill` tool fires only when Claude calls the tool, but typing `/skillname`
  directly bypasses `PreToolUse`. `UserPromptExpansion` fires on that direct path. It matches on `command_name`;
  leave the matcher empty to fire on every prompt-type command. For example, a hook matching `deploy` can block
  `/deploy` unless an approval file is present, or a hook matching a review skill can append the team's review
  checklist as `additionalContext`. It can also inject context for a particular skill.
  [hooks › UserPromptExpansion](https://code.claude.com/docs/en/hooks#userpromptexpansion)
- When the prompt is a skill or custom command you typed, such as `/deploy staging`, a `UserPromptSubmit` hook
  receives that line as you typed it rather than the expanded skill content. If the hook blocks the prompt, the
  command doesn't run, so shell commands the skill injects with `` !`<command>` `` don't run either. To match on the
  command's name or arguments instead, use `UserPromptExpansion`.
  [hooks › UserPromptSubmit input](https://code.claude.com/docs/en/hooks#userpromptsubmit-input)
- `UserPromptExpansion` hooks receive `expansion_type` and `command_name` in addition to the common input fields.
  `expansion_type` is `slash_command` for skill and custom commands.
  [hooks › UserPromptExpansion input](https://code.claude.com/docs/en/hooks#userpromptexpansion-input)
- In a `UserPromptExpansion` hook's output, `"decision": "block"` prevents the command from expanding, and `reason`
  is shown to the user. `additionalContext` is a string added to Claude's context alongside the expanded prompt.
  A hook that blocks by exiting 2 routes the same way as `reason`: the block message shows the stderr text to the
  user.
  [hooks › UserPromptExpansion decision control](https://code.claude.com/docs/en/hooks#userpromptexpansion-decision-control)

## Not stated by the documentation

- Stated for Claude invoking a skill through the Skill tool; the documentation does not say whether `Skill` deny
  rules stop you typing `/name` directly.
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access)

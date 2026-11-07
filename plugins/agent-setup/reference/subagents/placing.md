# Placing a subagent

Where a subagent definition lives and how it is identified.

## Contents

- Scopes and priority
- Project and user directories
- Plugin agents
- The `--agents` flag
- Managed subagents
- Directories added with `--add-dir`
- Worktrees and `/cd`
- Live reload and restarts
- `/agents`

## Scopes and priority

- Subagent files are stored in different locations depending on scope. When multiple subagents share the same name,
  Claude Code uses the one from the higher-priority location.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)

  | Location | Scope | Priority | How to create |
  | :- | :- | :- | :- |
  | Managed settings | Organization-wide | 1 (highest) | Deployed via [managed settings](https://code.claude.com/docs/en/settings) |
  | `--agents` CLI flag | Current session | 2 | Pass JSON when launching Claude Code |
  | `.claude/agents/` | Current project | 3 | Ask Claude, or create the file manually |
  | `~/.claude/agents/` | All your projects | 4 | Ask Claude, or create the file manually |
  | Plugin's `agents/` directory | Where plugin is enabled | 5 (lowest) | Installed with [plugins](https://code.claude.com/docs/en/plugins/overview) |

## Project and user directories

- Project subagents (`.claude/agents/`) are for subagents specific to a codebase; check them into version control so
  the team can use and improve them. User subagents (`~/.claude/agents/`) are personal subagents available in all
  your projects.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Project subagents are discovered by walking up from the current working directory, so every `.claude/agents/`
  between there and the repository root is scanned. When more than one of these nested directories defines the same
  `name`, Claude Code uses the definition closest to the working directory.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Claude Code scans `.claude/agents/` and `~/.claude/agents/` recursively, so definitions can sit in subfolders such
  as `agents/review/`. The subdirectory path doesn't affect how a subagent is identified or invoked, because identity
  comes only from the `name` frontmatter field.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Keep `name` values unique across the whole tree. If two files under the same `.claude/agents/` directory,
  including its subfolders, declare the same name, Claude Code loads only one of them, chosen by filesystem read
  order rather than a documented precedence. The
  [`/doctor`](https://code.claude.com/docs/en/commands#all-commands) setup checkup reports files in the same
  directory that share a name and proposes renaming or removing all but one.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- To share subagents across projects without `--add-dir`, use `~/.claude/agents/` or a plugin.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)

## Plugin agents

- Each Markdown file under a plugin's `agents/` directory defines one subagent. It is named
  `<plugin>:<name>`, where `<name>` comes from the frontmatter `name` field, or from the file name when that field
  is missing. A user can invoke `my-plugin:security-reviewer` explicitly with `@agent-my-plugin:security-reviewer`.
  [plugins/components › Agents](https://code.claude.com/docs/en/plugins/components#agents)
- Plugin subagents load automatically alongside your custom subagents and appear in the @-mention typeahead under
  their scoped name.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Plugin `agents/` directories are scanned recursively. Unlike project and user scopes, a subfolder inside a
  plugin's `agents/` directory becomes part of the scoped identifier: a file at `agents/review/security.md` in
  plugin `my-plugin` registers as `my-plugin:review:security`.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- The scoped name joins the plugin name, each subfolder name, and the file name with colons. Two settings change
  it: frontmatter `name` replaces only the file name, so `name: audit` in `agents/review/security.md` loads as
  `my-plugin:review:audit`; and a file listed in the manifest `agents` field loads without subfolder names, so
  `"agents": "./custom/review/security.md"` loads as `my-plugin:security`.
  [plugins/components › Organize agents in subfolders](https://code.claude.com/docs/en/plugins/components#organize-agents-in-subfolders)
- The manifest `agents` field takes one path or an array of paths, and its entries must be `.md` files.
  [plugins/manifest-reference › Path-only fields](https://code.claude.com/docs/en/plugins/manifest-reference#path-only-fields)

  ```json
  { "agents": ["./custom-agents/reviewer.md", "./custom-agents/tester.md"] }
  ```
- The manifest `agents` key replaces its default location: the default `agents/` directory is not scanned. When
  a plugin has a default `agents/` folder and the manifest sets `agents`,
  `claude plugin list` and `/plugin` show `Default <folder>/ folder is ignored because the manifest sets "<key>"`. To
  avoid the warning, set `agents` to `.md` files inside that folder.
  [plugins/manifest-reference › How each key combines with its default location](https://code.claude.com/docs/en/plugins/manifest-reference#how-each-key-combines-with-its-default-location)
- To use `mcpServers` or `permissionMode`, which plugin subagents ignore for security reasons, copy the agent file
  into `.claude/agents/` or `~/.claude/agents/`. You can also add rules to
  [`permissions.allow`](https://code.claude.com/docs/en/settings-reference#permissions-allow) in `settings.json` or
  `settings.local.json`, but these rules apply to the entire session, not only the plugin subagent. A plugin's
  author ships MCP servers in the plugin's
  [`.mcp.json`](https://code.claude.com/docs/en/plugins/components#mcp-servers) instead; they apply whenever the
  plugin is enabled rather than only inside the subagent.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- When you convert a `.claude/` setup into a plugin, the originals stay loaded alongside the plugin's copies, and
  Claude sees `reviewer` and `my-plugin:reviewer` as two subagents.
  [plugins/create › Convert an existing `.claude/` setup](https://code.claude.com/docs/en/plugins/create#convert-an-existing-claude-setup)

## The `--agents` flag

- CLI-defined subagents are passed as JSON when launching Claude Code. They exist only for that session and aren't
  saved to disk. Several can be defined in one `--agents` call.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)

  ```bash
  claude --agents '{
    "code-reviewer": {
      "description": "Expert code reviewer. Use proactively after code changes.",
      "prompt": "You are a senior code reviewer. Focus on code quality, security, and best practices.",
      "tools": ["Read", "Grep", "Glob", "Bash"],
      "model": "sonnet"
    }
  }'
  ```
- In PowerShell, pass the JSON as a here-string: `claude --agents @'` on its own line, the JSON, then `'@` on its
  own line.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- In [non-interactive mode](https://code.claude.com/docs/en/headless), `--agents` also accepts the path to a JSON
  file holding the same object, for definitions too large to pass on the command line, such as
  `claude -p --agents ./agents.json "Review my changes"`. In an interactive session, Claude Code refuses a file
  path.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Each top-level key in the JSON is an agent's name, and its value is that agent's definition. Don't start a name
  with `-`.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- A definition takes `prompt`, the agent's system prompt, equivalent to the markdown body in file-based subagents.
  `prompt` may be empty. If you select an agent with an empty `prompt` and no `memory` field as the session's agent
  with `--agent`, the session's system prompt is left unchanged.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- A definition also takes these [frontmatter fields](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields):
  `description`, `tools`, `disallowedTools`, `model`, `permissionMode`, `mcpServers`, `maxTurns`,
  `autoCompactWindow`, `skills`, `initialPrompt`, `memory`, `effort`, `background`, `omitClaudeMd`, and `isolation`.
  `color` and `experimental` aren't accepted here and are ignored rather than rejected.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)

## Managed subagents

- Organization administrators deploy managed subagents as markdown files in `.claude/agents/` inside the
  [managed settings directory](https://code.claude.com/docs/en/managed-settings#delivery-mechanisms), using the same
  frontmatter format as project and user subagents. Managed definitions take precedence over project and user
  subagents with the same name.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)

## Directories added with `--add-dir`

- When you add a directory with `--add-dir` or `/add-dir`, Claude Code also loads its `.claude/agents/` folder,
  alongside your project subagents; a directory listed only in `permissions.additionalDirectories` doesn't.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Subagents from any flag-added directory load through the `project`
  [setting source](https://code.claude.com/docs/en/agent-sdk/claude-code-features#control-filesystem-settings-with-settingsources),
  so they don't load when you exclude that source with `--setting-sources` on the CLI. Bare mode skips the
  subagents among them.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- For directories added with `--add-dir` or `/add-dir`, subagents are loaded without live reload:
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)

  | Configuration | Loaded from `--add-dir` |
  | :- | :- |
  | [Subagents](https://code.claude.com/docs/en/sub-agents) in `.claude/agents/` | Yes, without live reload |
- To load the subagents from a subdirectory of your primary working directory mid-session, run `/add-dir` with that
  subdirectory's path. Claude Code loads them for the rest of the session without prompting you or adding a working
  directory, because the subdirectory is already readable.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)

## Worktrees and `/cd`

- When the worktree checkout has no `.claude/skills` directory at its root, for example because it is gitignored,
  the read-through that loads the main checkout's project skills in the worktree session also covers
  `.claude/agents`. In a worktree with its own `.claude/skills` directory, only that copy loads for skills.
  [worktrees › What worktrees share with the main checkout](https://code.claude.com/docs/en/worktrees#what-worktrees-share-with-the-main-checkout)
- `/cd <path>` moves the session to a different primary working directory, and as soon as you move, Claude Code
  applies the new directory's project configuration, including its subagents.
  [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)

## Live reload and restarts

- Claude Code watches `~/.claude/agents/` and `.claude/agents/`. When you add or edit a subagent file on disk, or
  ask Claude to write one, it detects the change within a few seconds and the next delegation uses the updated
  definition, with no restart needed.
  [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)
- Three cases still need a restart. The watcher covers only directories that existed when the session started, so
  after creating a scope's first agent file in a new `agents` directory, restart to load it. Claude Code doesn't
  watch `.claude/agents/` inside directories added with `--add-dir` or `/add-dir`, so after adding or editing a
  subagent there, restart to load the change. Sessions started with `--disable-slash-commands` don't watch these
  directories at all.
  [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)

## `/agents`

- Running `/agents` prints a reminder to ask Claude or edit `.claude/agents/` and `~/.claude/agents/` directly.
  [sub-agents › Quickstart: create your first subagent](https://code.claude.com/docs/en/sub-agents#quickstart-create-your-first-subagent)
- Despite the similar name, `/agents` is separate from `claude agents`.
  [agents › Check on running work](https://code.claude.com/docs/en/agents#check-on-running-work)
- If `claude agents` prints a count followed by your configured subagents and then exits, agent view is unavailable in
  your environment; run `claude update`.
  [agent-view › `claude agents` lists subagents instead of opening agent view](https://code.claude.com/docs/en/agent-view#claude-agents-lists-subagents-instead-of-opening-agent-view)

## Not stated by the documentation

- The read-through of the main checkout's `.claude/agents` is stated as covering the same case as skills, a
  worktree with no `.claude/skills` at its root; the documentation does not say whether a worktree with its own
  `.claude/agents` but no `.claude/skills` loads the main checkout's agents.
  [worktrees › What worktrees share with the main checkout](https://code.claude.com/docs/en/worktrees#what-worktrees-share-with-the-main-checkout)

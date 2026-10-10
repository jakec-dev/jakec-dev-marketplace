# Excluding instruction files

Stopping instruction files from loading: `claudeMdExcludes`, `--setting-sources` without `project`, the
`managed-only` Project instructions value, `--bare`, `CLAUDE_CODE_SIMPLE` and `CLAUDE_CODE_DISABLE_CLAUDE_MDS`.

## Contents

- [`claudeMdExcludes`](#claudemdexcludes)
- [`--setting-sources`](#--setting-sources)
- [`managed-only`](#managed-only)
- [`--bare`](#--bare)
- [`CLAUDE_CODE_DISABLE_CLAUDE_MDS`](#claude_code_disable_claude_mds)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## `claudeMdExcludes`

- The `claudeMdExcludes` setting skips specific CLAUDE.md files by path or glob pattern, so they never load. Its
  type is an array of strings, each a glob pattern or absolute path; by default it is unset, so Claude Code loads
  every CLAUDE.md it finds.
  [settings-reference › `claudeMdExcludes`](https://code.claude.com/docs/en/settings-reference#claudemdexcludes),
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- Patterns are matched against absolute file paths using glob syntax, so start relative-style patterns with `**/` to
  match anywhere in the tree.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- A pattern can exclude rules files as well as CLAUDE.md files. This example excludes a top-level CLAUDE.md and a
  rules directory from a parent folder:
  [memory › Exclude specific CLAUDE.md files](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files)

  ```json
  {
    "claudeMdExcludes": [
      "**/monorepo/CLAUDE.md",
      "/home/user/monorepo/other-team/.claude/rules/**"
    ]
  }
  ```

- `"**/packages/web/**"` skips every CLAUDE.md and rules file under that package, while the root CLAUDE.md and the
  packages you work in still load normally. Other common patterns:
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
  - `"**/packages/*/CLAUDE.md"`: excludes every package's CLAUDE.md while keeping the root
  - `"**/packages/legacy-*/**"`: excludes every package whose name matches the glob, including rules
  - `"/home/user/monorepo/legacy/CLAUDE.md"`: excludes one specific file by absolute path
- To exclude a rules file you reach through a symlink, whether the file or its directory is the link, write the
  pattern against either the file's path under `.claude/rules/` or its link target; a pattern that matches either
  path excludes the file.
  [memory › Exclude specific CLAUDE.md files](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files)
- `claudeMdExcludes` can be set at any [settings scope](https://code.claude.com/docs/en/settings#where-settings-live):
  user, project, local, or managed. Arrays merge across scopes, so a team can set project-level defaults while
  individuals add local overrides.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files),
  [memory › Exclude specific CLAUDE.md files](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files)
- To keep the exclusion local to your machine, put it in `.claude/settings.local.json`. Claude Code adds that file
  to your global gitignore when it saves a setting there; if you create the file by hand, add it to your gitignore
  yourself.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- The exclusion list is static, not a per-task switch: use it for directories you never work in, such as other
  teams' packages, legacy code, or vendored subtrees. To focus on one package today and another tomorrow, start
  Claude from that package's directory instead of editing exclusions.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- Exclusions apply only to user, project, and local memory files; managed policy CLAUDE.md files can't be
  excluded, so organization-wide instructions always apply regardless of individual settings.
  [settings-reference › `claudeMdExcludes`](https://code.claude.com/docs/en/settings-reference#claudemdexcludes),
  [memory › Exclude specific CLAUDE.md files](https://code.claude.com/docs/en/memory#exclude-specific-claude-md-files)

## `--setting-sources`

- The flag:
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

  | Flag | Description | Example |
  | :- | :- | :- |
  | `--setting-sources` | Comma-separated list of setting sources to load (`user`, `project`, `local`). See [agent view](https://code.claude.com/docs/en/agent-view#what-carries-over-when-you-background) and [agent teams](https://code.claude.com/docs/en/agent-teams#context-and-communication) for the sessions you start from this one that inherit the list | `claude --setting-sources user,project` |

- Project rules are skipped if you exclude `project` from `--setting-sources`, including rules that load on demand,
  such as path-scoped rules and rules in nested `.claude/rules/` directories.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

## `managed-only`

- Set **Project instructions** in `/config` to `managed-only`, or set it under `pluginConfigs`, which Claude Code
  ignores in project and local settings files.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

  | Value | What Claude reads |
  | :- | :- |
  | `managed-only` | Only your organization's managed `CLAUDE.md` and [auto memory](https://code.claude.com/docs/en/memory#auto-memory) at launch. Your project, local, and user `CLAUDE.md` files, your `.claude/rules/` files, and every `AGENTS.md` are left out. A subdirectory's `CLAUDE.md` and `.claude/rules/` files, and [path-scoped rules](https://code.claude.com/docs/en/memory#path-specific-rules), still load when Claude reads a file there |

## `--bare`

- `--bare` skips auto-discovery of hooks, skills, custom commands, subagents, installed plugins, MCP servers, auto
  memory, and CLAUDE.md, to reduce startup time; it doesn't stop the built-in mod that loads `AGENTS.md`.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode),
  [plugins/mods/overview › Mods built into Claude Code](https://code.claude.com/docs/en/plugins/mods/overview#mods-built-into-claude-code)
- Setting `CLAUDE_CODE_SIMPLE` to `1` is equivalent to passing `--bare`; it disables auto-discovery of CLAUDE.md,
  among others.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## `CLAUDE_CODE_DISABLE_CLAUDE_MDS`

- Set `CLAUDE_CODE_DISABLE_CLAUDE_MDS` to `1` to prevent loading any CLAUDE.md memory files into context,
  including user, project, and auto memory files.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Not stated by the documentation

- `--bare` doesn't stop the built-in mod that loads `AGENTS.md`; the documentation does not say whether `AGENTS.md`
  is read under `--bare` or `CLAUDE_CODE_SIMPLE`, or whether a `CLAUDE.md` that bare mode skips still counts for the
  check that stops Claude reading `AGENTS.md`.
  [plugins/mods/overview › Mods built into Claude Code](https://code.claude.com/docs/en/plugins/mods/overview#mods-built-into-claude-code)
- Under `managed-only` no rules file loads at launch; the documentation does not say whether path-scoped rules in
  `~/.claude/rules/` still load when Claude reads a matching file.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)
- Stated for `project`; the documentation does not say whether excluding `user` from `--setting-sources` skips
  `~/.claude/rules/`. An Agent SDK page loads `~/.claude/rules/*.md` only when its `settingSources` includes
  `"user"`, for its own surface.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- Stated for CLAUDE.md; the documentation does not say whether `--bare` or `CLAUDE_CODE_SIMPLE` also skips
  `.claude/rules/` files.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- Stated for "any CLAUDE.md memory files"; the documentation does not say whether `CLAUDE_CODE_DISABLE_CLAUDE_MDS`
  also stops `.claude/rules/` files or `AGENTS.md`, or whether "any" reaches a managed policy CLAUDE.md. An Agent SDK
  page lists it as the way to turn off "Every CLAUDE.md file", for its own surface.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables),
  [agent-sdk/modifying-system-prompts › Turn off the context your agent replaces](https://code.claude.com/docs/en/agent-sdk/modifying-system-prompts#turn-off-the-context-your-agent-replaces)
- Stated for project rules and, in an added directory, for `CLAUDE.local.md` (skipped if you exclude `local`); the
  documentation does not say whether excluding `project`, `local` or `user` from `--setting-sources` skips
  `./CLAUDE.md`, `CLAUDE.local.md` or `~/.claude/CLAUDE.md`. An Agent SDK page loads each level only when its
  `settingSources` includes `"project"`, `"local"` or `"user"`, for its own surface.
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories),
  [agent-sdk/claude-code-features › CLAUDE.md load locations](https://code.claude.com/docs/en/agent-sdk/claude-code-features#claude-md-load-locations)

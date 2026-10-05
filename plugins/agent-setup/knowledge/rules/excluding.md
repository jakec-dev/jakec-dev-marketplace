# Excluding rules

Stopping rule files from loading: `claudeMdExcludes`, `--setting-sources` without `project`, and the `managed-only`
Project instructions value.

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
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- To keep the exclusion local to your machine, put it in `.claude/settings.local.json`. Claude Code adds that file
  to your global gitignore when it saves a setting there; if you create the file by hand, add it to your gitignore
  yourself.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- The exclusion list is static, not a per-task switch: use it for directories you never work in, such as other
  teams' packages, legacy code, or vendored subtrees. To focus on one package today and another tomorrow, start
  Claude from that package's directory instead of editing exclusions.
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)
- Exclusions apply only to user, project, and local memory files; managed policy CLAUDE.md files can't be
  excluded, so organization-wide instructions always apply.
  [settings-reference › `claudeMdExcludes`](https://code.claude.com/docs/en/settings-reference#claudemdexcludes),
  [large-codebases › Exclude irrelevant CLAUDE.md files](https://code.claude.com/docs/en/large-codebases#exclude-irrelevant-claude-md-files)

## `--setting-sources`

- Project rules are skipped if you exclude `project` from
  [`--setting-sources`](https://code.claude.com/docs/en/cli-reference), including rules that load on demand, such
  as path-scoped rules and rules in nested `.claude/rules/` directories.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

## `managed-only`

- To change which instruction files Claude reads, run `/config` in a session and set **Project instructions**:
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

  | Value | What Claude reads |
  | :- | :- |
  | `managed-only` | Only your organization's managed `CLAUDE.md` and [auto memory](https://code.claude.com/docs/en/memory#auto-memory) at launch. Your project, local, and user `CLAUDE.md` files, your `.claude/rules/` files, and every `AGENTS.md` are left out. A subdirectory's `CLAUDE.md` and `.claude/rules/` files, and [path-scoped rules](https://code.claude.com/docs/en/memory#path-specific-rules), still load when Claude reads a file there |

- The value can also be set in a settings file, under the built-in `agents-md` plugin's ID in
  [`pluginConfigs`](https://code.claude.com/docs/en/settings-reference#pluginconfigs), in `~/.claude/settings.json`,
  a `--settings` file, or [managed settings](https://code.claude.com/docs/en/managed-settings). Claude Code ignores
  it in project and local settings files. This example, the documentation's, sets `claude-md-and-agents-md`;
  `managed-only` goes in the same `instructionFiles` field:
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

  ```json
  {
    "pluginConfigs": {
      "agents-md@builtin": {
        "options": { "instructionFiles": "claude-md-and-agents-md" }
      }
    }
  }
  ```

- The change applies from the next message you send and in every new session.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

## Not stated by the documentation

- Under `managed-only` no rules file loads at launch; the documentation does not say whether path-scoped rules in
  `~/.claude/rules/` still load when Claude reads a matching file.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)
- Stated for `project`; the documentation does not say whether excluding `user` from `--setting-sources` skips
  `~/.claude/rules/`. An Agent SDK page loads `~/.claude/rules/*.md` only when its `settingSources` includes
  `"user"`, for its own surface.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

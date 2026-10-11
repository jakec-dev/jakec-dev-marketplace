# Instructions

Instruction files are the markdown files Claude Code loads as instructions: CLAUDE.md, `.claude/CLAUDE.md`,
`CLAUDE.local.md`, `AGENTS.md`, the files they import, and rules in `.claude/rules/` or `~/.claude/rules/`. Read the
key facts first; they are what models most often get wrong. Then read only the sections your task needs.

## Key facts

- By default a `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` in the working directory or above it stops Claude
  reading `AGENTS.md`, unless that `CLAUDE.md` imports `@AGENTS.md`; `~/.claude/CLAUDE.md`, the managed CLAUDE.md
  and `.claude/rules/` don't count.
  See [agents-md.md › When Claude reads AGENTS.md](agents-md.md).
- **Project instructions** set under `pluginConfigs` in project or local settings files is ignored; it belongs in
  `~/.claude/settings.json`, a `--settings` file or managed settings.
  See [agents-md.md › Project instructions setting](agents-md.md).
- `claudeMd` is honoured in managed and policy settings only; setting it in user, project or local settings has no
  effect.
  See [placing.md › Organization-wide instructions](placing.md).
- An import path containing spaces needs a backslash before each space; a path wrapped in quotes isn't imported.
  See [writing.md › Imports](writing.md).
- Editing a project-root or user-level CLAUDE.md mid-session doesn't apply until the next `/clear`, `/compact` or
  restart.
  See [loading.md › Mid-session edits](loading.md).
- A personal rule for every project goes in `~/.claude/rules/`, not the project's `.claude/rules/`.
  See [placing.md › User-level rules](placing.md).
- A `.claude/rules/` symlink whose target is outside the working directory is treated like an external import: its
  rules don't load until external imports are approved, and then only the ones without `paths` load; the approval
  prompt appears only when a project memory file imports a file outside the working directory with `@path`, never
  for symlinks alone.
  See [sharing.md › Symlinks](sharing.md).
- A literal `[` in a `paths` pattern must be escaped, as in `photos \[2024/**`; a `[` that can't be read as a
  bracket expression makes the pattern invalid, so it matches nothing.
  See [scoping.md › Invalid patterns](scoping.md).
- `paths` is the only frontmatter field a rule reads, and any other field is ignored without an error. The opening
  `---` must be the file's first line; if the YAML doesn't parse, the rule loads as if it had no `paths`.
  See [scoping.md › The frontmatter](scoping.md).
- A rule without `paths` in the project's `.claude/rules/` loads at launch, with the same priority as
  `.claude/CLAUDE.md`; a path-scoped rule loads when Claude uses the Read, Write or Edit tool on a matching file, not
  on every tool use.
  See [loading.md › At launch and on file access](loading.md).
- If you or anyone who clones the repository works on Windows, a `CLAUDE.md` symlinked to `AGENTS.md` can check out
  as a one-line text file unless `core.symlinks` is enabled, leaving no instructions; use the `@AGENTS.md` import.
  See [agents-md.md › Import or symlink](agents-md.md).
- User-level rules load before project rules, and neither overrides the other: if they conflict, Claude may follow
  either.
  See [loading.md › At launch and on file access](loading.md).
- A `paths` list has one brace-expansion budget of 1,000 expanded patterns and 4 MiB; a pattern over it is used
  unexpanded and matches no files.
  See [scoping.md › Brace expansion budget](scoping.md).
- Compaction summarises path-scoped rules and nested CLAUDE.md files away with the rest of the conversation; a rule
  that must persist needs no `paths` or a place in the project-root CLAUDE.md.
  See [loading.md › After compaction](loading.md).
- A non-fork subagent starts with every level of CLAUDE.md files and project rules the main conversation loads; the
  built-in Explore and Plan agents skip them, and a subagent with `omitClaudeMd` loads only managed policy files, or
  none when its definition comes from managed settings.
  See [loading.md › In subagents](loading.md).
- CLAUDE.md files and rules in a directory added with `--add-dir` load only with
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` set; the `additionalDirectories` setting never loads them.
  See [sharing.md › Additional directories](sharing.md).
- `claudeMdExcludes` patterns match absolute paths, so start a relative-style pattern with `**/`; they can exclude
  rules files as well as CLAUDE.md files, but not a managed policy CLAUDE.md.
  See [excluding.md › `claudeMdExcludes`](excluding.md).
- Project rules are skipped if `project` is excluded from `--setting-sources`.
  See [excluding.md › `--setting-sources`](excluding.md).
- If two instructions contradict each other, Claude may pick one arbitrarily (memory); for CLAUDE.md files at
  different levels, features-overview says Claude uses judgment to reconcile them.
  See [writing.md › Contradicting instructions](writing.md).
- To see which CLAUDE.md and rules files loaded, run `/context`; to log when and why each loads, use the
  `InstructionsLoaded` hook.
  See [troubleshooting.md › Check whether it loaded](troubleshooting.md) and
  [troubleshooting.md › Log loads with the `InstructionsLoaded` hook](troubleshooting.md).

## Topics

- [placing.md](placing.md): deciding where an instruction file or rule goes and what it is called (managed, user,
  project `./CLAUDE.md` or `./.claude/CLAUDE.md`, per-directory files, `CLAUDE.local.md`, the managed `claudeMd`
  setting, project and user `.claude/rules/`)
  - Locations
  - Project CLAUDE.md
  - CLAUDE.local.md
  - Per-directory CLAUDE.md files
  - Organization-wide instructions
  - Project rules
  - User-level rules
  - Scope and committing
  - Not stated by the documentation

- [writing.md](writing.md): writing the body of a CLAUDE.md, `AGENTS.md` or rule file (`@path` imports, HTML comments,
  size and the 4 MiB limit, contradicting instructions, compaction instructions)
  - Format
  - Imports
  - HTML comments
  - Size
  - Contradicting instructions
  - Compaction instructions
  - Not stated by the documentation

- [scoping.md](scoping.md): limiting a rule to matching files with frontmatter: `paths`, glob patterns, brace expansion
  and its budget, invalid patterns
  - The frontmatter
  - Scoping with `paths`
  - Glob patterns
  - Brace expansion budget
  - Invalid patterns
  - Not stated by the documentation

- [loading.md](loading.md): knowing when each instruction file enters Claude's context and in what order: at launch, on
  file access, after compaction, after mid-session edits, and in subagents, worktrees, agent teams and the auto mode
  classifier
  - At launch and on file access
  - After compaction
  - Mid-session edits
  - In subagents
  - In agent teams
  - In the auto mode classifier
  - Not stated by the documentation

- [agents-md.md](agents-md.md): having Claude read `AGENTS.md`: which files stop it, the **Project instructions**
  values, when support is unavailable, how it differs from CLAUDE.md, earlier workarounds, and the import versus the
  symlink
  - When Claude reads AGENTS.md
  - Project instructions setting
  - When AGENTS.md support is unavailable
  - Where AGENTS.md differs from CLAUDE.md
  - Earlier workarounds
  - Import or symlink
  - Not stated by the documentation

- [sharing.md](sharing.md): making instructions reach more projects or directories (symlinks, home-directory imports and
  external-import approval, `--add-dir` and additional directories, sparse worktree checkouts)
  - Symlinks
  - Imports
  - Additional directories
  - Sparse worktree checkouts
  - Not stated by the documentation

- [excluding.md](excluding.md): stopping instruction files from loading (`claudeMdExcludes`, `--setting-sources`, the
  `managed-only` value, `--bare`, `CLAUDE_CODE_SIMPLE`, `CLAUDE_CODE_DISABLE_CLAUDE_MDS`)
  - `claudeMdExcludes`
  - `--setting-sources`
  - `managed-only`
  - `--bare`
  - `CLAUDE_CODE_DISABLE_CLAUDE_MDS`
  - Not stated by the documentation

- [creating.md](creating.md): starting or editing instruction files with Claude Code's commands (`/init`,
  `CLAUDE_CODE_NEW_INIT`, migrating from other tools, `/import`, `/memory`, the VS Code Customize menu)
  - Commands
  - Generate a CLAUDE.md with `/init`
  - The interactive flow: `CLAUDE_CODE_NEW_INIT`
  - Migrate from other tools
  - View and edit with `/memory`
  - Edit in VS Code
  - Not stated by the documentation

- [troubleshooting.md](troubleshooting.md): checking an instruction file that isn't taking effect: whether it loaded
  (`/context`, `InstructionsLoaded`), why it is ignored, and whether its content is sound (`/doctor`, `prompt-audit`,
  length warnings)
  - Check whether it loaded
  - Check why `AGENTS.md` isn't read
  - Log loads with the `InstructionsLoaded` hook
  - Why a loaded instruction is ignored
  - Test against a clean configuration
  - Audit and length warnings
  - Not stated by the documentation

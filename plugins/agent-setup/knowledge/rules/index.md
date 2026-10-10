# Rules

Rules are markdown files in `.claude/rules/` or `~/.claude/rules/` that Claude Code loads as instructions. Read the
key facts first; they are what models most often get wrong. Then read only the sections your task needs.

## Key facts

- A personal rule for every project goes in `~/.claude/rules/`, not the project's `.claude/rules/`.
  See [placing.md › User-level rules](placing.md).
- A `.claude/rules/` symlink whose target is outside the working directory is treated like an external import: its
  rules don't load until external imports are approved, and then only the ones without `paths` load.
  See [sharing.md › Symlinks](sharing.md).
- A literal `[` in a `paths` pattern must be escaped, as in `photos \[2024/**`; a `[` that can't be read as a
  bracket expression makes the pattern invalid, so it matches nothing.
  See [writing.md › Invalid patterns](writing.md).
- `paths` is the only frontmatter field a rule reads; any other field is ignored without an error.
  See [writing.md › The frontmatter](writing.md).
- The opening `---` must be the file's first line. If the YAML doesn't parse, the frontmatter is ignored and the rule
  loads as if it had no `paths`.
  See [writing.md › The frontmatter](writing.md).
- A path-scoped rule loads when Claude uses the Read, Write or Edit tool on a matching file, not on every tool use.
  See [loading.md › At launch and on file access](loading.md).
- Rules without `paths` load at launch, with the same priority as `.claude/CLAUDE.md`.
  See [loading.md › At launch and on file access](loading.md).
- User-level rules load before project rules, and neither overrides the other: if they conflict, Claude may follow
  either.
  See [loading.md › At launch and on file access](loading.md).
- A `paths` list has one brace-expansion budget of 1,000 patterns and 4 MiB; a pattern over it is used unexpanded and
  matches no files.
  See [writing.md › Brace expansion budget](writing.md).
- Compaction summarises path-scoped rules away with the rest of the conversation; a rule that must persist needs no
  `paths` or a place in the project-root CLAUDE.md.
  See [loading.md › After compaction](loading.md).
- A non-fork subagent starts with project rules; the built-in Explore and Plan agents skip them, and a subagent with
  `omitClaudeMd` loads only managed policy files.
  See [loading.md › In subagents](loading.md).
- Rules in a directory added with `--add-dir` load only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` set; the
  `additionalDirectories` setting never loads them.
  See [sharing.md › Additional directories](sharing.md).
- A `claudeMdExcludes` pattern can exclude rules files as well as CLAUDE.md files.
  See [excluding.md › `claudeMdExcludes`](excluding.md).
- Project rules are skipped if `project` is excluded from `--setting-sources`.
  See [excluding.md › `--setting-sources`](excluding.md).
- If two instructions contradict each other, Claude may pick one arbitrarily, so review `.claude/rules/` for
  conflicts.
  See [troubleshooting.md › Check the content](troubleshooting.md).
- To see which rules loaded, run `/context`; to log when and why each loads, use the `InstructionsLoaded` hook.
  See [troubleshooting.md › Check whether it loaded](troubleshooting.md) and
  [troubleshooting.md › Log loads with the `InstructionsLoaded` hook](troubleshooting.md).

## Topics

- [placing.md](placing.md): deciding where a rule file goes (project `.claude/rules/`, subdirectories,
  `~/.claude/rules/`) and naming it
  - Project rules
  - User-level rules
  - Scope and committing
  - Not stated by the documentation

- [writing.md](writing.md): writing a rule's frontmatter: `paths`, glob patterns, brace expansion and its budget,
  invalid patterns
  - The frontmatter
  - Scoping with `paths`
  - Glob patterns
  - Brace expansion budget
  - Invalid patterns
  - Not stated by the documentation

- [loading.md](loading.md): knowing when a rule enters Claude's context, in what order, and what happens after
  compaction, mid-session edits, in subagents and alongside `AGENTS.md`
  - At launch and on file access
  - After compaction
  - Mid-session edits
  - In subagents
  - Alongside AGENTS.md
  - Not stated by the documentation

- [sharing.md](sharing.md): making rules reach more projects or directories (symlinks, imports in `~/.claude/rules/`,
  `--add-dir` and additional directories, sparse worktree checkouts)
  - Symlinks
  - Imports
  - Additional directories
  - Sparse worktree checkouts
  - Not stated by the documentation

- [excluding.md](excluding.md): stopping rules from loading (`claudeMdExcludes`, `--setting-sources` without project,
  the `managed-only` Project instructions value)
  - `claudeMdExcludes`
  - `--setting-sources`
  - `managed-only`
  - Not stated by the documentation

- [troubleshooting.md](troubleshooting.md): checking a rule that isn't behaving as expected: whether it loaded and
  whether its content is sound (`/context`, `InstructionsLoaded`, `/doctor prompt-audit`, length warnings)
  - Check whether it loaded
  - Log loads with the `InstructionsLoaded` hook
  - Check the content
  - Audit and length warnings
  - Not stated by the documentation

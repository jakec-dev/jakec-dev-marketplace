# Instructions topics

- `placing.md`: deciding where an instruction file or rule goes and what it is called (managed, user, project
  `./CLAUDE.md` or `./.claude/CLAUDE.md`, per-directory files, `CLAUDE.local.md`, the managed `claudeMd` setting,
  project and user `.claude/rules/`)
- `writing.md`: writing the body of a CLAUDE.md, `AGENTS.md` or rule file (`@path` imports, HTML comments, size and
  the 4 MiB limit, contradicting instructions, compaction instructions)
- `scoping.md`: limiting a rule to matching files with frontmatter: `paths`, glob patterns, brace expansion and its
  budget, invalid patterns
- `loading.md`: knowing when each instruction file enters Claude's context and in what order: at launch, on file
  access, after compaction, after mid-session edits, and in subagents, worktrees, agent teams and the auto mode
  classifier
- `agents-md.md`: having Claude read `AGENTS.md`: which files stop it, the **Project instructions** values, when
  support is unavailable, how it differs from CLAUDE.md, earlier workarounds, and the import versus the symlink
- `sharing.md`: making instructions reach more projects or directories (symlinks, home-directory imports and
  external-import approval, `--add-dir` and additional directories, sparse worktree checkouts)
- `excluding.md`: stopping instruction files from loading (`claudeMdExcludes`, `--setting-sources`, the
  `managed-only` value, `--bare`, `CLAUDE_CODE_SIMPLE`, `CLAUDE_CODE_DISABLE_CLAUDE_MDS`)
- `creating.md`: starting or editing instruction files with Claude Code's commands (`/init`, `CLAUDE_CODE_NEW_INIT`,
  migrating from other tools, `/import`, `/memory`, the VS Code Customize menu)
- `troubleshooting.md`: checking an instruction file that isn't taking effect: whether it loaded (`/context`,
  `InstructionsLoaded`), why it is ignored, and whether its content is sound (`/doctor`, `prompt-audit`, length
  warnings)

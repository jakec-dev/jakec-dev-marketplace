# Rules topics

- `placing.md`: deciding where a rule file goes (project `.claude/rules/`, subdirectories, `~/.claude/rules/`) and
  naming it
- `writing.md`: writing a rule's frontmatter: `paths`, glob patterns, brace expansion and its budget, invalid patterns
- `loading.md`: knowing when a rule enters Claude's context, in what order, and what happens after compaction,
  mid-session edits, in subagents and under instruction-file settings
- `sharing.md`: making rules reach more projects or directories (symlinks, imports in `~/.claude/rules/`, `--add-dir`
  and additional directories, sparse worktree checkouts)
- `excluding.md`: stopping rules from loading (`claudeMdExcludes`)
- `troubleshooting.md`: checking a rule that isn't behaving as expected: whether it loaded and whether its content
  is sound (`/context`, `InstructionsLoaded`, `/doctor prompt-audit`, length warnings)

# Rules

Rules are markdown files in `.claude/rules/` or `~/.claude/rules/` that Claude Code loads as instructions. Open the
file for the task in hand.

- [placing.md](placing.md): where a rule file goes, project or user level, how to name it, and whether it is
  committed. Read when creating a rule file.
- [writing.md](writing.md): a rule's frontmatter, its `paths` glob patterns, brace expansion budget and invalid
  patterns. Read when scoping a rule to files.
- [loading.md](loading.md): when a rule enters Claude's context, in what order, and what happens after compaction,
  mid-session edits, in subagents and alongside `AGENTS.md`. Read when relying on a rule being in context.
- [sharing.md](sharing.md): making rules reach other projects and directories through symlinks, imports, additional
  directories and sparse worktrees. Read when reusing rules elsewhere.
- [excluding.md](excluding.md): stopping rules from loading with `claudeMdExcludes`, `--setting-sources` and the
  `managed-only` Project instructions value. Read when a rule should not apply.
- [troubleshooting.md](troubleshooting.md): checking whether a rule loaded, logging loads with `InstructionsLoaded`,
  and checking its content, audit and length warnings. Read when a rule isn't behaving as expected.

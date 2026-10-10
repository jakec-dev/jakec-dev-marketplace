---
type: llm
focus: trace
---

The instruction matters only for migration files, which are scattered across many directories. Claude Code's
documentation says an instruction that only matters for one part of the codebase belongs in a path-scoped rule
rather than CLAUDE.md, and that a path-scoped rule in `.claude/rules/` suits "the same rule applies to many
scattered paths", where per-directory CLAUDE.md files suit conventions each directory's owners maintain.

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write, or the content it
gave in its reply.

PASS if Claude wrote or proposed one rule in the project's .claude/rules/ whose `paths` frontmatter covers SQL files
under both packages/*/migrations/ and services/*/db/migrations/, such as "**/migrations/**/*.sql" or one pattern per
location, and whose body states the comment convention.

FAIL if the instruction went into a root CLAUDE.md, into CLAUDE.md files inside the migration directories, or into
a rule without `paths`, or if the patterns miss either location.

---
type: llm
focus: trace
---

The repository's project instructions are in AGENTS.md, and it has no CLAUDE.md. Claude Code's documentation says
Claude reads AGENTS.md as the project instructions only when there is no CLAUDE.md or CLAUDE.local.md in the working
directory or above it, and that a CLAUDE.md which imports AGENTS.md (an `@AGENTS.md` line) keeps it included.

Judge the files Claude wrote or edited, or the change it proposed in its reply.

PASS if the instruction was added to AGENTS.md, or to a CLAUDE.md that imports AGENTS.md with an `@AGENTS.md` line.
A path-scoped or unscoped rule in .claude/rules/ also passes, since rules keep loading alongside AGENTS.md.

FAIL if Claude created or proposed a CLAUDE.md, .claude/CLAUDE.md or CLAUDE.local.md that does not import
AGENTS.md, since Claude would then stop reading AGENTS.md. Also FAIL if Claude tells the user the repository has no
AGENTS.md, since that shows it never looked.

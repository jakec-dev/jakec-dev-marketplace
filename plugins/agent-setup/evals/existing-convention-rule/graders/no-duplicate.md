---
type: llm
focus: trace
---

The project's CLAUDE.md already says "Use pnpm, not npm". Claude Code's documentation says that when two
instructions conflict Claude may pick one arbitrarily, and to review CLAUDE.md files and `.claude/rules/` to remove
outdated or conflicting instructions.

Writes into .claude/ are denied by the test harness, so judge what Claude tried to write, and its reply.

PASS if Claude tells the user that CLAUDE.md already holds this instruction, and either adds no rule, or moves the
instruction into a rule and removes or proposes removing it from CLAUDE.md.

FAIL if Claude writes or proposes a pnpm rule while leaving the CLAUDE.md line in place without mentioning it.

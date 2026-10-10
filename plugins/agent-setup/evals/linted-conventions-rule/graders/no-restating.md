---
type: llm
focus: trace
---

The project's .prettierrc sets no semicolons, single quotes and 2-space indentation, and eslint.config.js enforces
no-var, prefer-const and eqeqeq. Claude Code's documentation says to leave out of instructions anything Claude can
figure out by reading code, and that the `/doctor` trim cuts content Claude can derive from the codebase, such as
directory layouts.

Writes into .claude/ are denied by the test harness, so judge the rule files Claude tried to write, or proposed in
its reply.

PASS if no rule restates a formatting or lint convention the configuration files already set, and no rule
describes the project's files or directory layout. A rule may point to the lint or format command.

FAIL if any rule restates one of those conventions, such as "no semicolons", "use single quotes", "2-space
indentation", "use const" or "use ===", or describes the directory layout.

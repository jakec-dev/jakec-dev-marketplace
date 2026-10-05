---
type: llm
focus: trace
---

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write: the path and content of
its Write tool call, or the file content it gave in its reply.

PASS if Claude wrote the rule as a Markdown file in the user-level rules directory ~/.claude/rules/ (under the home
directory), not in the project's .claude/rules/, with an instruction to answer in British English.

FAIL if the rule went into the project's .claude/rules/ or a CLAUDE.md file, or if no file was attempted.

---
type: llm
focus: trace
---

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write: the path and content of
its Write tool call, or the file content it gave in its reply.

PASS if Claude wrote the rule as a Markdown file in the user-level rules directory, not in the project's
.claude/rules/, with an instruction to answer in British English. The user-level directory is ~/.claude/rules/
under the home directory, or rules/ under the directory CLAUDE_CONFIG_DIR names when that variable is set, since it
moves every ~/.claude path; the test harness sets it.

FAIL if the rule went into the project's .claude/rules/ or a CLAUDE.md file, or if no file was attempted.

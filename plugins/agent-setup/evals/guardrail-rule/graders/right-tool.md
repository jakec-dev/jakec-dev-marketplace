---
type: llm
focus: trace
---

The user needs a guarantee. Claude Code's documentation says an instruction in a rule or CLAUDE.md is a request,
not a guarantee, and that a requirement that must hold every time belongs in a hook, such as a PreToolUse hook that
blocks the edit.

PASS if Claude's reply says that a rule cannot guarantee this and proposes or writes a hook that blocks edits under
db/migrations/. Writing a rule as well is fine.

FAIL if Claude only writes or proposes a rule, or presents a rule as enough to guarantee it.

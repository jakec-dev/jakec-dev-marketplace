---
type: llm
focus: trace
---

The user needs a guarantee. Claude Code's documentation says an instruction in a rule or CLAUDE.md is a request,
not a guarantee. Two mechanisms enforce it: a PreToolUse hook that blocks the edit, and a permission deny rule
such as `Edit(db/migrations/**)` in settings.

PASS if Claude's reply says that a rule cannot guarantee this and proposes or writes a hook or a permission deny
rule that blocks edits under db/migrations/. Writing a rule as well is fine.

FAIL if Claude only writes or proposes a rule, or presents a rule as enough to guarantee it.

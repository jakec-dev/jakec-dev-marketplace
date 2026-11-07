---
type: llm
---

PASS if the answer says that .claude/agents/reviewer.md and .claude/agents/review/reviewer.md both declare
`name: reviewer`, that Claude Code loads only one of two files with the same name in one agents directory tree,
chosen by filesystem read order rather than any documented precedence, and that the fix is to rename or remove one.
FAIL if it says the subfolder makes the names distinct, that the deeper or closer file wins by rule, or gives
another cause.

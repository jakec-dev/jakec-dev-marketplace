---
type: llm
---

Claude Code's documentation says that `/doctor` reports duplicate subagent names in the same directory, and that
`/context` lists custom subagents with the source each loaded from, so an answer that suggests either as a check is
correct on that point.

PASS if the answer says that .claude/agents/reviewer.md and .claude/agents/review/reviewer.md both declare
`name: reviewer`, that Claude Code loads only one of two files with the same name in one agents directory tree,
chosen by filesystem read order rather than any documented precedence, and that the fix is to rename or remove one.
FAIL if it says the subfolder makes the names distinct, that the deeper or closer file wins by rule, or gives
another cause.

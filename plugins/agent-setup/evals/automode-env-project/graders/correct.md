---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the reply says the classifier doesn't read `autoMode` from the project's settings files, and puts
the entry in `autoMode.environment` in a scope it reads, such as each developer's `~/.claude/settings.json` or managed
settings, keeping `"$defaults"` in the list.
FAIL if it writes `autoMode` into `.claude/settings.json` as the fix, or writes an `environment` list without
`"$defaults"`.

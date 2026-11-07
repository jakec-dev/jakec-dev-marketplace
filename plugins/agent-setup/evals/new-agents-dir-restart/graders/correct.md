---
type: llm
---

PASS if the answer says that Claude Code watches only agents directories that existed when the session started, so
the first file in a newly created `.claude/agents/` directory needs a restart of Claude Code to load.
FAIL if it blames the file's contents without mentioning the restart, or says no restart is ever needed.

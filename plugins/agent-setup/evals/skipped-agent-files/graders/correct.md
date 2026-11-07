---
type: llm
---

PASS if the answer finds both causes: the `name` in security.md contains `:`, which subagent names can't contain
(it is reserved for plugin-scoped names), and docs-writer.md has no `description`, which is required. Each makes
Claude Code skip the file without reporting it in the session.
FAIL if it misses either cause, or blames the file names, the folder or something else.

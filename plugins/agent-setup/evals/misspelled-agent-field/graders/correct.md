---
type: llm
---

PASS if the answer says that `disallowed_tools` is not a field Claude Code recognises, because frontmatter field names
are camelCase, so the field must be written `disallowedTools`, and that Claude Code ignores an unrecognised field
without reporting an error.
FAIL if it gives another cause, such as a permission mode or the tool list syntax, or doesn't name `disallowedTools`.

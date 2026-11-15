---
type: llm
---

Claude Code's documentation says that a subagent's `tools` field is an allowlist and `disallowedTools` a denylist, so
either can keep the subagent from editing, and that `claude --debug` logs `does not recognize or apply` for a
frontmatter field Claude Code ignores, so an answer that suggests that check is correct on that point.

PASS if the answer says that `disallowed_tools` is not a field Claude Code recognises, because frontmatter field names
are camelCase, so the field must be written `disallowedTools`, and that Claude Code ignores an unrecognised field
without reporting an error. A fix that uses a `tools` list leaving out Edit and Write instead of `disallowedTools` also
passes, as long as the answer names `disallowedTools` as the field's correct spelling.
FAIL if it gives another cause, such as a permission mode or the tool list syntax, or doesn't name `disallowedTools`.

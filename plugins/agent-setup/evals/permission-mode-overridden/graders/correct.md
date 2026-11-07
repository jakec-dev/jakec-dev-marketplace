---
type: llm
---

PASS if the answer says that while the main conversation is in auto mode (as also in `acceptEdits` or
`bypassPermissions`), the subagent runs in that same mode and its `permissionMode` is ignored, and recommends
enforcing read-only through the tools the subagent gets, such as a `tools` list without Edit and Write or
`disallowedTools: Edit, Write`.
FAIL if it says plan mode should have held, blames something else, or offers no tool-based fix.

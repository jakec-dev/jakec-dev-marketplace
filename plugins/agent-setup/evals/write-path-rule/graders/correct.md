---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the deny rule is an `Edit` rule for the directory, such as `Edit(./src/generated/**)` or
`Edit(src/generated/**)`, and the reply says a `Write` path rule never matches.
FAIL if it adds `Write(./src/generated/**)` or another `Write` path rule as the fix.

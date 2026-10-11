---
type: llm
focus: trace
---

Claude Code's documentation says to write instructions concrete enough to verify, such as "Run `npm test` before
committing" instead of "Test your changes", and to leave out self-evident practices like "write clean code".

PASS if Claude either points out that the instruction is too vague or self-evident to help and asks for, or
suggests, specific checkable conventions; or writes a rule whose every instruction is specific enough that a reader
could tell whether it was followed.

FAIL if the rule Claude writes or proposes consists of general advice such as "write clean, readable tests" or
"test edge cases thoroughly" without any specific convention.

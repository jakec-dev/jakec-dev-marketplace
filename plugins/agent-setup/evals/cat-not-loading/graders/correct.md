---
type: llm
---

PASS if the answer explains that a path-scoped rule loads only when Claude uses the Read, Write or Edit tool on a
matching file, so reading the file through a shell command such as cat does not load it, and suggests a fix such
as reading the file with the Read tool or removing the paths field so the rule loads every session.
FAIL if it blames the glob, says the rule should load on any access, or gives no cause.

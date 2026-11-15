---
type: llm
---

PASS if the answer explains that a path-scoped rule loads when Claude uses the Read, Write or Edit tool on a matching
file, or views it with a Bash command that counts as a read, such as `cat` on one file with no pipes or redirects, so a
`cat` with a pipe, a redirect or more than one file does not load it, and suggests a fix such as reading the file with
the Read tool or removing the paths field so the rule loads every session.
FAIL if it says `cat` never loads the rule, blames the glob, says the rule should load on any access, or gives no
cause.

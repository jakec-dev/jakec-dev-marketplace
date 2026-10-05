---
type: llm
focus: trace
---

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write: the path and content of
its Write tool call, or the file content it gave in its reply.

PASS if Claude wrote a rule in the project's .claude/rules/ directory whose paths pattern matches files inside the
folder "photos [2024" by escaping the bracket with a backslash, as in photos \[2024/**, and whose body says not to
rename the files.

FAIL if the pattern leaves the [ unescaped, which makes the pattern invalid so it matches nothing, or if the rule has no
paths field.

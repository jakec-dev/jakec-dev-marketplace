---
type: llm
---

PASS if the reply gives a command that creates a symbolic link to ~/team-rules inside the project's .claude/rules/
directory, such as ln -s ~/team-rules .claude/rules/team.
FAIL if it copies the files instead, or links somewhere other than inside .claude/rules/.

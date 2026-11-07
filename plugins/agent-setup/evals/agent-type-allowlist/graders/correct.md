---
type: llm
focus: trace
---

Judge the reply and any subagent file Claude wrote or tried to write. Claude Code denies writes to `.claude/` in this
test, so judge the attempted content, not whether the file exists.
PASS if the answer says that an `Agent(test-runner, linter)` type list in tools restricts spawning only when the agent
runs as the main thread with `claude --agent`, and that in a subagent spawned by Claude the types in parentheses are
ignored; and it either sets coordinator up to run with `claude --agent coordinator` or offers another way to keep
other types out, such as `Agent(...)` deny rules in permissions.
FAIL if it writes `Agent(test-runner, linter)` into the subagent and presents it as enforcing the restriction when
Claude spawns coordinator as a subagent.

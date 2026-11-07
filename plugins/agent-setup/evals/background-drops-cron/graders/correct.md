---
type: llm
---

PASS if the answer says that a subagent Claude spawns from the main conversation runs in the background by default,
and that a background subagent loses built-in tools outside a fixed set, CronCreate among them, even when its tools
list names them, without an error; and gives a fix that works, such as running it in the foreground (for example
turning fork mode off with `CLAUDE_CODE_FORK_SUBAGENT=0` and asking Claude to wait for it), or removing CronCreate
from the subagent and scheduling the follow-up from the main conversation. A reply that also mentions removing
`background: true` still passes.
FAIL if it blames a typo, permissions or a missing server, or says listing CronCreate in tools should be enough.

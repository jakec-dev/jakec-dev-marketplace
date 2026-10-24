---
type: llm
focus: trace
---

Claude Code's documentation says a skill with `context: fork` runs in a subagent that doesn't see the conversation
history, so its content must be a task that stands on its own.

Judge the skill file Claude wrote and what it told the user.

PASS if Claude points out that a forked skill can't see this conversation, and either drops `context: fork`, or
gives the skill a task that doesn't depend on the conversation, such as reading decisions from a file.
FAIL if Claude writes a `context: fork` skill that tells the subagent to summarise the current conversation without
saying it can't see it.

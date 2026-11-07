---
type: llm
---

PASS if the answer says a subagent doesn't fit this, because the work needs frequent back-and-forth with the user,
or because a subagent can't ask the user questions, and recommends doing it in the main conversation or as a skill
that runs in the main conversation instead.
FAIL if it writes the subagent without saying that it doesn't fit, or recommends a skill with `context: fork`.

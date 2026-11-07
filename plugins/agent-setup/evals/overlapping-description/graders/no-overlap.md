---
type: llm
---

PASS if the answer notices that the existing code-reviewer subagent's description also covers security, and changes
or proposes changing the descriptions so that each routes to one subagent, such as narrowing code-reviewer away from
security, or merging the two.
FAIL if it adds security-reviewer without addressing the overlap with code-reviewer.

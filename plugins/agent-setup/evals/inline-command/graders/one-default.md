---
type: llm
weight: 0.01
focus: trace
---

Judge the `.claude/skills/release-notes/SKILL.md` content Claude wrote or tried to write with the Write tool. Claude Code
denies writes to `.claude/` in this test, so judge the attempted content, not whether the file exists.

PASS if, wherever the skill could use more than one tool or approach for a step, it names one default and at most
says when to use an alternative, and it uses one term for each concept throughout.
FAIL if it presents several interchangeable options for a step without a default, or switches between different
terms for the same thing (such as "endpoint", "route" and "URL path" for one concept).

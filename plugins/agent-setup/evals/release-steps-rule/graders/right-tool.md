---
type: llm
focus: trace
---

Claude Code's documentation says a multi-step procedure, or a workflow you trigger with /<name> such as a release,
belongs in a skill, which loads only when used, rather than in CLAUDE.md or a rule, which loads into context.

PASS if Claude's reply recommends a skill for the release steps, with the reason that it loads only when needed or
can be run on demand. Writing the skill, or writing the rule after recommending a skill, is fine.

FAIL if Claude writes the steps as a rule without suggesting a skill.

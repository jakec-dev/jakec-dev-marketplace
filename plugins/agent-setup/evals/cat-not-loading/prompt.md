---
description: Diagnosing why a path-scoped rule does not load.
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

I have a rule in .claude/rules/ with paths: ["src/**/*.py"]. When Claude reads one of those Python files using
`cat` in the terminal, the rule never seems to apply, but other times it does. Why, and what should I do about it?

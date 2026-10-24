---
description: A skill that injects the output of a check that exits non-zero when it finds problems.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called lint-report that helps fix lint problems. When the skill runs, the current output of
`npm run lint` should already be in its instructions, so Claude sees the problems straight away. npm run lint exits
with code 1 whenever it finds problems.

---
description: A blocking Stop hook, written so that it lets the turn end when Claude is already continuing because of it.
tags: [hooks]
max_turns: 40
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project hook that stops Claude from finishing its turn while `npm test` fails, so that it keeps working until
the tests pass. Put the script in `scripts/` and register it in the project's settings.

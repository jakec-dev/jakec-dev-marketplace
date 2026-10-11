---
description: A path-scoped rule for one directory.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a rule for this project so that whenever Claude works on files under src/api/, it makes sure every endpoint
validates its input. Don't touch any other files.

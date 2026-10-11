---
description: One rule for two file extensions.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a rule for this project that applies to every TypeScript and TSX file anywhere in the repo: it should say
to prefer type aliases over interfaces.

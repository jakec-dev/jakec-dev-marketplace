---
description: A skill the user wants restricted, where allowed-tools would grant rather than restrict.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called audit-deps that reviews package.json for outdated or risky dependencies. While it runs,
Claude must not be able to edit files or run shell commands.

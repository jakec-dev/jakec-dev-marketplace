---
description: A hook request in a settings file, which the settings skill hands to the hook skill.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project hook that runs `npx prettier --write` on each file Claude edits or writes.

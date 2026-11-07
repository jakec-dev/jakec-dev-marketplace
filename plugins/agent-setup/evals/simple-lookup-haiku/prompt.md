---
description: A subagent doing simple lookup work, which sets its model to haiku.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project subagent that, given a module path, collects every file that imports that module and lists them.

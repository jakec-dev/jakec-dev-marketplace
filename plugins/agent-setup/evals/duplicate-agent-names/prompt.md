---
description: Two subagent files in one agents tree with the same name, of which only one loads.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I put a security checklist in .claude/agents/review/reviewer.md, but when Claude uses the reviewer subagent it never
follows the checklist. Why?

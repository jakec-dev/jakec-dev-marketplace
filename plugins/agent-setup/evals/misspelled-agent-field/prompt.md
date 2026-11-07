---
description: A subagent field written in snake_case, which Claude Code ignores without an error.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

My test-runner subagent in .claude/agents/ is meant to be unable to edit files, but it just edited src/math.js to
make a failing test pass. Why, and how do I fix it?

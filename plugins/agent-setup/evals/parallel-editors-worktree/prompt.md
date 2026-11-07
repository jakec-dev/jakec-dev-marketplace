---
description: A subagent run as several copies that edit shared files, which runs in a worktree.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project subagent called migrator that converts a list of modules from console.log to our logger in
src/logger.js. I'll run several migrators at once, each on a different set of modules, and they all also update
src/index.js.

---
description: A subagent autoCompactWindow written as 200k, which Claude Code reads as 200 and ignores.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

My log-reader subagent should compact earlier than normal, so I set `autoCompactWindow: 200k`, but it still
compacts at the usual point. Fix it.

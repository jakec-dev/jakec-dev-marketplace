---
description: A subagent permissionMode that the main conversation in auto mode overrides.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

I gave my auditor subagent `permissionMode: plan` so that it can't change anything. I run Claude Code in auto mode,
and the auditor just edited a file. Why didn't plan mode stop it, and what should I do?

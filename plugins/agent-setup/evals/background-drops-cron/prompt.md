---
description: A subagent that lists CronCreate, which a background subagent loses without an error.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

My release-watcher subagent is supposed to schedule a follow-up check with CronCreate, but it says it has no
CronCreate tool, even though CronCreate is in its tools list. There's no error anywhere. Why, and how do I fix it?

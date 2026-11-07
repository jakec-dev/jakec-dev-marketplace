---
description: A subagent asked to spawn only some subagent types, which an Agent(type) list enforces only under --agent.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project subagent called coordinator that splits a change into checks and delegates them to other
subagents. It must only ever be able to spawn the test-runner and linter subagents, never any other.

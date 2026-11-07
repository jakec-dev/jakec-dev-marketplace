---
description: A reviewer subagent, written read-only with no Edit, Write or Agent.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project subagent that reviews the changed files against SPEC.md before I open a pull request.

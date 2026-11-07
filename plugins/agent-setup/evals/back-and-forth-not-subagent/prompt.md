---
description: A request for a subagent that needs back-and-forth with the user, which fits the main conversation or a skill.
tags: [subagents]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a subagent I can use to plan features: it should ask me questions about the feature, take my answers, and
refine the plan with me over several rounds until I'm happy with it.

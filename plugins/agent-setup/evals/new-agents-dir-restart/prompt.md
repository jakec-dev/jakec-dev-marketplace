---
description: A first subagent file in a new agents directory, which needs a restart to load.
tags: [subagents]
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Mid-session I asked Claude to create our project's first subagent, .claude/agents/reviewer.md. The .claude/agents
folder didn't exist before. The file is there and looks right, but Claude says there's no reviewer agent. I thought
subagent files reload live?

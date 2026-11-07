---
description: Two subagent files Claude Code skips silently, one with a colon in its name and one with no description.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Claude never delegates to either of the two subagents in .claude/agents/, and neither shows up when I type @ to
mention one. What's wrong with them?

---
description: A project skill, where a file directly under .claude/skills/ would never load.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called changelog that drafts a CHANGELOG entry from the commits since the last git tag.

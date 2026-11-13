---
description: Blocking writes to a directory with a Write path rule, which never matches, instead of an Edit rule.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project deny rule so Claude can never change anything in `src/generated/`. I was thinking
`Write(./src/generated/**)`.

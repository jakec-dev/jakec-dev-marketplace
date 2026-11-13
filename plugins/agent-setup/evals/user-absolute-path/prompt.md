---
description: A user-settings Read rule for an absolute path, written with a single slash that anchors at the settings source.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a deny rule to my user settings, `~/.claude/settings.json`, so that Claude can never read anything under
`/opt/vault`, in any project.

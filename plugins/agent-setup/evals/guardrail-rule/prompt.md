---
description: A requirement that must hold every time, asked for as a rule.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a rule so that Claude never edits anything under db/migrations/. It must never happen, not even once.

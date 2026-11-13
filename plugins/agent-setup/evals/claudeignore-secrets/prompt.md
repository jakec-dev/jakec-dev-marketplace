---
description: Hiding secrets with a .claudeignore file, which Claude Code ignores, instead of Read deny rules.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a `.claudeignore` file so that Claude can't read `.env` or anything in `secrets/`.

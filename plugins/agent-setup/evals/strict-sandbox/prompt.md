---
description: A sandbox that must hold, which needs the unsandboxed retry turned off and no fallback.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Turn on the sandbox for this repository, and make sure Claude can never run a command outside it.

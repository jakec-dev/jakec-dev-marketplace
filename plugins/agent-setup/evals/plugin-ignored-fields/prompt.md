---
description: A plugin agent that sets permissionMode and initialPrompt, which plugin agents ignore.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Our acme-plugin ships a deployer agent with `permissionMode: acceptEdits` and an `initialPrompt`. When I run
`claude --agent acme-plugin:deployer`, it still asks before every edit and the initial prompt never gets sent. Why?

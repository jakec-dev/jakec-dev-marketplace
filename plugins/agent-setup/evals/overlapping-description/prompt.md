---
description: A new subagent whose description would overlap an existing one and carry detail that belongs in its prompt.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a security-reviewer subagent. Its description should list everything it checks: injection, auth and session
handling, secrets in code, unsafe deserialisation, dependency vulnerabilities and insecure defaults.

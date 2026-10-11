---
description: An instruction for files in many directories.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Whenever Claude writes a SQL migration in this monorepo, it should start the file with a one-line comment saying
what the migration changes. Migrations live in packages/*/migrations/ and services/*/db/migrations/. Set that up.

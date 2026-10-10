---
description: A project instruction in a repository that uses AGENTS.md and has no CLAUDE.md.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project instruction for Claude Code: when running tests, run only the affected package with
`pnpm test --filter <package>`, never the whole suite.

---
description: Allow rules for a claude -p CI run left in project settings, which a never-trusted folder does not use.
tags: [settings]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Our CI runs `claude -p` in a fresh checkout of this repository, and it keeps being refused permission for
`npm test` and `git commit`. Add allow rules to the repository's `.claude/settings.json` so the CI run can use them.

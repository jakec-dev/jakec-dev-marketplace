---
description: Sharing rules from another directory by symlink.
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
---

Our team keeps shared Claude rules in ~/team-rules/ (outside this repo). I want to link that whole folder into this
project's rules instead of copying the files. Give me the exact command to run, and tell me anything I need to know
for the rules to actually load. Don't run anything yourself.

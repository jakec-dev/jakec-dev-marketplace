---
description: A skill whose body needs live values, written so that an inline command after "=" would never run.
tags: [skills]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called release-notes that drafts release notes. When the skill runs, its instructions should
already contain the current package version and git branch, filled in automatically, as lines in the form
`VERSION=<version>` and `BRANCH=<branch>`.

---
description: A deploy skill, which Claude shouldn't decide to run on its own.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called deploy-staging that deploys this app to staging with ./scripts/deploy.sh staging.

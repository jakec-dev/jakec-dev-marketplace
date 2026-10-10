---
description: A multi-step procedure, asked for as a rule.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Make a rule with our release steps so Claude knows them: bump the version in package.json, add the release to
CHANGELOG.md, commit, tag it as v<version>, push the tag, then run npm publish. We release about once a month.

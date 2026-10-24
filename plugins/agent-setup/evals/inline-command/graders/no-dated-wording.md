---
type: regex
weight: 0.01
flags: i
pattern: '\b(as of (19|20)\d\d|before (19|20)\d\d|after (19|20)\d\d|the new (api|version))\b'
match: not_contains
target:
  source: file
  path: .claude/skills/release-notes/SKILL.md
---

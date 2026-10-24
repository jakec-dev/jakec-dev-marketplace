---
type: regex
weight: 0.01
pattern: '[A-Za-z]:\\|[\w.-]+\\[\w.-]+\\[\w.-]+'
match: not_contains
target:
  source: file
  path: .claude/skills/lint-report/SKILL.md
---

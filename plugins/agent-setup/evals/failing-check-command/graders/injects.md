---
type: regex
flags: m
pattern: '(^|\s)!`[^`]*npm run lint|```!'
target:
  source: file
  path: .claude/skills/lint-report/SKILL.md
---

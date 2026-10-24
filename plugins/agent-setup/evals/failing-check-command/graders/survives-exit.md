---
type: regex
pattern: '!`[^`]*npm run lint(?![^`]*\|\|)|```!\n(?:[^`\n]*\n)*?[^`\n]*npm run lint(?![^\n]*\|\|)'
match: not_contains
target:
  source: file
  path: .claude/skills/lint-report/SKILL.md
---

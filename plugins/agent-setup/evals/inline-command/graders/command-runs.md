---
type: regex
pattern: '"name":"Write","input":\{"file_path":"[^"]*\.claude/skills/release-notes/SKILL\.md","content":"(?:[^"\\]|\\.)*?(?<!\s|\\n|\\t)!`'
match: not_contains
target: trace
---

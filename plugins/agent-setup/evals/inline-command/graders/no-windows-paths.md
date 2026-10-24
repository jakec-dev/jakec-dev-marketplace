---
type: regex
weight: 0.01
pattern: '"name":"Write","input":\{"file_path":"[^"]*\.claude/skills/release-notes/SKILL\.md","content":"(?:[^"\\]|\\.)*?(?:[A-Za-z]:\\\\|[\w.-]+\\\\[\w.-]+\\\\[\w.-]+)'
match: not_contains
target: trace
---

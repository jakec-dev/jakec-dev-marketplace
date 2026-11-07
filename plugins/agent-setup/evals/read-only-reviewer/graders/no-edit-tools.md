---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.claude/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:[^"\\]|\\.)*?\\ntools:(?:[^"\\]|\\[^n]|\\n *- )*?\b(?:Edit|Write|NotebookEdit|Agent|Task)\b'
match: not_contains
target: trace
---

---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.claude/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:(?:[^"\\]|\\.)*?\\n)?cacheTtl:'
match: not_contains
target: trace
---

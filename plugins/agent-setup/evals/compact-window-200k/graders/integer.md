---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.claude/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:[^"\\]|\\.)*?autoCompactWindow: *(?:1000000|[1-9][0-9]{5})\b'
target: trace
---

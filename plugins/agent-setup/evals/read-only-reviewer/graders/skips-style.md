---
type: regex
weight: 0.01
flags: i
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.claude/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:[^"\\]|\\.)*?(?:(?<=\\n)|\b)(?:skip|ignore|don.t (?:comment on|report))\w* (?:\w+ ){0,3}style'
target: trace
---

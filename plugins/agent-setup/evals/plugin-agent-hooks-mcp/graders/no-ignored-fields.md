---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*acme-plugin/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:[^"\\]|\\.)*?\\n(?:hooks|mcpServers):'
match: not_contains
target: trace
---

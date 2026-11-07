---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.mcp\.json"'
match: not_contains
target: trace
---

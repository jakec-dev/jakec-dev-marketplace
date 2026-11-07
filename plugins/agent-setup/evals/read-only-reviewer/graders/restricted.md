---
type: regex
pattern: '"name":"(?:Write|Edit)","input":\{(?:"replace_all":(?:true|false),)?"file_path":"[^"]*\.claude/agents/[^"]*\.md","(?:content|old_string":"(?:[^"\\]|\\.)*","new_string)":"(?:[^"\\]|\\.)*?(?:\\ntools:|\\ndisallowedTools:(?=(?:[^"\\]|\\[^n]|\\n *- )*?\bEdit\b)(?=(?:[^"\\]|\\[^n]|\\n *- )*?\bWrite\b)(?=(?:[^"\\]|\\[^n]|\\n *- )*?\bAgent\b))'
target: trace
---

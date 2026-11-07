---
type: regex
flags: i
pattern: '"name":"Write","input":\{"file_path":"[^"]*\.claude/agents/[^"]*security[^"]*\.md","content":"-{3}\\n(?:(?:[^"\\]|\\.)*?\\n)?description:(?:(?!deseriali[sz])(?:[^"\\]|\\[^n]))*(?=\\n)(?:[^"\\]|\\.)*?\\n-{3}\\n(?:[^"\\]|\\.)*?deseriali[sz]'
target: trace
---

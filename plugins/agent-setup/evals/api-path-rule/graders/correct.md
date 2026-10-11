---
type: llm
focus: trace
---

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write: the path and content of
its Write tool call, or the file content it gave in its reply.

PASS if Claude wrote a Markdown file inside the project's .claude/rules/ directory whose very first line is --- (YAML
frontmatter), whose frontmatter has a paths field with a glob such as src/api/**/* or "src/api/**" that matches every
file under src/api/, and whose body tells Claude to validate input on every endpoint.

FAIL if the file is somewhere else, has no paths field, has a glob that misses nested files (such as src/api/* alone),
or has anything before the opening ---.

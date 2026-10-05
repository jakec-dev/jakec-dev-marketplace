---
type: llm
focus: trace
---

Writes into .claude/ are denied by the test harness, so judge the file Claude tried to write: the path and content of
its Write tool call, or the file content it gave in its reply.

PASS if Claude wrote a Markdown file in the project's .claude/rules/ directory with frontmatter whose paths field covers
both .ts and .tsx files in any directory, either as one brace pattern such as "**/*.{ts,tsx}" or as two patterns, and
whose body states the type-alias guidance.

FAIL if the rule has no paths field, covers only one extension, or matches only the project root.

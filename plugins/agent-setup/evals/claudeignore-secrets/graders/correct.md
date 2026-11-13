---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the reply says a `.claudeignore` file has no effect and blocks the files with `Read` deny rules in
the project's settings, such as `Read(./.env)` and `Read(./secrets/**)`.
FAIL if it relies on a `.claudeignore` file, or adds no `Read` deny rules.

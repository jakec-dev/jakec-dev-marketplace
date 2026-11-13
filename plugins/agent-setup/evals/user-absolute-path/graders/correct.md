---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the rule is written with a double leading slash, such as `Read(//opt/vault/**)`, so that it is an
absolute path.
FAIL if the rule is `Read(/opt/vault/**)` or another single-slash path, which anchors at the settings source.

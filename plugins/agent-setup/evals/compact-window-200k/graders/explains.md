---
type: llm
---

PASS if the answer says that Claude Code reads `200k` as 200, which is outside the allowed range of 100000 to
1000000, so the field is ignored and the subagent compacts as if it were absent, and that the value must be a plain
integer such as `200000`.
FAIL if it gives another cause or doesn't say the value must be a plain integer.

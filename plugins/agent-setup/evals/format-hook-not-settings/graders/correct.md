---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the hook Claude wrote, tried to write or gave is a `PostToolUse` command hook for the project's
`.claude/settings.json` whose matcher covers Edit and Write and whose command runs prettier on the edited file.
FAIL if it gives no hook, or puts it on another event.

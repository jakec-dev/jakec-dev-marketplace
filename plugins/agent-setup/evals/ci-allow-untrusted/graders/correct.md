---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the reply says a `claude -p` run in a folder that was never trusted doesn't use `allow` rules from
`.claude/settings.json`, and gives a way that works, such as `--allowedTools` on the CI command, a `--settings` file,
user or managed settings, or marking the folder trusted.
FAIL if it only adds the allow rules to `.claude/settings.json` and presents that as the fix.

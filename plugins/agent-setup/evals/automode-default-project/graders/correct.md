---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the reply says that `permissions.defaultMode` set to `"auto"` in `.claude/settings.json` or
`.claude/settings.local.json` doesn't take effect, and points to a place that works, such as each developer's
`~/.claude/settings.json`, managed settings, the `--permission-mode auto` flag, or the built-in default that already
starts terminal sessions in auto mode.
FAIL if it sets `"defaultMode": "auto"` in the project's settings as the fix without saying it won't take effect.

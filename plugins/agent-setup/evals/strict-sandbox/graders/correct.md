---
type: llm
---

Writes into .claude/ are denied by the test harness, so judge the files Claude wrote or tried to write: the
path and content of its Write and Edit tool calls, or the file content it gave in its reply.

PASS if the settings Claude writes or gives set `sandbox.enabled` to `true` and
`sandbox.allowUnsandboxedCommands` to `false`, and the reply also sets `sandbox.failIfUnavailable` to `true` or says
that without it commands run unsandboxed when the sandbox can't start.
FAIL if it only enables the sandbox, leaving the retry outside the sandbox on.

---
type: llm
focus: trace
---

Claude Code's documentation says a skill's `allowed-tools` pre-approves the tools it lists for the invoking turn and
restricts nothing: other tools stay available under the normal permission settings. A skill's `disallowed-tools`
field removes tools while it runs.

Judge the skill file Claude wrote and what it told the user.

PASS if the skill uses `disallowed-tools` for editing and shell tools, or Claude tells the user that
`allowed-tools` alone can't stop those tools and offers a mechanism that does.
FAIL if the skill relies on `allowed-tools` listing only read tools as the way to stop edits and commands, and Claude
presents that as a restriction.

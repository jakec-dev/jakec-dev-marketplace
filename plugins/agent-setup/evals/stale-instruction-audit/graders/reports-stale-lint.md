---
type: llm
focus: last_message
---

The repository's CLAUDE.md says to run `npm run lint` before committing, but `package.json` defines only a `test`
script, so the lint command fails.

PASS if the answer reports the `npm run lint` instruction as wrong or stale because `package.json` has no `lint`
script, and proposes fixing or removing it.

FAIL if it doesn't mention the lint instruction, or treats it as correct.

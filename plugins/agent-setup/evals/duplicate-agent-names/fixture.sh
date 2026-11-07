#!/usr/bin/env bash
# A Node project with two reviewer subagents of the same name in one agents tree.
set -euo pipefail
cat >package.json <<'JSON'
{
  "name": "shop-api",
  "version": "2.4.1",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
JSON
mkdir -p src
printf 'export const add = (a, b) => a + b\n' >src/math.js
mkdir -p .claude/agents
cat >.claude/agents/reviewer.md <<'MD'
---
name: reviewer
description: Reviews changed files. Use after implementing a change.
tools: Read, Grep, Glob
---

Review the changed files for readability and report what could be clearer.
MD
mkdir -p .claude/agents/review
cat >.claude/agents/review/reviewer.md <<'MD'
---
name: reviewer
description: Reviews changed files against the security checklist. Use after implementing a change.
tools: Read, Grep, Glob
---

Review the changed files against this checklist and report each failed item with its file and line:

1. No secrets in code.
2. All input is validated.
3. No SQL built by string concatenation.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

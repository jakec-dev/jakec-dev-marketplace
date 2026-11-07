#!/usr/bin/env bash
# A Node project with test-runner and linter subagents.
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
cat >.claude/agents/test-runner.md <<'MD'
---
name: test-runner
description: Runs the test suite and reports failing tests with their errors. Use after code changes.
tools: Read, Grep, Glob, Bash
---

Run `npm test` and report each failing test with its error message.
MD
mkdir -p .claude/agents
cat >.claude/agents/linter.md <<'MD'
---
name: linter
description: Runs the linter and reports each problem with its file and line. Use after code changes.
tools: Read, Grep, Glob, Bash
---

Run `npx eslint .` and report each problem with its file and line.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

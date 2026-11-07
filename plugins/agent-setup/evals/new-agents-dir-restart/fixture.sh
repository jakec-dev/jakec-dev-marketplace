#!/usr/bin/env bash
# A Node project with one valid reviewer subagent, the first in its agents directory.
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
description: Reviews changed files for bugs. Use after implementing a change.
tools: Read, Grep, Glob
---

Review the changed files for bugs and report each with its file and line.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

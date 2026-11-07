#!/usr/bin/env bash
# A Node project with a log-reader subagent whose autoCompactWindow is written as 200k.
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
cat >.claude/agents/log-reader.md <<'MD'
---
name: log-reader
description: Reads long log files and reports the errors it finds. Use when asked about errors in logs.
tools: Read, Grep, Glob
autoCompactWindow: 200k
---

Read the log files you're given. Report each distinct error once, with how often it appears and its first timestamp.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

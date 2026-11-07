#!/usr/bin/env bash
# A Node project with a code-reviewer subagent that already covers security.
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
cat >.claude/agents/code-reviewer.md <<'MD'
---
name: code-reviewer
description: Reviews code changes for bugs, security vulnerabilities and readability. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
---

Run `git diff` and review the changed files. Report bugs, security vulnerabilities and unclear code, most severe
first.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A Node project with two subagent files that Claude Code skips.
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
cat >.claude/agents/security.md <<'MD'
---
name: review:security
description: Reviews changed code for security vulnerabilities. Use before opening a pull request.
tools: Read, Grep, Glob
---

Review the changed files for injection, secrets in code and unsafe input handling. Report each finding with its file
and line.
MD
mkdir -p .claude/agents
cat >.claude/agents/docs-writer.md <<'MD'
---
name: docs-writer
tools: Read, Grep, Glob, Write, Edit
---

Update the README to match the code. Keep the existing headings.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A Node project with a repo-auditor subagent.
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
cat >.claude/agents/repo-auditor.md <<'MD'
---
name: repo-auditor
description: Audits a large repository and reports what it finds. Use when asked for a repository audit.
tools: Read, Grep, Glob
---

Audit the repository for outdated dependencies, dead code and missing tests. Report each finding with its file.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

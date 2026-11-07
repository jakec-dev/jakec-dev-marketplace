#!/usr/bin/env bash
# A Node project with an auditor subagent that sets permissionMode: plan.
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
cat >.claude/agents/auditor.md <<'MD'
---
name: auditor
description: Audits the codebase for dead code and unused dependencies. Use when asked for an audit.
permissionMode: plan
---

Find dead code and unused dependencies. Report each with its file. Don't change anything.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

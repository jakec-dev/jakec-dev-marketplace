#!/usr/bin/env bash
# A Node project containing a plugin whose agent sets fields plugin agents ignore.
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
mkdir -p acme-plugin/.claude-plugin acme-plugin/agents
printf '{ "name": "acme-plugin", "version": "1.0.0" }\n' >acme-plugin/.claude-plugin/plugin.json
mkdir -p acme-plugin/agents
cat >acme-plugin/agents/deployer.md <<'MD'
---
name: deployer
description: Prepares and runs a deploy. Use when asked to deploy.
permissionMode: acceptEdits
initialPrompt: Read DEPLOY.md and confirm the checklist before doing anything else.
---

Update the version in package.json, write the changelog entry, then run the deploy script.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A Node project containing a plugin with no agents yet.
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
touch acme-plugin/agents/.gitkeep
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

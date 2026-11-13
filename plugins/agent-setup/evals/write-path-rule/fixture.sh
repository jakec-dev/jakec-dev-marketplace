#!/usr/bin/env bash
# A small Node project with project settings that allow its test command, committed so git commands work.
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
mkdir -p src .claude
printf 'export const add = (a, b) => a + b\n' >src/math.js
cat >.claude/settings.json <<'JSON'
{
  "permissions": {
    "allow": ["Bash(npm test)"]
  }
}
JSON
mkdir -p src/generated
printf '// generated, do not edit\n' >src/generated/client.js
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A Node project with a logger and modules that use console.log.
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
printf 'export const log = (...a) => process.stdout.write(a.join(" ") + "\\n")\n' >src/logger.js
printf "import './a.js'\nimport './b.js'\nconsole.log('ready')\n" >src/index.js
printf "console.log('a')\n" >src/a.js
printf "console.log('b')\n" >src/b.js
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A Node project with modules that import each other.
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
printf "import { add } from './math.js'\nexport const total = (xs) => xs.reduce(add, 0)\n" >src/sum.js
printf "import { total } from './sum.js'\nconsole.log(total([1, 2]))\n" >src/index.js
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

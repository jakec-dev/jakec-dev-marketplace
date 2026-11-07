#!/usr/bin/env bash
# A Node project with a spec.
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
cat >SPEC.md <<'MD'
# Rate limiter

- Allow 100 requests per minute per API key.
- Return 429 with a Retry-After header when the limit is exceeded.
- Edge cases: a missing API key, and a clock that moves backwards.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A small Node project with a test script, committed so git commands work.
set -euo pipefail
cat >package.json <<'JSON'
{
  "name": "shop-api",
  "version": "2.4.1",
  "private": true,
  "scripts": { "test": "node --test" }
}
JSON
mkdir -p src test
printf 'export const add = (a, b) => a + b\n' >src/math.js
cat >test/math.test.js <<'JS'
import { test } from 'node:test'
import assert from 'node:assert'
import { add } from '../src/math.js'
test('add', () => assert.equal(add(1, 2), 3))
JS
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

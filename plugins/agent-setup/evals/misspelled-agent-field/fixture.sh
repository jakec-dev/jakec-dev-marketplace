#!/usr/bin/env bash
# A Node project with a failing test and a test-runner subagent whose field names are snake_case.
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
mkdir -p test
cat >test/math.test.js <<'JS'
import { test } from 'node:test'
import assert from 'node:assert'
import { add } from '../src/math.js'
test('add', () => assert.equal(add(1, 2), 4))
JS
mkdir -p .claude/agents
cat >.claude/agents/test-runner.md <<'MD'
---
name: test-runner
description: Runs the test suite and reports the failing tests with their errors. Use after code changes.
disallowed_tools: Edit, Write
max_turns: 15
---

Run `npm test`. Report each failing test with its error message. Don't change any file.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

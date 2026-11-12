#!/usr/bin/env bash
# A small TypeScript service whose code already shows its layout and conventions, with no Claude setup yet.
set -euo pipefail
mkdir -p src/orders src/customers
cat >package.json <<'JSON'
{
  "name": "orders-api",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test", "lint": "eslint ." }
}
JSON
printf 'export default [{ rules: { "no-var": "error", "prefer-const": "error" } }]\n' >eslint.config.js
entity() { # <directory> <Name>
  cat >"src/$1/repository.ts" <<TS
export type Row = { id: string }

export const find$2ById = async (rows: Row[], id: string): Promise<Row | undefined> =>
  rows.find((row) => row.id === id)
TS
  cat >"src/$1/repository.test.ts" <<TS
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { find$2ById } from './repository.js'

test('finds a row by id', async () => {
  assert.deepEqual(await find$2ById([{ id: '1' }], '1'), { id: '1' })
})
TS
}
entity orders Order
entity customers Customer
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

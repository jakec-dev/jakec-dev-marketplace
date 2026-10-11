#!/usr/bin/env bash
# A small project whose formatter and linter already enforce its style.
set -euo pipefail
mkdir -p src/api src/db
cat >package.json <<'JSON'
{
  "name": "orders",
  "private": true,
  "type": "module",
  "scripts": {
    "lint": "eslint .",
    "format": "prettier --write .",
    "test": "node --test"
  }
}
JSON
printf '{ "semi": false, "singleQuote": true, "tabWidth": 2 }\n' >.prettierrc
cat >eslint.config.js <<'JS'
export default [{ rules: { 'no-var': 'error', 'prefer-const': 'error', eqeqeq: 'error' } }]
JS
cat >src/db/orders.js <<'JS'
// Order totals are stored in cents as integers. Never use floating-point amounts.
export const totalCents = (items) => items.reduce((sum, item) => sum + item.priceCents * item.quantity, 0)
JS
cat >src/api/orders.js <<'JS'
import { totalCents } from '../db/orders.js'

export const orderSummary = (items) => ({ total: totalCents(items) })
JS
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

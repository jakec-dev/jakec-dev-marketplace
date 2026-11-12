#!/usr/bin/env bash
# A small package whose CLAUDE.md names a lint command that its package.json does not define.
set -euo pipefail
mkdir -p src
printf '{ "name": "ui", "private": true, "type": "module", "scripts": { "test": "node --test" } }\n' >package.json
printf 'export const cn = (...classes: string[]): string => classes.filter(Boolean).join(" ")\n' >src/cn.ts
cat >CLAUDE.md <<'MD'
# ui

- Run `npm run lint` before committing.
- Run `npm test` after changing anything in `src/`.
MD
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

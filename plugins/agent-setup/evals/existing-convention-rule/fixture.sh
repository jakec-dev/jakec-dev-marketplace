#!/usr/bin/env bash
# A project whose CLAUDE.md already tells Claude to use pnpm.
set -euo pipefail
cat >CLAUDE.md <<'MD'
# Orders service

- Use pnpm, not npm: `pnpm install`, `pnpm test`, `pnpm run build`.
- Commit messages follow Conventional Commits.
MD
printf '{ "name": "orders", "private": true, "packageManager": "pnpm@9.12.0" }\n' >package.json
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A monorepo whose project instructions live in AGENTS.md, shared with other coding agents, with no CLAUDE.md.
set -euo pipefail
mkdir -p packages/api packages/web
cat >AGENTS.md <<'MD'
# Agent instructions

- Use pnpm, not npm.
- Commit messages follow Conventional Commits.
MD
printf '{ "name": "shop", "private": true, "packageManager": "pnpm@9.12.0" }\n' >package.json
printf 'packages:\n  - "packages/*"\n' >pnpm-workspace.yaml
printf '{ "name": "api", "scripts": { "test": "node --test" } }\n' >packages/api/package.json
printf '{ "name": "web", "scripts": { "test": "node --test" } }\n' >packages/web/package.json
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

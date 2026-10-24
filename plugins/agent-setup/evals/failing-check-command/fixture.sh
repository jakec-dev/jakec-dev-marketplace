#!/usr/bin/env bash
# A small Node project with lint and test scripts, committed so git commands work.
set -euo pipefail
cat >package.json <<'JSON'
{
  "name": "shop-api",
  "version": "2.4.1",
  "private": true,
  "scripts": { "lint": "eslint .", "test": "node --test" }
}
JSON
mkdir -p src scripts
printf 'export const add = (a, b) => a + b\n' >src/math.js
cat >scripts/deploy.sh <<'SH'
#!/usr/bin/env bash
echo "deploying to $1"
SH
chmod +x scripts/deploy.sh
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

#!/usr/bin/env bash
# A new React component library with one helper and no components yet, so no code shows a component's API.
set -euo pipefail
mkdir -p src/components
printf '{ "name": "ui", "private": true, "type": "module", "peerDependencies": { "react": "^19.0.0" } }\n' >package.json
printf '{ "compilerOptions": { "strict": true, "jsx": "react-jsx", "module": "nodenext" } }\n' >tsconfig.json
cat >src/cn.ts <<'TS'
export const cn = (...classes: Array<string | false | null | undefined>): string => classes.filter(Boolean).join(' ')
TS
printf "export { cn } from '../cn.js'\n" >src/components/index.ts
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit'

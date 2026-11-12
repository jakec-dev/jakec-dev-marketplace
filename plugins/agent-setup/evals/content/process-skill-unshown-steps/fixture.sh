#!/usr/bin/env bash
# A service freshly generated from a template: an example feature to copy, and an empty audit list that no code
# shows how to fill.
set -euo pipefail
mkdir -p src/features/example
printf '{ "name": "billing", "private": true, "type": "module", "scripts": { "test": "node --test" } }\n' >package.json
printf '{ "compilerOptions": { "strict": true, "module": "nodenext", "target": "es2022" } }\n' >tsconfig.json
cat >README.md <<'MD'
# billing

Generated from the service template. `src/features/example/` shows the shape of a feature.
MD
cat >src/http.ts <<'TS'
export type Handler = (request: Request, params: Record<string, string>) => Response | Promise<Response>

export type Route = { method: 'GET' | 'POST' | 'PUT' | 'DELETE'; path: string; handler: Handler }

export const json = (body: unknown, status = 200): Response =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } })
TS
cat >src/audit.ts <<'TS'
// Features whose requests are written to the audit log.
export const auditedFeatures: string[] = []
TS
cat >src/features/example/routes.ts <<'TS'
import { json, type Route } from '../../http.js'

const greetings = [{ id: '1', text: 'hello' }]

export const exampleRoutes: Route[] = [
  { method: 'GET', path: '/example', handler: () => json(greetings) },
  {
    method: 'GET',
    path: '/example/:id',
    handler: (_request, params) => {
      const greeting = greetings.find((item) => item.id === params.id)
      return greeting ? json(greeting) : json({ error: 'not found' }, 404)
    },
  },
]
TS
cat >src/app.ts <<'TS'
import { exampleRoutes } from './features/example/routes.js'
import type { Route } from './http.js'

export const routes: Route[] = [...exampleRoutes]
TS
git init -q
git add -A
git -c user.name=fixture -c user.email=fixture@example.com commit -q -m 'initial commit from the service template'

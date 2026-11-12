---
type: llm
focus: last_message
---

The repository is a small TypeScript service: `src/orders/` and `src/customers/` each hold a `repository.ts` and a
`repository.test.ts` built the same way, `package.json` has `test` and `lint` scripts, and `eslint.config.js` sets
two lint rules. Claude Code's documentation says CLAUDE.md works best holding only what Claude couldn't work out from
the code, and that content Claude can derive from the codebase, such as directory layouts, dependency lists and
architecture overviews, should be cut.

PASS if the answer proposes no CLAUDE.md content that restates what the code or configuration already shows: the
directory layout, the per-entity file structure, the lint rules, or the dependency list. Pointing to the `test` or
`lint` command is allowed, as is saying that little or nothing needs adding.

FAIL if it proposes, or writes out, CLAUDE.md content describing the directory or file layout, the repository and
test file pattern, the lint rules, or the dependencies.

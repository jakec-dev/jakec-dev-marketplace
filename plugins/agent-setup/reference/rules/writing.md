# Writing rule frontmatter

How to write a rule's frontmatter: the `paths` field, its glob patterns, brace expansion and its budget, and invalid
patterns.

## The frontmatter

- Configure a rule with YAML frontmatter between `---` markers at the top of the file. `paths` is the only field
  Claude Code reads from a rule; any other field is ignored without an error.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)
- For frontmatter in skills, subagents, output styles, and rules, the opening `---` must be the file's first line,
  and everything after the closing `---` is treated as the instructions.
  [glossary › Frontmatter](https://code.claude.com/docs/en/glossary#frontmatter)
- Claude Code removes the frontmatter before loading the rule into context.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)
- The field, as the reference table gives it:
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)

  | Field | Required | Description |
  | :- | :- | :- |
  | `paths` | No | Glob patterns that [scope the rule to matching files](https://code.claude.com/docs/en/memory#path-specific-rules). Accepts a YAML list or a comma-separated string |

- If the YAML between the markers doesn't parse, Claude Code ignores the frontmatter and loads the rule as if it had
  no `paths`. [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)

## Scoping with `paths`

- Rules can be scoped to specific files using YAML frontmatter with the `paths` field. These conditional rules only
  apply when Claude is working with files matching the specified patterns.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

  ```markdown
  ---
  paths:
    - "src/api/**/*.ts"
  ---

  # API Development Rules

  - All API endpoints must include input validation
  ```

- Rules without a `paths` field are loaded unconditionally and apply to all files.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

## Glob patterns

- Use glob patterns in the `paths` field to match files by extension, directory, or any combination:
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

  | Pattern | Matches |
  | - | - |
  | `**/*.ts` | All TypeScript files in any directory |
  | `src/**/*` | All files under `src/` directory |
  | `*.md` | Markdown files in the project root |
  | `src/components/*.tsx` | React components in a specific directory |

- You can specify multiple patterns and use brace expansion to match multiple extensions in one pattern.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

  ```markdown
  ---
  paths:
    - "src/**/*.{ts,tsx}"
    - "lib/**/*.ts"
    - "tests/**/*.test.ts"
  ---
  ```

## Brace expansion budget

- Each brace group multiplies the number of expanded patterns: `src/*.{ts,tsx}` expands to two patterns, and
  `{a,b}/{c,d}/*.{ts,tsx}` to eight. [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)
- A rule's whole `paths` list shares one budget of 1,000 expanded patterns and 4 MiB, and patterns without braces
  don't count against it. [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)
- Claude Code uses any pattern that would exceed the budget unexpanded, and its literal braces match no files.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

## Invalid patterns

- Glob syntax treats `[` as the start of a bracket expression such as `[abc]`. A pattern with a `[` that can't be
  read as a bracket expression, such as `photos [2024/**`, is invalid: it matches nothing, and the rule's other
  patterns keep working. [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)
- To match a literal `[` in a file name, escape it as `photos \[2024/**`.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)

## Not stated by the documentation

- In the comma-separated string form of `paths`, the documentation does not say whether a comma inside a brace
  group, such as `src/**/*.{ts,tsx}`, is read as part of the brace group or as a separator between patterns.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)
- The pattern table matches `*.md` against the project root; the documentation does not say what patterns are
  matched against for a rule in `~/.claude/rules/` or in a nested `.claude/rules/` directory.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)
- The documentation does not say what happens to a rule whose opening `---` is not on the first line, such as after
  a blank line: whether the block is read as frontmatter, or loads as instructions with the rule unscoped.
  [glossary › Frontmatter](https://code.claude.com/docs/en/glossary#frontmatter)

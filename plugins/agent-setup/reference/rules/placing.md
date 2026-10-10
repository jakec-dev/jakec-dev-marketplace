# Placing rules

Deciding where a rule file goes (project `.claude/rules/`, its subdirectories, `~/.claude/rules/`) and naming it.

## Project rules

- Project rules are markdown files placed in the project's `.claude/rules/` directory.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- Each file should cover one topic, with a descriptive filename like `testing.md` or `api-design.md`.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- All `.md` files in `.claude/rules/` are discovered recursively, so rules can be organised into subdirectories like
  `frontend/` or `backend/`. [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

  ```text
  your-project/
  ├── .claude/
  │   ├── CLAUDE.md           # Main project instructions
  │   └── rules/
  │       ├── code-style.md   # Code style guidelines
  │       ├── testing.md      # Testing conventions
  │       └── security.md     # Security requirements
  ```

- Rules can also be in nested `.claude/rules/` directories.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

## User-level rules

- Personal rules in `~/.claude/rules/` apply to every project on the machine. Use them for preferences that aren't
  project-specific. [memory › User-level rules](https://code.claude.com/docs/en/memory#user-level-rules)

  ```text
  ~/.claude/rules/
  ├── preferences.md    # Your personal coding preferences
  └── workflows.md      # Your preferred workflows
  ```

## Scope and committing

- In the `.claude` directory's file reference, project-scope files live in the repo under `.claude/`; global-scope
  files live in `~/.claude/`. The `rules/*.md` row:
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)

  | File | Scope | Commit | What it does | Reference |
  | - | - | - | - | - |
  | `rules/*.md` | Project and global | ✓ | Topic-scoped instructions, optionally path-gated | [Rules](https://code.claude.com/docs/en/memory#organize-rules-with-claude/rules/) |

## Not stated by the documentation

- Recursive discovery into subdirectories is stated for the project's `.claude/rules/`; the documentation does not
  say whether subdirectories of `~/.claude/rules/` are also discovered.
  [memory › User-level rules](https://code.claude.com/docs/en/memory#user-level-rules)
- The `rules/*.md` row is marked for committing, and the documentation gives no personal, uncommitted place for
  project-specific rules, as `CLAUDE.local.md` is for CLAUDE.md.
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)
- The documentation places a subdirectory's `.claude/rules/` files in the `managed-only` value, and rules files under
  a package in the `claudeMdExcludes` examples; it does not say at what depth below the working directory a nested
  `.claude/rules/` directory is found. [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)

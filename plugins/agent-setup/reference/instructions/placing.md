# Placing instruction files

Deciding where a CLAUDE.md file, `CLAUDE.local.md` or rule file goes and what it is called: managed, user,
project, per-directory and local files, the managed `claudeMd` setting, and project and user `.claude/rules/`.

## Contents

- Locations
- Project CLAUDE.md
- CLAUDE.local.md
- Per-directory CLAUDE.md files
- Organization-wide instructions
- Project rules
- User-level rules
- Scope and committing
- Not stated by the documentation

## Locations

- CLAUDE.md files are markdown files that give Claude persistent instructions for a project, your personal
  workflow, or your entire organization. You write them in plain text; Claude reads them at the start of every
  session. [memory › CLAUDE.md files](https://code.claude.com/docs/en/memory#claude-md-files)
- CLAUDE.md files can live in several locations, each with a different scope.
  [memory › Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files)

  | Scope | Location | Purpose | Use case examples | Shared with |
  | - | - | - | - | - |
  | **Managed policy** | • macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br />• Linux and WSL: `/etc/claude-code/CLAUDE.md`<br />• Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Organization-wide instructions managed by IT/DevOps | Company coding standards, security policies, compliance requirements | All users in organization |
  | **User instructions** | `~/.claude/CLAUDE.md` | Personal preferences for all projects | Code styling preferences, personal tooling shortcuts | Just you (all projects) |
  | **Project instructions** | `./CLAUDE.md` or `./.claude/CLAUDE.md`. See [AGENTS.md](https://code.claude.com/docs/en/memory#agents-md) for when `./AGENTS.md` loads instead of or alongside them | Team-shared instructions for the project | Project architecture, coding standards, common workflows | Team members via source control |
  | **Local instructions** | `./CLAUDE.local.md` | Personal project-specific preferences; add to `.gitignore` | Your sandbox URLs, preferred test data | Just you (current project) |

- To include instructions in a plugin, write them as a skill: Claude Code doesn't load a `CLAUDE.md` at a plugin's
  root, and `claude plugin validate` warns `CLAUDE.md at the plugin root is not loaded as project context`.
  [plugins/components › Skills](https://code.claude.com/docs/en/plugins/components#skills)

## Project CLAUDE.md

- A project CLAUDE.md can be stored in either `./CLAUDE.md` or `./.claude/CLAUDE.md`. Put in it instructions that
  apply to anyone working on the project: build and test commands, coding standards, architectural decisions,
  naming conventions, and common workflows.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- These instructions are shared with your team through version control, so focus on project-level standards rather
  than personal preferences.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)

## CLAUDE.local.md

- For private per-project preferences that shouldn't be checked into version control, create a `CLAUDE.local.md`
  at the project root. It loads alongside `CLAUDE.md` and is treated the same way.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- Add `CLAUDE.local.md` to your `.gitignore` so it isn't committed. With `CLAUDE_CODE_NEW_INIT=1` set, running
  `/init` and choosing the personal option does this for you.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

## Per-directory CLAUDE.md files

- In a large codebase, a single CLAUDE.md at the repository root tends to either grow to cover every subsystem's
  conventions, costing context on instructions unrelated to the current task, or stay too generic to be useful.
  Splitting instructions across per-directory files means Claude loads repository-wide rules plus only the
  conventions for the code you're working in.
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)
- A root file sets repository-wide rules and each subdirectory adds its own. A common split is two levels:
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)
  - **Root `CLAUDE.md`**: instructions that apply everywhere, such as coding standards and commit conventions.
  - **Per-subdirectory `CLAUDE.md`**: conventions specific to that area's stack. In a monorepo that's one per
    package. In a large single tree it's one per subsystem such as `src/db/` or `src/api/`.
- Commit these files to the repository so teammates inherit them. Each directory's owner typically maintains its
  file.
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)
- The documentation's example of a root file and a per-package file, shortened:
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)

  ```markdown
  Run package scripts from the package directory, not the monorepo root.
  Never edit files under packages/*/generated/. Run `npm run codegen` in the package instead.
  ```

  ```markdown
  Write database queries with the Knex query builder. Never put raw SQL strings in route handlers.
  Never edit a migration after it has merged. Add a new migration instead.
  ```

  The first block is the root `CLAUDE.md`; the second is `packages/api/CLAUDE.md`.

## Organization-wide instructions

- Organizations can deploy a centrally managed CLAUDE.md that applies to all users on a machine, created at the
  managed policy location and distributed with MDM, Group Policy, Ansible, or similar tools:
  [memory › Deploy organization-wide CLAUDE.md](https://code.claude.com/docs/en/memory#deploy-organization-wide-claude-md)
  - macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`
  - Linux and WSL: `/etc/claude-code/CLAUDE.md`
  - Windows: `C:\Program Files\ClaudeCode\CLAUDE.md`
- The `claudeMd` key puts managed CLAUDE.md content directly inside `managed-settings.json` instead of deploying a
  separate file. Its scope is every Claude Code session on the machine, in every repository; for
  repository-specific guidance, commit a project CLAUDE.md instead.
  [memory › Deploy organization-wide CLAUDE.md](https://code.claude.com/docs/en/memory#deploy-organization-wide-claude-md)
- `claudeMd` has the same precedence as a managed CLAUDE.md file: it loads before user and project CLAUDE.md.
  [memory › Deploy organization-wide CLAUDE.md](https://code.claude.com/docs/en/memory#deploy-organization-wide-claude-md)
- `claudeMd` is honored in managed and policy settings only. Setting `claudeMd` in user, project, or local settings
  has no effect.
  [memory › Deploy organization-wide CLAUDE.md](https://code.claude.com/docs/en/memory#deploy-organization-wide-claude-md)
- In the settings reference, `claudeMd` has scope `Managed`, defaults to unset, and is a string: the text of a
  CLAUDE.md file, written as you would the file, Markdown included, with line breaks as `\n`.
  [settings-reference › `claudeMd`](https://code.claude.com/docs/en/settings-reference#claudemd)

  ```json
  {
    "claudeMd": "# Engineering rules\n\n- Always run make lint before committing.\n- Never push directly to main."
  }
  ```

- In server-managed settings, a managed CLAUDE.md delivered through the `claudeMd` key doesn't require approval,
  because it's instruction text for Claude rather than a command Claude Code runs. Claude Code still checks
  permissions for the tools Claude uses while following those instructions.
  [server-managed-settings › Security approval dialogs](https://code.claude.com/docs/en/server-managed-settings#security-approval-dialogs)

## Project rules

- Project rules are markdown files placed in the project's `.claude/rules/` directory. Each file should cover one
  topic, with a descriptive filename like `testing.md` or `api-design.md`.
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

## User-level rules

- Personal rules in `~/.claude/rules/` apply to every project on the machine. Use them for preferences that aren't
  project-specific. [memory › User-level rules](https://code.claude.com/docs/en/memory#user-level-rules)

  ```text
  ~/.claude/rules/
  ├── preferences.md    # Your personal coding preferences
  └── workflows.md      # Your preferred workflows
  ```

## Scope and committing

- In the `.claude` directory's file reference, project-scope files live in the repo under `.claude/`, or at the
  root for `CLAUDE.md`; global-scope files live in `~/.claude/` and apply across all projects. The `CLAUDE.md` and
  `rules/*.md` rows:
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)

  | File | Scope | Commit | What it does | Reference |
  | - | - | - | - | - |
  | `CLAUDE.md` | Project and global | ✓ | Instructions loaded every session | [Memory](https://code.claude.com/docs/en/memory) |
  | `rules/*.md` | Project and global | ✓ | Topic-scoped instructions, optionally path-gated | [Rules](https://code.claude.com/docs/en/memory#organize-rules-with-claude/rules/) |

- On Windows, `~/.claude` resolves to `%USERPROFILE%\.claude`. If you set `CLAUDE_CONFIG_DIR`, every `~/.claude`
  path on the `.claude` directory page, including the global `CLAUDE.md` and `rules/*.md`, lives under that
  directory instead.
  [claude-directory › Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)

## Not stated by the documentation

- Recursive discovery into subdirectories is stated for the project's `.claude/rules/`; the documentation does not
  say whether subdirectories of `~/.claude/rules/` are also discovered.
  [memory › User-level rules](https://code.claude.com/docs/en/memory#user-level-rules)
- The `rules/*.md` row is marked for committing, and the documentation gives no personal, uncommitted place for
  project-specific rules, as `CLAUDE.local.md` is for CLAUDE.md.
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)
- `CLAUDE.local.md` loads from the working directory, the directories above it and subdirectories; the
  documentation does not say whether a `.claude/CLAUDE.local.md` loads, as `./.claude/CLAUDE.md` does for the
  project CLAUDE.md.
  [memory › Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files)
- A subdirectory's `.claude/CLAUDE.md`, such as `packages/api/.claude/CLAUDE.md`, counts as one of its own CLAUDE.md
  files when deciding whether to read its `AGENTS.md`; the documentation does not say whether the file itself loads
  when Claude reads a file there, since per-directory files are given only as `CLAUDE.md`.
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory),
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)

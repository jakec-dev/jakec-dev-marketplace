# Choosing the tool

Picking the kind of Claude tool that fits a goal, before writing anything.

## The instruction file the repository already uses

- "Claude Code can read `AGENTS.md` as your project instructions, so a repository already set up for other coding
  agents works without adding a `CLAUDE.md`, an import, or a setting." What Claude reads by default:

  | Your repository has | Claude reads |
  | :- | :- |
  | An `AGENTS.md`, and no `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it | Your `AGENTS.md` |
  | An `AGENTS.md` and a `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it | Your `CLAUDE.md` files only |
  | A `CLAUDE.md` that already imports `AGENTS.md` | Your `CLAUDE.md`, with `AGENTS.md` included through the import |

  [memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)
- A `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` in the working directory or above it counts, so Claude
  reads it instead of `AGENTS.md`; `~/.claude/CLAUDE.md`, the organization's managed `CLAUDE.md` and `.claude/rules/`
  files don't count, and keep loading alongside `AGENTS.md`. "Because `CLAUDE.local.md` counts, adding one to keep
  your own uncommitted instructions in a project that relies on `AGENTS.md` stops Claude from reading `AGENTS.md`
  for you."
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- To keep `AGENTS.md` as the one file every tool shares while adding Claude-specific instructions, put an
  `@AGENTS.md` import in a `CLAUDE.md` next to it, with the Claude-specific instructions below the import:

  ```markdown
  @AGENTS.md

  ## Claude Code

  Use plan mode for changes under `src/billing/`.
  ```

  [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)
- Evidence: eval case agents-md-instruction
- Check: in a repository with an `AGENTS.md` and no `CLAUDE.md`, project instructions go into `AGENTS.md`, or into
  a `CLAUDE.md` that imports it; no tool creates a `CLAUDE.md` or `CLAUDE.local.md` that leaves `AGENTS.md` unread.

## Must happen every time: a hook

- "An instruction like "never edit `.env`" in CLAUDE.md or a skill is a request, not a guarantee. A `PreToolUse`
  hook that blocks the edit is enforcement. If a rule must hold every time, make it a hook rather than a prompt
  instruction." Use a hook "when the action must happen the same way every time and doesn't need Claude to think".
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- For CLAUDE.md: "If the instruction is something that must run at a specific point, such as before every commit or
  after each file edit, write it as a hook instead."
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- To stop an action, a permission deny rule also holds every time. For auto mode, the documentation's boundaries
  table gives `permissions.deny` for "Never run the action", which "Blocks before the classifier is consulted.
  Neither the classifier nor user intent can override it", and says "Use an ask or deny rule for a durable
  guarantee."
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)
- A deny rule and a `PreToolUse` hook work together: "Claude Code evaluates deny and ask rules regardless of what a
  PreToolUse hook returns: a matching deny rule blocks the call", and "A hook that exits with code 2 stops the tool
  call before permission rules are evaluated". A mod that handles `tool.check` can approve a call either one
  refuses, except where the documentation says deny rules or managed hooks hold over it.
  [permissions › Extend permissions with hooks](https://code.claude.com/docs/en/permissions#extend-permissions-with-hooks)
- Check: no instruction in CLAUDE.md, a rule or a skill is something that must hold every time or run at a fixed
  point; each such requirement is a hook, or, to stop a tool call, a permission deny rule.

## Every session needs it: CLAUDE.md

- "Put it in CLAUDE.md if Claude should always know it: coding conventions, build commands, project structure,
  "never do X" rules." Rules without `paths` frontmatter also load at launch, so they suit the same content split
  into topic files: "Use rules to keep CLAUDE.md focused."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: the instruction applies in every session, whatever part of the codebase Claude works in.

## One part of the codebase: a path-scoped rule or a nested CLAUDE.md

- For CLAUDE.md: "If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a
  skill or a path-scoped rule instead."
  [memory › When to add to CLAUDE.md](https://code.claude.com/docs/en/memory#when-to-add-to-claude-md)
- Rules with `paths` frontmatter "only load when Claude works with matching files, saving context."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Between the two:

  | Approach | File location | Loads when | Use when |
  | :- | :- | :- | :- |
  | Per-directory `CLAUDE.md` | Inside the directory, alongside its code | At launch when started from that directory, or on demand when Claude reads a file there | Directory owners maintain their own conventions; instructions are versioned with the code |
  | Path-scoped rule in `.claude/rules/` | Central `.claude/` at the repo root | When Claude works with a file matching the rule's `paths:` glob | You want all conventions in one place, or the same rule applies to many scattered paths |

  [large-codebases › Choose between per-directory CLAUDE.md and path-scoped rules](https://code.claude.com/docs/en/large-codebases#choose-between-per-directory-claude-md-and-path-scoped-rules)
- Evidence: eval case scattered-paths-rule
- Check: an instruction that matters for only some files is scoped to them, and the choice between the two follows
  the table's "Use when" column.

## Needed sometimes, or a procedure: a skill

- "Put it in a skill if it's reference material Claude needs sometimes (API docs, style guides) or a workflow you
  trigger with `/<name>` (deploy, review, release)." Use a skill rather than a hook "when Claude should decide how to
  apply the steps, or when the content is knowledge rather than a script".
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: no multi-step procedure or occasional reference material sits in CLAUDE.md or a rule without `paths`.

## About the response, not the project: an output style

- Put it in CLAUDE.md "if it's true of the project whatever style you're in". "Use an output style if it's about the
  response itself and you might want it off again: length, format, how much Claude explains, or a different role
  such as a writing assistant."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: CLAUDE.md holds no instructions about response length, format or role.

## Isolated or parallel work: a subagent or a dynamic workflow

- "Use a subagent when you need context isolation or when your context window is getting full." "Use a dynamic
  workflow when a job outgrows a handful of subagents, or when you want the findings cross-checked before you see
  them, such as a codebase-wide audit, a large migration, or a plan drafted from several angles."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: work that reads many files but needs only a summary back runs outside the main conversation.

## An external system: MCP, with a skill for using it

- "MCP gives Claude purpose-built tools for an external system, with the connection and authentication handled by
  the server." "Skills give Claude knowledge about how to use those tools effectively, plus workflows you can
  trigger with `/<name>`."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: knowledge about an external system's data or conventions lives in a skill, not in the connection.

## The same setup in another repository: a plugin

- "Use plugins when you want to reuse the same setup across multiple repositories or distribute to others via a
  marketplace."
  [features-overview › Match features to your goal](https://code.claude.com/docs/en/features-overview#match-features-to-your-goal)
- Check: a setup copied into a second repository is proposed as a plugin instead.

# Choosing the tool

Picking the kind of Claude tool that fits a goal, before writing anything.

## Must happen every time: a hook

- "An instruction like "never edit `.env`" in CLAUDE.md or a skill is a request, not a guarantee. A `PreToolUse`
  hook that blocks the edit is enforcement. If a rule must hold every time, make it a hook rather than a prompt
  instruction." Use a hook "when the action must happen the same way every time and doesn't need Claude to think".
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- For CLAUDE.md: "If the instruction is something that must run at a specific point, such as before every commit or
  after each file edit, write it as a hook instead."
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- Check: no instruction in CLAUDE.md, a rule or a skill is something that must hold every time or run at a fixed
  point; each such requirement is a hook.

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

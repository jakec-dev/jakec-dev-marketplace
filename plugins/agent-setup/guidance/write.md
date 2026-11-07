# Writing instructions

Writing the content of CLAUDE.md files, AGENTS.md files and rules so that Claude follows it.

The documentation states most of these for CLAUDE.md files. It also says "Claude Code can read `AGENTS.md` as your
project instructions"
([memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)), so the plugin applies them to an
`AGENTS.md` that Claude reads in place of a `CLAUDE.md`, and says so when it does.

## Concrete enough to verify

- "Claude treats CLAUDE.md files as context, not enforced configuration, so how you write instructions affects how
  reliably Claude follows them. Write instructions that are concrete enough to verify":
  - "Use 2-space indentation" instead of "Format code properly"
  - "Run `npm test` before committing" instead of "Test your changes"
  - "API handlers live in `src/api/handlers/`" instead of "Keep files organized"

  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- Evidence: eval case vague-rule
- Check: someone reading Claude's work could tell whether each instruction was followed.

## Short files

- "Claude Code loads `CLAUDE.md` into every session, which means every line in it takes a little of Claude's
  attention on *every* task, whether it's relevant or not."
  [best-practices › Keep CLAUDE.md short](https://code.claude.com/docs/en/best-practices#keep-claude-md-short)
- "target under 200 lines per CLAUDE.md file. Longer files consume more context and reduce adherence." Imports "help
  you organize a long file but don't reduce its context cost, because imported files load together with the CLAUDE.md
  that imports them."
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- A warning appears at startup and in `/status` when an instruction file is over the recommended length, or when
  files within it add up past a combined limit; "Each CLAUDE.md, rules file, and `@path` import counts as a separate
  file."
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Check: each CLAUDE.md is under 200 lines, and length was cut by moving content, not by splitting it into imports.

## Headings and bullets

- "Group related instructions under markdown headers and bullets. Organized sections are easier for Claude to follow
  than dense paragraphs."
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- For rules: "Each file should cover one topic, with a descriptive filename like `testing.md` or `api-design.md`."
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- Check: no dense paragraphs of instructions; each rule file holds one topic and its name says which.

## No contradictions

- "If two instructions contradict each other, Claude may pick one arbitrarily. Review your CLAUDE.md files, nested
  CLAUDE.md files in subdirectories, and `.claude/rules/` periodically to remove outdated or conflicting
  instructions."
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- "If your CLAUDE.md sets commit or pull request rules, turn off the built-in ones with `includeGitInstructions` and
  set the attribution text with `attribution`."
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- Check: a new instruction contradicts nothing in the other instruction files that load with it, nor Claude Code's
  built-in git instructions.

## Plain wording, not emphasis

- Adding "IMPORTANT or ALL CAPS to instructions Claude keeps missing" is advice current models have made unnecessary:
  "Current ones follow a plainly worded line, and piling on emphasis mostly makes Claude over-apply the rule."
  [best-practices › What you can stop doing](https://code.claude.com/docs/en/best-practices#what-you-can-stop-doing)
- Check: is every instruction worded plainly, with no IMPORTANT, ALL CAPS or other emphasis added to make Claude
  follow it?

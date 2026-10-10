# Maintaining tools

Keeping existing tools useful as the codebase and models change, and finding the ones to cut.

## Read the symptoms

- For CLAUDE.md: "If Claude keeps doing something you don't want despite having a rule against it, the file is
  probably too long and the rule is getting lost. If Claude asks you questions that are answered in CLAUDE.md, the
  phrasing might be ambiguous."
  [best-practices › Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md)
- Check: an ignored instruction is diagnosed as length or ambiguity before more instructions are added.

## Prune, and revisit after model releases

- "Treat CLAUDE.md like code: review it when things go wrong, prune it regularly, and test changes by observing
  whether Claude's behavior actually shifts."
  [best-practices › Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md)
- "Instructions that worked around an older model's limitation may become overhead once a newer model handles the
  case on its own." Review CLAUDE.md edits in pull requests "so conventions track the code".
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)
- Check: an audit proposes deleting instructions the current model follows without them, not only adding new ones.

## Use the built-in audits

- `/doctor prompt-audit` checks instruction files "for outdated or conflicting content", such as "instructions
  written for older models, references to files or commands that don't exist, and files that contradict each
  other". By default it covers CLAUDE.md, CLAUDE.local.md and AGENTS.md files, plus the rules, skills, commands,
  subagents and output styles under `.claude/` and `~/.claude/`; pass a path to audit one file or directory.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- Check: an audit of instruction files names `/doctor prompt-audit` as a step the user can run.

## Capture a gap while it is fresh

- "A `Stop` hook receives the path to the session transcript when Claude finishes responding, so a script can review
  the session and propose CLAUDE.md updates while the gap it exposed is fresh."
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)

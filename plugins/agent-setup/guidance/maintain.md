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

## Cut skills that are never invoked

- "Every skill in the skill listing adds to your context on every turn, whether or not Claude ever uses it." The
  `/skill-doctor` report "flags skills in the listing that have never been invoked and says where to turn them off";
  of the skills it tells you where to turn off, start with the ones that have the highest context cost. The report
  covers the skills in your session other than bundled skills and enterprise skills.
  [skills › Find unused skills](https://code.claude.com/docs/en/skills#find-unused-skills)
- `/skill-doctor` "isn't available in sessions that skip feature-flag fetching".
  [skills › Find unused skills](https://code.claude.com/docs/en/skills#find-unused-skills)
- A skill with `disable-model-invocation: true` has no description in context.
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
- Check: has `/skill-doctor` been run, starting with the highest context cost, and does each skill it flags as never
  invoked have a reason to stay?

## Review allowed-tools before running a repository's skills

- "A skill can grant itself broad tool access, so review the `allowed-tools` of skills checked into a repository
  before you run Claude Code there." The reason: "Workspace trust doesn't gate this field. Claude Code applies a
  project skill's `allowed-tools` even in a `-p` run in a folder you've never trusted."
  [skills › Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill)
- Check: has each checked-in skill's `allowed-tools` been reviewed, with any broad grant flagged?

# Maintaining tools

Keeping existing tools useful as the codebase and models change, and finding the ones to cut.

## Read the symptoms

- "If Claude keeps ignoring a line that *is* in `CLAUDE.md`, adding IMPORTANT probably won't fix it. Either the file
  has grown long enough that the line gets lost, or the line is a rule that can't have exceptions, in which case it
  belongs in a hook."
  [best-practices › Keep CLAUDE.md short](https://code.claude.com/docs/en/best-practices#keep-claude-md-short)
- Check: is a line in CLAUDE.md that Claude keeps ignoring diagnosed as a file grown too long or as a rule that
  belongs in a hook?

## Prune, and revisit after model releases

- "Instructions that worked around an older model's limitation may become overhead once a newer model handles the
  case on its own." Review CLAUDE.md edits in pull requests "so conventions track the code".
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory)
- Check: an audit proposes deleting instructions the current model follows without them, not only adding new ones.

## Cut hooks and deny rules that guard preferences

- "If you have hooks for things that are only preferences, delete them and let Claude decide."
  [best-practices › Deterministic and non-deterministic instructions](https://code.claude.com/docs/en/best-practices#deterministic-and-non-deterministic-instructions)
- "keep the enforced set small. Every hook and deny rule will occasionally fire when it shouldn't,
  and someone has to maintain each one. If you ever find yourself at forty of them, most are probably preferences
  that Claude could have weighed on its own."
  [best-practices › Choose who a rule applies to](https://code.claude.com/docs/en/best-practices#choose-who-a-rule-applies-to)
- Check: has each hook and deny rule been checked for being a preference Claude could weigh on its own, and removed if
  it is?

## Turn off MCP servers you don't use

- "Connected servers add their tool names and instructions to the context even when you're not using them, so it's
  worth turning off the ones you don't need".
  [best-practices › Connect the tools Claude needs](https://code.claude.com/docs/en/best-practices#connect-the-tools-claude-needs)
- Check: is each connected MCP server one the work uses, with the rest turned off?

## Use the built-in audits

- `/doctor prompt-audit` checks instruction files "for outdated or conflicting content", such as "instructions
  written for older models, references to files or commands that don't exist, and files that contradict each
  other". By default it covers CLAUDE.md, CLAUDE.local.md and AGENTS.md files, plus the rules, skills, commands,
  subagents and output styles under `.claude/` and `~/.claude/`; pass a path to audit one file or directory. "The
  audit runs through the bundled `/claude-api` skill. It's unavailable while that skill is turned off in
  `skillOverrides` or with `disableBundledSkills`."
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- For what the setup costs: "`/usage` is the first place to look. On Pro, Max, Ultra, Team, and Enterprise it breaks
  your usage down by skill, subagent, plugin, and MCP server."
  [best-practices › Keep cost and context down](https://code.claude.com/docs/en/best-practices#keep-cost-and-context-down)
- Check: does an audit of instruction files name `/doctor prompt-audit` as a step the user can run, and does an audit
  of what the setup costs name `/usage`?

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

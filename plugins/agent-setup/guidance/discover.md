# Discovering what needs a tool

Deciding what in a repository or a way of working deserves a Claude tool, and what does not.

The documentation states the "Signs that something belongs in CLAUDE.md" section, and the architecture, `/doctor`
and `/init` parts of "What the codebase already says", for CLAUDE.md files. It also says "Claude Code can read
`AGENTS.md` as your project instructions"
([memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)), so the plugin applies those parts to an
`AGENTS.md` that Claude reads in place of a `CLAUDE.md`, and says so when it does.

## Add a tool when a trigger appears

- The documentation advises against configuring everything up front: "Each feature has a recognizable trigger, and
  most teams add them in roughly this order":

  | Trigger | Add |
  | :- | :- |
  | Claude gets a convention or command wrong twice | Add it to CLAUDE.md |
  | You keep asking Claude to be shorter, explain more, or answer in the same format | Set an output style |
  | You keep typing the same prompt to start a task | Save it as a user-invocable skill |
  | You paste the same playbook or multi-step procedure into chat for the third time | Capture it as a skill |
  | You keep copying data from a browser tab Claude can't see | Connect that system as an MCP server |
  | Claude reads many files to find where a symbol is defined or used | Install a code intelligence plugin for your language |
  | A side task floods your conversation with output you won't reference again | Route it through a subagent |
  | You want something to happen every time without asking | Write a hook |
  | A second repository needs the same setup | Package it as a plugin |

  [features-overview › Build your setup over time](https://code.claude.com/docs/en/features-overview#build-your-setup-over-time)
- Check: each proposed tool names the trigger it answers, and the evidence that the trigger happened.

## Signs that something belongs in CLAUDE.md

- For CLAUDE.md, the documentation says to "write down what you'd otherwise re-explain", and to add to it when
  Claude makes the same mistake a second time, when a code review catches something Claude should have known about
  this codebase, when you type the same correction into chat that you typed last session, or when a new teammate
  would need the same context to be productive.
  [memory › When to add to CLAUDE.md](https://code.claude.com/docs/en/memory#when-to-add-to-claude-md)
- For CLAUDE.md, "the file works best when it only holds what Claude couldn't work out from the code itself":
  - "How to confirm work in this repo: the exact test, typecheck, and lint commands, and how to run a single test
    file"
  - "Places where the code is misleading: an old pattern that's everywhere but that new code must not copy, or a
    directory that looks unused but isn't"
  - "Decisions that aren't in the repo: which error helper the team settled on, how deploys work, what needs a
    migration review"
  - "Anything you've had to correct twice already"

  [best-practices › Keep CLAUDE.md short](https://code.claude.com/docs/en/best-practices#keep-claude-md-short)
- Evidence: eval case mature-repo-convention
- Check: does each proposed entry trace to one of the four signs or to one of the kinds of content listed?

## What the codebase already says

- "Only write down what Claude can't find by reading the repo, or what it would otherwise spend time rediscovering
  every session." "A good test before you write anything down for Claude": "Could it find this by reading the code?"
  and "Would it actually go and look?" "If both are yes, leave it out."
  [best-practices › Tell Claude what it can't see](https://code.claude.com/docs/en/best-practices#tell-claude-what-it-cant-see)
  So describing your architecture and file layout in CLAUDE.md is advice current models have made unnecessary:
  "Claude reads the repo itself. Only write down what isn't in there."
  [best-practices › What you can stop doing](https://code.claude.com/docs/en/best-practices#what-you-can-stop-doing)
- The `/doctor` checkup's trims for a checked-in CLAUDE.md cut "content Claude can derive from the codebase, such
  as directory layouts, dependency lists, and architecture overviews", and keep "pitfalls, rationale, and
  conventions that differ from tool defaults".
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- When `/init` generates a CLAUDE.md, the documentation says to "refine from there with instructions Claude wouldn't
  discover on its own".
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
  "`/init` generates a starting version from your codebase. From there the work is mostly removing lines."
  [best-practices › Keep CLAUDE.md short](https://code.claude.com/docs/en/best-practices#keep-claude-md-short)
- Evidence: eval case linted-conventions-rule
- Evidence: eval case new-repo-convention
- Check: is each proposed entry something Claude couldn't find by reading the code, or wouldn't go and look for?

## Update what exists before adding

- "The same triggers tell you when to update what you already have. A repeated mistake or a recurring review
  comment is a CLAUDE.md edit, not a one-off correction in chat. A workflow you keep tweaking by hand is a skill
  that needs another revision."
  [features-overview › Build your setup over time](https://code.claude.com/docs/en/features-overview#build-your-setup-over-time)
- Check: before proposing a new tool, look for an existing one that the trigger points to.

## A skill closes a gap seen without it

- For a skill meant to fix a failure or missing context, the best-practices page says: "Create evaluations BEFORE
  writing extensive documentation. This ensures your Skill solves real problems rather than documenting imagined
  ones." Its first step, before writing the skill, is to run Claude on representative tasks without a skill and
  document the specific failures or missing context. A skill saved from a repeated prompt is covered by the trigger
  table above.
  [best-practices › Build evaluations first](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#build-evaluations-first)
- Check: for a skill meant to fix a failure or missing context, is there a recorded task where Claude failed, or
  lacked context, without this skill, from a run made before writing it?

## A worker you keep spawning becomes a custom subagent

- "Define a custom subagent when you keep spawning the same kind of worker with the same instructions."
  [sub-agents › Create custom subagents](https://code.claude.com/docs/en/sub-agents#page-title)
- Check: does each proposed custom subagent replace the same kind of worker that keeps being spawned with the same
  instructions?

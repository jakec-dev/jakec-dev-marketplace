# Discovering what needs a tool

Deciding what in a repository or a way of working deserves a Claude tool, and what does not.

The documentation states most of these for CLAUDE.md files. It also says "Claude Code can read `AGENTS.md` as your
project instructions"
([memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)), so the plugin applies them to an
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
- What to include and exclude in CLAUDE.md:

  | Include | Exclude |
  | - | - |
  | Bash commands Claude can't guess | Anything Claude can figure out by reading code |
  | Code style rules that differ from defaults | Standard language conventions Claude already knows |
  | Testing instructions and preferred test runners | Detailed API documentation (link to docs instead) |
  | Repository etiquette (branch naming, PR conventions) | Information that changes frequently |
  | Architectural decisions specific to your project | Long explanations or tutorials |
  | Developer environment quirks (required env vars) | File-by-file descriptions of the codebase |
  | Common gotchas or non-obvious behaviors | Self-evident practices like "write clean code" |

  [best-practices › Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md)
- Check: each proposed entry traces to one of these four signs; no entry falls in the Exclude column.

## What the codebase already says

- The `/doctor` checkup's trims for a checked-in CLAUDE.md cut "content Claude can derive from the codebase, such
  as directory layouts, dependency lists, and architecture overviews", and keep "pitfalls, rationale, and
  conventions that differ from tool defaults".
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- When `/init` generates a CLAUDE.md, the documentation says to "refine from there with instructions Claude wouldn't
  discover on its own".
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- Evidence: eval case linted-conventions-rule
- Check: no proposed entry restates what reading the repository would tell Claude.

## Update what exists before adding

- "The same triggers tell you when to update what you already have. A repeated mistake or a recurring review
  comment is a CLAUDE.md edit, not a one-off correction in chat. A workflow you keep tweaking by hand is a skill
  that needs another revision."
  [features-overview › Build your setup over time](https://code.claude.com/docs/en/features-overview#build-your-setup-over-time)
- Check: before proposing a new tool, look for an existing one that the trigger points to.

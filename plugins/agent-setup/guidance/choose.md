# Choosing the tool

Picking the kind of Claude tool that fits a goal, before writing anything.

## Contents

- The instruction file the repository already uses
- Must happen every time: a hook
- Never-rules are deny rules or hooks, not auto mode
- A preference stays an instruction, not a hook
- A rule on a command's text: keep it, and add a PreToolUse hook
- Every session needs it: CLAUDE.md
- Context that never changes: CLAUDE.md, not a hook
- One part of the codebase: a path-scoped rule or a nested CLAUDE.md
- Needed sometimes, or a procedure: a skill
- Context Claude would otherwise explore for: a skill
- A skill with side effects is user-only
- Background knowledge is a skill only Claude invokes
- About the response, not the project: an output style
- Side work that returns a summary: a subagent
- Back-and-forth or shared context: the main conversation
- A task that needs the conversation so far: a fork, not a context: fork skill
- Workers that coordinate among themselves: an agent team
- Many subagents, or cross-checked findings: a dynamic workflow
- An external system: a CLI or MCP, with a skill for using it
- The same setup in another repository: a plugin
- Instructions shipped in a plugin are skills

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
- To keep your `CLAUDE.local.md` and still have Claude read `AGENTS.md`, set **Project instructions** to
  `claude-md-and-agents-md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
  Claude Code reads that setting from `~/.claude/settings.json`, a `--settings` file or managed settings, and ignores
  it in project and local settings files, so it can't be committed with the repository.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)
- In sessions where you used `/plugin` to disable the built-in plugin that reads `AGENTS.md`, or, in some cases, in
  your first session after you upgrade from a version that couldn't read `AGENTS.md` directly, Claude reads
  `CLAUDE.md` files only. "To give Claude your `AGENTS.md` in any of them, import it from a `CLAUDE.md`."
  [memory › When AGENTS.md support is unavailable](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable)
- To keep `AGENTS.md` as the one file every tool shares while adding Claude-specific instructions, put an
  `@AGENTS.md` import in a `CLAUDE.md` next to it, with the Claude-specific instructions below the import:

  ```markdown
  @AGENTS.md

  ## Claude Code

  Use plan mode for changes under `src/billing/`.
  ```

  [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)
- Evidence: eval case agents-md-instruction
- Check: where a repository relies on `AGENTS.md`, does each `CLAUDE.md` or `CLAUDE.local.md` that Claude would read
  instead import `@AGENTS.md`, unless it is one person's `CLAUDE.local.md` and they set `claude-md-and-agents-md`?

## Must happen every time: a hook

- "An instruction like "never edit `.env`" in CLAUDE.md or a skill is a request, not a guarantee. A `PreToolUse`
  hook that blocks the edit is enforcement. If a rule must hold every time, make it a hook rather than a prompt
  instruction." Use a hook "when the action must happen the same way every time and doesn't need Claude to think".
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- For CLAUDE.md: "If the instruction is something that must run at a specific point, such as before every commit or
  after each file edit, write it as a hook instead."
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- "If something has to happen every time, make it a hook, a deny rule, or a managed setting. `CLAUDE.md` is for
  guidelines, and Claude is allowed to decide a guideline doesn't apply." A deny rule holds for the form it matches;
  a Bash command Claude writes another way is covered under "A rule on a command's text" below.
  [best-practices › Enforce the rules that can't have exceptions](https://code.claude.com/docs/en/best-practices#enforce-the-rules-that-cant-have-exceptions)
- For managed settings and a managed CLAUDE.md: "Settings rules are enforced by the client regardless of what
  Claude decides to do. CLAUDE.md instructions shape Claude's behavior but are not a hard enforcement layer." "Use the
  file for guidance, and enforce rules with managed settings such as `permissions.deny`."
  [memory › Deploy organization-wide CLAUDE.md](https://code.claude.com/docs/en/memory#deploy-organization-wide-claude-md)
- A deny rule and a `PreToolUse` hook work together: "Claude Code evaluates deny and ask rules regardless of what a
  PreToolUse hook returns: a matching deny rule blocks the call", and "A hook that exits with code 2 stops the tool
  call before permission rules are evaluated". A mod that handles `tool.check` answers after the `PreToolUse` hooks
  have run. With managed settings on the machine, or a Team or Enterprise `/login` as the session's credential, by
  default "A call that a deny rule refuses stays refused, and your organization can change that", and "A call that a
  `PreToolUse` hook blocked stays blocked, whichever settings file the hook comes from." With neither, the mod can
  approve a call that a deny rule refuses or a `PreToolUse` hook blocked; a session that runs on an API key or a
  long-lived `CLAUDE_CODE_OAUTH_TOKEN` isn't using that login, even when that login is stored.
  [permissions › Precedence among rules, hooks, and mods](https://code.claude.com/docs/en/permissions#precedence-among-rules-hooks-and-mods)
- Check: no instruction in CLAUDE.md, a rule or a skill is something that must hold every time or run at a fixed
  point; each such requirement is a hook, or, to stop a tool call, a permission deny rule, backed as "A rule on a
  command's text" asks where Claude could write the command another way.

## Never-rules are deny rules or hooks, not auto mode

- "`deny` rules hold in every permission mode, including auto and `bypassPermissions`, which is exactly why the
  `.env` rule belongs there." "Auto mode is a classifier model judging each action rather than a hard rule. It's good
  at that, but like any judgment call it can be wrong. You can also tune what it treats as risky, and your org can
  turn it off entirely, so your "never" rules belong in deny rules or hooks."
  [best-practices › Limit access with permission rules and the sandbox](https://code.claude.com/docs/en/best-practices#limit-access-with-permission-rules-and-the-sandbox)
  Without managed settings or a Team or Enterprise `/login`, an installed mod that handles `tool.check` can still
  approve a call that a deny rule refuses or a `PreToolUse` hook blocked
  ([permissions › Precedence among rules, hooks, and mods](https://code.claude.com/docs/en/permissions#precedence-among-rules-hooks-and-mods)).
- "Deny and ask rules and `PreToolUse` hooks apply before the classifier sees anything, so a deny rule blocks in auto
  mode exactly like it does everywhere else." A boundary you state in conversation, such as `don't push until I've
  reviewed`, is one the classifier treats as a block signal, but "It's still a model reading the transcript, and the
  sentence can get lost when the conversation compacts, so anything that matters belongs in a deny rule."
  [best-practices › Change the permission mode](https://code.claude.com/docs/en/best-practices#change-the-permission-mode)
- For auto mode, the documentation's boundaries table gives `permissions.deny` for "Never run the action", which
  "Blocks before the classifier is consulted. Neither the classifier nor user intent can override it", and says "Use
  an ask or deny rule for a durable guarantee."
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)
- Check: is every action that must never happen held by a deny rule or a hook, rather than left to the auto mode
  classifier or to a boundary stated in conversation, and, without managed settings or a Team or Enterprise `/login`,
  does no installed mod that handles `tool.check` approve it?

## A preference stays an instruction, not a hook

- "Most of the time, you want Claude to decide. Almost every guideline has exceptions, and current models are good at
  reading the code in front of them and judging whether a guideline fits the situation." "The deterministic kind is
  for when you want to make sure certain things *always* happen (or never happen), no matter what the model decides."
  [best-practices › Deterministic and non-deterministic instructions](https://code.claude.com/docs/en/best-practices#deterministic-and-non-deterministic-instructions)
- "Don't overdo it, though: a hook is for a rule with *zero* exceptions, and `Prefer named exports` has plenty, so
  that one stays in `CLAUDE.md`."
  [best-practices › Enforce steps with hooks](https://code.claude.com/docs/en/best-practices#enforce-steps-with-hooks)
- Check: is each new hook a rule with zero exceptions, with any guideline that has exceptions, such as
  `Prefer named exports`, left as an instruction?

## A rule on a command's text: keep it, and add a PreToolUse hook

- A Bash deny or ask rule stays, backed by a `PreToolUse` hook that inspects the full command text with your own
  logic, or by the sandbox for filesystem and network enforcement that doesn't depend on the command text. A Bash
  rule "matches the command text Claude writes, after Claude Code splits compound commands and strips wrappers. It
  doesn't match the same program invoked in a different form, so a deny or ask rule covers the invocation Claude
  usually produces and isn't a security boundary around the program." These rules in `deny` or `ask` stop the first
  form and not the others:

  | Rule | Stops | Doesn't stop |
  | :- | :- | :- |
  | `Bash(curl *)` | `curl https://example.com` | `/usr/bin/curl https://example.com`, `sh -c 'curl https://example.com'` |
  | `Bash(rm *)` | `rm -rf build/` | `/bin/rm -rf build/`, `bash -c 'rm -rf build/'` |
  | `Bash(git push *)` | `git push origin main` | `git -C . push origin main`, `git -c push.default=current push origin main`, `git 'push' origin main` |

  "Your other rules and the permission mode decide the commands in the last column." "For filesystem and network
  enforcement that doesn't depend on the command text, use sandboxing. To inspect the full command text with your own
  logic before it runs, use a PreToolUse hook." A hook narrowed with `if` is best-effort, so "use the permission
  system rather than a hook to enforce a hard allow or deny"
  ([hooks › How `if` patterns match Bash commands](https://code.claude.com/docs/en/hooks#bash-if-matching)).
  [permissions › What a Bash rule doesn't match](https://code.claude.com/docs/en/permissions#bash-rule-limits)
- For an `ask` rule such as `Bash(git push *)`, a push written as `git -C <dir> push` or `git -c <key>=<value> push`
  doesn't match the rule, so it isn't checkpointed. "For a checkpoint that inspects the full command text, add a
  PreToolUse hook."
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)
- Bash permission patterns that try to constrain command arguments are fragile: `Bash(curl http://github.com/ *)`
  won't match options before the URL, a different protocol, redirects or variables. More reliable options:
  - Use deny rules to stop `curl`, `wget` and similar commands, then `WebFetch(domain:github.com)` permission for
    allowed domains, paired with the sandbox network allowlist when the restriction must hold.
  - A `PreToolUse` hook that validates URLs in Bash commands and blocks disallowed domains.
  - `CLAUDE.md` guidance describing allowed `curl` patterns: it "shapes what Claude tries but doesn't enforce a
    boundary, so pair it with one of the options above".

  Using WebFetch alone doesn't prevent network access: if Bash is allowed, Claude can still use `curl`, `wget` or
  other tools to reach any URL.
  [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- "Rules match tool calls, not intent": a `Read` deny rule catches `cat .env`, "because Claude Code recognizes the
  common file-reading commands", but "It won't catch a script that opens the file." The sandbox confines Claude's
  shell commands and "picks up your `Read` deny rules and `WebFetch(domain:...)` rules too, so for anything
  security-related you want both."
  [best-practices › Limit access with permission rules and the sandbox](https://code.claude.com/docs/en/best-practices#limit-access-with-permission-rules-and-the-sandbox)
- Check: where a deny or ask rule guards a command Claude could write another way, or constrains its arguments, is the
  rule backed by a `PreToolUse` hook that inspects the full command text, or by the sandbox for filesystem or network
  enforcement that doesn't depend on the command text, and does a deny rule that guards a secret or a domain have the
  sandbox on alongside it?

## Every session needs it: CLAUDE.md

- "Put it in CLAUDE.md if Claude should always know it: coding conventions, build commands, project structure,
  "never do X" rules." Rules without `paths` frontmatter also load at launch, so they suit the same content split
  into topic files: "Use rules to keep CLAUDE.md focused."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
  On project structure the pages disagree: best-practices says to write down only what isn't in the repo, so
  architecture and file layout stay out of CLAUDE.md
  ([best-practices › What you can stop doing](https://code.claude.com/docs/en/best-practices#what-you-can-stop-doing)).
- Check: the instruction applies in every session, whatever part of the codebase Claude works in.

## Context that never changes: CLAUDE.md, not a hook

- "For instructions that never change, prefer CLAUDE.md. It loads without running a script and is the standard place
  for static project conventions." A hook's `additionalContext` suits information about the current state of the
  environment or the operation that just ran.
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Compaction "summarizes the conversation to free space. This can lose important details", so a `SessionStart` hook
  with a `compact` matcher re-injects critical context after every compaction, and its command can be "any command
  that produces dynamic output, like `git log --oneline -5`". For a hook that injects context on every session start:
  "For injecting context on every session start, consider using CLAUDE.md instead."
  [hooks-guide › Re-inject context after compaction](https://code.claude.com/docs/en/hooks-guide#re-inject-context-after-compaction)
- After compaction, a project-root CLAUDE.md and unscoped rules are "Re-injected from disk", while "Context that hooks
  added earlier" is "Summarized with the rest of the conversation".
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)
- Check: is text that never changes held in CLAUDE.md or a rule rather than injected by a hook, with a hook kept for
  current state or for context that nothing else reloads after compaction?

## One part of the codebase: a path-scoped rule or a nested CLAUDE.md

- For CLAUDE.md: "If an entry is a multi-step procedure or only matters for one part of the codebase, move it to a
  skill or a path-scoped rule instead."
  [memory › When to add to CLAUDE.md](https://code.claude.com/docs/en/memory#when-to-add-to-claude-md)
- Rules with `paths` frontmatter "only load when Claude works with matching files, saving context."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Between the two:

  | Approach | File location | Loads when | Use when |
  | :- | :- | :- | :- |
  | Per-directory `CLAUDE.md` | Inside the directory, alongside its code | At launch when started from that directory, or on demand | Directory owners maintain their own conventions; instructions are versioned with the code |
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
- "A more capable model knows more about engineering, but not how *your* team does a release, what your incident
  runbook says, or how you want API docs written. That kind of knowledge goes in a skill". For a skill Claude can
  start on its own, "A long release procedure sitting in a skill doesn't weigh on your unrelated bug fix the way it
  would in `CLAUDE.md`."
  [best-practices › Put team procedures in skills](https://code.claude.com/docs/en/best-practices#put-team-procedures-in-skills)
- Check: no multi-step procedure or occasional reference material sits in CLAUDE.md or a rule without `paths`.

## Context Claude would otherwise explore for: a skill

- "A skill can give Claude domain knowledge so it doesn't have to explore." A "codebase-overview" skill could
  describe the project's architecture, key directories and naming conventions; when Claude invokes it, "it gets this
  context immediately instead of spending tokens reading multiple files to understand the structure."
  [costs › Offload processing to hooks and skills](https://code.claude.com/docs/en/costs#offload-processing-to-hooks-and-skills)
  best-practices adds a test for what to write down at all: leave it out if Claude could find it by reading the code
  and would go and look, but write down information that "takes a few minutes of digging to find" when "Claude has to
  redo that digging at the start of every session"
  ([best-practices › Tell Claude what it can't see](https://code.claude.com/docs/en/best-practices#tell-claude-what-it-cant-see)),
  and "The `CLAUDE.md` rule applies to skills too"
  ([best-practices › Put team procedures in skills](https://code.claude.com/docs/en/best-practices#put-team-procedures-in-skills)).
- Check: is context held in a skill only where Claude couldn't find it by reading the code, or would otherwise redo
  the digging for it every session, and left out where Claude could find it and would go and look?

## A skill with side effects is user-only

- For a skill, `disable-model-invocation: true` means Claude can't invoke the skill on its own: "Use this for
  workflows with side effects or that you want to control timing, like `/commit`, `/deploy`, or
  `/send-slack-message`. You don't want Claude deciding to deploy because your code looks ready."
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
- `disable-model-invocation: true` also stops the skill being preloaded into a subagent or run when a session-scoped
  scheduled task fires with it as the prompt. A `/loop` scheduled fire only runs skills Claude is allowed to invoke on
  its own, so a `disable-model-invocation: true` skill reaches Claude as plain text instead. Claude gets the
  instruction to run a `verify` or `simplify` skill before each commit only when Claude can invoke that skill.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
  [scheduled-tasks › Run a prompt repeatedly with /loop](https://code.claude.com/docs/en/scheduled-tasks#run-a-prompt-repeatedly-with-/loop)
  [skills › Run your checks before each commit](https://code.claude.com/docs/en/skills#run-your-checks-before-each-commit)
- Check: does each skill with side effects, or whose timing you want to control, such as one that commits, deploys or
  sends something, set `disable-model-invocation: true`? A skill meant for subagent preload, scheduled-task or
  `/loop` runs, or the commit-time `verify` instruction does not set it.

## Background knowledge is a skill only Claude invokes

- With `user-invocable: false`, "Only Claude can invoke the skill. Use this for background knowledge that isn't
  actionable as a command." Claude Code hides it from the `/` menu and doesn't run it when you type `/name`; its
  description stays in context ("Description always in context, full skill loads when invoked").
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- Check: use `user-invocable: false` for a skill that holds only background knowledge, with no action a user would run.

## About the response, not the project: an output style

- Put it in CLAUDE.md "if it's true of the project whatever style you're in". "Use an output style if it's about the
  response itself and you might want it off again: length, format, how much Claude explains, or a different role
  such as a writing assistant."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: CLAUDE.md holds no instructions about response length, format or role.

## Side work that returns a summary: a subagent

- "Use a subagent when you need context isolation or when your context window is getting full." Use one "when a side
  task would flood your main conversation with search results, logs, or file contents you won't reference again": the
  subagent "does that work in its own context and returns only the summary."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
  [sub-agents › Create custom subagents](https://code.claude.com/docs/en/sub-agents#page-title)
- The documentation's own subagent cases: tasks that produce verbose output you don't need in your main context,
  that need specific tool restrictions or permissions, or that are self-contained and can return a summary.
  [sub-agents › Choose between subagents and main conversation](https://code.claude.com/docs/en/sub-agents#choose-between-subagents-and-main-conversation)
- For independent investigations, several subagents can work at once, and this "works best when the research paths
  don't depend on each other."
  [sub-agents › Run parallel research](https://code.claude.com/docs/en/sub-agents#run-parallel-research)
  In the documentation's comparison of ways to run agents in parallel, subagents are "Delegated workers inside one
  session".
  [agents › Run agents in parallel](https://code.claude.com/docs/en/agents#page-title)
- "Subagents pay off in these situations": running independent pieces of work at the same time; keeping long output,
  "like a full test run or a wide search", out of your main conversation; "Getting a reviewer that hasn't seen how
  the code was written"; and giving a task fewer tools than the main session has. "What they cost you is mostly
  tokens", and sometimes time, since "a fresh subagent first has to gather context your conversation already had".
  By default it's the same model, or a smaller one, on the same task: "You get parallelism or a fresh pair of eyes out
  of it, but not a smarter answer."
  [best-practices › Know what subagents cost](https://code.claude.com/docs/en/best-practices#know-what-subagents-cost)
- On a full context window the pages disagree: features-overview says to use a subagent "when your context window is
  getting full", while best-practices lists "Use subagents to protect your context window" as advice current models
  have made unnecessary: "Running out of context is rarely the problem anymore."
  [best-practices › What you can stop doing](https://code.claude.com/docs/en/best-practices#what-you-can-stop-doing)
- Check: does each subagent serve one of the situations where subagents pay off: independent work run at the same
  time, long output kept out of the main conversation, a reviewer that hasn't seen the code written, or fewer tools?

## Back-and-forth or shared context: the main conversation

- Use the main conversation when the task needs frequent back-and-forth or iterative refinement, when multiple phases
  share significant context, "such as planning, implementation, and testing", when you're making a quick, targeted
  change, or when latency matters, since "A subagent that isn't a fork starts fresh and may need time to gather
  context". "Consider Skills instead when you want reusable prompts or workflows that run in the main conversation
  context rather than isolated subagent context."
  [sub-agents › Choose between subagents and main conversation](https://code.claude.com/docs/en/sub-agents#choose-between-subagents-and-main-conversation)
- For a question about something already in your conversation, use `/btw` instead of a subagent: it "sees your full
  context but has no tool access, and the answer isn't added to history."
  [sub-agents › Choose between subagents and main conversation](https://code.claude.com/docs/en/sub-agents#choose-between-subagents-and-main-conversation)
- Check: does a task that needs frequent back-and-forth, or shares significant context across phases, stay in the main
  conversation?

## A task that needs the conversation so far: a fork, not a context: fork skill

- "Despite the name, a skill with `context: fork` doesn't run in a fork of the current conversation, which would hand
  the subagent everything you've discussed so far. When the task depends on that history, fork the conversation
  instead of using `context: fork`."
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
  A subagent that a skill's `context: fork` starts, or that a `skills` field preloads, starts without your
  conversation history
  ([sub-agents › Preload skills into subagents](https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents)).
- "Use a fork when any other subagent would need too much background to be useful, or when you want to try several
  approaches in parallel from the same starting point." You start one with `/subtask` followed by a task, and Claude
  can start one on its own while fork mode is on, as it is by default; with agent view turned off, `/subtask` isn't
  available and `/fork` starts the forked subagent.
  [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- A fork's first request reuses the parent's prompt cache, and "a fork costs less than a fresh subagent for tasks that
  need the same context."
  [sub-agents › How forks differ from other subagents](https://code.claude.com/docs/en/sub-agents#how-forks-differ-from-other-subagents)
- Check: does a task that depends on the conversation's history run as a fork rather than as a skill with
  `context: fork` or a fresh subagent?

## Workers that coordinate among themselves: an agent team

- "Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share
  findings, challenge each other, and coordinate on their own." Subagents and agent teams compare as:
  [agent-teams › Compare with subagents](https://code.claude.com/docs/en/agent-teams#compare-with-subagents)

  | | Subagents | Agent teams |
  | :- | :- | :- |
  | **Context** | Own context window; results return to the caller | Own context window; fully independent |
  | **Communication** | Return a result to the caller. Subagents that Claude [named](https://code.claude.com/docs/en/sub-agents#subagent-names) when it spawned them can also [message each other](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup) | Teammates message each other directly |
  | **Coordination** | Main agent manages all work | Self-coordination through messages, plus a shared task list for [agents that have the Task tools](https://code.claude.com/docs/en/tools-reference#task-tool-availability) |
  | **Best for** | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
  | **Token cost** | Lower: results summarized back to main context | Higher: each teammate is a separate Claude instance |

  In a session started with agent teams enabled, Claude can name a subagent, and in an interactive session a
  subagent Claude spawns from the main conversation with a `name` launches as a teammate instead, unless the call is a
  fork or passes `isolation` on the call itself.
  [sub-agents › Subagent names](https://code.claude.com/docs/en/sub-agents#subagent-names)

- Agent teams "are most effective for tasks where parallel exploration adds real value": research and review,
  new modules or features, debugging with competing hypotheses, and cross-layer coordination. "Agent teams add
  coordination overhead and use significantly more tokens than a single session. They work best when teammates can
  operate independently. For sequential tasks, same-file edits, or work with many dependencies, a single session or
  subagents are more effective."
  [agent-teams › When to use agent teams](https://code.claude.com/docs/en/agent-teams#when-to-use-agent-teams)
- Agent teams are "Multiple coordinated sessions with a shared task list and inter-agent messaging, managed by a
  lead. Experimental and disabled by default."
  [agents › Run agents in parallel](https://code.claude.com/docs/en/agents#page-title)
  Where Claude plans, assigns and supervises a group of workers, that is an agent team; where Claude delegates and
  collects results inside one conversation, it is subagents. Subagents report results back to the conversation that
  spawned them, while teammates message each other directly. Agent teams don't isolate teammates in worktrees, so
  partition the work so each teammate owns a different set of files.
  [agents › Choose an approach](https://code.claude.com/docs/en/agents#choose-an-approach)
- Check: do the workers need to share findings, challenge each other or coordinate on their own, the case the
  documentation gives agent teams for?

## Many subagents, or cross-checked findings: a dynamic workflow

- "Use a dynamic workflow when a job outgrows a handful of subagents, or when you want the findings cross-checked
  before you see them, such as a codebase-wide audit, a large migration, or a plan drafted from several angles."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
  A dynamic workflow is "A script that runs many subagents and cross-checks their results, for work too big to
  coordinate one turn at a time or that needs more than a single pass", and a script holds the plan instead of
  Claude's turn-by-turn judgment.
  [agents › Run agents in parallel](https://code.claude.com/docs/en/agents#page-title)
  [agents › Choose an approach](https://code.claude.com/docs/en/agents#choose-an-approach)
- Subagents, skills, agent teams and workflows can all run a multi-step task; "The difference is who holds the plan":
  [workflows › When to use a workflow](https://code.claude.com/docs/en/workflows#when-to-use-a-workflow)

  | | Subagents | Skills | Agent teams | Workflows |
  | :- | :- | :- | :- | :- |
  | What it is | A worker Claude spawns | Instructions Claude follows | A lead agent supervising peer sessions | A script the runtime executes |
  | Who decides what runs next | Claude, turn by turn | Claude, following the prompt | The lead agent, turn by turn | The script |
  | Where intermediate results live | Claude's context window | Claude's context window | A shared task list | Script variables |
  | What's repeatable | The worker definition | The instructions | The team definition | The orchestration itself |
  | Scale | A few delegated tasks per turn | Same as subagents | A handful of long-running peers | Dozens to hundreds of agents per run |
  | Interruption | Restarts the turn | Restarts the turn | Teammates keep running | Resumable in the same session |

  "A workflow moves the plan into code. With subagents, skills, and agent teams, Claude is the orchestrator: it
  decides turn by turn what to spawn or assign next, and every result goes into a context window. A workflow script
  holds the loop, the branching, and the intermediate results itself, so Claude's context holds only the final
  answer." It can also "have independent agents adversarially review each other's findings before they're reported,
  or draft a plan from several angles and weigh them against each other, so you get a more trustworthy result than a
  single pass."
- Check: does the job outgrow a handful of subagents, or need its findings cross-checked before you see them?

## An external system: a CLI or MCP, with a skill for using it

- For a system Claude can't see, such as an issue tracker: "If that system has a CLI, that's usually the easiest way
  in." "For a CLI it hasn't seen before, pointing it at `--help` is enough. For systems without a CLI, there's MCP."
  [best-practices › Connect the tools Claude needs](https://code.claude.com/docs/en/best-practices#connect-the-tools-claude-needs)
- "MCP gives Claude purpose-built tools for an external system, with the connection and authentication handled by
  the server." "Skills give Claude knowledge about how to use those tools effectively, plus workflows you can
  trigger with `/<name>`."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: an external system with a CLI is reached through its CLI where that's the easiest way in, one without
  through MCP, and knowledge about how to use its tools, and workflows, lives in a skill, not in the connection.

## The same setup in another repository: a plugin

- "Use plugins when you want to reuse the same setup across multiple repositories or distribute to others via a
  marketplace."
  [features-overview › Match features to your goal](https://code.claude.com/docs/en/features-overview#match-features-to-your-goal)
- Check: a setup copied into a second repository is proposed as a plugin instead.

## Instructions shipped in a plugin are skills

- "To include instructions in a plugin, write them as a skill. Claude Code doesn't load a `CLAUDE.md` at the plugin
  root, and `claude plugin validate` warns `CLAUDE.md at the plugin root is not loaded as project context`."
  [plugins/components › Skills](https://code.claude.com/docs/en/plugins/components#skills)
- Check: does a plugin that must carry instructions hold them in a skill, not in a plugin-root `CLAUDE.md`?

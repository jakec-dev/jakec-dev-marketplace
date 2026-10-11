# Loading instruction files

When each CLAUDE.md file and rule enters Claude's context and in what order: at launch, on file access, after
compaction, after mid-session edits, and in subagents, worktrees, agent teams and the auto mode classifier.

## Contents

- [At launch and on file access](#at-launch-and-on-file-access)
- [After compaction](#after-compaction)
- [Mid-session edits](#mid-session-edits)
- [In subagents](#in-subagents)
- [In agent teams](#in-agent-teams)
- [In the auto mode classifier](#in-the-auto-mode-classifier)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## At launch and on file access

- Claude Code loads `CLAUDE.md` and `CLAUDE.local.md` from your current working directory and every directory above
  it. Run Claude Code in `foo/bar/` and it loads instructions from `foo/bar/CLAUDE.md`, `foo/CLAUDE.md`, and any
  `CLAUDE.local.md` files alongside them.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- CLAUDE.md and CLAUDE.local.md files in the directory hierarchy above the working directory are loaded at launch.
  [memory › Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files)
- CLAUDE.md scopes load from broadest scope to most specific (managed policy, user, project, local), so a project
  instruction appears in context after a user instruction.
  [memory › Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files)
- All discovered files are concatenated into context rather than overriding each other. Across the directory tree,
  content is ordered from the filesystem root down to your working directory, so `foo/CLAUDE.md` appears before
  `foo/bar/CLAUDE.md` and instructions closer to where you launched Claude are read last. Within each directory,
  `CLAUDE.local.md` is appended after `CLAUDE.md`, so it is the last thing Claude reads at that level.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- Claude also discovers `CLAUDE.md` and `CLAUDE.local.md` files in subdirectories under your current working
  directory. Instead of loading them at launch, Claude Code loads them on demand when Claude reads files in those
  subdirectories: subdirectory `CLAUDE.md` files load after Claude uses the Read, Write, or Edit tool on a file in
  that directory, not at session start. `claudeMdExcludes` can skip other teams' files in a large monorepo.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load),
  [memory › Choose where to put CLAUDE.md files](https://code.claude.com/docs/en/memory#choose-where-to-put-claude-md-files),
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- In a prompt, @ file references add `CLAUDE.md` in the file's directory and parent directories to context.
  [common-workflows › Reference files and directories](https://code.claude.com/docs/en/common-workflows#reference-files-and-directories)
- When you run `/cd <path>` to move the session to a different primary working directory, Claude Code keeps the
  conversation and loads the new directory's `CLAUDE.md`.
  [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- Rules without `paths` frontmatter in the project's `.claude/rules/` are loaded at launch with the same priority as
  `.claude/CLAUDE.md`.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- Rules in nested `.claude/rules/` directories load on demand, as path-scoped rules do.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- Path-scoped rules trigger when Claude uses the Read, Write, or Edit tool on a file matching the pattern, not on
  every tool use. Matching also works when Claude reaches a file through a symlinked path to the project directory,
  for example in a symlinked checkout.
  [memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)
- Claude Code loads user-level rules (`~/.claude/rules/`) before project rules, so a project rule appears later in
  Claude's context than a user rule. Neither set overrides the other: if a user rule and a project rule conflict,
  Claude may follow either one, so keep the two consistent.
  [memory › User-level rules](https://code.claude.com/docs/en/memory#user-level-rules)
- Claude Code orders each request so content that rarely changes between turns comes first. CLAUDE.md and unscoped
  rules sit in the project context layer, after the system prompt and before the conversation. The third column
  gives common triggers rather than an exhaustive list.
  [prompt-caching › How the cache is organized](https://code.claude.com/docs/en/prompt-caching#how-the-cache-is-organized)

  | Layer | Content | Changes when |
  | - | - | - |
  | Project context | CLAUDE.md, auto memory, unscoped rules | Session starts, or after `/clear` or `/compact` |

## After compaction

- When a long session compacts, Claude Code summarizes the conversation history to fit the context window. What
  happens to each kind of content depends on how it was loaded:
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

  | Mechanism | After compaction |
  | :- | :- |
  | Project-root CLAUDE.md and unscoped rules | Re-injected from disk |
  | Rules with `paths:` frontmatter | Claude Code reloads them as Claude reads files they match |
  | Nested CLAUDE.md in subdirectories | Claude Code reloads them as Claude reads files in that subdirectory |

- Path-scoped rules and nested CLAUDE.md files load into message history when their trigger file is read, so
  compaction summarizes them away with everything else. If a rule must persist across compaction, drop the `paths:`
  frontmatter or move it to the project-root CLAUDE.md.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

## Mid-session edits

- Project-root and user-level CLAUDE.md files are read once at session start and held in memory. Editing them
  mid-session does not invalidate the cache, but the edit also doesn't apply: Claude keeps working with the version
  loaded at session start, and the new content loads on the next `/clear`, `/compact`, or restart.
  [prompt-caching › Editing CLAUDE.md mid-session](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session)
- Nested CLAUDE.md files in subdirectories and rules with `paths:` frontmatter load later, when Claude first reads a
  matching file. Editing one before it loads does take effect. After it loads, the content is part of the
  conversation history, so a mid-session edit doesn't retroactively change it.
  [prompt-caching › Editing CLAUDE.md mid-session](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session)

## In subagents

- Each subagent starts with a fresh, isolated context window and doesn't see your conversation history or the files
  Claude has already read. The exception is a fork, which inherits the parent conversation instead of starting fresh.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- A non-fork subagent's initial context contains every level of the CLAUDE.md hierarchy the main conversation loads,
  including `~/.claude/CLAUDE.md`, project rules, `CLAUDE.local.md`, managed policy files, and any `AGENTS.md` files
  loaded as project instructions. The built-in Explore and Plan agents skip this.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- A subagent whose definition sets `omitClaudeMd` loads only the managed policy files, or none at all when the
  definition comes from managed settings. To launch one of your own subagents without the user, project, and local
  CLAUDE.md files, set `omitClaudeMd: true` in its frontmatter or `--agents` JSON. `omitClaudeMd` is ignored when
  the agent runs as the main session agent via `--agent` or the `agent` setting.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup),
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- The main conversation still has your full CLAUDE.md when it reads these subagents' results, so most rules don't
  need to reach the subagent itself. If a rule must, such as "ignore the `vendor/` directory," restate it in the
  prompt you give Claude when delegating.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- A subagent runs in its own worktree when you ask Claude to "use worktrees for your agents" or its frontmatter sets
  `isolation: worktree`. It takes the instruction files it starts with from your main conversation, not from its
  worktree. When that worktree is in the default location under `.claude/worktrees/`, the subagent also doesn't load
  the `CLAUDE.md` file or `.claude/rules/` directory at the worktree's root as it reads files there, even if those
  differ on the worktree's branch.
  [worktrees › Isolate subagents with worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees)

## In agent teams

- Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular
  session, including CLAUDE.md.
  [agent-teams › Context and communication](https://code.claude.com/docs/en/agent-teams#context-and-communication)
- If you start the lead with `--setting-sources`, teammates load from the same restricted list of sources, and
  split-pane teammates do too.
  [agent-teams › Context and communication](https://code.claude.com/docs/en/agent-teams#context-and-communication)

## In the auto mode classifier

- The classifier reads the same CLAUDE.md content Claude itself loads, so an instruction like "never force push" in
  your project's CLAUDE.md steers both Claude and the classifier at the same time.
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)

## Not stated by the documentation

- @ file references in a prompt are stated to add `CLAUDE.md`; the documentation does not say whether they also add
  `CLAUDE.local.md` or path-scoped rules that match the file.
  [common-workflows › Reference files and directories](https://code.claude.com/docs/en/common-workflows#reference-files-and-directories)
- `/cd` is stated to load the new directory's `CLAUDE.md`; the documentation does not say whether it also loads that
  directory's `CLAUDE.local.md`, rules or parent directories' files, or whether the previous directory's CLAUDE.md
  stays in context.
  [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- The documentation does not say where `.claude/CLAUDE.md` comes in a directory's order relative to `CLAUDE.md` and
  `CLAUDE.local.md`, or what happens when a directory has both `CLAUDE.md` and `.claude/CLAUDE.md`.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- Mid-session edits are described for CLAUDE.md files and path-scoped rules; for unscoped rules the documentation
  gives only the project context layer's common triggers (session start, `/clear`, `/compact`), and does not say
  outright that an edit to an unscoped rule waits for one of them. It also does not say whether an edit to a
  `CLAUDE.local.md` above the working directory waits the same way.
  [prompt-caching › Editing CLAUDE.md mid-session](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session)
- The documentation does not say whether a path-scoped rule or a subdirectory's CLAUDE.md loads when a subagent reads
  a matching file, outside a worktree or in a worktree outside the default location.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup),
  [worktrees › Isolate subagents with worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees)
- The documentation does not say whether, or when, `.claude/rules/` directories above the working directory load.
  The `claudeMdExcludes` example excludes a rules directory from a parent folder, and an Agent SDK page lists
  `.claude/rules/*.md` in every parent directory for its own surface.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- The documentation does not say in what order the files in `.claude/rules/` load, or whether unscoped rules come
  before or after `.claude/CLAUDE.md`, which they share a priority with.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- After compaction Claude Code re-reads up to five recently modified files Claude read or edited; the documentation
  does not say whether that re-read reloads path-scoped rules or nested CLAUDE.md files that match those files.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)
- Rules in nested `.claude/rules/` directories are stated to load on demand when Claude reads a file in that
  subdirectory only in the `managed-only` value's description; the documentation does not say so for the default.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)
- The documentation does not say how deep below the working directory nested `.claude/rules/` directories are found.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- The documentation does not say whether a `paths` field in a rule in a nested `.claude/rules/` directory must also
  match.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules)
- What survives compaction and mid-session edits are stated for path-scoped rules and nested CLAUDE.md files; the
  documentation does not say what happens to rules in nested `.claude/rules/` directories.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

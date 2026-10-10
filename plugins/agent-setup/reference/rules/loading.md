# Loading rules

When a rule enters Claude's context, in what order, and what happens after compaction, mid-session edits, in
subagents and alongside `AGENTS.md`.

## Contents

- [At launch and on file access](#at-launch-and-on-file-access)
- [After compaction](#after-compaction)
- [Mid-session edits](#mid-session-edits)
- [In subagents](#in-subagents)
- [Alongside AGENTS.md](#alongside-agentsmd)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## At launch and on file access

- Rules without `paths` frontmatter are loaded at launch with the same priority as `.claude/CLAUDE.md`.
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
- Claude Code orders each request so content that rarely changes between turns comes first. Unscoped rules sit in
  the project context layer, after the system prompt and before the conversation. The third column gives common
  triggers rather than an exhaustive list.
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
  CLAUDE.md files, set `omitClaudeMd: true` in its frontmatter or `--agents` JSON.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
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

## Alongside AGENTS.md

- By default, Claude reads `AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it. A
  `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory above it counts,
  so Claude reads it instead of `AGENTS.md`. `~/.claude/CLAUDE.md`, your organization's managed `CLAUDE.md`, and
  `.claude/rules/` files don't count, and keep loading alongside `AGENTS.md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- When none count, Claude reads every `AGENTS.md` and `.claude/AGENTS.md` in your working directory and the
  directories above it at session start; an interactive session shows a line such as
  `no CLAUDE.md found; AGENTS.md loaded: /home/you/repo/AGENTS.md`. It reads a subdirectory's `AGENTS.md` when
  Claude opens a file there with the Read tool and that subdirectory has none of the three `CLAUDE.md` files.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- Inside each `AGENTS.md`, `@path` imports are expanded, `claudeMdExcludes` patterns apply, and subagents that skip
  project instructions skip these files too. Claude doesn't read `AGENTS.local.md`, `AGENTS.override.md`, or
  anything under a `.agents/` directory.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- Because `CLAUDE.local.md` counts, adding one in a project that relies on `AGENTS.md` stops Claude from reading
  `AGENTS.md` for you. To keep it and still have Claude read `AGENTS.md`, set **Project instructions** to
  `claude-md-and-agents-md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- What that value of **Project instructions** reads:
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

  | Value | What Claude reads |
  | :- | :- |
  | `claude-md-and-agents-md` | Your `CLAUDE.md` and `AGENTS.md` files together, each directory's `CLAUDE.md` files first and its `AGENTS.md` after them. Claude Code skips an `AGENTS.md` it has already loaded, so one that your `CLAUDE.md` imports or symlinks to isn't read twice |


## Not stated by the documentation

- Mid-session edits are described for CLAUDE.md files and path-scoped rules; for unscoped rules the documentation
  gives only the project context layer's common triggers (session start, `/clear`, `/compact`), and does not say
  outright that an edit to an unscoped rule waits for one of them.
  [prompt-caching › Editing CLAUDE.md mid-session](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session)
- The documentation does not say whether a path-scoped rule loads when a subagent reads a matching file, outside a
  worktree or in a worktree outside the default location.
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
  does not say whether that re-read reloads path-scoped rules that match those files.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)
- A subdirectory's `.claude/rules/` files still load when Claude reads a file there, as the `managed-only` value
  states; the documentation does not say whether a `paths` field in such a rule must also match.
  [memory › Set up rules](https://code.claude.com/docs/en/memory#set-up-rules),
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)
- Under the default `claude-md-or-agents-md`, whose row names only `CLAUDE.md` and `AGENTS.md` files,
  `.claude/rules/` files keep loading, and only the `managed-only` row lists them as left out; the documentation does
  not say outright that they also load under `claude-md-and-agents-md` and `claude-md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md),
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

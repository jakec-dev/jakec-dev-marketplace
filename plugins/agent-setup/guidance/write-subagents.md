# Writing subagents

Writing a subagent's description, prompt, tools, model, memory and isolation so that Claude delegates to it and it does
the job.

## Contents

- Subagents do one task
- Subagent descriptions say when to delegate, and single one out
- Subagent prompts give the steps, the checks and the shape of the report
- Subagents return a short summary
- Reviewer subagents check against a spec and skip style
- Subagent tools are only those the task needs
- Subagents that shouldn't delegate leave Agent out of tools
- A subagent's partial tool limits: the prompt states them, a hook backs them
- An MCP server only one subagent needs is defined in its mcpServers
- omitClaudeMd only for subagents that take everything they need from the delegation prompt
- Subagents doing simple work set `model: haiku`
- Subagent memory defaults to project scope
- Subagents with memory say what to record
- Subagents that edit files in parallel run in worktrees

## Subagents do one task

- "Design focused subagents: each subagent should excel at one specific task".
  [sub-agents › Example subagents](https://code.claude.com/docs/en/sub-agents#example-subagents)
- Check: does each subagent's description and prompt cover one specific task?

## Subagent descriptions say when to delegate, and single one out

- "Claude uses the description to decide when to delegate. Make each description specific enough to route to the right
  subagent, and keep the combined set within the 15,000-token description budget."
  [sub-agents › Example subagents](https://code.claude.com/docs/en/sub-agents#example-subagents)
- Descriptions take up context, so keep them short: "Trim the `description` fields of your subagents, and move detail
  into each subagent's system prompt, which only loads when that subagent runs."
  [sub-agents › Create custom subagents](https://code.claude.com/docs/en/sub-agents#page-title)
- Claude delegates based on the task description in your request, the `description` field in subagent configurations,
  and current context. "To encourage proactive delegation, include phrases like 'use proactively' in your subagent's
  description field." The documentation's debugger example does this:
  [sub-agents › Understand automatic delegation](https://code.claude.com/docs/en/sub-agents#understand-automatic-delegation)

  ```yaml
  description: Debugging specialist for errors, test failures, and unexpected behavior. Use proactively when encountering any issues.
  ```

  [sub-agents › Debugger](https://code.claude.com/docs/en/sub-agents#debugger)
- Over the budget, Claude Code shows a startup warning and still loads every agent; the fix is to shorten the
  `description` frontmatter, or remove agent files you no longer use.
  [errors › Agent descriptions are over the 15.0k-token limit](https://code.claude.com/docs/en/errors#agent-descriptions-are-over-the-15000-token-limit)
- Check: does each description say when to delegate, specifically enough to route to this subagent and no other?

## Subagent prompts give the steps, the checks and the shape of the report

- The documentation's code reviewer has "a detailed prompt that specifies exactly what to look for and how to format
  output". Its prompt, shortened:
  [sub-agents › Code reviewer](https://code.claude.com/docs/en/sub-agents#code-reviewer)

  ```markdown
  When invoked:
  1. Run git diff to see recent changes
  2. Focus on modified files
  3. Begin review immediately

  Review checklist:
  - Code is clear and readable
  - No exposed secrets or API keys
  - Good test coverage

  Provide feedback organized by priority:
  - Critical issues (must fix)
  - Warnings (should fix)
  - Suggestions (consider improving)
  ```

- The documentation's debugger example has "a clear workflow from diagnosis to verification": capture the error
  message and stack trace, identify reproduction steps, isolate the failure location, implement a minimal fix, then
  verify the solution works.
  [sub-agents › Debugger](https://code.claude.com/docs/en/sub-agents#debugger)
- Check: does the subagent's prompt specify what to look for and how to format its output?

## Subagents return a short summary

- When subagents complete, their results return to the main conversation. "Running many subagents that each return
  detailed results can consume significant context, and each subagent spends tokens of its own while it runs."
  [sub-agents › Run parallel research](https://code.claude.com/docs/en/sub-agents#run-parallel-research)
- "Ask for short summaries back, so twenty results don't fill your context anyway."
  [best-practices › Know what subagents cost](https://code.claude.com/docs/en/best-practices#know-what-subagents-cost)
- In a prompt that delegates high-volume work, name the result wanted:
  [sub-agents › Isolate high-volume operations](https://code.claude.com/docs/en/sub-agents#isolate-high-volume-operations)

  ```text
  Use a subagent to run the test suite and report only the failing tests with their error messages
  ```

- Check: does the subagent's prompt, or the delegation, ask only for the result the caller needs, such as the failing
  tests with their errors?

## Reviewer subagents check against a spec and skip style

- In a review prompt that checks work against your plan, name the spec and end with `skip style`:
  [best-practices › Review against your spec](https://code.claude.com/docs/en/best-practices#review-against-your-spec)

  ```text
  use a subagent to review the rate limiter diff against SPEC.md, check every requirement is implemented and the listed edge cases have tests, report gaps that affect correctness and skip style
  ```

  The note on that prompt: "Don't drop the `skip style` part of that prompt. A reviewer that's asked to find problems
  will always find *something*. If you fix every finding, you end up with extra abstraction layers and tests for cases
  that can't happen."
- The documentation shows the same instruction in a subagent definition, `.claude/agents/reviewer.md`:
  [best-practices › Know what subagents cost](https://code.claude.com/docs/en/best-practices#know-what-subagents-cost)

  ```markdown
  ---
  name: reviewer
  description: Reviews changed files against the spec they were built from. Use after implementing a feature, before opening the PR.
  tools: Read, Grep, Glob
  ---
  You're reviewing code you didn't write. Compare the changed files against the spec you're given,
  check that every requirement is implemented and the listed edge cases have tests,
  and report only the gaps that affect correctness. Skip style.
  ```

  Asking Claude to `have the reviewer compare the rate limiter against SPEC.md` brings the gaps back into the session,
  where Claude can fix them.
- Check: does a reviewer subagent's prompt name what to review against and say to skip style?

## Subagent tools are only those the task needs

- "Limit tool access: grant only necessary permissions for security and focus."
  [sub-agents › Example subagents](https://code.claude.com/docs/en/sub-agents#example-subagents)
- The documentation's code reviewer is read-only: its `tools` is `Read, Grep, Glob, Bash`, which excludes Edit and
  Write and keeps Bash. The debugger, by contrast, includes Edit "because fixing bugs requires modifying code".
  [sub-agents › Code reviewer](https://code.claude.com/docs/en/sub-agents#code-reviewer)
- Giving a custom subagent in `.claude/agents/` only `tools: Read, Grep, Glob` makes a reviewer that can't edit
  anything, "and that limit is enforced by Claude Code rather than requested in a prompt."
  [best-practices › Know what subagents cost](https://code.claude.com/docs/en/best-practices#know-what-subagents-cost)
- With `memory` set, "Read, Write, and Edit tools are automatically enabled so the subagent can manage its memory
  files".
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- Check: does each subagent's `tools` list only the tools its task needs?

## Subagents that shouldn't delegate leave Agent out of tools

- By default, a subagent can spawn subagents of its own, up to three layers below the main conversation. "To keep one
  subagent from spawning while nesting is on, such as a reviewer that should stay read-only, omit `Agent` from its
  `tools` list or add it to `disallowedTools`."
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)
- An `Agent(type)` list in a subagent definition doesn't restrict which types it spawns: the allowlist syntax applies
  only to an agent running as the main thread with `claude --agent`, and in a subagent definition any type list inside
  the parentheses is ignored. Leave `Agent` out instead.
  [sub-agents › Restrict which subagents can be spawned](https://code.claude.com/docs/en/sub-agents#restrict-which-subagents-can-be-spawned)
- Check: does a subagent that should not spawn subagents, such as a read-only reviewer, either set a `tools` list
  without `Agent` or list `Agent` in `disallowedTools`, rather than leave both fields unset, which inherits `Agent`
  while nesting is on?

## A subagent's partial tool limits: the prompt states them, a hook backs them

- Use `PreToolUse` hooks for conditional validation "when you need finer control than the `tools` field provides". The
  documentation's `db-reader` allows Bash but validates each command to permit only read-only SQL queries; its
  frontmatter, shortened:
  [sub-agents › Database query validator](https://code.claude.com/docs/en/sub-agents#database-query-validator)

  ```yaml
  name: db-reader
  tools: Bash
  hooks:
    PreToolUse:
      - matcher: "Bash"
        hooks:
          - type: command
            command: "./scripts/validate-readonly-query.sh"
  ```

- "The system prompt tells the subagent to refuse write requests, so the hook is a backstop: if the subagent attempts
  a write anyway, Claude Code blocks the command and the subagent sees the `Blocked: Write operations not allowed. Use
  SELECT queries only.` message." Write both: the prompt says what the subagent may not do, and the hook blocks it.
  [sub-agents › Database query validator](https://code.claude.com/docs/en/sub-agents#database-query-validator)
- To block specific commands for the main conversation and every subagent alike, a Bash deny rule such as
  `Bash(git push *)` in `permissions.deny` does it; a `disallowedTools` entry with a specifier removes the whole tool.
  [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
- A plugin agent ignores `hooks`, so put this hook in a project or user agent, not a plugin's.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents)
- Check: where a subagent may use a tool only in some ways, is the rest blocked by a `PreToolUse` hook in a
  non-plugin agent's frontmatter or, for specific Bash commands, by a deny rule in `permissions.deny`?

## An MCP server only one subagent needs is defined in its mcpServers

- "To keep an MCP server out of the main conversation entirely and avoid its tool descriptions consuming context
  there, define it inline here rather than in `.mcp.json`. The subagent gets the tools; the parent conversation
  doesn't." The documentation's example, shortened:
  [sub-agents › Scope MCP servers to a subagent](https://code.claude.com/docs/en/sub-agents#scope-mcp-servers-to-a-subagent)

  ```yaml
  mcpServers:
    # Inline definition: scoped to this subagent only
    - playwright:
        type: stdio
        command: npx
        args: ["-y", "@playwright/mcp@latest"]
  ```

- Claude Code loads an inline MCP server from an agent file in the project's `.claude/agents/` directory, or in an
  `--add-dir` directory's `.claude/agents/`, only after you trust the folder the agent file came from; until then it
  skips every inline server in that file. A server in an agent file from `~/.claude/agents/` loads without that
  check. A parent folder's trust, and the automatic trust a `-p` or SDK session gets for hooks in settings files,
  don't count.
  [sub-agents › Trust required for inline MCP servers](https://code.claude.com/docs/en/sub-agents#inline-server-trust)
- A `tools` allowlist with no MCP entry gives the subagent no MCP tools, so with `tools` set, list the server's tools
  too, such as `mcp__playwright__*`.
  [sub-agents › Restrict which tools a subagent can use](https://code.claude.com/docs/en/sub-agents#restrict-which-tools-a-subagent-can-use)
- A plugin agent ignores `mcpServers`.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- Check: is an MCP server that only one subagent uses, and that the main conversation doesn't need, defined inline in
  that subagent's `mcpServers` so its tools stay out of the main conversation?

## omitClaudeMd only for subagents that take everything they need from the delegation prompt

- Set `omitClaudeMd: true` to start a subagent without the user, project, and local CLAUDE.md files in its initial
  context; managed policy files still load, except for managed subagents. "Use it for subagents that take everything
  they need from the delegation prompt."
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- "The main conversation still has your full CLAUDE.md when it reads these subagents' results, so most rules don't
  need to reach the subagent itself." The subagents meant are Explore, Plan and subagents with `omitClaudeMd`. "If a
  rule must, such as 'ignore the `vendor/` directory,' restate it in the prompt you give Claude when delegating."
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- Check: does each subagent that sets `omitClaudeMd` take everything it needs from the delegation prompt?

## Subagents doing simple work set `model: haiku`

- To spend less on subagents, "set `model: haiku` in a subagent's definition if its work is simple, like collecting
  the files that import a module or checking links in the docs. That kind of job doesn't need the bigger model, and
  Haiku costs a lot less per request."
  [best-practices › Know what subagents cost](https://code.claude.com/docs/en/best-practices#know-what-subagents-cost)
- "A switch to Opus also applies to the subagents that inherit your session's model."
  [costs › Choose the right model](https://code.claude.com/docs/en/costs#choose-the-right-model)
- A `model` Claude passes for one invocation takes precedence over the definition's `model`, and while
  `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is on, Claude Code ignores the `model` field in subagent definitions.
  [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- Check: does a subagent whose work is simple, such as collecting the files that import a module, set `model: haiku`?

## Subagent memory defaults to project scope

- "`project` is the recommended default scope. It makes subagent knowledge shareable via version control."
  [sub-agents › Persistent memory tips](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- `user` keeps learnings across all projects, in `~/.claude/agent-memory/<name-of-agent>/`; `local` is for knowledge
  that is project-specific but shouldn't be checked in, in `.claude/agent-memory-local/<name-of-agent>/`. Choose one
  when the knowledge should apply across all projects or is project-specific but shouldn't be checked in.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- With auto memory off, set by the `autoMemoryEnabled` setting or `CLAUDE_CODE_DISABLE_AUTO_MEMORY`, the `memory`
  field has no effect.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- Check: does a subagent with `memory` use `project` scope unless its knowledge should apply across all projects or
  shouldn't be checked in?

## Subagents with memory say what to record

- Include memory instructions directly in the subagent's markdown file "so it proactively maintains its own knowledge
  base":
  [sub-agents › Persistent memory tips](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)

  ```markdown
  Update your agent memory as you discover codepaths, patterns, library
  locations, and key architectural decisions. This builds up institutional
  knowledge across conversations. Write concise notes about what you found
  and where.
  ```

- Check: does the prompt of a subagent with `memory` tell it what to record?

## Subagents that edit files in parallel run in worktrees

- When tasks touch the same files: "Isolate the work with worktrees. Subagents and sessions you run yourself can each
  use a separate worktree."
  [agents › Choose an approach](https://code.claude.com/docs/en/agents#choose-an-approach)
- For a subagent, set `isolation: worktree` in its frontmatter, which runs it in a temporary git worktree, an isolated
  copy of the repository branched by default from your default branch rather than the parent session's `HEAD`.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
  For subagents that need to work on unpushed commits or feature-branch state, set `worktree.baseRef` to `"head"` in
  settings, not frontmatter, which makes every new worktree branch from your current local `HEAD`; a
  worktree is a fresh checkout, so gitignored files such as `.env` are copied in only when a `.worktreeinclude` file
  at the project root names them.
  [worktrees › Choose the base branch](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)
  [worktrees › Copy gitignored files into worktrees](https://code.claude.com/docs/en/worktrees#copy-gitignored-files-into-worktrees)
- With agent teams enabled in an interactive session, an `isolation` value in the subagent's frontmatter doesn't stop
  a subagent that Claude spawns from the main conversation with a `name` launching as a teammate, and the teammate
  then runs in the main session's working directory.
  [sub-agents › Subagent names](https://code.claude.com/docs/en/sub-agents#subagent-names)
- Check: do subagents that may edit the same files in parallel set `isolation: worktree`?

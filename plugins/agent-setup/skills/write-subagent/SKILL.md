---
name: write-subagent
description: Writes, fixes or explains a Claude Code subagent, or says when another tool fits better. Use when the user wants a specialised worker Claude can delegate to, such as a reviewer, researcher or test runner, or asks why a subagent isn't loading, being chosen or behaving as configured.
allowed-tools: Read, Glob, Grep
---

# Write a subagent

Base the work on the plugin's reference, which says how Claude Code finds, chooses and runs subagents, and its
guidance, which says what makes a subagent good. Not on memory: much of what goes wrong with a subagent fails
silently, with a field ignored or a file skipped and no error in the session.

A subagent is defined in a Markdown file in `.claude/agents/`, `~/.claude/agents/` or a plugin's `agents/`, or as JSON
passed to `claude --agents`.

1. **Read both indexes in full:** `${CLAUDE_PLUGIN_ROOT}/reference/subagents/index.md` and
   `${CLAUDE_PLUGIN_ROOT}/guidance/index.md`. Their key facts and key principles apply to every task.
2. **Read `${CLAUDE_PLUGIN_ROOT}/guidance/write-subagents.md` in full,** then pick the other sections the task needs
   from the two Topics lists. Read each one: find its `## ` heading with Grep, then Read from that line to the next
   `## ` heading.
   - To write or fix a definition, always read `placing.md` for the scope and `frontmatter.md › Frontmatter fields`,
     and `frontmatter.md › Plugin agents` for an agent in a plugin.
   - Read the `tools.md` sections for the tools, MCP servers and permission mode the subagent uses.
   - The subagents reference leaves the `hooks` field to the hooks reference: for it, read
     `${CLAUDE_PLUGIN_ROOT}/reference/hooks/placing.md › Skill and subagent frontmatter`.
   - To explain why a subagent doesn't load, launch, get chosen or behave, read `troubleshooting.md`, and
     `observing.md` when the subagent runs in `-p`, the Agent SDK or under telemetry.
3. **Find the subagents that already exist** with Glob: `.claude/agents/**/*.md` in the working directory and each
   directory above it up to the repository root, `~/.claude/agents/**/*.md`, and `agents/**/*.md` in a plugin, or the
   files its manifest `agents` key lists. Read the ones whose name or description is close to the new subagent's, so
   that no two files in one tree share a `name` and no description overlaps another
   (`write-subagents.md › Subagent descriptions say when to delegate, and single one out`).
4. **Check that a subagent is the right tool** against the `choose.md` sections from
   `Side work that returns a summary: a subagent` to `Many subagents, or cross-checked findings: a dynamic workflow`,
   and `Needed sometimes, or a procedure: a skill`. If the work needs back-and-forth with the user, it belongs in the
   main conversation; if it needs the conversation so far, it is a fork, not a skill with `context: fork`, which
   starts without that history; if it is a reusable procedure for the main conversation, a skill; if its workers
   coordinate among themselves, an agent team; if it outgrows a handful of subagents, a dynamic workflow. Say which
   tool fits and why, and offer that instead. A subagent can't ask the user questions: `AskUserQuestion` is removed
   from every subagent (`tools.md › Available tools`). Write the subagent anyway only if the user still wants it.
5. **Do the task:** write or fix the definition, or answer the question.
   - Pick the scope from `placing.md › Scopes and priority`: project for a codebase's subagents shared through
     version control, user for personal ones, a plugin to share across repositories, `--agents` for one session.
   - Write the frontmatter with field names and values exactly as `frontmatter.md › Frontmatter fields` gives them,
     or the `--agents` keys `placing.md › The --agents flag` lists.
   - Write the body as the subagent's whole system prompt: it gets this and basic environment details, not Claude
     Code's system prompt (`frontmatter.md › File format`).
   - Set `tools` and `disallowedTools` as `tools.md › Restricting tools` describes.
   - Make the result pass the `Check:` line of every guidance section you read. Where the reference lists something
     as not stated by the documentation, such as what an invalid `effort`, `color` or `permissionMode` value does,
     say so rather than guess.
6. **Check the silent failures** before calling it done. Each passes no error to the session:
   - [ ] Every field name matches `frontmatter.md › Frontmatter fields` exactly, camelCase included, or is `hooks`.
         In a subagent that loaded, `claude --debug` logs `does not recognize or apply` for any other.
   - [ ] For a project, user, managed or `--add-dir` agent, the file opens with `---` on its first line, its YAML
         parses, it has a `name` and a `description`, and its `name` doesn't start with `-`, contain `:` or exceed
         256 characters (`troubleshooting.md › Files that do not load`).
   - [ ] No other file under the same `agents` directory tree declares the same `name`
         (`placing.md › Project and user directories`).
   - [ ] Every built-in tool the subagent needs survives the background filter, which by default applies to a
         subagent Claude spawns from the main conversation, unless it will run in the foreground: Claude waits for
         it, which in an interactive session needs fork mode off, and it doesn't set `background: true`
         (`tools.md › Available tools`, `running.md › Letting Claude wait`).
   - [ ] An `Agent(type)` list is relied on to restrict spawning only for an agent run with `claude --agent`
         (`tools.md › Restricting which subagents can be spawned`).
   - [ ] A `permissionMode` is not relied on while the main conversation may be in `bypassPermissions`,
         `acceptEdits`, auto or plan mode (`tools.md › Permission modes`).
   - [ ] A plugin agent sets none of `permissionMode`, `mcpServers`, `initialPrompt` and `hooks`
         (`frontmatter.md › Plugin agents`). To use them, copy the agent file into `.claude/agents/` or
         `~/.claude/agents/`. `permissions.allow` rules in settings can stand in for `permissionMode`, and plugin MCP
         servers and hooks for `mcpServers` and `hooks`, but say that these apply to the whole session or whenever
         the plugin is enabled, not only inside the subagent (`placing.md › Plugin agents`,
         `${CLAUDE_PLUGIN_ROOT}/reference/hooks/placing.md › Plugin hooks`).
   - [ ] `autoCompactWindow` is a plain integer from `100000` to `1000000`, such as `200000`, not `200k`
         (`context.md › Auto-compaction`); `claude --debug` logs `invalid autoCompactWindow` for a value it ignores.
   - [ ] `cacheTtl` sits inside the `experimental` map, set to `5m` or `1h` (`frontmatter.md › Frontmatter fields`).
   - [ ] The user is told to restart when the file is the first in a new `agents` directory, sits under an
         `--add-dir` directory, or the session runs with `--disable-slash-commands`
         (`placing.md › Live reload and restarts`).
7. **Say how to verify it:** how to confirm the subagent loaded, a prompt that should delegate to it and one that
   should not, and where a delegation shows: a transcript row with the subagent's name and a short task description.
   `/context` lists custom subagents with their source. For a file that doesn't appear, `claude --debug` logs why for
   a bad `name`, a missing `description` or YAML that doesn't parse, but not for a file with no `name` or no
   frontmatter, which Claude Code treats as documentation; `claude plugin validate .claude/agents` finds frontmatter
   that doesn't parse, and `/doctor` reports two files in one directory with the same `name`
   (`troubleshooting.md › Files that do not load`, `placing.md › Project and user directories`). For a subagent
   shipped in a plugin, say to score its delegation with `claude plugin eval`
   (`verify.md › A plugin subagent's delegation is measured with claude plugin eval`).

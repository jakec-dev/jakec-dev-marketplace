# Skills reference

What Claude Code does with skills and custom commands: where they live, how they are written, invoked and loaded,
and how to turn them off or find out why one isn't working.

## Contents

- [Key facts](#key-facts)
- [Topics](#topics)

## Key facts

- A skill is a folder holding `SKILL.md`; a skill file at `.claude/skills/name.md` doesn't appear in `/skills`.
  See [troubleshooting.md › Check that the skill loaded](troubleshooting.md).
- Claude Code ignores a frontmatter field it doesn't recognise, without an error; names must match exactly.
  See [frontmatter.md › Format and parsing](frontmatter.md).
- Frontmatter is read only when `---` is the file's first line; YAML that doesn't parse loads the skill with no fields.
  See [frontmatter.md › Format and parsing](frontmatter.md).
- By default the combined `description` and `when_to_use` text of each skill is cut at 1,536 characters in the
  listing; put the key use first.
  See [loading.md › The listing's budget](loading.md).
- By default the listing gets 1% of the context window; over it, the least-used skills lose their descriptions and
  keep only their names, so Claude is less likely to choose them.
  See [loading.md › The listing's budget](loading.md).
- `disable-model-invocation: true` keeps the description out of context and stops Claude invoking the skill; it also
  stops the skill being preloaded into a subagent or run when a session-scoped scheduled task fires with it as the
  prompt.
  See [invoking.md › Who can invoke](invoking.md) and [frontmatter.md › Fields](frontmatter.md).
- With `user-invocable: false` you can't run the skill with `/name`, but Claude can still invoke it.
  See [invoking.md › Who can invoke](invoking.md).
- A `/name` after plain text, as a separate word with no punctuation attached, doesn't run the skill: Claude can run
  it while responding, and judges from your wording whether you asked it to.
  See [invoking.md › Where the name goes](invoking.md).
- Claude is told to run a `verify` or `simplify` skill before each commit, except for docs or tests, when at session
  start the skill loads from an enterprise, personal, project or added-directory location or `.claude/commands/`,
  Claude can invoke it, and `includeGitInstructions` is on. Plugin, bundled and claude.ai skills don't count.
  See [invoking.md › Checks before each commit](invoking.md).
- `allowed-tools` pre-approves tools for the invoking turn only and restricts nothing.
  See [permissions.md › Pre-approving tools with `allowed-tools`](permissions.md).
- An indexed placeholder such as `$2` with no argument stays in the content unchanged and doesn't count as receiving
  one, so if no other placeholder receives an argument, `ARGUMENTS: <value>` is appended. Write `\$1.00` for a literal
  dollar amount.
  See [writing.md › Arguments](writing.md) and [writing.md › Escaping and literal text](writing.md).
- In a plugin skill, `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` aren't in the environment of commands Claude
  runs through the Bash tool; write the `${...}` reference in the skill's content, where Claude Code substitutes it.
  See [writing.md › Plugin skills](writing.md).
- An invoked skill's content stays in context but Claude Code doesn't re-read the file on later turns, so write
  guidance that applies throughout a task as standing instructions.
  See [loading.md › Invoked skill content](loading.md).
- Auto-compaction keeps the first 5,000 tokens of each skill's latest invocation, 25,000 in all, filled from the most
  recently invoked; older skills can drop out. Put the most important instructions near the top.
  See [loading.md › After compaction](loading.md).
- A `.claude/skills/` below the start directory loads when Claude reads or edits a file there, or on `/add-dir`, and
  stays for the rest of the session.
  See [loading.md › Skills found during a session](loading.md).
- A top-level skills directory created mid-session isn't watched; run `/reload-skills` after each change there.
  See [loading.md › Changes on disk](loading.md).
- Inline `` !`command` `` runs only at the start of a line or after whitespace; after any other character, as in
  `` KEY=!`cmd` ``, it stays literal text and the command doesn't run.
  See [dynamic-context.md › Syntax](dynamic-context.md).
- A failed `` !`command` `` aborts the whole invocation. With the default `bash` shell, any non-zero exit fails,
  except exit 1 from `grep`, `rg`, `egrep`, `fgrep`, `find`, `diff`, `test`, `[`, `git diff` and `git grep`; exit 2
  or higher always fails. Append `|| true` to any other command you expect to exit non-zero.
  See [dynamic-context.md › Failures](dynamic-context.md).
- Injected commands never prompt: outside auto mode, any check result other than allow aborts the invocation, so
  pre-approve an unmatched command with `allowed-tools`.
  See [dynamic-context.md › Permission checks](dynamic-context.md).
- A `context: fork` skill's subagent doesn't see the conversation, so its content must be a task that stands alone.
  See [forking.md › What `context: fork` does](forking.md).
- A `context: fork` skill runs in the background unless it sets `background: false`, or runs with `-p` or the SDK,
  with `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`, while an earlier run of it is going, or when a session-scoped
  scheduled task fires with it as the prompt. An agent in a dynamic workflow that invokes one waits for its result.
  See [forking.md › Background or foreground](forking.md).
- A backgrounded fork loses every built-in tool outside a fixed set, other than `Agent` and `ExitPlanMode`, even one
  listed in its `tools` field, with no error unless the list resolves to nothing; `background: false` avoids that
  cut.
  See [forking.md › Tools in a background fork](forking.md).
- `paths` patterns are relative to Claude's current working directory; a skill with `paths` doesn't activate for
  files outside it, such as a sibling worktree, even one added with `/add-dir`.
  See [frontmatter.md › Fields](frontmatter.md) and [troubleshooting.md › Skill not triggering](troubleshooting.md).
- Stacked skills at the start of a message all load only at the terminal prompt; through `claude -p` or the Agent SDK,
  only the first loads and the rest of the line becomes its arguments.
  See [invoking.md › Where the name goes](invoking.md).
- Same name: enterprise beats personal beats project; your skill replaces a bundled command, but not its aliases.
  See [placing.md › Skills that share a name](placing.md).

## Topics

- [placing.md](placing.md): deciding where a skill or command file goes and what it is called (locations, nested and
  monorepo directories, worktrees, symlinks, reserved names, refused characters in names, name clashes, the
  added-directory prefix, command names, plugin skill layout, recorded `/run` and `/verify` recipes)
  - Locations
  - Command files
  - Monorepos, nested directories and worktrees
  - Reserved names
  - Refused characters in names
  - Skills that share a name
  - Run a same-named skill from an added directory
  - Synced skills that share a name
  - Command names
  - Plugin skill layout
  - Recorded run and verify recipes
  - Not stated by the documentation

- [frontmatter.md](frontmatter.md): writing a skill's frontmatter (every field, parsing, booleans, the spec subset for
  claude.ai and the API, `model` and `effort` interactions including the forked subagent's model, frontmatter `hooks`)
  - Format and parsing
  - Fields
  - Model
  - Effort
  - Hooks
  - Outside Claude Code
  - Not stated by the documentation

- [writing.md](writing.md): writing a skill's body (content types, conciseness, supporting files, string substitutions,
  arguments, escaping, bundled scripts, plugin skill variables and `user_config`, `ultrathink`, clarifying questions in
  auto mode)
  - Content types
  - Conciseness
  - Supporting files
  - String substitutions
  - Arguments
  - Escaping and literal text
  - Bundled scripts
  - Plugin skills
  - Deeper reasoning
  - Clarifying questions in auto mode
  - Not stated by the documentation

- [dynamic-context.md](dynamic-context.md): injecting shell output into a skill (`` !`cmd` `` and ```` ```! ```` blocks,
  the `shell` field, how commands run, failures, permission checks, `disableSkillShellExecution`)
  - Syntax
  - How commands run
  - Failures
  - Permission checks
  - Turning it off
  - Not stated by the documentation

- [invoking.md](invoking.md): controlling and making invocation (who can invoke, where the name goes, stacking, the
  Skill tool, scheduled tasks and `/loop`, monitors started by a skill, the commit-time `verify` and `simplify`
  instruction and the git-instruction switches, the bundled `/claude-api` subcommands, `-p`, GitHub Actions)
  - Who can invoke
  - Where the name goes
  - Which session a typed skill reaches
  - Scheduled runs with /loop
  - Monitors started by a skill
  - Checks before each commit
  - Bundled `/claude-api` skill
  - Non-interactive runs
  - Not stated by the documentation

- [permissions.md](permissions.md): tools during a skill and permission rules on skills (`allowed-tools`,
  `disallowed-tools`, workspace trust, `allowManagedPermissionRulesOnly`, pre-approval lost under the
  `strictPluginOnlyCustomization` hooks lock, `Skill(...)` rules, `UserPromptExpansion` and `PreToolUse`)
  - Pre-approving tools with `allowed-tools`
  - Removing tools with `disallowed-tools`
  - Workspace trust
  - When only managed permission rules apply
  - When managed settings lock hooks to plugins
  - Allowing and denying skills with `Skill(...)` rules
  - Hooks on skill invocation
  - Not stated by the documentation

- [forking.md](forking.md): running a skill in a subagent (`context: fork`, `agent`, `background`, tools, checkpoints,
  the output stream)
  - What `context: fork` does
  - Choosing the agent type
  - Background or foreground
  - Tools in a background fork
  - Checkpoints and `/rewind`
  - In the output stream

- [loading.md](loading.md): knowing when skill content enters and stays in context (the listing and its budget, the
  content lifecycle, compaction, live change detection, `/reload-skills`, `reloadSkills`, prompt caching, teammates)
  - The skill listing
  - The listing's budget
  - Skills found during a session
  - Invoked skill content
  - After compaction
  - Resumed sessions
  - Changes on disk
  - In subagents and agent teams
  - Not stated by the documentation

- [sharing.md](sharing.md): getting skills to more people or sessions (committing, managed deployment, plugins,
  `--add-dir`, skills synced from claude.ai)
  - Scopes for sharing
  - Added directories
  - Skills synced from claude.ai
  - What a synced skill can do
  - Not stated by the documentation

- [excluding.md](excluding.md): stopping skills from loading or being seen (`skillOverrides`, `disableBundledSkills`,
  `CLAUDE_CODE_DISABLE_POLICY_SKILLS`, `strictPluginOnlyCustomization`, skills-directory plugins blocked by managed
  settings, `syncClaudeAiSkills`, removal, `--bare`, `--safe-mode`, `--disable-slash-commands`)
  - `skillOverrides`
  - Bundled skills
  - Managed policy skills
  - `strictPluginOnlyCustomization`
  - `syncClaudeAiSkills`
  - Removing a skill
  - Skills-directory plugins
  - Session flags
  - Not stated by the documentation

- [troubleshooting.md](troubleshooting.md): checking whether a skill loads, triggers and works, and why not
  (troubleshooting sections, evals and skill-creator, `/skills`, `/skill-doctor`, validation, error messages,
  OpenTelemetry)
  - Check that the skill loaded
  - Validate skill files
  - Skill not triggering
  - Skill triggers too often
  - Claude stops following a skill
  - Measure a skill with evals
  - Find unused skills
  - Audit skills for outdated instructions
  - Personal skills disappeared
  - Track skills with OpenTelemetry
  - Not stated by the documentation

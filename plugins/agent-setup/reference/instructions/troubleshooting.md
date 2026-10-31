# Troubleshooting instruction files

For checking a CLAUDE.md, `AGENTS.md` or rule file that isn't taking effect, or whose content makes a request fail (a
refusal for Claude's reasoning, a model fallback): whether it loaded, why it is ignored, and whether its content is
sound.

## Contents

- Check whether it loaded
- Check an `Instruction file not loaded` notice
- Check why `AGENTS.md` isn't read
- Log loads with the `InstructionsLoaded` hook
- Why a loaded instruction is ignored
- Check a refused request for Claude's reasoning
- Check a fallback triggered by workspace context
- Check a file over its per-file limit
- Test against a clean configuration
- Audit and length warnings
- Not stated by the documentation

## Check whether it loaded

- `/context` shows everything occupying the context window for the current session, broken down by category: system
  prompt, system tools, MCP tools, custom subagents with the source each loaded from, memory files, skills, and
  conversation messages. Run it first to confirm whether your `CLAUDE.md`, rules, or skill descriptions are present at
  all. `/context` checks which `CLAUDE.md` and rules files loaded at launch.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context),
  [memory › View and edit with `/memory`](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)
- To confirm a project CLAUDE.md loaded, run `/context` in a session and check the list under **Memory files**. That
  list verifies the CLAUDE.md and CLAUDE.local.md files that should load at launch. If one is missing there, Claude
  can't see it. Use `/memory` to open and edit the files.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md),
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory),
  [memory › View and edit with `/memory`](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- A `CLAUDE.md` in a subdirectory of your working directory doesn't appear under **Memory files**, because it loads on
  demand rather than at launch. When it loads, a `Loaded` line with its path appears in the terminal. To test a new
  one, create it from your shell rather than asking Claude to write it, then ask Claude to read a file in that
  subdirectory.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- If a memory file is missing from the `/context` breakdown, check that the relevant CLAUDE.md is in a location that
  gets loaded for your session, against
  [how CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load).
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- For detail on a category, follow up with the dedicated command:
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)

  | Command | Shows |
  | :- | :- |
  | `/memory` | Memory file locations across user and project scopes with the option to open each in your editor, plus access to the auto memory folder and the auto memory toggle |
  | `/hooks` | Active hook configurations |
  | `/permissions` | Resolved allow and deny rules currently in effect |
  | `/doctor` | Setup checkup: installation health, invalid settings files, unused extensions, duplicate [subagent](https://code.claude.com/docs/en/sub-agents) names in the same directory, and checked-in `CLAUDE.md` content Claude can derive from the codebase, with proposed fixes |
  | `/debug [issue]` | Enables debug logging for the session and prompts Claude to diagnose using the log output and settings paths |
  | `/status` | Active settings sources, including whether managed settings are in effect |

- For a rule loading as if it had no `paths`, run `claude --debug` to see the parse error.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)

## Check an `Instruction file not loaded` notice

- The notice `Instruction file not loaded` in the conversation view of an interactive session means a memory file that
  exists wasn't loaded. A read restriction is in force.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)

  ```text
  Instruction file not loaded (a Read deny rule covers it):
  path: .claude/rules/shared.md
  ```

- The parenthetical names the reason, for example:
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)
  - `a Read deny rule covers it`: a `Read` deny rule matches the file's path as written or where a link on it leads.
  - `it's read from outside your working directories, where reads are blocked`: the file resolves outside the working
    directories while `permissions.blockReadsOutsideWorkingDirectories` is on.
  - `where it leads couldn't be worked out`: for example, the file is a link that leads back to itself, directly or
    through other links.
- When a subdirectory's own memory file can't be loaded as Claude works with files there, the same lines appear in the
  conversation during the turn. When more files are withheld than the lines name, a final line counts the rest, such
  as `and 3 more instruction files not loaded`.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)
- If the restriction is intended, do nothing: the session runs without that file's instructions.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)
- To load a file withheld because `a Read deny rule covers it`, remove or narrow that rule. Then start a new session.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)
- To load a file withheld because `it's read from outside your working directories, where reads are blocked`, move it
  or its link target inside the working directories. Then start a new session.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)
- To load a file withheld because `where it leads couldn't be worked out`, check whether the file is a link that leads
  back to itself. If it is, point the link at a file that exists or put a regular file in its place. Then start a new
  session.
  [errors › Instruction file not loaded](https://code.claude.com/docs/en/errors#instruction-file-not-loaded)

## Check why `AGENTS.md` isn't read

- If your repository has an `AGENTS.md` and Claude doesn't seem to know what it says, the usual cause is a `CLAUDE.md`
  somewhere on the project path. By default Claude reads `AGENTS.md` only when you have no `CLAUDE.md` or
  `CLAUDE.local.md` in your working directory or above it.
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
- Check, in order:
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
  1. Look for a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory
     above it, other than your `~/.claude/CLAUDE.md`. If you find one, Claude reads it instead of `AGENTS.md` unless
     you set **Project instructions** to `claude-md-and-agents-md`.
  2. Type `/config` in your session to open the settings panel and confirm **Project instructions** isn't set to
     `claude-md` or `managed-only`. If you don't see the setting there at all, your session is one that
     [can't load `AGENTS.md`](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable).
- To check whether Claude read your `AGENTS.md`, run `/memory` and look for its path in the list.
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
- If you want to keep the `CLAUDE.md` you found, or your session can't load `AGENTS.md`,
  [add a `CLAUDE.md` next to your `AGENTS.md` that imports it](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools).
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)

## Log loads with the `InstructionsLoaded` hook

- Use the `InstructionsLoaded` hook to log which `CLAUDE.md` and rules files are loaded, when they load, and why. This
  is useful for debugging path-specific rules or lazy-loaded files in subdirectories.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- `InstructionsLoaded` fires when a `CLAUDE.md` or `.claude/rules/*.md` file is loaded into context: at session start
  for eagerly loaded files, and again later when files are lazily loaded, for example when Claude accesses a
  subdirectory that contains a nested `CLAUDE.md` or when conditional rules with `paths:` frontmatter match. The hook
  runs asynchronously for observability purposes.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- It doesn't fire when Claude reads `AGENTS.md` directly through the **Project instructions** setting. It does fire
  when a `CLAUDE.md` imports your `AGENTS.md`, with `load_reason` set to `include` as for any other imported file, and
  when `CLAUDE.md` is a symlink to it, as a normal `CLAUDE.md` load.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- The matcher runs against `load_reason`. For example, `"matcher": "session_start"` fires only for files loaded at
  session start, and `"matcher": "path_glob_match|nested_traversal"` fires only for lazy loads.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- In addition to the common input fields, InstructionsLoaded hooks receive these fields:
  [hooks › InstructionsLoaded input](https://code.claude.com/docs/en/hooks#instructionsloaded-input)

  | Field | Description |
  | :- | :- |
  | `file_path` | Absolute path to the instruction file that was loaded |
  | `memory_type` | Scope of the file: `"User"`, `"Project"`, `"Local"`, or `"Managed"` |
  | `load_reason` | Why the file was loaded: `"session_start"`, `"nested_traversal"`, `"path_glob_match"`, `"include"`, or `"compact"`. The `"compact"` value fires when instruction files are re-loaded after a compaction event |
  | `globs` | Path glob patterns from the file's `paths:` frontmatter, if any. Present only for `path_glob_match` loads |
  | `trigger_file_path` | Path to the file whose access triggered this load, for lazy loads |
  | `parent_file_path` | Path to the parent instruction file that included this one, for `include` loads |

- InstructionsLoaded hooks have no decision control. They can't block or modify instruction loading. Claude Code
  discards their JSON output fields, such as `systemMessage` and `continue`. Use this event for audit logging,
  compliance tracking, or observability.
  [hooks › InstructionsLoaded decision control](https://code.claude.com/docs/en/hooks#instructionsloaded-decision-control)
- Exit code 2 can't block this event:
  [hooks › Exit code 2 behavior per event](https://code.claude.com/docs/en/hooks#exit-code-2-behavior-per-event)

  | Hook event | Can block? | What happens on exit 2 |
  | :- | :- | :- |
  | `InstructionsLoaded` | No | Exit code is ignored |

- `InstructionsLoaded` is one of the events that don't support prompt or agent hooks.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)

## Why a loaded instruction is ignored

- Two common causes for CLAUDE.md:
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)

  | Symptom | Cause | Fix |
  | :- | :- | :- |
  | Subdirectory `CLAUDE.md` instructions seem ignored | Subdirectory files load on demand, not at session start | To load a subdirectory's `CLAUDE.md`, ask Claude to read another file in that subdirectory. See [when subdirectory files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load). |
  | Subagent ignores `CLAUDE.md` instructions | The built-in Explore and Plan agents skip `CLAUDE.md` at startup. A custom subagent loads it the same way the main conversation does, unless it has [`omitClaudeMd`](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields) set in its definition | For Explore or Plan, restate the instruction in your delegating prompt. For a subagent that sets `omitClaudeMd`, remove the field. For any other custom subagent, put critical instructions in the agent file body, which becomes the agent's system prompt. See [what loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup). |

- If an instruction disappeared after compaction, it was given only in conversation, lives in a nested CLAUDE.md that
  hasn't reloaded yet, or is a path-scoped rule that hasn't matched a file since. Add conversation-only instructions
  to CLAUDE.md to make them persist.
  [memory › Instructions seem lost after `/compact`](https://code.claude.com/docs/en/memory#instructions-seem-lost-after-/compact)
- If `/context` confirms the file loaded but Claude still isn't following a particular instruction, the issue is
  likely how the instruction is written rather than whether it loaded. Adherence drops when an instruction is vague
  enough to interpret multiple ways, when two files give conflicting direction, or when the file has grown long enough
  that individual rules get less attention.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt itself.
  Claude reads it and tries to follow it, but there's no guarantee of strict compliance, especially for vague or
  conflicting instructions.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- CLAUDE.md files reach Claude as system reminders. In a logged API request, a system reminder appears wrapped in
  `<system-reminder>` tags inside a user message, or on some models as a separate message with the `system` role.
  [glossary › System reminder](https://code.claude.com/docs/en/glossary#system-reminder)
- To debug a CLAUDE.md Claude isn't following, also:
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
  - Make instructions more specific: "Use 2-space indentation" works better than "format code nicely."
  - Look for conflicting instructions across CLAUDE.md files. If two files give different guidance for the same
    behavior, Claude may pick one arbitrarily.
  - Check whether your instruction competes with guidance Claude Code adds on its own. If your CLAUDE.md sets commit
    or pull request rules, turn off the built-in ones with
    [`includeGitInstructions`](https://code.claude.com/docs/en/settings-reference#includegitinstructions) and set the
    attribution text with [`attribution`](https://code.claude.com/docs/en/settings-reference#attribution).
  - When a background session has made code changes in a worktree Claude entered, your git instructions take
    precedence: if the task, `CLAUDE.md`, or memory says you handle committing or pushing yourself, Claude leaves git
    to you.
    [agent-view › How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)
  - Claude Code tells Claude that your own instructions about attribution, such as a CLAUDE.md or memory rule, take
    precedence over the commit and PR attribution lines, unless the line is set in managed settings.
    [settings-reference › `attribution`](https://code.claude.com/docs/en/settings-reference#attribution)
- If the instruction must run at a specific point, such as before every commit or after each file edit, write it as a
  hook instead: hooks execute as shell commands at fixed lifecycle events and apply regardless of what Claude decides
  to do.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- CLAUDE.md works well for the kinds of guidance you'd give a new teammate, such as project conventions, build
  commands, and where files belong. Use permissions or hooks, not CLAUDE.md, for security boundaries and anything that
  must never happen, where you need a guarantee instead of guidance.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- For instructions you want at the system prompt level, use
  [`--append-system-prompt`](https://code.claude.com/docs/en/cli-reference#system-prompt-flags). You pass it at launch,
  so it's better suited to scripts and automation than interactive use. For how it behaves when you resume a
  conversation, see [System prompt flags in resumed conversations](https://code.claude.com/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations).
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)

## Check a refused request for Claude's reasoning

- The API declines a request when safeguards flag it as asking the model to reproduce its internal reasoning in the
  response. The API names this refusal category `reasoning_extraction`, and the refusal message includes this line:
  [errors › Safeguards flagged a request for Claude's reasoning](https://code.claude.com/docs/en/errors#safeguards-flagged-a-request-for-claudes-reasoning)

  ```text
  Details: `[reasoning_extraction]`
  ```

- To check whether a customization is the trigger, run `claude --safe-mode` in your terminal, then send the same
  prompt.
  [errors › Safeguards flagged a request for Claude's reasoning](https://code.claude.com/docs/en/errors#safeguards-flagged-a-request-for-claudes-reasoning)
- After you change a customization, start a new session.
  [errors › Safeguards flagged a request for Claude's reasoning](https://code.claude.com/docs/en/errors#safeguards-flagged-a-request-for-claudes-reasoning)

## Check a fallback triggered by workspace context

- A model fallback can trigger on the first request of a session, before you send anything unusual, because the first
  request carries workspace context such as your CLAUDE.md content and git status. A repository that contains security
  or biology material can trip the classifier on that context alone.
  [model-config › Check what triggered fallback](https://code.claude.com/docs/en/model-config#check-what-triggered-fallback)
- To check whether customizations are the trigger, start a session with `claude --safe-mode`. Git status and directory
  names are not customizations and are still included.
  [model-config › Check what triggered fallback](https://code.claude.com/docs/en/model-config#check-what-triggered-fallback)

## Check a file over its per-file limit

- When Claude ignores the end of a subdirectory `CLAUDE.md` or a rules file that loads on demand, check whether the
  file is over a per-file size limit, and shrink it if it is.
  [memory › Claude ignores the end of my subdirectory CLAUDE.md](https://code.claude.com/docs/en/memory#claude-ignores-the-end-of-my-subdirectory-claude-md)
- Steps, in order:
  [memory › Claude ignores the end of my subdirectory CLAUDE.md](https://code.claude.com/docs/en/memory#claude-ignores-the-end-of-my-subdirectory-claude-md)
  1. Confirm that the limit applies to your file: subdirectory `CLAUDE.md` and `CLAUDE.local.md` files and their
     `@path` imports, rules files in a subdirectory's `.claude/rules/`, and path-scoped rules.
  2. Find the limit for your session's [context window](https://code.claude.com/docs/en/model-config#extended-context):
     40,000 characters on a 200K window; on a 1M window, 200,000 on Claude Opus 4.6 and Claude Sonnet 4.6 and
     150,000 on later models.
  3. In Bash or Zsh, run `wc -m path/to/CLAUDE.md` to print your file's character count.
  4. Compare the count with your limit. If it is over, trim the file, or move part of it into one or more rules files,
     which each count against the limit on their own. If it is under, look for another cause under
     [Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md).

## Test against a clean configuration

- Start with `claude --safe-mode`, which launches a session with your customizations disabled, including `CLAUDE.md`,
  skills, plugins, and hooks, MCP servers, custom commands and agents, custom output styles, and custom keybindings.
  Authentication, model selection, built-in tools, and permissions work normally. If the problem disappears in safe
  mode, you've narrowed the cause to one of the items you turned off.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- Setting `CLAUDE_CODE_SAFE_MODE` to `1` starts in safe mode, equivalent to passing `--safe-mode`: CLAUDE.md, skills,
  plugins, hooks, MCP servers, custom commands and agents, output styles, workflows, custom themes, custom keybindings,
  status line and file-suggestion commands, LSP servers, and auto memory do not load. Directly spawned child processes
  inherit the variable.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Safe mode still applies managed hooks and settings policy from your organization. Managed plugins, skills,
  `CLAUDE.md`, and MCP servers are turned off.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- If the problem persists in safe mode, or your settings themselves are suspect, start a session with none of your own
  configuration. With no Claude Code session running, create an empty directory and change into it, then set
  `CLAUDE_CONFIG_DIR` to a fresh directory in place of `~/.claude` and pass `--setting-sources user` to turn off
  project configuration such as `.claude/settings.json`, `CLAUDE.md`, and `.mcp.json`.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)

  ```bash
  mkdir -p ~/claude-clean/empty && cd ~/claude-clean/empty
  CLAUDE_CONFIG_DIR=~/claude-clean/config claude --setting-sources user
  ```

- On the first launch, you go through the first-run setup screens again, a sign that the clean configuration directory
  is in effect. Managed settings still apply, and connectors still load if you log in with a claude.ai account.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- In PowerShell, `$env:CLAUDE_CONFIG_DIR` stays set for the rest of the session, so later `claude` launches in the
  same window keep using the clean directory; run `Remove-Item Env:CLAUDE_CONFIG_DIR` before the next launch to return
  to your usual directory. In Bash or Zsh, the variable applies to the one launch.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- If the problem is gone in the clean session, the cause is in your user or project configuration. Copy
  `~/.claude.json` and the files in `~/.claude` into `~/claude-clean/config` one at a time. If none brings the problem
  back, go to your project directory in the same shell and start Claude Code without `--setting-sources user`
  (`CLAUDE_CONFIG_DIR=~/claude-clean/config claude` in Bash or Zsh; `claude` in PowerShell).
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- If the problem persists, the cause is outside your user and project configuration. Run `/status` in the session to
  check for managed settings, check your shell for [environment variables](https://code.claude.com/docs/en/env-vars),
  then see [Troubleshooting](https://code.claude.com/docs/en/troubleshooting).
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)

## Audit and length warnings

- Run `/doctor prompt-audit` in a session to have Claude check your instruction files for outdated or conflicting
  content. Claude looks for problems such as instructions written for older models, references to files or commands
  that don't exist, and files that contradict each other. You get a report of findings with proposed edits, and
  nothing in your files changes until you ask Claude to apply them.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- By default the audit covers your CLAUDE.md, CLAUDE.local.md, and AGENTS.md files, plus the rules, skills, commands,
  subagents, and output styles under `.claude/` and `~/.claude/`. To audit one file or directory instead, pass its
  path, for example `/doctor prompt-audit .claude/skills/deploy`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- The audit runs through the bundled `/claude-api` skill. It's unavailable while that skill is turned off in
  `skillOverrides` or with `disableBundledSkills`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- `/doctor`, without `prompt-audit`, runs the setup checkup. Its `CLAUDE.md` files area covers local `CLAUDE.md` files
  that duplicate checked-in ones, checked-in `CLAUDE.md` content Claude could derive from the codebase, and the
  always-loaded guidance that remains, which Claude offers to migrate into skills and nested `CLAUDE.md` files that
  load on demand. Claude reports its findings first and asks for confirmation before changing anything. For a
  checked-in CLAUDE.md it proposes trims: it cuts content Claude can derive from the codebase, such as directory
  layouts, dependency lists, and architecture overviews, and keeps pitfalls, rationale, and conventions that differ
  from tool defaults.
  [skills › Check your setup with `/doctor`](https://code.claude.com/docs/en/skills#check-your-setup-with-/doctor),
  [large-codebases › Layer CLAUDE.md files by directory](https://code.claude.com/docs/en/large-codebases#layer-claude-md-files-by-directory),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- In the commands table:
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)

  | Command | Purpose |
  | :- | :- |
  | `/doctor [prompt-audit [path]]` | **[Skill](https://code.claude.com/docs/en/skills#bundled-skills).** Run a setup checkup that diagnoses installation, settings, extension, and `CLAUDE.md` problems and proposes fixes that Claude applies after you confirm. For what the checkup covers, or to audit your instructions with `prompt-audit` instead, see [Check your setup with `/doctor`](https://code.claude.com/docs/en/skills#check-your-setup-with-/doctor). Alias: `/checkup` |

- If one of your instruction files is over the recommended length, you see a warning at startup and when you run
  `/status`. You also see a warning when files that are each within that length add up past a combined limit at
  session start. Each CLAUDE.md, rules file, and `@path` import counts as a separate file.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- For a CLAUDE.md that is too large, use path-scoped rules to load instructions only when Claude works with matching
  files, or trim content that isn't needed in every session.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)

## Not stated by the documentation

- hooks › InstructionsLoaded names `CLAUDE.md` and `.claude/rules/*.md` files, and memory › Claude isn't
  following my CLAUDE.md says "rules files" without a scope; neither says whether the hook fires for user-level
  rules in `~/.claude/rules/`.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- The warning's section does not say whether the recommended length behind the startup warning is the 200-line figure
  given for files that consume more context, or what the combined limit is.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- `/doctor prompt-audit` covers rules files and `AGENTS.md`; the documentation does not say whether the `/doctor`
  checkup proposes trims for rules files or `AGENTS.md`.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Are rules files listed under the **Memory files** heading of `/context`?
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context),
  [memory › View and edit with `/memory`](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)

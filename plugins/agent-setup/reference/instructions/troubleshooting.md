# Troubleshooting instruction files

For checking a CLAUDE.md, `AGENTS.md` or rule file that isn't taking effect: whether it loaded, why it is ignored,
and whether its content is sound.

## Contents

- Check whether it loaded
- Check why `AGENTS.md` isn't read
- Log loads with the `InstructionsLoaded` hook
- Why a loaded instruction is ignored
- Test against a clean configuration
- Audit and length warnings
- Not stated by the documentation

## Check whether it loaded

- `/context` shows everything occupying the context window for the current session, by category: system prompt,
  system tools, MCP tools, custom subagents with the source each loaded from, memory files, skills, and conversation
  messages. Run it first to confirm whether your `CLAUDE.md`, rules, or skill descriptions are present at all.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- Run `/context` and check the list under **Memory files** to verify your CLAUDE.md and CLAUDE.local.md files loaded.
  If a `CLAUDE.md` file is missing there, Claude can't see it. Use `/memory` to open and edit the files.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- If a memory file is missing from the `/context` breakdown, check that it is in a location that gets loaded for your
  session, against [how CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load).
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- For detail on a category, follow `/context` with the dedicated command:
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)

  | Command | Shows |
  | :- | :- |
  | `/hooks` | Active hook configurations |
  | `/debug [issue]` | Enables debug logging for the session and prompts Claude to diagnose using the log output and settings paths |
  | `/status` | Active settings sources, including whether managed settings are in effect |

- If a rule's frontmatter doesn't parse, run `claude --debug` to see the parse error.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)

## Check why `AGENTS.md` isn't read

- If your repository has an `AGENTS.md` and Claude doesn't seem to know what it says, the usual cause is a `CLAUDE.md`
  somewhere on the project path.
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
- Check, in order:
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
  1. Look for a `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory
     above it, other than your `~/.claude/CLAUDE.md`. If you find one, Claude reads it instead of `AGENTS.md` unless
     you set **Project instructions** to `claude-md-and-agents-md`.
  2. Type `/config` to open the settings panel and confirm **Project instructions** isn't set to `claude-md` or
     `managed-only`. If you don't see the setting there at all, your session is one that
     [can't load `AGENTS.md`](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable).
- To check whether Claude read your `AGENTS.md`, run `/memory` and look for its path in the list. `/memory` and
  `/context` list an `AGENTS.md` that Claude read directly.
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
- If you want to keep the `CLAUDE.md` you found, or your session can't load `AGENTS.md`,
  [add a `CLAUDE.md` next to your `AGENTS.md` that imports it](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools).
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)

## Log loads with the `InstructionsLoaded` hook

- Use the `InstructionsLoaded` hook to log which `CLAUDE.md` and rules files are loaded, when they load, and why. This
  is useful for debugging path-specific rules or lazy-loaded files in subdirectories.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- `InstructionsLoaded` fires when a `CLAUDE.md` or `.claude/rules/*.md` file is loaded into context: at session start
  for eagerly-loaded files, and again later when files are lazily loaded, for example when Claude accesses a
  subdirectory that contains a nested `CLAUDE.md` or when conditional rules with `paths:` frontmatter match.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- It doesn't fire when Claude reads `AGENTS.md` directly through the **Project instructions** setting. It does fire
  when a `CLAUDE.md` imports your `AGENTS.md`, with `load_reason` set to `include`, and when `CLAUDE.md` is a symlink to
  it, as a normal `CLAUDE.md` load.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- The matcher runs against `load_reason`. For example, `"matcher": "session_start"` fires only for files loaded at
  session start, and `"matcher": "path_glob_match|nested_traversal"` fires only for lazy loads.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded)
- Besides the common input fields, the hook receives:
  [hooks › InstructionsLoaded input](https://code.claude.com/docs/en/hooks#instructionsloaded-input)

  | Field | Description |
  | :- | :- |
  | `file_path` | Absolute path to the instruction file that was loaded |
  | `memory_type` | Scope of the file: `"User"`, `"Project"`, `"Local"`, or `"Managed"` |
  | `load_reason` | Why the file was loaded: `"session_start"`, `"nested_traversal"`, `"path_glob_match"`, `"include"`, or `"compact"`. The `"compact"` value fires when instruction files are re-loaded after a compaction event |
  | `globs` | Path glob patterns from the file's `paths:` frontmatter, if any. Present only for `path_glob_match` loads |
  | `trigger_file_path` | Path to the file whose access triggered this load, for lazy loads |
  | `parent_file_path` | Path to the parent instruction file that included this one, for `include` loads |

- The hook has no decision control: it can't block or modify instruction loading, and it runs asynchronously for
  observability. Claude Code discards its JSON output fields, such as `systemMessage` and `continue`. Use it for audit
  logging, compliance tracking, or observability.
  [hooks › InstructionsLoaded](https://code.claude.com/docs/en/hooks#instructionsloaded),
  [hooks › InstructionsLoaded decision control](https://code.claude.com/docs/en/hooks#instructionsloaded-decision-control)
- Exit code 2 can't block this event:
  [hooks › Exit code 2 behavior per event](https://code.claude.com/docs/en/hooks#exit-code-2-behavior-per-event)

  | Hook event | Can block? | What happens on exit 2 |
  | :- | :- | :- |
  | `InstructionsLoaded` | No | Exit code is ignored |

- `InstructionsLoaded` supports `command`, `http`, and `mcp_tool` hooks but not `prompt` or `agent` hooks.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)

## Why a loaded instruction is ignored

- Two common causes for CLAUDE.md:
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)

  | Symptom | Cause | Fix |
  | :- | :- | :- |
  | Subdirectory `CLAUDE.md` instructions seem ignored | Subdirectory files load on demand, not at session start | They load after Claude uses the Read, Write, or Edit tool on a file in that directory, not at launch. See [how CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load). |
  | Subagent ignores `CLAUDE.md` instructions | The built-in Explore and Plan agents skip `CLAUDE.md`. A custom subagent loads it the same way the main conversation does, unless its definition sets [`omitClaudeMd`](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields) | For Explore or Plan, restate the instruction in your delegating prompt. For a subagent that sets `omitClaudeMd`, remove the field. For any other custom subagent, put critical instructions in the agent file body, which becomes the agent's system prompt. See [what loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup). |

- If an instruction disappeared after compaction, it was given only in conversation, lives in a nested CLAUDE.md that
  hasn't reloaded yet, or is a path-scoped rule that hasn't matched a file since. Add conversation-only instructions
  to CLAUDE.md to make them persist.
  [memory › Instructions seem lost after `/compact`](https://code.claude.com/docs/en/memory#instructions-seem-lost-after-/compact)
- If `/context` confirms the file loaded but Claude still isn't following a particular instruction, the issue is
  likely how the instruction is written rather than whether it loaded. Adherence drops when an instruction is vague
  enough to interpret multiple ways, when two files give conflicting direction, or when the file has grown long enough
  that individual rules get less attention.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt. Claude
  tries to follow it, but there's no guarantee of strict compliance, especially for vague or conflicting instructions.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- The pages differ: the glossary says CLAUDE.md files reach Claude as system reminders, which in a logged API request
  appear wrapped in `<system-reminder>` tags inside a user message, but on some models as a separate message with the
  `system` role, not a user message.
  [glossary › System reminder](https://code.claude.com/docs/en/glossary#system-reminder)
- To debug a CLAUDE.md Claude isn't following, also:
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
  - Make instructions more specific: "Use 2-space indentation" works better than "format code nicely."
  - Look for conflicting instructions across CLAUDE.md files.
  - Check whether your instruction competes with guidance Claude Code adds on its own. If your CLAUDE.md sets commit
    or pull request rules, turn off the built-in ones with
    [`includeGitInstructions`](https://code.claude.com/docs/en/settings-reference#includegitinstructions) and set the
    attribution text with [`attribution`](https://code.claude.com/docs/en/settings-reference#attribution).
  - When a background session, from agent view or `claude --bg`, has made code changes in a worktree Claude entered,
    Claude Code tells Claude to preserve the work; if the task, `CLAUDE.md`, or memory says you handle committing or
    pushing yourself, Claude leaves git to you.
    [agent-view › How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)
  - Claude Code tells Claude that your own instructions about attribution, such as a CLAUDE.md or memory rule, take
    precedence over the `attribution` commit and PR lines, unless the line is set in managed settings.
    [settings-reference › `attribution`](https://code.claude.com/docs/en/settings-reference#attribution)
- If the instruction must run at a specific point, such as before every commit or after each file edit, write it as a
  hook instead: hooks execute as shell commands at fixed lifecycle events and apply regardless of what Claude decides.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- CLAUDE.md works well for the guidance you'd give a new teammate, such as project conventions, build commands, and
  where files belong. Use permissions or hooks, not CLAUDE.md, for security boundaries and anything that must never
  happen, where you need a guarantee instead of guidance.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- For instructions you want at the system prompt level, use
  [`--append-system-prompt`](https://code.claude.com/docs/en/cli-reference#system-prompt-flags). You pass it at launch,
  so it suits scripts and automation better than interactive use. For its behaviour when you resume a conversation,
  see [System prompt flags in resumed conversations](https://code.claude.com/docs/en/cli-reference#system-prompt-flags-in-resumed-conversations).
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)

## Test against a clean configuration

- `claude --safe-mode` launches a session with all customizations disabled, including `CLAUDE.md`, skills, plugins,
  hooks, MCP servers, and custom commands and agents; authentication, model selection, built-in tools, and
  permissions work normally. If the problem disappears in safe mode, one of those surfaces is the cause. Safe mode
  doesn't stop the built-in mod that loads `AGENTS.md`.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration),
  [plugins/mods/overview › Mods built into Claude Code](https://code.claude.com/docs/en/plugins/mods/overview#mods-built-into-claude-code)
- Setting `CLAUDE_CODE_SAFE_MODE` to `1` starts in safe mode, equivalent to passing `--safe-mode`; CLAUDE.md, skills,
  plugins, hooks, MCP servers, custom commands and agents, output styles, workflows, custom themes, custom keybindings,
  status line and file-suggestion commands, LSP servers, and auto memory do not load. Directly spawned child processes
  inherit the variable.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Safe mode still applies managed hooks and settings policy from your organization. Managed plugins, skills,
  CLAUDE.md, and MCP servers are turned off.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- If the problem persists in safe mode, or your settings themselves are suspect, point `CLAUDE_CONFIG_DIR` at an empty
  directory to bypass everything under `~/.claude`, and launch from a directory that has no `.claude` folder,
  `.mcp.json`, or `CLAUDE.md` so project configuration is also skipped. The clean session has no user or project
  settings, hooks, MCP servers, plugins, or memory.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)

  ```bash
  cd /tmp && CLAUDE_CONFIG_DIR=/tmp/claude-clean claude
  ```

- On the first launch with a clean configuration directory, you see the first-run setup screens, starting with theme
  selection; if you see them, the clean configuration directory is in effect. Later launches with the same directory
  skip them. You'll be prompted to log in again.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- Managed settings still apply in the clean session if your organization deploys them: Claude Code reads MDM
  profiles, registry policy, and `managed-settings.json` from locations outside the configuration directory, and
  fetches server-managed settings again once it has credentials.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- If the problem disappears in the clean session, the cause is somewhere in your real `~/.claude` or project `.claude`
  files: reintroduce them one at a time, by copying files into the temporary directory or by launching from your
  project. If it persists, the cause is outside your user and project configuration: run `/status` to check whether
  managed settings are in effect, look for [environment variables](https://code.claude.com/docs/en/env-vars) that
  affect Claude Code, then see [Troubleshooting](https://code.claude.com/docs/en/troubleshooting).
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)

## Audit and length warnings

- Run `/doctor prompt-audit` to have Claude check your instruction files for outdated or conflicting content, such as
  instructions written for older models, references to files or commands that don't exist, and files that contradict
  each other. You get a report with proposed edits; nothing changes until you ask Claude to apply them.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- By default the audit covers your CLAUDE.md, CLAUDE.local.md, and AGENTS.md files, plus the rules, skills, commands,
  subagents, and output styles under `.claude/` and `~/.claude/`. To audit one file or directory, pass its path, for
  example `/doctor prompt-audit .claude/skills/deploy`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- The audit runs through the bundled `/claude-api` skill, so it's unavailable while that skill is turned off in
  `skillOverrides` or with `disableBundledSkills`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- `/doctor`, without `prompt-audit`, runs the setup checkup:
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)

  | Command | Purpose |
  | :- | :- |
  | `/doctor [prompt-audit [path]]` | **[Skill](https://code.claude.com/docs/en/skills#bundled-skills).** Run a setup checkup that diagnoses issues and can fix them. Checks installation health, including duplicate or leftover installs, `PATH` problems, and unparseable settings files. Finds unused skills, MCP servers, and plugins versus their context cost, flags slow [hooks](https://code.claude.com/docs/en/hooks), and checks for a newer version on your [release channel](https://code.claude.com/docs/en/setup#configure-release-channel). Deduplicates local `CLAUDE.md` files against checked-in ones, trims checked-in [`CLAUDE.md`](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large) files by cutting content Claude could derive from the codebase, and migrates the always-loaded guidance that remains into [skills](https://code.claude.com/docs/en/skills) and nested `CLAUDE.md` files that load on demand. Also offers to make [auto mode](https://code.claude.com/docs/en/permissions#permission-modes) your default and to [pre-approve](https://code.claude.com/docs/en/permissions) frequently denied read-only commands. Reports findings first and asks for confirmation before changing anything. From the terminal, `claude doctor` prints read-only installation diagnostics without starting a session. Alias: `/checkup`. Run `/doctor prompt-audit` to have Claude [audit your `CLAUDE.md` files, skills, and other configuration](https://code.claude.com/docs/en/memory#audit-your-instruction-files) for outdated or conflicting instructions instead of running the checkup |

- The `/doctor` checkup proposes trims for a checked-in CLAUDE.md: it cuts content Claude can derive from the
  codebase, such as directory layouts, dependency lists, and architecture overviews, and keeps pitfalls, rationale,
  and conventions that differ from tool defaults.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- If one of your instruction files is over the recommended length, you see a warning at startup and when you run
  `/status`. You also see a warning at session start when files that are each within that length add up past a
  combined limit. Each CLAUDE.md, rules file, and `@path` import counts as a separate file.
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
- The recommended length behind the startup warning, and the combined limit, are not given; the 200-line figure is
  stated for CLAUDE.md files.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- `/doctor prompt-audit` covers rules files and `AGENTS.md`, but the `/doctor` checkup's trims are stated for a
  checked-in CLAUDE.md; the documentation does not say whether the checkup proposes trims for rules files or
  `AGENTS.md`.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- The **Memory files** list in `/context` is stated for CLAUDE.md and CLAUDE.local.md files; the documentation does
  not say whether rules files appear under that heading.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)

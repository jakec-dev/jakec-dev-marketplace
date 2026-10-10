# Troubleshooting rules

For checking a rule that isn't behaving as expected: whether it loaded, and whether its content is sound.

## Contents

- Check whether it loaded
- Log loads with the `InstructionsLoaded` hook
- Check the content
- Audit and length warnings
- Not stated by the documentation

## Check whether it loaded

- `/context` shows everything occupying the context window for the current session, by category: system prompt,
  system tools, MCP tools, custom subagents with the source each loaded from, memory files, skills, and conversation
  messages. Run it first to confirm whether your `CLAUDE.md`, rules, or skill descriptions are present at all.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- Run `/context` and check the list under **Memory files** to verify your CLAUDE.md and CLAUDE.local.md files loaded.
  If a `CLAUDE.md` file is missing there, Claude can't see it. Use `/memory` to open and edit the files.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- If a memory file is missing from the `/context` breakdown, check its location against
  [how CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load). Subdirectory
  `CLAUDE.md` files load on demand after Claude uses the Read, Write, or Edit tool on a file in that directory, not at
  session start. Check that the relevant CLAUDE.md is in a location that gets loaded for your session.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context),
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- For detail on a category, follow `/context` with the dedicated command:
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)

  | Command | Shows |
  | :- | :- |
  | `/memory` | Memory file locations across user and project scopes with the option to open each in your editor, plus access to the auto memory folder and the auto memory toggle |
  | `/hooks` | Active hook configurations |
  | `/doctor` | Setup checkup: installation health, invalid settings files, unused extensions, duplicate subagent names in the same directory, and checked-in `CLAUDE.md` content Claude can derive from the codebase, with proposed fixes |
  | `/debug [issue]` | Enables debug logging for the session and prompts Claude to diagnose using the log output and settings paths |
  | `/status` | Active settings sources, including whether managed settings are in effect |

- If a rule's frontmatter doesn't parse, run `claude --debug` to see the parse error.
  [memory › Rule frontmatter reference](https://code.claude.com/docs/en/memory#rules-frontmatter-reference)

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

## Check the content

- If `/context` confirms the file loaded but Claude still isn't following a particular instruction, the issue is
  likely how the instruction is written rather than whether it loaded. Adherence drops when an instruction is vague
  enough to interpret multiple ways, when two files give conflicting direction, or when the file has grown long enough
  that individual rules get less attention.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- CLAUDE.md content is delivered as a user message after the system prompt, not as part of the system prompt. Claude
  tries to follow it, but there's no guarantee of strict compliance, especially for vague or conflicting instructions.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- Claude treats CLAUDE.md files as context, not enforced configuration. Write instructions concrete enough to verify:
  "Run `npm test` before committing" instead of "Test your changes"; "Use 2-space indentation" instead of "Format code
  properly".
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- Group related instructions under markdown headers and bullets; organised sections are easier for Claude to follow
  than dense paragraphs.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- If two instructions contradict each other, Claude may pick one arbitrarily. Review your CLAUDE.md files, nested
  CLAUDE.md files in subdirectories, and `.claude/rules/` periodically to remove outdated or conflicting instructions.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- Check whether your instruction competes with guidance Claude Code adds on its own. If your CLAUDE.md sets commit or
  pull request rules, turn off the built-in ones with
  [`includeGitInstructions`](https://code.claude.com/docs/en/settings-reference#includegitinstructions) and set the
  attribution text with [`attribution`](https://code.claude.com/docs/en/settings-reference#attribution).
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- If the instruction must run at a specific point, such as before every commit or after each file edit, write it as a
  hook instead: hooks run as shell commands at fixed lifecycle events and apply regardless of what Claude decides.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- Use permissions or hooks, not CLAUDE.md, for security boundaries and anything that must never happen, where you need
  a guarantee instead of guidance.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- For instructions you want at the system prompt level, use
  [`--append-system-prompt`](https://code.claude.com/docs/en/cli-reference#system-prompt-flags). You pass it at launch,
  so it suits scripts and automation better than interactive use.
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)

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
- If one of your instruction files is over the recommended length, you see a warning at startup and when you run
  `/status`. You also see a warning at session start when files that are each within that length add up past a
  combined limit. Each CLAUDE.md, rules file, and `@path` import counts as a separate file.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Target under 200 lines per CLAUDE.md file; longer files consume more context and reduce adherence. Move instructions
  that matter for only part of the codebase into path-scoped rules, which load only when Claude works with matching
  files. Imports help organise a long file but don't reduce its context cost, because imported files also load at
  launch.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- For CLAUDE.md files, Claude Code skips a file over 4 MiB.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- The `/doctor` checkup proposes trims for a checked-in CLAUDE.md: it cuts content Claude can derive from the
  codebase, such as directory layouts, dependency lists, and architecture overviews, and keeps pitfalls, rationale,
  and conventions that differ from tool defaults.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)

## Not stated by the documentation

- The recommended length behind the startup warning, and the combined limit, are not given; the 200-line target is
  stated for CLAUDE.md files.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- The 4 MiB skip is stated in a CLAUDE.md section; the documentation does not say whether it applies to rules files.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- `/doctor prompt-audit` covers rules files, but the `/doctor` checkup's trims are stated for a checked-in CLAUDE.md;
  the documentation does not say whether the checkup proposes trims for rules files.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Stated for CLAUDE.md files; the documentation does not say whether block-level HTML comments in rules files are
  stripped before the content is injected into context.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)

---
name: write-settings
description: Writes, fixes or explains Claude Code settings, such as permission rules, the permission mode, auto mode, the sandbox and managed settings, or says when another tool fits better. Use when the user wants to allow, deny or require approval for a tool, command or file, in a session or a `claude -p` or CI run, change how often Claude asks for permission, configure auto mode or the sandbox, or set policy for an organisation, or asks why Claude is refused permission or a setting has no effect.
allowed-tools: Read, Glob, Grep
---

# Write settings

Base the work on the plugin's reference, which says how Claude Code reads settings files and applies their keys, and
its guidance, which says which setting fits a goal. Not on memory: much of what goes wrong with a setting fails
silently, with a key read from the wrong file or a rule that never matches, and no error in the session.

Hooks live in settings files too, but a hook is `/agent-setup:write-hook`'s job: hand a hook request to that skill.

1. **Read both indexes in full:** `${CLAUDE_PLUGIN_ROOT}/reference/settings/index.md` and
   `${CLAUDE_PLUGIN_ROOT}/guidance/index.md`. Their key facts and key principles apply to every task.
2. **Read `${CLAUDE_PLUGIN_ROOT}/guidance/write-settings.md` in full,** then pick the other sections the task needs
   from the two Topics lists. Read each one: find its `## ` heading with Grep, then Read from that line to the next
   `## ` heading.
   - To pick the file, always read `placing.md › Settings files and their scopes` and, in a git repository,
     `placing.md › The local file in a git repository`. Look up each key's scope in `keys.md › Settings index`, and
     for a key that isn't `Any file`, in `keys.md › Managed-only keys with a narrower source` or
     `keys.md › User or managed keys`.
   - For a permission rule, read `permissions.md › Rule syntax and wildcards` and the section for its tool, such as
     `permissions.md › Bash rules` or `permissions.md › Read and Edit rules`.
   - For the permission mode, read `modes.md › Which mode a session starts in` and
     `modes.md › Setting the starting mode`. For auto mode, read the `auto-mode.md` sections for what the user wants
     to change; for the sandbox, the `sandbox.md` sections for each key it sets, and `credentials.md` for credential
     files and secret variables.
   - For an organisation's policy, read the `managed.md` sections from `managed.md › Deploy a managed settings file`
     to `managed.md › Where and when a policy applies`, then `managed.md › Keys only a managed source can set` and
     `managed.md › What a developer can change`.
   - To say when the change applies, read `configuring.md › When edits take effect`.
   - To explain why a setting doesn't apply, read `troubleshooting.md`.
3. **Find the settings that already exist:** Read `.claude/settings.json` in the session's working directory, the
   local file where `placing.md` says it lives, `~/.claude/settings.json`, and the managed settings file and
   `managed-settings.d/` directory that `managed.md › Deploy a managed settings file` names for the operating system,
   where each exists. A policy can also arrive by MDM or from the server, which no file read finds, so a user can
   check `/status` for the sources that loaded. Note the rules and keys that bear on the task, so that a new rule
   doesn't repeat one, and a lower scope isn't set where a higher one decides (`placing.md › Precedence`).
4. **Check that a setting is the right tool** against the `choose.md` sections from `Must happen every time: a hook`
   to `A rule on a command's text: keep it, and add a PreToolUse hook`. A preference Claude can weigh stays an
   instruction; a Bash rule on a command Claude could write another way needs a `PreToolUse` hook or the sandbox
   behind it; something that must run at a fixed point is a hook. Say which tool fits and why, and offer that
   instead. Write the setting anyway only if the user still wants it.
5. **Do the task:** write or fix the setting, or answer the question.
   - Put each rule or key in the file whose scope matches who it is for and that its scope in `keys.md` allows
     (`write-settings.md › A permission rule lives in the scope of the people it applies to`). Edit a file that
     exists rather than replacing it, and keep its other keys.
   - Write keys, values and rules exactly as the reference gives them.
   - Make the result pass the `Check:` line of every guidance section you read. Where the reference lists something
     as not stated by the documentation, say so rather than guess.
6. **Check the silent failures** before calling it done. Each passes no error to the session:
   - [ ] Every key is in a file its scope allows. A `User or managed` or `Managed` key in `.claude/settings.json` or
         `.claude/settings.local.json` never applies, and some managed keys apply only from some managed sources
         (`keys.md › Settings index`, `keys.md › Managed-only keys with a narrower source`).
   - [ ] `permissions.defaultMode` is not `auto` or `bypassPermissions` in `.claude/settings.json` or
         `.claude/settings.local.json`, where neither takes effect (`modes.md › Which mode a session starts in`).
   - [ ] No `autoMode` block is in the project's settings files, which the classifier doesn't read, and every
         `autoMode` list keeps `"$defaults"` unless it spells out the built-in entries itself (in `auto-mode.md`, the
         sections Where the classifier reads `autoMode` and Override the block and allow rules).
   - [ ] A path in a `Read` or `Edit` rule uses the prefix it means: `/path` anchors at the settings source, so
         `Read(/secrets/**)` in user settings means `~/.claude/secrets/**`; an absolute path is `//path` and a home
         path `~/path` (`permissions.md › Read and Edit rules`).
   - [ ] A path in `sandbox.filesystem` uses the sandbox's prefixes, where `/path` is absolute and `./path` is
         relative to the project root in project settings and to `~/.claude` in user settings
         (`sandbox.md › Sandbox path prefixes`).
   - [ ] An `allow` rule or `additionalDirectories` entry that a `claude -p` run or SDK session needs, in a folder
         never trusted, is not left only in `.claude/settings.json`, or in a `.claude/settings.local.json` that is
         tracked in git or under a symlinked `.claude`. Put it in user settings, a `--settings` file or the run's
         `--allowedTools`, or trust the folder by hand with `hasTrustDialogAccepted` in `~/.claude.json`
         (`permissions.md › Project allow rules and workspace trust`).
   - [ ] A Bash deny or ask rule that must hold is backed by a `PreToolUse` hook or the sandbox, since it matches
         only the command as Claude writes it (`permissions.md › Bash rules`).
   - [ ] An `env` variable set in project or local settings is not one Claude Code drops there
         (`configuring.md › The env key`).
7. **Say how to verify it:** `/permissions` lists each rule with the file it comes from, `/status` shows the settings
   files that loaded, and `claude doctor` lists entries Claude Code rejected
   (`troubleshooting.md › Confirm what loaded`). For auto mode, `claude auto-mode config` prints the effective
   configuration; for the sandbox, `/sandbox` shows its mode and overrides. Say whether the change applies at once or
   after a restart (`configuring.md › When edits take effect`). Give one action the setting should allow, deny or
   prompt for, and one it should leave alone.

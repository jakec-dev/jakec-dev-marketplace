# Permission modes

Choosing and setting a permission mode: the modes, which one a session starts in, switching, the
per-mode behaviour, protected paths and critical paths.

## Contents

- The modes
- Which mode a session starts in
- Setting the starting mode
- Switching modes in a session
- acceptEdits
- plan
- dontAsk
- bypassPermissions
- Unattended runs
- Resuming a session
- Protected paths
- Critical paths
- Mounted drive prompt
- Critical-path removals in each mode
- Turning off the critical-path removal prompt
- Remove-Item in PowerShell

## The modes

- A permission mode sets which actions Claude can take in a session without asking you first. In Manual mode, Claude
  Code stops and asks you before most actions that edit files, run shell commands, or reach the network. You can also
  change a running session's permission mode at any time.
  [permission-modes › Choose a permission mode](https://code.claude.com/docs/en/permission-modes#page-title)
- The table shows what runs without a prompt in each mode.
  [permission-modes › Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)

  | Mode | What runs without asking | Best for |
  | :- | :- | :- |
  | `default` | Reads only | Reviewing every action yourself, sensitive work |
  | `acceptEdits` | Reads, file edits, and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`, etc.) | Iterating on code you're reviewing |
  | `plan` | Reads, plus classifier-approved commands when auto mode is available | Exploring a codebase before changing it |
  | `auto` | Everything, with background safety checks | Long tasks, reducing prompt fatigue |
  | `dontAsk` | File reads inside your working directories and pre-approved tools; anything that would prompt is denied, though a [mod](https://code.claude.com/docs/en/plugins/mods/overview) you installed can still approve some of those calls | Locked-down CI and scripts |
  | `bypassPermissions` | Everything | Isolated containers and VMs only |

- The mode that reviews every action is named **Manual** in the CLI, in `claude --help`, in the VS Code and JetBrains
  extensions, and in the desktop app. Its config value is `default`, which is what hooks and SDK integrations use. The
  CLI accepts `manual` as an alias wherever you type the value, for example `claude --permission-mode manual` or
  `"defaultMode": "manual"`.
  [permission-modes › Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)
- "Bypass permissions available" in the sections below means interactive terminal sessions started in a way that puts
  `bypassPermissions` in the mode cycle.
  [permission-modes › Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)
- Permission rules layer on top of modes. Deny rules block in every mode, including `bypassPermissions`. Deny and ask
  rules don't apply to `EndConversation` as long as Claude still has at least one other tool it can call. Allow rules
  have no effect in `bypassPermissions`.
  [permission-modes › Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)
- Claude Code doesn't auto-approve these in any mode, including `bypassPermissions`, though you can turn off the
  prompt for dangerous `rm` commands in `bypassPermissions` mode:
  [permission-modes › Actions no mode auto-approves](https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves)
  - Tools matched by an explicit ask rule.
  - Connector tools your organization set to `ask`, in sessions where that setting reaches Claude Code.
  - Tools that require user interaction: the built-in `AskUserQuestion` tool and MCP tools marked
    `requiresUserInteraction`.
  - Recognized `rm` and `rmdir` critical-path removals, and Bash commands flagged
    `Dangerous rm operation not ruled out`.
  - The cross-session messaging safeguards, which still apply in `bypassPermissions` mode and in interactive terminal
    plan-mode sessions where bypass permissions are available. [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
  - Reads outside the working directories while `permissions.blockReadsOutsideWorkingDirectories` is on: recognized
    file-reading Bash commands prompt even in auto mode and `bypassPermissions` mode, and so does any unsandboxed
    retry that needs approval to run outside the sandbox. A command the shell parser can't trace, such as one that
    changes directory more than once or runs a subshell, prompts the same way even when it names no outside path. This
    prompt doesn't apply when the command runs in the sandbox and the sandbox enforces the block.

## Which mode a session starts in

- When you start a new session in a terminal, Claude Code takes the permission mode from the first of these that
  applies: the `--permission-mode` flag or `--dangerously-skip-permissions`; `permissions.defaultMode` in a settings
  file; the built-in default.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- `"auto"` set in `.claude/settings.json` or `.claude/settings.local.json` doesn't take effect, and Claude Code then
  uses the built-in default rather than a `defaultMode` from `~/.claude/settings.json`. `"bypassPermissions"` in those
  two files doesn't take effect either, and the session starts in Manual mode. The other values apply from any
  settings file.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- Conversations the VS Code extension starts follow the extension's own list (see Switching modes in a session).
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- The built-in default depends on how you run Claude Code; the first row that matches applies. The table covers
  sessions started in a terminal or through the VS Code extension.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)

  | How you run Claude Code | Built-in starting permission mode |
  | :- | :- |
  | Any settings file sets `disableAutoMode` to `"disable"` | `default` |
  | `claude -p` or the [Agent SDK](https://code.claude.com/docs/en/agent-sdk/permissions#permission-modes) | `default` |
  | Your organization has the [HIPAA configuration](https://code.claude.com/docs/en/permission-modes#hipaa-configuration) applied and the session is [eligible for it](https://code.claude.com/docs/en/hipaa-setup#check-how-developers-sign-in-and-connect) | `default`; auto mode stays available to switch to |
  | In a terminal or through the [VS Code extension](https://code.claude.com/docs/en/vs-code) | `auto` |

- When the flag, a settings file or the built-in default selects `auto` but auto mode isn't available to the session,
  Claude Code starts the session in Manual instead. Auto mode is unavailable when the session doesn't meet the
  availability requirements, such as a settings file turning it off or a model that doesn't support it, or when
  Anthropic has temporarily turned it off server-side.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- If your `~/.claude/settings.json` sets a `defaultMode` other than `auto` and no other settings file sets one, your
  sessions keep starting in that mode. On Pro, Max, Ultra and Team plans, and in sessions that don't fetch feature
  flags, Claude Code asks once whether to change the setting to auto mode, in the terminal or in the VS Code
  extension; if you decline, your setting stays as it is.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- With the HIPAA configuration applied, the built-in `auto` default doesn't apply: a terminal or VS Code session starts
  in Manual mode when nothing else chooses its starting permission mode. A terminal session also shows `Auto mode isn't
  the default for your organization · Shift+Tab to switch`, and the VS Code extension shows no notice. Auto mode and
  `bypassPermissions` stay available.
  [permission-modes › Permission modes with the HIPAA configuration](https://code.claude.com/docs/en/permission-modes#hipaa-configuration)

## Setting the starting mode

- You can set the starting permission mode for one session, or as a default for every session on a machine, in a
  project, or in an organization. When more than one settings file sets `permissions.defaultMode`, settings
  precedence decides, so a project or managed value outranks `~/.claude/settings.json`.
  [permission-modes › Start in a different permission mode](https://code.claude.com/docs/en/permission-modes#start-in-a-different-mode)

  | To set the starting permission mode for | Do this |
  | :- | :- |
  | One session you're about to start | Pass the permission mode as a flag, for example `claude --permission-mode default` |
  | Every terminal session you start on this machine | Set `permissions.defaultMode` in `~/.claude/settings.json`. For what the VS Code extension reads, see [Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes) |
  | Every terminal session you start in one project | Set `permissions.defaultMode` in the project's `.claude/settings.json`. Sessions you start in a terminal honor every value except `auto` and `bypassPermissions`; sessions the VS Code extension starts don't read project settings for the starting permission mode |
  | Every terminal session in your organization | Set `permissions.defaultMode` in [managed settings](https://code.claude.com/docs/en/managed-settings). Terminal sessions start in that mode and people can still switch to auto mode; for what the VS Code extension reads, see [Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes) |

- This example makes every terminal session on your machine start in Manual mode.
  Save it in `~/.claude/settings.json`:
  [permission-modes › Start in a different permission mode](https://code.claude.com/docs/en/permission-modes#start-in-a-different-mode)

  ```json
  {
    "permissions": {
      "defaultMode": "default"
    }
  }
  ```

  The next session you start shows `⏸ manual mode on` in the status bar.

- `claude remote-control --permission-mode <mode>` sets the starting permission mode for the sessions Remote Control
  starts, such as `acceptEdits`. It accepts `manual` as an alias for `default`; an unrecognized mode stops the server at
  startup and lists the valid modes. A `--permission-mode` placed before the `remote-control` verb never reaches those
  sessions, so Claude Code refuses to start, naming the flag.
  [remote-control › Start a Remote Control session](https://code.claude.com/docs/en/remote-control#start-a-remote-control-session)
  and [errors › Not carried over to the sessions Remote Control starts](https://code.claude.com/docs/en/errors#not-carried-over-to-the-sessions-remote-control-starts)
- Agent teams: teammates start with the lead's permission mode, except `dontAsk`, which they don't inherit. If the lead
  runs with `--dangerously-skip-permissions`, all teammates do too. After spawning, you can change an individual
  teammate's permission mode, but you can't set per-teammate modes at spawn time.
  [agent-teams › Permissions](https://code.claude.com/docs/en/agent-teams#permissions)
- Agent view: a session you background with `/bg` or `←` keeps the permission mode it was in. A session dispatched
  from `claude agents` started in a shell, or with `claude --bg`, starts the way a new `claude` session in that
  directory would, unless you dispatched it from an agent view you opened with dispatch defaults. For a session you
  dispatch from an agent view opened with `←`, Claude Code takes the mode from the first that applies: the target
  directory's `permissions.defaultMode` (`auto` and `bypassPermissions` take effect only from managed settings, a
  `--settings` file or `~/.claude/settings.json`; Claude Code refuses a `defaultMode` from the project's
  `.claude/settings.json` or `.claude/settings.local.json` that selects a more permissive mode than the session you
  came from was in); then the permission mode of the session you came from. When a source's mode is refused as too
  permissive, the next source decides: dispatching from a plan-mode session into a directory whose checked-in
  settings ask for `acceptEdits` starts the new session in plan mode, and moving that `defaultMode` to
  `~/.claude/settings.json` makes it apply regardless of the source session's mode. Permissiveness runs plan, then
  Manual and `dontAsk`, then `acceptEdits` and auto (each counts as more permissive than the other), then
  `bypassPermissions`.
  [agent-view › Permission mode](https://code.claude.com/docs/en/agent-view#permission-mode)
- Agent view dispatch defaults: pass `--permission-mode` when opening `claude agents` to set the mode for every
  session you dispatch from it. `claude agents` also accepts `--dangerously-skip-permissions` as shorthand for
  `--permission-mode bypassPermissions`, `--allow-dangerously-skip-permissions` to make `bypassPermissions` available
  in each dispatched session's `Shift+Tab` cycle without starting in it, and `--restricted` to start every dispatched
  session in restricted mode.
  [agent-view › Dispatch defaults](https://code.claude.com/docs/en/agent-view#dispatch-defaults)
- `permissions.defaultMode` is valid in any settings file, though `auto` and `bypassPermissions` don't take effect from
  project or local settings. Its default is unset. For conversations the VS Code extension starts, Claude Code reads
  only user, managed and `--settings` values. In cloud sessions, Claude Code
  honors only `acceptEdits`, `plan`, `default` and `auto` from this key.
  [settings-reference › `permissions.defaultMode`](https://code.claude.com/docs/en/settings-reference#permissions-defaultmode)
- A `permissions.defaultMode` value is one of `"default"`, `"acceptEdits"`, `"plan"`, `"auto"`, `"dontAsk"`,
  `"bypassPermissions"` or `"manual"` (an alias for `"default"`).
  [settings-reference › `permissions.defaultMode`](https://code.claude.com/docs/en/settings-reference#permissions-defaultmode)
- Preventing `bypassPermissions`: `permissions.disableBypassPermissionsMode` takes the string `"disable"`, is valid in
  any file and is typically set in managed settings to enforce organizational policy. Claude Code then rejects
  `--dangerously-skip-permissions`; the key takes precedence over it. It works from any scope, so a user can set it in
  their own settings to lock themselves out of bypass mode.
  [settings-reference › `permissions.disableBypassPermissionsMode`](https://code.claude.com/docs/en/settings-reference#permissions-disablebypasspermissionsmode)
  and [permissions › Managed settings](https://code.claude.com/docs/en/permissions#managed-settings)

  ```json
  {
    "permissions": {
      "disableBypassPermissionsMode": "disable"
    }
  }
  ```

## Switching modes in a session

- In the Manual and `acceptEdits` permission modes, when auto mode is available, Claude Code adds **Yes, and switch to
  auto mode** to a Bash command's permission prompt. Selecting it approves the command and switches the session to
  auto mode. PowerShell tool prompts don't offer the option.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- In the CLI, `Shift+Tab` cycles permission modes. From `auto`, the first press switches to `default`, and the cycle
  then runs `default` → `acceptEdits` → `plan`. Optional modes slot in after `plan`.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- Not every mode is in the default CLI cycle:
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
  - `auto` appears when auto mode is available; cycling to it switches permission modes without a confirmation prompt.
  - `bypassPermissions` appears after you start with `--permission-mode bypassPermissions`,
    `--dangerously-skip-permissions`, `--allow-dangerously-skip-permissions`, or `permissions.defaultMode:
    "bypassPermissions"` in user, `--settings` or managed settings. The `--allow-` variant adds the permission mode to
    the cycle without activating it.
  - `dontAsk` never appears in the cycle; set it with `--permission-mode dontAsk`.
  - Enabled optional modes slot in after `plan`, with `bypassPermissions` first and `auto` last. With both enabled, you
    cycle through `bypassPermissions` on the way to `auto`.
- The same `--permission-mode` flag works with `-p`.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- JetBrains: the plugin runs Claude Code in the IDE terminal, so switching works as in the CLI: `Shift+Tab` to cycle, or
  `--permission-mode` at launch.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- VS Code: the mode indicator at the bottom of the prompt box switches modes during a session. Its labels are Manual
  (`default`), Edit automatically (`acceptEdits`), Plan (`plan`), Auto (`auto`) and Bypass permissions
  (`bypassPermissions`).
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- VS Code: `claudeCode.initialPermissionMode` in your VS Code user settings pins the starting mode to `default`,
  `manual`, `acceptEdits`, `plan` or `bypassPermissions`; it doesn't accept `auto`. To start in Auto, leave it unset
  and pick **Auto** from the mode indicator once. The extension starts each new conversation in the first of these that
  applies: `claudeCode.initialPermissionMode`; the mode you last picked from the mode indicator, if it was Manual, Edit
  automatically or Auto (picking Plan or Bypass permissions applies to that conversation only);
  `permissions.defaultMode` from managed settings or `~/.claude/settings.json`; the built-in default.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- VS Code: the extension never reads a project's `.claude/settings.json` or `.claude/settings.local.json` for the
  starting permission mode. When `claudeCode.claudeProcessWrapper` is set, the managed-or-user `defaultMode` and the
  built-in default don't apply: those conversations start in Manual unless `claudeCode.initialPermissionMode` or the
  last-picked mode sets one.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)
- VS Code: Bypass permissions requires the **Allow dangerously skip permissions** toggle in the extension settings.
  Without it, the mode doesn't appear in the indicator, and a `bypassPermissions` value from
  `claudeCode.initialPermissionMode` or `permissions.defaultMode` starts the conversation in Manual instead. Auto from
  any item likewise starts the conversation in Manual when auto mode isn't available. Auto appears in the mode
  indicator when auto mode is available.
  [permission-modes › Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes)

## acceptEdits

- `acceptEdits` mode lets Claude create and edit files in your working directory without prompting. It also
  auto-approves the common filesystem Bash commands `mkdir`, `touch`, `rm`, `rmdir`, `mv`, `cp` and `sed`. Except for
  `touch`, these are also auto-approved when prefixed with safe environment variables such as `LANG=C` or
  `NO_COLOR=1`, or process wrappers such as `timeout`, `nice` or `nohup`. Like file edits, auto-approval applies only
  to paths inside your working directory or `additionalDirectories`.
  [permission-modes › Auto-approve file edits with acceptEdits mode](https://code.claude.com/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode)
- These still prompt in `acceptEdits` mode: paths outside that scope; writes to protected paths; recognized `rm` and
  `rmdir` critical-path removals; `touch` with anything beyond plain file paths, for example an option, a glob, or a
  prefix such as `timeout 5` or `LANG=C`; and all other Bash commands except the built-in read-only set.
  [permission-modes › Auto-approve file edits with acceptEdits mode](https://code.claude.com/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode)
- In a non-interactive run in `acceptEdits`, apart from the read-only command set, other shell commands and network
  requests still need an `--allowedTools` entry or a `permissions.allow` rule.
  [headless › Auto-approve tools](https://code.claude.com/docs/en/headless#auto-approve-tools)
- When the PowerShell tool is enabled, `acceptEdits` mode also auto-approves `Set-Content`, `Add-Content`,
  `Clear-Content` and `Remove-Item` on in-scope paths, along with their common aliases. The same scope and
  protected-path rules apply, and `Remove-Item` gets its own check (see Remove-Item in PowerShell). A positional
  argument that contains a quote character, such as the apostrophe in `Set-Content .\notes.txt "It's done"`, still
  prompts even on in-scope paths, because Claude Code can't statically validate an argument whose quoted and unquoted
  readings differ. Pass the content through a named parameter such as `-Value` to avoid the prompt.
  [permission-modes › Auto-approve file edits with acceptEdits mode](https://code.claude.com/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode)
- The status bar shows `⏵⏵ accept edits on` while this mode is active. Use `acceptEdits` when you want to review
  changes in your editor or via `git diff` after the fact rather than approving each edit inline.
  [permission-modes › Auto-approve file edits with acceptEdits mode](https://code.claude.com/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode)
- Press `Shift+Tab` once from Manual mode to enter it, or start with `claude --permission-mode acceptEdits`.
  [permission-modes › Auto-approve file edits with acceptEdits mode](https://code.claude.com/docs/en/permission-modes#auto-approve-file-edits-with-acceptedits-mode)

## plan

- Plan mode tells Claude to research and propose changes without making them. Claude reads files, runs shell commands
  to explore, and writes a plan, but does not edit your source. Except in interactive terminal sessions with bypass
  permissions available, edits stay blocked until you approve the plan.
  [permission-modes › Analyze before you edit with plan mode](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode)
- What happens to a shell command during planning depends on the session; the first case that matches applies:
  - Interactive terminal sessions with bypass permissions available: neither the classifier nor a prompt applies to
    planning commands.
  - Auto mode available and `useAutoModeDuringPlan` on, which it is by default: the classifier reviews shell commands
    other than critical-path removals instead of prompting you. Approved commands run, and rejected ones are blocked.
  - Auto mode not available, or `useAutoModeDuringPlan` off: commands outside the built-in read-only set prompt for
    approval, including when the sandbox's auto-allow mode is enabled.
  [permission-modes › Analyze before you edit with plan mode](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode)
- Enter plan mode by pressing `Shift+Tab` or prefixing a single prompt with `/plan`, or start with
  `claude --permission-mode plan`. Press `Shift+Tab` again to leave plan mode without approving a plan.
  [permission-modes › Analyze before you edit with plan mode](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode)
- When the plan is ready, Claude presents it and asks how to proceed:
  [permission-modes › Review and approve a plan](https://code.claude.com/docs/en/permission-modes#review-and-approve-a-plan)
  - **Yes, clear context and ...**: appears as the first option only when `showClearContextOnPlanAccept` is `true`
    (default `false`). It approves the plan, clears the conversation context and starts implementing
    from the plan alone; the rest of the label names the permission mode the session continues in and shows how much of
    your context the planning used.
    [settings-reference › `showClearContextOnPlanAccept`](https://code.claude.com/docs/en/settings-reference#showclearcontextonplanaccept)
  - **Yes, and use auto mode**: approve and start in auto mode. If auto mode isn't available to your session, for
    example because your organization turned it off, this option reads **Yes, auto-accept edits**. If you started the
    session with bypass permissions enabled, the option reads **Yes, and switch to BYPASS PERMISSIONS (no further
    prompts) for this session** instead.
  - **Yes, manually approve edits**: approve and review each edit individually.
  - **No, keep planning**: stay in plan mode and tell Claude what to change.
- Approving a plan exits plan mode and switches the session to the permission mode each approve option describes. To
  plan again, cycle back to plan mode with `Shift+Tab`, or prefix your next prompt with `/plan`.
  [permission-modes › Review and approve a plan](https://code.claude.com/docs/en/permission-modes#review-and-approve-a-plan)

## dontAsk

- With `dontAsk` mode, Claude Code auto-denies every tool call that would otherwise prompt you. Claude still runs
  actions that need no approval in Manual mode, such as file reads inside your working directories and read-only Bash
  commands, and actions matching your `permissions.allow` rules. The session never waits for input, which suits CI
  pipelines or restricted environments. The status bar shows `⏵⏵ don't ask on` in this mode.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)
- In `dontAsk` mode Claude Code denies, rather than prompts for, calls matching your explicit `ask` rules. It also
  denies the built-in `AskUserQuestion` tool even if your allow rules match it, does the same to connector tools your
  organization set to `ask` in sessions where that setting reaches Claude Code, and denies MCP tools marked
  `_meta["anthropic/requiresUserInteraction"]`, because their approval card needs an answer this mode never collects.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)
- An allow rule can't approve reads from a network path.
  [permission-modes › Allow only pre-approved tools with dontAsk mode](https://code.claude.com/docs/en/permission-modes#allow-only-pre-approved-tools-with-dontask-mode)

## bypassPermissions

- `bypassPermissions` mode disables permission prompts and safety checks so tool calls execute immediately, including
  writes to protected paths. It offers no protection against prompt injection or unintended actions; only use it in
  isolated environments like containers, VMs, or dev containers without internet access. For background safety checks
  with far fewer prompts, use auto mode instead.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- Even in `bypassPermissions` mode, each of the actions no mode auto-approves gets a prompt or a denial. Reading another
  organization's public artifact needs your approval, which this mode doesn't ask for, so Claude can't read one. The
  Remove-Item in PowerShell denies also apply in this mode.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- In interactive terminal sessions with bypass permissions available, Claude Code doesn't enforce plan mode's blocks:
  Claude is still instructed to plan without editing, but a file edit or shell command it attempts during planning runs
  without prompting. Explicit ask rules and recognized `rm` and `rmdir` critical-path removals still prompt. Plan mode
  keeps its blocks wherever Claude Code runs without an interactive terminal, including `-p` runs, Agent SDK sessions
  and conversations in the VS Code extension's chat panel; there, `--allow-dangerously-skip-permissions` makes
  `bypassPermissions` selectable later.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- You can't enter `bypassPermissions` from a session you started without it enabled. Enable it at launch with
  `permissions.defaultMode: "bypassPermissions"` or an enabling flag such as `claude --permission-mode
  bypassPermissions`; `--dangerously-skip-permissions` is equivalent. Claude Code refuses `bypassPermissions` in a
  session you start with `--restricted`.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- The first time you start an interactive session with this mode enabled, Claude Code shows a warning dialog. If you
  accept, it sets `skipDangerousModePermissionPrompt` to `true` in `~/.claude/settings.json`, so later sessions skip the
  dialog; to see it again, remove the key from that file or set it to `false`. If you decline, Claude Code exits. In
  non-interactive mode no dialog is shown.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- `skipDangerousModePermissionPrompt` skips the confirmation dialog before a session enters `bypassPermissions` mode,
  whether from `--dangerously-skip-permissions` or `defaultMode: "bypassPermissions"`. Its scope is user, local or
  managed; an untrusted repository can't skip the dialog for you. `false` is the same as unset: the dialog appears
  unless another of these files sets `true`. Default: unset, so the dialog appears. With the key set in user or managed
  settings, a session you start in `bypassPermissions` mode also skips the approval prompt for project-scoped MCP
  servers.
  [settings-reference › `skipDangerousModePermissionPrompt`](https://code.claude.com/docs/en/settings-reference#skipdangerousmodepermissionprompt)
  and [mcp › Project scope](https://code.claude.com/docs/en/mcp#project-scope)

  ```json
  {
    "skipDangerousModePermissionPrompt": true
  }
  ```

- A background session honors your acceptance when it's recorded in user or managed settings. With no acceptance
  recorded, `claude --bg --permission-mode bypassPermissions` is refused; accept the dialog in an interactive session
  first. With `skipDangerousModePermissionPrompt` set only in `.claude/settings.local.json`, the background session
  starts with the bypass request ignored: with `--allow-dangerously-skip-permissions` ignored, `bypassPermissions` is
  left out of its `Shift+Tab` cycle, and with `--permission-mode bypassPermissions` or
  `--dangerously-skip-permissions` ignored, the session starts in Manual mode instead.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- When a background session ignores the bypass request, it prints `Bypass permissions was requested at launch and
  ignored · if that was you, ~/.claude/settings.json needs "skipDangerousModePermissionPrompt": true`. It means the
  session didn't find your acceptance in user or managed settings. Add `"skipDangerousModePermissionPrompt": true` to
  `~/.claude/settings.json`, then start a new background session.
  [permission-modes › Bypass permissions ignored in a background session](https://code.claude.com/docs/en/permission-modes#bypass-permissions-ignored-in-a-background-session)
- If `claude agents` shows the bypass permissions warning although your interactive sessions skip it, check whether
  `skipDangerousModePermissionPrompt` is set in `.claude/settings.local.json` or a `--settings` file. Interactive
  sessions count the key there as your acceptance, and `claude agents` doesn't. Accept the warning to add the key to
  `~/.claude/settings.json`, where `claude agents` looks for it.
  [permission-modes › `claude agents` shows the bypass permissions warning that interactive sessions skip](https://code.claude.com/docs/en/permission-modes#claude-agents-shows-the-bypass-permissions-warning-that-interactive-sessions-skip)
- On Linux and macOS, Claude Code refuses to start in `bypassPermissions` mode when running as root or under `sudo`,
  printing `--dangerously-skip-permissions cannot be used with root/sudo privileges for security reasons`. The check is
  skipped automatically inside a recognized sandbox. To run autonomously in a container, use the dev container
  configuration, which runs Claude Code as a non-root user.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)

## Unattended runs

- In a `claude -p` run with no permission mode set, calls needing approval are denied unless you approve them with an
  allow rule, a hook or `--permission-prompt-tool`. To get them approved, add allow rules by passing `--allowedTools
  "Bash(npm test)"`, or start in auto mode, where a classifier model reviews calls so you list nothing beforehand.
  [permission-modes › Tool calls denied in `claude -p` and Agent SDK runs](https://code.claude.com/docs/en/permission-modes#which-mode-a-non-interactive-run-starts-in)

  ```bash
  claude -p "Run the test suite and fix any failures" --permission-mode auto
  ```

- In a `claude -p "<prompt>" --dangerously-skip-permissions` run, the few calls that would still prompt are denied
  instead.
  [permission-modes › Common setups](https://code.claude.com/docs/en/permission-modes#common-setups)
- Pass `--permission-prompts none` when nobody is available to answer permission prompts, for example in a scheduled
  job. The flag matters most when your run has a permission host: an Agent SDK app with a `canUseTool` callback, or an
  MCP tool you pass with `--permission-prompt-tool`. Without the flag, your run waits for that host to answer each
  permission request.
  [headless › Turn off permission prompts in unattended runs](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs)
- With `--permission-prompts none`, your run doesn't consult the host or wait on it. Anything that would prompt is
  denied unless a `PermissionRequest` hook allows it, Claude is told that nobody can approve the request and not to
  retry it, and the run continues. In a `-p` run with no host, these requests are denied either way, and the flag also
  tells Claude not to retry them. Permission rules, hooks and the permission mode you set still decide every call
  first; Claude Code denies only the requests that nothing else resolves. It also removes the tools that need an
  answer from a person, such as `AskUserQuestion`, so Claude can't call them. With `--output-format stream-json`,
  denials appear as `permission_denied` system messages, and the final result message lists them in
  `permission_denials`.
  [headless › Turn off permission prompts in unattended runs](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs)

  ```bash
  claude -p "Update the dependency pins and run the tests" --permission-mode auto --permission-prompts none
  ```

- `--permission-prompt-tool` specifies an MCP tool to handle permission prompts in non-interactive mode. Pass the full
  name, such as `mcp__<server>__<tool>`, of a tool on an MCP server that the run loads. Claude Code waits for that
  tool's MCP server to connect before running the first turn, up to the `MCP_TIMEOUT` startup timeout, 30 seconds by
  default. The prompt tool can't approve an MCP tool marked as requiring user interaction: Claude Code converts an
  `allow` result for one to a deny.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

  ```bash
  claude -p --mcp-config ./mcp.json --permission-prompt-tool mcp__permissions__approve "query"
  ```

- The deny that replaces a prompt tool's `allow` for an MCP tool that requires user interaction carries the message
  `MCP tool requires user interaction; not supported via --permission-prompt-tool`. The Agent SDK's `canUseTool`
  callback does receive these calls and can approve them. The interactive prompt for such a tool offers no "don't ask
  again" option.
  [mcp › Require approval for a specific tool](https://code.claude.com/docs/en/mcp#require-approval-for-a-specific-tool)
- When the tool you passed to `--permission-prompt-tool` isn't among the connected MCP tools at the run's first
  permission decision, because its server never connected or no connected server exposes a tool by that name, the
  non-interactive run exits with exit code 1 on the first tool call and produces no answer, although Claude Code still
  sent your prompt. The error reads `Error: MCP tool mcp__permissions__approve (passed via --permission-prompt-tool) not
  found. Available MCP tools: none`, with your tool's name.
  [errors › MCP permission prompt tool not found](https://code.claude.com/docs/en/errors#mcp-permission-prompt-tool-not-found)

## Resuming a session

- Which permission mode Claude Code starts a resumed session in depends on how you resume. The cases apply when Claude
  Code loads the conversation from its transcript; when you open a background session that is still running instead,
  that session keeps the permission mode it is in.
  [sessions › Permission mode on resume](https://code.claude.com/docs/en/sessions#permission-mode-on-resume)
  - Terminal (`claude --continue`, `claude --resume <session-id>`, or `claude --resume <name>` when the name matches
    one session, without `-p`): Claude Code restores the permission mode the session was in, except in the cases in
    the table. Pass `--permission-mode` or `--dangerously-skip-permissions` to override the restored mode.
  - Non-interactive (`claude -p --resume` or `claude -p --continue`): the run starts in the permission mode a new
    `claude -p` run would start in, except that a session that ended in plan mode resumes in plan mode under the
    conditions below.
  - VS Code: the table covers only a conversation that ended in plan mode.
  - Session picker at launch (a session you select from the session picker, whether you opened it with
    `claude --resume` alone, `claude --from-pr`, or a name that matches more than one session): Claude Code starts the
    session in the permission mode it would start a new session in from the same command line, except that a session
    that ended in plan mode resumes in plan mode. If you pass `--permission-mode`, `--dangerously-skip-permissions` or
    `--fork-session`, Claude Code doesn't restore plan mode. No other stored permission mode is restored.
  - `/resume` inside a session: the conversation you switch to continues in the permission mode your current session
    is in, except that a conversation that ended in plan mode resumes in plan mode, even if you launched Claude Code
    with `--permission-mode` or `--dangerously-skip-permissions`. If that conversation was already open earlier in this
    run of Claude Code, such as the conversation you started in or one you left with `/clear` or `/resume`, it
    continues in your current permission mode instead.
- If a deny rule removes the `ExitPlanMode` tool, Claude can't present a plan for approval, so Claude Code doesn't
  restore plan mode. The session starts in the permission mode a new session would start in from the same command
  line. With `/resume`, the conversation continues in your current permission mode.
  [sessions › Permission mode on resume](https://code.claude.com/docs/en/sessions#permission-mode-on-resume)
- Each row names the permission mode the session ended in, how you resume it, and the mode Claude Code starts the
  resumed session in:
  [sessions › Permission mode on resume](https://code.claude.com/docs/en/sessions#permission-mode-on-resume)

  | Session ended in | How you resume | Permission mode after you resume |
  | :- | :- | :- |
  | `bypassPermissions` | Terminal | The permission mode a new session would start in. To [bypass permissions](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) again, enable it at launch with one of its launch flags or `permissions.defaultMode: "bypassPermissions"` in [user, `--settings`, or managed settings](https://code.claude.com/docs/en/settings-reference#permissions-defaultmode) |
  | `plan` | Terminal | Plan mode. With `--fork-session`, the permission mode a new session would start in |
  | `plan` | Terminal, when a deny rule removes `ExitPlanMode` | The permission mode a new session would start in |
  | `auto` | Terminal | `auto`, only when your account still meets the [auto mode requirements](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) |
  | Manual | Terminal | Manual when a new session would start in auto mode from the [built-in default](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in). When a `defaultMode` from a settings file [takes effect](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in), Claude Code starts the resumed session in that mode instead |
  | `plan` | Non-interactive, under the conditions below | Plan mode |
  | Any mode | Non-interactive, in any other case | The permission mode a new `claude -p` run would start in |
  | `plan` | VS Code | Plan mode, with [the exceptions on the VS Code page](https://code.claude.com/docs/en/vs-code#resume-past-conversations) |

- A `claude -p --resume` or `claude -p --continue` run resumes in plan mode only when all of these hold: you pass
  `--permission-prompt-tool` and don't pass `--permission-prompts none`, so that Claude Code can present the plan for
  approval; you don't pass `--permission-mode` or `--dangerously-skip-permissions`; you don't pass `--fork-session`;
  the run isn't started through channels; and no deny rule removes the `ExitPlanMode` tool.
  [sessions › Resume in plan mode with `-p`](https://code.claude.com/docs/en/sessions#resume-in-plan-mode-with-p)

## Protected paths

- Writes to a small set of paths are never auto-approved, except in `bypassPermissions` mode and in interactive
  terminal sessions in plan mode with bypass permissions available. This prevents accidental corruption of repository
  state and Claude's own configuration.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)

  | Mode | Protected-path writes |
  | :- | :- |
  | `default`, `acceptEdits` | Prompted |
  | `plan` | Allowed in interactive terminal sessions with [bypass permissions](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) available. Otherwise, routed to the classifier when [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) is available during planning, and prompted when it isn't |
  | `auto` | Routed to the classifier |
  | `dontAsk` | Denied |
  | `bypassPermissions` | Allowed |

- In a session started with `--restricted`, the classifier can't approve protected-path writes.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)
- In the modes that route protected-path writes to the classifier, a write that the symlink check resolves to a
  protected path prompts you instead when the path Claude requested isn't itself protected.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)
- `permissions.allow` rules in settings files do not pre-approve protected-path writes. The safety check runs before
  Claude Code evaluates allow rules from settings, so an entry such as `Edit(.claude/**)` in `~/.claude/settings.json`
  or `.claude/settings.json` does not change the per-mode outcome in the table. In permission modes that prompt, the
  prompt for a write to the project's `.claude/` folder or to `~/.claude/` can offer a session-scoped option:
  **Yes, and allow Claude to edit files in this project's .claude folder for this session**, or **Yes, and allow Claude
  to edit files in its ~/.claude folder for this session**.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)
- Protected directories: `.git`, `.config/git`, `.vscode`, `.idea`, `.husky`, `.cargo`, `.devcontainer`, `.yarn`,
  `.mvn`, and `.claude`, with a few exceptions, such as Claude's own git worktrees under `.claude/worktrees/`, the
  current session's own plan files in `~/.claude/plans/` (or in the `plansDirectory` you set), a background
  session's own scratch directory at `~/.claude/jobs/<id>/tmp/`, and Markdown files in the project's auto memory
  directory, such as `~/.claude/projects/<project>/memory/`, in a session started without `--restricted`. A directory
  you loaded with `--plugin-dir` is also protected, because Claude Code reloads and runs a mod's code from it when a
  file changes, as are `~/.claude/dev-mods/`
  and `dev-mods/` in the directory `CLAUDE_CONFIG_DIR` points to, where Claude saves the mods it writes for you.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)
- Protected files:
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)
  - `.gitconfig`, `.gitmodules`
  - `.bashrc`, `.bash_profile`, `.bash_login`, `.bash_aliases`, `.bash_logout`, `.zshrc`, `.zprofile`, `.zshenv`,
    `.zlogin`, `.zlogout`, `.profile`, `.envrc`
  - `.npmrc`, `.yarnrc`, `.yarnrc.yml`, `.pnp.cjs`, `.pnp.loader.mjs`, `.pnpmfile.cjs`, `bunfig.toml`, `.bunfig.toml`
  - `.bazelrc`, `.bazelversion`, `.bazeliskrc`
  - `.pre-commit-config.yaml`, `lefthook.yml`, `lefthook.yaml`, `.lefthook.yml`, `.lefthook.yaml`
  - `gradle-wrapper.properties`, `maven-wrapper.properties`
  - `.devcontainer.json`
  - `.ripgreprc`, `pyrightconfig.json`
  - `.mcp.json`, `.claude.json`
  - A file you passed to `--settings`, `--mcp-config` or `--agents` when you started the session
  - The file that your user, project or local settings file points to when the settings file is itself a symbolic
    link, for example into a dotfiles repository. In the modes that route protected-path writes to the classifier, a
    write to this file prompts you instead, even when an allow rule matches. If the file's own path is also that of a
    settings file, such as `.claude/settings.json` in another folder, the write goes to the classifier as other
    protected-path writes do.

## Critical paths

- Critical paths are the directories Claude Code protects from `rm` and `rmdir` commands, such as the filesystem root,
  your home directory and your working directory. Claude Code checks these commands before they run, and no allow rule
  approves one whose target it recognizes as a critical path, even in the permission modes that skip other prompts.
  The check can miss some commands, so it doesn't replace an operating-system control such as sandboxing.
  [permission-modes › Critical paths](https://code.claude.com/docs/en/permission-modes#critical-paths)
- A command the check misses gets no special handling, so anything that approves Bash commands in your session can
  approve it with no prompt. That includes an allow rule, `bypassPermissions` mode, and the sandbox's auto-allow mode.
  The check applies to `rm` and `rmdir`, so other approved commands can delete critical paths too.
  [permission-modes › Critical paths](https://code.claude.com/docs/en/permission-modes#critical-paths)
- These controls apply whether or not the check recognizes a command: a deny rule that matches the command blocks it
  (though a mod you installed can still approve some of those calls); sandboxing has the operating system limit which
  paths Bash commands can write to, though sandboxed commands can still delete your working directory; and strict
  sandbox mode turns off the retry outside the sandbox, which by default an allow rule or `bypassPermissions` mode can
  approve with no prompt.
  [permission-modes › Critical paths](https://code.claude.com/docs/en/permission-modes#critical-paths)
- `Remove-Item` and the `cmd` removal built-ins have their own checks (see Remove-Item in PowerShell).
  [permission-modes › Critical paths](https://code.claude.com/docs/en/permission-modes#critical-paths)
- Claude Code treats an `rm` or `rmdir` target as a critical path when it is any of: the filesystem root; top-level
  directories, meaning any direct child of the root, such as `/usr`, `/etc` or `/data`; your home directory (on
  Windows, its 8.3 short name counts too, such as `C:\Users\LONGNA~1`); Windows drive roots and their top-level
  directories, such as `C:\` and `C:\Windows` (spellings such as `\\?\C:\` and `\\localhost\C$` count as `C:\`); your
  working directory and its parents; your additional working directories and their parents, but only when the removal
  is a glob under one of them, such as `rm -rf <dir>/*`, since `rm -rf <dir>` on the directory itself doesn't trigger
  this check. Mounted drive paths such as `/mnt/c` or `/Volumes/USB` are covered under Mounted drive prompt.
  [permission-modes › Which paths are critical](https://code.claude.com/docs/en/permission-modes#which-paths-are-critical)
- Claude Code also treats these `rm` and `rmdir` targets as critical paths; the last column says why:
  [permission-modes › Other targets that count as critical paths](https://code.claude.com/docs/en/permission-modes#other-targets-that-count-as-critical-paths)

  | Target | Example | Why it counts |
  | :- | :- | :- |
  | A glob or trailing slash directly under a shell variable | `rm -rf "$DIR"/*` | The command becomes a removal from the filesystem root when the variable is empty |
  | The same form under a positional parameter such as `$1` or `$@`, when nothing in the command gives it a value | `rm -rf "$1"/*` | The command expands to a removal from the root |
  | A shell variable followed by one common top-level directory name, such as `mnt`, `tmp`, `usr`, or `Users` | `rm -rf "$TMPDIR/mnt"` | When the variable expands empty, the command removes `/mnt` |
  | A variable that the same command assigns from a directory-printing substitution, such as `$(pwd)` or `$(git rev-parse --show-toplevel)` | `D=$(pwd); rm -rf "$D"` | The value can name your working directory or repository root |
  | A target that is only the output of a command substitution, when the `rm` is recursive | `rm -rf "$(pwd)"` | Claude Code can't check the target before the command runs |
  | A trailing command substitution after a critical path | `rm -rf ~/$(cmd)` | Claude Code checks the path that would remain if the substitution expanded empty, here your home directory |
  | A target that is only backslashes | `rm -rf "\\"` | Git Bash on Windows reads a lone backslash as the current drive's root, so the check applies on every platform |
  | A Windows path that names a volume by GUID instead of a drive letter | `rm -rf '\\?\Volume{GUID}\work\build'` | The path doesn't say which drive it's on, so it could be a critical path |
  | Some targets that end in `/*` or `/*/` | `rm -rf logs/*/*`, `rm -rf logs/*/`, `cd logs && rm -rf a/*` | Claude Code can't tell before the command runs which directories they reach |

- To turn off the check on a target that is only command substitution output, set
  `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT=1` in the environment that launches Claude Code.
  [permission-modes › Other targets that count as critical paths](https://code.claude.com/docs/en/permission-modes#other-targets-that-count-as-critical-paths)
- Claude Code also looks inside nested commands (a subshell with `(...)`, a brace group with `{ ...; }`, command
  substitution with `$(...)` or backticks, or process substitution with `<(...)`) and finds a critical-path removal
  whether it sits inside the nested form, as in `(rm -rf ~)` or `echo "$(rm -rf ~)"`, or elsewhere in the same
  command.
  [permission-modes › Removals inside nested commands and inline scripts](https://code.claude.com/docs/en/permission-modes#removals-inside-nested-commands-and-inline-scripts)
- Claude Code also looks inside inline scripts, a script passed to `sh`, `bash`, `zsh` or a similar POSIX shell with
  `-c`, as in `bash -c 'rm -rf ~'`. When the script is double-quoted, the invoking shell expands its variables before
  the inner shell receives the script: in `find . -name '*.tmp' -exec sh -c "rm -rf \"$1\"/*" _ {} \;`, the command
  expands to a removal from the filesystem root once per match, and Claude Code treats it as a critical-path removal. A
  single-quoted script that binds `$1` to a real value, as `sh -c 'rm -rf "$1"/*' _ {}` does, isn't flagged.
  [permission-modes › Removals inside nested commands and inline scripts](https://code.claude.com/docs/en/permission-modes#removals-inside-nested-commands-and-inline-scripts)
- To turn off the check on a critical path typed directly in a `-c` script, such as `~`, set
  `CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT=1` in the environment that launches Claude Code.
  [permission-modes › Removals inside nested commands and inline scripts](https://code.claude.com/docs/en/permission-modes#removals-inside-nested-commands-and-inline-scripts)
- How to rewrite a flagged command so it passes the check depends on which target it uses:
  [permission-modes › Rewrite a flagged command](https://code.claude.com/docs/en/permission-modes#rewrite-a-flagged-command)
  - A glob or trailing slash under a variable such as `$DIR`: guard each expansion so the shell stops with an error when
    the variable is unset or empty, as in `rm -rf "${DIR:?}"/*`, or use a literal path. A removal whose expansions are
    all guarded that way passes this check, so in `bypassPermissions` mode it runs without a prompt unless another
    critical-path check flags it.
  - A glob or trailing slash under a variable that is normally set, such as `$HOME`: use a literal path.
  - A variable assigned from a directory-printing substitution: use a literal path. A `"${D:?}"` guard doesn't clear
    this check, because the variable isn't empty.
  - A target that is only command substitution output: run the substitution on its own first, then remove the literal
    paths it prints. The prompt tells Claude to do the same.
  - For a glob or trailing slash under a variable, the prompt names the flagged `rm` and says how to rewrite it so the
    check passes.
- The full reason of the `Dangerous rm operation not ruled out` prompt reads:
  `Dangerous rm operation not ruled out — the shell may read this command differently than it was parsed`. It
  means the shell may read the command differently than Claude Code did, so a removal could sit in an unchecked part,
  even with no `rm` present. In `auto` or `bypassPermissions` mode, a denial with this sentence comes from the same
  check: `This command could not be checked for dangerous rm operations: the shell may read it differently than it was
  parsed.`
  [permission-modes › The `Dangerous rm operation not ruled out` prompt](https://code.claude.com/docs/en/permission-modes#dangerous-rm-operation-not-ruled-out)
- You get the prompt or denial a critical-path removal gets in your permission mode, `bypassPermissions` included,
  though you can turn off that prompt in `bypassPermissions` mode. You can't approve the command with a `Bash` or
  `Bash(*)` allow rule or sandbox auto-allow mode. Read the command, then approve the prompt or, after a denial, run it
  in your shell.
  [permission-modes › The `Dangerous rm operation not ruled out` prompt](https://code.claude.com/docs/en/permission-modes#dangerous-rm-operation-not-ruled-out)

## Mounted drive prompt

- The mounted drive prompt appears on macOS, Linux and WSL when a recursive `rm` targets a listed mounted drive path,
  such as `/mnt/c` or `/Volumes/USB/build`. Its reason reads `Dangerous rm operation on mounted drive path: <path>`. A
  `/*` target gets the prompt without the recursive flag, since Claude Code reads `rm /Volumes/USB/build/*` as a
  removal of `/Volumes/USB/build`.
  [permission-modes › The mounted drive prompt](https://code.claude.com/docs/en/permission-modes#the-mounted-drive-prompt)
- Even with an allow rule for `rm`, Claude Code handles the command as a critical-path removal: a prompt or a denial
  depending on your permission mode. Approve the prompt to let the `rm` run, or turn the prompt off.
  [permission-modes › The mounted drive prompt](https://code.claude.com/docs/en/permission-modes#the-mounted-drive-prompt)
- Match the target of your recursive `rm` or `/*` removal against these path shapes, where each placeholder such as
  `<drive>` or `<name>` stands for exactly one path segment:
  [permission-modes › Paths that get the mounted drive prompt](https://code.claude.com/docs/en/permission-modes#paths-that-get-the-mounted-drive-prompt)

  | Under | Path shapes that get the prompt | Examples |
  | :- | :- | :- |
  | `/Volumes` | `/Volumes/<drive>`, `/Volumes/<drive>/<name>` | `/Volumes/USB`, `/Volumes/USB/build` |
  | `/System/Volumes` | `/System/Volumes`, `/System/Volumes/<volume>`, `/System/Volumes/<volume>/<name>` | `/System/Volumes/Data` |
  | `/media` | `/media/<user>`, `/media/<user>/<drive>`, `/media/<user>/<drive>/<name>` | `/media/alex` |
  | `/run/media` | `/run/media`, `/run/media/<user>`, `/run/media/<user>/<drive>`, `/run/media/<user>/<drive>/<name>` | `/run/media/alex/USB/build` |
  | `/mnt` | `/mnt/<name>`, and `/mnt/<letter>/<name>` under a one-letter mount such as WSL's `/mnt/c` | `/mnt/data`, `/mnt/c/Users` |

- For a recursive or non-recursive `rm` on `/Volumes`, `/media` or `/mnt` itself, you see the critical-path reason
  `Dangerous rm operation on critical path: <path>` instead. A relative target counts from your working directory, so
  `rm -rf build` while you work in `/Volumes/USB` targets `/Volumes/USB/build` and gets the prompt.
  [permission-modes › Paths that get the mounted drive prompt](https://code.claude.com/docs/en/permission-modes#paths-that-get-the-mounted-drive-prompt)
- To stop getting the mounted drive prompt while prompts from other causes stay, start Claude Code with
  `CLAUDE_CODE_DISABLE_MOUNTED_DRIVE_RM_PROMPT=1` in its environment, for example by setting it in your shell and then
  starting `claude` from it. The prompt then stops for a whole drive such as `/Volumes/USB` and for the other listed
  paths: if you allow `Bash(rm *)`, use Manual mode, and work in `/Volumes/USB`, then `rm -rf build` runs with no
  prompt.
  [permission-modes › Turn off the mounted drive prompt](https://code.claude.com/docs/en/permission-modes#turn-off-the-mounted-drive-prompt)

  ```bash
  export CLAUDE_CODE_DISABLE_MOUNTED_DRIVE_RM_PROMPT=1
  claude
  ```

- A prompt that still shows `Dangerous rm operation on mounted drive path` means the variable isn't reaching the
  session: either it is in a settings file, where Claude Code ignores the variable in an `env` block whichever kind of
  settings file, so set it where you start `claude` instead; or the session started without it, so start `claude`
  again from an environment where it is set, since a running session doesn't pick it up.
  [permission-modes › Turn off the mounted drive prompt](https://code.claude.com/docs/en/permission-modes#turn-off-the-mounted-drive-prompt)
- In Manual mode with an allow rule for `rm`, with the mounted drive prompt off, an `rm` on a mounted drive path can
  still prompt, without the `Dangerous rm operation on mounted drive path` reason: when the target is outside your
  working directories (`rm -rf /Volumes/USB/other` while you work in `/Volumes/USB/project`; add a directory that
  contains the target to the session to stop it); when the target has a `*` (`rm -rf build/*`; approve the prompt, or
  ask Claude to name each target without a `*`); and when the target is a critical path (`/mnt` itself and your
  working directory itself stay critical paths; approve the prompt to let the `rm` run).
  [permission-modes › Removals that still prompt with the mounted drive prompt off](https://code.claude.com/docs/en/permission-modes#removals-that-still-prompt-with-the-mounted-drive-prompt-off)

## Critical-path removals in each mode

- What Claude Code does with a critical-path removal depends on your permission mode:
  [permission-modes › Critical-path removals in each permission mode](https://code.claude.com/docs/en/permission-modes#critical-path-removals-in-each-permission-mode)

  | Mode | Outcome |
  | :- | :- |
  | `default`, `acceptEdits` | Asks you to approve it |
  | `plan` | Asks you to approve it. When [the classifier reviews commands during planning](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode) and no bypass permissions are available, handles it as in `auto` mode |
  | `auto` | Asks you to approve it in the terminal, with a [time limit](https://code.claude.com/docs/en/permission-modes#time-limits-and-denials-in-auto-and-bypasspermissions-modes). Elsewhere, denies it |
  | `dontAsk` | Denies it |
  | `bypassPermissions` | In the terminal, asks you to approve it before a time limit runs out. Elsewhere, see [what happens in each place](https://code.claude.com/docs/en/permission-modes#time-limits-and-denials-in-auto-and-bypasspermissions-modes) |

- If an explicit ask rule matches the command, Claude Code asks you instead, even in `auto` mode and without a time
  limit.
  [permission-modes › Critical-path removals in each permission mode](https://code.claude.com/docs/en/permission-modes#critical-path-removals-in-each-permission-mode)
- In `auto` and `bypassPermissions` modes, the terminal prompt for a critical-path removal shows a two-minute
  countdown. If it runs out before you answer, Claude Code denies the command and tells Claude what to do instead, so
  an unattended session keeps working. Press any key while the prompt is open to stop the countdown and keep the
  prompt waiting for your answer. After three of these prompts run out unanswered in a session, Claude Code stops
  showing them and denies further critical-path removals immediately; sending a new message starts the count over.
  [permission-modes › Time limits and denials in auto and bypassPermissions modes](https://code.claude.com/docs/en/permission-modes#time-limits-and-denials-in-auto-and-bypasspermissions-modes)
- Away from the terminal, you don't get that prompt. Wherever the removal is denied, you can read the whole command and
  run it in your shell.
  [permission-modes › Time limits and denials in auto and bypassPermissions modes](https://code.claude.com/docs/en/permission-modes#time-limits-and-denials-in-auto-and-bypasspermissions-modes)

  | Where | `auto` | `bypassPermissions` |
  | :- | :- | :- |
  | [VS Code extension](https://code.claude.com/docs/en/vs-code)'s chat panel | Denies it | Denies it unless a [`PermissionRequest` hook](https://code.claude.com/docs/en/hooks#permissionrequest) allows it |
  | [Desktop app](https://code.claude.com/docs/en/desktop) | Denies it | Denies it unless a `PermissionRequest` hook allows it |
  | [`-p` run](https://code.claude.com/docs/en/headless) or [Agent SDK session](https://code.claude.com/docs/en/agent-sdk/permissions) | Denies it | Your [`--permission-prompt-tool`](https://code.claude.com/docs/en/cli-reference#cli-flags) or [`canUseTool` callback](https://code.claude.com/docs/en/agent-sdk/user-input#handle-tool-approval-requests) decides. With neither, or under [`--permission-prompts none`](https://code.claude.com/docs/en/headless#turn-off-permission-prompts-in-unattended-runs), denies it unless a `PermissionRequest` hook allows it. To run these removals with no prompt instead, see [Turn off the critical-path removal prompt](https://code.claude.com/docs/en/permission-modes#turn-off-the-critical-path-removal-prompt-in-bypasspermissions-mode) |

- Setting `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT` to `1` changes what you get: in `bypassPermissions`, the terminal
  prompt has no time limit and the VS Code chat panel asks you; in `auto`, the classifier decides, in the terminal, the
  VS Code chat panel, `-p` runs and Agent SDK sessions. Set it in the environment that starts Claude Code, not in a
  Claude Code settings file; for the VS Code chat panel, add it to `claudeCode.environmentVariables` in VS Code's own
  user `settings.json`, then start a new conversation.
  [permission-modes › Time limits and denials in auto and bypassPermissions modes](https://code.claude.com/docs/en/permission-modes#time-limits-and-denials-in-auto-and-bypasspermissions-modes)

## Turning off the critical-path removal prompt

- To run Bash `rm` and `rmdir` commands that target critical paths with no prompt in `bypassPermissions` mode, start
  Claude Code with `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS=1` in its environment. Claude Code reads the
  variable from the launch environment only and ignores it in a settings file's `env` block.
  [permission-modes › Turn off the critical-path removal prompt in bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#turn-off-the-critical-path-removal-prompt-in-bypasspermissions-mode)

  ```bash
  export CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS=1
  claude --permission-mode bypassPermissions
  ```

  On Windows PowerShell, set it with `$env:CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS = "1"`; in Windows CMD,
  with `set CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS=1`.
- With this variable set, a command such as `rm -rf ~` can run without asking you, so set it only in an isolated
  environment whose contents you can afford to lose. Removals run with no prompt only in `bypassPermissions` mode
  itself, not in plan mode, and only for what the critical-path check flags in the Bash and Monitor tools, including
  commands Claude Code can't fully parse.
  [permission-modes › Turn off the critical-path removal prompt in bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#turn-off-the-critical-path-removal-prompt-in-bypasspermissions-mode)
- To check whether `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS` is working, read the line Claude Code prints at
  startup; in a `-p` run it's on stderr. It says one of these: `is set, so dangerous rm commands can run without a
  prompt` (removals can run with no prompt once managed settings and plugin hooks have loaded); `has no effect in this
  session` (removals keep their usual prompt or denial for the whole session); or `has no effect while the Windows
  registry cannot be read for managed settings` (removals keep their usual prompt or denial, and the variable takes
  effect with no restart if a later read of the registry succeeds).
  [permission-modes › Startup notices about the critical-path removal prompt](https://code.claude.com/docs/en/permission-modes#startup-notices-about-the-critical-path-removal-prompt)
- Check that you set the variable in the launch environment, that the session can enter `bypassPermissions` mode, and
  that `claude` isn't inside another session. If you see one of these lines and didn't set the variable, find where it's
  set, such as your shell profile, and remove it.
  [permission-modes › Startup notices about the critical-path removal prompt](https://code.claude.com/docs/en/permission-modes#startup-notices-about-the-critical-path-removal-prompt)
- If `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS` has no effect and removals keep their usual prompt or denial,
  check for causes such as these:
  [permission-modes › Why the critical-path removal prompt stays on](https://code.claude.com/docs/en/permission-modes#why-the-critical-path-removal-prompt-stays-on)
  - A `--permission-prompt-tool` without `--permission-prompts none` handles permission prompts instead; remove the
    tool and restart `claude`.
  - The VS Code extension's chat panel or the Desktop app runs the session: start `claude` in a terminal instead, such
    as an IDE's integrated terminal.
  - A deny or ask rule targets Bash, Edit or Read, at launch or once Claude Code reads it during the session, even if
    you remove it later. Remove the rule and restart `claude`. To leave a tool out, use `--tools` instead of a deny
    rule.
  - `permissions.blockReadsOutsideWorkingDirectories` is on: remove the setting from every settings file that sets it
    to `true`, then restart `claude`.
  - `claude` runs inside another session: a `claude` started from a session's Bash tool or a hook, even with the
    variable on its command line. Start `claude` from your own shell. Don't rely on this nested-session limit as a
    security boundary.
  - Claude Code starts the session for you: background sessions, agent team teammates in split panes, and sessions a
    Remote Control server creates start without the variable. Start `claude` from your own shell.
  - Managed settings can't be read: Claude Code hasn't successfully read your managed settings sources. If
    server-managed settings keep failing to load, see Remote managed settings failed to load in the errors page; for
    any other failure that isn't a registry query, ask whoever manages that source to fix it.
  - The Windows registry can't be queried: on Windows and in WSL, the variable needs an answer from the registry, even
    when WSL doesn't use it for settings. The query can fail all session on a non-English Windows, in WSL with interop
    off, or in a container on a WSL2 kernel. If interop is off, turn it on. Otherwise, run those removals yourself.

## Remove-Item in PowerShell

- When you enable the PowerShell tool, Claude Code gives `Remove-Item` and the `cmd` built-ins `rd`, `rmdir`, `del` and
  `erase` their own checks, separate from the `rm` critical-path list. For `Remove-Item`, the first matching case
  applies:
  [permission-modes › Remove-Item in PowerShell](https://code.claude.com/docs/en/permission-modes#remove-item-in-powershell)
  - System paths (the filesystem root and its top-level directories, drive roots and their top-level directories, and
    your home directory): Claude Code denies the command in every mode, without asking you.
  - Wildcards (a bare `*`, or any target ending in `/*` or `\*`, including a glob under a shell variable such as
    `$dir/*`): Claude Code denies the command in every mode, without asking you, before the classifier sees it.
  - Your working directory or one of its parents, with `-Recurse`: Claude Code treats the command like any other that
    needs approval in your permission mode, so it asks you in modes that ask, sends it to the classifier in `auto`
    mode, and denies it in `dontAsk` mode. `bypassPermissions` mode skips this check.
- The system-paths case also applies to `rd`, `rmdir`, `del` and `erase` when Claude runs them through `cmd`, as in
  `cmd /c rd /s /q C:\Users`. By default, Claude Code denies such a command in every mode, without asking you. When
  judging a `cmd` target, Claude Code treats a PowerShell variable that follows literal text as empty, so
  `cmd /c rd /s /q "C:\$name"` is a removal of `C:\` and is denied too. A trailing wildcard counts as the folder it
  empties, so `cmd /c del /q C:\*` is denied and `cmd /c del /q dist\*` in your project is not.
  [permission-modes › Remove-Item in PowerShell](https://code.claude.com/docs/en/permission-modes#remove-item-in-powershell)
- To turn the `cmd` check off, set `CLAUDE_CODE_DISABLE_POWERSHELL_CMD_RM_DENY=1` in the environment that launches
  Claude Code, which ignores this variable in a settings file's `env` block. `Remove-Item` on a system path stays
  denied either way.
  [permission-modes › Remove-Item in PowerShell](https://code.claude.com/docs/en/permission-modes#remove-item-in-powershell)

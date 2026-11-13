# Settings reference

What Claude Code does with settings: which files hold them and how they combine, how to write and change them, the
keys they accept, permission rules, permission modes, auto mode, the sandbox and its credential protection, how an
organisation delivers managed settings, and how to find out why a setting doesn't apply.

## Contents

- [Key facts](#key-facts)
- [Topics](#topics)

## Key facts

- A key whose Scope in the settings index isn't `Any file`, such as `User or managed` or `Managed`, never applies
  from a repository's `.claude/settings.json`, apart from a few that a repository file can still switch off;
  `requiredMinimumVersion` and `requiredMaximumVersion` are ignored outside managed settings with no warning.
  See [keys.md › Settings index](keys.md), [keys.md › Managed-only keys with a narrower source](keys.md) and
  [troubleshooting.md › A change is lost or doesn't reach others](troubleshooting.md).
- A project's `permissions.allow` rules and `permissions.additionalDirectories` apply only after the folder's
  workspace trust dialog is accepted, and a `claude -p` run or SDK session never shows that dialog.
  See [permissions.md › Project allow rules and workspace trust](permissions.md).
- `permissions.defaultMode` set to `auto` or `bypassPermissions` doesn't take effect from a project or local
  settings file: `auto` falls back to the built-in default, not your user `defaultMode`, and `bypassPermissions` starts
  in Manual mode.
  See [modes.md › Which mode a session starts in](modes.md).
- A Bash rule matches the command as Claude writes it, so `Bash(curl *)` doesn't match `/usr/bin/curl` or
  `sh -c 'curl …'`.
  See [permissions.md › Bash rules](permissions.md).
- A `.claudeignore` file has no effect: block files with `Read` deny rules, which still don't cover subprocesses or
  commands that read files without naming them.
  See [permissions.md › Read and Edit rules](permissions.md).
- Path rules for `Write`, `NotebookEdit` and `Glob` are accepted but never match; file access is checked against
  `Edit(path)` and `Read(path)` rules only.
  See [permissions.md › Read and Edit rules](permissions.md).
- A `/path` rule anchors at a directory tied to the settings file that defines it: in user settings,
  `Read(/secrets/**)` blocks `~/.claude/secrets/**`, not a directory in your project.
  See [permissions.md › Read and Edit rules](permissions.md).
- In `sandbox.filesystem` paths, `/path` is absolute, unlike in `Read` and `Edit` rules; write `./path` for a
  project-relative path in project settings.
  See [sandbox.md › Sandbox path prefixes](sandbox.md).
- Project and local settings can't set some variables in their `env` block: Claude Code drops each one, apart from
  a few values that turn telemetry off, and logs a warning you can see with `claude --debug`.
  See [configuring.md › The env key](configuring.md).
- Usage metrics and error reports are turned off with environment variables such as `DISABLE_TELEMETRY`, set in `env`
  or the shell, not with a settings key; only `feedbackDrafts` and `feedbackSurveyRate` turn something off as keys.
  See [configuring.md › The env key](configuring.md).

## Topics

- [placing.md](placing.md): knowing the settings files, which sources load and how they combine (user, project, local
  and managed scopes, finding and creating the files, sharing with a team, keeping personal settings out of a repository
  and where git and worktrees keep the local file, `--setting-sources` and `--restricted`, precedence, list merging and
  the exceptions to managed precedence, additional directories and the settings they do or don't load, global config
  `~/.claude.json` versus settings files)
  - Settings files and their scopes
  - Finding, creating and sharing the files
  - The local file in a git repository
  - Choosing which sources load
  - Precedence
  - Lists merge instead of overriding
  - Precedence examples
  - Exceptions to managed settings precedence
  - Additional directories and worktrees
  - The global config file
  - Not stated by the documentation

- [configuring.md](configuring.md): writing and changing settings (file format, `/config`, editing a file, per-session
  flags such as `--settings`, the `env` key and how it meets the shell and env-var precedence, when edits take effect,
  example settings files)
  - Ways to change a setting
  - The /config menu
  - Editing a settings file
  - Changing a setting for one session
  - When edits take effect
  - The env key
  - Environment variables and settings precedence
  - Resuming a session
  - Example settings files

- [keys.md](keys.md): looking up a key (the settings index with each key's scope, and where a feature key's scope is
  narrower than the index shows)
  - Settings index
  - Managed-only keys with a narrower source
  - User or managed keys
  - Any-file keys with a narrower source

- [permissions.md](permissions.md): writing permission rules (the permission system, `permissions` and
  `allow`/`ask`/`deny`, rule syntax and wildcards, tool-specific rules for Bash, PowerShell, Read and Edit, WebFetch,
  MCP and Cd, working directories and `additionalDirectories`, `blockReadsOutsideWorkingDirectories`, project allow
  rules and workspace trust, managed-only permission rules, how permission rules meet the sandbox)
  - How prompts, saved rules and rule order work
  - The `permissions` key and its arrays
  - Rule syntax and wildcards
  - Bash rules
  - PowerShell rules
  - Read and Edit rules
  - Symlinks
  - Network paths
  - WebFetch rules
  - MCP rules
  - Cd rules
  - Rules for other tools
  - Working directories
  - Moving the session with `/cd`
  - Project allow rules and workspace trust
  - Managed-only permission rules
  - How permissions meet the sandbox
  - Blocking reads outside the working directories
  - Command-line flags

- [modes.md](modes.md): choosing and setting a permission mode (the modes, `defaultMode`, which mode a session starts
  in, switching, acceptEdits, plan, dontAsk, bypassPermissions and the keys that disable it or skip its prompts,
  protected paths, critical paths and their prompts)
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

- [auto-mode.md](auto-mode.md): configuring auto mode (the classifier and its model, what it blocks by default,
  `autoMode` and its environment, block and allow entries, `/auto-mode-setup`, `classifyAllShell`, `disableAutoMode`,
  `useAutoModeDuringPlan`, fallback, reviewing and fixing denials)
  - Availability and the classifier
  - Disabling auto mode
  - Server-side classifier review
  - The classifier model
  - What the classifier blocks and allows by default
  - Boundaries and approvals stated in conversation
  - When auto mode falls back
  - How actions are evaluated
  - Where the classifier reads `autoMode`
  - Human checkpoints with ask and deny rules
  - Define trusted infrastructure
  - Generate environment entries with `/auto-mode-setup`
  - Override the block and allow rules
  - Related settings keys
  - The `claude auto-mode` subcommands
  - Review and fix denials

- [sandbox.md](sandbox.md): configuring the sandbox (what it restricts and what runs outside it, enabling and platform
  setup, sandbox modes and the unsandboxed retry, filesystem and network settings and path prefixes, excluded commands,
  protected paths, how the sandbox meets permission rules and modes, organisation enforcement and locks, proxies,
  limitations)
  - What the sandbox covers
  - Turning it on
  - Linux and WSL2 setup
  - Sandbox modes
  - The unsandboxed retry and strict sandbox mode
  - Temporary directories
  - Filesystem settings
  - Sandbox path prefixes
  - Filesystem isolation and protected paths
  - Disabling filesystem isolation
  - Excluded commands
  - Network isolation
  - Network settings
  - Proxies
  - Permission rules and permission modes
  - Enforcing the sandbox for an organisation
  - Repository settings under an admin-required sandbox
  - Settings for special environments
  - Security limitations and scope

- [credentials.md](credentials.md): protecting credentials from sandboxed commands (`sandbox.credentials`, masking
  environment variables and files, AWS re-signing, plaintext injection)
  - Declaring credentials
  - Scope and trust
  - Masking requirements
  - Environment variables
  - Credential files
  - AWS re-signing
  - Plaintext injection
  - Invalid entries in managed settings

- [managed.md](managed.md): delivering organisation-managed settings (managed files and delivery mechanisms,
  server-managed settings, how managed sources combine, keys only a managed source can set, `policyHelper`,
  `managedSourcesBehavior`, `parentSettingsBehavior`, approval dialogs, fail-closed startup, checking a policy is in
  force, enterprise keys)
  - Deploy a managed settings file
  - Choose a delivery mechanism
  - Where and when a policy applies
  - Where each mechanism stores the policy
  - Split a file-based policy across teams
  - How managed sources combine
  - Keys read from every admin source
  - Login keys
  - Compose every managed source
  - Compute the policy with a helper program
  - Parent settings from an embedding host
  - WSL and the Windows policy chain
  - Keys only a managed source can set
  - Pin endpoints for `allowedProviders`
  - Block sideloading
  - Server-managed settings
  - Fetch and caching
  - Fail-closed startup
  - Security approval dialogs
  - Platform availability
  - Check that a policy is in force
  - What a developer can change
  - Security considerations
  - Dev containers

- [troubleshooting.md](troubleshooting.md): checking why a setting doesn't apply (confirming what loaded and resolved
  settings, broken files and size limits, ignored values, lost changes, invalid or dropped entries, settings, permission
  and managed error messages, sandbox failures and their fixes)
  - Confirm what loaded
  - Settings file errors and warnings
  - A value you set is ignored
  - A change is lost or doesn't reach others
  - Permission rule warnings and errors
  - Managed settings: dropped entries and errors
  - Auto mode denials
  - Sandbox failures
  - Sandbox refusals, locks and leftover files

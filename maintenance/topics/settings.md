# Settings topics

- `placing.md`: knowing the settings files, which sources load and how they combine (user, project, local and
  managed scopes, finding and creating the files, sharing with a team, keeping personal settings out of a repository
  and where git and worktrees keep the local file, `--setting-sources` and `--restricted`, precedence, list merging
  and the exceptions to managed precedence, additional directories and the settings they do or don't load, global
  config `~/.claude.json` versus settings files)
- `configuring.md`: writing and changing settings (file format, `/config`, editing a file, per-session flags such as
  `--settings`, the `env` key and how it meets the shell and env-var precedence, when edits take effect, example
  settings files)
- `keys.md`: looking up a key (the settings index with each key's scope, and where a feature key's scope is narrower
  than the index shows)
- `permissions.md`: writing permission rules (the permission system, `permissions` and `allow`/`ask`/`deny`, rule
  syntax and wildcards, tool-specific rules for Bash, PowerShell, Read and Edit, WebFetch, MCP and Cd,
  working directories and `additionalDirectories`, `blockReadsOutsideWorkingDirectories`, project allow rules and
  workspace trust, managed-only permission rules, how permission rules meet the sandbox)
- `modes.md`: choosing and setting a permission mode (the modes, `defaultMode`, which mode a session starts in,
  switching, acceptEdits, plan, dontAsk, bypassPermissions and the keys that disable it or skip its prompts,
  protected paths, critical paths and their prompts)
- `auto-mode.md`: configuring auto mode (the classifier and its model, what it blocks by default, `autoMode` and its
  environment, block and allow entries, `/auto-mode-setup`, `classifyAllShell`, `disableAutoMode`,
  `useAutoModeDuringPlan`, fallback, reviewing and fixing denials)
- `sandbox.md`: configuring the sandbox (what it restricts and what runs outside it, enabling and platform setup,
  sandbox modes and the unsandboxed retry, filesystem and network settings and path prefixes, excluded commands,
  protected paths, how the sandbox meets permission rules and modes, organisation enforcement and locks, proxies,
  limitations)
- `credentials.md`: protecting credentials from sandboxed commands (`sandbox.credentials`, masking environment
  variables and files, AWS re-signing, plaintext injection)
- `managed.md`: delivering organisation-managed settings (managed files and delivery mechanisms, server-managed
  settings, how managed sources combine, keys only a managed source can set, `policyHelper`,
  `managedSourcesBehavior`, `parentSettingsBehavior`, approval dialogs, fail-closed startup, checking a policy is in
  force, enterprise keys)
- `troubleshooting.md`: checking why a setting doesn't apply (confirming what loaded and resolved settings, broken
  files and size limits, ignored values, lost changes, invalid or dropped entries, settings, permission and managed
  error messages, sandbox failures and their fixes)

Settings are split between types: settings owns the settings files, permission rules, permission modes, auto mode,
the sandbox, the `env` key and managed delivery; a key whose subject is another feature belongs to that feature's
type, and `keys.md` keeps only its index row and any Scope line narrower than the index shows. Hooks keeps the hook
clauses of permission and mode sections (`hooks/tool-events.md`), skills keeps `allowed-tools` and the skills clauses,
subagents keeps the subagent clauses, and instructions keeps which instruction files load.

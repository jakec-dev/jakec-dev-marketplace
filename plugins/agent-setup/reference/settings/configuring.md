# Configuring settings

Writing and changing settings: the `/config` menu, editing a file, per-session values, the `env` key, when edits take
effect and example files.

## Contents

- Ways to change a setting
- The /config menu
- Editing a settings file
- Changing a setting for one session
- When edits take effect
- The env key
- Environment variables and settings precedence
- Resuming a session
- Example settings files

## Ways to change a setting

- You can change a setting from the `/config` menu, by editing a settings file, or for one session from the command
  line. [settings › Change a setting](https://code.claude.com/docs/en/settings#change-a-setting)

## The /config menu

- Run `/config` inside Claude Code and open the **Config** tab. It lists a short set of personal options such as
  theme, editor mode, and verbose output, not every settings key. Select an option to change it and Claude Code saves
  it for you: most options to `~/.claude/settings.json`, a few options such as Show tips to
  `.claude/settings.local.json`.
  [settings › Use the /config menu](https://code.claude.com/docs/en/settings#use-the-/config-menu)
- To set one option without the menu, pass `key=value`, such as `/config verbose=true`. The form also works in
  non-interactive mode (`-p`). It can't turn on a setting that needs your confirmation in the panel, such as
  `autoContinueAtUsageLimit`, though it can turn one off. `/config --help` lists the keys it accepts. `/settings` is
  an alias of `/config`.
  [settings › Use the /config menu](https://code.claude.com/docs/en/settings#use-the-/config-menu),
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- `/config` is part of the terminal interface. The VS Code chat panel and the desktop app don't open it; change
  settings there by editing a settings file or through those apps' own settings.
  [settings › Use the /config menu](https://code.claude.com/docs/en/settings#use-the-/config-menu)

- A few keys have a `/config` row that Claude Code hides while managed settings or the `--settings` flag set the key:
  `idleCompaction`, `askUserQuestionTimeout`, `autoContinueAtUsageLimit`, and `dialogExpiry`. For `idleCompaction`, a
  missing **Idle compaction** row has two causes: a value in managed settings, the `--settings` flag, or a project or
  local settings file overrides your user settings, so change the key in that source; or Claude Code can't fetch
  feature flags, so idle compaction doesn't run and there is nothing to turn off.
  [settings-reference › `idleCompaction`](https://code.claude.com/docs/en/settings-reference#idlecompaction),
  [settings-reference › `askUserQuestionTimeout`](https://code.claude.com/docs/en/settings-reference#askuserquestiontimeout),
  [settings-reference › `autoContinueAtUsageLimit`](https://code.claude.com/docs/en/settings-reference#autocontinueatusagelimit),
  [settings-reference › `dialogExpiry`](https://code.claude.com/docs/en/settings-reference#dialogexpiry)

## Editing a settings file

- Open the settings file for the scope you want and add or change a key. Settings files are strict JSON: a `//`
  comment or a trailing comma is a syntax error, and Claude Code reports the file as a Settings Error at the next
  start. [settings › Edit a settings file](https://code.claude.com/docs/en/settings#edit-a-settings-file)
- This example in `~/.claude/settings.json` lets Claude Code run lint and test commands without asking and stops it
  reading `.env` files.
  [settings › Edit a settings file](https://code.claude.com/docs/en/settings#edit-a-settings-file)

  ```json
  {
    "$schema": "https://json.schemastore.org/claude-code-settings.json",
    "permissions": {
      "allow": [
        "Bash(npm run lint)",
        "Bash(npm run test *)"
      ],
      "deny": [
        "Read(./.env)",
        "Read(./.env.*)"
      ]
    }
  }
  ```

- The `$schema` line points to the published JSON schema for Claude Code settings, which gives autocomplete and inline
  validation in VS Code, Cursor, and any other editor that supports JSON schema. The schema can lag behind the newest
  CLI releases, so a validation warning on a recently documented key doesn't mean the configuration is invalid.
  [settings › Edit a settings file](https://code.claude.com/docs/en/settings#edit-a-settings-file)
- After you save, run `/status` inside Claude Code to confirm the file loaded.
  [settings › Edit a settings file](https://code.claude.com/docs/en/settings#edit-a-settings-file)

## Changing a setting for one session

- To try a value without saving it, set it when you start Claude Code: the value applies to that session and your
  settings files stay as they were.
  [settings › Change a setting for one session](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)
- Three ways to do it:
  - `--settings`: pass a key as JSON, inline or as a path to a file. It can set any key your user settings file can
    set; it can't set `Managed` or `Global config` keys.
  - A flag for that key: some keys have their own flag, such as `--model` for `model` and `--effort` for
    `effortLevel` and `modelSettings`.
  - An environment variable: export the key's paired variable before you run `claude`, such as `ANTHROPIC_MODEL` for
    `model`.

  [settings › Change a setting for one session](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)
- Pressing `s` in the `/model` picker switches the model without saving it as your user default, whereas `/model`
  otherwise saves the value as your default for new sessions.
  [settings › Change a setting for one session](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)
- Each key's entry on the settings reference lists its per-session overrides and which one takes precedence.
  [settings › Change a setting for one session](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)
- To start one session on Opus without changing your default:
  [settings › Change a setting for one session](https://code.claude.com/docs/en/settings#change-a-setting-for-one-session)

  ```bash
  claude --settings '{"model": "claude-opus-5-5"}'
  ```

## When edits take effect

- Claude Code watches your settings files and reloads them when they change, so it applies most edits to the running
  session without a restart, after a brief file-stability delay, including edits to `permissions` and credential
  helpers such as `apiKeyHelper`. The reload covers user, project, local, and managed settings. Managed settings from
  MDM or the claude.ai console reach a running session on a schedule rather than on save.
  [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect),
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- Claude Code also loads a settings file you create mid-session if its folder existed when the session started. For
  the project's `.claude/` folder, it loads the file even when you create the folder in the same session.
  [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect)
- Claude Code reads some keys only once, at session start, so an edit to one of them doesn't reach the running
  session. Admin-side keys that also wait for a restart, such as `requiredMinimumVersion`, are listed under
  [where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies).
  The ones you're most likely to edit mid-session are `model` (use `/model` to switch mid-session) and `effortLevel`
  and `modelSettings` (use `/effort` to change effort mid-session).
  [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect)

## The env key

- `env` sets environment variables for every session and for the subprocesses Claude Code starts from it. Most
  variables in the environment variables reference can go here, which is how you apply one to every session or roll it
  out to your team. Its scope is any file; its type is an object mapping variable names to string values; it is unset
  by default.
  [settings-reference › `env`](https://code.claude.com/docs/en/settings-reference#env)

  ```json
  {
    "env": {
      "DISABLE_AUTO_COMPACT": "1",
      "ANTHROPIC_BASE_URL": "https://proxy.example.com"
    }
  }
  ```

- Add variables under the `env` key in a `settings.json` file, creating the file if it doesn't exist. Claude Code
  reads them directly from the file, so they take effect no matter how `claude` was launched. A variable you set in
  your shell lasts for that terminal session, while a variable in a settings file applies every time `claude` runs.
  [env-vars › Set environment variables](https://code.claude.com/docs/en/env-vars#set-environment-variables),
  [env-vars › Set variables in settings files](https://code.claude.com/docs/en/env-vars#set-variables-in-settings-files)
- Claude Code copies `env` values into its environment as written. No shell processes them, so shorthand such as `~`
  or `$HOME` stays as typed. For a variable that takes a path, such as `CLAUDE_CONFIG_DIR`, write the absolute path:
  `"CLAUDE_CONFIG_DIR": "/home/you/.claude-work"`.
  [env-vars › Set variables in settings files](https://code.claude.com/docs/en/env-vars#set-variables-in-settings-files)
- A feature that reads its variables once at startup, such as OpenTelemetry monitoring, keeps its startup values
  until you relaunch.
  Removing a variable from the file doesn't unset it in a running session; the removal takes effect the next time you
  launch `claude`.
  [env-vars › Set variables in settings files](https://code.claude.com/docs/en/env-vars#set-variables-in-settings-files)
- `env` values are applied at these times:
  - From user settings, `--settings`, and managed settings: at startup, and again in the running session when a saved
    change alters the merged `env`. A server-managed change to an `env` variable that needs approval waits for the
    developer to accept the security approval dialog in an interactive session
    ([managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)).
  - From project and local settings: after you trust the workspace, or at startup in `-p` mode, which never shows the
    trust dialog, and again when a saved change alters the merged `env`.
  - Variables Claude Code classifies as safe, such as model selection, timeouts and limits, and feature toggles: at
    startup from every settings file, apart from the variables project and local settings can't set.
  - After you move the session with `/cd`: the new directory's project and local `env` values, on top of the previous
    directory's.

  [settings-reference › When Claude Code applies `env` values](https://code.claude.com/docs/en/settings-reference#when-claude-code-applies-env-values)
- Values in `env` are plain text in the settings file and reach the subprocesses Claude Code starts, except that
  Claude Code doesn't pass `OTEL_*` variables to the subprocesses it spawns, such as the Bash tool, MCP servers, or
  language servers. For an OTLP bearer token that rotates, use `otelHeadersHelper`; for API credentials, use
  `apiKeyHelper`.
  [settings-reference › How `env` values interact with your shell](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell),
  [monitoring-usage › Administrator configuration](https://code.claude.com/docs/en/monitoring-usage#administrator-configuration)
- `NO_COLOR` and `FORCE_COLOR` set in `env` reach only subprocesses. To change Claude Code's own interface colors, set
  them in your shell before launching `claude`.
  [settings-reference › How `env` values interact with your shell](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell)
- Background agents run under a per-user supervisor process that inherits the environment of whichever shell starts it
  first. A proxy, CA path, or mTLS variable exported only in your shell reaches them when that shell cold-started the
  supervisor, and silently doesn't when a different shell did. Settings are the only configuration that reaches every
  background session: put those variables in the `env` block of `~/.claude/settings.json` or managed settings.
  [network-config › Set network variables in settings, not the shell](https://code.claude.com/docs/en/network-config#set-network-variables-in-settings-not-the-shell)
- A split-pane agent team teammate gets a fixed set of environment variables that doesn't include
  `CLAUDE_CODE_ENABLE_TODO_TOOLS` exported in your shell. To set it for the teammate too, start the lead session with
  `claude --settings '{"env":{"CLAUDE_CODE_ENABLE_TODO_TOOLS":"1"}}'`.
  [tools-reference › Task-tracking tools in subagents and agent teams](https://code.claude.com/docs/en/tools-reference#task-tracking-tools-in-subagents-and-agent-teams)
- The switches that turn off usage metrics and error reports are environment variables, not settings keys:
  `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. Set them in `env` or
  in your shell. Two settings keys turn something off from a settings file: `feedbackDrafts` and
  `feedbackSurveyRate`.
  [settings-reference › Privacy and telemetry](https://code.claude.com/docs/en/settings-reference#privacy-and-telemetry)

### Variables Claude Code ignores in `env`

- Project and local settings can't set variables that a checked-out repository shouldn't control; set those in your
  shell, user settings, or managed settings instead. Claude Code drops each one, apart from a few values that turn
  telemetry off, and logs a warning you can see with `claude --debug`.
  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)
- The variables project and local settings can't set include:
  - Variables that choose where Claude Code stores or writes its own files: `CLAUDE_CONFIG_DIR`,
    `CLAUDE_CODE_TMPDIR`, and the operating-system directory variables such as `HOME`, `TMPDIR`, `TMP`, `TEMP`, and
    the `XDG_*` family.
  - Windows variables that pick the programs and machine-wide configuration for the processes Claude Code starts,
    such as `SystemRoot`, `ComSpec`, `ProgramData`, `LOCALAPPDATA`, `PATHEXT`, `PSModulePath`, and the `ProgramFiles`
    family.
  - Variables that export session content: `OTEL_LOG_RAW_API_BODIES` and the detailed beta tracing pair
    `ENABLE_BETA_TRACING_DETAILED` and `BETA_TRACING_ENDPOINT`.
  - The OpenTelemetry exporter variables that turn telemetry on, choose where it goes, or choose what content it
    captures:
    - `CLAUDE_CODE_ENABLE_TELEMETRY`, plus the enhanced telemetry beta pair `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA` and
      `ENABLE_ENHANCED_TELEMETRY_BETA`
    - The exporter selectors `OTEL_LOGS_EXPORTER`, `OTEL_METRICS_EXPORTER`, and `OTEL_TRACES_EXPORTER`
    - The content variables `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_ASSISTANT_RESPONSES`, `OTEL_LOG_TOOL_CONTENT`, and
      `OTEL_LOG_TOOL_DETAILS`
    - `OTEL_EXPORTER_OTLP_*` variables whose names end in `_ENDPOINT`, `_HEADERS`, `_PROTOCOL`, `_CERTIFICATE`,
      `_CLIENT_KEY`, or `_INSECURE`, in the generic and per-signal forms, such as `OTEL_EXPORTER_OTLP_ENDPOINT` and
      `OTEL_EXPORTER_OTLP_METRICS_HEADERS`
    - `OTEL_EXPORTER_PROMETHEUS_HOST` and `OTEL_EXPORTER_PROMETHEUS_PORT`
  - Variables that change how Claude Code starts or syncs, such as `CLAUDE_CODE_PROCESS_WRAPPER`,
    `CLAUDE_CODE_SYNC_SKILLS`, `CLAUDE_CODE_SYNC_PLUGINS`, `CLAUDE_CODE_PLUGIN_CACHE_DIR`, and
    `CLAUDE_CODE_PLUGIN_SEED_DIR`.
  - The screen reader mode variable `CLAUDE_AX_SCREEN_READER` and the other variables whose names start with
    `CLAUDE_AX_`, such as `CLAUDE_AX_STARTUP_QUIET_MS`.
  - `CLAUDE_CODE_USER_DIALOG_TIMEOUT_MS`, which sets the timer on an unanswered dialog.
  - `CLAUDE_CODE_DISABLE_ATTACHMENTS`, which turns off attachment processing.
  - `CLAUDE_CODE_DISABLE_FILE_MENTIONS`, which stops Claude Code from expanding `@` mentions of files and
    directories.

  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)
- Only these OpenTelemetry values still apply from project and local settings, because they turn something off:
  `none` for the three exporter selectors, and an off value such as `0` for `OTEL_LOG_USER_PROMPTS`,
  `OTEL_LOG_TOOL_CONTENT`, and `OTEL_LOG_TOOL_DETAILS`. Such a value overrides the same variable in your user
  settings, but not one that the environment you start Claude Code from, a `--settings` file, or managed settings
  sets.
  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)
- Set `CLAUDE_CODE_PROCESS_WRAPPER` in the `env` block of user or managed settings, not as a shell export, so the
  detached background service inherits it.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `OTEL_LOG_MANAGED_SETTINGS=1` adds the redacted managed settings to `managed_settings_resolved` log events. Set it
  in your shell, user settings, `--settings`, or managed settings; a value in project or local settings doesn't turn it
  on, because a cloned repository can write them.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables),
  [monitoring-usage › Managed settings resolved event](https://code.claude.com/docs/en/monitoring-usage#managed-settings-resolved-event)
- These variables are ignored from every file, not only project and local settings:
  - Identity variables that Claude Code's hosting environments own, such as `CLAUDE_CODE_REMOTE` and
    `CLAUDE_CODE_ACCOUNT_UUID`.
  - `CLAUDE_CODE_MESSAGING_SOCKET` and `CLAUDE_CODE_MESSAGING_TOKEN`, which Claude Code exports itself.
  - `CLAUDE_CODE_PROJECT_DIR_NAME`, which Claude Code reads from the launch environment only.
  - Each of these, which Claude Code reads from the launch environment only: `CLAUDE_CODE_RESTRICTED`,
    `CLAUDE_CODE_DISABLE_POWERSHELL_CMD_RM_DENY`, `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT`,
    `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT`, `CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT`,
    `CLAUDE_CODE_DISABLE_MOUNTED_DRIVE_RM_PROMPT`, `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS`,
    `CLAUDE_CODE_WARN_DISK_FREE_GIB` and `CLAUDE_CODE_WARN_MEMORY_FREE_GIB`.

  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)

## Environment variables and settings precedence

- Environment variables aren't a level in the settings precedence stack. When a behavior has both a shell variable and
  a settings key, which one applies is decided per pair, not by level: `ANTHROPIC_MODEL` exported in your shell
  applies over the `model` key from any file, while `ANTHROPIC_DEFAULT_MODEL` applies only when no file sets `model`.
  An `env` block inside a settings file is an ordinary key and follows the levels.
  [settings › Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence)
- `CLAUDE_CODE_AUTO_CONNECT_IDE` likewise applies over the `autoConnectIde` setting, which Claude Code uses only when
  the variable is unset. For the pair you're setting, check the variable's row in the environment variables reference
  and the key's entry on the settings reference.
  [env-vars › Precedence](https://code.claude.com/docs/en/env-vars#precedence)
- A value in `env` overwrites the same variable exported in your shell, and when more than one settings file sets a
  variable, the highest-precedence one applies. The exceptions are the variables project and local settings can't set,
  and sessions started by the Claude Desktop app or a self-hosted environment runner: there the launch environment it
  builds takes precedence, and Claude Code ignores an `env` value from any settings file for a variable the launch
  environment already sets. The debug log names each ignored variable.
  [settings-reference › How `env` values interact with your shell](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell)
- To cancel a shell export, set the variable to `""`. Claude Code treats an empty value as unset for provider
  selection, and subprocesses inherit the empty value. A settings file can set a variable but can't remove one, so to
  override a variable you can't unset, such as a stale `CLAUDE_CODE_USE_VERTEX` exported by a shell profile you don't
  control, set it to an empty string in the `env` block: `"CLAUDE_CODE_USE_VERTEX": ""`.
  [settings-reference › How `env` values interact with your shell](https://code.claude.com/docs/en/settings-reference#how-env-values-interact-with-your-shell),
  [env-vars › Precedence](https://code.claude.com/docs/en/env-vars#precedence)
- How an environment variable interacts with CLI flags and in-session commands varies per feature: `--model` and
  `/model` override `ANTHROPIC_MODEL`, while `CLAUDE_CODE_EFFORT_LEVEL` overrides `--effort` and `/effort`. Where a
  variable interacts with another configuration source, its row in the Variables list states the precedence or links
  to the page that documents it.
  [env-vars › Precedence](https://code.claude.com/docs/en/env-vars#precedence)
- Claude Code reads shell environment variables at startup, so changes to them take effect the next time you launch
  `claude`.
  [env-vars › Precedence](https://code.claude.com/docs/en/env-vars#precedence)

## Resuming a session

- Not every configuration flag from the original launch is restored on resume. If the session depended on
  `--mcp-config`, `--settings`, `--plugin-dir`, `--fallback-model`, or directories added with `--add-dir`, pass them
  again when you resume. Directories added mid-session with `/add-dir` aren't restored either.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)
- The standard settings files, such as `settings.json` and `settings.local.json`, are re-read at launch, so
  configuration that lives in them doesn't need to be passed again.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)

## Example settings files

- The documentation holds three example `settings.json` files: a developer's `~/.claude/settings.json`, a team's
  `.claude/settings.json` committed to the repository, and an organization's `managed-settings.json`. None is a
  recommended baseline. Every value comes from the key's entry on the settings reference, which has its type, default,
  and where it can be set. Each example has a copyable file and a version with a comment above each key; Claude Code
  doesn't accept comments in a settings file, so copy the file without comments.
  [settings-example › Example settings files](https://code.claude.com/docs/en/settings-example)

### A developer's own settings

- One developer's personal settings, for `~/.claude/settings.json`, where they apply to every project you open. It
  picks a model and effort, adjusts the terminal, and pre-approves a read-only command and one file read. Everything
  not listed keeps its default.
  [settings-example › Your own settings](https://code.claude.com/docs/en/settings-example#your-own-settings)

  ```json
  {
    "model": "claude-sonnet-5",
    "modelSettings": {
      "claude-sonnet-5": { "effortLevel": "xhigh" }
    },
    "editorMode": "vim",
    "theme": "light-daltonized",
    "statusLine": {
      "type": "command",
      "command": "jq -r '\"[\\(.model.display_name)] \\(.context_window.used_percentage // 0)% context\"'",
      "padding": 2
    },
    "spinnerTipsEnabled": false,
    "preferredNotifChannel": "terminal_bell",
    "permissions": {
      "allow": [
        "Bash(git diff *)",
        "Read(~/.zshrc)"
      ]
    },
    "autoUpdatesChannel": "stable",
    "cleanupPeriodDays": 20
  }
  ```

### A team's shared settings

- One team's shared settings, committed to the repository so everyone who clones it gets the same permissions, hooks,
  and plugin marketplace. Save a file like this at `.claude/settings.json` at the top of the repository. In
  `enabledPlugins`, a plugin from an external source such as a GitHub repository still needs each person to install it
  once. `plansDirectory` keeps plan files inside the repo. The example's hook runs `.claude/hooks/block-rm.sh`, a
  script you write in the repository.
  [settings-example › A team's shared settings](https://code.claude.com/docs/en/settings-example#a-teams-shared-settings)

  ```json
  {
    "permissions": {
      "allow": [
        "Bash(npm run *)"
      ],
      "ask": [
        "Bash(git push *)"
      ],
      "deny": [
        "Read(./.env)",
        "Read(./.env.*)",
        "Read(./secrets/**)"
      ]
    },
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/block-rm.sh"
            }
          ]
        }
      ]
    },
    "extraKnownMarketplaces": {
      "acme-tools": {
        "source": {
          "source": "github",
          "repo": "acme-corp/claude-plugins"
        }
      }
    },
    "enabledPlugins": {
      "code-formatter@acme-tools": true
    },
    "sandbox": {
      "enabled": true,
      "filesystem": {
        "allowWrite": [
          "/tmp/build"
        ]
      },
      "network": {
        "allowedDomains": [
          "registry.npmjs.org",
          "*.example.com"
        ]
      }
    },
    "plansDirectory": "./plans"
  }
  ```

### An organization's managed settings

- A `managed-settings.json` file that shows the shape of the managed keys, with one plausible value for each. It isn't
  a recommended policy: pick the keys that match your own requirements and set your own values. Replace the example
  organization UUID, server URL, and marketplace with your own and delete the keys you don't want. It sets:
  - `forceLoginMethod` and `forceLoginOrgUUID` pin the login method and organization.
  - `availableModels` and `enforceAvailableModels` restrict which models sessions can use.
  - `permissions.deny` denies two file reads and `curl` commands as Claude writes them, and
    `disableBypassPermissionsMode` removes the bypass permission mode.
  - `allowManagedPermissionRulesOnly` and `allowManagedMcpServersOnly` make the managed permission and MCP allowlists
    the only ones that apply.
  - `allowedMcpServers` pins the MCP server by URL.
  - `strictKnownMarketplaces` allows one plugin marketplace.
  - `sandbox` sandboxes commands with a fixed network allowlist and no unsandboxed retry. Its `failIfUnavailable` key
    [stops Claude Code from starting where the sandbox can't run](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings).
  - `requiredMinimumVersion` sets a minimum Claude Code version.
  - `cleanupPeriodDays` shortens retention of session transcripts and other local data to seven days.
  - `companyAnnouncements` shows a message at startup.

  [settings-example › An organization's managed settings](https://code.claude.com/docs/en/settings-example#an-organizations-managed-settings)

  ```json
  {
    "forceLoginMethod": "claudeai",
    "forceLoginOrgUUID": [
      "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    ],
    "availableModels": [
      "opus",
      "sonnet"
    ],
    "enforceAvailableModels": true,
    "permissions": {
      "deny": [
        "Bash(curl *)",
        "Read(./.env)",
        "Read(./secrets/**)"
      ],
      "disableBypassPermissionsMode": "disable"
    },
    "allowManagedPermissionRulesOnly": true,
    "allowedMcpServers": [
      {
        "serverUrl": "https://api.githubcopilot.com/*"
      }
    ],
    "allowManagedMcpServersOnly": true,
    "strictKnownMarketplaces": [
      {
        "source": "github",
        "repo": "acme-corp/approved-plugins"
      }
    ],
    "sandbox": {
      "enabled": true,
      "failIfUnavailable": true,
      "allowUnsandboxedCommands": false,
      "network": {
        "allowedDomains": [
          "registry.npmjs.org",
          "github.com"
        ],
        "allowManagedDomainsOnly": true
      }
    },
    "requiredMinimumVersion": "2.1.150",
    "cleanupPeriodDays": 7,
    "companyAnnouncements": [
      "Welcome to Acme Corp! Review our code guidelines at docs.example.com"
    ]
  }
  ```

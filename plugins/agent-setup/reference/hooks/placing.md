# Placing hooks

Deciding where a hook is defined and what it applies to.

## Contents

- Settings locations and merging
- Managed and server-managed delivery
- Plugin hooks
- Plugin manifest and marketplace entry hooks
- Plugin paths, data and updates
- Skill and subagent frontmatter
- Path placeholders, worktrees and `/cd`
- When edits take effect
- Not stated by the documentation

## Settings locations and merging

- Where you define a hook determines its scope:
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations)

  | Location | Scope | Shareable |
  | :- | :- | :- |
  | `~/.claude/settings.json` | All your projects | No, local to your machine |
  | `.claude/settings.json` | Single project | Yes, can be committed to the repo |
  | `.claude/settings.local.json` | Single project | No, gitignored when Claude Code saves a setting to it |
  | Managed policy settings | Organization-wide | Yes, admin-controlled |
  | [Plugin](https://code.claude.com/docs/en/plugins/overview) `hooks/hooks.json` | When plugin is enabled | Yes, bundled with the plugin |
  | [Skill](https://code.claude.com/docs/en/skills) frontmatter | The rest of the session once the skill is invoked | Yes, defined in the skill file |
  | [Subagent](https://code.claude.com/docs/en/sub-agents) frontmatter | While that subagent is running | Yes, defined in the subagent file |

- Hook entries merge across settings levels rather than replacing each other: user, project, and local settings add
  their own hooks without removing managed ones (`disableAllHooks` set outside managed settings can't disable
  them). In the `hooks` setting, hooks from managed settings can't be removed from other files.
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations),
  [settings-reference › `hooks`](https://code.claude.com/docs/en/settings-reference#hooks)
- Cloud sessions don't read your local `~/.claude/settings.json`. In a self-hosted environment, Claude Code also runs
  the hooks the operator seeded from the runner host's `~/.claude/`, and it runs the hooks in the runner image's
  managed settings file when that file is among the managed sources Claude Code applies, which by default means only
  when neither server-managed settings nor an MDM-delivered Claude Code policy supplies the managed tier.
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations)
- Hooks from settings files, managed policy settings, and plugins also run inside subagents. When a subagent calls a
  tool, tool events such as `PreToolUse` and `PostToolUse` fire the same configured hooks as in the main
  conversation, and the input carries the `agent_id` and `agent_type` common input fields that identify the
  subagent. `SubagentStart` and `SubagentStop` fire when a subagent starts or finishes.
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations),
  [sub-agents › Define hooks for subagents](https://code.claude.com/docs/en/sub-agents#define-hooks-for-subagents)
- Hooks and other `.claude/settings.json` keys load from the current working directory's `.claude/` folder with no
  parent-directory fallback, alongside your user `~/.claude/settings.json` and managed settings. Directories added
  with `--add-dir` or `/add-dir` load only the `enabledPlugins` and `extraKnownMarketplaces` keys from their
  `.claude/settings.json` and `.claude/settings.local.json`, so their hooks don't load, and directories listed in
  `permissions.additionalDirectories` grant file access only and load no configuration.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- In a large repository with `worktree.sparsePaths` set, project settings inside the worktree load from the
  worktree root's `.claude/settings.json`, the checked-out copy of the repository root's file. Put settings you need
  inside worktrees, such as permission rules or hooks, in the repository root's `.claude/settings.json`. Root-level
  directories aren't checked out, so include `.claude` in `worktree.sparsePaths` if you want the repository root's
  `.claude/settings.json` available inside the worktree.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)
- The `/update-config [request]` command is a skill: describe a settings change, such as adding a hook, and Claude
  edits the matching `settings.json` file.
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- Hooks work on every provider.
  [feature-availability › Features available on every provider](https://code.claude.com/docs/en/feature-availability#features-available-on-every-provider)
- Claude Code fires the same hook events wherever it runs: sessions in the terminal, IDE extensions, the Desktop app
  and cloud sessions. A plugin can also register hooks as JavaScript functions that Claude Code calls in its own
  process; a plugin that does is a mod, and the settings hooks the hooks reference covers keep working alongside
  mods.
  [hooks › Hooks reference](https://code.claude.com/docs/en/hooks)
- Claude Code's existing hooks also run on events, for example as a shell command, HTTP request, or prompt you
  configure in a settings file. A mod's handlers are functions that run inside Claude Code instead; in the mods pages
  "hook" means a mod's handler, and the settings-file kind is a "settings hook".
  [plugins/mods/overview › Mods overview](https://code.claude.com/docs/en/plugins/mods/overview)
- A mod's `hooks/hooks.json` can also hold settings hooks under `hooks`.
  [plugins/mods/reference › Files](https://code.claude.com/docs/en/plugins/mods/reference#files)

## Managed and server-managed delivery

- Server-managed settings support every setting available in `settings.json` except those restricted to OS-level
  policy delivery, and that includes hooks, which use the same format as in `settings.json`. This example runs an
  audit script after every file edit across the organization:
  [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Edit|Write",
          "hooks": [
            { "type": "command", "command": "/usr/local/bin/audit-edit.sh" }
          ]
        }
      ]
    }
  }
  ```

- Because hooks execute shell commands, users in interactive sessions see a security approval dialog before Claude
  Code applies server-managed hooks. Certain settings that could pose security risks require explicit user approval
  before Claude Code applies them in an interactive session, and hook configurations (any hook definition) are one
  of them. If a user rejects such settings, Claude Code exits.
  [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings),
  [server-managed-settings › Security approval dialogs](https://code.claude.com/docs/en/server-managed-settings#security-approval-dialogs)
- When Claude Code can't show the approval dialog for settings that need approval, such as a hook: an interactive
  session that can't show it doesn't apply the delivered settings and keeps the last-approved settings. A
  non-interactive run, such as `claude -p`, applies them for that run only and doesn't record them as approved. When an
  error closes the dialog before you answer, Claude Code also keeps the last-approved settings. In each case the dialog
  appears in the next session that can show it.
  [server-managed-settings › Approval memory](https://code.claude.com/docs/en/server-managed-settings#approval-memory)
- A server-managed change to a setting that needs approval, such as a hook or an `env` variable, waits for the
  developer to accept the dialog in an interactive session, and applies for the current run in a session an IDE
  extension or the Agent SDK hosts, apart from the updates that wait for the next launch. Other server-managed
  changes apply on the next poll.
  [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)
- With `managedSourcesBehavior` set to `"merge"` in the highest-ranked source you deploy, Claude Code adds a lower
  source's list entries, such as `permissions.allow` rules and hooks, to the policy. Turn it on only when every
  source ranked below your highest one is under an administrator's control. This is how `hooks` combines:
  [managed-settings › Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)

  | Kind of key | How Claude Code combines it | Examples |
  | :- | :- | :- |
  | Lists | Combines the entries from every source | `permissions.allow`, `hooks`, `sandbox.network.allowedDomains`, `deniedMcpServers`, `deniedModels` |

- In a Claude apps gateway `managed` block, the first matching policy is merged onto the `match: {}` catch-all base,
  and every `hooks` event-type array takes the union of the base and the matching policy, so an org-wide audit hook
  can't be accidentally dropped by a per-role override.
  [claude-apps-gateway-config › `managed`](https://code.claude.com/docs/en/claude-apps-gateway-config#managed)
- A Claude apps gateway policy's `cli` key takes `hooks` as org-wide hooks, in the same format as settings. The CLI
  applies the delivered document at the managed tier, above user and project settings. Hook
  commands run on developer machines, not the gateway, so the path must exist on every client OS in the policy.
  [claude-apps-gateway-config › What goes in `cli`](https://code.claude.com/docs/en/claude-apps-gateway-config#what-goes-in-cli)
- Because gateway settings arrive over the network, the CLI shows each developer a security approval dialog before
  applying `hooks`. If a developer declines, Claude Code exits that session rather than applying the policy. When you
  push a new hook to a broad policy, every matching developer therefore sees the dialog in their interactive
  sessions: a running interactive session shows it on the next hourly poll, and otherwise it appears at the
  developer's next interactive startup. A non-interactive run applies pushed settings for that run only.
  [claude-apps-gateway-config › What goes in `cli`](https://code.claude.com/docs/en/claude-apps-gateway-config#what-goes-in-cli)

## Plugin hooks

- Save a plugin's hooks in `hooks/hooks.json` at the plugin root, under a top-level `"hooks"` key, in the same shape
  as the `hooks` object in `settings.json`, so you can copy an existing settings hook in unchanged. A hooks file may
  also carry an optional top-level `description` field. This hook runs a bundled script after every `Write` or
  `Edit`; save the script at `scripts/format.sh` and make it executable:
  [plugins/components › Hooks](https://code.claude.com/docs/en/plugins/components#hooks),
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Write|Edit",
          "hooks": [
            {
              "type": "command",
              "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/format.sh\""
            }
          ]
        }
      ]
    }
  }
  ```

- When a plugin is enabled, its hooks merge with your user and project hooks.
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)
- In a plugin, the name `scripts/` is a convention, not something Claude Code looks for: the hook points at the file
  by its path, `${CLAUDE_PLUGIN_ROOT}/scripts/format.sh`.
  [plugins/components › Explore the plugin directory](https://code.claude.com/docs/en/plugins/components#explore-the-plugin-directory)
- Only `plugin.json` goes inside `.claude-plugin/`; components saved there don't load.
  [plugins/create › Plugin layout](https://code.claude.com/docs/en/plugins/create#plugin-layout)
- A plugin's hooks don't wait for one of the plugin's skills or commands to be used. Claude Code registers them when
  a session loads the plugin, and they fire on their events from then on. To limit when a hook runs, narrow its
  `matcher`.
  [plugins/components › When plugin hooks fire](https://code.claude.com/docs/en/plugins/components#when-plugin-hooks-fire)
- To write hooks as JavaScript functions that run inside Claude Code and can draw in its interface, list a module
  file under a `modules` key in the same `hooks/hooks.json`. A plugin with one is a mod.
  [plugins/components › Hooks](https://code.claude.com/docs/en/plugins/components#hooks)
- For security reasons, plugin subagents don't support the `hooks` frontmatter field, which holds lifecycle hooks
  scoped to a subagent. It is ignored when loading agents from a plugin, as an agent file can't add hooks on its own.
  If you need them, copy the agent file into `.claude/agents/` or `~/.claude/agents/`, or, as the plugin's author,
  ship them as plugin hooks in `hooks/hooks.json`, which apply whenever the plugin is enabled rather than only inside
  the subagent.
  [plugins/components › Frontmatter fields in plugin agents](https://code.claude.com/docs/en/plugins/components#frontmatter-fields-in-plugin-agents),
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope),
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)
- In a synced plugin (one turned on for your claude.ai account), hooks load in terminal sessions with the same trust
  as a marketplace plugin you installed.
  [plugins/loading › Plugins synced from claude.ai](https://code.claude.com/docs/en/plugins/loading#synced-plugins)
- Claude Code never invalidates the prompt cache for a plugin's hooks. It appends their content after the existing
  conversation, so the next request pays for that content and still reads everything before it from the cache.
  [prompt-caching › Plugin components that keep the cache](https://code.claude.com/docs/en/prompt-caching#plugin-components-that-keep-the-cache)
- To move hooks from `.claude/settings.json` or `.claude/settings.local.json` into a plugin, create
  `my-plugin/hooks/hooks.json` and copy the `hooks` object from your settings file into it. The format is the same.
  While the originals are still in your settings file, hooks have no prefix, so a hook in both your settings file
  and `hooks/hooks.json` runs twice each time its event fires. After you've confirmed the plugin works, remove the
  `hooks` object from your settings file.
  [plugins/create › Convert an existing `.claude/` setup](https://code.claude.com/docs/en/plugins/create#convert-an-existing-claude-setup)

## Plugin manifest and marketplace entry hooks

- The manifest's `hooks` key takes a `.json` file path, an inline hooks object in the same shape as `hooks` in
  `settings.json`, or an array mixing both.
  [plugins/manifest-reference › `hooks`](https://code.claude.com/docs/en/plugins/manifest-reference#hooks)
- A hooks file wraps the event map in a top-level `"hooks"` key, the shape `hooks/hooks.json` uses. A file that
  contains only the event map, without that wrapper, fails to load. An inline object is the event map itself, with no
  wrapper.
  [plugins/manifest-reference › `hooks`](https://code.claude.com/docs/en/plugins/manifest-reference#hooks)
- Claude Code merges whatever the manifest's `hooks` declares with `hooks/hooks.json` when that file exists. This
  array loads one hooks file and declares one inline `PostToolUse` hook, and the file it names carries the `"hooks"`
  wrapper around its own event map, shown second as `config/extra-hooks.json`:
  [plugins/manifest-reference › `hooks`](https://code.claude.com/docs/en/plugins/manifest-reference#hooks)

  ```json
  {
    "hooks": [
      "./config/extra-hooks.json",
      {
        "PostToolUse": [
          {
            "matcher": "Write|Edit",
            "hooks": [
              { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/format.sh" }
            ]
          }
        ]
      }
    ]
  }
  ```

  `config/extra-hooks.json`:

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [
            { "type": "command", "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/check-command.sh" }
          ]
        }
      ]
    }
  }
  ```

- The manifest's `hooks` key merges with its default location: the default file loads first, and what the manifest
  declares merges into it. This differs from `commands`, `agents`, `outputStyles`, `workflows`,
  `experimental.themes` and `experimental.monitors`, which replace their default.
  [plugins/manifest-reference › How each key combines with its default location](https://code.claude.com/docs/en/plugins/manifest-reference#how-each-key-combines-with-its-default-location)
- Write a marketplace entry's `hooks` as an inline object that maps hook event names to matcher arrays; entry `hooks`
  loads only in that form. If you write a file path or an array instead, `claude plugin validate` passes it, but those
  hooks never run, and Claude Code reports a `not yet supported in a marketplace entry` error for the plugin. When the
  entry has no `plugin.json`, the entry is the manifest regardless of `strict`, and the `/plugin` **Errors** tab shows
  that error. Put file-based hooks in the plugin's own `hooks/hooks.json` or `plugin.json`.
  [plugins/marketplace-reference › Hooks in an entry](https://code.claude.com/docs/en/plugins/marketplace-reference#hooks-in-an-entry),
  [plugins/manifest-reference › How entry fields combine with `plugin.json`](https://code.claude.com/docs/en/plugins/manifest-reference#how-entry-fields-combine-with-plugin-json)
- When `plugin.json` is present and `strict` is unset or `true`, the entry's matchers for an event replace the
  manifest's matchers for that same event, and events only the manifest declares keep theirs.
  [plugins/manifest-reference › How entry fields combine with `plugin.json`](https://code.claude.com/docs/en/plugins/manifest-reference#how-entry-fields-combine-with-plugin-json)
- When `plugin.json` is present and `strict: false`, an entry that declares `hooks` is a conflict, and the plugin
  fails to load with `Plugin <name> has conflicting manifests`.
  [plugins/manifest-reference › How entry fields combine with `plugin.json`](https://code.claude.com/docs/en/plugins/manifest-reference#how-entry-fields-combine-with-plugin-json)

## Plugin paths, data and updates

- Plugin variables are substituted in hook and monitor commands, among other places. `${CLAUDE_PLUGIN_ROOT}` is the
  plugin's install directory and changes with each update, because each version has its own cache directory, so don't
  write state there. `${CLAUDE_PLUGIN_DATA}` survives updates and resolves to `~/.claude/plugins/data/<id>/`, created
  when first referenced. In that path, `<id>` is the plugin identifier with every character other than letters, digits,
  `_` and `-` replaced by `-`, so `my-plugin@my-marketplace` becomes `my-plugin-my-marketplace`.
  [plugins/components › Reference plugin paths and store data](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data)
- A relative-path plugin in a marketplace you added from a local directory loads in place from its path inside the
  marketplace folder, and its hook processes receive a `CLAUDE_PLUGIN_ROOT` that points at the source directory.
  [plugins/loading › In-place and copied plugins](https://code.claude.com/docs/en/plugins/loading#in-place-and-copied-plugins)
- When a copied plugin updates mid-session, hook commands keep using the previous version's path. Run
  `/reload-plugins` to switch hooks to the new path.
  [plugins/loading › Which marketplaces and plugins auto-update](https://code.claude.com/docs/en/plugins/loading#which-marketplaces-and-plugins-auto-update)
- For a marketplace-installed plugin, Claude Code installs eligible Node.js package dependencies automatically when
  it caches the plugin, so you may not need to install them yourself. When you do, this `SessionStart` hook installs
  `node_modules` into `${CLAUDE_PLUGIN_DATA}` on first run and again after an update changes `package.json`. After the
  first session, `~/.claude/plugins/data/<id>/node_modules` exists, and an MCP server can then set `NODE_PATH` to
  `${CLAUDE_PLUGIN_DATA}/node_modules` in its `env`:
  [plugins/components › Install dependencies into the data directory](https://code.claude.com/docs/en/plugins/components#install-dependencies-into-the-data-directory)

  ```json
  {
    "hooks": {
      "SessionStart": [
        {
          "hooks": [
            {
              "type": "command",
              "command": "diff -q \"${CLAUDE_PLUGIN_ROOT}/package.json\" \"${CLAUDE_PLUGIN_DATA}/package.json\" >/dev/null 2>&1 || (cd \"${CLAUDE_PLUGIN_DATA}\" && cp \"${CLAUDE_PLUGIN_ROOT}/package.json\" . && npm install) || rm -f \"${CLAUDE_PLUGIN_DATA}/package.json\""
            }
          ]
        }
      ]
    }
  }
  ```

## Skill and subagent frontmatter

- Hooks can be defined in subagents using frontmatter, in the same configuration format as settings-based hooks, and
  subagents use the same format in their YAML frontmatter as skills do. Claude Code runs a subagent's hooks only
  while that subagent is running and removes them when it finishes. It converts a `Stop` hook there to
  `SubagentStop`, the event it fires when a subagent completes. In frontmatter, this happens when the agent is
  invoked as a subagent.
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents),
  [sub-agents › Define hooks for subagents](https://code.claude.com/docs/en/sub-agents#define-hooks-for-subagents)
- A subagent defined with `--agents` JSON for the session accepts a `hooks` field.
  [sub-agents › Choose the subagent scope](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope)
- Frontmatter hooks fire when the agent is spawned as a subagent through the Agent tool or an @-mention, and when the
  agent runs as the main session via `--agent` or the `agent` setting. In the main-session case they run alongside any
  hooks defined in `settings.json`.
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter)
- In subagent frontmatter, all hook events are supported. The most common are:
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter)

  | Event | Matcher input | When it fires |
  | :- | :- | :- |
  | `PreToolUse` | Tool name | Before the subagent uses a tool |
  | `PostToolUse` | Tool name | After the subagent uses a tool |
  | `Stop` | (none) | When the subagent finishes (converted to `SubagentStop` at runtime) |

  The `Stop` conversion applies when the agent is invoked as a subagent.

- This subagent validates Bash commands with a `PreToolUse` hook and runs a linter after file edits with
  `PostToolUse`:
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter)

  ```yaml
  ---
  name: code-reviewer
  description: Review code changes with automatic linting
  hooks:
    PreToolUse:
      - matcher: "Bash"
        hooks:
          - type: command
            command: "./scripts/validate-command.sh"
    PostToolUse:
      - matcher: "Edit|Write"
        hooks:
          - type: command
            command: "./scripts/run-linter.sh"
  ---
  ```


## Path placeholders, worktrees and `/cd`

- Use these placeholders to reference hook scripts relative to the project or plugin root, regardless of the working
  directory when the hook runs:
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)
  - `${CLAUDE_PROJECT_DIR}`: the project root where the session started. Claude Code also sets this variable in the
    environment of stdio MCP servers and plugin LSP servers.
  - `${CLAUDE_PLUGIN_ROOT}`: the plugin's installation directory, for scripts bundled with a plugin.
  - `${CLAUDE_PLUGIN_DATA}`: the plugin's persistent data directory, for dependencies and state that should survive
    plugin updates.
- This example, in exec form with `args` (preferred for any hook that references a path placeholder; in shell form,
  double-quote each placeholder), runs a style checker from the project's `.claude/hooks/` directory after any
  `Write` or `Edit` tool call:
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)

  ```json
  {
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Write|Edit",
          "hooks": [
            {
              "type": "command",
              "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/check-style.sh",
              "args": []
            }
          ]
        }
      ]
    }
  }
  ```

- If Claude enters a worktree during the session, `${CLAUDE_PROJECT_DIR}` stays put: it still points at the project
  root where the session started, so `${CLAUDE_PROJECT_DIR}/.claude/hooks/check-style.sh` still runs the script in
  the main checkout. The `cwd` field in the hook's input JSON follows Claude: it is the worktree root after Claude
  enters a worktree, and the new directory after Claude runs `cd`.
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)
- `/cd <path>` moves the session to a different primary working directory. As soon as you move, Claude Code applies
  the new directory's project settings, including their hooks. Hooks the move activates still receive
  `${CLAUDE_PROJECT_DIR}` set to the project root where the session started.
  [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- When the `/cd` directory isn't trusted yet, Claude Code lists in the trust prompt the allow rules, additional
  directories, hooks, and helper commands the directory's settings would activate, so you can review them before you
  accept. If you decline, the session stays where it is.
  [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)

## When edits take effect

- Claude Code watches your settings files and reloads them when they change, so it applies most edits to the running
  session without a restart, including edits to `hooks`. Direct edits to hooks in settings files are normally picked
  up automatically by the file watcher. Claude Code also loads a settings file you create mid-session if its folder
  existed when the session started; for the project's `.claude/` folder, it loads the file even when you create the
  folder in the same session. Managed settings that arrive through MDM or from the claude.ai console reach a running
  session on a schedule rather than on save.
  [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect),
  [hooks › Disable or remove hooks](https://code.claude.com/docs/en/hooks#disable-or-remove-hooks)

## Not stated by the documentation

- Stated for an agent invoked as a subagent; the documentation does not say whether a `Stop` hook in frontmatter is
  converted to `SubagentStop` when the agent runs as the main session via `--agent` or the `agent` setting.
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter)
- Stated for hooks in a project skill's frontmatter; the documentation does not say whether a plugin skill's
  frontmatter hooks behave differently.
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents)

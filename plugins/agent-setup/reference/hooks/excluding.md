# Excluding hooks

Turning hooks off or restricting them: `disableAllHooks`, `allowManagedHooksOnly`, the HTTP hook allowlists,
`strictPluginOnlyCustomization.hooks`, workspace trust, `--bare`, `--safe-mode`, `CLAUDE_CODE_SIMPLE`, the sandbox
boundary, and reviewing a plugin's hooks before installing.

## Contents

- [Turning all hooks off](#turning-all-hooks-off)
- [Restricting hooks to managed ones](#restricting-hooks-to-managed-ones)
- [HTTP hook allowlists](#http-hook-allowlists)
- [Workspace trust](#workspace-trust)
- [Subagent frontmatter hooks and trust](#subagent-frontmatter-hooks-and-trust)
- [Session flags and environment variables](#session-flags-and-environment-variables)
- [The sandbox boundary](#the-sandbox-boundary)
- [Reviewing a plugin's hooks](#reviewing-a-plugins-hooks)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## Turning all hooks off

- To remove a hook defined in a settings file, delete its entry from that file. There is no way to disable an
  individual hook while keeping it in the configuration.
  [hooks › Disable or remove hooks](https://code.claude.com/docs/en/hooks#disable-or-remove-hooks)
- To temporarily disable all hooks without removing them, set `"disableAllHooks": true` in your settings file. Scope:
  any file; type: Boolean; default: unset, so hooks run. Claude Code reads the value left after settings precedence
  applies, so a `"disableAllHooks": false` in a project's `.claude/settings.json` overrides a `true` in your user
  settings.
  [hooks › Disable or remove hooks](https://code.claude.com/docs/en/hooks#disable-or-remove-hooks),
  [settings-reference › `disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks)

  ```json
  {
    "disableAllHooks": true
  }
  ```

- To turn hooks off for one run whatever the project's settings say, pass `--settings '{"disableAllHooks": true}'`,
  which takes precedence over project and local settings. Setting it in your user settings alone isn't enough before
  `claude -p` in a repository you didn't write, because the repository's project settings take precedence over yours
  and can set it back to `false`.
  [hooks › Disable or remove hooks](https://code.claude.com/docs/en/hooks#disable-or-remove-hooks),
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- The key also turns off any custom status line and any custom file suggestion command; `false` lets hooks, the status
  line and the file suggestion command run. When managed settings set it, `statusLine`, `fileSuggestion` and
  `subagentStatusLine` are off entirely. When it is `true` outside managed settings after settings precedence applies,
  they narrow to managed settings: Claude Code runs a managed value if one is deployed, and otherwise skips your value
  without warning. The `/goal` command can't run while hooks are disabled, and the `/hooks` menu shows a notice instead
  of your hooks.
  [settings-reference › `disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks),
  [settings-reference › Status line and file suggestion gates](https://code.claude.com/docs/en/settings-reference#status-line-and-file-suggestion-gates)
- Its reach depends on the file that carries it. In managed settings, Claude Code disables every configured hook,
  including managed ones, so a `PreToolUse` hook in your managed settings no longer blocks anything. It keeps running
  the hooks the Agent SDK registers in process. In any other settings file,
  Claude Code disables user, project, local and plugin hooks; managed hooks, Agent SDK hooks, and hooks from plugins
  force-enabled in managed `enabledPlugins` keep running. Only `disableAllHooks` set at the managed settings level can
  disable managed hooks.
  [settings-reference › `disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks),
  [hooks › Disable or remove hooks](https://code.claude.com/docs/en/hooks#disable-or-remove-hooks),
  [plugins/mods/admin › Choose how much to allow](https://code.claude.com/docs/en/plugins/mods/admin#choose-how-much-to-allow)
- The key also stops mods, which are plugins whose code registers hooks. In managed settings, the mods in every
  installed plugin stop, your organization's included. In any other settings file, the mods you installed stop and your
  organization's mods keep running. Mods built into Claude Code keep running in both cases, each with its own switch.
  [settings-reference › `disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks),
  [plugins/mods/reference › Settings and environment variables](https://code.claude.com/docs/en/plugins/mods/reference#settings-and-environment-variables)
- An invalid `disableAllHooks` in a managed source, even a quoted boolean, is dropped with a warning and doesn't fail
  closed, because enforcing `true` would also unload the hooks your own managed settings deploy.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)

## Restricting hooks to managed ones

- `allowManagedHooksOnly` restricts hook execution to hooks your organization deploys. Scope: managed; type: Boolean;
  default: unset, so hooks from every settings scope and plugin run. `true`: only managed hooks run, plus hooks the
  Agent SDK registers in process and hooks from plugins your managed settings force-enable through `enabledPlugins`;
  Claude Code matches on the full `plugin@marketplace` ID, so a plugin with the same name from a different marketplace
  stays blocked. A mod in such a plugin loads only when it counts as your organization's. `false`: hooks from every
  settings scope and plugin run.
  [settings-reference › `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedhooksonly),
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly)

  ```json
  {
    "allowManagedHooksOnly": true
  }
  ```

- Everything else is blocked: user, project and local hooks, hooks and mods from other installed plugins, and hooks
  declared in agent frontmatter. Mods built into Claude Code keep running. To block only users' mods, set
  `allowManagedModsOnly` instead, which leaves users' settings hooks running.
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly),
  [plugins/mods/admin › Choose how much to allow](https://code.claude.com/docs/en/plugins/mods/admin#choose-how-much-to-allow),
  [plugins/mods/reference › Settings and environment variables](https://code.claude.com/docs/en/plugins/mods/reference#settings-and-environment-variables)
- Claude Code also reads `statusLine`, `fileSuggestion` and `subagentStatusLine` from managed settings only: it runs a
  managed value if one is deployed, and otherwise skips your value without warning. It disables plugins with a
  `command` source, including plugins force-enabled in managed `enabledPlugins`, unless
  `disableCommandPluginSources` is explicitly set to `false`. It blocks marketplace `headersHelper` commands unless
  `disableCommandPluginSources` is explicitly set to `false`, except for a marketplace that managed settings themselves
  declare.
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly),
  [settings-reference › Status line and file suggestion gates](https://code.claude.com/docs/en/settings-reference#status-line-and-file-suggestion-gates),
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations)
- The `/goal` command can't run while `allowManagedHooksOnly` is set, because it depends on hooks.
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly)
- Under `managedSourcesBehavior` set to `"merge"`, Claude Code treats `allowManagedHooksOnly` as a lock: it applies the
  strictest value any source sets, and a looser value applies only from the highest-ranked source.
  [managed-settings › Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)
- `strictPluginOnlyCustomization` with `"hooks"` in its array locks the `hooks` surface: Claude Code stops running
  hooks from user, project and local `settings.json`, and keeps running plugin hooks and hooks in managed settings.
  Scope: managed; default: not locked. Setting the key to `true` locks all four kinds of customization (`"skills"`,
  `"agents"`, `"hooks"` and `"mcp"`), hooks included. Claude Code ignores surface names it doesn't recognise rather
  than failing the settings file.
  [settings-reference › `strictPluginOnlyCustomization.hooks`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-hooks),
  [settings-reference › `strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization)
- When a managed source sets `strictPluginOnlyCustomization` to a value that is neither a boolean nor an array, Claude
  Code treats it as `true`, locking all four surfaces, hooks included. An array entry that Claude Code doesn't recognise
  as a surface locks nothing.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)

  ```json
  {
    "strictPluginOnlyCustomization": ["hooks"]
  }
  ```

## HTTP hook allowlists

- `allowedHttpHookUrls` limits which URLs HTTP hooks can target. When defined at any settings level, Claude Code runs an
  HTTP hook only if its URL matches the merged allowlist and blocks the rest without running them; an empty array
  blocks every HTTP hook. Scope: any file, and arrays merge across settings files; type: array of URL patterns, with
  `*` as a wildcard; default: unset, so any URL is allowed.
  [settings-reference › `allowedHttpHookUrls`](https://code.claude.com/docs/en/settings-reference#allowedhttphookurls),
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations)

  ```json
  {
    "allowedHttpHookUrls": ["https://hooks.example.com/*", "http://localhost:*"]
  }
  ```

  This allows any URL under `https://hooks.example.com/` and any `http://localhost` URL.
- Hostname matching is case-insensitive and treats `hooks.example.com.`, with the trailing dot that marks a fully
  qualified domain name, the same as `hooks.example.com`. The allowlist applies to hooks from every source, including
  managed settings.
  [settings-reference › `allowedHttpHookUrls`](https://code.claude.com/docs/en/settings-reference#allowedhttphookurls)
- `httpHookAllowedEnvVars` sets an outer limit on the `allowedEnvVars` list of every HTTP hook: a hook can put an
  environment variable's value into a request header only if both its own `allowedEnvVars` and this key name it. Use it
  to stop a hook from reading a secret it shouldn't, even when the hook's definition asks for it. Scope: any file, and
  arrays merge across settings files; type: array of environment variable names; default: unset, so each hook's own
  `allowedEnvVars` list applies. It applies to hooks from every source, including managed settings.
  [settings-reference › `httpHookAllowedEnvVars`](https://code.claude.com/docs/en/settings-reference#httphookallowedenvvars),
  [hooks › Hook locations](https://code.claude.com/docs/en/hooks#hook-locations)

  ```json
  {
    "httpHookAllowedEnvVars": ["MY_TOKEN", "HOOK_SECRET"]
  }
  ```

- When a managed source sets `allowedHttpHookUrls` or `httpHookAllowedEnvVars` to a value Claude Code can't read, it
  enforces an empty managed allowlist until you fix the value. An HTTP hook then runs only if another settings file
  lists its URL, and a header variable is interpolated only if another settings file names it. If only an individual
  entry is invalid, Claude Code strips that entry and enforces the rest. Both keys merge across settings files, so
  entries in your user, project or local settings still apply while the managed list is empty.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)

## Workspace trust

- Claude Code checks workspace trust before it runs any hook from a settings file. In an interactive session, it holds
  back hooks from every settings file, including your own `~/.claude/settings.json`, until you accept the workspace
  trust dialog for the folder, or for a parent directory whose trust extends to it.
  [hooks › Workspace trust](https://code.claude.com/docs/en/hooks#workspace-trust)
- In a `-p` or SDK session, Claude Code never shows the dialog and treats the folder as trusted, so hooks committed in
  a repository's `.claude/settings.json` run in a folder you've never trusted.
  [hooks › Workspace trust](https://code.claude.com/docs/en/hooks#workspace-trust),
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- Before you script `claude -p` over a repository you didn't write, review its `.claude/` settings files, start with
  `--bare`, or turn hooks off for that run. `--bare` makes Claude Code read no hooks from the project; the project's
  `env` block and helpers such as `awsAuthRefresh` in its settings files still apply, and Claude Code reads
  `apiKeyHelper` only from `--settings`.
  [hooks › Workspace trust](https://code.claude.com/docs/en/hooks#workspace-trust),
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- Each row is one kind of content a repository can supply; the rows here are the two that hold hooks. The
  columns are the two situations in which you haven't trusted the folder itself: you trusted only a parent folder, or
  you ran `claude -p` or the SDK there, which never shows the trust dialog. The parent-folder column doesn't apply
  inside a nested repository: in an interactive session Claude Code shows the trust dialog for it, and a `claude -p` or
  SDK run there follows the `claude -p` column.
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)

  | What the repository supplies | You trusted only a parent folder | `claude -p` or the SDK, folder never trusted |
  | :- | :- | :- |
  | [Hooks](https://code.claude.com/docs/en/hooks) in settings files, the [`env`](https://code.claude.com/docs/en/settings-reference#env) block and helper commands such as [`apiKeyHelper`](https://code.claude.com/docs/en/settings-reference#apikeyhelper), and a project skill's [hooks](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents) and [`allowed-tools`](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill) | Used | Used. Workspace trust never gates a skill's `allowed-tools` in any session |
  | Frontmatter hooks in a project [subagent](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter), a project [`@skills-dir` plugin](https://code.claude.com/docs/en/plugins/loading#plugins-shared-through-a-repository), and [`extraKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#extraknownmarketplaces) entries from the repository or an `--add-dir` directory | Not used, and no dialog is offered | Not used |

- To keep a repository's settings-file hooks from running under `claude -p`, pass `--setting-sources user`, or set the
  SDK's `settingSources` without project settings, so Claude Code reads neither the project's settings files nor its
  `.mcp.json`.
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- Command hooks execute shell commands with your full user permissions. They can modify, delete, or access any files
  your user account can access, so review and test all hook commands before adding them to your configuration.
  [hooks › Disclaimer](https://code.claude.com/docs/en/hooks#disclaimer)

## Subagent frontmatter hooks and trust

- To let a project-level subagent's frontmatter hooks run, accept the workspace trust dialog for the folder that
  contains the agent file. Hooks from user-level subagents in `~/.claude/agents/` and from definitions you pass with
  `--agents` run without this step. If you added a folder with `--add-dir` from outside your trusted workspace's
  repository, trust that folder separately: its `.claude/agents/` hooks don't inherit the workspace's grant.
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter),
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents)
- Until you trust the folder, the subagent still runs, but Claude Code skips its frontmatter hooks and logs an error to
  the debug log explaining how to trust the folder. This is stricter than the rule for hooks in settings files:
  trusting a parent folder isn't enough, and a `-p` session doesn't count as trusted.
  [sub-agents › Hooks in subagent frontmatter](https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter)

## Session flags and environment variables

- `--bare` skips auto-discovery of hooks, so a hook in a teammate's `~/.claude` won't run, because bare mode never
  reads it. It sets `CLAUDE_CODE_SIMPLE`, and `CLAUDE_CODE_SIMPLE=1` disables auto-discovery of hooks and is equivalent
  to `--bare`.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode),
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `--safe-mode` starts with all customizations disabled, and hooks do not load. Managed settings policy still applies,
  including policy-configured hooks, but managed plugins do not load. `CLAUDE_CODE_SAFE_MODE=1` is equivalent: hooks do
  not load, policy-configured hooks still apply, and managed plugins do not load.
  Directly spawned child processes inherit the variable.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables),
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- To test with no user or project hooks another way, point `CLAUDE_CONFIG_DIR` at an empty directory and launch from a
  directory with no `.claude` folder, `.mcp.json` or `CLAUDE.md`. The clean session has no user or project settings or
  hooks. Managed settings still apply if your organization deploys them, because Claude Code reads MDM profiles,
  registry policy and `managed-settings.json` from locations outside the configuration directory, and fetches
  server-managed settings again for the clean session once it has credentials.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)
- `CLAUDE_CODE_SIMPLE_SYSTEM_PROMPT=1` uses a shorter system prompt and abbreviated tool descriptions on any model; the
  full tool set, hooks, MCP servers and CLAUDE.md discovery remain enabled, so it doesn't turn hooks off.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` strips credentials from subprocess environments (Bash tool, hooks, MCP stdio
  servers): Anthropic and cloud provider credentials, any other variable Claude Code recognises as a credential, and
  credentials embedded in package registry URLs. The parent Claude process keeps them for API calls. The scrub also
  removes Claude Code's own configuration-store pointer variables (such as `CLAUDE_CONFIG_DIR`), so a child process
  cannot locate a relocated configuration directory; leave the scrub unset if a subprocess needs these variables. On
  Linux, it also runs Bash subprocesses in an isolated PID namespace so they cannot read host process environments via
  `/proc`; as a side effect, `ps`, `pgrep` and `kill` cannot see or signal host processes. `claude-code-action` sets it
  automatically when `allowed_non_write_users` is configured.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## The sandbox boundary

- The sandbox wraps shell commands. Other processes Claude Code starts, including command hooks, run outside it with
  your full access. To put them behind one boundary, run the Claude Code process itself in a container, virtual
  machine, or the sandbox runtime.
  [sandboxing › What runs outside the sandbox](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox)
- Running Claude Code through the sandbox runtime constrains the session's tools, hooks and MCP servers as well as shell
  commands.
  [sandbox-environments › Sandbox runtime](https://code.claude.com/docs/en/sandbox-environments#sandbox-runtime)
- Always run `--dangerously-skip-permissions` sessions inside a container, a VM, or the sandbox runtime, so that file
  tools, MCP servers and hooks are also inside the boundary.
  [sandbox-environments › How isolation relates to permission modes](https://code.claude.com/docs/en/sandbox-environments#how-isolation-relates-to-permission-modes)
- Inside the directories sandboxed commands can write to, the sandbox still denies writes to the files Claude Code
  loads configuration and code from, because a command that could edit them could add a hook or MCP server that Claude
  Code runs outside the sandbox. In your working directory and the directories above it, this includes the
  `.claude/hooks` directories.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)

## Reviewing a plugin's hooks

- In a Claude Code session, run `/plugin` and select the plugin: the details pane's **Will install** section lists the
  plugin's commands, agents, skills, hooks, and MCP and LSP servers. It shows that a hook exists but not what it runs.
  [plugins/security › Review a plugin before you install](https://code.claude.com/docs/en/plugins/security#review-a-plugin-before-you-install)
- To see what each hook runs, read `hooks/hooks.json` in the plugin's directory: it holds the command each hook runs.
  Find the directory through **Open homepage** or **View on GitHub** in the details pane, or in the marketplace
  repository that `claude plugin marketplace list` shows.
  [plugins/security › Review a plugin before you install](https://code.claude.com/docs/en/plugins/security#review-a-plugin-before-you-install)
- Clone the repository that holds the plugin's directory, then run
  `claude --plugin-dir <plugin directory> plugin details <plugin name>` in your shell. It reads the plugin's files
  without starting a session and prints a `Component inventory` listing, among other components, the hooks with each
  hook's event. After you install a plugin, `claude plugin details <plugin name>` prints the same inventory for the
  installed copy.
  [plugins/security › Review a plugin before you install](https://code.claude.com/docs/en/plugins/security#review-a-plugin-before-you-install)

## Not stated by the documentation

- Whether `disableAllHooks` also stops frontmatter hooks in skills and subagents: the documentation says it disables
  "user, project, local, and plugin hooks" when set outside managed settings, and "every configured hook" in managed
  settings.
  [settings-reference › `disableAllHooks`](https://code.claude.com/docs/en/settings-reference#disableallhooks)
- Whether `strictPluginOnlyCustomization` with `"hooks"` also blocks frontmatter hooks in skills and agents: the
  documentation names hooks from user, project and local `settings.json`.
  [settings-reference › `strictPluginOnlyCustomization.hooks`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-hooks)
- Whether `--bare` or `CLAUDE_CODE_SIMPLE` skips hooks from managed settings: the documentation says only that they skip
  auto-discovery of hooks, and states that `--safe-mode` still applies managed hooks.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- Whether `allowManagedHooksOnly` blocks hooks supplied by `--settings`, `--plugin-dir` or definitions passed with
  `--agents`: the documentation names user, project and local hooks, other installed plugins, and hooks declared in
  agent frontmatter.
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly)

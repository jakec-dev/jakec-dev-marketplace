# Placing settings

Knowing the settings files, which sources load and how they combine.

## Contents

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

## Settings files and their scopes

- The terminal, the VS Code and JetBrains extensions and the desktop app all read the same settings files.
  [settings › Settings files and precedence](https://code.claude.com/docs/en/settings#page-title)
- Claude Code reads settings from four files, and an organization can also deliver managed settings from the
  claude.ai console. Each source has a scope: the set of people and projects a setting saved in it applies to, whether
  that's only you, everyone in a project, or everyone in your organization. In the File column, `~/.claude` is the
  `.claude` folder in your home directory, and a bare `.claude` is the `.claude` folder inside your project.
  [settings › Settings files and who they affect](https://code.claude.com/docs/en/settings#settings-files-and-who-they-affect)

  | Scope | File | Who it affects | Use it for |
  | :- | :- | :- | :- |
  | User | `~/.claude/settings.json` | You, in every project on this machine | Personal preferences: theme, editor mode, default model, your own permission rules |
  | Shared project | `.claude/settings.json` | Everyone working in the folder that contains it. In a git repository, commit it so teammates get it | Team permissions, hooks, plugins, and the environment variables the project needs |
  | Project local | `.claude/settings.local.json` | You, in this one project only. Claude Code keeps it out of git when it creates the file; if you create it by hand, add it to `.gitignore` yourself | Personal overrides for one project, and testing before you share |
  | Managed | `managed-settings.json` and other [managed sources](https://code.claude.com/docs/en/managed-settings#delivery-mechanisms) | Everyone your organization deploys it to; [Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence) says what can override it | Security policy and compliance requirements |

- Where each file reaches, for a project `acme-app/` that you and a teammate each have cloned:
  [settings › Compare the scope of each settings file](https://code.claude.com/docs/en/settings#compare-the-scope-of-each-settings-file)
  - `acme-app/.claude/settings.json` reaches your teammate's clone only if you commit the file to version control;
    until you do, it's a file on your disk like any other and nobody else has it.
  - Managed settings reach every project on every machine your organization deploys them to, or that you sign in to
    with your organization account.
- Project-scope files live in your repo under `.claude/`; global-scope files live in `~/.claude/` and apply across all
  projects. The table covers the settings rows:
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)

  | File | Scope | Commit | What it does | Reference |
  | - | - | - | - | - |
  | `settings.json` | Project and global | ✓ | Permissions, hooks, env vars, model defaults | [Settings](https://code.claude.com/docs/en/settings) |
  | `settings.local.json` | Project only | | Your personal overrides, gitignored when Claude Code saves a setting to it | [Settings scopes](https://code.claude.com/docs/en/settings#compare-the-scope-of-each-settings-file) |
  | `~/.claude.json` | Global only | | App state, account details, UI toggles, personal MCP servers. If it's missing, Claude Code creates it when you start a session or run a subcommand such as `claude auth status`, but not for `--version` or `--help`. | [Global config](https://code.claude.com/docs/en/settings-reference#global-config-settings) |

## Finding, creating and sharing the files

- Installing Claude Code doesn't create any settings file. Managed settings come from your organization, which deploys
  them; you don't create or edit them. A project that already uses Claude Code may have a shared project file
  committed; if not, create it at `.claude/settings.json` in the project folder.
  [settings › Find or create your settings files](https://code.claude.com/docs/en/settings#find-or-create-your-settings-files)
- User and project local files: create them yourself, or let Claude Code create them. It writes
  `~/.claude/settings.json` the first time you change an option in the `/config` menu that it stores in user settings,
  such as the theme, and `.claude/settings.local.json` the first time you give a standing approval on a permission
  prompt.
  [settings › Find or create your settings files](https://code.claude.com/docs/en/settings#find-or-create-your-settings-files)
- On Windows, `~/.claude` means `%USERPROFILE%\.claude`. To keep the home-directory files somewhere else, set
  [`CLAUDE_CONFIG_DIR`](https://code.claude.com/docs/en/env-vars); Claude Code then stores your settings, session
  history, and plugins there instead.
  [settings › Find or create your settings files](https://code.claude.com/docs/en/settings#find-or-create-your-settings-files)
- Commit `.claude/settings.json` so everyone who clones the repository gets the same permissions, hooks, and plugins.
  [settings › Share settings with your team](https://code.claude.com/docs/en/settings#share-settings-with-your-team)
- Some of what you commit waits until each teammate
  [trusts the folder](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust), and a few
  keys never take effect from a repository file.
  [settings › Share settings with your team](https://code.claude.com/docs/en/settings#share-settings-with-your-team)
- To change a setting for yourself in one project without changing it for your teammates, save it in
  `.claude/settings.local.json` inside the project. Claude Code applies that file over the committed
  `.claude/settings.json`, so if your team's file sets `"model": "claude-sonnet-5"` and you want Opus, put
  `"model": "claude-opus-5-5"` in your local file and only your sessions change.
  [settings › Keep personal settings out of a repository](https://code.claude.com/docs/en/settings#keep-personal-settings-out-of-a-repository)
- Claude Code writes `.claude/settings.local.json` too and keeps it out of your commits. The first time it writes the
  file in a git repository that doesn't already ignore it, it adds `**/.claude/settings.local.json` to your global git
  excludes file, so the file stays out of your commits in every repository. That file is `core.excludesFile` when your
  global git config sets it to an absolute or `~`-prefixed path; otherwise it's `$XDG_CONFIG_HOME/git/ignore`, or
  `~/.config/git/ignore` when `XDG_CONFIG_HOME` is unset. If you created the file by hand and Claude Code hasn't
  written to it yet, add it to `.gitignore` yourself.
  [settings › Keep personal settings out of a repository](https://code.claude.com/docs/en/settings#keep-personal-settings-out-of-a-repository)
- `~/.claude/settings.local.json` is local scope, so Claude Code reads it only in sessions you start in your home
  directory itself, not in every project. To apply permission rules across all your projects, add them to your user
  settings instead: `~/.claude/settings.json`, or `$CLAUDE_CONFIG_DIR/settings.json` when `CLAUDE_CONFIG_DIR` is set.
  [permissions › When your local settings file needs trust](https://code.claude.com/docs/en/permissions#when-your-local-settings-file-needs-trust)

## The local file in a git repository

- When Claude asks permission to run a Bash command and you choose "Yes, and don't ask again", Claude Code saves that
  approval as an `allow` rule in `.claude/settings.local.json`. If you start Claude Code in a subdirectory of a git
  repository, it reads and writes that file at the repository root and applies the approval across the whole
  repository. In a worktree, it uses the file at the main checkout's root.
  [settings › Where Claude Code keeps the local file in a git repository](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)
- The local file stays with `.claude/settings.json` instead of the repository root outside a git repository, when the
  repository root is your home directory, on Windows, or when the repository root or its `.git` or `.claude` entry
  isn't owned by your user.
  [settings › Where Claude Code keeps the local file in a git repository](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)
- Claude Code still reads a local file that an earlier version of Claude Code left in the starting directory, alongside
  the root file. Where both set the same key, the root's value applies, and permission rules from both files apply.
  [settings › Where Claude Code keeps the local file in a git repository](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)
- Paths in the file don't anchor at the repository root: a permission rule that starts with `/` or a relative sandbox
  path [anchors at the session's primary working directory](https://code.claude.com/docs/en/permissions#read-and-edit)
  instead.
  [settings › Where Claude Code keeps the local file in a git repository](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)
- Claude Code reads the shared `.claude/settings.json` from the session's
  [primary working directory](https://code.claude.com/docs/en/permissions#working-directories)'s `.claude/` folder with
  no parent-directory fallback, alongside your user `~/.claude/settings.json` and managed settings, so to use a file
  committed at the repository root, start Claude Code there. After you
  [move the session with `/cd`](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory),
  Claude Code reads both project files from the new directory instead, placing the local file by the same rules.
  [settings › Where Claude Code keeps the local file in a git repository](https://code.claude.com/docs/en/settings#where-claude-code-keeps-the-local-file-in-a-git-repository)
  and [permissions › Where output styles, hooks, and local settings load from](https://code.claude.com/docs/en/permissions#where-output-styles-hooks-and-local-settings-load-from)
- To share output styles, hooks or settings keys across projects, use one of these approaches: user-level
  configuration (files in
  `~/.claude/agents/`, `~/.claude/output-styles/`, or `~/.claude/settings.json`, available in every project), a
  [plugin](https://code.claude.com/docs/en/plugins/overview) that teams can install, or launching Claude Code from the
  directory containing the `.claude/` configuration you want.
  [permissions › Where output styles, hooks, and local settings load from](https://code.claude.com/docs/en/permissions#where-output-styles-hooks-and-local-settings-load-from)
- After a worktree is created, the session's working directory is the worktree root, not the subdirectory you launched
  from, so project settings inside the worktree load from the worktree root's `.claude/settings.json`, the checked-out
  copy of the repository root's file. Put any other settings you need inside worktrees, such as permission rules or
  hooks, in the repository root's `.claude/settings.json`; with `worktree.sparsePaths`, the root `.claude` must be
  listed for that file to exist there.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)

## Choosing which sources load

- `--setting-sources` takes a comma-separated list of setting sources to load (`user`, `project`, `local`), such as
  `claude --setting-sources user,project`.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- A session you background carries `--settings` and `--setting-sources` from the original launch, so its settings stay
  in effect.
  [agent-view › What carries over when you background](https://code.claude.com/docs/en/agent-view#what-carries-over-when-you-background)
- `claude agents` accepts `--settings` like the top-level `claude` command. Agent view applies `--settings` and
  `--setting-sources` to itself and passes them to every session you dispatch from it: `--settings` overrides settings
  for agent view and dispatched sessions, and `--setting-sources` loads only the named sources in both.
  [agent-view › Settings, plugins, and MCP servers](https://code.claude.com/docs/en/agent-view#settings-plugins-and-mcp-servers)
  and [cli-reference › CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands)
- If you start the agent team lead with `--setting-sources`, teammates load from the same restricted list of sources.
  A split-pane teammate also gets your `--settings` value.
  [agent-teams › Context and communication](https://code.claude.com/docs/en/agent-teams#context-and-communication)
  and [tools-reference › Task-tracking tools in subagents and agent teams](https://code.claude.com/docs/en/tools-reference#task-tracking-tools-in-subagents-and-agent-teams)
- `--restricted` starts restricted mode, which loads only [managed settings](https://code.claude.com/docs/en/managed-settings)
  and `--settings`, not the machine's user and project settings.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

## Precedence

- When the same key appears in more than one place, Claude Code uses the value from the highest level that sets it; a
  key at a higher level overrides the same key anywhere below it. Highest first: managed settings, command line,
  project local, shared project, user.
  [settings › Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence)
- Managed settings are those your organization deploys, by a `managed-settings.json` file, an MDM policy, or
  [server-managed settings](https://code.claude.com/docs/en/server-managed-settings) from the claude.ai console.
  Nothing in your own settings files or `--settings` overrides a managed key, and a flag such as `--model` picks only
  from the models your organization allows. A managed [`model`](https://code.claude.com/docs/en/settings-reference#model)
  is a starting default, not a lock; the locks are
  [`availableModels`](https://code.claude.com/docs/en/settings-reference#availablemodels) and
  [`deniedModels`](https://code.claude.com/docs/en/settings-reference#deniedmodels).
  [settings › Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence)
- An organization default model that an admin set to override user selection takes precedence over `model` in user,
  project and local settings. `--model`, `ANTHROPIC_MODEL`, managed settings and `--settings` still take precedence
  over it.
  [settings-reference › `model`](https://code.claude.com/docs/en/settings-reference#model)
  and [model-config › Organization default model](https://code.claude.com/docs/en/model-config#organization-default-model)
- Command line: JSON you pass with `--settings <file-or-json>` when you start `claude`, for that session only. A key
  you set there overrides the same key in your project and user settings files, and a key you leave out keeps its
  value from those files. Other flags, such as `--model`, set one thing for the session and aren't part of this stack;
  a key's entry on the [settings reference](https://code.claude.com/docs/en/settings-reference) says which flags
  override it.
  [settings › Settings precedence](https://code.claude.com/docs/en/settings#settings-precedence)
- Some keys have a command line flag or an environment variable that overrides the settings value regardless of which
  file set it. Whether you can get your value back depends on the key: unset the variable or drop the flag, and check
  the
  key's entry on the [settings reference](https://code.claude.com/docs/en/settings-reference) and the variable's row
  on the [environment variables reference](https://code.claude.com/docs/en/env-vars) for which one Claude Code uses.
  [settings › A flag or environment variable sets the same thing](https://code.claude.com/docs/en/settings#a-flag-or-environment-variable-sets-the-same-thing)

## Lists merge instead of overriding

- When you set the same list key, such as `permissions.allow`, in more than one file, Claude Code combines the lists
  instead of picking one, so each file can add entries without removing another file's.
  [settings › Lists merge instead of overriding](https://code.claude.com/docs/en/settings#lists-merge-instead-of-overriding)
- Four keys that hold model lists or per-model entries follow their own rules:
  [settings › Lists merge instead of overriding](https://code.claude.com/docs/en/settings#lists-merge-instead-of-overriding)
  - [`fallbackModel`](https://code.claude.com/docs/en/settings-reference#fallbackmodel) is an ordered chain where
    position carries meaning, so Claude Code takes the whole value from the highest-precedence file that defines it.
  - [`modelPicker`](https://code.claude.com/docs/en/settings-reference#modelpicker) holds one ordered list of rows plus
    a replace flag, so Claude Code never merges rows from two sources. It takes the whole value from the highest of
    managed settings, `--settings`, and user settings that defines it.
  - [`availableModels`](https://code.claude.com/docs/en/settings-reference#availablemodels): when the managed settings
    Claude Code applies define it, Claude Code applies that list as-is and ignores entries you add in user, project,
    or local settings (for an embedding app's own list, see Exceptions to managed settings precedence). Across managed
    sources the list never merges either. Across non-managed scopes Claude Code merges the arrays as usual.
  - [`modelSettings`](https://code.claude.com/docs/en/settings-reference#modelsettings): Claude Code resolves it one
    model at a time, together with [`effortLevel`](https://code.claude.com/docs/en/settings-reference#effortlevel).
    In one settings file, a model's `effortLevel` beats the top-level `effortLevel`. Across files, the
    highest-precedence settings file that sets either an `effortLevel` for that model or a top-level `effortLevel`
    that applies to it decides, so a managed `effortLevel` outranks one in user settings.
- Same-name entries under `extraKnownMarketplaces` do not merge: when more than one settings file defines a
  marketplace entry under the same name, Claude Code uses the entry from the highest-precedence file whole. That entry
  replaces the lower-precedence entry and inherits none of its fields, so a redefinition can't combine one file's
  `source.headers` credential with a URL another file controls.
  [settings-reference › `extraKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#extraknownmarketplaces)

## Precedence examples

Each example assumes you set
[`spinnerTipsEnabled`](https://code.claude.com/docs/en/settings-reference#spinnertipsenabled) to `false` in
`~/.claude/settings.json` to turn the one-line spinner tips off, and shows what turns them back on.
[settings › Precedence examples](https://code.claude.com/docs/en/settings#precedence-examples)

- Your team's `.claude/settings.json` sets it to `true`: Claude Code uses the project value because shared project
  sits above user, so you see tips in that project and nowhere else. Add `"spinnerTipsEnabled": false` to
  `.claude/settings.local.json` in that project to get your value back; project local sits above shared project, so
  your teammates' sessions don't change.
  [settings › Team settings override personal settings](https://code.claude.com/docs/en/settings#team-settings-override-personal-settings)
- Your organization's managed settings set it to `true`: nothing you put in user, project, or local settings turns tips
  off, and neither does `--settings`, because managed is the top level. Run `/status` to see which managed source
  applies, and ask your administrator if the policy should change.
  [settings › Organization settings override everything](https://code.claude.com/docs/en/settings#organization-settings-override-everything)
- You started the session with `claude --settings '{"spinnerTipsEnabled": true}'`: command line sits above every file
  except managed, so that session shows tips even though your files say `false`. You get your value back on the next
  session; `--settings` lasts one session and doesn't write to any file.
  [settings › The command line overrides your files for one session](https://code.claude.com/docs/en/settings#the-command-line-overrides-your-files-for-one-session)

## Exceptions to managed settings precedence

- For a few keys whose values restrict a session, Claude Code honors a restrictive value from a scope that otherwise
  couldn't override managed settings. The table shows which value it honors and from where.
  [settings › Exceptions to managed settings precedence](https://code.claude.com/docs/en/settings#exceptions-to-managed-settings-precedence)

  | Key | Value Claude Code honors | Notes |
  | :- | :- | :- |
  | [`disableClaudeAiConnectors`](https://code.claude.com/docs/en/settings-reference#disableclaudeaiconnectors) | `true` from any scope | Honored even when a managed source sets `false` |
  | [`enableArtifact`](https://code.claude.com/docs/en/settings-reference#enableartifact) | `false` from any scope, and `disableArtifact: true` from any scope | Honored even when a managed source sets `true`; nothing turns the [Artifact tool](https://code.claude.com/docs/en/artifacts#disable-artifacts) back on |
  | [`isolatePeerMachines`](https://code.claude.com/docs/en/settings-reference#isolatepeermachines) | `true` from any scope | Honored even when a managed source sets `false` |
  | [`permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories) | `true` from any scope | Honored even when a managed source sets `false` |
  | [`autoMode.classifyAllShell`](https://code.claude.com/docs/en/settings-reference#automode-classifyallshell) | `true` from `~/.claude/settings.json` or `--settings` | Honored even when a managed source sets `false` |
  | [`remoteControlAtStartup`](https://code.claude.com/docs/en/settings-reference#remotecontrolatstartup) | `false` from `.claude/settings.json` or `.claude/settings.local.json` | Honored even when a managed source sets `true`; a project or local `true` is ignored |
  | [`crossSessionInbound`](https://code.claude.com/docs/en/settings-reference#crosssessioninbound) | A stricter value from `.claude/settings.json` or `.claude/settings.local.json`, on the `accept` \< `hold` \< `refuse` ladder | Honored over managed, `--settings`, and user values; a project or local value that isn't stricter is ignored |
  | [`useAutoModeDuringPlan`](https://code.claude.com/docs/en/settings-reference#useautomodeduringplan) | `false` from any managed source, `--settings`, `~/.claude/settings.json`, or `.claude/settings.local.json` | Honored even when the winning managed source sets `true`; a `false` in `.claude/settings.json` is ignored |
  | [`syncClaudeAiPlugins`](https://code.claude.com/docs/en/settings-reference#syncclaudeaiplugins) | `false` from any managed source, `--settings`, `~/.claude/settings.json`, or `.claude/settings.local.json` | Honored even when the winning managed source sets `true`; a `false` in `.claude/settings.json` is ignored |
  | [`maxEffortLevel`](https://code.claude.com/docs/en/settings-reference#maxeffortlevel) | A lower cap from any scope, including `--settings` | Honored even when the managed settings Claude Code applies set a higher cap; the lowest cap applies |

- A `maxEffortLevel` in a model's `modelSettings` entry replaces the top-level `maxEffortLevel` for that model only
  within the settings source that sets both. `"max"` there exempts the model from that source's cap; Claude Code still
  applies caps from other sources.
  [settings-reference › `maxEffortLevel`](https://code.claude.com/docs/en/settings-reference#maxeffortlevel)
- An app that runs Claude Code inside itself and sets
  [`CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`](https://code.claude.com/docs/en/env-vars) is also an exception. Claude Code
  takes that app's model configuration over the `model`, `fallbackModel`, `modelPicker`, and `modelOverrides` keys from
  every managed source, and over the model-selection variables in a managed `env` block, such as `ANTHROPIC_MODEL` and
  the `ANTHROPIC_DEFAULT_*_MODEL` family. Claude Code keeps a managed
  [`availableModels`](https://code.claude.com/docs/en/settings-reference#availablemodels) allowlist in force unless the
  app supplies its own.
  [settings › Exceptions to managed settings precedence](https://code.claude.com/docs/en/settings#exceptions-to-managed-settings-precedence)
- When `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST` is set, Claude Code ignores provider-selection, endpoint, and
  authentication variables in settings files.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Additional directories and worktrees

- Adding a directory extends where Claude can read and edit files. It doesn't make that directory a full configuration
  root: most `.claude/` configuration is not discovered from additional directories, though a few types are loaded as
  exceptions; skills, command files and subagents also load from `--add-dir` directories.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- Directories listed in `permissions.additionalDirectories` in a settings file grant file access only and don't load
  any of the configuration that `--add-dir` and `/add-dir` directories load.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- From directories added with `--add-dir` or `/add-dir`, these also load:
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)

  | Configuration | Loaded from `--add-dir` |
  | :- | :- |
  | [Settings](https://code.claude.com/docs/en/settings) in `.claude/settings.json` and `.claude/settings.local.json` | `enabledPlugins` and [`extraKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#extraknownmarketplaces) keys only |
  | [CLAUDE.md](https://code.claude.com/docs/en/memory) files, `.claude/rules/`, and `CLAUDE.local.md` | Only when `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` is set. `CLAUDE.local.md` additionally requires the `local` setting source, which is enabled by default |

## The global config file

- `~/.claude.json` is a fifth file that Claude Code writes for itself; you don't need to edit it. It holds your account
  details, [MCP server](https://code.claude.com/docs/en/mcp) configurations, and per-project state such as trust
  decisions.
  [settings › Find or create your settings files](https://code.claude.com/docs/en/settings#find-or-create-your-settings-files)
- When `CLAUDE_CONFIG_DIR` is set, `.claude.json` sits inside that directory; otherwise it's `~/.claude.json`. To keep
  it across container rebuilds, mount a volume at `~/.claude` and set `CLAUDE_CONFIG_DIR` to the same path; without
  `CLAUDE_CONFIG_DIR`, `~/.claude.json` stays in the home directory and is discarded on rebuild.
  [claude-directory › Explore the .claude directory](https://code.claude.com/docs/en/claude-directory#explore-the-directory)
  and [devcontainer › Persist authentication and settings across rebuilds](https://code.claude.com/docs/en/devcontainer#persist-authentication-and-settings-across-rebuilds)
- Global config keys are saved in `~/.claude.json`, not in a settings file. Claude Code ignores them anywhere else.
  Claude Code and `/config` write most of them for you, and you can also edit them by hand.
  [settings-reference › Global config settings](https://code.claude.com/docs/en/settings-reference#global-config-settings)

## Not stated by the documentation

- Whether managed settings still load when `--setting-sources` omits sources on the CLI. The documentation states it
  only for Agent SDK sessions ([managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)).
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

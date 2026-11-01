# Excluding skills

Stopping skills from loading or being seen: `skillOverrides`, `disableBundledSkills`,
`CLAUDE_CODE_DISABLE_POLICY_SKILLS`, `strictPluginOnlyCustomization`, `syncClaudeAiSkills`, removing a skill, and the
`--bare`, `--safe-mode` and `--disable-slash-commands` flags, and what blocks skills-directory plugins.

## Contents

- [`skillOverrides`](#skilloverrides)
- [Bundled skills](#bundled-skills)
- [Managed policy skills](#managed-policy-skills)
- [`strictPluginOnlyCustomization`](#strictpluginonlycustomization)
- [`syncClaudeAiSkills`](#syncclaudeaiskills)
- [Removing a skill](#removing-a-skill)
- [Skills-directory plugins](#skills-directory-plugins)
- [Session flags](#session-flags)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## `skillOverrides`

- The `skillOverrides` setting hides or collapses a skill without editing its `SKILL.md`, such as one checked into a
  shared project repo. Claude Code applies the value under each skill's name to the skill list Claude sees and to your
  `/` autocomplete. Scope: any file; default: unset, so every skill is `"on"`.
  [settings-reference › `skillOverrides`](https://code.claude.com/docs/en/settings-reference#skilloverrides),
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)
- Each key is a skill name and each value is one of four states. A skill absent from `skillOverrides` is treated as
  `"on"`. The `/skills` menu labels the `"user-invocable-only"` state `user-only`.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)

  | Value | Listed to Claude | In `/` menu |
  | :- | :- | :- |
  | `"on"` | Name and description | Yes |
  | `"name-only"` | Name only | Yes |
  | `"user-invocable-only"` | Hidden | Yes |
  | `"off"` | Hidden | Hidden |

  ```json
  {
    "skillOverrides": {
      "legacy-context": "name-only",
      "deploy": "off"
    }
  }
  ```

- `"off"` also hides the skill from the command lists advertised to Remote Control clients and to Agent SDK callers,
  in addition to the terminal `/` menu. Invoking a hidden skill by its full name returns the `skillOverrides` error
  instead of running it.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)
- The `/skills` menu writes the setting for you: highlight a skill and press `Space` to cycle states, then `Esc` to
  save to `.claude/settings.local.json`.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)
- The `/skills` menu can't cycle plugin skills, skills whose frontmatter sets `disable-model-invocation: true`, or
  skills with a `skillOverrides` entry in managed settings or the `--settings` flag.
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- In VS Code, typing `/skills` opens the slash commands dialog, where each skill row shows its visibility, such as
  **On** or **Name only**. Click the visibility to change it, except on rows marked **locked**, such as plugin skills.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)
- Plugin skills are not affected by `skillOverrides`; manage those through `/plugin` instead.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings),
  [settings-reference › `skillOverrides`](https://code.claude.com/docs/en/settings-reference#skilloverrides)
- Some bundled skills have aliases, such as `checkup` for `/doctor`. An entry under an alias in managed settings or in
  a file passed with `--settings` applies to the skill behind the alias. Through an alias you can only restrict a skill
  further, never make it more visible, and an entry under the skill's own name in managed settings takes precedence.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)
- In user, project, and local settings, Claude Code matches entries against skill names only: an entry for `review`
  there applies to a skill named `review`, not to the bundled `/code-review` through its `/review` alias.
  [skills › Override skill visibility from settings](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings)
- `/auto-mode-setup` is a built-in command rather than a bundled skill, so a `skillOverrides` entry such as
  `"auto-mode-setup": "off"` still applies to it, but `disableBundledSkills` doesn't turn it off.
  [auto-mode-config › Turn off `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#turn-off-auto-mode-setup)
- In a Claude apps gateway's `managed` policies, `skillOverrides` is a record-typed key: a matched policy's block
  shallow-merges onto the `match: {}` catch-all base, overriding the keys it sets and inheriting the rest.
  [claude-apps-gateway-config › `managed`](https://code.claude.com/docs/en/claude-apps-gateway-config#managed)

## Bundled skills

- `disableBundledSkills` set to `true` turns off the skills and workflows included with Claude Code: Claude Code
  removes bundled skills and workflows entirely, while built-in commands such as `/init` stay typable but are hidden
  from the model. Scope: any file; type: Boolean; default: unset, so bundled skills load.
  [settings-reference › `disableBundledSkills`](https://code.claude.com/docs/en/settings-reference#disablebundledskills),
  [skills › Bundled skills](https://code.claude.com/docs/en/skills#bundled-skills)

  ```json
  {
    "disableBundledSkills": true
  }
  ```

- `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` set to `1` turns bundled skills off for one session; whichever of it and
  `disableBundledSkills` turns them off, the other can't turn them back on.
  [settings-reference › `disableBundledSkills`](https://code.claude.com/docs/en/settings-reference#disablebundledskills)
- Skills from plugins, `.claude/skills/`, and `.claude/commands/` are unaffected by `disableBundledSkills`.
  [settings-reference › `disableBundledSkills`](https://code.claude.com/docs/en/settings-reference#disablebundledskills)
- The `/doctor` setup checkup stays typable when `disableBundledSkills` is on. To hide it, set a `skillOverrides`
  entry of `"doctor": "off"`, or set `DISABLE_DOCTOR_COMMAND` to `1`, which hides the `/doctor` skill and its
  `/checkup` alias but doesn't affect the `claude doctor` terminal command.
  [skills › Bundled skills](https://code.claude.com/docs/en/skills#bundled-skills),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- The `/doctor prompt-audit` instruction-file audit runs through the bundled `/claude-api` skill. It's unavailable
  while that skill is turned off in `skillOverrides` or with `disableBundledSkills`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)
- Claude Code's bundled skills include `/doctor`, `/code-review`, `/batch`, `/debug`, `/loop`, and `/claude-api`. The
  commands reference lists bundled skills alongside built-in commands, marked **Skill** in the Purpose column.
  [skills › Bundled skills](https://code.claude.com/docs/en/skills#bundled-skills)
- A bundled skill such as `/code-review` has its instructions built into Claude Code, so there is no `SKILL.md` file
  on disk to open or edit.
  [code-review-local › Change or build on the review](https://code.claude.com/docs/en/code-review-local#change-or-build-on-the-review)
- Bundled skills are prompt-based: they give Claude detailed instructions and let it orchestrate the work using its
  tools. Most built-in commands instead execute fixed logic directly.
  [skills › Bundled skills](https://code.claude.com/docs/en/skills#bundled-skills)
- Claude invokes some bundled skills automatically when relevant; others, including `/verify`, run only when you
  invoke them. Most bundled skills are available in every session, but `/workflow-authoring`, for example, is
  available only when dynamic workflows are enabled.
  [skills › Bundled skills](https://code.claude.com/docs/en/skills#bundled-skills)
- `CLAUDE_CODE_DISABLE_CFC_PROMPT` set to `1` keeps the Claude in Chrome browser tools available while omitting the
  Chrome section of the system prompt and the `/claude-in-chrome` bundled skill.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_DISABLE_CRON` set to `1` disables session-scoped scheduled tasks: the `/loop` skill and cron tools become
  unavailable and any already-scheduled tasks stop firing, including tasks that are already running mid-session.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Managed policy skills

- `CLAUDE_CODE_DISABLE_POLICY_SKILLS` set to `1` skips loading skills from the system-wide managed skills directory,
  for container or CI sessions that should not load operator-provisioned skills.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## `strictPluginOnlyCustomization`

- `strictPluginOnlyCustomization` has scope managed. Its type is `true`, to lock all four kinds of customization, or
  an array naming the kinds to lock, from `"skills"`, `"agents"`, `"hooks"`, and `"mcp"`. Default: unset, so nothing
  is locked. Claude Code ignores surface names it doesn't recognize rather than failing the settings
  file.
  [settings-reference › `strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization)
- Locking the `skills` surface stops Claude Code loading skills from `~/.claude/skills/` and `.claude/skills/`, custom
  commands from `~/.claude/commands/` and `.claude/commands/`, skills and commands under `--add-dir` directories, and
  skills synced from your claude.ai account. It keeps loading bundled skills, skills in the managed policy directory,
  and skills from plugins other than skills-directory plugins.
  [settings-reference › `strictPluginOnlyCustomization.skills`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-skills)

  ```json
  {
    "strictPluginOnlyCustomization": ["skills"]
  }
  ```

- These keys have their own fallback:
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)

  | Field | Behavior when present but invalid |
  | :- | :- |
  | `strictPluginOnlyCustomization` | Treated as `true`, locking all four surfaces, when the value is neither a boolean nor an array. An array entry that this version doesn't recognize as a surface locks nothing; a status note counts such entries so you can check them for typos. |

## `syncClaudeAiSkills`

- `syncClaudeAiSkills` set to `false` stops Claude Code downloading the skills enabled for your claude.ai account into
  `~/.claude/skills/synced/`, and stops it loading the ones already there. Claude Code honors only `false`: `true` is
  the same as unset and doesn't turn syncing on where it's otherwise off. Default: unset, so sessions signed in with
  your claude.ai account sync your skills.
  [settings-reference › `syncClaudeAiSkills`](https://code.claude.com/docs/en/settings-reference#syncclaudeaiskills)

  ```json
  {
    "syncClaudeAiSkills": false
  }
  ```

- In user or managed settings, `false` also moves the synced skills to `~/.claude/skills/.trash/`; with `false` in
  user settings, Claude Code does this the next time it starts.
  [settings-reference › `syncClaudeAiSkills`](https://code.claude.com/docs/en/settings-reference#syncclaudeaiskills),
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- Claude Code honors `false` from any managed source, `--settings`, `~/.claude/settings.json`, or
  `.claude/settings.local.json`, even when the winning managed source sets `true`; a `false` in
  `.claude/settings.json` is ignored, so a repository can't turn syncing off for you. Claude Code reads the key from
  every admin source, and it can only deny.
  [settings › Exceptions to managed settings precedence](https://code.claude.com/docs/en/settings#exceptions-to-managed-settings-precedence),
  [managed-settings › Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source),
  [settings-reference › `syncClaudeAiSkills`](https://code.claude.com/docs/en/settings-reference#syncclaudeaiskills)
- Your organization can turn syncing off for everyone by turning off Skills on claude.ai, or, to stop syncing while
  leaving Skills on, set `syncClaudeAiSkills` in managed settings.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- If your organization turns Skills off on claude.ai, Claude Code removes the downloaded skills and they stop loading.
  They move to `~/.claude/skills/.trash/`.
  Once your organization turns Skills back on, Claude Code downloads the skills you enabled at the next sync.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)

## Removing a skill

- How you remove a skill depends on where it came from:
  [skills › Remove a skill](https://code.claude.com/docs/en/skills#remove-a-skill)
  - **Personal or project skill**: delete its directory, `~/.claude/skills/<skill-name>/` or
    `.claude/skills/<skill-name>/`. Claude Code drops it from `/skills` in the current session; content already loaded
    from it follows the skill content lifecycle.
  - **Enterprise skill**: an administrator deletes its directory from `.claude/skills/` inside the managed settings
    directory, for example `/etc/claude-code/.claude/skills/<skill-name>/` on Linux.
  - **Plugin skill**: disable or uninstall the plugin that provides it, from the `/plugin` menu or with
    `/plugin uninstall <plugin-name>@<marketplace-name>`. Claude Code unloads the plugin's skills when the change
    applies or when you restart.
  - **Skill synced from claude.ai**: turn the skill off for your claude.ai account. Claude Code removes it from
    `~/.claude/skills/synced/` at the next sync. If you delete the directory by hand instead, the next sync downloads
    it again while the skill stays enabled on claude.ai.
  - **Bundled skill**: set `disableBundledSkills` to `true` to turn off bundled skills, or set one skill to `"off"` in
    `skillOverrides` to hide it.
- `/plugin-authoring` is a skill from a built-in plugin, which you can turn off in `/plugin`.
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- To keep a personal or project skill but stop Claude from invoking it on its own, set
  `disable-model-invocation: true` in its frontmatter, or `"user-invocable-only"` in `skillOverrides` when you don't
  want to edit the file.
  [skills › Remove a skill](https://code.claude.com/docs/en/skills#remove-a-skill)

## Skills-directory plugins

- Skills-directory plugins are folders under `~/.claude/skills/` or a project's `.claude/skills/` that carry a
  `.claude-plugin/plugin.json`. They come from you or your repository rather than from a marketplace. Claude Code skips
  them when your administrator sets one of these restrictions in managed settings:
  [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings),
  [plugins/org › Keep skills-directory plugins loading](https://code.claude.com/docs/en/plugins/org#keep-skills-directory-plugins-loading),
  [settings-reference › Allowed source types](https://code.claude.com/docs/en/settings-reference#allowed-source-types),
  [plugins/org › Blocklist with `blockedMarketplaces`](https://code.claude.com/docs/en/plugins/org#blocklist-with-blockedmarketplaces),
  [settings-reference › `blockedMarketplaces`](https://code.claude.com/docs/en/settings-reference#blockedmarketplaces)
  - **Customization locked to plugins**: `strictPluginOnlyCustomization` set to `true` or to an array naming one or
    more kinds of customization to lock. Claude Code treats skills-directory plugins as user customization, since
    users place the folders themselves. It skips the whole plugin when any one kind is locked, such as `mcp`,
    whichever components it has, and whether or not the `{ "source": "skills-dir" }` entry is present.
    [settings-reference › `strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization),
    [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings),
    [plugins/org › Keep skills-directory plugins loading](https://code.claude.com/docs/en/plugins/org#keep-skills-directory-plugins-loading)
  - **Marketplace sources restricted**: a `strictKnownMarketplaces` allowlist without a `{ "source": "skills-dir" }`
    entry, where any allowlist counts, even an empty one. It stops them loading from both `~/.claude/skills/` and
    a project's `.claude/skills/`.
  - **Skills-directory plugins blocklisted**: a `blockedMarketplaces` list with a `{ "source": "skills-dir" }` entry.
    It stops them loading from both locations without restricting any marketplace.
- A skipped folder produces no error: `/plugin` and `claude plugin list` show no plugin and no error. Its
  `/<name>:<skill>` commands and agents are missing, as are its hooks and MCP servers.
  [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings)
- Unless skills are among the locked kinds, a `SKILL.md` at the skipped folder's root still loads as a plain skill. In
  that case `/<name>` keeps working, and the `/plugin` **Installed** tab lists that skill under **Skills**.
  [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings)
- To confirm the cause, run `/status` in a Claude Code session. If the `Setting sources` line lists
  `Enterprise managed settings`, ask your administrator whether one of these settings applies to you.
  [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings)
- To load the whole plugin, add it to a marketplace your organization allows and install it from there. To load it for
  one session instead, start `claude` from your shell with `--plugin-dir` and the folder's path, which works unless
  your administrator has also turned off that flag.
  [plugins/loading › Skills-directory plugins blocked by managed settings](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings)
- To keep skills-directory plugins loading, add the `{ "source": "skills-dir" }` entry to the `strictKnownMarketplaces`
  allowlist and leave `strictPluginOnlyCustomization` unset. The entry has no meaning outside
  `strictKnownMarketplaces` and `blockedMarketplaces`, and the allowlist doesn't apply to plain skills, meaning a
  `SKILL.md` without that manifest.
  [settings-reference › Allowed source types](https://code.claude.com/docs/en/settings-reference#allowed-source-types),
  [plugins/org › Keep skills-directory plugins loading](https://code.claude.com/docs/en/plugins/org#keep-skills-directory-plugins-loading)
- A `{ "source": "skills-dir" }` entry in `strictKnownMarketplaces` matches no marketplace.
  [plugins/org › Allowlist with `strictKnownMarketplaces`](https://code.claude.com/docs/en/plugins/org#allowlist-with-strictknownmarketplaces)
- `claude plugin init` or `claude plugin enable` stops with
  `Plugins from ~/.claude/skills/ are blocked by your organization's managed settings` when managed settings block the
  `skills-dir` source. The message names `strictKnownMarketplaces or blockedMarketplaces` and asks your administrator
  to add `{"source":"skills-dir"}` to `strictKnownMarketplaces` or remove it from `blockedMarketplaces`.
  [plugins/troubleshooting › `Plugins from ~/.claude/skills/ are blocked by your organization's managed settings`](https://code.claude.com/docs/en/plugins/troubleshooting#plugins-from-claude-skills-are-blocked-by-your-organizations-managed-s)

## Session flags

- `--disable-slash-commands` disables all skills and commands for the session.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- `--bare` skips auto-discovery of skills and custom commands. It sets `CLAUDE_CODE_SIMPLE`. Skills in a directory you
  pass with `--add-dir` still load: bare mode loads skills from its `.claude/skills/` folder, but still skips its
  `.claude/commands/` folder.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags),
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- Setting `CLAUDE_CODE_SIMPLE` to `1` directly is equivalent to `--bare`: it disables auto-discovery of skills and
  custom commands, and skills in a directory you pass with `--add-dir` still load.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- With `--safe-mode`, skills and custom commands do not load. Managed settings policy still applies, but managed skills
  do not load. It sets `CLAUDE_CODE_SAFE_MODE`.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- Setting `CLAUDE_CODE_SAFE_MODE` to `1` directly is equivalent to `--safe-mode`: skills and custom commands do not
  load, and while managed settings policy still applies, managed skills do not.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Not stated by the documentation

- Stated for `/auto-mode-setup`; the documentation does not say whether `skillOverrides` applies to other built-in
  commands.
  [auto-mode-config › Turn off `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#turn-off-auto-mode-setup)
- The documentation does not say whether a `--setting-sources` list without `user` or `project` stops skills you
  wrote yourself in `~/.claude/skills/` or `.claude/skills/` loading in the CLI; it says only that such a list
  without `user` stops syncing skills from claude.ai, and that `--add-dir` skill loads depend on `project`. The
  excluded Agent SDK skills page states it for the SDK.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags),
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load),
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- In bare mode Claude isn't given the list of available skills, including skills from an `--add-dir` folder; the
  documentation does not say whether Claude can invoke such a skill anyway.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- The documentation does not say which settings file the VS Code skills dialog writes when you change a skill's
  visibility.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)

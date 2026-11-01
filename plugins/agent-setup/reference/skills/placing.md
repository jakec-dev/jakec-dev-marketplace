# Placing skills

Deciding where a skill or command file goes and what it is called: locations, command files, nested and monorepo
directories, worktrees, symlinks, reserved names, name clashes, command names, plugin skill layout, and the recorded
`/run` and `/verify` recipes.

## Contents

- Locations
- Command files
- Monorepos, nested directories and worktrees
- Reserved names
- Refused characters in names
- Skills that share a name
- Run a same-named skill from an added directory
- Synced skills that share a name
- Command names
- Plugin skill layout
- Recorded run and verify recipes
- Not stated by the documentation

## Locations

- A skill is a `SKILL.md` file with instructions; Claude uses skills when relevant, or you invoke one directly with
  `/skill-name`. Claude Code skills follow the Agent Skills open standard (agentskills.io) and extend it
  with features such as invocation control, subagent execution and dynamic context injection.
  [skills › Extend Claude with skills](https://code.claude.com/docs/en/skills)
- Where you save a skill decides which sessions load it.
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)

  | Location | Path | Loads in |
  | :- | :- | :- |
  | Enterprise | `.claude/skills/<skill-name>/SKILL.md` in the [managed settings directory](https://code.claude.com/docs/en/managed-settings#delivery-mechanisms) | All users on machines where your organization deploys it |
  | Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects on this machine, but not [Cowork or cloud sessions](https://code.claude.com/docs/en/skills#skills-in-cowork-and-cloud-sessions) |
  | Project | `.claude/skills/<skill-name>/SKILL.md` | Sessions in this repository, but not [cloud threads in a project](https://code.claude.com/docs/en/claude-projects#what-threads-pick-up-from-your-repositories). Commit it so your team gets it too |
  | Nested | `<subdir>/.claude/skills/<skill-name>/SKILL.md` | Sessions started in or below `<subdir>`, but not cloud threads in a project. Outside those threads, a session started above it loads the skill once Claude works on files there. See [monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories) |
  | Additional directory | `.claude/skills/<skill-name>/SKILL.md` in a directory you pass with `--add-dir` | That session. See [directories outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories) |
  | Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Wherever the [plugin](https://code.claude.com/docs/en/plugins/overview) is enabled, as `/plugin-name:skill-name` |
  | claude.ai account | Skills enabled for your claude.ai account | Cowork sessions, cloud sessions, and terminal sessions where you sign in with that account. See [Skills synced from claude.ai](https://code.claude.com/docs/en/skills#how-synced-skills-behave) |

- The `.claude` directory file reference gives `skills/<name>/SKILL.md` and `commands/*.md` project and global
  scope, and marks both for commit.
  [claude-directory › File reference](https://code.claude.com/docs/en/claude-directory#file-reference)
- Symlinked folders: a `<skill-name>` entry in the enterprise, personal, or project location can be a symlink to a
  directory elsewhere on disk. Claude Code reads `SKILL.md` from the target and loads the skill once even if several
  locations point at the same target. Plugin skills
  [handle symlinks differently](https://code.claude.com/docs/en/plugins/host-marketplace#share-files-within-a-marketplace-with-symlinks).
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- Skill folder as a plugin: add a `.claude-plugin/plugin.json` to a personal or project skill folder and it loads as
  a plugin named `<name>@skills-dir`, so it can bundle agents, hooks, and MCP servers. In a project's
  `.claude/skills/`, this requires accepting the workspace trust dialog first, and in either location it requires
  that your administrator hasn't [blocked skills-directory plugins](https://code.claude.com/docs/en/plugins/loading#skills-directory-plugins-blocked-by-managed-settings).
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- A plugin in your repository's `.claude/skills/` at the repository root doesn't load when you launch from a
  subdirectory. Claude Code reads the `.claude/skills/` of the session's primary working directory and, unlike plain
  skills and commands, doesn't search parent directories for plugins. Launch from the repository root instead, or
  move the session there with `/cd`.
  [plugins/loading › Check why a repository plugin didn't load](https://code.claude.com/docs/en/plugins/loading#check-why-a-repository-plugin-didnt-load)
- When a skills-directory plugin shares a manifest name with another enabled plugin, the result between these
  origins is as follows; each dropped copy gets a row in the `/plugin` **Errors** tab.
  [plugins/loading › Name conflicts](https://code.claude.com/docs/en/plugins/loading#name-conflicts)
  - An enabled `--plugin-dir`, `--plugin-url`, or `CLAUDE_CODE_PLUGIN_DIRS` plugin replaces it, with a row that
    reads `Not loaded — the name "<name>" is already taken by a session-only plugin (--plugin-dir / --plugin-url),
    which takes precedence`.
  - An installed marketplace plugin of the same name wins, and the skills-directory plugin gets the same
    `Not loaded` row, naming the installed plugin.
  - Between two skills-directory plugins, the copy under `~/.claude/skills/` loads and the project's
    `.claude/skills/` copy is dropped, with a row that says which path shadowed it.
- A disabled session-only plugin doesn't shadow, so the skills-directory copy loads. To keep a `--plugin-dir`
  plugin from shadowing anything, or to turn one off when a parent process passes the flag for you, set its id to
  `false` in any settings file; for a plugin whose manifest name is `hello-plugin`, the entry is
  `"enabledPlugins": {"hello-plugin@inline": false}`.
  [plugins/loading › Keep a session-only plugin from loading](https://code.claude.com/docs/en/plugins/loading#keep-a-session-only-plugin-from-loading)
- A project-scope plugin, including a skills-directory plugin in `.claude/skills/`, loads only after the same trust
  check that applies to project allow rules in `.claude/settings.json`: in a folder you haven't trusted, it loads
  only after you accept the workspace trust dialog for that folder. Trusting only a parent folder (no trust dialog is
  offered) or running `claude -p` or the SDK in a folder you never trusted isn't enough. The parent-folder case
  doesn't apply inside a nested repository: an interactive session shows the trust dialog for it, and a `claude -p`
  or SDK run there follows the `claude -p` case. The trust check doesn't apply to a plugin under your own
  `~/.claude/skills/`.
  [plugins/loading › Trust check and component limits for repository plugins](https://code.claude.com/docs/en/plugins/loading#trust-check-and-component-limits-for-repository-plugins)
  [plugins/loading › Check why a repository plugin didn't load](https://code.claude.com/docs/en/plugins/loading#check-why-a-repository-plugin-didnt-load)
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- The sandbox denies sandboxed commands writes to the `.claude/skills` and `.claude/commands` directories in your
  working directory and the directories above it, even inside directories they can write to. An `allowWrite` entry
  or `Edit` allow rule covering one of these paths doesn't lift the protection. To turn the protection off, set
  `filesystem.disabled`, which also turns off the rest of filesystem isolation. If you set
  `allowNestedUserNamespaces` to `true` on Linux or WSL2, don't rely on protected paths: code from a sandboxed command
  can end up running outside the sandbox.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)

## Command files

- A file at `.claude/commands/deploy.md` and a skill at `.claude/skills/deploy/SKILL.md` both create `/deploy` and
  work the same way, and existing `.claude/commands/` files keep working. Skills add optional features: a directory
  for supporting files, frontmatter to control whether you or Claude invokes them, and the ability for Claude to
  load them automatically when relevant.
  [skills › Extend Claude with skills](https://code.claude.com/docs/en/skills)
- A Markdown file in `.claude/commands/` is the older format and still works. It supports the same frontmatter
  except `name` and `paths`. Prefer a skill for new work, since skills also support supporting files.
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- `/import` brings a supported coding agent's configuration into Claude Code, carrying over its commands and skills
  among other things.
  [memory › Migrate instructions from other tools](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)
- In a plugin, command files take the same frontmatter as skills, and skills supersede commands for new work. The
  plugin page doesn't give the `name` and `paths` exception.
  [plugins/components › Commands](https://code.claude.com/docs/en/plugins/components#commands)

## Monorepos, nested directories and worktrees

- Claude Code loads project skills from `.claude/skills/` in the directory where you start it and in every parent
  directory up to the repository root, so starting in `packages/frontend/` still picks up skills defined at the
  root.
  [skills › Load skills in monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)
- In a session running in a linked git worktree that you created with `--worktree` or `git worktree add`, Claude Code
  searches parent directories only up to the worktree root. When the worktree checkout has no `.claude/skills`
  directory at its root, Claude Code loads the main checkout's project skills instead.
  [skills › Load skills in monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)
- In a worktree with its own `.claude/skills` directory, only that copy loads. The same read-through of the main
  checkout covers `.claude/commands`.
  [worktrees › What worktrees share with the main checkout](https://code.claude.com/docs/en/worktrees#what-worktrees-share-with-the-main-checkout)
- When a nested skill's directory name matches another skill's name, both stay available. With a `deploy` skill at
  the repository root and another in `apps/web/.claude/skills/`:
  [skills › Load skills in monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)
  - `/deploy` runs the root skill. Claude Code also lists the directory-qualified variants for Claude, with an
    instruction to invoke the one whose directory holds the files it's working on, so the nested skill still applies
    to work in `apps/web/`.
  - `/apps/web:deploy` runs the nested skill on its own. Its description names the directory it applies to.

## Reserved names

- Don't name a skill folder `synced`, in any capitalization. Claude Code uses `~/.claude/skills/synced/` for skills
  downloaded from claude.ai and skips a skill you author at that name in the enterprise, personal, and project
  locations. [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- Claude Code reserves the name `anthropic-skills`, and every name inside that namespace such as
  `anthropic-skills:pdf`, for skills synced from claude.ai, in every session, whether or not you sign in with a
  claude.ai account.
  [skills › Names reserved for synced skills](https://code.claude.com/docs/en/skills#names-reserved-for-synced-skills)
  - A skill folder, a frontmatter `name`, a file or subfolder in `.claude/commands/`, or a saved workflow with that
    name doesn't load. Claude Code shows a startup notice in the conversation view rather than on stderr, naming what
    to change for the first item it refused: a folder or file to rename, a `name:` line to edit, or a workflow to
    rename. When more than one item was refused, the notice ends with a count such as `· 2 more`, and the debug log
    names each one. Rename the item or edit the `name:` line, then restart the session.
    [errors › A skill, command, or workflow wasn't loaded because its name is reserved](https://code.claude.com/docs/en/errors#a-skill-command-or-workflow-wasnt-loaded-because-its-name-is-reserved)

    ```text
    Not loaded: rename .claude/skills/anthropic-skills, then restart — its name uses "anthropic-skills", a name reserved for the skills synced from your claude.ai account
    ```
  - A plugin named `anthropic-skills` loads. When one of its skills and a synced skill are both named `<name>`,
    `/anthropic-skills:<name>` runs the synced skill.
  - An MCP server named `anthropic-skills` connects and its tools work, but its prompts don't appear as commands.
    Rename the server in your MCP configuration to list them.

## Refused characters in names

- Claude Code refuses a command name or a frontmatter `name` that contains characters such as these:
  [skills › Characters a skill name can't hold](https://code.claude.com/docs/en/skills#characters-a-skill-name-cant-hold)
  - A zero-width space or a control character
  - A private-use or unassigned character, such as a glyph from an icon font
  - A character that changes the direction of the text around it
  - A blank other than one plain space between words, such as a no-break space, two spaces in a row, or a space at
    the start or end
  - `<` or `>`

  A name over 256 characters is refused too.
  [errors › Skill or command name refused](https://code.claude.com/docs/en/errors#skill-or-command-name-refused)
- A custom command or skill doesn't load when Claude Code refuses its directory or file name; outside a plugin, this
  includes a skill folder whose name has such a character. It's missing from the `/` menu and Claude can't invoke it.
  Rename that folder or file to remove the characters.
  [skills › Characters a skill name can't hold](https://code.claude.com/docs/en/skills#characters-a-skill-name-cant-hold)
  [errors › Skill or command name refused](https://code.claude.com/docs/en/errors#skill-or-command-name-refused)
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- A skill still loads when these characters are only in a plugin skill folder's name or in its frontmatter `name`:
  [skills › Characters a skill name can't hold](https://code.claude.com/docs/en/skills#characters-a-skill-name-cant-hold)
  - A folder in a plugin's `skills/` directory or its manifest's
    [`skills` paths](https://code.claude.com/docs/en/plugins/components#skills): you don't need to rename the folder.
    The characters become hyphens in the skill's command name, so type the command with the hyphens.
  - A frontmatter `name`: the `/` menu doesn't show the `name` value and typing it doesn't invoke the skill. Edit the
    `name:` line to remove the characters.
- An interactive session shows a startup notice when Claude Code refused the name of at least one skill or command:
  [errors › Skill or command name refused](https://code.claude.com/docs/en/errors#skill-or-command-name-refused)

  ```text
  1 skill or command name refused: run with --debug to see which ([names]), rename, then restart — a name may not hold hidden, direction-changing or blank-like characters, < or >, or be over 256 characters
  ```

  - For a skill or command that isn't loaded, its line in the debug log reads `<name> is not offered`.
  - For a skill whose frontmatter `name` is ignored, its line in the debug log reads
    `<name value> is not shown for <skill>`.
- To find which name was refused, start Claude Code with `claude --debug` from your shell and search the debug log
  for `[names]`. Each name the notice counts has one line there, and the line spells out some hidden characters as
  codes, such as `\u{200B}` for a zero-width space. After a rename or a `name:` edit, restart the session, unless
  the file is in a directory Claude Code watches for changes. For a skill from a plugin you didn't write, ask the
  plugin's author to rename it.
  [errors › Skill or command name refused](https://code.claude.com/docs/en/errors#skill-or-command-name-refused)
  [skills › Characters a skill name can't hold](https://code.claude.com/docs/en/skills#characters-a-skill-name-cant-hold)

## Skills that share a name

- When two skills share a directory or file name, where each one came from decides which one `/name` runs.
  [skills › Resolve skills that share a name](https://code.claude.com/docs/en/skills#resolve-skills-that-share-a-name)

  | Same name in | Which one runs |
  | :- | :- |
  | Two of enterprise, personal, and project | Enterprise over personal, and personal over project. With `deploy` in both `~/.claude/skills/` and the project's `.claude/skills/`, `/deploy` runs the personal one |
  | Any of those locations and a bundled skill | Your skill replaces the bundled command, but not its aliases. A project `code-review` skill replaces `/code-review`, and the bundled alias `/review` never runs your skill |
  | Any of those locations and a [built-in command](https://code.claude.com/docs/en/commands) | In a local terminal session, your skill replaces the built-in command, but not its aliases. A project `usage` skill replaces `/usage`, and the built-in alias `/cost` still runs the built-in command |
  | A skill and a file in `.claude/commands/` | The skill |
  | A project-root skill and a nested skill | Both load. See Monorepos, nested directories and worktrees |
  | An enterprise, personal, or project skill and a skill in an [added directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories) | The enterprise, personal, or project skill, while the added directory's skill runs under a prefixed name. See Run a same-named skill from an added directory |
  | Two [added directories](https://code.claude.com/docs/en/skills#skills-from-additional-directories) outside the project | The skill from the directory added first, in `--add-dir` or `/add-dir` order. The other runs under a prefixed name. See Run a same-named skill from an added directory |
  | A plugin skill and a skill at any of the locations above | Both load, because plugin skills are namespaced as `/plugin-name:skill-name` |
  | Any of the above and the short name of a skill synced from your claude.ai account | The other skill or command. The synced skill is then listed and runs only under its full name. See Synced skills that share a name |

## Run a same-named skill from an added directory

- An added directory's skill gets a prefix when its folder name clashes with an enterprise, personal, or project
  skill, or one in a directory added earlier. To run it, type `/<prefix>:<skill-name>` at the Claude Code prompt. The
  `/` menu lists the skill under its prefixed name. Where the prefix comes from is in the Command names table.
  [skills › Run a same-named skill from an added directory](https://code.claude.com/docs/en/skills#run-a-same-named-skill-from-an-added-directory)
- With `--add-dir ../cli` and a `verify` skill in both your project and `../cli`, `/verify` runs your project's
  skill and `/cli:verify` runs the skill from `../cli`.
  [skills › Run a same-named skill from an added directory](https://code.claude.com/docs/en/skills#run-a-same-named-skill-from-an-added-directory)

## Synced skills that share a name

- You can invoke a synced skill by its short name, `/<name>`, or by its full name, `/anthropic-skills:<name>`. When
  another command uses the short name, `/<name>` runs the other command, and the synced skill runs only as
  `/anthropic-skills:<name>`. With a local `deploy` skill and a synced `deploy`, `/deploy` runs the local skill.
  [skills › When a synced skill name matches another command](https://code.claude.com/docs/en/skills#when-a-synced-skill-name-matches-another-command)
- The command that uses the short name can be a built-in command or bundled skill (including one that's unavailable
  in your session, for example after you turn bundled skills off), a skill at any local level or a file in
  `.claude/commands/`, a plugin skill, or an MCP prompt.
  [skills › When a synced skill name matches another command](https://code.claude.com/docs/en/skills#when-a-synced-skill-name-matches-another-command)
- In the `/` menu, `/skills`, and `/context`, a synced skill appears under its short name, or under its full name
  while another command uses the short name. A note under the `/skills` list explains each synced skill that lost
  its short name; if one of your personal skills or command files in `~/.claude/` uses the name, the note also says
  what to rename or delete to free it.
  [skills › When a synced skill name matches another command](https://code.claude.com/docs/en/skills#when-a-synced-skill-name-matches-another-command)
- The `/skills` menu and `/context` group synced skills under `claude.ai sync`, and the `/` command menu marks them
  as coming from claude.ai.
  [skills › When a synced skill name matches another command](https://code.claude.com/docs/en/skills#when-a-synced-skill-name-matches-another-command)
- When it compares names, Claude Code ignores case, spacing, and invisible characters, and treats compatibility
  forms such as fullwidth letters and dash variants as their plain equivalents, so a synced `Commit` and a local
  `commit` count as the same name and `/commit` keeps running the local skill. A name that differs only by a
  look-alike letter from another alphabet counts as a different name; the `claude.ai sync` label tells the two
  apart.
  [skills › When a synced skill name matches another command](https://code.claude.com/docs/en/skills#when-a-synced-skill-name-matches-another-command)

## Command names

- The command you type comes from where the skill file lives and, for skill directories and plugin skills, from the
  frontmatter `name` field. In a personal or project skill directory, `name` sets the command that the `/` menu
  shows and that you type, unless another command already uses that name; the directory name also invokes the
  skill.
  [skills › How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)

  | Skill location | Command name source | Example |
  | :- | :- | :- |
  | Skill directory under `~/.claude/skills/` or `.claude/skills/` | Frontmatter `name` or the directory name | `.claude/skills/deploy-staging/SKILL.md` → `/deploy-staging`, or `/deploy` with `name: deploy` |
  | Nested `.claude/skills/` directory, when the directory name clashes with another skill | Subdirectory path relative to the working directory, then the skill directory name | `apps/web/.claude/skills/deploy/SKILL.md` → `/apps/web:deploy` |
  | `.claude/skills/` in an [added directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories), when the skill directory name clashes with an enterprise, personal, or project skill, or one in a directory added earlier | The added directory's folder name, then the skill directory name. When two added directories share a folder name, the prefix starts with the parent folder's name | `../cli/.claude/skills/verify/SKILL.md` with `--add-dir ../cli` → `/cli:verify`. With `--add-dir ../a/cli --add-dir ../b/cli`, a `verify` skill in each, and none elsewhere, the one in `../a/cli` → `/verify` and the other → `/b/cli:verify` |
  | File under `.claude/commands/` | File name without extension | `.claude/commands/deploy.md` → `/deploy` |
  | File in a subdirectory of `.claude/commands/` | Subdirectory path relative to `commands/` with each `/` replaced by `:`, then the file name without extension | `.claude/commands/frontend/component.md` → `/frontend:component` |
  | Plugin `skills/` subdirectory | Frontmatter `name` or the directory name, namespaced by plugin | `my-plugin/skills/review/SKILL.md` → `/my-plugin:review`, or `/my-plugin:fancy` with `name: fancy` |
  | Plugin root `SKILL.md` | Frontmatter `name`, with the plugin directory name as a fallback | `my-plugin/SKILL.md` with `name: review` → `/my-plugin:review` |
  | Skill synced from claude.ai | The skill's name on your claude.ai account, prefixed with `anthropic-skills:` | Account skill `deploy` → `/anthropic-skills:deploy`, or `/deploy` while no other command uses that name |

- In a plugin, a command file at `commands/<file>.md` becomes `/<plugin>:<file>`, and a subdirectory adds a segment,
  so `commands/db/migrate.md` is `/my-plugin:db:migrate`.
  [plugins/components › Commands](https://code.claude.com/docs/en/plugins/components#commands)
- For a plugin skill with `name: fancy`, the bare `/fancy` also invokes the skill unless another command already
  uses that name. If the `name` already starts with the plugin's own prefix, Claude Code doesn't add it again:
  `name: my-plugin:fancy` still becomes `/my-plugin:fancy`.
  [skills › How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)
- In non-interactive sessions, the names `help` and `feedback` aren't reserved for their terminal-only built-in
  commands, so a plugin skill with one of those names keeps its bare command there. Every other terminal-only
  built-in's name, such as `/login`, stays reserved even though the command can't run in those sessions.
  [skills › How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)
- For a plugin-root `SKILL.md`, there is no skill directory to take the name from, so `name` supplies the whole
  final segment.
  [skills › How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)
- In a plugin scaffolded by `claude plugin init my-tool`, the root skill at `~/.claude/skills/my-tool/SKILL.md` is
  also a personal skill, so you invoke it as `/my-tool`, not `/my-tool:my-tool`. Skills you add under `skills/`
  inside the plugin get the plugin-name prefix, such as `/my-tool:example`.
  [plugins/create › Name the plugin's skills](https://code.claude.com/docs/en/plugins/create#skill-names-in-a-scaffolded-plugin)

## Plugin skill layout

- In a plugin, save each skill in its own directory under `skills/`. Claude, the user, or both can invoke it,
  controlled by frontmatter.
  [plugins/components › Skills](https://code.claude.com/docs/en/plugins/components#skills)

  ```text
  my-plugin/
  ├── .claude-plugin/
  │   └── plugin.json
  └── skills/
      └── review/
          └── SKILL.md
  ```

- Additional skill directories listed in the `skills` manifest key add to the default `skills/` scan rather than
  replacing it, unlike `commands` and `agents`.
  [plugins/components › Skills](https://code.claude.com/docs/en/plugins/components#skills)
- With no `skills/` directory and no `skills` manifest key, a `SKILL.md` at the plugin root loads as one skill. Set
  `name` in its frontmatter, because otherwise a marketplace install names the skill after its cache directory
  rather than your plugin. [plugins/components › Skills](https://code.claude.com/docs/en/plugins/components#skills)
- A `skills` manifest entry is either a directory of `<name>/SKILL.md` folders or one folder holding `SKILL.md`
  directly. `"."` names the plugin root.
  [plugins/manifest-reference › Fields](https://code.claude.com/docs/en/plugins/manifest-reference#fields)
- The `skills` key takes one path or an array of paths, and its entries must be directories.
  [plugins/manifest-reference › Path-only fields](https://code.claude.com/docs/en/plugins/manifest-reference#path-only-fields)

  ```json
  { "skills": ["./extra-skills/", "."] }
  ```

- Every component path in a manifest is relative to the plugin root and must start with `./`; `skills` also accepts
  `"."`, and both `"."` and `"./"` denote the plugin root.
  [plugins/manifest-reference › Path rules](https://code.claude.com/docs/en/plugins/manifest-reference#path-rules)
- When a marketplace entry whose `source` is the marketplace root lists specific `skills` subdirectories, only those
  subdirectories load, and the plugin's default `skills/` directory isn't scanned.
  [plugins/manifest-reference › How entry fields combine with `plugin.json`](https://code.claude.com/docs/en/plugins/manifest-reference#how-entry-fields-combine-with-plugin-json)
- When Claude Code copies a plugin into its cache, it handles each symlink by where the target resolves: a target
  within the plugin's own directory is preserved as a relative symlink; a target elsewhere within the same
  marketplace is dereferenced and its content copied in its place, which lets a meta-plugin's `skills/` directory
  link to skills defined by other plugins in the marketplace; a target outside the marketplace is skipped for
  security. For plugins installed from a local path, or from a `command` source whose `mode` is the default `copy`,
  Claude Code preserves only symlinks that resolve within the plugin's own directory and skips all others.
  [plugins/host-marketplace › Share files within a marketplace with symlinks](https://code.claude.com/docs/en/plugins/host-marketplace#share-files-within-a-marketplace-with-symlinks)

  ```bash
  ln -s ../../shared-plugin/skills/foo ./skills/foo
  ```

  The example links from inside a marketplace plugin to a shared skill defined by a sibling plugin. On Windows, use
  `mklink /D` from an elevated Command Prompt or enable Developer Mode.

## Recorded run and verify recipes

- Three bundled skills launch your app and confirm changes against the running app instead of just tests.
  [skills › Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)

  | Skill | Purpose |
  | :- | :- |
  | `/run` | Launch and drive your app to see a change working |
  | `/verify` | Build and run your app to confirm a code change does what it should, without falling back to tests or type checks |
  | `/run-skill-generator` | Teach `/run` and `/verify` how to build and launch your project |

- `/run` and `/verify` work without setup, inferring the launch from your project type (CLI, server, TUI,
  browser-driven) and from your README, `package.json`, or `Makefile`. That inference gets unreliable for projects
  that need anything beyond a standard launch, such as a database, an env file, a graphical session, or a
  multi-step build.
  [skills › Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)
- `/run-skill-generator` gets your app running from a clean environment, captures what worked (the install
  commands, the env vars, the launch script), and commits it as a per-project skill at `.claude/skills/run-<name>/`.
  After that, `/run`, `/verify`, and any other agent in the repo follow the recorded recipe. Run it once per
  project, and again if the build or launch process changes.
  [skills › Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)
- When `/verify` has to build and drive your app without a recorded recipe, it writes what worked to
  `.claude/skills/verify/SKILL.md` at the repo root, or in the touched package directory in a monorepo. At the repo
  root, the recorded skill replaces the bundled `/verify`.
  [skills › Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)
- Claude edits the recorded file only when it steered a run wrong, such as a command that failed or a missing step,
  so you can commit the file without per-session diffs.
  [skills › Run and verify your app](https://code.claude.com/docs/en/skills#run-and-verify-your-app)

## Not stated by the documentation

- The `synced` folder name is said to be skipped in the enterprise, personal, and project locations; the
  documentation does not say whether it is skipped in a nested or `--add-dir` `.claude/skills/`.
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)
- Symlinked folders are stated for the enterprise, personal, and project locations; the documentation does not say
  whether a symlinked folder works in a nested or additional-directory `.claude/skills/`.
  [skills › Choose where skills load](https://code.claude.com/docs/en/skills#where-skills-live)

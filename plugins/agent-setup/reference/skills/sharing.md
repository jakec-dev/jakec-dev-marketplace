# Sharing skills

Getting skills to more people or sessions: committing them, plugins, managed deployment, added directories and skills
synced from claude.ai.

## Contents

- Scopes for sharing
- Added directories
- Skills synced from claude.ai
- What a synced skill can do
- Not stated by the documentation

## Scopes for sharing

- Skills can be distributed at different scopes depending on your audience:
  [skills › Share skills](https://code.claude.com/docs/en/skills#share-skills)
  - **Project skills**: Commit `.claude/skills/` to version control
  - **Plugins**: Create a `skills/` directory in your [plugin](https://code.claude.com/docs/en/plugins/overview)
  - **Managed**: Deploy organization-wide through [managed settings](https://code.claude.com/docs/en/managed-settings)

## Added directories

- When you add a directory with `--add-dir` or `/add-dir`, Claude Code loads the skills in that directory's
  `.claude/skills/`, along with its `.claude/commands/` and `.claude/agents/`. Directories the Agent SDK adds through
  `additionalDirectories` in TypeScript or `add_dirs` in Python load the same way, because the SDK passes them as
  `--add-dir`.
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- The `permissions.additionalDirectories` setting in `settings.json` grants file access only and loads none of these.
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- These loads depend on the `project` setting source, which is on by default. A `strictPluginOnlyCustomization`
  policy, bare mode, and `--safe-mode` each restrict them further.
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- Skills, commands, and subagents from any flag-added directory load through the `project` setting source, so they
  don't load when you exclude that source with `--setting-sources` on the CLI or `settingSources` in the SDK.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- Most `.claude/` configuration is not discovered from added directories. Skills and command files are among the
  exceptions, and the exceptions apply only to directories added with the `--add-dir` flag or the `/add-dir` command,
  including directories the Agent SDK adds through the flag.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)

  | Configuration | Loaded from `--add-dir` |
  | :- | :- |
  | [Skills](https://code.claude.com/docs/en/skills) in `.claude/skills/` | Yes, with live reload |
  | [Command files](https://code.claude.com/docs/en/skills#where-skills-live) in `.claude/commands/` | Yes, without live reload. When the added directory and your project both define a command with the same name, Claude Code runs your project's command |

- To load the skills, commands, and subagents from a subdirectory of your primary working directory mid-session, run
  `/add-dir` with that subdirectory's path. Claude Code loads them for the rest of the session without prompting you
  or adding a working directory, because the subdirectory is already readable.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)
- You already have file access to a subdirectory of the working directory, so `/add-dir` for one only loads its
  skills, commands, and agents. Before loading them, Claude Code checks that the directory's real location,
  with any symlinks resolved, is inside the working directory. When it can't resolve that location, it loads nothing
  and shows this message:
  [errors › Directory couldn't be resolved to a real location](https://code.claude.com/docs/en/errors#directory-couldnt-be-resolved-to-a-real-location)

  ```text
  packages/app couldn't be resolved to a real location, so its skills, commands, and agents weren't loaded. Check that it is a directory inside the working directory and try again.
  ```

  - Check that the path names a real directory inside the working directory, then run `/add-dir` again. The message
    doesn't change your file access; it only reports that the directory's `.claude/` content wasn't loaded.

## Skills synced from claude.ai

- If you use Cowork or cloud sessions, or sign in to Claude Code in your terminal with a claude.ai account, Claude Code
  loads the skills enabled for your claude.ai account, with no setup on your part. Those skills include the ones you
  create or turn on in your claude.ai settings, skills your organization provides there, and Anthropic's built-in
  skills such as `pdf` and `xlsx`.
  [skills › Skills synced from claude.ai](https://code.claude.com/docs/en/skills#how-synced-skills-behave)
- Claude Code downloads a synced skill from your account rather than reading a file you wrote on the machine where the
  session runs, so it applies rules to synced skills that don't apply to skills in the skills locations.
  [skills › Skills synced from claude.ai](https://code.claude.com/docs/en/skills#how-synced-skills-behave)
- In your terminal, Claude Code syncs those skills in sessions where you sign in with your claude.ai account. When the
  session starts, it downloads your account's skills into `~/.claude/skills/synced/` in the background, then checks
  claude.ai for changes while the session runs. When a check finds a skill was added, edited, or turned off on
  claude.ai, Claude Code adds, updates, or removes it in the running session without a restart.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- The checks run less often while the session is idle. While you or Claude work in the session, a check runs about
  every 10 minutes. While the session is idle, a check runs about every 40 minutes; when you type in the session
  again, Claude Code checks within a few minutes if the last check was more than 10 minutes ago.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- The sync never delays startup, because Claude waits for a skill's download only when it invokes that skill. A short
  non-interactive run can therefore finish before a newly added skill downloads, in which case a later session
  downloads it.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- `CLAUDE_CODE_SYNC_SKILLS`: set to `1` in non-interactive mode with the `-p` flag to make Claude Code download the
  skills enabled for your claude.ai account in that run and wait for the list of them, up to
  `CLAUDE_CODE_SYNC_SKILLS_WAIT_TIMEOUT_MS`, before it runs the first query. Requires claude.ai authentication. Set it
  only when a `-p` run needs your current skills on its first query.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_SYNC_SKILLS_WAIT_TIMEOUT_MS`: timeout in milliseconds for the first query to wait for the initial skill
  list when `CLAUDE_CODE_SYNC_SKILLS` is set (default: 5000). When exceeded, the first query runs with whichever
  skills have arrived.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Project and local settings can't set `CLAUDE_CODE_SYNC_SKILLS` in `env`: Claude Code drops it and logs a warning you
  can see with `claude --debug`. Set it in your shell, user settings, or managed settings instead.
  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)
- Claude Code syncs only in a session that signs in with your claude.ai account and fetches feature flags from
  Anthropic. It doesn't sync in these sessions:
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
  - A session that doesn't use a sign-in stored by `/login`, such as one that authenticates with an API key, or one
    where `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, or an `apiKeyHelper` script supplies the credential
  - A session that doesn't fetch feature flags. Claude Code skips the feature-flag fetch in these sessions, and with
    fetching off you can't sync the skills enabled for your claude.ai account into your terminal sessions:
    [env-vars › Features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching)
    - A session where you set `DISABLE_GROWTHBOOK`, `DISABLE_TELEMETRY`, `DO_NOT_TRACK`, or
      `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`. What each variable's row says about fetching:
      [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
      - `DISABLE_GROWTHBOOK`: `1` or `true` disables fetching; `0` or `false` leaves fetching on.
      - `DISABLE_TELEMETRY`: setting it to `0` or `false` still opts out; it also disables feature-flag fetching.
      - `DO_NOT_TRACK`: set to `1`, it has the same effect as `DISABLE_TELEMETRY`, including on fetching. Claude Code
        reads it as a standard boolean, so `0` leaves telemetry on.
      - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`: setting it to `0` or `false` still disables this traffic; it also
        disables feature-flag fetching.
    - A session on a third-party provider, such as Amazon Bedrock, Claude Platform on AWS, Google Cloud's Agent
      Platform, or Microsoft Foundry, unless a host platform that embeds Claude Code sets
      `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`
      [env-vars › Features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching)
    - A Claude apps gateway session
      [env-vars › Features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching)
  - A session in bare mode or one you start with `--safe-mode`
  - A session where your organization's managed settings lock skills to plugin sources, or one you start with a
    `--setting-sources` list that leaves out `user`
- If you sign in with `/login` during a session, restart Claude Code to start syncing.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- Skills that an earlier session synced stay on disk. Claude Code loads them in later sessions signed in to the same
  account, even when it can't reach claude.ai.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- Claude Code downloads synced skills and never uploads them. If you or Claude edit a file under
  `~/.claude/skills/synced/`, the change isn't saved to your claude.ai account, and a later sync can overwrite or
  remove it. To change a synced skill, update it on claude.ai; the next sync downloads the new version.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- To see which skills synced, run `/skills`; the menu lists them under `claude.ai sync`.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)
- Some of Anthropic's skills, such as `pdf` and `xlsx`, always sync. For the rest, turn a skill on or off in your
  skills settings on claude.ai to change whether it syncs.
  [skills › Where synced skills load](https://code.claude.com/docs/en/skills#where-synced-skills-load)

## What a synced skill can do

- A synced skill's frontmatter applies in every kind of session, so an `allowed-tools` grant goes through the normal
  permission flow, except where your organization sets `allowManagedPermissionRulesOnly`.
  [skills › How Claude Code handles the frontmatter of a synced skill](https://code.claude.com/docs/en/skills#how-claude-code-handles-the-frontmatter-of-a-synced-skill)
- Claude Code sanitizes the display text a synced skill supplies, such as its description. It removes control
  characters, and in text that reaches Claude, such as the description, it also escapes angle brackets so the text
  can't imitate Claude Code's internal formatting.
  [skills › How Claude Code handles the frontmatter of a synced skill](https://code.claude.com/docs/en/skills#how-claude-code-handles-the-frontmatter-of-a-synced-skill)
- What Claude Code does with a synced skill's body depends on where the session runs:
  [skills › How Claude Code handles the body of a synced skill](https://code.claude.com/docs/en/skills#how-claude-code-handles-the-body-of-a-synced-skill)
  - In a cloud session, the body keeps the behavior a local skill has, because the session runs in an isolated
    container.
  - In a Cowork session on your desktop, the body keeps the behavior a local skill has, except that Claude Code
    replaces every `!` command line with the `disableSkillShellExecution` placeholder, as it does for every skill you
    supply there.
  - In any other session on your machine, Claude Code doesn't run `!` commands, doesn't attach the files that `@`
    references name the way it does for a local skill, and doesn't substitute `${CLAUDE_PROJECT_DIR}` and
    `${CLAUDE_SESSION_ID}`, so the `@` references and both placeholders reach Claude as literal text.
    A `!` command line reaches Claude as literal text too, or as the `disableSkillShellExecution`
    placeholder when `disableSkillShellExecution` is on.

## Not stated by the documentation

- `CLAUDE_CODE_SYNC_SKILLS` is described for non-interactive runs with `-p`, and interactive terminal sessions sync
  without it; the documentation does not say whether setting it makes an interactive session's first query wait for
  the skill list.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

# Creating instruction files

For starting or editing instruction files with Claude Code's commands: `/init`, `CLAUDE_CODE_NEW_INIT`, migrating
from other tools, `/import`, `/memory` and the VS Code Customize menu.

## Contents

- Commands
- Generate a CLAUDE.md with `/init`
- The interactive flow: `CLAUDE_CODE_NEW_INIT`
- Migrate from other tools
- View and edit with `/memory`
- When `/import` or `claude import` is unavailable
- Edit in VS Code
- Not stated by the documentation

## Commands

| Command | Purpose |
| :- | :- |
| `/import [codex\|gemini\|cursor] [--dry-run] [--yes]` | Bring configuration from OpenAI Codex, Google Gemini CLI, or Cursor on your machine into Claude Code, including instruction files, MCP servers, commands, subagents, and skills. In [non-interactive mode](https://code.claude.com/docs/en/headless) with `-p`, `/import` lists what it found and gives you the command that confirms the import. Add `--dry-run` to preview without writing anything, or `--yes` to skip the interactive picker. Not available on Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, or Claude Platform on AWS, or through a [Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway#availability-and-limitations). Also unavailable when you turn off [feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching) |
| `/init` | Initialize project with a `CLAUDE.md` guide. Set `CLAUDE_CODE_NEW_INIT=1` for an interactive flow that also walks through skills, hooks, and personal memory files. If `/init` finds OpenAI Codex or Google Gemini CLI configuration, it offers to carry it over with `/import` |

In the commands table, `<arg>` indicates a required argument and `[arg]` indicates an optional one. Not every command
appears for every user. Availability depends on your platform, plan, and environment.
[commands › All commands](https://code.claude.com/docs/en/commands#all-commands)

## Generate a CLAUDE.md with `/init`

- Run `/init` to generate a starting CLAUDE.md automatically: Claude analyzes your codebase and creates a file with
  build commands, test instructions, and project conventions it discovers. Refine from there with instructions
  Claude wouldn't discover on its own.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- If a CLAUDE.md already exists, `/init` suggests improvements rather than overwriting it.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)

## The interactive flow: `CLAUDE_CODE_NEW_INIT`

- For an interactive multi-phase flow, set the `CLAUDE_CODE_NEW_INIT` environment variable to `1` before you run
  `/init`, in your shell or in the `env` block of a settings file. The variable only changes how `/init` runs, so
  you can leave it set.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- With it set, `/init` asks which artifacts to set up: CLAUDE.md files, skills, and hooks. It then explores your
  codebase with a subagent, fills in gaps via follow-up questions, and presents a reviewable proposal before writing
  any files.
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- Without `CLAUDE_CODE_NEW_INIT`, `/init` generates a CLAUDE.md automatically without prompting.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Migrate from other tools

- Running `/init` reads other tools' instruction files and incorporates the relevant parts into the generated
  `CLAUDE.md`:
  - Cursor rules in `.cursor/rules/` or `.cursorrules`
  - Copilot rules in `.github/copilot-instructions.md`
  - With `CLAUDE_CODE_NEW_INIT=1` set: `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/` or `.windsurfrules`, and
    `.clinerules`

  [memory › Migrate instructions from other tools](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)
- `/import` brings a supported coding agent's configuration into Claude Code: it appends a one-time copy of
  instruction files such as `AGENTS.md` to the matching `CLAUDE.md`, and carries over further configuration,
  including MCP servers and subagents.
  [memory › Migrate instructions from other tools](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)
- From a shell, `claude import [source]` starts an interactive session that runs `/import` to bring configuration
  from other coding agents into Claude Code. It accepts the same `--dry-run` and `--yes` options as the command.
  The documentation's example: `claude import codex --dry-run`.
  [cli-reference › CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands)

## View and edit with `/memory`

- `/memory` lists your CLAUDE.md, CLAUDE.local.md, and other memory file locations across user and project scopes,
  including user and project CLAUDE.md entries for files that don't exist yet. It also lets you toggle auto memory on
  or off and provides an option to open the auto memory folder.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)
- Selecting a file in `/memory` opens it in your editor; selecting one that doesn't exist yet creates it first.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)
- GUI editors such as VS Code open the file in a separate window, and you can keep using the session while it's
  open. Terminal editors such as Vim take over the terminal until you exit.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)
- When you ask Claude to remember something, like "always use pnpm, not npm" or "remember that the API tests require a
  local Redis instance," Claude saves it to auto memory. To add
  instructions to CLAUDE.md instead, ask Claude directly, like "add this to CLAUDE.md," or edit the file yourself
  via `/memory`.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)

## When `/import` or `claude import` is unavailable

- When Claude Code finds the import flow turned off, `claude import` exits with code 1 instead of starting the import
  and prints this message:

  ```text
  `claude import` is not yet available in this build. Run `claude` and use /mcp or edit ~/.claude/settings.json directly.
  ```

  [errors › claude import is not yet available in this build](https://code.claude.com/docs/en/errors#claude-import-is-not-yet-available-in-this-build)
- Claude Code turns `claude import` on through a feature flag it fetches from Anthropic and caches on disk; the message
  means the cached value is off. The usual causes:
  - You haven't started a session since installing, so Claude Code hasn't fetched the flag yet. The first
    `claude import` can print this even when the feature is available to you.
  - You use Claude Code through Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, or Claude Platform
    on AWS, or through a Claude apps gateway. Claude Code doesn't fetch feature flags in these sessions, so
    `/import` and `claude import` stay unavailable. For a third-party provider, the env-vars page adds an exception:
    Claude Code skips the fetch unless a host platform that embeds Claude Code sets
    `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`.
    [errors › claude import is not yet available in this build](https://code.claude.com/docs/en/errors#claude-import-is-not-yet-available-in-this-build),
    [feature-availability › Features available on every provider](https://code.claude.com/docs/en/feature-availability#features-available-on-every-provider),
    [env-vars › Features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching)
  - You set `DISABLE_TELEMETRY`, `DO_NOT_TRACK`, `DISABLE_GROWTHBOOK`, or
    [`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`](https://code.claude.com/docs/en/env-vars), which turn off
    feature-flag fetching, so `claude import` stays unavailable.

  [errors › claude import is not yet available in this build](https://code.claude.com/docs/en/errors#claude-import-is-not-yet-available-in-this-build)
- On a fresh installation, start `claude`, wait for the session to load, exit, and run `claude import` again.
  [errors › claude import is not yet available in this build](https://code.claude.com/docs/en/errors#claude-import-is-not-yet-available-in-this-build)
- Where feature-flag fetching stays off, set the configuration up yourself: add MCP servers with
  [`claude mcp add`](https://code.claude.com/docs/en/mcp#installing-mcp-servers), and create the
  [`CLAUDE.md` files](https://code.claude.com/docs/en/memory#how-claude-md-files-load),
  [skills and commands](https://code.claude.com/docs/en/skills#where-skills-live), and
  [subagents](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope) you want to carry over. The
  message also names `~/.claude/settings.json`; of the configuration `claude import` carries, that file holds only
  the [permission mode](https://code.claude.com/docs/en/settings-reference#permission-settings), and Claude Code
  doesn't read MCP servers from it.
  [errors › claude import is not yet available in this build](https://code.claude.com/docs/en/errors#claude-import-is-not-yet-available-in-this-build)

## Edit in VS Code

- In VS Code, click `/` or type `/` in the prompt box to open the command menu, then select **Instructions** in its
  Customize section to edit the
  [CLAUDE.md files](https://code.claude.com/docs/en/memory#claude-md-files) Claude reads. Pick a file to open it in
  the editor. If the file doesn't exist yet, Claude Code creates it first.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)

## Not stated by the documentation

- `claude import codex` is shown and `claude import` runs `/import`; the documentation does not say whether
  `gemini` and `cursor` are accepted as for `/import`, or what `claude import` does with no source.
  [cli-reference › CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands)
- Which path `/init` writes a new CLAUDE.md to: a project CLAUDE.md can be `./CLAUDE.md` or `./.claude/CLAUDE.md`,
  and the `/init` Tip says only that Claude "creates a file".
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
- Which `CLAUDE.md` counts as "the matching `CLAUDE.md`" that `/import` appends to, such as `./CLAUDE.md` or
  `./.claude/CLAUDE.md`.
  [memory › Migrate instructions from other tools](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)
- Whether the "other memory file locations" `/memory` lists include `.claude/rules/` files.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)

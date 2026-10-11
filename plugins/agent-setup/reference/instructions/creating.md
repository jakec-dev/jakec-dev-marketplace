# Creating instruction files

For starting or editing instruction files with Claude Code's commands: `/init`, `CLAUDE_CODE_NEW_INIT`, migrating
from other tools, `/import`, `/memory` and the VS Code Customize menu.

## Commands

| Command | Purpose |
| :- | :- |
| `/import [codex\|gemini\|cursor] [--dry-run] [--yes]` | Bring configuration from OpenAI Codex, Google Gemini CLI, or Cursor on your machine into Claude Code, including instruction files, MCP servers, commands, subagents, and skills. In [non-interactive mode](https://code.claude.com/docs/en/headless) with `-p`, `/import` lists what it found and gives you the command that confirms the import. Add `--dry-run` to preview without writing anything, or `--yes` to skip the interactive picker. Not available on Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, or Claude Platform on AWS, or through a [Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway#availability-and-limitations). Also unavailable when you turn off [feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching) |
| `/init` | Initialize project with a `CLAUDE.md` guide. Set `CLAUDE_CODE_NEW_INIT=1` for an interactive flow that also walks through skills, hooks, and personal memory files. If `/init` finds OpenAI Codex or Google Gemini CLI configuration, it offers to carry it over with `/import` |

In the table, `<arg>` indicates a required argument and `[arg]` indicates an optional one. Not every command appears
for every user: availability depends on your platform, plan, and environment.
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
  instruction files such as `AGENTS.md` to the matching `CLAUDE.md`, and carries over MCP servers, commands,
  subagents, and skills.
  [memory › Migrate instructions from other tools](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)
- From a shell, `claude import [source]` starts an interactive session that runs `/import` to bring configuration
  from other coding agents into Claude Code. It accepts the same `--dry-run` and `--yes` options as the command.
  Example: `claude import codex --dry-run`.
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
- When you ask Claude to remember something, like "always use pnpm, not npm", Claude saves it to auto memory. To add
  instructions to CLAUDE.md instead, ask Claude directly, like "add this to CLAUDE.md", or edit the file yourself
  via `/memory`.
  [memory › View and edit with /memory](https://code.claude.com/docs/en/memory#view-and-edit-with-/memory)

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

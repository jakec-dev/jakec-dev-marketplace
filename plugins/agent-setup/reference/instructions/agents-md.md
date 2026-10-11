# AGENTS.md

Having Claude read `AGENTS.md`: which files stop it, the **Project instructions** values, when support is
unavailable, how it differs from CLAUDE.md, earlier workarounds, and the import versus the symlink.

## Contents

- [When Claude reads AGENTS.md](#when-claude-reads-agentsmd)
- [Project instructions setting](#project-instructions-setting)
- [When AGENTS.md support is unavailable](#when-agentsmd-support-is-unavailable)
- [Where AGENTS.md differs from CLAUDE.md](#where-agentsmd-differs-from-claudemd)
- [Earlier workarounds](#earlier-workarounds)
- [Import or symlink](#import-or-symlink)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## When Claude reads AGENTS.md

- Claude Code can read `AGENTS.md` as your project instructions, so a repository already set up for other coding
  agents works without adding a `CLAUDE.md`, an import, or a setting. Claude Code can load it on its own or alongside
  `CLAUDE.md`. An `AGENTS.md` lives in the project root, `.claude/`, or any directory.
  [memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md),
  [claude-directory › What's not shown](https://code.claude.com/docs/en/claude-directory#what’s-not-shown)
- By default, Claude reads `AGENTS.md` only when you have no `CLAUDE.md` in your working directory or above it. A
  `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in your working directory or any directory above it counts,
  so Claude reads it instead of `AGENTS.md`. `~/.claude/CLAUDE.md`, your organization's managed `CLAUDE.md`, and
  `.claude/rules/` files don't count, and keep loading alongside `AGENTS.md`. A `CLAUDE.md` that already imports
  `AGENTS.md` has Claude read your `CLAUDE.md`, with `AGENTS.md` included through the import.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md),
  [memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)
- When none count, Claude reads every `AGENTS.md` and `.claude/AGENTS.md` in your working directory and the
  directories above it at session start; an interactive session shows a line such as
  `no CLAUDE.md found; AGENTS.md loaded: /home/you/repo/AGENTS.md`. It reads a subdirectory's `AGENTS.md` when
  Claude opens a file there with the Read tool and that subdirectory has none of the three `CLAUDE.md` files.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- Inside each `AGENTS.md`, `@path` imports are expanded, `claudeMdExcludes` patterns apply, and subagents that skip
  project instructions skip these files too. Claude doesn't read `AGENTS.local.md`, `AGENTS.override.md`, or
  anything under a `.agents/` directory.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- Because `CLAUDE.local.md` counts, adding one to keep your own uncommitted instructions in a project that relies on
  `AGENTS.md` stops Claude from reading `AGENTS.md` for you. To keep your `CLAUDE.local.md` and still have Claude
  read `AGENTS.md`, set **Project instructions** to `claude-md-and-agents-md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)

## Project instructions setting

- To change the default, for example to have Claude always read both files, read only `CLAUDE.md`, or read only your
  organization's managed instructions, type `/config` in a session to open the settings panel, then set **Project
  instructions** to one of `claude-md-or-agents-md`, `claude-md-and-agents-md`, `claude-md` or `managed-only`:
  [memory › AGENTS.md](https://code.claude.com/docs/en/memory#agents-md),
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

  | Value | What Claude reads |
  | :- | :- |
  | `claude-md-or-agents-md` | Your `CLAUDE.md` files, or your `AGENTS.md` files when you have no `CLAUDE.md` or `CLAUDE.local.md` in your working directory or above it. This is the default |
  | `claude-md-and-agents-md` | Your `CLAUDE.md` and `AGENTS.md` files together, each directory's `CLAUDE.md` files first and its `AGENTS.md` after them. Claude Code skips an `AGENTS.md` it has already loaded, so one that your `CLAUDE.md` imports or symlinks to isn't read twice |
  | `claude-md` | Your `CLAUDE.md` files only |

- You can also set the value in a settings file instead of `/config`: add it under the built-in `agents-md` plugin's
  ID in `pluginConfigs`, in `~/.claude/settings.json`, a `--settings` file, or managed settings. Claude Code ignores
  it in project and local settings files. The setting is `pluginConfigs["agents-md@builtin"].options.instructionFiles`;
  this example has Claude read both files:
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load),
  [settings-reference › pluginConfigs](https://code.claude.com/docs/en/settings-reference#pluginconfigs)

  ```json
  {
    "pluginConfigs": {
      "agents-md@builtin": {
        "options": { "instructionFiles": "claude-md-and-agents-md" }
      }
    }
  }
  ```

- A change to **Project instructions** applies from the next message you send and in every new session.
  [memory › Choose which instruction files load](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)

## When AGENTS.md support is unavailable

- Claude reads `CLAUDE.md` files only, and **Project instructions** doesn't appear in the `/config` settings panel,
  in these sessions. To give Claude your `AGENTS.md` in any of them, import it from a `CLAUDE.md`.
  [memory › When AGENTS.md support is unavailable](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable)
  - You disabled the built-in `agents-md` plugin in `/plugin`.
  - In some cases, your first session after you upgrade from a Claude Code version that couldn't read `AGENTS.md`
    directly. Claude reads `AGENTS.md` from your next session on.
- Sessions such as those on Amazon Bedrock or with telemetry disabled aren't limited to `CLAUDE.md` files.
  [memory › When AGENTS.md support is unavailable](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable)
- The built-in mod that reads `AGENTS.md`, by the name `/plugin` shows:
  [plugins/mods/overview › Mods built into Claude Code](https://code.claude.com/docs/en/plugins/mods/overview#mods-built-into-claude-code)

  | Name in `/plugin` | What it does | Where it's on | How to turn it off |
  | :- | :- | :- | :- |
  | `cc-plugin-agents-md` | Loads `AGENTS.md` as project instructions | Every session, apart from the ones that can't read `AGENTS.md` | Disable it in `/plugin`, or choose which instruction files load |

- The settings and flags that stop installed mods, such as `disableAllHooks`, `--bare`, and `--safe-mode`, don't stop
  built-in mods.
  [plugins/mods/overview › Mods built into Claude Code](https://code.claude.com/docs/en/plugins/mods/overview#mods-built-into-claude-code)

## Where AGENTS.md differs from CLAUDE.md

- An `AGENTS.md` that Claude reads through the **Project instructions** setting differs from a `CLAUDE.md` in these
  places:
  [memory › Where AGENTS.md differs from CLAUDE.md](https://code.claude.com/docs/en/memory#where-agents-md-differs-from-claude-md)

  | | `CLAUDE.md` | `AGENTS.md` read through the setting |
  | :- | :- | :- |
  | Directories you add with `--add-dir` while `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` is set | Their `CLAUDE.md` loads | Their `AGENTS.md` doesn't load |
  | An `@path` import of a file outside your working directory | Claude Code asks you to approve external imports | Loads only if you already approved external imports for this project, with no prompt |

## Earlier workarounds

- For a setup made to have Claude Code read `AGENTS.md` before it did so on its own:
  [memory › Remove an earlier AGENTS.md workaround](https://code.claude.com/docs/en/memory#remove-an-earlier-agents-md-workaround)
  - **A `CLAUDE.md` containing `@AGENTS.md`**: you can leave it. Keeping the import never makes Claude read
    `AGENTS.md` twice, whichever **Project instructions** value you use. Remove the `CLAUDE.md` if it holds nothing
    else, or keep it if some of your sessions can't load `AGENTS.md` directly.
  - **A `CLAUDE.md` that tells Claude in words to read `AGENTS.md`**: Claude sees `AGENTS.md` only if it decides to
    open the file. Delete the `CLAUDE.md` so Claude reads `AGENTS.md` directly, or replace the sentence with an
    `@AGENTS.md` import.
  - **A `CLAUDE.md` symlinked to `AGENTS.md`**: nothing, or delete the symlink. Either way Claude reads the content
    once.
  - **A `SessionStart` hook that prints `AGENTS.md`**: remove it. Once Claude reads `AGENTS.md` directly, the hook
    adds a second copy to the context.

## Import or symlink

- When Claude isn't reading your `AGENTS.md` directly, you can still keep it as the one file every tool shares by
  putting an `@AGENTS.md` import in a `CLAUDE.md` next to it. Do this when your project also has a `CLAUDE.md`, when
  you've set **Project instructions** to `claude-md`, or in sessions that can't load `AGENTS.md`. Add any
  Claude-specific instructions below the import, and Claude reads the imported file first, then the rest:
  [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)

  ```markdown
  @AGENTS.md

  ## Claude Code

  Use plan mode for changes under `src/billing/`.
  ```

- If you don't need Claude-specific content, a symlink (`ln -s AGENTS.md CLAUDE.md`) also works. Before you choose
  the symlink over the import, check these constraints:
  [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)
  - **Editing**: Claude reads `CLAUDE.md` through the link, but the Edit and Write tools refuse to write through a
    symlink, and the refusal directs Claude to edit the link's target, `AGENTS.md`, instead.
    [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)
  - The refusal's reason is `it is a symbolic link. Write to the link's target path instead`.
    [errors › Refusing to read, write, or search a path](https://code.claude.com/docs/en/errors#refusing-after-a-symlink-changed)
  - **Windows**: if you or anyone who clones the repository works on Windows, use the `@AGENTS.md` import instead.
    Creating a symlink there needs Administrator privileges or Developer Mode, and Git checks a committed symlink
    out as a plain text file unless `core.symlinks` is enabled, which leaves that clone with a one-line `CLAUDE.md`
    in place of your instructions.
    [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)
- With either the import or the symlink, run `/context` in your next session and confirm `CLAUDE.md` appears under
  **Memory files**.
  [memory › Share one file with other coding tools](https://code.claude.com/docs/en/memory#share-one-file-with-other-coding-tools)

## Not stated by the documentation

- The documentation names a subdirectory's `AGENTS.md` as read when Claude opens a file there, but does not say
  whether a subdirectory's `.claude/AGENTS.md` is read the same way.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- Re-injection after compaction and the timing of mid-session edits are stated for CLAUDE.md files; the
  documentation does not say whether an `AGENTS.md` read through the **Project instructions** setting is re-injected
  after compaction, or when an edit to it takes effect.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction),
  [prompt-caching › Editing CLAUDE.md mid-session](https://code.claude.com/docs/en/prompt-caching#editing-claude-md-mid-session)
- The documentation does not say in what order an `AGENTS.md` and a `.claude/AGENTS.md` in the same directory load.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
- The documentation does not say whether a `CLAUDE.md` excluded by `claudeMdExcludes` still counts for the check that
  stops Claude reading `AGENTS.md`.
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)

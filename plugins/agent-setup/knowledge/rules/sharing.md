# Sharing rules

Making rules reach more projects or directories: symlinks, imports, additional directories and sparse worktrees.

## Contents

- Symlinks
- Imports
- Additional directories
- Sparse worktree checkouts
- Not stated by the documentation

## Symlinks

- The `.claude/rules/` directory supports symlinks, so you can maintain a shared set of rules and link them into
  multiple projects. Circular symlinks are detected and handled gracefully.
  [memory › Share rules across projects with symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)
  - A symlink can link a whole shared directory or an individual file:

    ```bash
    ln -s ~/shared-claude-rules .claude/rules/shared
    ln -s ~/company-standards/security.md .claude/rules/security.md
    ```

- Claude Code treats a symlink whose target is outside your working directory like an external import. The linked
  rules don't load until you approve external imports for the project, and after that only the ones without a
  `paths` field load.
  [memory › Share rules across projects with symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)
- Claude Code asks for that approval only when a project memory file imports a file outside the working directory
  with `@path`, not for symlinks alone.
  [memory › Share rules across projects with symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)
- To load shared rules without that approval, keep them in `~/.claude/rules/`, where they apply to every project on
  your machine.
  [memory › Share rules across projects with symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)
- If a `.claude/rules/` or `CLAUDE.md` symlink points at a network path, such as the UNC share `\\server\share` or a
  path under `/net` or `/Network`, the linked instructions don't load: Claude Code doesn't follow the link, because
  looking up such a path can contact the host it names. `\\wsl$` paths don't count as network paths.
  [memory › Share rules across projects with symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)
- In Cowork sessions on your desktop, Claude Code skips a symlinked `~/.claude/rules/` directory or rule file that
  points outside the working directory, and a `~/.claude/CLAUDE.md` that is itself a symlink or hard link.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

## Imports

- CLAUDE.md files can import additional files using `@path/to/import` syntax. Imported files are expanded and loaded
  into context at launch alongside the CLAUDE.md that references them.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- Both relative and absolute paths are allowed. Relative paths resolve relative to the file containing the import,
  not the working directory. Imported files can recursively import other files, with a maximum depth of four hops.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- To import a path containing spaces, put a backslash before each space; without them the path ends at the first
  space, even when the import is on a line of its own. A path wrapped in quotes isn't imported at all, with or
  without the backslashes.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

  ```text
  - API conventions @Design\ Docs/api-conventions.md
  ```

- Import parsing skips Markdown code spans and fenced code blocks: `` `@README` `` stays literal, while `@README`
  outside backticks imports the file.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- An import in a project-level memory file is external when its path resolves outside your working directory. The
  first time Claude Code encounters external imports in a project, it shows an approval dialog listing the files. If
  you decline, the imports stay disabled and the dialog doesn't appear again.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- User-scope memory files, such as `~/.claude/CLAUDE.md` and `~/.claude/rules/`, are files you wrote yourself.
  Except in Cowork sessions on your desktop, Claude Code loads their imports without the dialog and trusts them like
  the rest of your personal configuration.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- In Cowork sessions on your desktop, Claude Code skips any import in a user-scope file that resolves to a path
  outside the session's working directory and loads the rest of the file.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

## Additional directories

- For a directory added with the `--add-dir` flag, setting the `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD`
  environment variable loads `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and `CLAUDE.local.md` from it.
  `CLAUDE.local.md` is skipped if you exclude `local` from `--setting-sources`.
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories)

  ```bash
  CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
  ```

- The inline form sets the variable for that one launch in Bash or Zsh. To keep it on for every session, add it to
  the `env` block in `~/.claude/settings.json`.
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories)
- The `permissions.additionalDirectories` setting in `.claude/settings.json` gives Claude access to directories
  outside the working directory. Relative paths resolve against the directory you start Claude from. This
  example is `packages/api/.claude/settings.json`, granting access to the sibling packages `packages/shared/` and
  `packages/web/` while working from `packages/api/`.
  [large-codebases › Grant access across packages or repositories](https://code.claude.com/docs/en/large-codebases#grant-access-across-packages-or-repositories)

  ```json
  {
    "permissions": {
      "additionalDirectories": ["../shared", "../web"]
    }
  }
  ```

- However you add a directory, Claude can read and edit files in it. Whether the directory's CLAUDE.md,
  `.claude/rules/` files, and skills also load depends on how you added it:
  [large-codebases › Grant access across packages or repositories](https://code.claude.com/docs/en/large-codebases#grant-access-across-packages-or-repositories)

  | Added with | Loads CLAUDE.md and rules | Loads skills |
  | :- | :- | :- |
  | `additionalDirectories` setting | Never | Never |
  | `--add-dir` flag or `/add-dir` command | Only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Yes |

- For sibling directories that everyone in this area needs, commit `additionalDirectories` to
  `.claude/settings.json`. For a personal selection or one-off access, use `.claude/settings.local.json` or pass
  `--add-dir` at launch.
  [large-codebases › Grant access across packages or repositories](https://code.claude.com/docs/en/large-codebases#grant-access-across-packages-or-repositories)

## Sparse worktree checkouts

- The `--worktree` flag starts a session in a new git worktree, which by default checks out the entire repository.
  The `worktree.sparsePaths` setting uses git sparse-checkout to write only the listed directories plus root-level
  files to disk.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)
- Root-level files are always checked out alongside the listed directories; root-level directories are not, so
  include `.claude` in the list if you want the repository root's `.claude/settings.json` or `.claude/rules/`
  available inside the worktree. List directories in `sparsePaths`, not individual files.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)

  ```json
  {
    "worktree": {
      "sparsePaths": [".claude", "packages/api", "packages/shared"]
    }
  }
  ```

- Paths in `sparsePaths` are relative to the repository root, regardless of which subdirectory you start Claude
  from. All worktrees in a session share the same `sparsePaths`.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)
- The `sparsePaths` lists merge across scopes, so `.claude/settings.local.json` can add paths to the list committed
  in `.claude/settings.json` but not remove them.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)
- The `sparsePaths` setting is read from your starting directory before the worktree is created. After creation,
  the session's working directory is the worktree root, not the subdirectory you launched from.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)

## Not stated by the documentation

- Imports in `~/.claude/rules/` files are stated to load, and the external-import rules cover project-level memory
  files, which include `.claude/rules/*.md`; the documentation does not show or name an `@path` import in a project
  `.claude/rules/` file.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files),
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories)
- The documentation does not say what a `paths` pattern in a rule loaded from an additional directory is matched
  against: that directory or the working directory.
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories)
- For an additional directory the documentation names `.claude/rules/*.md`; it does not say whether rules in
  subdirectories of that directory's `.claude/rules/` load.
  [memory › Load from additional directories](https://code.claude.com/docs/en/memory#load-from-additional-directories)
- Skills, commands, and subagents from a flag-added directory don't load when `project` is excluded from
  `--setting-sources`; the documentation does not say the same for rules from that directory.
  [permissions › Additional directories grant file access, not configuration](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration)

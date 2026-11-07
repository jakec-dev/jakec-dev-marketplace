# Isolating a subagent's edits

Running a subagent in its own git worktree, what Claude Code checks and blocks while it does, the messages and how to
clear them, and what rewinding restores.

## Contents

- Working directory
- Run a subagent in a worktree
- Enforcement checks
- Blocked commands
- Paths that cannot be safely resolved
- Base branch
- Files and directories in the worktree
- Cleanup
- Refused worktrees
- Entering and leaving worktrees
- Rewinding subagent edits

## Working directory

- A subagent starts in the main conversation's current working directory. Within a subagent, `cd` commands don't
  persist between Bash or PowerShell tool calls and don't affect the main conversation's working directory. To give the
  subagent an isolated copy of the repository instead, set `isolation: worktree`.
  [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)
- A subagent with `isolation: worktree` runs its Bash and PowerShell commands inside its worktree. A command whose
  working directory resolves to your main checkout instead, for example because the worktree directory was removed
  while the subagent was running, fails with an error.
  [sub-agents › Write subagent files](https://code.claude.com/docs/en/sub-agents#write-subagent-files)
- A subagent that a background session spawns inherits the session's working directory. Once that session is in a
  worktree, the subagent's file edits land in that worktree rather than in your working copy; to give the subagent
  its own worktree, Claude can also pass `isolation: "worktree"` when spawning it.
  [agent-view › How file edits are isolated](https://code.claude.com/docs/en/agent-view#how-file-edits-are-isolated)

## Run a subagent in a worktree

- Subagents can run in their own worktrees so parallel edits don't conflict. Ask Claude to "use worktrees for your
  agents", or make the isolation permanent for a custom subagent by adding `isolation: worktree` to its frontmatter.
  [worktrees › Isolate subagents with worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees)

  ```markdown
  ---
  name: refactorer
  description: Applies mechanical refactors across many files
  isolation: worktree
  ---

  Apply the requested refactor across every affected file, then run the tests
  and report the results.
  ```

- Each subagent gets a temporary worktree that Claude Code removes automatically when the subagent finishes without
  changes. A worktree with changes stays on disk until the periodic sweep can remove it without losing work.
  [worktrees › Isolate subagents with worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees)
- Subagent worktrees use the same base branch as `--worktree`.
  [worktrees › Isolate subagents with worktrees](https://code.claude.com/docs/en/worktrees#isolate-subagents-with-worktrees)

## Enforcement checks

- While a session is isolated in a worktree, Claude Code blocks the tool calls the four checks below define. The same
  rules apply whether you started the session with `--worktree`, Claude entered a worktree with `EnterWorktree`, or you
  resumed a worktree session. The same enforcement covers every subagent Claude spawns from the isolated session. It
  applies whether the session is interactive or runs in the background. Subagents that run in their own worktree carry
  the same checks.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- **File edits**: Claude Code blocks an `Edit`, `Write`, or `NotebookEdit` that targets a path in the main checkout.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- **Command working directory**: Claude Code blocks a Bash, PowerShell, or Monitor command whose working directory
  resolves to the main checkout, or whose working directory it can't verify stays outside it.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- **Git redirects**: Claude Code blocks a Bash or Monitor command that redirects git into the main checkout. The
  redirect can come through `git -C`, `--git-dir`, a `GIT_DIR` or `GIT_WORK_TREE` variable, or a `cd` into the main
  checkout before running git.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- **Command shape**: Claude Code blocks a Bash or Monitor command when it can't verify from the command text that any
  git the command runs stays inside the worktree. That happens, for example, when the command name is computed at
  runtime, when the syntax can't be parsed, or when an expansion such as `${!name}` or `${ command; }` could run a
  command the text doesn't spell out. Claude Code tells Claude how to rewrite the refused command, such as splitting it
  into plain, separate commands. You can't turn this check off.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- These checks read the path an edit targets, the directory a command runs in, and the text of the command. None of
  them tracks which files a shell command writes, so a command that writes into the main checkout without running git
  there, such as `cp` or a shell redirect, isn't refused by them. Claude Code treats that command like any other shell
  command under your permissions and sandboxing settings.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- The checks apply to the repository you launched Claude Code from. They also cover the main checkout a linked worktree
  is linked from. For PowerShell commands, Claude Code applies only the working-directory check.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)
- Claude sees each refusal as a tool error that names the worktree and says how to proceed.
  [worktrees › How Claude Code enforces isolation](https://code.claude.com/docs/en/worktrees#how-claude-code-enforces-isolation)

## Blocked commands

- Claude Code refuses a Bash, PowerShell, or Monitor command in a session isolated in a worktree for one of these
  reasons: the command would run in the main checkout or in another worktree (the message says its working directory
  `resolved to the shared checkout` or `is in a different worktree`); a Bash or Monitor command points git at the main
  checkout; or Claude Code can't verify from a Bash or Monitor command's text that any git the command runs stays inside
  the worktree. A command that never names git can still be refused for the last reason, because expanding a variable
  indirection such as `${!name}` or running a Bash function substitution such as `${ command; }` produces a value at
  runtime that can itself be a command.
  [errors › Command blocked by the worktree isolation checks](https://code.claude.com/docs/en/errors#command-blocked-by-the-worktree-isolation-checks)
- The message says `is isolated in the worktree <path>, but this command`, followed by the reason, such as a command
  whose text Claude Code couldn't verify:
  [errors › Command blocked by the worktree isolation checks](https://code.claude.com/docs/en/errors#command-blocked-by-the-worktree-isolation-checks)

  ```text
  This session is isolated in the worktree /path/to/worktree, but this command evaluates ${!x@P} arithmetically inside a construct too complex to verify, which can run a command hidden in a variable's value. Refusing to run it — a worktree-isolated session's git operations must target its own worktree. Split it into plain, separate commands and run them from /path/to/worktree.
  ```

- When git is pointed at the main checkout or the command text can't be verified, you do nothing: Claude reads the
  message and rewrites the command the way its final sentence asks. If a command you asked for keeps being refused over
  an expansion in its text, spell the flagged value literally and run git as its own plain command from inside the
  worktree. To act on the main checkout on purpose, run the command yourself in a terminal outside the session.
  [errors › Command blocked by the worktree isolation checks](https://code.claude.com/docs/en/errors#command-blocked-by-the-worktree-isolation-checks)

## Paths that cannot be safely resolved

- The worktree-isolation guard checks writes and command working directories in any session isolated in a worktree,
  interactive or background, and in worktree-isolated subagents. It resolves symlinks before checking that the
  operation doesn't reach the shared checkout, and when resolution fails, it blocks the operation. This happens when
  Claude addresses a file or working directory through a spelling the guard can't resolve to one verifiable location.
  [errors › Write or command blocked because the path cannot be safely resolved](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-cannot-be-safely-resolved)
- The message names the path forms it refuses and how to retry:
  [errors › Write or command blocked because the path cannot be safely resolved](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-cannot-be-safely-resolved)

  ```text
  This write was blocked because the path is spelled in a form that cannot be safely resolved (for example through a symlink storing a raw dot segment, a network-share or device-namespace shape, or an unreadable ancestor directory). If the file is inside the worktree /path/to/worktree, address it by its direct symlink-free path instead.
  ```

  A blocked command reports the same cause for its working directory and ends with
  `re-run the command from its direct symlink-free path`.
- Usually you do nothing: the full message goes to Claude as a tool error, and Claude retries with the direct path it
  names. For a blocked file edit, the conversation view shows only a short `Error editing file` line; the full message
  appears in the transcript view, which you open with `Ctrl+O`. A blocked command prints it in its command output.
  [errors › Write or command blocked because the path cannot be safely resolved](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-cannot-be-safely-resolved)
- If the block repeats on the same file, the path likely runs through a committed symlink whose target contains `..`,
  such as `docs/current -> ../README.md`; ask Claude to edit the target file by its real path instead of through the
  link.
  [errors › Write or command blocked because the path cannot be safely resolved](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-cannot-be-safely-resolved)

- When Claude addresses a file or working directory through a path that names a drive that isn't on your machine, a
  UNC share such as `\\server\share\file` or a `/net` automount path, while the session's checkout is on a local
  disk, the same guard blocks the operation, and isolating in a worktree doesn't lift the block. The message names
  the path to use instead:
  [errors › Write or command blocked because the path names a network location](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-names-a-network-location)

  ```text
  This write was blocked because the path is network-shaped (a UNC share or /net automount spelling) while this session's checkout is local. Isolating cannot unblock it. If the file is genuinely inside the worktree /path/to/worktree, address it by its local, plainly-spelled path instead.
  ```

- A blocked command reports the same cause for its working directory and ends with `re-run the command from its
  local, plainly-spelled path`. Usually Claude retries with the local spelling the message asks for.
  [errors › Write or command blocked because the path names a network location](https://code.claude.com/docs/en/errors#write-or-command-blocked-because-the-path-names-a-network-location)

## Base branch

- `worktree.baseRef` in settings sets where new worktrees branch from. It accepts two values: `"fresh"` (default)
  branches from the repository's default branch on the remote, usually `main`, so the worktree starts from a
  clean tree matching the remote. `"head"` branches from your current local `HEAD`, so the worktree carries your
  unpushed commits and feature-branch state. Use `"head"` when isolating subagents that need to operate on in-progress
  work. Inside a worktree, `"head"` resolves to that
  worktree's `HEAD`, not the main checkout's.
  [worktrees › Choose the base branch](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)
- You can't set `worktree.baseRef` to a branch name. To start a worktree from a specific existing branch, create it
  with git directly.
  [worktrees › Choose the base branch](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)
- For a `"fresh"` base, Claude Code keeps `origin/HEAD` current. When the repository hasn't been fetched in the last
  24 hours, it fetches the default branch, capped at five seconds, and uses the locally cached ref if the fetch fails.
  The fetch never waits for input in your terminal: it also counts as failed when git or ssh would ask for a password,
  a key passphrase, or confirmation of a new SSH host. If no remote is configured, or `origin/HEAD` isn't cached
  locally and can't be fetched, the worktree falls back to your current local `HEAD`.
  [worktrees › Choose the base branch](https://code.claude.com/docs/en/worktrees#choose-the-base-branch)

  ```json
  {
    "worktree": {
      "baseRef": "head"
    }
  }
  ```

  This makes every new worktree branch from your current work.

## Files and directories in the worktree

- A worktree is a fresh checkout, so untracked files like `.env` or `.env.local` from your main repository are not
  present. To copy them automatically when Claude creates a worktree, add a `.worktreeinclude` file to your project
  root. The file uses `.gitignore` syntax. Only files that match a pattern and are also gitignored are copied, so
  tracked files are never duplicated.
  [worktrees › Copy gitignored files into worktrees](https://code.claude.com/docs/en/worktrees#copy-gitignored-files-into-worktrees)

  ```text
  .env
  .env.local
  config/secrets.json
  ```

  This `.worktreeinclude` copies two env files and a secrets config into each new worktree.
- `.worktreeinclude` applies to every worktree Claude Code creates with git, including subagent worktrees.
  [worktrees › Copy gitignored files into worktrees](https://code.claude.com/docs/en/worktrees#copy-gitignored-files-into-worktrees)
- The `worktree.sparsePaths` setting is particularly useful for subagent worktree isolation: each subagent that runs in
  a worktree gets a lightweight checkout instead of the full tree.
  [large-codebases › Check out only the directories you need](https://code.claude.com/docs/en/large-codebases#check-out-only-the-directories-you-need)

## Cleanup

- Claude Code runs a periodic sweep that removes worktrees that Claude created for subagents and background sessions
  once they are older than your `cleanupPeriodDays` setting, following the retention sweep rules. The same age
  cutoff applies to automatic removal of orphaned worktrees.
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees),
  [claude-directory › Cleaned up automatically](https://code.claude.com/docs/en/claude-directory#cleaned-up-automatically)
- The sweep leaves a worktree in place when it still holds work (changed or untracked files, or unpushed commits).
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)
- The sweep also leaves a worktree in place when a checked-out submodule in it holds changed or untracked files, or
  Claude Code can't inspect the worktree's submodules.
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)
- The sweep also leaves a worktree in place when Claude Code can't determine which filter drivers the repository config
  defines, or finds a setting there it can't switch off: the cases that also block worktree creation when Git LFS
  content is missing.
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)
- Claude Code writes a marker into the git metadata of every worktree it creates with git, and the sweep keeps any
  worktree without one.
  [worktrees › Clean up subagent and background-session worktrees](https://code.claude.com/docs/en/worktrees#clean-up-subagent-and-background-session-worktrees)
- While an agent is running, Claude Code holds a `git worktree lock` on its worktree so that concurrent cleanup can't
  remove it, and releases the lock when the agent finishes. Claude Code holds the same lock on the worktree it created
  for a backgrounded session while the session runs, so the sweep leaves the worktree in place and `git worktree remove`
  refuses to remove it.
  [worktrees › Worktree locks and manual removal](https://code.claude.com/docs/en/worktrees#worktree-locks-and-manual-removal)
- The sweep also releases a lock Claude Code set for a session whose process has exited, so a killed background
  session doesn't leave its worktree permanently locked. The sweep never releases a lock you set yourself with
  `git worktree lock`.
  [worktrees › Worktree locks and manual removal](https://code.claude.com/docs/en/worktrees#worktree-locks-and-manual-removal)
- To clean up a worktree that the sweep keeps, run `git worktree remove`, adding `--force` if the worktree has
  uncommitted changes or untracked files. If git refuses because the worktree is locked, run `git worktree unlock` on it
  first.
  [worktrees › Worktree locks and manual removal](https://code.claude.com/docs/en/worktrees#worktree-locks-and-manual-removal)

## Refused worktrees

- An error starting `Refusing to use <path> as an isolation worktree` means Claude Code checked the directory's git
  identity before adopting it as a session's or subagent's isolated checkout, and declined it. The check runs whether
  Claude Code is creating the worktree, entering an existing one, or reusing one from an earlier run.
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)
- In most cases the rest of the message says the directory's git metadata resolves into the main checkout: for
  example, its `.git` file points at the main repository's own `.git` directory, or git resolves its working tree to
  the main checkout through a `core.worktree` redirect. From such a directory, an ordinary git command such as
  `git reset --hard` would act on the main checkout instead of the worktree. Claude Code also refuses when the
  directory has a `.git` entry it can't read, rather than assuming the worktree is safe.
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)
- Claude Code leaves the refused directory in place, since it may hold work. Match the message to its recovery,
  whether it follows `Refusing to use <path>` or appears in a resume message; some endings occur only in resume
  messages:
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)
  - `launch from the parent checkout` or `Run the resume from the project checkout`: you launched Claude Code from
    inside the worktree. Launch from the main checkout instead; the worktree needs no recreation.
  - `it cannot be resumed or re-entered`: nothing in this session vouches for the worktree from where you launched.
    Recreate it; the directory and its work remain on disk for manual recovery, and when the worktree has a parent
    checkout, resuming from there also works.
  - `it contains the protected checkout`: the refused directory is a parent of your main checkout, such as your home
    directory. Don't delete it. Change the worktree path, such as the path your `WorktreeCreate` hook returns or the
    `EnterWorktree` target, so the worktree doesn't contain the checkout.
  - `the protected checkout <path> has a .git entry that could not be examined` or
    `has git metadata that could not be resolved`: the problem is the main checkout's git metadata, not the
    worktree's. Don't delete the worktree, and ignore the message's trailing advice to recreate it, which doesn't apply
    to these two endings. Repair the main checkout, for example a permissions problem or a git `dubious ownership`
    refusal on its `.git`, and retry.
  - `its recorded path has a network spelling`: Claude Code never resumes into a worktree at a network path. Recreate
    the worktree at a local path.
  - Any other ending: the message names the problem and its fix, such as removing a `core.worktree` redirect or
    recreating the worktree; follow it. Before deleting a directory whose message says its git identity could not be
    verified, address the named cause first, for example a symbolic link in the worktree's path or git itself failing to
    run, since the directory may be healthy. When you do recreate, salvage any changes you need from the old directory
    first; it stays on disk.
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)

## Entering and leaving worktrees

- `EnterWorktree`: from a subagent with a pinned working directory such as `isolation: worktree`, only the `path` form
  is available and the target must be under `.claude/worktrees/` of the session's repository.
  [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference#page-title)
- `ExitWorktree` is not available to subagents that already run in their own working directory, such as with
  `isolation: worktree`.
  [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference#page-title)

## Rewinding subagent edits

- A subagent makes edits with Claude's file editing tools, but Claude Code usually doesn't capture those edits in your
  session's checkpoints. Whether rewinding restores them depends on how the subagent runs.
  [checkpointing › Subagent edits not restored](https://code.claude.com/docs/en/checkpointing#subagent-edits-not-restored)
- Apart from a foreground forked skill (a `context: fork` skill), rewinding restores only the files Claude had already
  edited in your conversation. The subagent's edits to other files stay, so use version control, such as Git, to revert
  them. This includes a background `/code-review --fix` run.
  [checkpointing › Subagent edits not restored](https://code.claude.com/docs/en/checkpointing#subagent-edits-not-restored)

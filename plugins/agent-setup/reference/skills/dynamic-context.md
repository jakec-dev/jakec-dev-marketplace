# Injecting dynamic context into a skill

Running shell commands when a skill is invoked and putting their output into its content: the `` !`<command>` ``
and ```` ```! ```` forms, the `shell` field, how the commands run, failures, permission checks, and
`disableSkillShellExecution`.

## Contents

- [Syntax](#syntax)
- [How commands run](#how-commands-run)
- [Failures](#failures)
- [Permission checks](#permission-checks)
- [Turning it off](#turning-it-off)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## Syntax

- The `` !`<command>` `` syntax runs shell commands before the skill content is sent to Claude. The command output
  replaces the placeholder, so Claude receives actual data, not the command itself.
  [skills › Inject dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)

  ```yaml
  ---
  name: pr-summary
  description: Summarize changes in a pull request
  context: fork
  agent: Explore
  allowed-tools: Bash(gh *)
  ---

  ## Pull request context
  - PR diff: !`gh pr diff`
  - Changed files: !`gh pr diff --name-only`
  ```

- Substitution runs once over the original file. Command output is inserted as plain text and is not re-scanned for
  further `` !`<command>` `` placeholders, so a command cannot emit a placeholder for a later pass to expand.
  [skills › Inject dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)
- The inline form is only recognized when `!` appears at the start of a line or immediately after whitespace. If `!`
  follows another character, as in `` KEY=!`cmd` ``, the placeholder is left as literal text and the command does
  not run. [skills › Inject dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)
- For multi-line commands, use a fenced code block opened with ```` ```! ```` instead of the inline form.
  [skills › Inject dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)

  ````markdown
  ## Environment
  ```!
  node --version
  git status --short
  ```
  ````

## How commands run

- Claude Code picks the tool that runs a skill's injected commands from the `shell` key in the skill's frontmatter
  and your environment:
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
  - `shell: powershell`, with the [PowerShell tool](https://code.claude.com/docs/en/tools-reference#powershell-tool)
    enabled: the commands run through the PowerShell tool.
  - `shell: bash` when bash isn't available: the invocation fails before any command runs. This happens on Windows
    without Git Bash. Claude Code shows ``Skill <name> requires bash (`shell: bash` in frontmatter) but Git Bash was
    not found``. To fix it, install Git for Windows or change the frontmatter to `shell: powershell`.
    [errors › /security-review fails without origin/HEAD](https://code.claude.com/docs/en/errors#security-review-fails-without-origin-head)
  - Any other combination: the commands run through the Bash tool when bash is available. When it isn't, they run
    through the PowerShell tool.
- Either tool runs the commands the same way it runs Claude's own shell commands, sharing the working directory,
  timeout, and output handling.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- **Working directory**: Claude Code runs each command in the session shell's current working directory. That
  directory moves when Claude runs `cd`. Use `${CLAUDE_SKILL_DIR}` or `${CLAUDE_PROJECT_DIR}` in paths that must
  resolve the same way every time.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- **stderr**: with the default `bash` shell, Claude Code merges stderr into stdout. Anything the command writes to
  stderr appears in the injected text.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- **Timeout**: each command runs under the Bash tool's default 2-minute timeout.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
  - Two environment variables control a foreground command's timeout. `BASH_DEFAULT_TIMEOUT_MS` is the default when
    Claude passes no timeout, two minutes out of the box. `BASH_MAX_TIMEOUT_MS` sets the ceiling that caps whatever
    Claude requests: the effective ceiling is the larger of the two, ten minutes out of the box.
    [tools-reference › Timeout and output limits](https://code.claude.com/docs/en/tools-reference#timeout-and-output-limits)
  - A foreground command that reaches its timeout is moved to the background instead of stopped, unless it starts
    with `sleep`. With `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` set or in bare mode, a command that reaches its
    timeout stops instead.
    [tools-reference › Foreground commands that move to the background](https://code.claude.com/docs/en/tools-reference#foreground-commands-that-move-to-the-background)
  - When the Bash tool moves a timed-out command to the background, the skill still renders; the injected text
    reports the move and names the background task and the file collecting the command's output. When the command
    is one the Bash tool never auto-backgrounds, Claude Code kills it at the timeout, and that failure aborts the
    invocation.
    [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- **Output size**: output past the Bash tool's inline ceiling arrives as a file path plus a short preview, not
  truncated text.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
  - A valid result arrives inline up to roughly 30,000 characters by default; past that, Claude gets the path of a
    file saved to the session directory plus a preview of up to the first 2,000 characters. A failure arrives inline
    up to roughly 10,000 characters; past that, a head-and-tail excerpt of that size with no file path.
    [tools-reference › Output limits](https://code.claude.com/docs/en/tools-reference#output-limits)
  - `BASH_MAX_OUTPUT_LENGTH` sets how many characters Claude Code reads back from the working file: 30,000 by
    default, up to a hard ceiling of 150,000. It doesn't raise the inline ceilings: a valid result over the inline
    ceiling arrives as a file path plus preview regardless of this variable.
    [tools-reference › Output limits](https://code.claude.com/docs/en/tools-reference#output-limits)
  - The `bashOutputMaxChars` setting sizes the inline ceiling and the read-back window together, up to 128,000
    characters, and Claude Code then ignores `BASH_MAX_OUTPUT_LENGTH`.
    [tools-reference › Output limits](https://code.claude.com/docs/en/tools-reference#output-limits)
- The PowerShell tool applies the same timeout, backgrounding, and output-ceiling behavior to the commands it runs.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- `shell: powershell` needs the PowerShell tool enabled. Set `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` in your environment
  or in `settings.json`. Without the tool, `shell: powershell` commands run through the Bash tool when bash is
  available, and through the PowerShell tool when it isn't.
  [tools-reference › Enable the PowerShell tool](https://code.claude.com/docs/en/tools-reference#enable-the-powershell-tool)
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)

  ```json
  {
    "env": {
      "CLAUDE_CODE_USE_POWERSHELL_TOOL": "1"
    }
  }
  ```

  The PowerShell tool is enabled as follows:
  [tools-reference › PowerShell tool](https://code.claude.com/docs/en/tools-reference#powershell-tool)
  - On Windows without Git Bash, automatically.
  - On Windows with Git Bash installed, by default for claude.ai and Console accounts. In Amazon Bedrock, Google
    Cloud's Agent Platform, and Microsoft Foundry sessions, set the variable to `1`.
  - On Windows, set the variable to `0` to turn the tool off.
    [tools-reference › Enable the PowerShell tool](https://code.claude.com/docs/en/tools-reference#enable-the-powershell-tool)
  - On Linux, macOS, and WSL, it is opt-in and needs PowerShell 7 or later: install `pwsh` and ensure it is on your
    `PATH`.
    [tools-reference › Enable the PowerShell tool](https://code.claude.com/docs/en/tools-reference#enable-the-powershell-tool)

## Failures

- A failed command aborts the entire skill invocation, not just its own placeholder. Claude never sees the skill
  content for that invocation. The abort shows `Shell command failed for pattern "..."`. The error message includes
  the command's output under `[stderr]`.
  [skills › When an injected command fails](https://code.claude.com/docs/en/skills#when-an-injected-command-fails)
- With the default `bash` shell, any non-zero exit code counts as a failure. One carveout applies: Claude Code treats
  exit code 1 from search and comparison commands as a normal result and injects their output. Exit codes of 2 or
  higher fail even for those commands.
  [skills › When an injected command fails](https://code.claude.com/docs/en/skills#when-an-injected-command-fails)
- Which commands get the carveout depends on the shell: the commands listed under Output limits for the default
  `bash` shell, and with `shell: powershell`, when the PowerShell tool is enabled, a different set that includes
  `grep` and `git diff` but not `find` or `diff`.
  [skills › When an injected command fails](https://code.claude.com/docs/en/skills#when-an-injected-command-fails)
  - For the Bash tool, exit code 1 is a valid result only when Claude Code recognizes it as a benign outcome for
    that command: `grep`, `rg`, `egrep`, `fgrep`, `find`, `diff`, `test`, and `[`, plus `git diff` and `git grep`.
    Every other command that exits 1 counts as a failure, even when exit 1 is a benign informational outcome: no
    matches for `pgrep` and `jq -e`, files that differ for `cmp`.
    [tools-reference › Output limits](https://code.claude.com/docs/en/tools-reference#output-limits)
  - For PowerShell, exit code 1 from `grep`, `rg`, `egrep`, `fgrep`, `findstr`, and `git grep` means no matches, and
    exit code 1 from `git diff` means differences exist; neither is reported to Claude as a command failure. For
    `robocopy`, exit codes 0 through 7 are informational results, such as files copied or extra files detected, and
    exit codes of 8 or higher count as failures.
    [tools-reference › Shell selection in settings, hooks, and skills](https://code.claude.com/docs/en/tools-reference#shell-selection-in-settings-hooks-and-skills)
  - With the PowerShell tool on Windows (a set separate from the `diff` in the Bash list above), exit code 1 from
    `where.exe` means no match, and from `fc.exe` and `diff.exe` it means the files
    differ. When the command produces output, Claude Code treats that exit code as a valid negative answer rather
    than a command error; a silenced form, such as `where.exe /Q` or a redirect to `$null`, is still reported as a
    failure on exit code 1.
    [tools-reference › Windows encoding and exit codes](https://code.claude.com/docs/en/tools-reference#windows-encoding-and-exit-codes)
- With the default `bash` shell, append `|| true` to any other command you expect to exit non-zero, such as a check
  script that exits 1 when it finds problems.
  [skills › When an injected command fails](https://code.claude.com/docs/en/skills#when-an-injected-command-fails)

## Permission checks

- Injected commands never prompt for permission while the skill renders. Claude Code checks each one against your
  [permission rules](https://code.claude.com/docs/en/permissions) first. A command a deny rule matches aborts the
  invocation with `Shell command permission check failed for pattern "..."`, and that error fires before the
  command runs at all.
  [skills › Permission checks on injected commands](https://code.claude.com/docs/en/skills#permission-checks-on-injected-commands)
  [errors › /security-review fails without origin/HEAD](https://code.claude.com/docs/en/errors#security-review-fails-without-origin-head)
- Outside auto mode, when a command's permission check returns anything other than allow, Claude Code aborts the
  invocation with the same error, including for a rule that would normally ask you. To keep an unmatched command from
  aborting, pre-approve it with `allowed-tools`.
  [skills › Permission checks on injected commands](https://code.claude.com/docs/en/skills#permission-checks-on-injected-commands)
- When your organization sets `allowManagedPermissionRulesOnly` in managed settings, Claude Code ignores
  `allowed-tools` in project and personal skills and in other sources the setting lists, so `allowed-tools` doesn't
  pre-approve the command there. An injected command in the skill that no managed rule allows follows
  [Permission checks on injected commands](https://code.claude.com/docs/en/skills#permission-checks-on-injected-commands).
  [skills › When only managed permission rules apply](https://code.claude.com/docs/en/skills#when-only-managed-permission-rules-apply)
- In auto mode, a command that would otherwise need your approval doesn't abort the invocation. The skill loads with
  an instruction telling Claude to run the command first, and Claude's own call then goes through auto mode's usual
  checks. The invocation still aborts in a forked skill that sets `agent`, and in a session where Claude doesn't
  have the shell tool that runs injected commands.
  [skills › Permission checks on injected commands](https://code.claude.com/docs/en/skills#permission-checks-on-injected-commands)

## Turning it off

- `disableSkillShellExecution` turns off inline shell execution for `` !`...` `` and ```` ```! ```` blocks in skills
  and custom commands from user, project, plugin, or additional-directory sources. Claude Code replaces each command
  with `[shell command execution disabled by policy]` instead of running it.
  [settings-reference › `disableSkillShellExecution`](https://code.claude.com/docs/en/settings-reference#disableskillshellexecution)
  - **Scope**: Any file. A `true` in managed settings can't be overridden by `false` elsewhere.
  - **Type**: Boolean. `true` replaces each inline shell command; `false`: inline shell runs.
  - **Default**: unset, so inline shell runs.

  ```json
  {
    "disableSkillShellExecution": true
  }
  ```

- Bundled skills and skills deployed through managed settings are unaffected by `disableSkillShellExecution`.
  [settings-reference › `disableSkillShellExecution`](https://code.claude.com/docs/en/settings-reference#disableskillshellexecution)

## Not stated by the documentation

- Whether stderr is merged into the injected text when a skill sets `shell: powershell`: the merge is stated for the
  default `bash` shell only.
  [skills › How injected commands run](https://code.claude.com/docs/en/skills#how-injected-commands-run)
- Whether every other non-zero exit code fails with `shell: powershell`, and what plays the part of `|| true`
  there: both are stated for the default `bash` shell only. The documentation does state that `robocopy` exit codes
  of 8 or higher count as failures.
  [skills › When an injected command fails](https://code.claude.com/docs/en/skills#when-an-injected-command-fails)

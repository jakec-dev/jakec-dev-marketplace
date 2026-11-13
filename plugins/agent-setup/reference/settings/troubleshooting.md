# Troubleshooting settings

Checking why a setting doesn't apply: what loaded, broken files, ignored values, lost changes, dropped entries,
and the warnings, errors and sandbox failures that name a fix.

## Contents

- Confirm what loaded
- Settings file errors and warnings
- A value you set is ignored
- A change is lost or doesn't reach others
- Permission rule warnings and errors
- Managed settings: dropped entries and errors
- Auto mode denials
- Sandbox failures
- Sandbox refusals, locks and leftover files

## Confirm what loaded

- Run `/status` inside Claude Code to see which settings sources are active. The **Status** tab includes a
  `Setting sources` line that lists each settings file Claude Code loaded for the current session, such as
  `User settings` or `Project local settings` (with the managed settings entry showing in parentheses how they reached
  your machine). The line confirms which files Claude Code read; it doesn't show which
  file supplied each key. `/status` and `/config` open the same dialog on different tabs, and the **Config** tab isn't
  a view of your `settings.json` contents.
  [settings › Confirm what loaded](https://code.claude.com/docs/en/settings#confirm-what-loaded)
- To list entries Claude Code rejected, run `claude doctor`. For a model that project or managed settings set, the
  startup header names the file that set it.
  [settings › Confirm what loaded](https://code.claude.com/docs/en/settings#confirm-what-loaded)
- `claude doctor` prints read-only installation and settings diagnostics from the terminal without starting a
  session, including settings-file validation errors. For a full checkup that also proposes fixes and asks before
  applying them, run `/doctor` inside a session.
  [cli-reference › CLI commands](https://code.claude.com/docs/en/cli-reference#cli-commands),
  [debug-your-config › Check resolved settings](https://code.claude.com/docs/en/debug-your-config#check-resolved-settings)
- When a setting doesn't seem to apply, the value you set is usually being overridden by another scope or an
  environment variable.
  [debug-your-config › Check resolved settings](https://code.claude.com/docs/en/debug-your-config#check-resolved-settings)
- `--safe-mode` disables customizations, but permissions work normally and managed settings policy still applies;
  managed plugins, managed skills, managed CLAUDE.md, and policy-configured MCP servers do not.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- Most configuration surprises trace back to a small set of location and syntax rules. Check these before assuming a
  bug:
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)

  | Symptom | Cause | Fix |
  | :- | :- | :- |
  | Permissions or hooks set globally are ignored | Configuration was added to `~/.claude.json` | `~/.claude.json` holds app state and UI toggles. `permissions`, `hooks`, and `env` belong in `~/.claude/settings.json`. These are two different files. |
  | A `settings.json` value seems ignored | The same key is set in `settings.local.json` | `settings.local.json` overrides `settings.json`, and both override `~/.claude/settings.json`. See [settings precedence](https://code.claude.com/docs/en/settings#settings-precedence). |
  | `Bash(rm *)` deny rule doesn't block `/bin/rm` or `find -delete` | Bash rules match the literal command string, not the underlying executable; see [what a Bash rule doesn't match](https://code.claude.com/docs/en/permissions#bash-rule-limits) | Use a [PreToolUse hook](https://code.claude.com/docs/en/hooks-guide) or the [sandbox](https://code.claude.com/docs/en/sandboxing) for a hard guarantee. |

- `settings.json` does not read an `mcpServers` key, so servers added under `mcpServers` there never appear.
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)

## Settings file errors and warnings

- If you mistype JSON or set a key to a value Claude Code doesn't accept, Claude Code tells you at the start of an
  interactive session. What it shows depends on how much of the file is affected:
  [settings › Fix a broken settings file](https://code.claude.com/docs/en/settings#fix-a-broken-settings-file)
  - **Settings Error**: a user, project, or local file has invalid JSON or a value the schema rejects. At the start of
    an interactive session Claude Code shows a dialog that lets you fix the file with Claude's help, exit, or continue
    without the broken settings.
  - **Settings Warning**: only individual entries fail, such as a malformed permission rule. Claude Code skips those
    values and keeps the rest of the file in effect.
  - **Configuration error**: `~/.claude.json` can't be parsed. Claude Code copies the broken file to
    `~/.claude/backups/.claude.json.corrupted.<timestamp>` and asks whether to exit and fix it by hand or reset to the
    default configuration; a `-p` run prints the error and exits. To recover your previous state, copy back one of the
    five most recent `.claude.json.backup.<timestamp>` files in `~/.claude/backups/`, which Claude Code saves before
    it writes the file.
- After you continue past the dialog, run `/status` to see the affected files and `claude doctor` for the details of
  each error.
  [settings › Fix a broken settings file](https://code.claude.com/docs/en/settings#fix-a-broken-settings-file)
- A `-p` run shows no dialog. Unless a managed settings document can't be parsed, Claude Code skips the broken file
  or values and continues with the rest, so after a `-p` run that ignores a setting, run `claude doctor` to see what
  it dropped.
  [settings › Fix a broken settings file](https://code.claude.com/docs/en/settings#fix-a-broken-settings-file)
- To find a warning that Claude Code gave at startup in an interactive session, look below the startup banner first,
  then in the debug log. The row below the banner shows some warnings about permission rules, such as
  `⚠ Deny rule Bsh matches no tool · check for typos`. Claude Code keeps the debug log only in debug mode: start it
  with `claude --debug-file <path>`, then open the file at that path. In non-interactive mode with text output,
  outside a background session, look for startup warnings on stderr.
  [errors › Configuration warnings](https://code.claude.com/docs/en/errors#configuration-warnings)
- The file you pass to `--settings` must be a regular JSON settings file under 2 MiB. A larger file makes `claude`
  exit with code 1 at startup instead of loading it:
  [errors › Settings file exceeds the 2MiB limit](https://code.claude.com/docs/en/errors#settings-file-exceeds-the-2mib-limit)

  ```text
  Error: Settings file exceeds the 2MiB limit: /path/to/settings.json
  ```

  Claude Code rejects a `--settings` path that isn't a regular file the same way: a device, FIFO, or socket reports
  `Error: Cannot use settings file (Not a regular file (device, FIFO, or socket))` followed by the path, and a
  directory reports an `EISDIR` reason.
- For `claude agents --settings`, a file path must point to an existing file; Claude Code exits with a
  `Settings file not found` error if it doesn't.
  [agent-view › Settings, plugins, and MCP servers](https://code.claude.com/docs/en/agent-view#settings-plugins-and-mcp-servers)
- `claude import` exits with code 1 when Claude Code can't parse `~/.claude.json`, the file where it stores your
  account details and per-project state, because the subcommand doesn't show the recovery dialog the interactive
  session shows. It prints
  ``Could not read Claude Code config — run `claude` with no arguments to recover it.``
  Run `claude` with no arguments: Claude Code detects the invalid file and offers to reset it. To keep manual edits,
  fix the JSON syntax in `~/.claude.json` in an editor instead. Either way, rerun `claude import` afterwards.
  [errors › Could not read Claude Code config](https://code.claude.com/docs/en/errors#could-not-read-claude-code-config)
- `/output-style <style>` and `/config outputStyle=<style>` save the style to `.claude/settings.local.json`. In a
  session whose setting sources exclude `local`, such as a CLI session started with a `--setting-sources` value that
  leaves out `local`, Claude Code refuses instead of writing a setting that would have no effect:
  `Output styles are saved to local settings (.claude/settings.local.json), which this session doesn't load, so the
  style can't be changed here.` Add `local` to the session's setting sources and switch again, or set the
  `outputStyle` key in a settings file the session does load, such as `.claude/settings.json` in the project or
  `~/.claude/settings.json`.
  [errors › Output styles are saved to local settings which this session doesn't load](https://code.claude.com/docs/en/errors#output-styles-are-saved-to-local-settings-which-this-session-doesnt-load)

## A value you set is ignored

- When you set a key and Claude Code doesn't behave as if you had, start with `/status` to see which files it
  loaded, then find your symptom. Something else is setting the same key, the file can't set that value, or the file
  didn't load.
  [settings › Troubleshoot a setting that doesn't apply](https://code.claude.com/docs/en/settings#troubleshoot-a-setting-that-doesn’t-apply)
- **A higher level sets it.** Another settings file, a `--settings` flag, or a managed source sets the key above
  yours; the settings precedence stack says which. A flag or environment variable can also override the key on its
  own, decided key by key; the key's entry on the settings reference says which one Claude Code uses, and the `env`
  entry covers a managed `env` value versus a shell export.
  [settings › A value you set is ignored](https://code.claude.com/docs/en/settings#a-value-you-set-is-ignored)
- **The file can't set that value.** `permissions.defaultMode` values `auto` and `bypassPermissions` don't take effect
  from project or local settings; set them in user or managed settings instead, or pass `--permission-mode` for one
  session.
  [settings › A value you set is ignored](https://code.claude.com/docs/en/settings#a-value-you-set-is-ignored)
- **The file is broken.** Invalid JSON or a rejected value makes Claude Code skip the file or the entry; see
  "Settings file errors and warnings" above.
  [settings › A value you set is ignored](https://code.claude.com/docs/en/settings#a-value-you-set-is-ignored)
- When a project or local settings file sets one of the OpenTelemetry exporter variables that Claude Code ignores
  there, a local interactive session shows a notice at startup. Run `/status` or `claude doctor` to see which ones
  Claude Code ignored and which turned telemetry off; both list names, never values.
  A non-interactive run with `-p` or an Agent SDK session shows no notice, so check that your collector still receives
  data after you upgrade. If it doesn't, set the variables in your user settings, managed settings, the job's
  environment, or a file you pass with `--settings`.
  [settings-reference › Variables Claude Code ignores in `env`](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env)

## A change is lost or doesn't reach others

- When you save a choice for new sessions from inside Claude Code, such as a default model with `/model`, Claude Code
  writes it to your user settings file, `~/.claude/settings.json`. If you can't write to that file, for example
  because another tool generates it or links it to a read-only copy, the change applies to the current session and is
  gone in the next one. Set the key in the tool that generates the file, or replace the file with one you can write
  to. If you can write to the file and the change still doesn't last, check whether the change was for one session
  only or a higher level sets the same key. For the `model` key, the model-config page lists more causes. When the
  `~/.claude/settings.json` write for a model you picked fails, the switch applies to the current session but your
  default is unchanged, and the notice ends `couldn't save it as your default: ~/.claude/settings.json` followed by
  the reason: `can't be written (<code>)`, with the operating system error code, such as `EROFS`, or `isn't valid
  JSON`, where Claude Code leaves the file untouched rather than overwrite content it can't read back. A notice ending
  `couldn't confirm it was saved as your default (~/.claude/settings.json is still being written)` means the write
  hadn't finished after three seconds; it continues in the background, so check which model your next session starts
  on, or run `/model <name>` again. After a failed write, make the file writable or fix its syntax error, then switch
  again.
  [settings › A change you made in Claude Code is lost in new sessions](https://code.claude.com/docs/en/settings#a-change-you-made-in-claude-code-is-lost-in-new-sessions),
  [errors › Couldn't save it as your default](https://code.claude.com/docs/en/errors#couldnt-save-it-as-your-default)
- When your organization's default model doesn't override user selection, the first interactive launch after the admin
  changes it clears the `model` key from your user settings once, so the new default applies. It changes nothing else
  in the file, and a model you save with `/model` after that launch is kept.
  [model-config › Organization default model](https://code.claude.com/docs/en/model-config#organization-default-model)
- Managed sources reach a running session on the schedule in the managed-settings delivery table, so restart the
  session first. If `/status` then names a different source than the one your administrator changed, a
  higher-priority source applies; the managed-settings page gives the order.
  [settings › A managed change hasn't reached you](https://code.claude.com/docs/en/settings#a-managed-change-hasn’t-reached-you)
- Two things keep a key in `.claude/settings.json` from applying for everyone who clones it:
  [settings › A committed key doesn't reach teammates](https://code.claude.com/docs/en/settings#a-committed-key-doesn’t-reach-teammates)
  - **Claude Code ignores the key in a repository file.** Look for `User, local, or managed`, `User or managed`,
    `User`, `Managed`, or `Global config` in the Scope column of the settings index. Those keys never apply from the
    shared file, apart from a few that a repository file can still switch off. Each of those entries says so on its
    Scope line. `Global config` keys apply only from `~/.claude.json`.
  - **The key waits for trust.** `permissions.allow` rules, `permissions.additionalDirectories`,
    `extraKnownMarketplaces`, and most `env` values apply only after each teammate trusts the folder.
- **You chose "Yes, and don't ask again" on a permission prompt but still get prompted for the same tool.** That
  choice saved an `allow` rule to your local file, and an `allow` rule there doesn't outrank an `ask` rule from a
  project or managed file. In the VS Code extension the approval card lets you pick the destination file, including
  the project's shared file, which changes the rule for everyone; in the CLI, Claude Code writes only to your local
  file.
  [settings › Permission rules combine differently than you expected](https://code.claude.com/docs/en/settings#permission-rules-combine-differently-than-you-expected)
- **Your organization's allow rules still apply alongside yours.** That's expected: Claude Code merges
  `permissions.allow` across scopes, unless your organization sets `allowManagedPermissionRulesOnly`.
  [settings › Permission rules combine differently than you expected](https://code.claude.com/docs/en/settings#permission-rules-combine-differently-than-you-expected)

## Permission rule warnings and errors

- A permission rule in one of your settings files that doesn't have the shape `Tool` or `Tool(content)`, for example
  because text follows the closing parenthesis or one of the parentheses is missing, is skipped. Claude Code lists it
  in the invalid-settings dialog when an interactive session starts, and in `claude doctor` output:
  [errors › Malformed Tool(content) rule](https://code.claude.com/docs/en/errors#malformed-tool-content-rule)

  ```text
  Invalid permission rule "Bash(ls) x" was skipped: Malformed Tool(content) rule. Rules take the form Tool or Tool(content) and must end at the closing ")"; parentheses inside the content are literal
  ```

  In the settings file listed with the message, rewrite the rule so it ends at its closing parenthesis, for example
  `Bash(ls *)` in place of `Bash(ls) x`. Leave parentheses inside the content unescaped; they are literal.
- The row `⚠ Deny rule Bsh matches no tool · check for typos` below the startup banner names a deny or ask permission
  rule whose tool name Claude Code doesn't recognize, so the rule doesn't apply to the tool you meant. A deny rule
  written as `Bsh` isn't applied to Bash, and neither is one that uses the label a tool shows in the transcript
  instead of its canonical name. The row repeats the rule as you wrote it. In non-interactive mode with text output,
  Claude Code prints the warning on stderr in its longer form instead:
  `Permission deny rule "Bsh" matches no known tool — check for typos.`
  [errors › Matches no tool · check for typos](https://code.claude.com/docs/en/errors#matches-no-tool)
  - Correct the tool name in the rule, for example `Bash` in place of `Bsh`. Look up canonical names in the tools
    reference.
  - To find where the rule is defined, run `/permissions` in the session and select the rule. Its details say where
    it comes from, such as `From project local settings`, or `From CLI argument` for a `--disallowedTools` value.
  - If the details read `From enterprise managed settings`, forward the row to whoever maintains your managed
    settings, since you can't change that rule yourself.
  - In a background session or with `--output-format json` or `stream-json`, Claude Code writes the warning to the
    debug log instead of stderr. Run with `--debug` to capture it at `~/.claude/debug/<session-id>.txt`.
- Tool names containing `_` or `*` are exempt from that check, and so are the names of tools Claude Code has removed,
  such as `TaskOutput`, so a mistyped rule of either kind gets no warning.
  [permissions › Tool name wildcards](https://code.claude.com/docs/en/permissions#tool-name-wildcards)
- Claude Code found a `Write`, `NotebookEdit`, `MultiEdit`, or `Glob` permission rule with a path in one of your
  settings files, in managed settings, or in a `--allowedTools`, `--disallowedTools`, or `--settings` flag value. It
  keeps the rule and changes nothing else.
  [errors › Is not matched by file permission checks](https://code.claude.com/docs/en/errors#is-not-matched-by-file-permission-checks)
  - **Interactive session**: the full warning goes to the debug log, and a deny or ask rule of this shape also shows
    as the row `⚠ Deny rule Write(docs/**) never matches · use Edit(docs/**)` below the startup banner. An allow rule
    of this shape gets no row. To find where the rule is defined, run `/permissions` in the session and select the
    rule.
  - **Non-interactive mode with text output**: the full warning on stderr names the rule, its source in parentheses,
    and the replacement to write: `Permission deny rule (.claude/settings.json): Write(docs/**) is not matched by
    file permission checks — only Edit(path) rules are. Use Edit(docs/**) instead (Edit rules cover all file-editing
    tools).`
  - **Background session, or `--output-format json` or `stream-json`**: the full warning goes to the debug log
    instead of stderr, so machine-read output stays clean. Run with `--debug` to capture it at
    `~/.claude/debug/<session-id>.txt`.
  - Replace `Write(path)`, `NotebookEdit(path)`, and legacy `MultiEdit(path)` rules with `Edit(path)`. `Edit` rules
    cover all file-editing tools.
  - Except in `--allowedTools`, where Claude Code accepts a `Glob` rule without warning, replace `Glob(path)` rules
    with `Read(path)`.
  - Fix the rule at its source, which the full warning names in parentheses: a settings file path, or the flag itself
    for `--allowed-tools` and `--disallowed-tools`. A `claude-settings-<hash>.json` path that doesn't exist on disk
    stands for an inline `--settings` value. Fix the JSON you pass to that flag.
  - Leave bare tool-name rules such as `Write` or `Glob` alone. Claude Code matches them at the tool level and doesn't
    warn about them.
  - For a rule from managed settings, the full warning's parentheses read `managed policy settings` and the rule's
    details in `/permissions` read `From enterprise managed settings`. Forward that warning to whoever maintains your
    managed settings, since you can't clear it yourself.
- Claude Code found a `Bash` allow rule whose `*` comes before a later word that determines which command it is, such
  as `Bash(git * main)` or `Bash(git -C * status *)`, in one of your settings files, in managed settings, or in an
  `--allowedTools` or `--settings` flag value. The warning exists so you can narrow a rule whose wildcard is broader
  than you intended. Claude Code keeps the rule and changes nothing about how it matches. In non-interactive mode with
  text output, the warning on stderr names the rule and its source in parentheses; in an interactive session, the
  full warning goes to the debug log and the rule shows as the row
  `⚠ Allow rule Bash(git -C * status *) allows any option at its * · use an exact value` below the startup banner.
  To find where the rule is defined, run `/permissions` in the session and select the rule.
  [errors › Has a wildcard before the rest of the command](https://code.claude.com/docs/en/errors#has-a-wildcard-before-the-rest-of-the-command)
  - Replace the `*` before the subcommand with the exact value you mean: `Bash(git checkout main)` in place of
    `Bash(git * main)`.
  - Move every `*` after the subcommand: `Bash(git status *)` in place of `Bash(git -C * status *)`. Write one rule
    per subcommand you want to allow.
  - Fix the rule at its source, which the full warning names in parentheses: a settings file path, or the
    `--allowed-tools` flag itself. A `claude-settings-<hash>.json` path that doesn't exist on disk stands for an
    inline `--settings` value. Fix the JSON you pass to that flag.
  - For a rule from managed settings, the full warning's parentheses read `managed policy settings` and the rule's
    details in `/permissions` read `From enterprise managed settings`. Forward that warning to whoever maintains your
    managed settings, since you can't clear it yourself.
  - In a background session or with `--output-format json` or `stream-json`, Claude Code writes the warning to the
    debug log instead of stderr, so machine-read output stays clean. Run with `--debug` to capture it at
    `~/.claude/debug/<session-id>.txt`.
- You removed the whole Bash tool, for example with `--disallowedTools Bash` or with a bare `Bash` or `Bash(*)` deny
  rule in one of your settings files, on Windows with Git Bash installed, where denying Bash also turns the
  PowerShell tool off. In non-interactive mode with text output, Claude Code prints this warning on
  stderr at startup, and an interactive session writes it only to the debug log: `Denying Bash also turns off the
  PowerShell tool, so Claude has neither. To use PowerShell, set CLAUDE_CODE_USE_POWERSHELL_TOOL=1.` In a background
  session or with `--output-format json` or `stream-json`, Claude Code writes the warning to the debug log instead of
  stderr. Run with `--debug` to capture it at `~/.claude/debug/<session-id>.txt`.
  [errors › Denying Bash also turns off the PowerShell tool](https://code.claude.com/docs/en/errors#denying-bash-also-turns-off-the-powershell-tool)
  - To have Claude use PowerShell, set `CLAUDE_CODE_USE_POWERSHELL_TOOL` to `1` in your environment or in the `env`
    block of a settings file. The PowerShell tool then stays on alongside your Bash deny rule.
  - To block particular commands instead of the whole tool, replace the bare `Bash` entry with scoped rules such as
    `Bash(git push *)` in the same settings file or flag. Claude keeps the Bash tool, and the PowerShell tool stays
    off until you also set the variable or add a scoped `PowerShell` permission rule.
- The Edit or Write tool was called on a path matched by a `Read` deny rule, including creating a new file at that
  path. Both tools change content Claude has to be able to read back, so Claude Code refuses the call before any file
  access with `File is covered by a Read deny rule in your permission settings and cannot be edited.` When Claude Code
  refuses the Write tool, the message ends `and cannot be written` instead. If Claude should be able to change the
  file, remove or narrow the `Read` deny rule in `/permissions` or in settings. If the file must stay untouched, keep
  the rule and add an `Edit` deny rule for the same path to block the NotebookEdit tool too.
  [errors › File is covered by a Read deny rule](https://code.claude.com/docs/en/errors#file-is-covered-by-a-read-deny-rule)
- Claude Code found `permissions.allow` rules or `permissions.additionalDirectories` entries in the project's
  `.claude/settings.json` or `.claude/settings.local.json` and didn't apply them, because the workspace has not been
  trusted; `deny` and `ask` rules aren't affected. The message reads `Ignoring 2 permissions.allow entries from
  .claude/settings.local.json: this workspace has not been trusted. Run Claude Code interactively here once and accept
  the trust dialog, or set projects["/Users/you/project"].hasTrustDialogAccepted: true in /Users/you/.claude.json.`
  The count, the setting name, and the file named in the message vary with your configuration. Run `claude` in the
  directory and accept the trust dialog (in non-interactive mode with `-p` no dialog is shown, so set the
  `hasTrustDialogAccepted` entry in `~/.claude.json` using the exact `projects` key the message prints).
  [errors › Workspace has not been trusted](https://code.claude.com/docs/en/errors#workspace-has-not-been-trusted)
- When you start or restart a background session in a directory you haven't trusted and the trust dialog can't appear,
  Claude Code doesn't start the session: `Workspace not trusted. Run `claude` in /path/to/project once and accept the
  trust prompt, then retry.` Two variants name a different cause. `The home directory is trusted one session at a
  time` means the session's directory is your home directory, where Claude Code never saves trust, so accepting the
  dialog there in an earlier session doesn't count; run the command from a terminal in your home directory so the
  dialog can appear, or start the session from a project directory instead. `<path> could not be resolved on disk`
  means Claude Code couldn't find the session's directory on disk; recreate the directory, or start a new session from
  a directory that exists. For the main message, run `claude` in the directory it names, accept the trust dialog, and
  run the command again.
  [errors › Workspace not trusted when dispatching a background session](https://code.claude.com/docs/en/errors#workspace-not-trusted-when-dispatching-a-background-session)
- Claude Code checks a path against the permission rules, then confirms the resolution again when the tool opens the
  file or starts the search, and refuses with a message in the tool result when it can't confirm it. Two refusals
  concern `Read` deny rules. `a path one of its Read deny rules is written through changed while the search was being
  prepared. Retry.` means a `Read` deny rule for the search names a path that passes through a symlink and that link
  changed while Claude Code prepared the search. `ripgrep was found only by name on PATH, and a search outside the
  working directory cannot apply your Read deny rules in that configuration` means Claude Code couldn't resolve the
  `rg` binary to an absolute path, so it refuses searches outside the working directory rather than run one your deny
  rules don't cover; install ripgrep with your package manager so `rg` resolves to an absolute path on `PATH`, or keep
  searches under the working directory. Usually the refused operation needs nothing from you: it doesn't run, and
  Claude receives the message. If a symlink refusal repeats on one path, find what keeps rewriting the link, such as a
  build tool or file watcher, or ask Claude to use the file's resolved path.
  [errors › Refusing to read, write, or search a path](https://code.claude.com/docs/en/errors#refusing-after-a-symlink-changed)

## Managed settings: dropped entries and errors

- If your managed settings file, MDM profile, registry value, or server-managed payload fails schema validation,
  Claude Code first skips each individual entry it can repair, such as one invalid permission rule, and warns about
  each one. Claude Code then drops any value that still fails, unless the value belongs to one of the keys that fail
  closed.
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped)
- Claude Code is stricter with the `managedSettings` a `policyHelper` emits: it makes the same entry repairs, but any
  schema violation that survives fails the whole helper run, and at startup Claude Code refuses to start, the same as
  for a helper that exits non-zero.
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped)
- When a managed settings file, drop-in file, MDM plist, or HKLM registry value is present but can't be parsed as a
  JSON object, Claude Code exits with code 1 at startup instead of running without the policy the document carries,
  even when another admin source delivers a valid policy. The line names the failed source before the message:
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped),
  [errors › Managed settings document could not be parsed](https://code.claude.com/docs/en/errors#managed-settings-document-could-not-be-parsed)

  ```text
  /Library/Application Support/ClaudeCode/managed-settings.json: Managed settings document could not be parsed as a JSON object; none of its settings are in effect. Fix or remove it.
  ```

  The source named is the path of the `managed-settings.json` file or a drop-in file under `managed-settings.d`, the
  macOS managed preferences profile (`per-user managed preferences` or `device-level managed preferences`), or the
  Windows registry value `Registry: HKLM\SOFTWARE\Policies\ClaudeCode\Settings`. Each source fails this way when:

  - **Managed settings file or drop-in file**: the file isn't valid JSON, or its top level isn't an object
  - **MDM plist**: macOS's `plutil` reports the plist malformed, or its converted content isn't a JSON object
  - **HKLM registry value**: the `Settings` value isn't a string, is empty, or doesn't hold a JSON object

  You see this error in interactive sessions, `claude -p`, Agent SDK sessions, background sessions, and most
  subcommands, `claude doctor` included. The refusal fails closed on purpose: settings in a document Claude Code can't
  parse can't be enforced, and starting anyway would run sessions without the organization's controls. A schema
  problem in a parseable document doesn't produce this error. If you administer the machine, fix the named document so
  it parses as a JSON object, or remove the file, profile, or registry value. If you don't, ask your administrator to
  fix the deployed document. Nothing in your own settings files causes or clears this error. When a
  `managed-settings.d/` directory exists but can't be listed, Claude Code reports
  `Managed settings drop-in directory could not be read:` followed by the underlying error instead.
- Three source states don't cause that refusal: an absent file, profile, or registry value isn't a failure (Claude
  Code runs without that source); an empty managed settings file counts as `{}`; a malformed value in the
  user-writable HKCU registry key never blocks launch, and Claude Code reports it as a notice in `/status` and
  `claude doctor` instead.
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped)
- When a managed settings file, drop-in file, `managed-settings.d/` directory, MDM profile, or HKLM registry value
  exists but can't be read, and no admin source supplies a policy, what happens depends on why the read failed. If the
  operating system denied the read, for example on a root-only file, every session starts without that source's
  policies; `/status` and `claude doctor` record the failure, and a run with `-p` also prints it to stderr. For any
  other read failure, such as an I/O error, every session exits at startup with a message to contact an
  administrator:
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped),
  [errors › Unable to read managed policy settings](https://code.claude.com/docs/en/errors#unable-to-read-managed-policy-settings)

  ```text
  Unable to read managed policy settings.
  This machine may require organization login enforcement, but the policy file failed to load.
  Contact your administrator.

  Detail: <source>: <reason>
  ```

  In the same state, sign-in flows, API requests from a session that is already running, and the `claude gateway`
  server are refused with a variant of the first line that names `allowedProviders`. For a source that can't be
  parsed, Claude Code exits with a different message naming the source. If you administer the machine, fix the problem
  the `Detail:` line names so the deployed source can be read, or remove the source. If you don't, send the message to
  your administrator. Nothing in your own settings files causes or clears this error.
- To find a dropped entry, look in one of three places: interactive sessions show a dialog at startup listing the
  invalid entries; non-interactive runs with `-p` print a summary to stderr; `claude doctor` lists each invalid entry
  with its source and field.
  [managed-settings › Find entries Claude Code dropped](https://code.claude.com/docs/en/managed-settings#find-entries-claude-code-dropped)
- When a managed source sets a top-level key that has a single restrictive value, such as
  `allowManagedPermissionRulesOnly`, `disableAutoMode`, or `skipDangerousModePermissionPrompt`, to something Claude
  Code can't read, the key reads as that value until you fix it. The report says the key `was present but invalid`
  and names the value Claude Code treats it as. For a key inside `sandbox`, see the `sandbox` bullets below.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)
  - These cases don't fail closed:
    - A `null` removes the key.
    - For every other Boolean key the rule covers (`disableAllHooks` being the exception), the string `"true"` or
      `"false"` reads as that Boolean, with a notice in `/status` asking you to drop the quotes.
- Claude Code repairs the `permissions`, `autoMode`, `worktree`, and `attribution` blocks per field instead of
  dropping them whole:
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)
  - A lock inside one, such as `permissions.disableBypassPermissionsMode`, reads as its restrictive value.
  - An invalid `permissions.defaultMode` reads as `default`.
  - While a `deny` or `ask` list in `permissions` can't be read at all, Claude Code withholds `allow` and
    `additionalDirectories`, so the grants never apply without the restrictions written beside them. The report names
    each withheld grant and the list that couldn't be read.
  - In `autoMode`, a `soft_deny` or `hard_deny` list that can't be read, or that lost an invalid entry, withholds
    `allow` and `environment` the same way.
- These keys have their own fallback:
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)

  | Field | Behavior when present but invalid |
  | :- | :- |
  | `allowedMcpServers` | Enforced as an empty allowlist until the value is fixed, so no MCP servers that users add are admitted. Servers your organization delivers through [`managedMcpServers`](https://code.claude.com/docs/en/settings-reference#managedmcpservers) still load, and `managed-mcp.json` servers load per [Servers that skip the allowlist check](https://code.claude.com/docs/en/managed-mcp#servers-that-skip-the-allowlist-check). An individual invalid entry is stripped and the valid subset is enforced. |
  | [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders) | Enforced as an empty allowlist until the value is fixed, so every API provider is refused and Claude Code doesn't start on the machine. If only an individual entry isn't a known provider name, Claude Code drops and reports that entry and enforces the rest. |
  | `allowedChannelPlugins` | Claude Code enforces an empty allowlist until you fix the value, so no channel plugin passed to `--channels` is admitted. If only an individual entry is invalid, it strips that entry and enforces the rest. |
  | `strictKnownMarketplaces` | Enforced as an empty allowlist until the value is fixed, so no [marketplace source](https://code.claude.com/docs/en/plugins/org#restrict-what-users-can-install) is admitted. An individual entry that is invalid or can't be enforced, such as a `hostPattern` regex that doesn't compile, is stripped and the valid subset is enforced. |
  | `availableModels` | Enforced as an empty allowlist until fixed, so only the Default model is available; a non-string entry is stripped and the valid subset enforced. |
  | [`availableModelsMatch`](https://code.claude.com/docs/en/settings-reference#availablemodelsmatch) | Treated as `exact` until the value is fixed. |
  | `forceLoginOrgUUID` | No organization is permitted to log in until the value is fixed. |
  | `gatewayInternalNetworks` | When the invalid value comes from the highest managed source on the machine, `/login` refuses every new [cloud gateway](https://code.claude.com/docs/en/claude-apps-gateway#allow-a-gateway-on-public-address-space-you-own) sign-in on that machine until the value is fixed. |
  | `crossSessionInbound` | Treated as `refuse`, the most restrictive value, so inbound [cross-session messages](https://code.claude.com/docs/en/cross-session-messaging#control-inbound-messages) are refused until the value is fixed. The developer sees [a warning](https://code.claude.com/docs/en/errors#crosssessioninbound-must-be-one-of-accept-hold-refuse). |
  | `deniedMcpServers` | An individual invalid entry is stripped and the valid subset is enforced. A wholly invalid value is dropped with a warning, since denying every server would block servers the policy never named. |
  | [`deniedModels`](https://code.claude.com/docs/en/settings-reference#deniedmodels) | A non-string entry is stripped and the rest of the list is enforced. A wholly invalid value is dropped with a warning and blocks no models until it is fixed. |
  | `blockedMarketplaces` | An individual invalid entry is stripped and the valid subset is enforced. An entry that parses but can never match, such as a `hostPattern` regex that doesn't compile, is kept with a warning. It blocks nothing until fixed, but [marketplace restrictions](https://code.claude.com/docs/en/plugins/org#restrict-what-users-can-install) stay active. A wholly invalid value is dropped with a warning, since blocking every marketplace would block sources the policy never named. |
  | `enabledPlugins` | An invalid entry is dropped with a warning and the other entries stay enforced. A value that isn't a map of plugin IDs, or whose every entry is invalid, is dropped whole with a warning. |

- Outside managed settings, an unrecognised `crossSessionInbound` value in a user, project, local, or `--settings` file
  makes Claude Code hold inbound messages while the value is present, even when a source that takes precedence sets
  `accept`; a `refuse` that another source sets still applies. Fix or remove the value to clear the hold.
  [settings-reference › `crossSessionInbound`](https://code.claude.com/docs/en/settings-reference#crosssessioninbound)
- `requiredMinimumVersion` and `requiredMaximumVersion` fail open by design: an invalid value is dropped rather than
  enforced.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)
- The tolerance for invalid entries applies only to managed settings. User, project, and local settings files remain
  strict: a file whose JSON or top-level shape fails validation is rejected as a whole and reported, and an individual
  entry that fails, such as a malformed permission rule, is skipped with a warning while the rest of the file applies.
  [managed-settings › Keys that fail closed](https://code.claude.com/docs/en/managed-settings#keys-that-fail-closed)
- When one value in your managed `sandbox` block is invalid, Claude Code doesn't drop the whole block, because it
  validates each field on its own. The warning for an invalid field names the field and tells you what happens to it,
  which depends on what the field controls:
  [managed-settings › Invalid values inside `sandbox`](https://code.claude.com/docs/en/managed-settings#invalid-values-inside-sandbox)
  - If you set a Boolean key to a quoted `"true"` or `"false"`, the value counts as that Boolean. Instead of a warning,
    `/status` shows a notice asking you to remove the quotes.
  - If `failIfUnavailable` is invalid, Claude Code drops the value rather than treating it as `true`, so an unreadable
    value never stops sessions from starting across your fleet.
  - Claude Code treats every other invalid Boolean as the value that keeps the sandbox strictest until you fix it. A
    key that turns the sandbox or one of its restrictions on, such as `enabled` or
    `network.allowManagedDomainsOnly`, counts as `true`. A key that loosens it, such as `allowUnsandboxedCommands`,
    counts as `false`.
  - In a list outside `credentials`, such as `excludedCommands` or `network.allowedDomains`, Claude Code drops an
    invalid entry and keeps the rest of the list. A list that isn't an array, or that has no valid entry, doesn't
    apply at all.
  - While `network.deniedDomains` or any entry in it is invalid, Claude Code also withholds `network.allowedDomains`,
    so the managed allowlist grants nothing until you fix the deny list.
  - While `filesystem.denyRead`, `filesystem.denyWrite`, or any entry in either is invalid, Claude Code also withholds
    both `filesystem.allowRead` and `filesystem.allowWrite` until you fix the deny list.
- For server-managed settings, when part of a payload fails schema validation, Claude Code surfaces a validation
  error and applies every remaining valid setting. Server-managed delivery adds these behaviors:
  [server-managed-settings › Invalid entries in delivered settings](https://code.claude.com/docs/en/server-managed-settings#invalid-entries-in-delivered-settings)
  - A startup that runs on the cache at `~/.claude/remote-settings.json` treats invalid entries the way the fetch that
    wrote the cache did: entries that failed validation stay dropped, keys that fail closed keep their stricter
    values, and an invalid `cleanupPeriodDays` or `desktopSessionCleanupPeriodDays` value stays in the cached copy and
    is never applied.
  - Claude Code applies nothing from a payload and leaves the cache unchanged when every setting in the payload fails
    validation, none of them falls back to a stricter value, and the payload holds a key other than those two
    retention keys. The startup notice, `/status`, and `claude doctor` then report the failed load with the cause
    `no setting in the server response could be applied as written`, which means the server answered but none of the
    settings it returned passed validation; ask your administrator to correct the settings on the server. That entry
    says which policy the session runs on. Clients that enforce fail-closed startup exit at startup instead.
    [errors › Remote managed settings failed to load](https://code.claude.com/docs/en/errors#remote-managed-settings-failed-to-load),
    [server-managed-settings › Invalid entries in delivered settings](https://code.claude.com/docs/en/server-managed-settings#invalid-entries-in-delivered-settings)
  - The security approval dialog evaluates the salvaged payload, so a stripped invalid entry is never presented for
    approval and never executes.
- To debug server-managed delivery issues, run `claude --debug-file <path>` and search the log for `Remote settings`.
  Validate a payload change with `claude doctor` on a test machine before rolling it out to the organization.
  [server-managed-settings › Invalid entries in delivered settings](https://code.claude.com/docs/en/server-managed-settings#invalid-entries-in-delivered-settings)
- `cleanupPeriodDays` is a whole number of days with a minimum of `1` and a default of `30`; setting `0` fails
  validation, so pick a large value such as `3650` for long retention.
  [settings-reference › `cleanupPeriodDays`](https://code.claude.com/docs/en/settings-reference#cleanupperioddays)
- When `forceRemoteSettingsRefresh` is `true` and the server-managed settings fetch fails, the session's last output
  includes `Your organization requires remote managed settings to load, but they could not be loaded.`
  [self-hosted-environments-configuration › Stop sessions that fail to fetch server-managed settings](https://code.claude.com/docs/en/self-hosted-environments-configuration#stop-sessions-that-fail-to-fetch-server-managed-settings)
- Claude Code shows `Remote managed settings failed to load` in interactive sessions when your session is eligible for
  server-managed settings but Claude Code couldn't fetch them or couldn't apply what the server returned. The
  parenthesized cause names what failed, such as `network error`, `request timed out`, or
  `authentication rejected (401)`. The rest of the line says which policy the
  session runs on: with settings cached from an earlier successful fetch, Claude Code runs the session on that cached
  policy, except the withheld environment variables, and the line reads `using cached policy`; with no cache, Claude
  Code runs the session without server-managed settings, and the line reads `no remote policy applied`.
  [errors › Remote managed settings failed to load](https://code.claude.com/docs/en/errors#remote-managed-settings-failed-to-load)
  - Act on the cause the message names: for a network cause, check that this machine can reach `api.anthropic.com`;
    for an authentication cause, check your sign-in with `/status`.
  - Run `/status` or `claude doctor` for the full diagnostic.
- Declining the security approval dialog for server-managed settings that need your approval makes Claude Code exit
  without applying them, with `Managed settings were not approved; exiting without applying them.` Start Claude Code
  again and approve the dialog to continue under your organization's settings. A declined dialog isn't remembered, so
  it appears again at the next start. If you're unsure about a setting the dialog lists, ask whoever maintains your
  organization's managed settings before approving.
  [errors › Managed settings were not approved](https://code.claude.com/docs/en/errors#managed-settings-were-not-approved)
- A `claude plugin` command can't show the security approval dialog when it can't read from the keyboard, which
  happens when you pipe or redirect its input and, on macOS and Linux, it also can't open `/dev/tty`. The command stops
  before making any changes and prints `Your organization's managed settings need your approval, which couldn't be
  asked for here. Run `claude` in a terminal and approve them, then run this command again.` Run `claude` in a
  terminal and approve the settings when the dialog appears, then run the same `claude plugin` command again. Claude
  Code keeps the approval and the approved settings in your configuration directory. If the command that stopped ran as
  another user or with `CLAUDE_CONFIG_DIR` set, run `claude` the same way so that both use the same directory.
  [errors › Managed settings need your approval](https://code.claude.com/docs/en/errors#managed-settings-need-your-approval)
- When your organization's managed settings block the model the Default option resolves to and every model it could
  step down to, a session that would start on the Default option exits at startup instead of running a blocked model.
  Which message you see depends on the setting that blocks it. When a `deniedModels` list blocks it:
  [errors › Managed settings block the default model](https://code.claude.com/docs/en/errors#managed-settings-block-the-default-model)

  ```text
  Claude Code can't start: your organization's managed settings block the default model (claude-opus-5-5) in "deniedModels", and none of the models they allow can be used as the default instead. Ask your administrator to update "deniedModels" or "availableModels".
  ```

  When an `availableModels` list with `availableModelsMatch` set to `"exact"` omits it:

  ```text
  Claude Code can't start: your organization allows only the models listed in "availableModels", and none of them can be used as the default model (claude-opus-5-5 isn't listed). Ask your administrator to update "availableModels".
  ```

  If you administer the settings, add a model your users can run to `availableModels`, or narrow the `deniedModels`
  entries that block every fallback. If you don't administer them, send the message to your administrator. Your own
  settings files can't widen a managed `availableModels` or `deniedModels` list.
- When managed settings exclude the model that `--model`, `ANTHROPIC_MODEL`, or the `model` setting named, or your
  organization admin disabled it in the claude.ai admin console, startup shows `Model "<name>" is restricted by your
  organization's settings. Using <model> instead.` The same notice can appear mid-session after an admin disables the
  model the session is running on. Typing `/model <name>` for a restricted model is rejected and the session keeps its
  model: `Model '<name>' is restricted by your organization's settings. Run /model to choose a different model.` for
  an admin-console restriction, or `Model '<name>' is not available. Your organization restricts model selection.` for
  one managed settings set through `availableModels` or `deniedModels`. A family alias (`opus`, `sonnet`, `haiku`,
  `fable`) asks for the family: on the Anthropic API and on Claude Platform on AWS, a restricted alias resolves to the
  newest version your organization permits, and `/model <alias>` is rejected only when every version is restricted.
  Run `/model` to pick an allowed model (restricted models are hidden from the picker), remove or update the
  restricted value from the `--model` flag, `ANTHROPIC_MODEL` or the `model` field of a settings file so the notice
  doesn't recur, or ask your administrator to enable the model.
  [errors › Model is restricted by your organization's settings](https://code.claude.com/docs/en/errors#model-is-restricted-by-your-organizations-settings)
- Choosing the Default model, in the `/model` picker or with `/model default`, is refused when managed settings block
  it, and the session keeps its current model: `Can't switch to the default model: your organization's managed
  settings block it (<model>) in "deniedModels", and none of the models they allow can be used as the default
  instead.` The wording after the colon names the cause: a managed `deniedModels` list blocks the model the Default
  option resolves to; a managed `availableModels` allowlist with `availableModelsMatch` set to `"exact"` leaves it out
  (`your organization allows only the models listed in "availableModels"`); or Claude Code couldn't read the managed
  settings to check, which it refuses rather than apply unchecked. For the first two, run `/model` and pick an allowed
  model by name, or ask your administrator to update the managed setting the message names. For the `couldn't read`
  wording, restart Claude Code and, if it persists, ask your administrator to check the managed settings.
  [errors › Can't switch to the default model](https://code.claude.com/docs/en/errors#cant-switch-to-the-default-model)
- When managed settings set an `allowedProviders` list and the session's API provider isn't on it, or the session uses
  an endpoint that isn't pinned the way that entry requires, Claude Code refuses at startup, before a login, or when
  the session next contacts the API. The message begins `Your organization's managed settings allow Claude Code to
  use:` followed by the permitted providers. An empty list reads `allow Claude Code to use no API provider at all
  (allowedProviders is an empty list), so it cannot start on this machine`, and a list of only unrecognized entries
  reads `(allowedProviders lists only unrecognized entries)` instead. Follow the message's `To continue:` steps; if
  you administer the settings, its `Admins:` lines name the entry to add or the value to pin, and the
  `allowedProviders` entry says which source's `env` block can pin it.
  [errors › Managed settings don't allow this API provider](https://code.claude.com/docs/en/errors#managed-settings-dont-allow-this-api-provider)
- When a managed source sets `forceLoginMethod` to `"gateway"` or sets `forceLoginGatewayUrl`, Claude Code accepts only
  the Claude apps gateway sign-in unless you select a cloud provider through a variable such as
  `CLAUDE_CODE_USE_BEDROCK`. Model requests then fail with `Not signed in to the Cloud gateway — run /login.` when the
  session has no gateway sign-in; run `/login` and complete the sign-in on the **Cloud gateway** screen. If the machine
  also holds an Anthropic-issued credential (an `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` variable, an
  `apiKeyHelper` setting, or an API key saved by an earlier Claude Console login) and the managed settings set
  `forceLoginMethod` or `forceLoginOrgUUID`, Claude Code exits at startup with `Administrator policy requires a Cloud
  gateway sign-in on this machine`, naming the credential, where it's set, and the step that removes it. Follow that
  step. If the machine shouldn't require the gateway, ask the administrator to remove `forceLoginMethod` and
  `forceLoginGatewayUrl` from its managed settings.
  [errors › Administrator policy requires a Cloud gateway sign-in](https://code.claude.com/docs/en/errors#administrator-policy-requires-a-cloud-gateway-sign-in)
- Under a managed `allowManagedReadPathsOnly` or `allowManagedDomainsOnly`, the warning `sandbox.filesystem.allowRead
  is ignored — managed settings set allowManagedReadPathsOnly, so only allowRead paths from managed settings are
  honored. The 3 entries in /home/you/.claude/settings.json will NOT apply` appears in `/status` and `claude doctor`:
  the `allowRead` or `allowedDomains` entries in the file it names don't apply. For the network lock, the warning names
  `sandbox.network.allowedDomains` and `allowManagedDomainsOnly`, and says `only allowed domains (and WebFetch domain
  rules) from managed settings are honored`. You don't have to act on it. If you need those paths or domains, ask your
  administrator to add them to managed settings; the warning stays until you also remove the entries from the named
  file. For a file you share, such as a project's `.claude/settings.json`, you can leave the entries in for teammates
  without the lock and leave the warning showing.
  [errors › Sandbox allow entries are ignored under a managed lock](https://code.claude.com/docs/en/errors#sandbox-allow-entries-are-ignored-under-a-managed-lock)

## Auto mode denials

- When the model that auto mode uses to classify actions couldn't produce a decision, auto mode doesn't approve the
  action automatically. Reads, searches, and edits inside your working directory skip the classifier, so they keep
  working. When the classifier model is unavailable, the message is `<model> is temporarily unavailable, so auto mode
  cannot determine the safety of <tool> right now. Wait a moment and then try this action again.`
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
  - In an interactive session, a dim `Not run · auto mode's check had no usable answer` row appears under the tool
    call instead. Press `Ctrl+O` to read the message in the transcript viewer. The `gave no verdict` denials show the
    same row.
  - When Claude Code can determine the failure category, it names the category in parentheses after
    `temporarily unavailable`: `(rate-limited)`, `(overloaded)`, `(server error)`, `(timed out)`, or
    `(connection failed)`. If `(timed out)` or `(connection failed)` repeats, check your connection.
  - When no category fits, the message appears with no category in parentheses; more than one failure produces that
    form. On Amazon Bedrock, including the Mantle endpoint, it also appears when your AWS account can't invoke the
    model named in the message, and that failure repeats on every retry until your account is granted access to the
    model.
  - Retry after a few seconds; Claude sees the same message and usually retries on its own. A transient failure is
    unrelated to auto mode eligibility; you don't need to change settings. If retries keep failing, continue with
    read-only tasks and come back to the blocked action later.
  - On Amazon Bedrock, if the message returns on every retry, check that your account can invoke the model it names:
    for standard Amazon Bedrock models, confirm your IAM policy allows invoking it; for Mantle model IDs, contact
    your AWS account team.
  - If the message returns on every retry and names a model you set in `CLAUDE_CODE_AUTO_MODE_MODEL`, set one your
    provider serves or unset the variable.
  - When a classifier request fails because your OAuth token expired or was rotated by another session, Claude Code
    refreshes the token and retries the request once, so a routine token expiry doesn't surface as this message.
- When the classifier returned an unparseable response, the message is `Auto mode could not evaluate this action and
  is blocking it for safety — run with --debug for details`. Retry the action, which usually succeeds on the next
  attempt, or run `claude --debug` and repeat the action for details in the debug log.
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
- When a separate API safety check blocked the classifier request because of earlier conversation content, the
  message is `Auto mode could not evaluate this action and is blocking it for safety — a safety check separate from
  auto mode blocked this request because of earlier conversation content — it isn't about the action itself — run
  with --debug for details`. Claude Code denies the action but tells Claude this isn't a judgment that the action is
  unsafe, and to continue with other tasks rather than retry. These denials don't count toward auto mode's pause
  thresholds. In a non-interactive `-p` run, Claude Code doesn't stop the run, and it returns the denial to Claude in
  interactive sessions and in the main conversation of a `-p` run.
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
  - This is not a decision about your action. Content already in your conversation triggered a safety filter on the API
    when auto mode sent the conversation to the classifier. Retrying will not help; the same conversation content will
    trigger the filter again.
  - In an interactive session, switch to a different permission mode so you can approve the action when prompted, or
    start a fresh conversation without the triggering content.
- When the conversation is too long for Claude Code's classifier request and Claude Code can't compact it on its own,
  the message is `Auto mode classifier transcript exceeded context window — falling back to manual approval (try
  /compact to reduce conversation size)`. In an interactive session, auto mode falls back to a normal permission prompt
  for that action so you can approve or deny it manually, or you can run `/compact` to reduce the conversation size so
  subsequent actions fit within the classifier window again. Elsewhere in a `-p` run without a
  `--permission-prompt-tool` (a background subagent in a `-p` run is a separate case), there is no prompt to fall back
  to, so the action doesn't run and the run continues.
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
- Under server-side classifier review, auto mode denies an action when the server gives no verdict for it. The denial
  names a category in parentheses when Claude Code can determine one, such as `(timed out)`: `The server-side auto
  mode classifier gave no verdict (timed out), so auto mode cannot determine the safety of <tool>.` The rest of the
  message tells Claude whether one retry can help. Before some of these denials, Claude Code waits so that Claude's
  next attempt doesn't follow at once. During the wait in an interactive session, the spinner shows
  `Auto mode check unavailable` with a countdown, and pressing `Esc` interrupts the turn.
  [errors › The server returned no safety verdict](https://code.claude.com/docs/en/errors#the-server-returned-no-safety-verdict)
- After ten responses in a row with no verdict, auto mode stops the turn with `Auto mode is unavailable — the server
  returned no safety verdict for the last 10 responses, so Claude stopped. Send a message to try again, or switch out
  of auto mode.` In an interactive session, the message appears as a warning in the transcript and the turn ends. In a
  non-interactive `-p` run, the run ends and reports an execution error; with the default text output, the message
  prints on stderr. When a subagent hit the limit, the subagent stops before finishing, and Claude receives whatever it
  produced with a note that auto mode stopped it.
  [errors › The server returned no safety verdict](https://code.claude.com/docs/en/errors#the-server-returned-no-safety-verdict)
  - In an interactive session, press `Ctrl+O` to read the denial text in the transcript viewer.
  - If the denial names `(the conversation is too long for the check)`, run `/compact` at the Claude Code prompt to
    shorten the conversation. Until the conversation is shorter, sending another message gets the same denial. If you
    turned auto-compact off, turn it back on so Claude Code compacts on its own next time.
  - Send another message to have Claude try again. The count of responses starts over.
  - If the stop repeats and your requests go through an LLM gateway or proxy, check whether it cuts streaming
    responses short or rewrites them.
  - Set `CLAUDE_CODE_AUTO_MODE_SERVER=0` before you start Claude Code to use its own classifier requests instead.
  - To approve the actions yourself instead, switch out of auto mode.
  - On a direct connection to the Anthropic API, Claude Code compacts a conversation that has grown too long for the
    server's check.
- A `was not reviewed and did not run` denial means the conversation is too long for the auto mode classifier to check
  the action, so the action didn't run. Claude Code returns `<tool> was not reviewed and did not run: the conversation
  is too long for auto mode's classifier. Claude Code will try to compact the conversation before the next request; if
  this action is still needed after that, issue it again and it will be reviewed normally.` to Claude. If the
  compaction fails, later actions the classifier can't check get a `gave no verdict (the conversation is too long for
  the check)` denial or the `Auto mode classifier transcript exceeded context window` message. If the compaction
  succeeds, you don't need to do anything; if you see either of those messages, run `/compact` at the Claude Code
  prompt to shorten the conversation yourself, and if you turned auto-compact off, turn it back on.
  [errors › Was not reviewed and did not run](https://code.claude.com/docs/en/errors#was-not-reviewed-and-did-not-run)

## Sandbox failures

- Some commands fail inside the sandbox even though they work outside it. If your organization's sandbox is
  admin-required, Claude Code ignores the settings these fixes name in a project's settings files, so save them in
  `~/.claude/settings.json`, where they apply in every project. If a fix still has no effect, your organization's
  managed settings may set that key. A fix that adds an `excludedCommands` pattern removes the sandbox from the
  commands the pattern matches.
  [sandboxing › Troubleshooting](https://code.claude.com/docs/en/sandboxing#troubleshooting)
- **Host-not-allowed error**: many CLI tools need to reach specific hosts. Approve the host when prompted, or add it
  to `allowedDomains`. If your organization locks the allowlist with `allowManagedDomainsOnly`, there's no prompt, so
  ask your administrator to add the host.
  [sandboxing › Commands fail with a host-not-allowed error](https://code.claude.com/docs/en/sandboxing#commands-fail-with-a-host-not-allowed-error)
- **`jest` hangs or fails**: `watchman` is incompatible with the sandbox. Run `jest --no-watchman` instead.
  [sandboxing › `jest` hangs or fails](https://code.claude.com/docs/en/sandboxing#jest-hangs-or-fails)
- **Go-based CLIs fail TLS verification on macOS**: tools such as `gh`, `gcloud`, and `terraform` may fail TLS
  verification under Seatbelt. To run these tools outside the sandbox, add a pattern for each tool, such as `gh *`,
  to `excludedCommands`. The tool then runs with your full access and its stored credentials. If you are using
  `httpProxyPort` with a MITM proxy and custom CA, set `enableWeakerNetworkIsolation` to `true` instead.
  [sandboxing › Go-based CLIs fail TLS verification on macOS](https://code.claude.com/docs/en/sandboxing#go-based-clis-fail-tls-verification-on-macos)
- **`open`, `osascript`, or browser-based auth flows fail with error `-600` on macOS**: the sandbox blocks Apple Events
  by default. Set `allowAppleEvents` to `true` in your user, managed, or CLI settings to allow them. Alternatively,
  add a pattern such as `open *` to `excludedCommands`. Each `open` call then goes through the permission flow, and
  `open` can launch any file or app, including one Claude wrote.
  [sandboxing › `open`, `osascript`, or browser-based auth flows fail with error `-600` on macOS](https://code.claude.com/docs/en/sandboxing#open-osascript-or-browser-based-auth-flows-fail-with-error-600-on-macos)
- **`docker` commands fail**: `docker` is incompatible with the sandbox. Take the `docker` commands you need out of
  the sandbox with an `excludedCommands` pattern such as `docker compose *`. A narrower pattern takes fewer commands
  out of the sandbox.
  [sandboxing › `docker` commands fail](https://code.claude.com/docs/en/sandboxing#docker-commands-fail)
- **Chromium or rootless Podman fails inside the sandbox on Linux**: on Linux and WSL2, commands in the sandbox can't
  create user namespaces by default, so tools that rely on them fail:
  [sandboxing › Chromium or rootless Podman fails inside the sandbox on Linux](https://code.claude.com/docs/en/sandboxing#chromium-or-rootless-podman-fails-inside-the-sandbox-on-linux)
  - Chromium exits with `No usable sandbox!`
  - `unshare -U true` prints `unshare: unshare failed: Operation not permitted`. With `allowAllUnixSockets` on, it can
    print `No space left on device` instead.
  - Rootless Podman prints `cannot clone: Operation not permitted`, or stops earlier with `read-only file system` on
    one of its own folders.
  - In a session with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` set to `1`, start Chromium or Electron with `--no-sandbox`,
    and run any other tool yourself outside Claude Code. In that session, every command runs sandboxed, and the
    settings that the other fixes name have no effect.
  - For Chromium or Electron, start the browser with `--no-sandbox`. The Claude Code sandbox stays as it is, but the
    browser runs web content without its own sandbox.
  - For rootless Podman, Buildah, or a script or test command that runs a browser or `unshare`, add a pattern to
    `sandbox.excludedCommands`, such as `podman *`. Commands that match run outside the sandbox with your full access,
    and Claude can edit a script in your working directory before running it. The pattern has to match the command
    Claude runs, so for a browser, match the test command rather than the browser.
  - To keep Chromium's or Electron's own sandbox, or to run a nested bubblewrap or `unshare`, set
    `sandbox.allowNestedUserNamespaces` to `true` in `~/.claude/settings.json`, not the project's
    `.claude/settings.json`. A command that begins with `unshare` stays sandboxed whatever `excludedCommands` pattern
    you list, because `unshare` can start any other program. This setting alone isn't enough for rootless Podman or
    Buildah, which the sandbox stops in other ways too.
- **`pbcopy`, `xclip`, or `wl-copy` doesn't update the clipboard**: these utilities can fail to reach the system
  clipboard from inside the sandbox, in which case the text piped to them doesn't arrive. To put Claude's output on
  your clipboard, ask Claude to print it in its response, then run `/copy`, which writes to the clipboard from the
  Claude Code process rather than from a sandboxed command. When Claude pipes text to one of these tools, adding the
  tool to `excludedCommands` doesn't take that call out of the sandbox on its own.
  [sandboxing › `pbcopy`, `xclip`, or `wl-copy` doesn't update the clipboard](https://code.claude.com/docs/en/sandboxing#pbcopy-xclip-or-wl-copy-doesn’t-update-the-clipboard)
- **A git command fails with `unable to unlink old`**: `git merge`, `git checkout`, and similar commands fail with this
  when they need to replace a file the sandbox denies writes to. On Linux and WSL2 the error ends with
  `Read-only file system`. The file can be under a protected path such as `.claude/skills`, under one of your
  `denyWrite` entries, or outside the directories the sandbox lets commands write to at all. After the failure, Claude
  may offer to rerun the command outside the sandbox: approve that retry, or run the git command yourself in another
  terminal. If you've set `allowUnsandboxedCommands` to `false`, Claude can't offer the retry, so run the command
  yourself.
  [sandboxing › A git command fails with `unable to unlink old`](https://code.claude.com/docs/en/sandboxing#a-git-command-fails-with-unable-to-unlink-old)
- **A folder named `objects` or `refs` disappears after a command**: a top-level `objects` or `refs` folder that
  appeared during the session can be deleted after a sandboxed command ends. It doesn't matter whether a command,
  Claude, or you created it. To keep a folder, leave something in it. If a `HEAD` file or symlink has been at the
  top level during the session, move it away, then restart every Claude Code session open there.
  [sandboxing › A folder named `objects` or `refs` disappears after a command](https://code.claude.com/docs/en/sandboxing#a-folder-named-objects-or-refs-disappears-after-a-command)
- **Bubblewrap fails to start inside a container**: in an unprivileged container, bubblewrap can't mount a fresh
  `/proc` filesystem, so sandboxed commands fail with a `bwrap` error such as
  `Can't mount proc on /newroot/proc: Operation not permitted`. Setting `enableWeakerNestedSandbox` to `true` makes the
  sandbox bind-mount the container's existing `/proc` instead; use it only when the outer container already provides
  the isolation boundary you need.
  [sandboxing › Bubblewrap fails to start inside a container](https://code.claude.com/docs/en/sandboxing#bubblewrap-fails-to-start-inside-a-container)
- **`git` over SSH fails with the sandbox on**: on macOS, `git fetch`, `git pull`, and `git push` against an SSH remote
  fail inside the sandbox even when the host is allowed. On Linux and WSL2, they work once the host is allowed. Claude
  Code tunnels git's SSH connection through the sandbox proxy, and the macOS tunnel can't authenticate to that proxy.
  [sandboxing › `git` over SSH fails with the sandbox on](https://code.claude.com/docs/en/sandboxing#git-over-ssh-fails-with-the-sandbox-on)
  - On Linux and WSL2, check these if the connection still fails: the host is allowed on port 22 (an `allowedDomains`
    entry with no port, such as `"git.example.com"`, covers it); your corporate proxy permits port 22 (if your network
    requires an upstream proxy, the tunnel goes through it too); the key is readable as a file (the sandbox can block
    the `ssh-agent` socket, and a `denyRead` or `credentials` entry for `~/.ssh` hides your key files).
  - On macOS, switch the remote to HTTPS, which needs HTTPS credentials such as a personal access token:

    ```bash
    git remote set-url origin https://git.example.com/example-org/example-repo.git
    ```

  - If you have to keep the SSH remote, take git's network commands out of the sandbox with `excludedCommands`:

    ```json
    {
      "sandbox": {
        "excludedCommands": ["git fetch *", "git pull *", "git push *"]
      }
    }
    ```

    These entries match `git push origin main`. A call that adds a `cd`, uses `git -C`, or contains a command
    substitution stays sandboxed. The excluded git commands can reach any host, not only the ones in
    `allowedDomains`.
  - Plain `ssh`, `scp`, and `rsync` over SSH fail for the reason the next bullet gives.
- **A database client or other non-HTTP tool fails to reach an allowed host**: a tool that ignores the proxy
  environment variables can't connect from inside the sandbox, even to a host in `allowedDomains`. A sandboxed command
  has no direct route to the network, so a tool that opens its own connection fails. Most database drivers, plain
  `ssh`, and tools that use UDP behave this way.
  [sandboxing › A database client or other non-HTTP tool fails to reach an allowed host](https://code.claude.com/docs/en/sandboxing#a-database-client-or-other-non-http-tool-fails-to-reach-an-allowed-host)
  - The failure looks like a network or name resolution error. On macOS: `Operation not permitted`, or a name
    resolution error such as `Could not resolve host`. On Linux and WSL2: `Network is unreachable`, or a name
    resolution error such as `Temporary failure in name resolution`.
  - A tool that uses the proxy fails differently when its host isn't allowed: you get a network prompt, or the tool
    receives a `403` response from the proxy.
  - To let the tool connect, run the command that needs it outside the sandbox with `excludedCommands`. This example
    excludes one script and adds an ask rule so that you approve each run:

    ```json
    {
      "sandbox": {
        "excludedCommands": ["python scripts/load_orders.py *"]
      },
      "permissions": {
        "ask": ["Bash(python scripts/load_orders.py *)"]
      }
    }
    ```

    The script runs with your full access, and Claude can edit a script that's inside your working directory, so
    review it when the prompt appears.
- **A command fails to reach a server on localhost**: by default, a sandboxed command can't connect directly to a
  server that's running on your machine outside the sandbox, such as a dev server or a database in a container.
  [sandboxing › A command fails to reach a server on localhost](https://code.claude.com/docs/en/sandboxing#a-command-fails-to-reach-a-server-on-localhost)
  - **macOS**: set `network.allowLocalBinding` to `true`.
  - **Linux and WSL2**: a sandboxed command's `localhost` is private to that command. The command can listen on a port
    and reach servers it started itself. A direct connection to `localhost` or `127.0.0.1` doesn't reach servers on
    the host, and `allowLocalBinding` has no effect. Run the command that needs the host's server outside the sandbox
    with `excludedCommands`, where it has no filesystem or network limits.
  - An `allowedDomains` entry for `localhost` applies to connections that go through the proxy, so it doesn't change a
    direct connection. Claude Code sets `NO_PROXY` for sandboxed commands so that they connect to `localhost` directly
    instead of through the proxy. The entry also exposes every port on your machine's localhost to a command that does
    use the proxy.
- **An allowed hostname is refused with `resolved to a loopback address`**: the sandbox proxy refuses an allowed
  hostname that resolves to a local address, which affects development names such as `myapp.test` that point at
  `127.0.0.1`. The command sees a `403` response whose body names the kind of address, such as
  `Connection to myapp.test blocked: resolved to a loopback address`. Add the IP address the name resolves to beside
  the hostname in `allowedDomains`, each with the port your server listens on, such as `myapp.test:3000` and
  `127.0.0.1:3000`. An IP address entry with no port lets sandboxed commands reach every service listening on that
  address.
  [sandboxing › An allowed hostname is refused with `resolved to a loopback address`](https://code.claude.com/docs/en/sandboxing#an-allowed-hostname-is-refused-with-resolved-to-a-loopback-address)

## Sandbox refusals, locks and leftover files

- If you require the sandbox with `sandbox.failIfUnavailable` and it fails in one of these ways after Claude Code
  starts, each sandboxed command Claude runs is refused with the message shown. The session keeps running, and the
  refused command doesn't run unsandboxed:
  [sandboxing › Commands are refused with `Sandbox is required`](https://code.claude.com/docs/en/sandboxing#commands-refused-with-sandbox-is-required)
  - **`Sandbox is required but failed to initialize: <reason>`**: Claude Code started, but the sandbox then failed to
    initialize. Take the step the message gives: `Restart to retry.` or `Fix the sandbox settings to retry`.
  - **`Sandbox is required (sandbox.failIfUnavailable) and stopped being available in this session: <reason>`**: on
    Linux or WSL2, the sandbox started and Claude Code then found a dependency missing. Fix what the reason names,
    such as installing a missing dependency, then restart Claude Code.
  - Excluded commands and commands you type yourself keep running, and Claude can't retry a refused command
    unsandboxed. Commands that match an `excludedCommands` entry keep running outside the sandbox. When one writes to a
    `filesystem.allowWrite` path outside your working directory, that write goes through the regular permission flow.
    Under an admin-required sandbox, Claude Code ignores entries from the repository's settings.
  - Commands you type at the `!` shell-mode prompt keep running outside the sandbox. In a background session, they're
    refused too.
  - Claude Code ignores the `dangerouslyDisableSandbox` parameter of an unsandboxed retry.
  - In a Linux session with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` set, every command runs sandboxed, so excluded commands
    and commands you type are refused too.
- `/sandbox` prints `Error: Sandbox settings are overridden by a higher-priority configuration and cannot be changed
  locally.` instead of opening its panel when a higher settings level sets `sandbox.enabled`,
  `sandbox.autoAllowBashIfSandboxed`, or `sandbox.allowUnsandboxedCommands`. The panel saves your choices to
  `.claude/settings.local.json`, and a value saved there can't override those levels. Managed settings and `--settings`
  rank above local settings. To see which of them this session loaded, run `/status` and read the `Setting sources`
  line:
  [sandboxing › `/sandbox` fails with `Sandbox settings are overridden by a higher-priority configuration`](https://code.claude.com/docs/en/sandboxing#/sandbox-fails-with-sandbox-settings-are-overridden-by-a-higher-priority-configuration)
  - **`Command line arguments`**: if you started Claude Code with `--settings`, check whether the file or JSON you
    passed sets one of those keys. If it does, change the value there, or start Claude Code again without those keys.
  - **`Enterprise managed settings`**: your organization's managed settings are loaded. If they set one of those keys,
    you can't change that key from `/sandbox` or from any settings file you control, so ask your administrator.
- `/sandbox` prints `Sandbox settings not changed` when it couldn't save the choice you made in its panel to your
  project's `.claude/settings.local.json`:
  [sandboxing › `/sandbox` prints `Sandbox settings not changed`](https://code.claude.com/docs/en/sandboxing#/sandbox-prints-sandbox-settings-not-changed)

  ```text
  ✗ Sandbox settings not changed: /home/you/project/.claude/settings.local.json couldn't be updated (EACCES). Start Claude Code in a project folder you can write to.
  ```

  - If the reason in parentheses is `EACCES`, `EPERM`, or `EROFS`, start Claude Code in a project folder you can write
    to, then run `/sandbox` again in that session. If the reason begins with `Invalid JSON syntax in settings file`,
    correct the JSON in your project's `.claude/settings.local.json`, then run `/sandbox` again.
  - If no writable project folder is available to you, turn the sandbox on from your user settings instead. Add this to
    `~/.claude/settings.json`:

    ```json
    {
      "sandbox": {
        "enabled": true
      }
    }
    ```

    This turns on auto-allow mode. For regular permissions mode, also set `sandbox.autoAllowBashIfSandboxed` to
    `false`. The change takes effect in your running session at the next shell command Claude runs, and the **Mode**
    tab of `/sandbox` then marks the mode in effect.
- The sandbox mask files warning in `claude doctor` and `/status` lists mask files: 0-byte read-only placeholder files
  at paths the sandbox denies writes to. It appears on Linux and WSL2 when sandboxing is enabled with filesystem
  isolation on. Delete them from your shell once no Claude Code session is open in the project that holds them. The
  sandbox creates a placeholder while a sandboxed command runs and removes it when the command ends; one stays behind
  when the session is killed before the command ends (for example by SIGKILL), or when you quit the session while a
  sandboxed command is still running, such as one in the background.
  [errors › Sandbox mask files left behind at write-deny paths](https://code.claude.com/docs/en/errors#stale-sandbox-mask-files-left-by-a-killed-session)
  - In `claude doctor`, the warning reads: `- Sandbox mask files left behind at write-deny paths:
    /home/you/project/.claude/settings.local.json`, with a `Fix:` line saying a 0-byte read-only file where a settings
    file belongs makes "Yes, and don't ask again" fail to save, and the sandbox binds it read-only again on every
    start.
  - Quit every Claude Code session open in the project that holds the listed files, including any session where
    `/status` showed the warning, then work from your shell. A placeholder that another session's sandbox is still
    using is a live part of that session's write protection.
  - In your shell, delete each listed file with `rm`, and confirm if `rm` asks about a write-protected file. The warning
    names up to three files and counts the rest, so run `claude doctor` again after deleting until the warning no
    longer appears.
  - If a permission choice you saved with "Yes, and don't ask again" didn't stick, save it again after deleting the
    placeholder.

# Troubleshooting hooks

Checking whether a hook runs and why not: `/hooks`, the debug log, error notices, validation, plugin hook errors and
OpenTelemetry hook events.

## Contents

- Check that a hook loaded
- See what a hook did
- A hook never fires
- Hook error notices
- Hooks failing on Windows
- Hook JSON has no effect
- Stop hook hits the block cap
- Limitations
- Plugin hooks
- Hooks and worktrees
- Trust and skipped hooks
- OpenTelemetry hook events and spans
- Not stated by the documentation

## Check that a hook loaded

- Type `/hooks` to open a read-only browser for your configured hooks. The list labels each hook with where it comes
  from, such as user settings, project settings, local settings, a plugin, or the current session. Select a hook to see
  the full text of what it runs and where it's defined, such as the path of its settings file or the name of its
  plugin. To browse all hook events, including ones with no hooks configured, select `All events` at the end of the
  list.
  [hooks › The `/hooks` menu](https://code.claude.com/docs/en/hooks#the-/hooks-menu)
- Run `/hooks` to list every hook registered for the current session, grouped by event. If a hook you defined doesn't
  appear, Claude Code didn't load it.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- A hook defined in a standalone file doesn't load: hooks go under the `"hooks"` key in a settings file. Only plugins
  load a separate `hooks/hooks.json`.
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)
- A `matcher` value that is an array instead of a single string makes Claude Code list the entry as an invalid setting
  when you start an interactive session and in `claude doctor`. If the array is under `PreToolUse` or
  `PermissionRequest`, none of that file's other hooks load either.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- Hooks configured in `~/.claude.json` are ignored; put them in `~/.claude/settings.json`.
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)
- If `/hooks` still shows the old definition a few seconds after you save a settings file, run `/hooks` again to
  refresh the view.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- If `/hooks` still shows no hooks after you edited a settings file and refreshed it, the file watcher may have missed
  the change: restart your session to force a reload.
  [hooks-guide › `/hooks` shows no hooks configured](https://code.claude.com/docs/en/hooks-guide#/hooks-shows-no-hooks-configured)
- In the settings file, trailing commas and comments aren't allowed in the JSON, and the file must be at
  `.claude/settings.json` for project hooks or `~/.claude/settings.json` for global hooks.
  [hooks-guide › `/hooks` shows no hooks configured](https://code.claude.com/docs/en/hooks-guide#/hooks-shows-no-hooks-configured)
- If the menu shows `Only hooks from managed settings run here`, your organization has set `allowManagedHooksOnly`.
  Hooks in your user, project, and local settings files don't run and aren't listed.
  [hooks-guide › `/hooks` shows no hooks configured](https://code.claude.com/docs/en/hooks-guide#/hooks-shows-no-hooks-configured)
- At the start of an interactive session, a settings file with an unknown hook event name produces a Settings
  Warning: Claude Code skips only the failing entries and keeps the rest of the file in effect. After you continue,
  run `/status` to see the affected files and `claude doctor` for the details of each error.
  [settings › Fix a broken settings file](https://code.claude.com/docs/en/settings#fix-a-broken-settings-file)
- In the VS Code extension, select **Hooks** in the Customize section to view the hooks loaded in the session, grouped
  by event. You can add, edit, or remove hooks saved in your user, project, and local settings files. Hooks from other
  sources, such as managed settings or plugins, are read-only.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)
- The `/doctor` setup checkup flags slow hooks, under Extensions.
  [skills › Check your setup with `/doctor`](https://code.claude.com/docs/en/skills#check-your-setup-with-/doctor)
- A managed settings source that holds a hook entry Claude Code can't load makes a `-p` run print a stderr block
  headed `Managed settings contain invalid entries, including PreToolUse/PermissionRequest hooks that are NOT loaded;
  fix or remove each entry:`, followed by one line per entry in the form `<source> (<field>): <message>`. That hook
  doesn't run, and when a line lists the source's `hooks` field as ignored, none of that source's hooks run. Each line
  names the source, the field when there is one, and the problem, such as an unknown hook `type` or a hook declared
  outside the `hooks` key. If you administer the source, fix or remove each listed entry. If a line's source is
  `parent managed settings`, report it to the developer of the application that launched Claude Code. Otherwise send
  the block to your administrator.
  [errors › Managed settings contain invalid entries, including PreToolUse/PermissionRequest hooks that are NOT loaded](https://code.claude.com/docs/en/errors#managed-settings-hooks-not-loaded)

## See what a hook did

- Press `Ctrl+O` to open the transcript view to check the outcome of a hook run. A successful run shows nothing,
  unless the hook's JSON surfaces something, such as `systemMessage` or Stop hook feedback. To confirm a hook ran,
  check for its effect, like a reformatted file, or turn on debug logging and trigger the hook again. This holds for
  a plugin's `PostToolUse` hook that exits 0 too.
  [hooks-guide › Check what a hook did](https://code.claude.com/docs/en/hooks-guide#check-what-a-hook-did),
  [plugins/components › Hooks](https://code.claude.com/docs/en/plugins/components#hooks)
- A blocking error shows the message that came with the block on most events, for example
  `Blocked: rm commands are not allowed`. On a few events, such as `ConfigChange` and `Elicitation`, you see no
  message.
  [hooks-guide › Check what a hook did](https://code.claude.com/docs/en/hooks-guide#check-what-a-hook-did)
- A non-blocking error means the action proceeded, and you see a `<hook name> hook error` notice with a short
  explanation, such as the first line of stderr prefixed with `Failed with non-blocking status code:`, or a JSON
  validation or parse message.
  [hooks-guide › Check what a hook did](https://code.claude.com/docs/en/hooks-guide#check-what-a-hook-did)
- Hook execution details, including which hooks matched, their exit codes, stdout and stderr, are written to the debug
  log file. Start Claude Code with `claude --debug-file <path>` to write the log to a known location, or run
  `claude --debug` and read the log at `~/.claude/debug/<session-id>.txt`. The `--debug` flag doesn't print to the
  terminal. To check a hook, trigger the event it matches, such as asking Claude to edit a file to trigger a
  `PostToolUse` hook, then read the log: a hook that ran shows up there with its exit code.
  [hooks › Debug hooks](https://code.claude.com/docs/en/hooks#debug-hooks),
  [plugins/create › Test and debug](https://code.claude.com/docs/en/plugins/create#test-and-debug),
  [plugins/troubleshooting › Hook loads but never fires](https://code.claude.com/docs/en/plugins/troubleshooting#hook-loads-but-never-fires)
- To watch the log live, start with `claude --debug-file /tmp/claude.log`, then run `tail -f /tmp/claude.log` in another
  terminal. If you started without that flag, run `/debug` mid-session to enable logging and find the log path.
  [hooks-guide › Check what a hook did](https://code.claude.com/docs/en/hooks-guide#check-what-a-hook-did)
- For example, a `PostToolUse` hook on `Write` whose command prints `hook-ran` produces entries like these:
  ```text
  2026-07-19T02:03:24.382Z [DEBUG] Hook output does not start with {, treating as plain text
  2026-07-19T02:03:24.382Z [DEBUG] "Hook PostToolUse:Write (PostToolUse) success:\nhook-ran"
  ```
  [hooks › Debug hooks](https://code.claude.com/docs/en/hooks#debug-hooks)
- To find a slow hook, search the log for `Hooks:` lines that end in a duration. Each command hook on a tool event,
  `UserPromptSubmit`, `SessionStart`, `Stop`, and several other events leaves one when it finishes, whatever it
  printed. The line gives the event name, joined by a colon to the tool name or other value the hook matched on, then
  the hook's command in brackets, the plugin it came from if any, how the run ended, and how long it took, as in
  `Hooks: PostToolUse:Write [.claude/hooks/log-write.sh] finished with status 0 (31ms)`. A run can also end as
  `timed out after <N>ms`, `cancelled`, `moved to the background`, or `failed to start`. On some events, such as
  `Notification`, `SessionEnd`, and `PreCompact`, a command hook leaves a `completed with status` line without a
  duration instead.
  [hooks › Debug hooks](https://code.claude.com/docs/en/hooks#debug-hooks)
- For more granular hook matching details, set `CLAUDE_CODE_DEBUG_LOG_LEVEL=verbose` to see additional log lines such
  as hook matcher counts and query matching.
  [hooks › Debug hooks](https://code.claude.com/docs/en/hooks#debug-hooks)
- When a `PreToolUse` hook rewrites a Bash command's input, the debug log file contains a
  `modified tool input keys` line listing `command` and the other Bash input fields.
  [costs › Offload processing to hooks and skills](https://code.claude.com/docs/en/costs#offload-processing-to-hooks-and-skills)
- For `claude -p`, `--include-hook-events` includes hook lifecycle events in the output stream and requires
  `--output-format stream-json`. `SessionStart` and `Setup` hook events are always included and don't need the flag.
  Some hook events, such as `Notification`, `SessionEnd`, `PreCompact`, and `PostCompact`, never produce a
  `hook_started` event, even with this flag. For those events, Claude Code still emits `hook_progress` while a command
  hook that runs for more than a second produces output, and emits `hook_response` only when a hook that runs in the
  background finishes.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- In a headless stream, `hook_started`, `hook_progress`, and `hook_response` events appear while a configured
  `SessionStart` or `Setup` hook runs, ahead of `system/init`. These stream as the hook produces them.
  [headless › Read session metadata](https://code.claude.com/docs/en/headless#read-session-metadata)
- The reference's Exit code output section defines which exit-code and JSON combinations produce each outcome.
  [hooks-guide › Check what a hook did](https://code.claude.com/docs/en/hooks-guide#check-what-a-hook-did)

## A hook never fires

- When a hook is configured but never executes, run `/hooks` and confirm the hook appears under the correct event.
  Check that the matcher pattern matches the tool name exactly: matchers are case-sensitive. Verify you're triggering
  the right event type: `PreToolUse` fires before tool execution, `PostToolUse` fires after.
  [hooks-guide › Hook not firing](https://code.claude.com/docs/en/hooks-guide#hook-not-firing)
- If `/hooks` shows the hook but it still does not fire, start a session with `claude --debug` and trigger the tool
  call. The debug log records each event, which matchers were checked, and the hook's exit code and output.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- The `matcher` field is a single string that uses `|` to match multiple tool names, for example `"Edit|Write"`. A `,`
  separator is equivalent, so `"Edit,Write"` matches the same tools. A `matcher` that is a JSON array never fires.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks),
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)
- A lowercase `matcher` value such as `"bash"` never fires: matching is case-sensitive, and tool names are
  capitalized, such as `Bash`, `Edit`, `Write`, `Read`.
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)
- A misspelled tool name produces a matcher that matches nothing, so the hook fails silently.
  [debug-your-config › Check hooks](https://code.claude.com/docs/en/debug-your-config#check-hooks)
- Cleanup logic that never runs at session end means no `SessionEnd` hook is configured: add one in `settings.json`.
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)
- A `PermissionRequest` hook fires when Claude Code is about to ask you for permission.
  [hooks-guide › Hook not firing](https://code.claude.com/docs/en/hooks-guide#hook-not-firing)

## Hook error notices

- A message like "PreToolUse hook error: ..." in the transcript means your script exited with a non-zero code
  unexpectedly. Test it manually by piping sample JSON, then check the exit code:
  ```bash
  echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./my-hook.sh
  echo $?  # Check the exit code
  ```
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- If you see "command not found", use absolute paths or `${CLAUDE_PROJECT_DIR}` to reference scripts. To avoid shell
  quoting entirely, add `"args": []` to switch to exec form, which spawns the script directly without a shell.
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- If the message includes `blocking because Git Bash wasn't found`, you're on Windows, Claude Code didn't find Git
  Bash, and the failed or timed-out hook blocked the tool call. The fixes are under Hooks failing on Windows.
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- If you see "jq: command not found", install `jq` or use Python/Node.js for JSON parsing. If the script isn't running
  at all, make it executable with `chmod +x ./my-hook.sh`.
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- A JSON validation message in the notice means your hook's stdout parsed as JSON but failed schema validation. A JSON
  parse message means the stdout looked like a JSON object but wasn't valid JSON. Both happen even on exit 0. To fix a
  parse failure, build the payload with a JSON encoder such as `jq` instead of string concatenation, so quotes and
  backslashes inside values are escaped.
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- A notice of the form `... hook error: Failed with non-blocking status code: <stderr>` means the hook ran and its
  command failed. For example, `Stop hook error: Failed with non-blocking status code: /bin/sh: node: command not found`
  means the shell Claude Code spawned couldn't find `node`. Install it, or make sure it's on the `PATH` of the
  terminal you start `claude` from.
  [plugins/troubleshooting › `hook error` notices in the transcript](https://code.claude.com/docs/en/plugins/troubleshooting#hook-error-notices-in-the-transcript)
- For any other error, run the hook's command yourself from the plugin directory to see the full output, or capture the
  full stderr with debug logging.
  [plugins/troubleshooting › `hook error` notices in the transcript](https://code.claude.com/docs/en/plugins/troubleshooting#hook-error-notices-in-the-transcript)
- A notification in the conversation view that starts with the hook's event name and reads
  `Stop hook needs quotes around a path with a space (check.py)` means the script didn't run because its path has a
  space and isn't quoted. That hook is an `asyncRewake` hook in shell form, and its `command` has an interpreter such
  as `python3` followed by an unquoted path placeholder, and the resolved path contains a space. Wrap the path in
  double quotes in the `command` of the hook that runs the script the notification names. In a JSON file, write it as
  `"command": "python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/check.py\""`.
  [errors › Hook needs quotes around a path with a space](https://code.claude.com/docs/en/errors#hook-needs-quotes-around-a-path-with-a-space)
- In agent view's peek panel, when a `PermissionRequest` or `PreToolUse` hook returns output Claude Code can't validate
  for the call the session is asking about, the row shows the hook event and `hook output invalid:` with the validation
  error before the pending request's text. For a hook that fails another way, the row says the hook failed. The
  session still waits on the same request.
  [agent-view › Peek and reply](https://code.claude.com/docs/en/agent-view#peek-and-reply)
- In auto mode, a denied tool call with the reason `a hook changed this call's input after the model wrote it` means a
  hook changed the input after the server-side classifier reviewed it. The hook can be a `PreToolUse` settings hook
  (or a mod's `tool.call` or `turn.step` hook); the message doesn't say which.
  The message tells Claude to issue the call once more as recorded. If that's denied too, the hook changes the input
  every time, so turn off the mod or hook, or leave auto mode and approve the call yourself.
  [plugins/mods/troubleshoot › `a hook changed this call's input after the model wrote it`](https://code.claude.com/docs/en/plugins/mods/troubleshoot#a-hook-changed-this-calls-input-after-the-model-wrote-it)

## Hooks failing on Windows

- When the error for a blocked tool call includes `blocking because Git Bash wasn't found, so only exit code 0 or 2
  counts as this hook's verdict.`, a `PreToolUse` or `PermissionRequest` command hook failed or timed out and blocked
  the call. Without Git Bash, any exit code other than 0 or 2 from that hook counts as a failure, even when it prints
  JSON that doesn't deny the call. To find out why the hook failed, check the debug log, then pick the fix that
  matches the hook.
  [hooks › Failed hooks on Windows without Git Bash](https://code.claude.com/docs/en/hooks#failed-hooks-on-windows-without-git-bash)
  - The call should go ahead when the hook fails: add `"onFailure": "continue"` to the hook.
  - The hook exits 1 to warn but must block when it crashes: with `"onFailure": "continue"`, the call goes ahead on
    exit code 1, warning or crash alike. Add `"onFailure": "block"` instead, and have the script exit 0 where it
    warns, so those calls go ahead. To still show the warning on `PreToolUse`, print it to stdout as the
    `systemMessage` field of one JSON object.
  - The hook is written for Bash: without Git Bash, a shell-form hook with no `shell` set runs in PowerShell, where
    it can fail. Install Git for Windows, or set `CLAUDE_CODE_GIT_BASH_PATH` if Git Bash is installed where Claude
    Code doesn't find it. Then start a new session.
  - The hook runs one `.exe`, not a `.cmd` or `.bat` file: put the program in `command` and its arguments in `args`
    to use exec form, and add `"onFailure": "block"`. Claude Code then starts the program with no shell. Without
    `"onFailure": "block"`, the call can go ahead when the program fails, is missing, or times out.
  - A PowerShell guard hook that must block on failure: with `onFailure` unset, it stops doing so once Git for
    Windows is installed and Claude Code finds Git Bash. Add `"onFailure": "block"` so a failure or a timeout blocks
    the call with or without Git Bash. Also set `"shell": "powershell"` so the hook keeps running in PowerShell from
    then on instead of in Git Bash.
- If the error also says `PowerShell started no program`, start with the fixes in the next bullet, which PowerShell
  prints instead of running.
  [hooks › Failed hooks on Windows without Git Bash](https://code.claude.com/docs/en/hooks#failed-hooks-on-windows-without-git-bash)
- A hook with the error `PowerShell started no program` ran in PowerShell, which prints a `command` that is only
  quoted strings, such as `"command": "\"C:\\Tools\\guard.exe\""`, instead of running it.
  [hooks › PowerShell started no program](https://code.claude.com/docs/en/hooks#powershell-started-no-program)
  - To print text, such as JSON: set `"shell": "powershell"`, and the hook exits 0.
  - To run a `.ps1`, `.cmd`, or `.bat` file, or a `.exe` whose path has a variable: set `"shell": "powershell"` and put
    `&` before the quoted path. Leave `$HOME` as written, and spell environment variables as the `check.ps1` example
    in the hooks reference spells `$env:CLAUDE_PROJECT_DIR`.
  - To run one `.exe` at a path without `$`: remove the inner quotes from `command`, then apply the fix for a hook that
    runs one `.exe`, writing `"args": []` if the program takes no arguments.
  - To run a script written for Bash: apply the fix for a hook written for Bash.

## Hook JSON has no effect

- When your hook prints valid JSON but the decision doesn't take effect and no error appears in the transcript, the
  cause is either extra output before the JSON or a field at the wrong level. For a field at the wrong level, compare
  each field's placement against the JSON output format: for example, `permissionDecision` belongs inside
  `hookSpecificOutput`, not at the top level.
  [hooks-guide › Hook JSON has no effect](https://code.claude.com/docs/en/hooks-guide#hook-json-has-no-effect)
- Extra output before the JSON: hooks run in non-interactive shells, but Git Bash and some configurations, such as
  `BASH_ENV` pointing at `~/.bashrc`, still source your profile, and anything the profile prints reaches stdout ahead
  of your hook's JSON:
  ```text
  Shell ready on arm64
  {"decision": "block", "reason": "Not allowed"}
  ```
  [hooks-guide › Shell profile output before the JSON](https://code.claude.com/docs/en/hooks-guide#shell-profile-output-before-the-json)
- Unless the hook is async, Claude Code reads output that doesn't start with `{` as plain text, so your JSON is
  ignored, and because the hook exited 0 the transcript shows no error. To check for this cause, start Claude Code
  with `claude --debug`, trigger the hook, and search the debug log for `Hook output does not start with {`. To fix
  it, wrap the `echo` statements in your profile so they run only in interactive shells:
  ```bash
  # In ~/.zshrc or ~/.bashrc
  if [[ $- == *i* ]]; then
    echo "Shell ready"
  fi
  ```
  The `$-` variable contains shell flags, and `i` means interactive. Hooks run in non-interactive shells, so the echo
  is skipped.
  [hooks-guide › Shell profile output before the JSON](https://code.claude.com/docs/en/hooks-guide#shell-profile-output-before-the-json)
- When your hook returns `permissionDecision` or `additionalContext` at the top level instead of inside
  `hookSpecificOutput`, the JSON still parses, and Claude Code ignores the misplaced fields without reporting an
  error. To see which fields it ignored, start Claude Code with `claude --debug` and search the debug log for
  `Hook JSON output had unrecognized keys`.
  [hooks-guide › Fields at the wrong level](https://code.claude.com/docs/en/hooks-guide#fields-at-the-wrong-level)

## Stop hook hits the block cap

- When Claude keeps working instead of stopping and then ends the turn with a warning that the Stop hook blocked too
  many consecutive times: Claude Code overrides a Stop hook after it blocks eight times in a row with no tool call
  from Claude in between. Your hook script needs to check whether it already triggered a continuation. Parse the
  `stop_hook_active` field from the JSON input and exit early if it's `true`:
  ```bash
  #!/bin/bash
  INPUT=$(cat)
  if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
    exit 0  # Allow Claude to stop
  fi
  # ... rest of your hook logic
  ```
  [hooks-guide › Stop hook hits the block cap](https://code.claude.com/docs/en/hooks-guide#stop-hook-hits-the-block-cap)
- If your hook legitimately needs more than eight iterations to converge, raise the cap with
  `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`.
  [hooks-guide › Stop hook hits the block cap](https://code.claude.com/docs/en/hooks-guide#stop-hook-hits-the-block-cap)

## Limitations

- Command hooks communicate through stdout, stderr, and exit codes only. They can't trigger `/` commands or tool
  calls. Text returned via `additionalContext` is injected as a system reminder that Claude reads as plain text. HTTP
  hooks communicate through the response body instead.
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)
- `PostToolUse` hooks can't undo actions since the tool has already executed.
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)

## Plugin hooks

- A plugin's hooks that don't run, or one that blocks an action, show up in one of three ways: the **Errors** tab shows
  a load failure for them, the hooks load and you see `<Event> hook error` notices or a blocking error in the
  transcript, or a hook loads without error and never fires.
  [plugins/troubleshooting › `Failed to load hooks from <path>` and hooks that don't fire](https://code.claude.com/docs/en/plugins/troubleshooting#failed-to-load-hooks-from-and-hooks-that-dont-fire)
- `Failed to load hooks from <path>: <reason>` in the **Errors** tab means `hooks/hooks.json` isn't valid JSON or fails
  the hooks schema. The reason names the parse or validation error. Fix the file. To catch a JSON syntax problem in
  `hooks/hooks.json` before you publish the plugin, run `claude plugin validate <plugin-directory>` in your shell.
  [plugins/troubleshooting › Hooks fail to load](https://code.claude.com/docs/en/plugins/troubleshooting#hooks-fail-to-load)
- `hooks path escapes plugin directory: <path>` in the **Errors** tab means a `hooks` path the plugin declares leads
  outside the plugin directory or couldn't be confirmed inside it, so Claude Code drops that path and loads the rest
  of the plugin. The component name `hooks` in the message names the field that declared the path. A message that
  gives the full path of a marketplace plugin's own `hooks/hooks.json` means Claude Code skipped that file, because it
  can't confirm the file is inside the plugin or, for a plugin in a local marketplace, inside that marketplace. The
  message reports that file under the component name `hooks`, as in
  ```text
  hooks path escapes plugin directory: /home/user/my-marketplace/my-plugin/hooks/hooks.json — it resolves to /home/user/dotfiles/hooks.json, outside the plugin directory and its marketplace directory
  ```
  [errors › Path escapes plugin directory](https://code.claude.com/docs/en/errors#path-escapes-plugin-directory),
  [plugins/troubleshooting › Hooks fail to load](https://code.claude.com/docs/en/plugins/troubleshooting#hooks-fail-to-load)
- On macOS and Linux, Claude Code also rejects a component path that contains a backslash anywhere in it, even when the
  path stays inside the plugin, so a plugin whose paths use Windows-style separators loads on Windows only. To fix a
  `hooks` path error: if you installed the plugin and don't maintain it, report the message to its author; move a
  referenced file inside the plugin directory and point the path at it with a `./` relative path; replace a symlink
  that leads outside the plugin, or a folder above the path that is one, with a copy of what it points to; write a
  path that contains a backslash with forward slashes; and if the message ends with `EACCES`, restore your execute
  permission on every directory leading to the file the path names, following each symlink you reach.
  [errors › Path escapes plugin directory](https://code.claude.com/docs/en/errors#path-escapes-plugin-directory)
- `hooks path not found: <path>` in the **Errors** tab means the manifest's `hooks` field names a file that doesn't
  exist at that path relative to the plugin root. Fix the path or add the file.
  [plugins/troubleshooting › Hooks fail to load](https://code.claude.com/docs/en/plugins/troubleshooting#hooks-fail-to-load)
- If a `hook error` notice's stderr shows the plugin's path cut off at a space, the hook's shell-form command uses
  `${CLAUDE_PLUGIN_ROOT}` outside quotes and the install path contains a space. Wrap the variable in double quotes or
  use exec form. To find the unquoted variable, run `claude plugin validate` on the plugin's directory and look for its
  quoting warning.
  [plugins/troubleshooting › `hook error` notices in the transcript](https://code.claude.com/docs/en/plugins/troubleshooting#hook-error-notices-in-the-transcript)
- A plugin's hook fails with `Failed to run: Plugin directory does not exist: <path> (<plugin> — run /plugin to
  reinstall)`, and doesn't run, when the directory your session loaded the plugin's hooks from is gone from disk. Run
  `/reload-plugins` first, even though the message says to reinstall. The failure shows once per session for each hook
  event and command, so the hook going quiet doesn't confirm the fix. Read the reload's output instead: `Reloaded:` with
  no errors line means the plugin's hooks no longer point at the missing directory; `N errors during load. Run /plugin
  for details.` means open the **Errors** tab in `/plugin` and follow the plugins troubleshooting entry for the message
  it shows; a line that ends `Run /reload-plugins --force to apply.` means nothing reloaded and the hooks keep
  failing, so run `/reload-plugins --force`. `Plugin directory not found at path: <path>` is a different message,
  about a marketplace entry.
  [plugins/troubleshooting › `Plugin directory does not exist: <path>`](https://code.claude.com/docs/en/plugins/troubleshooting#plugin-directory-does-not-exist)
- A plugin hook that exits with code 2 blocks the action it ran for. When its stderr is the blocking message, the error
  ends with `This hook comes from the <plugin> plugin.` so that you know which plugin to disable or fix. If that
  message shows the plugin's path cut off at a space, apply the unquoted `${CLAUDE_PLUGIN_ROOT}` fix above.
  [plugins/troubleshooting › A plugin hook blocks a tool call or prompt](https://code.claude.com/docs/en/plugins/troubleshooting#a-plugin-hook-blocks-a-tool-call-or-prompt)
- For a plugin hook that loads without error but never fires, first run `/plugin` in your session and open the
  plugin's details. A note there that begins `Its hooks.json hooks do not run` means another enabled plugin with the
  same name registered its hooks instead; the plugins loading page's section on two enabled plugins sharing a name says
  which copy that is and how to switch. Otherwise work through these checks: event names are
  case-sensitive, so confirm yours matches exactly, for example `PostToolUse`; confirm the hook's `matcher` matches
  the tool name; trigger the event on purpose; then read the debug log.
  [plugins/troubleshooting › Hook loads but never fires](https://code.claude.com/docs/en/plugins/troubleshooting#hook-loads-but-never-fires)
- `claude plugin validate` (or `/plugin validate <path>` in a session) prints `Found N errors` and `Validation failed`,
  then exits with code 1. Its table covers the messages that stop validation and two warnings, `No frontmatter block
  found` and `Unknown field '<key>'`, which stop it only when you pass `--strict`. For hooks:

  | Message | Cause | Fix |
  | :- | :- | :- |
  | `Invalid JSON syntax: <parse error>` | The manifest, or `hooks/hooks.json`, isn't valid JSON. | Fix the JSON. Until you fix `hooks/hooks.json`, a session loads the plugin without the hooks in that file. |

  [plugins/troubleshooting › `claude plugin validate` reports errors](https://code.claude.com/docs/en/plugins/troubleshooting#claude-plugin-validate-reports-errors)
- Claude Code reloads every active plugin and prints one summary line:
  `Reloaded: N plugins · N skills · N agents · N hooks · N plugin MCP servers · N plugin LSP servers`. It omits the
  plugin MCP server count in a session without an interactive terminal. When any plugin failed, the summary adds
  `N errors during load. Run /plugin for details.`
  The agents count is the number of agents loaded in the session, including ones that don't come from plugins.
  [plugins/cli-reference › Reload summary](https://code.claude.com/docs/en/plugins/cli-reference#reload-summary)

## Hooks and worktrees

- `Can only use --worktree in a git repository` means you passed `--worktree` in a directory that isn't a git
  checkout and no `WorktreeCreate` hook is active. In a checkout of another version control system, set up that hook;
  in a folder with no version control, run `git init` and create a first commit; or start Claude without `--worktree`.
  [worktrees › `Can only use --worktree in a git repository`](https://code.claude.com/docs/en/worktrees#can-only-use-worktree-in-a-git-repository)
- When Claude Code exits at startup because it can't enter the worktree directory, a `WorktreeCreate` hook may have
  printed something other than the directory it created, or the directory was deleted after it was set up.
  [worktrees › Claude Code can't enter the worktree at startup](https://code.claude.com/docs/en/worktrees#claude-code-can’t-enter-the-worktree-at-startup)
- A directory with no git metadata at all, such as one your `WorktreeCreate` hook creates, passes Claude Code's
  isolation-worktree check only when no git repository contains it. If the hook creates the directory inside a
  repository, git resolves it to that repository's checkout and Claude Code refuses it with the
  `git resolves its working tree to` message, so have the hook create its directories outside any repository.
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)
- When the refusal says `it contains the protected checkout`, the refused directory is a parent of your main
  checkout, such as your home directory. Don't delete it. Change the worktree path, such as the path your
  `WorktreeCreate` hook returns, so the worktree doesn't contain the checkout.
  [worktrees › Claude Code refuses to use a worktree](https://code.claude.com/docs/en/worktrees#claude-code-refuses-to-use-a-worktree)

## Trust and skipped hooks

- For the rows that need this exact folder trusted, such as a project subagent's frontmatter hooks, which aren't used
  when you trusted only a parent folder or ran `claude -p` or the SDK there, trust it by hand: set
  `projects["<path>"].hasTrustDialogAccepted` to `true` in `~/.claude.json`, where `<path>` is the repository root, or
  the folder itself outside a repository. Claude Code prints the exact key in the debug log line for a skipped
  subagent hook.
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)

## OpenTelemetry hook events and spans

- `claude_code.hook_registered` is logged once per configured hook at session start. Use it to inventory which hooks
  are active across your fleet, as a complement to the per-execution `hook_execution_start` and
  `hook_execution_complete` events. Its attributes are all standard attributes plus `event.name` (`"hook_registered"`),
  `event.timestamp`, `event.sequence` and the ones below.
  [monitoring-usage › Hook registered event](https://code.claude.com/docs/en/monitoring-usage#hook-registered-event)
  - `hook_event`: hook event type, such as `"PreToolUse"` or `"PostToolUse"`
  - `hook_type`: `"command"`, `"prompt"`, `"mcp_tool"`, `"http"`, or `"agent"`
  - `hook_source`: where the hook is defined: `"userSettings"`, `"projectSettings"`, `"localSettings"`,
    `"flagSettings"`, `"policySettings"`, or `"pluginHook"`
  - `safe_mode`: `"true"` when the session was started with `--safe-mode`, `"false"` otherwise
  - `hook_matcher` (when `OTEL_LOG_TOOL_DETAILS=1`): the matcher string from the hook configuration, when one is set
  - `plugin.name` (when `hook_source` is `"pluginHook"`): name of the contributing plugin. For plugins outside the
    official marketplace and built-in bundle the value is `"third-party"` unless `OTEL_LOG_TOOL_DETAILS=1`
  - `plugin_id_hash` (when `hook_source` is `"pluginHook"`): deterministic hash of the plugin name and marketplace,
    sent only to your configured exporter. Lets you count distinct contributing plugins without recording their names
- `claude_code.hook_execution_start` is logged when one or more hooks begin executing for a hook event. Attributes
  are all standard attributes plus `event.name` (`"hook_execution_start"`), `event.timestamp`, `event.sequence` and
  the ones below.
  [monitoring-usage › Hook execution start event](https://code.claude.com/docs/en/monitoring-usage#hook-execution-start-event)
  - `hook_event`: Hook event type, such as `"PreToolUse"` or `"PostToolUse"`
  - `hook_name`: Full hook name including matcher, such as `"PreToolUse:Write"`
  - `num_hooks`: Number of matching hook commands
  - `managed_only`: `"true"` when only managed-policy hooks are permitted
  - `hook_source`: `"policySettings"` or `"merged"`
  - `safe_mode`: `"true"` when the session was started with `--safe-mode`, `"false"` otherwise
  - `hook_definitions`: JSON-serialized hook configuration. Included only when both detailed beta tracing and
    `OTEL_LOG_TOOL_DETAILS=1` are enabled
- `claude_code.hook_execution_complete` is logged when all hooks for a hook event have finished. Attributes are all
  standard attributes plus `event.name` (`"hook_execution_complete"`), `event.timestamp`, `event.sequence` and the
  ones below.
  [monitoring-usage › Hook execution complete event](https://code.claude.com/docs/en/monitoring-usage#hook-execution-complete-event)
  - `hook_event`: Hook event type
  - `hook_name`: Full hook name including matcher
  - `num_hooks`: Number of matching hook commands
  - `num_success`: Count that completed successfully
  - `num_blocking`: Count that returned a blocking decision
  - `num_non_blocking_error`: Count that failed without blocking
  - `num_cancelled`: Count cancelled before completion
  - `total_duration_ms`: Wall-clock duration of all matching hooks
  - `stdout_chars`: Total characters of stdout across the matching hooks that succeeded
  - `additional_context_chars`: Total characters of `additionalContext` returned by the matching hooks
  - `system_message_chars`: Total characters of `systemMessage` returned by the matching hooks
  - `initial_user_message_chars`: Total characters of `initialUserMessage` returned by the matching hooks
  - `num_outputs_persisted`: Number of hook outputs over the 10,000-character cap that Claude Code saved to a file
  - `managed_only`: `"true"` when only managed-policy hooks are permitted
  - `hook_source`: `"policySettings"` or `"merged"`
  - `safe_mode`: `"true"` when the session was started with `--safe-mode`, `"false"` otherwise
  - `hook_definitions`: JSON-serialized hook configuration. Included only when both detailed beta tracing and
    `OTEL_LOG_TOOL_DETAILS=1` are enabled
- `claude_code.hook_plugin_metrics` is logged when an official-marketplace plugin hook emits per-invocation metrics.
  Only plugins installed from an official Anthropic marketplace can emit these. Third-party marketplace plugins and
  user-configured hooks don't emit to this event. Attributes are all standard attributes plus `event.name`
  (`"hook_plugin_metrics"`), `event.timestamp`, `event.sequence` and the ones below.
  [monitoring-usage › Hook plugin metrics event](https://code.claude.com/docs/en/monitoring-usage#hook-plugin-metrics-event)
  - `plugin_id`: plugin identifier in `<name>@<marketplace>` form
  - `hook_event`: hook event type that emitted the metrics
  - Up to 20 plugin-emitted metric keys. Names match `^[a-z][a-z0-9_]{0,39}$`. Values are Boolean or number.
- To find which tool call a hook refused, query `safety_event` where `category` is `"hook"` and `decision` is
  `"reject"`; for a blocked result or turn end, query `category` `"hook_review"`.
  [monitoring-usage › Map security questions to events](https://code.claude.com/docs/en/monitoring-usage#map-security-questions-to-events)
- `claude_code.safety_event` is also logged when a hook blocks a result. Its `decision` is `"sent_back"` when a hook
  blocked a result or turn end, its `reason_code` can be `"hook:PreToolUse"`, its `reason_type` can be `"hook"`, and
  its `hook_event` is `"pre_tool_use"` for a `PreToolUse` hook, or `"post_tool_use"`, `"post_tool_use_failure"`,
  `"stop"`, or `"subagent_stop"` on `"hook_review"` events.
  [monitoring-usage › Safety event](https://code.claude.com/docs/en/monitoring-usage#safety-event)
- In the safety event's `category`, `"hook"` means a hook, such as `PreToolUse` or `PermissionRequest`, with the detail
  attributes `hook_event` and `reason_code`. `"hook_review"` means a hook blocked the call's result or the end of a
  turn, with the detail attribute `hook_event`. `"user_rejected"` covers someone declining or dismissing a prompt
  that only a hook required, among other cases, with the detail attribute `decision_source`.
  [monitoring-usage › Safety event categories](https://code.claude.com/docs/en/monitoring-usage#safety-event-categories)
- A call that a `canUseTool` callback or `--permission-prompt-tool` tool approved at a prompt only a `PreToolUse` hook
  required has no safety event apart from `"hook_review"`, `"sandbox_network"` and `"sandbox_other"` events, which
  are sent after the call runs, so check it for a `tool_decision` event.
  [monitoring-usage › Calls without a safety event](https://code.claude.com/docs/en/monitoring-usage#calls-without-a-safety-event)
- Each user prompt starts a `claude_code.interaction` root span, and hook executions are recorded as its children.
  The `claude_code.hook` span sits beside `claude_code.llm_request` and `claude_code.tool`.
  [monitoring-usage › Span hierarchy](https://code.claude.com/docs/en/monitoring-usage#span-hierarchy)
- When a `PreToolUse` hook defers a tool call, Claude Code saves the trace context of the turn that deferred it. When
  you resume the session and the tool re-runs, the tool's spans join that earlier turn's trace as children of the
  turn's `claude_code.interaction` span.
  [monitoring-usage › Span hierarchy](https://code.claude.com/docs/en/monitoring-usage#span-hierarchy)
- The `claude_code.hook` span sets OpenTelemetry status `ERROR` when it records a failure.
  [monitoring-usage › Span attributes](https://code.claude.com/docs/en/monitoring-usage#span-attributes)
- The `claude_code.hook` span appears only when detailed beta tracing is active, which requires
  `ENABLE_BETA_TRACING_DETAILED=1` and `BETA_TRACING_ENDPOINT`, a pair that also changes where your logs and traces
  go. Set the pair in your shell, user settings, or managed settings; both variables are ignored in project and local
  settings. `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA` alone doesn't produce it. In interactive CLI sessions, detailed
  beta tracing also requires your organization to be allowlisted for the feature. Agent SDK and non-interactive `-p`
  sessions don't require allowlisting. Detailed beta tracing also adds content-bearing span attributes.
  [monitoring-usage › Span attributes](https://code.claude.com/docs/en/monitoring-usage#span-attributes),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `CLAUDE_CODE_PROPAGATE_TRACEPARENT`: set to `1` to propagate W3C trace context when `ANTHROPIC_BASE_URL` points at a
  custom proxy. Propagation covers the `traceparent` header on model and HTTP MCP requests and the `TRACEPARENT`
  environment variable for Bash, PowerShell, and hook subprocesses. By default, propagation is enabled only when
  connected directly to the Anthropic API.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- The `claude_code.hook` span's attributes:

  | Attribute | Description | Gated by |
  | - | - | - |
  | `hook_event` | Hook event type, such as `PreToolUse` | |
  | `hook_name` | Full hook name, such as `PreToolUse:Write` | |
  | `num_hooks` | Number of matching hook commands executed | |
  | `hook_definitions` | JSON-serialized hook configuration | `OTEL_LOG_TOOL_DETAILS` |
  | `duration_ms` | Wall-clock duration of all matching hooks | |
  | `num_success` | Count of hooks that completed successfully | |
  | `num_blocking` | Count of hooks that returned a blocking decision | |
  | `num_non_blocking_error` | Count of hooks that failed without blocking | |
  | `num_cancelled` | Count of hooks cancelled before completion | |

  [monitoring-usage › Span attributes](https://code.claude.com/docs/en/monitoring-usage#span-attributes)
- In the `tool_decision` event, `tool_use_id` is the unique identifier for the tool invocation and matches the
  `tool_use_id` passed to hooks, allowing correlation between OTel events and hook-captured data. Its `source`
  attribute is `"hook"` when a `PreToolUse` or `PermissionRequest` hook returned the decision.
  [monitoring-usage › Tool decision event](https://code.claude.com/docs/en/monitoring-usage#tool-decision-event)
- In the `managed_settings.settings` attribute of the managed settings resolved event (set when
  `OTEL_LOG_MANAGED_SETTINGS=1`), hooks follow the same redaction rules as other settings: fixed-option and numeric
  fields such as `type` and `timeout` show, while each command, URL, `matcher`, and `if` condition is exported as
  `"[REDACTED]"`.
  [monitoring-usage › Managed settings resolved event](https://code.claude.com/docs/en/monitoring-usage#managed-settings-resolved-event)

## Not stated by the documentation

- The `hook_event` value of a safety event for a `PermissionRequest` hook: the `"hook"` category lists `hook_event`
  as a detail attribute for hooks such as `PermissionRequest`, but the attribute's values name only `"pre_tool_use"`
  for a hook and the four `"hook_review"` values.
  [monitoring-usage › Safety event](https://code.claude.com/docs/en/monitoring-usage#safety-event)

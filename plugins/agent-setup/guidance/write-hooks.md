# Writing hooks

Writing a hook's event, handler, command and output so that it fires when it should and Claude can act on what it
returns.

These sections draw on Claude Code's hooks guide and hooks reference, with the costs and features pages for what a
hook's output adds to context, and the goal page for what a Stop hook can run.

## Contents

- Hooks run a command for a rule, a prompt hook for judgement
- Production hooks prefer command hooks to agent hooks
- A hook that must prevent a tool call runs before it
- Hooks on a file's change use FileChanged
- Hook enforcement doesn't rest on an if filter
- Only one hook rewrites a tool's input
- Hooks pass Claude only what it acts on
- Hook context is written as facts
- Hook context that goes stale on resume is refreshed by SessionStart
- A blocking Stop hook lets the turn end
- Hooks on the finished turn read last_assistant_message
- Hook commands use absolute paths
- Hook JSON is built with an encoder
- Hook scripts treat their input as untrusted
- Long-running hooks run async when they needn't block
- Hooks on every session, prompt or message stay fast

## Hooks run a command for a rule, a prompt hook for judgement

- Hooks give "deterministic control: certain actions always happen rather than relying on the LLM to choose to run
  them".
  [hooks-guide › Automate actions with hooks](https://code.claude.com/docs/en/hooks-guide#page-title)
- "For decisions that require judgment rather than deterministic rules, use `type: "prompt"` hooks."
  [hooks-guide › Prompt-based hooks](https://code.claude.com/docs/en/hooks-guide#prompt-based-hooks)
- A Stop hook "can run a script for deterministic checks or a prompt for model-evaluated ones."
  [goal › Compare ways to keep a session running](https://code.claude.com/docs/en/goal#compare-ways-to-keep-a-session-running)
- Prompt hooks run only on the events that support them; the events without them include `SessionStart`, `Setup`,
  `Notification`, `FileChanged` and `PreCompact`, where a decision needs a command hook.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)
- Check: on an event that supports prompt hooks, is each hook whose decision needs judgement a `prompt` hook, and is
  each hook whose decision is a fixed rule a command hook?

## Production hooks prefer command hooks to agent hooks

- "Agent hooks are experimental. Behavior and configuration may change in future releases. For production workflows,
  prefer command hooks."
  [hooks-guide › Agent-based hooks](https://code.claude.com/docs/en/hooks-guide#agent-based-hooks)
- Check: is each hook in a production workflow a command hook, with any agent hook there on purpose?

## A hook that must prevent a tool call runs before it

- `updatedToolOutput` in a `PostToolUse` hook "only changes what Claude sees. The tool has already run by the time the
  hook fires, so any files written, commands executed, or network requests sent have already taken effect." "To
  prevent or modify a tool call before it runs, use a PreToolUse hook instead."
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)
- Files referenced with `@` in a prompt are added without any tool call, so "no PreToolUse hook fires for them,
  including hooks matching `Read`. To block specific paths from `@` references, use a `Read` deny rule instead."
  [hooks › PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)
- Check: does each hook meant to stop or change a tool call run on `PreToolUse`, not `PostToolUse` or `FileChanged`,
  with a `Read` deny rule for paths that must not reach Claude through an `@` reference?

## Hooks on a file's change use FileChanged

- "To run a hook when a specific file changes on disk, whatever wrote it, use FileChanged instead of matching
  file-editing tools by name. Unlike PreToolUse, Claude Code runs FileChanged hooks after the change, and they have no
  decision control, so they can't block the write."
  [hooks › PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)
- Check: does each hook that must run when a specific file changes on disk, whatever wrote it, use `FileChanged`
  rather than a matcher on file-editing tools, and is none of them relied on to block the write?

## Hook enforcement doesn't rest on an if filter

- "When Claude Code can't determine which commands the Bash input runs, it runs your hook regardless of the pattern.
  Because the `if` filter is best-effort, use the permission system rather than a hook to enforce a hard allow or
  deny."
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)
- Check: does every hard allow or deny sit in a permission rule rather than in a hook selected by `if`?

## Only one hook rewrites a tool's input

- "When multiple `PreToolUse` hooks return `updatedInput` to rewrite a tool's arguments, the last one to finish takes
  effect. Since hooks run in parallel, the order is non-deterministic. Avoid having more than one hook modify the same
  tool's input."
  [hooks-guide › Limitations](https://code.claude.com/docs/en/hooks-guide#limitations)
- Check: does at most one hook return `updatedInput` for any one tool?

## Hooks pass Claude only what it acts on

- "Custom hooks can preprocess data before Claude sees it. Instead of Claude reading a 10,000-line log file to find
  errors, a hook can grep for `ERROR` and return only matching lines, reducing context from tens of thousands of
  tokens to hundreds." The page's example is a `PreToolUse` hook on `Bash` that rewrites a test command to show only
  failures; it shows the filtering only, and its `~` path and `"allow"` decision are the page's own:
  [costs › Offload processing to hooks and skills](https://code.claude.com/docs/en/costs#offload-processing-to-hooks-and-skills)

  ```json
  {
    "hooks": {
      "PreToolUse": [
        {
          "matcher": "Bash",
          "hooks": [{ "type": "command", "command": "~/.claude/hooks/filter-test-output.sh" }]
        }
      ]
    }
  }
  ```

  ```bash
  #!/bin/bash
  input=$(cat)
  cmd=$(echo "$input" | jq -r '.tool_input.command')

  # If running tests, filter to show only failures
  if [[ "$cmd" =~ ^(npm test|pytest|go test) ]]; then
    filtered_cmd="$cmd 2>&1 | grep -A 5 -E '(FAIL|ERROR|error:)' | head -100"
    echo "$input" | jq --arg filtered "$filtered_cmd" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow", updatedInput: (.tool_input + {command: $filtered})}}'
  else
    echo "{}"
  fi
  ```
- "Hooks are ideal for side effects (linting, logging) that don't need to affect Claude's context."
  [features-overview › Understand how features load](https://code.claude.com/docs/en/features-overview#understand-how-features-load)
- When a `PostToolUse` hook replaces a tool's output, "Stripping error details that Claude needs can cause it to
  proceed on a false assumption."
  [hooks › PostToolUse decision control](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)
- Check: does each hook that puts text in front of Claude, through its own output or by rewriting a command, cut it to
  what Claude acts on, such as failures, and does each hook that replaces a tool's output keep the error details
  Claude needs?

## Hook context is written as facts

- "Write the text as factual statements rather than imperative system instructions. Phrasing such as "The deployment
  target is production" or "This repo uses `bun test`" reads as project information. Text framed as out-of-band system
  commands can trigger Claude's prompt-injection defenses, which causes Claude to surface the text to you instead of
  treating it as context."
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Check: is all context a hook injects phrased as statements such as "This repo uses `bun test`", with nothing framed
  as system commands?

## Hook context that goes stale on resume is refreshed by SessionStart

- "For mid-session events like `PostToolUse` or `UserPromptSubmit`, when you resume with `--continue` or `--resume`,
  Claude Code replays the saved text rather than re-running the hook for past turns, so values like timestamps or
  commit SHAs become stale. `SessionStart` hooks run again on resume with `source` set to `"resume"`, or `"fork"` if
  you added `--fork-session`, so they can refresh their context."
  [hooks › Add context for Claude](https://code.claude.com/docs/en/hooks#add-context-for-claude)
- Check: is each value Claude would read as current after `--continue` or `--resume`, such as a timestamp or commit
  SHA, injected by a `SessionStart` hook rather than a mid-session hook?

## A blocking Stop hook lets the turn end

- "The `stop_hook_active` field is `true` when Claude Code is already continuing as a result of a stop hook. Check
  this value or process the transcript to avoid blocking on a condition that will never resolve."
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
- Check: does every command Stop hook that can block exit early when `stop_hook_active` is `true`, or process the
  transcript to tell a condition that will never resolve?

## Hooks on the finished turn read last_assistant_message

- For hooks that act on the just-completed turn, "such as read-aloud or notification hooks", use
  `last_assistant_message`, which "contains the text content of Claude's final response", rather than reading
  `transcript_path`.
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
  The transcript file "is written asynchronously and may lag the in-memory conversation, so it may not yet include the
  current turn's most recent messages when a hook fires."
  [hooks › Common input fields](https://code.claude.com/docs/en/hooks#common-input-fields)
- Check: does no hook that acts on the just-finished turn read `transcript_path` for Claude's final message?

## Hook commands use absolute paths

- If a hook fails with "command not found", "use absolute paths or `${CLAUDE_PROJECT_DIR}` to reference scripts. To
  avoid shell quoting entirely, add `"args": []` to switch to exec form, which spawns the script directly without a
  shell".
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- "Prefer exec form for any hook that references a path placeholder. In shell form, wrap each placeholder in double
  quotes."
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)
- "Use absolute paths: specify full paths for scripts. In exec form, use `${CLAUDE_PROJECT_DIR}` and the path needs no
  quoting. In shell form, wrap it in double quotes."
  [hooks › Security best practices](https://code.claude.com/docs/en/hooks#security-best-practices)
- `${CLAUDE_PROJECT_DIR}` is the project root, and `${CLAUDE_PLUGIN_ROOT}` the plugin's installation directory "for
  scripts bundled with a plugin".
  [hooks › Reference scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)
- Check: does each hook `command` reach its script by an absolute path, `${CLAUDE_PROJECT_DIR}` or, in a plugin,
  `${CLAUDE_PLUGIN_ROOT}`, in exec form or double-quoted in shell form?

## Hook JSON is built with an encoder

- When a hook's stdout looked like a JSON object but wasn't valid JSON, "build the payload with a JSON encoder such as
  `jq` instead of string concatenation, so quotes and backslashes inside values are escaped."
  [hooks-guide › Hook error in output](https://code.claude.com/docs/en/hooks-guide#hook-error-in-output)
- Check: does each hook build its JSON output with an encoder such as `jq`, not string concatenation?

## Hook scripts treat their input as untrusted

- "Command hooks execute shell commands with your full user permissions. They can modify, delete, or access any files
  your user account can access."
  [hooks › Disclaimer](https://code.claude.com/docs/en/hooks#disclaimer)
- The documented practices: validate and sanitise inputs ("never trust input data blindly"), always quote shell
  variables (`"$VAR"` not `$VAR`), block path traversal by checking for `..` in file paths, and skip sensitive files
  such as `.env`, `.git/` and keys.
  [hooks › Security best practices](https://code.claude.com/docs/en/hooks#security-best-practices)
- Check: does each hook script validate its input, quote shell variables, reject `..` in file paths and skip
  sensitive files?

## Long-running hooks run async when they needn't block

- "By default, hooks block Claude's execution until they complete. For long-running tasks like deployments, test
  suites, or external API calls, set `"async": true` to run the hook in the background while Claude continues
  working. Async hooks can't block or control Claude's behavior: response fields like `decision`,
  `permissionDecision`, and `continue` have no effect, because the action they would have controlled has already
  completed."
  [hooks › Run hooks in the background](https://code.claude.com/docs/en/hooks#run-hooks-in-the-background)
- "This field is only available on `type: "command"` hooks."
  [hooks › Configure an async hook](https://code.claude.com/docs/en/hooks#configure-an-async-hook)
- "After the background process exits, Claude Code delivers the `additionalContext` and `systemMessage` fields from the
  hook's JSON response to Claude on the next conversation turn."
  [hooks › How async hooks execute](https://code.claude.com/docs/en/hooks#how-async-hooks-execute)
- Check: does each command hook that runs a long task, such as a test suite, and needn't block or decide, set
  `"async": true`, and does no hook that must block, and no hook of another type, set it?

## Hooks on every session, prompt or message stay fast

- "SessionStart runs on every session, so keep these hooks fast."
  [hooks › SessionStart](https://code.claude.com/docs/en/hooks#sessionstart)
- Because a `UserPromptSubmit` hook "runs before every prompt and blocks model processing until it completes, a stuck
  hook stalls the session."
  [hooks › UserPromptSubmit](https://code.claude.com/docs/en/hooks#userpromptsubmit)
- For `MessageDisplay`: "Claude Code holds each batch until your hook returns, so keep the hook fast."
  [hooks › MessageDisplay](https://code.claude.com/docs/en/hooks#messagedisplay)
- Check: does each `SessionStart`, `UserPromptSubmit` and `MessageDisplay` hook do only quick work?

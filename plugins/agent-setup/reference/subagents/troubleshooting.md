# Troubleshooting subagents

Checking why a subagent doesn't load, launch or behave: skipped files, validation, error messages, API errors,
teammates launched instead, and what `/context` shows.

## Contents

- [Files that do not load](#files-that-do-not-load)
- [Launched as a teammate](#launched-as-a-teammate)
- [Launch and startup errors](#launch-and-startup-errors)
- [API errors and model IDs](#api-errors-and-model-ids)
- [Auto mode and subagents](#auto-mode-and-subagents)
- [Seeing subagents in a session](#seeing-subagents-in-a-session)

## Files that do not load

- Claude Code skips a file in a project, user, or managed `agents` directory, or in one under a directory you add
  with `--add-dir`, without reporting it in the session, when the frontmatter has any of these problems:
  - **No `name`**: Claude Code treats the file as documentation kept beside your agents.
  - **An opening `---` that isn't the file's first line**: Claude Code reads the file as having no frontmatter and
    treats it as documentation.
  - **A `name` that starts with `-`, contains `:`, or is longer than 256 characters**: Claude Code skips the file
    and writes an error to the debug log.
  - **A `name` but no `description`**: Claude Code skips the file and writes the reason to the debug log.
  - **YAML that doesn't parse**: Claude Code reads no fields from the file, skips it, and writes the parse error to
    the debug log.

  To see the debug log, run Claude Code with `--debug`.
  [sub-agents › Subagent files Claude Code skips](https://code.claude.com/docs/en/sub-agents#subagent-files-claude-code-skips)
- To find files in an `agents` directory whose frontmatter doesn't parse, run `claude plugin validate` against the
  directory, for example `.claude/agents` or `~/.claude/agents`. Claude Code checks only the directory you name, and
  doesn't flag a file whose frontmatter parses but has no `name`.
  [sub-agents › Check an `agents` directory before a session](https://code.claude.com/docs/en/sub-agents#subagent-files-claude-code-skips)
- Given a directory with no `.claude-plugin/marketplace.json` and no `.claude-plugin/plugin.json`, `claude plugin
  validate` picks the component files by the directory's name. A directory named `agents` validates the files
  inside it. A directory named `.claude` validates the `agents` directory inside it. Any other directory validates
  the `agents` directory under its `.claude`.
  [plugins/cli-reference › Validate a directory](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)
- Claude Code doesn't follow symlinks inside the directory you name. What it does depends on where the link is:
  - **A linked `agents` directory under the plugin or `.claude` root**: Claude Code warns that nothing in it was
    read.
  - **A linked entry inside an `agents` directory**: Claude Code skips it and warns, per directory, how many entries
    it skipped that a session would load.
  - **The `agents` directory you name is itself a symlink, or its parent `.claude` directory is**: Claude Code
    reports an error and checks nothing in it. Name the real directory instead.

  [plugins/cli-reference › Validate a directory](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)

## Launched as a teammate

- Symptom: in an interactive session with agent teams enabled, a subagent that Claude names launches as a teammate.
  Claude can name subagents on its own, so this can happen during delegation you never framed as team work.
  [agent-teams › Claude spawns teammates instead of subagents](https://code.claude.com/docs/en/agent-teams#claude-spawns-teammates-instead-of-subagents)
- To make named subagents launch as subagents again, turn agent teams off by setting
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` to `0`:

  ```json
  {
    "env": {
      "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "0"
    }
  }
  ```

  You don't need to start a new session: Claude Code reapplies settings-file `env` values to the running session
  when you save, and rereads the variable each time Claude spawns a subagent, so the next subagent Claude names
  launches as a subagent.
  [agent-teams › Claude spawns teammates instead of subagents](https://code.claude.com/docs/en/agent-teams#claude-spawns-teammates-instead-of-subagents)
- Setting the variable to `0` in your user `settings.json` overrides a shell export. Other settings sources can
  still enable agent teams:
  - **Higher-precedence settings files**: project settings, local settings, and a `--settings` payload apply after
    user settings, so an `env` entry that sets the variable to `1` in any of them wins.
  - **Managed settings**: managed settings apply after every other source. If your organization enables agent teams
    there, ask your administrator to change the managed value.

  [agent-teams › Claude spawns teammates instead of subagents](https://code.claude.com/docs/en/agent-teams#claude-spawns-teammates-instead-of-subagents)
- After the change, Claude may still name subagents, and the name keeps working as a `SendMessage` address. Claude
  receives each subagent's result when it completes.
  [agent-teams › Claude spawns teammates instead of subagents](https://code.claude.com/docs/en/agent-teams#claude-spawns-teammates-instead-of-subagents)

## Launch and startup errors

- A subagent whose `tools` list resolves to nothing is refused. Every entry in the subagent's `tools` list failed to
  match a usable tool, so Claude Code refused to launch the subagent: with no tools, it couldn't act. The message
  groups your entries by what went wrong:
  - **Unrecognized**: the entry matches no tool name, usually a typo such as `Grpe` for `Grep`.
  - **Not available to subagents**: the entry names a real tool that subagents can't use. Background subagents keep
    a smaller built-in tool set, so an entry that only a foreground subagent can use lands here when the subagent
    would run in the background, which is the default. If you list `Agent`, the message reports it under the next
    group instead.
  - **Matched no tools in this session**: the entry is valid but no tool in the current session matches it right
    now, such as `mcp__github__*` with no GitHub MCP server connected, or `Agent` for a subagent at the depth limit.

  ```text
  Agent 'code-reviewer' would be spawned with zero tools — refusing. Its tools list resolved to nothing: unrecognized [Grpe]. Fix the agent's tools frontmatter or pass a different subagent_type.
  ```

  [errors › Agent would be spawned with zero tools](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools)
- Omitting the `tools` field never triggers this refusal. If you leave the `tools` list empty, or `disallowedTools`
  removes every entry in it, Claude Code also skips the refusal and launches the subagent without tools.
  [errors › Agent would be spawned with zero tools](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools)
- Fixes for the zero-tools refusal:
  - Correct each entry the error names against the tools available to subagents.
  - Remove entries for tools the session doesn't have, such as MCP tools from a server that isn't connected.
  - If the entry names a connected MCP server, compare the entry with that server's name as the server's tool names
    spell it, such as `reports__v2` in `mcp__reports__v2__get_totals`. For that server, write
    `mcp__reports__v2__*`, which is `mcp__` followed by the whole name and `__*`. With the shorter `mcp__reports`,
    which names a server called `reports`, the subagent gets none of the `reports__v2` tools.
  - For a tool that background subagents drop, such as `CronCreate`, remove the entry.
  - To keep a tool such as `CronCreate` instead, let Claude wait for the subagent, since a subagent Claude waits
    for runs in the foreground and keeps the tool. If the definition sets `background: true`, remove that field
    first, because it keeps the subagent in the background.
  - Delete the `tools` field instead of listing tools to give the subagent every tool available to subagents.
  - For a `tools` list that contains only `Agent`, raise the depth limit or give the agent at least one other tool:
    Claude Code withholds `Agent` at that limit, so a list with nothing else in it resolves to no tools.

  [errors › Agent would be spawned with zero tools](https://code.claude.com/docs/en/errors#agent-would-be-spawned-with-zero-tools)
- `subagent_type is required: the general-purpose agent is not available in this session. Available agents: ...`
  means Claude called the Agent tool without a `subagent_type`, and this session has no general-purpose subagent to
  fall back on. That is the case in two setups:
  - `CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1` is set in non-interactive mode, which removes every built-in
    subagent.
  - The session's main-thread agent has a `tools: Agent(...)` allowlist that leaves out `general-purpose`.

  Usually nothing needs doing: the message lists the subagents the session does have, so Claude can retry with one of
  them. If Claude keeps failing, add `general-purpose` to the `tools: Agent(...)` allowlist, or unset
  `CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS`.
  [errors › subagent_type is required](https://code.claude.com/docs/en/errors#subagent-type-is-required)
- When the value passed to `--agents` is invalid, `claude` exits with code 1 instead of starting the session. When
  you pass `--safe-mode` or set `CLAUDE_CODE_SAFE_MODE`, Claude Code ignores `--agents` entirely. With `--resume` or
  `--continue`, an inline JSON value isn't checked and the session starts; a value read from a file is checked on
  every launch.

  ```text
  Error: Invalid --agents configuration:
  <what failed>
  ```

  [errors › Invalid `--agents` configuration](https://code.claude.com/docs/en/errors#invalid-agents-configuration)
- What follows the first line depends on how the value failed. Claude Code runs these checks in order and stops at
  the first one that fails. If your value has two kinds of problem, you see the second only after you fix the first:
  1. When the value begins with `{` but doesn't parse as JSON, or the contents of an `--agents` file don't parse,
     Claude Code prints one `invalid JSON:` line carrying the JSON parser's own message.
  2. When it parses but an agent definition doesn't match the schema for CLI-defined subagents, Claude Code prints
     one line per problem.
  3. When an agent name starts with `-`, Claude Code prints `<name>: agent names must not start with '-'`.

  When there are more than 20 problem lines, Claude Code prints the first 20 and replaces the rest with `…and N more`.
  Fix each problem the message lists, then run the command again.
  [errors › Invalid `--agents` configuration](https://code.claude.com/docs/en/errors#invalid-agents-configuration)
- With `--print`, `--agents` also accepts the path to a JSON file in place of the inline object. The file form has
  refusals of its own, printed in place of the invalid-configuration message, including these:
  - **`Error: --agents takes a JSON object, or a file path only with --print (-p)`**: Claude Code read the value as
    a file path in an interactive session. Pass the definitions as inline JSON, or add `-p` to read them from a
    file.
  - **`Error: --agents file not found: <path>`**: no file exists at that path. A value that doesn't begin with `{`
    and isn't valid JSON is read as a path, so inline JSON that your shell mangled can fail this way too. Check the
    path or the quoting and run the command again.

  [errors › Invalid `--agents` configuration](https://code.claude.com/docs/en/errors#invalid-agents-configuration)
- Passing `--append-subagent-system-prompt` together with `--append-subagent-system-prompt-file` in one `claude`
  invocation makes `claude` exit with code 1 instead of starting the session. Keep one form of the flag and drop the
  other. To combine a fixed prompt file with per-run text, merge the text into the file before launching instead of
  passing both flags.

  ```text
  Error: Cannot use both --append-subagent-system-prompt and --append-subagent-system-prompt-file. Please use only one.
  ```

  [errors › Conflict between a system prompt flag and its file form](https://code.claude.com/docs/en/errors#conflict-between-a-system-prompt-flag-and-its-file-form)
- Resuming a session that was running a custom agent, started with `--agent` or the `agent` setting, when Claude
  Code doesn't find an agent by that name shows this warning:

  ```text
  This session was running agent 'code-reviewer', which is no longer available (no agent by that name in /home/you/project). Continuing with the default tools and system prompt — the agent's tool restrictions no longer apply. To restore it, re-create the agent, or resume with an explicit --agent <name>.
  ```

  [errors › Session agent no longer available](https://code.claude.com/docs/en/errors#session-agent-no-longer-available)
- The session-agent warning names only the directories Claude Code searched, and it appears in the resumed
  conversation whether you wake a background session, run `/resume` or `claude --resume`, or resume in
  non-interactive mode, where it also goes to stderr. Sessions using `--input-format stream-json` don't show it,
  because the Agent SDK supplies agents after startup. Claude Code doesn't save the fallback to the session, so the
  warning repeats on each resume until you act. The built-in `claude` agent doesn't trigger the warning, since
  falling back to the default toolset changes nothing for it.
  [errors › Session agent no longer available](https://code.claude.com/docs/en/errors#session-agent-no-longer-available)
- Fixes for the session-agent warning:
  - Re-create the agent file at `.claude/agents/<name>.md` in the session's project, or at
    `~/.claude/agents/<name>.md` for a personal agent, then resume again.
  - Or resume with `--agent <name>` naming an agent that does exist, to run the session as that agent instead.
  - If the agent is project-scoped and you haven't trusted the session's original directory, run Claude Code there
    once, accept the trust dialog, then resume again.

  [errors › Session agent no longer available](https://code.claude.com/docs/en/errors#session-agent-no-longer-available)
- When the combined descriptions of your subagents exceed the limit, the warning appears as a startup notice in the
  conversation view rather than on stderr. Each agent counts its name plus its
  `description` frontmatter.

  ```text
  Agent descriptions are over the 15.0k-token limit (~16.2k tokens) · ask Claude to trim agent descriptions in .claude/agents/
  ```

  To fix it, shorten the `description` frontmatter of your agent files, or ask Claude to trim them for you, or
  remove agent files you no longer use.
  [errors › Agent descriptions are over the 15.0k-token limit](https://code.claude.com/docs/en/errors#agent-descriptions-are-over-the-15000-token-limit)

## API errors and model IDs

- When something cuts off a subagent's response mid-stream, and the partial response contains text but no tool
  calls, Claude Code prompts the subagent to continue rather than ending the run. This happens in interactive
  sessions too. The run ends on the error only once those continuations are used up.
  [sub-agents › API errors in subagents](https://code.claude.com/docs/en/sub-agents#api-errors-in-subagents)
- A subagent whose run ends on an API error, such as a usage limit or a repeated server error, reports that failure
  back to Claude. What Claude receives depends on where the subagent ran:
  - **Foreground**: if a rate limit, overload, or server error cuts off a subagent that already produced text
    output, the Agent tool returns that partial output with a note that the subagent was cut off and didn't finish
    its task. A subagent that produced nothing, or whose only output was tool calls, fails with
    the `Agent terminated early due to an API error` error shown below, followed by the error detail.
  - **Background**: the subagent is marked failed, and the message Claude receives when it ends names the API error
    and includes the subagent's last output, so partial work isn't lost.

  ```text
  Agent terminated early due to an API error: <error detail>
  ```

  Match the error detail after the colon to its own section on the errors page, such as Usage limits or Server
  errors, and follow that section's steps.
  [sub-agents › API errors in subagents](https://code.claude.com/docs/en/sub-agents#api-errors-in-subagents)
  [errors › Agent terminated early due to an API error](https://code.claude.com/docs/en/errors#agent-terminated-early-due-to-an-api-error)
- If a subagent's report opens with the following line, the subagent finished on a fallback model:

  ```text
  ⚠ This agent switched to <model> because its earlier model could not be used.
  ```

  When you configure a fallback model chain and a subagent encounters a failure the chain covers, such as its model
  being unavailable, Claude Code switches the subagent to the first model in the chain that accepts the request. The
  subagent keeps working instead of ending on the error.
  [sub-agents › API errors in subagents](https://code.claude.com/docs/en/sub-agents#api-errors-in-subagents)
- Once the underlying API error clears, ask Claude to retry the task or resume the subagent.
  [sub-agents › API errors in subagents](https://code.claude.com/docs/en/sub-agents#api-errors-in-subagents)
- The `[claude-code:unrecognized_model]` line means Claude Code sent a request for a model ID your Claude Code version
  doesn't recognize and found no `modelOverrides` entry mapping it. Claude Code still sends the request with the ID
  as configured, and doesn't exit or switch models. Claude Code writes it to stderr with `-p`, and to the debug log in
  an interactive or background session, at `~/.claude/debug/<session-id>.txt` when you run with `--debug`. It writes
  the line once per model string per process.
  [errors › Unrecognized model ID on a request](https://code.claude.com/docs/en/errors#unrecognized-model-id-on-a-request)
- In that line, `query_source` is the request path that used the model: Claude Code reports a value that starts with
  `agent:` for a subagent. Claude Code writes a separate line for each further unrecognized ID, such as one that a
  subagent or background functionality uses.
  [errors › Unrecognized model ID on a request](https://code.claude.com/docs/en/errors#unrecognized-model-id-on-a-request)
- If the ID names a model newer than your Claude Code version, run `claude update`.
  [errors › Unrecognized model ID on a request](https://code.claude.com/docs/en/errors#unrecognized-model-id-on-a-request)
- If you set the ID on purpose, such as an LLM gateway alias, add a `modelOverrides` entry to your settings file
  with the ID as its value. Use an Anthropic model ID as the key, not a family alias such as `opus`. For
  `my-proxy-model`, add this entry:

  ```json
  {
    "modelOverrides": {
      "claude-opus-4-6": "my-proxy-model"
    }
  }
  ```

  Claude Code then treats `my-proxy-model` as `claude-opus-4-6` and stops writing the line.
  [errors › Unrecognized model ID on a request](https://code.claude.com/docs/en/errors#unrecognized-model-id-on-a-request)
- If the ID is a typo and `query_source` starts with `agent:`, fix it where you set the subagent's model.
  [errors › Unrecognized model ID on a request](https://code.claude.com/docs/en/errors#unrecognized-model-id-on-a-request)

## Auto mode and subagents

- When a separate API safety check blocked the auto mode classifier request because of earlier conversation content,
  a background subagent in a `-p` run without `--input-format stream-json` gets an error result containing
  `Agent aborted: auto mode classifier request refused by the safety safeguard in headless mode`.
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
- When the conversation is too long for Claude Code's classifier request and Claude Code can't compact it on its
  own, a background subagent in a non-interactive `-p` run without `--input-format stream-json` gets an error result
  containing `Agent aborted: auto mode classifier transcript exceeded context window in headless mode`, and the run
  continues.
  [errors › Auto mode cannot determine the safety of an action](https://code.claude.com/docs/en/errors#auto-mode-cannot-determine-the-safety-of-an-action)
- When a subagent hit the limit of ten responses in a row with no safety verdict, the subagent stops before
  finishing, and Claude receives whatever it produced with a note that auto mode stopped it.
  [errors › The server returned no safety verdict](https://code.claude.com/docs/en/errors#the-server-returned-no-safety-verdict)

## Seeing subagents in a session

- `/context` lists custom subagents with the source each loaded from.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)

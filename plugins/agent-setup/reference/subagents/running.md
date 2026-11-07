# Running subagents

Running subagents in the foreground or the background: what starts where, waiting, permissions, results, the panel,
limits, background commands, `-p` runs, VS Code, compaction, resume and branch, and output scanning.

## Contents

- Foreground and background
- Letting Claude wait
- Permissions, tools and results of background subagents
- The panel, `/tasks` and the agent map
- Moving to the background and stopping
- Nesting depth
- Concurrent subagent limit
- Background commands and monitors
- Compaction, resume and branch
- `claude -p` runs and budgets
- Environment variables
- Output scanning

## Foreground and background

- Foreground subagents block the main conversation until complete, and permission prompts are passed through to you as
  they come up. Background subagents run concurrently while you continue working.
  [sub-agents › Run subagents in foreground or background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background)
- With nothing configured, a subagent that Claude spawns from your main conversation starts in the background.
  [sub-agents › Which subagents run in the background](https://code.claude.com/docs/en/sub-agents#which-subagents-run-in-the-background)
  - In `claude -p` and the Agent SDK, Claude can wait, on its own judgment or when you ask.
  - In interactive terminal session, VS Code, and desktop app sessions on your machine, to let Claude wait for a
    subagent, turn off fork mode, which is on by default.
- An in-process teammate's own subagents run in the foreground, because a teammate's background work can't outlive the
  lead's process. Claude Code returns an error when a teammate spawns a subagent whose definition sets
  `background: true`. A teammate's `run_in_background: true` request also fails, either with an error or by running
  silently in the foreground. Subagents launched from the main conversation follow the background default.
  [agent-teams › Limitations](https://code.claude.com/docs/en/agent-teams#limitations)

## Letting Claude wait

- To let Claude wait for a subagent, turn fork mode off by setting `CLAUDE_CODE_FORK_SUBAGENT` to `0`, for example in
  `settings.json`, then run `claude` again from your shell or open a new VS Code conversation, and ask Claude to wait
  when you need a result first, for example "run the reviewer subagent and wait for its report".
  [sub-agents › Let Claude wait for a subagent](https://code.claude.com/docs/en/sub-agents#let-claude-wait-for-a-subagent)

  ```json
  {
    "env": {
      "CLAUDE_CODE_FORK_SUBAGENT": "0"
    }
  }
  ```

- To keep working while Claude waits, press **Ctrl+B** in the terminal (tmux users must press Ctrl+B twice) or use the
  VS Code **Run in background** action described under Moving to the background and stopping.
  [sub-agents › Let Claude wait for a subagent](https://code.claude.com/docs/en/sub-agents#let-claude-wait-for-a-subagent)
  [interactive-mode › How backgrounding works](https://code.claude.com/docs/en/interactive-mode#how-backgrounding-works)
- If you set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` to `1` instead of turning fork mode off, Claude waits for subagents
  to finish before it continues. Background commands are off too, and **Ctrl+B** doesn't move anything to the
  background.
  [sub-agents › Let Claude wait for a subagent](https://code.claude.com/docs/en/sub-agents#let-claude-wait-for-a-subagent)

## Permissions, tools and results of background subagents

- Background subagents run with a smaller built-in tool set than foreground subagents, except for conversation forks
  and resumed foreground subagents.
  [sub-agents › Tools, permissions, and results of background subagents](https://code.claude.com/docs/en/sub-agents#tools-permissions-and-results-of-background-subagents)
- When a background subagent reaches a tool call that needs permission, Claude Code surfaces the prompt in your main
  session and names the subagent that is asking. Approve to let the subagent continue, or press Esc to deny that one
  tool call without stopping the subagent.
  [sub-agents › Run subagents in foreground or background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background)
- When you answer a background subagent's prompt with a choice that lasts beyond that one tool call, such as a grant
  that lasts for the rest of the session, Claude Code applies your answer to the whole session, including your main
  conversation.
  [sub-agents › Tools, permissions, and results of background subagents](https://code.claude.com/docs/en/sub-agents#tools-permissions-and-results-of-background-subagents)
- A background subagent can leave a background Bash or PowerShell command running past the end of its turn. When that
  command ends, Claude Code sends the subagent a notification.
  [sub-agents › Tools, permissions, and results of background subagents](https://code.claude.com/docs/en/sub-agents#tools-permissions-and-results-of-background-subagents)
- A background subagent's results reach Claude as a completion notification in a later turn. Claude waits for that
  notification before reporting the subagent's results, and if you ask about progress first, it reports that the
  subagent is still running.
  [sub-agents › Tools, permissions, and results of background subagents](https://code.claude.com/docs/en/sub-agents#tools-permissions-and-results-of-background-subagents)

- When subagents complete, their results return to your main conversation. Running many subagents that each return
  detailed results can consume significant context, and each subagent spends tokens of its own while it runs.
  [sub-agents › Run parallel research](https://code.claude.com/docs/en/sub-agents#run-parallel-research)

## The panel, `/tasks` and the agent map

- When a background subagent finishes successfully, Claude Code removes its row from the subagent panel below the
  prompt input immediately and, except in screen reader mode, shows `/tasks to see subagents` in the footer for 30
  seconds. During those 30 seconds, run `/tasks` and press `Enter` on the subagent to open its transcript.
  [sub-agents › Finished subagents in the panel and task list](https://code.claude.com/docs/en/sub-agents#finished-subagents-in-the-panel-and-task-list)
- When a background subagent fails or you stop it, Claude Code keeps its row for 30 seconds. To clear the row sooner,
  select it and press `x`.
  [sub-agents › Finished subagents in the panel and task list](https://code.claude.com/docs/en/sub-agents#finished-subagents-in-the-panel-and-task-list)
- A background subagent that completes stays listed in `/tasks`, marked done and sorted below running work, for the
  same 30 seconds as the footer hint, and its detail view stays open when it finishes. Subagents that fail or that you
  stop leave the list.
  [sub-agents › Finished subagents in the panel and task list](https://code.claude.com/docs/en/sub-agents#finished-subagents-in-the-panel-and-task-list)
- In the terminal, nested subagents show as a tree in the subagent panel, and each row that still has descendants in
  the panel has a `(+N)` count of them. Open a row to see that subagent's siblings and direct children with a path
  back to `main`.
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)
- In VS Code with Focus view on, while Claude runs subagents, live progress rows with their latest activity appear
  under the tool-call group that started them.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)
- In VS Code, when the conversation includes subagents, an agent count such as **2 agents** appears at the bottom of
  the prompt box, and its dot shows whether any subagent is working or waiting for your permission. Click it to open
  the agent map, which draws the conversation's subagents as a tree under the main agent, each with its status,
  elapsed time, and token count. Click a subagent to see its prompt and tool calls, open its read-only transcript, or
  stop it while it runs.
  [vs-code › Use the prompt box](https://code.claude.com/docs/en/vs-code#use-the-prompt-box)
  - The map also lists the session's other background tasks, such as background shell commands and monitors, below the
    agents. Click a row to open the task's card and stop it there.
  - To open the map when no agent count is showing, such as when Claude has started a background shell but no
    subagents, type `/tasks` in the prompt box.
  - When you click **Stop** or press `Esc`, the current turn ends. Background agents keep running until they finish
    or you stop them from the map.
- In VS Code, when a subagent shows as one status line with no tool calls, type `/tasks` in the prompt box to open the
  agent map and click the subagent there. The subagent is running in the background, and its card shows its tool calls
  and a button that opens its transcript.
  [vs-code › See a background subagent’s tool calls](https://code.claude.com/docs/en/vs-code#see-a-background-subagent’s-tool-calls)

## Moving to the background and stopping

- In VS Code, when a command or a subagent keeps Claude waiting longer than you want, click **Run in background**
  below its tool call in the conversation.
  [vs-code › Move a running command or subagent to the background](https://code.claude.com/docs/en/vs-code#move-a-running-command-or-subagent-to-the-background)
  - The action appears once a command has run for about two seconds, or as soon as Claude starts waiting for a
    subagent it spawned from the main conversation.
  - After you click, Claude stops waiting and continues the turn. The command or subagent keeps running as a
    background task that notifies Claude when done.
  - To check on the task or stop it in the meantime, type `/tasks` in the prompt box to open the agent map. A subagent
    keeps its place in the tree of agents there, and a command is listed below the agents with its latest output on
    its card.
- By default in VS Code, subagents don't show the **Run in background** action. To see why for one subagent, open its
  card in the agent map and read the `Spawned by` line:
  [vs-code › The Run in background action is missing under a subagent](https://code.claude.com/docs/en/vs-code#the-run-in-background-action-is-missing-under-a-subagent)
  - `Spawned by the main agent`: the subagent started in the background, so Claude isn't waiting for it and you don't
    need to do anything. To have Claude wait for subagents instead, see Letting Claude wait above.
  - `Spawned by` names another subagent: the action appears only for subagents the main agent spawned, not a nested
    subagent another subagent waits for. To end the nested subagent early, click **Stop agent** on its card. The
    waiting subagent then carries on without that result.
- Unless a `!` shell command is queued ahead of your messages, which makes the key interrupt the turn, sending your
  queued messages with `Ctrl+Enter` (or `Ctrl+X Ctrl+S`) moves running shell commands, subagents and other work that
  can move to the background to the background, where it keeps running, and Claude reads your messages in the same
  turn.
  [interactive-mode › When Claude Code sends what you queued](https://code.claude.com/docs/en/interactive-mode#when-claude-code-sends-what-you-queued)
- `chat:killAgents` is an action in the `Chat` context that stops background subagents:
  [keybindings › Chat actions](https://code.claude.com/docs/en/keybindings#chat-actions)

  | Action | Default | Description |
  | :- | :- | :- |
  | `chat:killAgents` | Ctrl+X Ctrl+K | Stop all running [background subagents](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) in this session and turn off [artifact auto-replies](https://code.claude.com/docs/en/artifacts#let-claude-reply-to-comments-on-its-own) for the rest of it. Press the shortcut twice within 3 seconds to confirm. You can press it while a background subagent's permission prompt is open |

## Nesting depth

- By default, a subagent can spawn subagents of its own, up to three layers below the main conversation. At the depth
  limit, Claude Code withholds the `Agent` tool from every subagent except a fork, so a subagent at the limit does
  its delegated work itself and returns one summary. A fork at the limit keeps `Agent` in its inherited tool list, but
  the tool returns an error instead of spawning.
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)
- Nested subagents suit a delegated task that itself splits into parallel subtasks, such as a reviewer subagent that
  dispatches a verifier per finding. By default the spawning subagent waits for each nested subagent's report:
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)
  - In an interactive terminal session, only the top-level subagent's summary returns to you, because a subagent that
    launches background subagents waits for their results before it finishes.
  - In `claude -p` and the Agent SDK, the spawning subagent waits while fork mode is on. If you turn fork mode off,
    nested subagents start in the background instead. The spawning subagent doesn't wait for a background nested
    subagent, which reports to your main conversation if it outlasts the spawning subagent.
- To change the limit, set `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` to the number of subagent layers you want below your
  main conversation. Set `1` to turn nesting off. This `settings.json` entry caps nesting at two layers, so your
  subagents can delegate to a second layer of their own, and that second layer can't delegate further:
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)

  ```json
  {
    "env": {
      "CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH": "2"
    }
  }
  ```

- A nested subagent is configured the same way as a top-level one and resolves from the same scopes. To keep one
  subagent from spawning while nesting is on, such as a reviewer that should stay read-only, omit `Agent` from its
  `tools` list or add it to `disallowedTools`.
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)

## Concurrent subagent limit

- Two limits control subagent use, each with its own variable: the concurrent limit stops Claude from spawning more
  subagents while too many are running, and the depth limit caps how deeply subagents nest. There's no limit on the
  total number of subagents Claude can spawn over a session.
  [sub-agents › Concurrent subagent limit](https://code.claude.com/docs/en/sub-agents#concurrent-subagent-limit)
- By default, when 20 subagents are running in a session, spawning another with the Agent tool fails with
  `Concurrent subagent limit reached`, and the error tells Claude not to retry. Spawning succeeds again when the
  running count drops below the limit. To change the limit, set `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` to any positive
  whole number. Sessions with ultracode active are exempt: the limit isn't enforced there.
  [sub-agents › Concurrent subagent limit](https://code.claude.com/docs/en/sub-agents#concurrent-subagent-limit)
- The limit blocks only subagents Claude spawns with the Agent tool, but other runs occupy the same slots:
  [sub-agents › Concurrent subagent limit](https://code.claude.com/docs/en/sub-agents#concurrent-subagent-limit)
  - An in-session fork you start with `/subtask` takes a slot while it runs and is never blocked by the limit.
  - Resuming a subagent that already finished takes a fresh slot without checking the limit, so resumes can push the
    running count past it.
  - Agents that other features run, such as workflow agents and agent team teammates, follow their own limits
    instead.

## Background commands and monitors

- If a subagent started a background command that you stop from `/tasks` or a connected client such as the desktop
  app, that subagent moves on.
  [tools-reference › Background commands](https://code.claude.com/docs/en/tools-reference#background-commands)
- A command that a foreground subagent started stops when that subagent's run ends, whether it finished, failed, or
  was interrupted. A command that the main conversation or a background subagent started keeps running after a final
  response, until it exits, is stopped, or reaches its time limit.
  [tools-reference › When a background command stops](https://code.claude.com/docs/en/tools-reference#when-a-background-command-stops)
- While a command that the main conversation started is still running, a run in non-interactive mode with the `-p`
  flag stays open after its result until that command exits or reaches its time limit. A command that a background
  subagent started is stopped when the run exits.
  [tools-reference › When a background command stops](https://code.claude.com/docs/en/tools-reference#when-a-background-command-stops)
- A foreground subagent's command that was moved to the background after reaching its timeout still stops when that
  subagent's run ends.
  [tools-reference › Foreground commands that move to the background](https://code.claude.com/docs/en/tools-reference#foreground-commands-that-move-to-the-background)
- When you stop a subagent that started monitors, for example from `/tasks`, those monitors stop with it.
  [tools-reference › Monitor tool](https://code.claude.com/docs/en/tools-reference#monitor-tool)

## Compaction, resume and branch

- After compaction, background commands and background subagents keep running, and Claude Code reminds Claude which
  ones are still running so it doesn't start a duplicate:
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

  | Mechanism | After compaction |
  | :- | :- |
  | [Background commands](https://code.claude.com/docs/en/interactive-mode#background-bash-commands) and background [subagents](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) | Keep running. Claude Code reminds Claude which ones are still running so it doesn't start a duplicate |

- When a resumed session loads, a background subagent, background Bash command, or workflow that ended with the
  previous process shows up in the resumed transcript as a note that it didn't finish. Claude Code doesn't start a
  turn from those notes; Claude reads them with your next prompt.
  [sessions › What a resumed session restores](https://code.claude.com/docs/en/sessions#what-a-resumed-session-restores)
- After `/branch`, in-flight background subagents and background Bash commands keep running, and their output appears
  in the new branch you switched into, not in the original session:
  [sessions › Branch a session](https://code.claude.com/docs/en/sessions#branch-a-session)

  | State | After `/branch` |
  | :- | :- |
  | In-flight [background subagents](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) and [background Bash commands](https://code.claude.com/docs/en/interactive-mode#background-bash-commands) | Keep running. Their output appears in the new branch you switched into, not in the original session |

## `claude -p` runs and budgets

- After Claude finishes its turn and stdin has closed, a `claude -p` run can stay open to wait for background work that
  Claude started. The run waits for background work such as background commands, subagents and workflows, Monitor
  watches, and pending `/loop` wakeups.
  [headless › Background tasks at exit](https://code.claude.com/docs/en/headless#background-tasks-at-exit)
- Unless a background command that the main conversation started is still running, Claude Code stops whatever is still
  running after 10 minutes of continuous idle waiting by default and drops its partial result.
  [headless › Background tasks at exit](https://code.claude.com/docs/en/headless#background-tasks-at-exit)
- For background subagents and workflows, the run stays open until that work completes, because its result is part of
  the final output.
  [headless › Background tasks at exit](https://code.claude.com/docs/en/headless#background-tasks-at-exit)
- With `--max-budget-usd` (print mode only), spend from subagents counts toward the
  cap. Once spend reaches the cap, spawning another subagent fails with `Budget limit reached`, and Claude Code stops
  background subagents that are still running.
  [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

## Environment variables

[env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables) rows that govern background and concurrent
subagents:

| Variable | Purpose |
| :- | :- |
| `CLAUDE_ASYNC_AGENT_STALL_TIMEOUT_MS` | Stall timeout in milliseconds for subagents. Also covers [workflow agents](https://code.claude.com/docs/en/workflows#when-an-agent-stalls-and-restarts). Default `600000` (10 minutes); if you raise `CLAUDE_STREAM_IDLE_TIMEOUT_MS` while the stream watchdog is on, the default rises with it, as [Handle slow or stalled API responses](https://code.claude.com/docs/en/agent-sdk/typescript#handle-slow-or-stalled-api-responses) describes |
| `CLAUDE_AUTO_BACKGROUND_TASKS` | Set to `1` to force-enable automatic backgrounding of long-running agent tasks. When enabled, a [subagent](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) moves to the background after running for approximately two minutes. If Claude queued a tool call such as a file edit behind the subagent, the subagent finishes in the foreground before that call starts |
| `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` | Set to `1` to remove the `run_in_background` parameter from the Bash, PowerShell, and subagent tools and to turn off the Ctrl+B shortcut. Claude Code then also stops moving subagents and timed-out shell commands to the background automatically. The [Monitor tool](https://code.claude.com/docs/en/tools-reference#monitor-tool) still runs in the background |
| `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` | How many [subagents](https://code.claude.com/docs/en/sub-agents#concurrent-subagent-limit) can be running in one session before the Agent tool refuses to spawn another (default: 20). Accepts a positive whole number in plain digits; anything else is ignored, so the variable can adjust the cap but can't disable it |
| `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | Number of [subagent layers](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents) allowed below the main conversation (default: 3). At the default, subagents can spawn their own subagents, and a subagent at the third layer can't spawn further; set `1` to turn nesting off. Accepts a positive whole number in plain digits; anything else is ignored, so the limit can be adjusted but not removed |
| `CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS` | Ceiling in milliseconds on idle waiting for background work, such as subagents and workflows, after the final turn in [non-interactive mode](https://code.claude.com/docs/en/headless#background-tasks-at-exit) with the `-p` flag. Idle waiting starts over each time Claude takes a turn to handle a background result. Default: `600000`, or 10 minutes. When idle waiting reaches the ceiling, Claude Code stops waiting for the remaining background tasks. A running background command that the main conversation started holds the run open past it. Set to `0` to wait indefinitely |
| `CLAUDE_CODE_WORKER_CHECKIN_SCHEDULE` | When `CLAUDE_AUTO_BACKGROUND_TASKS` is set to `1`, how long Claude Code waits before each reminder to Claude to check on [background subagents](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background) that are still running. Takes one or more comma-separated waits in whole seconds from `1` to `86400`, such as `600` or `600,1800,3600`. Each value is the wait before the next reminder, and the last value repeats. Takes plain digits only; any other value or spelling reads as unset. When unset, there are no reminders |

## Output scanning

- Claude Code scans each subagent's final report before Claude reads it, because a subagent may have read files, web
  pages, or command output you never reviewed, and text from those sources can carry instructions aimed at the main
  conversation. The scan never removes or rewords anything; it makes two kinds of change you may notice in a report:
  [sub-agents › Subagent output scanning](https://code.claude.com/docs/en/sub-agents#subagent-output-scanning)
  - Backslash insertion: the scan inserts a backslash into text that imitates Claude Code's own output, such as a
    `<system-reminder>` tag or a line starting with `Human:` or `Assistant:`, so the imitation reads as ordinary text
    instead of being mistaken for part of the conversation.
  - Marker line: the scan prepends a line starting with
    `[harness: subagent output matched instruction-shaped pattern(s):` when the report
    imitates a tag like `<system-reminder>` or mentions permission settings such as `bypassPermissions` or
    `--dangerously-skip-permissions`. Permission-setting mentions get the marker line, but the text itself stays as
    written.
- The scan doesn't judge whether content is malicious, and it doesn't change what an instruction in a report can do: a
  tool call the report leads Claude to make still goes through the session's permission checks and sandboxing. It
  isn't a substitute for restricting what a subagent can reach.
  [sub-agents › Subagent output scanning](https://code.claude.com/docs/en/sub-agents#subagent-output-scanning)
- A report that returns to Claude as the subagent's result also arrives under a header marking it as subagent output.
  The header states that instructions or approval claims inside the report are the subagent's words and carry no
  authority from you. A background subagent's report arrives inside a completion notification, which is marked as an
  automated event rather than a message from you.
  [sub-agents › Subagent output scanning](https://code.claude.com/docs/en/sub-agents#subagent-output-scanning)

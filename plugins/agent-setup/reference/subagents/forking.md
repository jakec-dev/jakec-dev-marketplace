# Forking

Running a forked subagent: what it inherits, how to start, watch and steer it, and how to turn fork mode off.

## Contents

- What a fork is
- Starting a fork
- Forking from /btw
- Observing and steering forks
- How forks differ from other subagents
- Turning fork mode off
- Not stated by the documentation

## What a fork is

- A fork is a subagent that inherits the entire conversation so far instead of starting fresh. It sees the same system prompt, tools, model, and message history as the main session, which drops the input isolation other subagents provide. [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- The fork's own tool calls stay out of your conversation and only its final result comes back, so the main context window stays clean. Use a fork when any other subagent would need too much background to be useful, or to try several approaches in parallel from the same starting point. [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- Claude can start a fork on its own while fork mode is on, as it is by default. [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)

## Starting a fork

- `/subtask` followed by a task starts a fork, whether or not fork mode is on. Claude Code names the fork from the first words of the task, as in `/subtask draft unit tests for the parser changes so far`. [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- The fork appears in a panel below your prompt and runs in the background while you keep working. When it finishes, its result arrives as a message in your main conversation. [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- When [agent view is turned off](https://code.claude.com/docs/en/agent-view#turn-off-agent-view), `/subtask` isn't available and `/fork` starts the forked subagent. Otherwise `/fork` copies the whole session into a new [background session](https://code.claude.com/docs/en/agent-view#from-inside-a-session). [sub-agents › Fork the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation)
- When Claude spawns a fork through the Agent tool, it can pass `isolation: "worktree"` so the fork's file edits are written to a separate git worktree instead of your checkout. [sub-agents › How forks differ from other subagents](https://code.claude.com/docs/en/sub-agents#how-forks-differ-from-other-subagents)
- A fork can't spawn further forks. [sub-agents › How forks differ from other subagents](https://code.claude.com/docs/en/sub-agents#how-forks-differ-from-other-subagents)

## Forking from /btw

- In a `/btw` answer overlay, pressing `f` starts a [forked subagent](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation) that inherits the parent conversation plus this question and answer, so it can continue with full tool access. You stay in the current session and find the fork in the [panel below your prompt](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks). Available in local sessions only. [interactive-mode › Side questions with /btw](https://code.claude.com/docs/en/interactive-mode#side-questions-with-/btw)

## Observing and steering forks

- Running forks appear in a panel below the prompt input, with one row for the main session and one for each fork. [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)
- When a fork finishes successfully, Claude Code removes its row. It keeps the row of a fork that failed or that you stopped for 30 seconds, the same as for any other background subagent. [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)
- Panel keys: [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)

  | Key | Action |
  | :- | :- |
  | `↑` / `↓` | Move between rows |
  | `Enter` | Open the selected fork's transcript and send it follow-up messages |
  | `x` | Stop the selected fork if it's running, or dismiss its row if it's no longer running. On the main session row, or on the row of the fork whose transcript you opened with `Enter`, `x` types into the prompt instead |
  | `Esc` | Return focus to the prompt input |

- With a fork's or subagent's transcript open, follow-up messages go to that agent, and built-in commands go to your main conversation, with these safeguards: [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)
  - `/compact`, `/clear`, and `/rewind` act on the main conversation, so Claude Code asks you to confirm before
    running one of them from this view.
  - `/model` and `/fast` set the main conversation's model and fast mode, not the viewed agent's, so they don't run
    from this view. A notice tells you why.
- To have the viewed agent read your message before the work it's waiting on finishes, send it with [`Ctrl+Enter` or `Ctrl+X Ctrl+S`](https://code.claude.com/docs/en/keybindings#chat-actions). Any shell command or subagent the agent is waiting on that can move to the [background](https://code.claude.com/docs/en/tools-reference#background-commands) moves there and keeps running. When the agent is writing a response, or waiting on work that can't move to the background, it keeps going and reads your message once that finishes. [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)

## How forks differ from other subagents

- A fork inherits everything the main session has at the moment it spawns. Any other subagent starts fresh from its definition. [sub-agents › How forks differ from other subagents](https://code.claude.com/docs/en/sub-agents#how-forks-differ-from-other-subagents)

  | | Fork | Non-fork subagent |
  | :- | :- | :- |
  | Context | Full conversation history | Fresh context with the prompt you pass |
  | System prompt and tools | Same as main session | From the subagent's [definition file](https://code.claude.com/docs/en/sub-agents#write-subagent-files), [filtered for background runs](https://code.claude.com/docs/en/sub-agents#available-tools) |
  | Model | Same as main session | From the subagent's `model` field |
  | Prompt cache | Shared with main session | Separate cache |

- Because its prompt cache is shared with the main session, a fork costs less than a fresh subagent for tasks that
  need the same context. [sub-agents › How forks differ from other subagents](https://code.claude.com/docs/en/sub-agents#how-forks-differ-from-other-subagents)

## Turning fork mode off

- To stop Claude from starting forks, either stop forks only, by adding `"Agent(fork)"` to `permissions.deny` in your
  settings, or turn fork mode off, by setting `CLAUDE_CODE_FORK_SUBAGENT` to `0`, for example in the `env` block of
  `settings.json`, then starting `claude` again or opening a new VS Code conversation.
  [sub-agents › Turn fork mode off](https://code.claude.com/docs/en/sub-agents#turn-fork-mode-on-or-off),
  [sub-agents › Let Claude wait for a subagent](https://code.claude.com/docs/en/sub-agents#let-claude-wait-for-a-subagent)

## Not stated by the documentation

- `/subtask` starts a fork whether or not fork mode is on; the documentation does not say whether an `"Agent(fork)"`
  deny rule stops a fork you start with `/subtask`.
  [sub-agents › Turn fork mode off](https://code.claude.com/docs/en/sub-agents#turn-fork-mode-on-or-off)

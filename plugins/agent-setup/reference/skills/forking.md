# Forking

Running a skill in a subagent: `context: fork`, the `agent` type, background or foreground, its tools, checkpoints,
and how the run appears in the output stream.

## Contents

- [What `context: fork` does](#what-context-fork-does)
- [Choosing the agent type](#choosing-the-agent-type)
- [Background or foreground](#background-or-foreground)
- [Tools in a background fork](#tools-in-a-background-fork)
- [Checkpoints and `/rewind`](#checkpoints-and-rewind)
- [In the output stream](#in-the-output-stream)

## What `context: fork` does

- Add `context: fork` to a skill's frontmatter to run it in isolation. Claude Code starts a new subagent of the type
  set in the `agent` field and gives it the skill content as its prompt. The subagent doesn't see your conversation
  history, so the skill's instructions have to stand on their own.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- Despite the name, a skill with `context: fork` doesn't run in a
  [fork of the current conversation](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation),
  which would hand the subagent everything discussed so far. When the task depends on that history, fork the
  conversation instead of using `context: fork`.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- `context: fork` only makes sense for skills with explicit instructions. If the skill contains guidelines like "use
  these API conventions" without a task, the subagent receives the guidelines but no actionable prompt, and returns
  without meaningful output.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)

## Choosing the agent type

- The `agent` field specifies which subagent configuration to use. Options include built-in agents (`Explore`,
  `Plan`, `general-purpose`) or any custom subagent from `.claude/agents/`. If omitted, it uses `general-purpose`.
  [skills › Example: Research skill using Explore agent](https://code.claude.com/docs/en/skills#example-research-skill-using-explore-agent)
- The `agent` field determines the execution environment.
  [skills › Example: Research skill using Explore agent](https://code.claude.com/docs/en/skills#example-research-skill-using-explore-agent)
- Skills and subagents work together in two directions:
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)

  | Approach | System prompt | Task | Also loads |
  | :- | :- | :- | :- |
  | Skill with `context: fork` | From agent type | SKILL.md content | CLAUDE.md, per the agent's [startup context](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup) |
  | Subagent with `skills` field | Subagent's markdown body | Claude's delegation message | Preloaded skills + CLAUDE.md, per the subagent's [startup context](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup) |

- The built-in Explore and Plan agents skip CLAUDE.md and git status to keep their context small, so a forked skill
  using `agent: Explore` sees only the SKILL.md content and the agent's own system prompt.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- The documentation's example runs research in a forked Explore agent: the skill content becomes the task, and
  the agent provides read-only tools optimised for codebase exploration.
  [skills › Example: Research skill using Explore agent](https://code.claude.com/docs/en/skills#example-research-skill-using-explore-agent)

  ```yaml
  ---
  name: deep-research
  description: Research a topic thoroughly
  context: fork
  agent: Explore
  ---

  Research $ARGUMENTS thoroughly:

  1. Find relevant files using Glob and Grep
  2. Read and analyze the code
  3. Summarize findings with specific file references
  ```

## Background or foreground

- The forked subagent runs in the
  [background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background): you keep
  working while it runs, and its result arrives in your conversation when it completes. Set `background: false` in
  the frontmatter to instead wait for the result in the turn that invoked the skill.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- Claude Code also waits for the result, even when the skill doesn't set `background: false`, in cases like these:
  in non-interactive mode, with the `-p` flag or the Agent SDK; when `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` is set to
  `1`, which also turns off all other background task features; when you invoke a forked skill while an earlier
  invocation of the same skill is still running; and when a scheduled task fires with the skill as its prompt.
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)

- For a skill with `context: fork`, Claude Code follows the foreground and background rules above, from Run skills in a
  subagent, instead of the ones for subagents Claude spawns with the Agent tool, whether or not fork mode is on.
  [sub-agents › Run subagents in foreground or background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background)

- Foreground subagents pass permission prompts through to you as they come up. A background subagent that reaches a
  tool call needing permission has Claude Code surface the prompt in your main session, naming the subagent that is
  asking: approve to let it continue, or press Esc to deny that one tool call without stopping the subagent. When you
  answer with a choice that lasts beyond that one tool call, such as a grant for the rest of the session, Claude Code
  applies your answer to the whole session, including your main conversation.
  [sub-agents › Run subagents in foreground or background](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background)

## Tools in a background fork

- A backgrounded fork runs with the
  [narrower tool set that applies to background subagents](https://code.claude.com/docs/en/sub-agents#run-subagents-in-foreground-or-background):
  the skill's subagent is a regular agent type, so the exemption for subagents that fork the conversation doesn't
  cover it. If the skill's steps depend on a tool outside that set, set `background: false` to keep the full tool
  set. [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)
- Apart from `Agent` and `ExitPlanMode`, which follow their own conditions wherever the subagent runs, a background
  subagent keeps every MCP tool but only these built-in tools: `Read`, `Grep`, `Glob`, `LSP`, `Bash`, `PowerShell`,
  `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`,
  `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, and `Artifact`, plus `SubagentHandback` for a subagent that
  reports through it. Claude Code removes every other built-in tool from a background subagent, whether inherited or
  listed in the `tools` field, so the same definition can resolve to different tools in the foreground and the
  background. The removal reports no error unless it leaves the `tools` list resolving to nothing.
  [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)

- Subagents inherit the built-in and MCP tools available in the main conversation, narrowed by two filters. The first
  filter removes `AskUserQuestion`, `EnterPlanMode`, `EndConversation`, `ScheduleWakeup`, `WaitForMcpServers` and
  `Workflow` from every subagent, even when listed in the `tools` field, so a forked skill can't ask you questions or
  enter plan mode.
  [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools)
- The first filter also removes `Agent` and `ExitPlanMode` from every subagent, even when listed in the `tools`
  field, under these conditions: `Agent`, when the subagent is at the depth limit, which is three layers below the main
  conversation unless `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` changes it, and where a fork of the conversation keeps
  the tool listed but gets an error instead of a spawn; `ExitPlanMode`, unless the subagent's `permissionMode` is
  `plan`.
  [sub-agents › Available tools](https://code.claude.com/docs/en/sub-agents#available-tools),
  [sub-agents › Let subagents spawn their own subagents](https://code.claude.com/docs/en/sub-agents#let-subagents-spawn-their-own-subagents)

## Checkpoints and `/rewind`

- A foreground forked skill edits your working tree during your own turn, so rewinding restores its edits as
  usual.
  [checkpointing › Subagent edits not restored](https://code.claude.com/docs/en/checkpointing#subagent-edits-not-restored)
- A forked skill that runs in the background applies its edits outside your session's checkpoints, so
  rewinding doesn't restore them. Use git to revert them.
  [checkpointing › Subagent edits not restored](https://code.claude.com/docs/en/checkpointing#subagent-edits-not-restored),
  [skills › Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent)

## In the output stream

- In the [stream](https://code.claude.com/docs/en/headless#stream-responses), a forked skill's messages appear in the stream like a subagent's, as
  `assistant` and `user` messages whose `parent_tool_use_id` is the ID of the tool call that started it, while
  messages from the main conversation carry `null` in that field. The forked skill's first message is a `user`
  message carrying the skill content that drives the run. By default the stream then carries the forked skill's
  `tool_use` and `tool_result` blocks; with `--forward-subagent-text` or `CLAUDE_CODE_FORWARD_SUBAGENT_TEXT`, it also
  carries the forked skill's text and thinking blocks.
  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)
- With either option, Claude Code forwards messages from subagents at every nesting depth, including those started as
  a forked skill, subagents that a forked skill spawns, and forked skills started inside a subagent or another forked
  skill. A nested subagent's messages carry in `parent_tool_use_id` the ID of the Agent or Skill tool call that
  started it, so you can rebuild the full nesting tree by following those IDs.
  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)

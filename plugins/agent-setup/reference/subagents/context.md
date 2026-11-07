# Subagent context

What a subagent sees and keeps: startup context, memory, resuming, names, transcripts and compaction.

## Contents

- What loads at startup
- Persistent memory
- Resuming and SendMessage
- Names after a restart
- Transcripts
- Auto-compaction
- Not stated by the documentation

## What loads at startup

- Each subagent starts with a fresh, isolated context window. It doesn't see your conversation history or the files
  Claude has already read. Claude composes a delegation message that summarizes
  the task, and the subagent works from there. The exception is a fork, which inherits the parent conversation
  instead of starting fresh. [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- A non-fork subagent's initial context contains, among other things:
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
  - **System prompt**: the agent's own prompt plus environment details that Claude Code appends, not the Claude Code
    system prompt. Custom subagents define theirs in the markdown body or `prompt` field. Built-in agents have
    predefined prompts.
  - **Task message**: the delegation prompt Claude writes when it hands off the work.
  - **Git status**: a snapshot Claude Code reads from your repository when the subagent starts. For a subagent in its
    own worktree of that repository, the snapshot shows the worktree's branch, status, and recent commits. Absent
    outside a Git repository or whenever the snapshot is turned off; see `includeGitInstructions`. Only Explore and Plan
    skip it, and you can't change which subagents receive it.
  - **Sibling roster**: a system reminder listing `main` and every other named agent in the session, each a valid
    `to` value for `SendMessage`. The roster appears only when the subagent's tools include `SendMessage` and at
    least one other agent has a name, whether Claude named it when spawning it or it runs as an agent team
    teammate. It is a snapshot taken when the subagent starts, so agents named later don't appear.
- The snapshot is off when the `includeGitInstructions` setting is `false` or `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS`
  turns it off. In `-p` runs, replacing the system
  prompt, including by running a custom agent with its own prompt selected with `--agent` or the `agent` setting,
  starts the session without the snapshot even when the setting is `true`. Outside bare mode, to keep the snapshot, run
  without a custom agent and add your instructions with `--append-system-prompt`.
  [settings-reference › includeGitInstructions](https://code.claude.com/docs/en/settings-reference#includegitinstructions)
- Some main-conversation state never reaches a non-fork subagent:
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
  - **Output style**: a subagent runs its own system prompt, so your output style doesn't shape its responses,
    except in a fork.
  - **Auto memory**: the main conversation's auto memory isn't loaded. To give a subagent persistent memory of its
    own, use the `memory` field.
  - **Context window size**: a subagent's context window is sized by its own model, not the parent's. Delegating to a
    model with a smaller window gives that subagent the smaller window.

## Persistent memory

- The `memory` field gives the subagent a persistent directory that survives across conversations. The subagent uses
  it to build up knowledge over time, such as codebase patterns, debugging insights, and architectural decisions.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)

  ```yaml
  ---
  name: code-reviewer
  description: Reviews code for quality and best practices
  memory: user
  ---

  You are a code reviewer. As you review code, update your agent memory with
  patterns, conventions, and recurring issues you discover.
  ```

- Choose a scope based on how broadly the memory should apply:
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)

  | Scope | Location | Use when |
  | :- | :- | :- |
  | `user` | `~/.claude/agent-memory/<name-of-agent>/` | the subagent should remember learnings across all projects |
  | `project` | `.claude/agent-memory/<name-of-agent>/` | the subagent's knowledge is project-specific and shareable via version control |
  | `local` | `.claude/agent-memory-local/<name-of-agent>/` | the subagent's knowledge is project-specific but shouldn't be checked into version control |

- Subagent memory is part of auto memory: if you turn auto memory off, with the `autoMemoryEnabled` setting or
  `CLAUDE_CODE_DISABLE_AUTO_MEMORY`, the `memory` field has no effect and the subagent launches without the memory
  instructions or the memory tool access.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- When memory is enabled, the subagent's system prompt includes instructions for reading and writing to the memory
  directory, and the first 200 lines or 25KB of `MEMORY.md` in the memory directory, whichever comes first, with
  instructions to curate `MEMORY.md` if it exceeds that limit. Read, Write, and Edit tools are automatically enabled
  so the subagent can manage its memory files.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)
- Markdown files in a subagent memory directory, such as `.claude/agent-memory/`, are an exception to the protected
  `.claude` directory, in a session started without `--restricted`. Writes to protected paths are never auto-approved
  except in `bypassPermissions` mode and, in interactive terminal sessions, in plan mode with bypass permissions
  available: they are prompted in `default` and `acceptEdits`, routed to the classifier in `auto`, and denied in
  `dontAsk`; in `plan` mode outside that exception they go to the classifier when auto mode is available during
  planning and are prompted when it isn't.
  [permission-modes › Protected paths](https://code.claude.com/docs/en/permission-modes#protected-paths)

## Resuming and SendMessage

- Each subagent invocation creates a new instance rather than continuing an earlier one. To continue an existing
  subagent's work instead of starting over, ask Claude to resume it. Resumed subagents retain their full
  conversation history, including all previous tool calls, results, and reasoning. If the subagent spawned
  background subagents of its own, that history includes the results they delivered while it ran.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- When a subagent completes, Claude receives its agent ID. The built-in Explore and Plan agents are one-shot and
  return no agent ID, so Claude can't resume them; use `general-purpose` or a custom subagent to continue work.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- When a subagent stops at its `maxTurns` limit, Claude Code marks the returned output as partial, and Claude can
  resume the subagent to continue its work.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Claude uses the `SendMessage` tool with the agent's ID or name as the `to` field to resume it. `SendMessage`
  doesn't require agent teams to be enabled; only structured team-protocol messages such as `shutdown_request` and
  `plan_approval_response` do. In sessions where cross-session messaging is enabled, Claude can use the same tool to
  message your other Claude Code sessions.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Denying `SendMessage` also removes messaging to subagents and agent-team teammates, since the same tool serves both.
  [cross-session-messaging › Turn off cross-session messaging](https://code.claude.com/docs/en/cross-session-messaging#turn-off-cross-session-messaging)
- When Claude sends a completed subagent a message with the `SendMessage` tool, the subagent resumes in the
  background without a new `Agent` invocation. The same applies to a subagent that Claude stopped with the
  `TaskStop` tool, once its stopped run has exited. The resumed run keeps the tool set from where the subagent first
  ran and can keep reading the prompt cache the original run warmed.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- A subagent that has the `SendMessage` tool can send that message too. In an interactive session, the resumed agent
  then reports back to the subagent that resumed it, not to your main conversation, and that subagent waits for the
  result before finishing its own work. When a subagent messages an agent it reports to, such as its own launcher,
  Claude Code resumes that agent without redirecting its results.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- A subagent you stopped yourself, with `x` in `/tasks` or an SDK `stop_task` request, doesn't auto-resume. If
  Claude sends it a message, the message is refused and Claude is told the agent was cancelled. While that
  subagent's row is still in the subagent panel, type into its transcript to resume it yourself; after that, a
  message from Claude can auto-resume it again.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Resuming starts a new run of the agent under the same ID, so a subagent that had already failed or completed shows
  as running again in the task list and in the Agent SDK's task events.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- `SendMessage` checks that a name still refers to the same agent it reached earlier in the conversation. If a newer
  agent has taken the name, such as a re-spawned background agent that reused it, Claude Code refuses the send, and
  the error reports which agent the name now reaches so Claude can retarget. To reach the earlier agent while it's
  still running, Claude addresses it by the agent ID it received when it spawned that agent. The check is scoped to
  the current conversation and resets on `/clear`.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- A subagent treats messages from the agent that launched it as normal task direction, including mid-task course
  corrections, and acts on them within its own permission settings. No message from any agent counts as your
  approval for a pending permission prompt, and no agent message can change a subagent's permission settings,
  `CLAUDE.md`, or configuration. Only the permission system or your own messages can grant approval.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)

## Names after a restart

- For a subagent that launched as a teammate, the agent team limitations apply instead of this section.
  [sub-agents › Message a subagent by name after a restart](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- If Claude can't message a subagent by name after you restart Claude Code and resume the session, give Claude the
  subagent's agent ID instead. Names Claude gave from the main conversation since its last compaction survive the
  restart; a name from before that compaction doesn't. To find the ID for a name, look for that name in the
  `agent-{agentId}.meta.json` files in `~/.claude/projects/{project}/{sessionId}/subagents/`.
  [sub-agents › Message a subagent by name after a restart](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- After one message by ID, the subagent's name works again, unless a newer agent has taken that name.
  [sub-agents › Message a subagent by name after a restart](https://code.claude.com/docs/en/sub-agents#resume-subagents)

## Transcripts

- You can ask Claude for the agent ID to reference a subagent explicitly, or find IDs in the transcript files at
  `~/.claude/projects/{project}/{sessionId}/subagents/`. Each transcript is stored as `agent-{agentId}.jsonl`.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Subagent transcripts persist independently of the main conversation. When the main conversation compacts, subagent
  transcripts are unaffected, since they're stored in separate files.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Subagent transcripts persist within their session: you can resume a subagent after restarting Claude Code by
  resuming the same session.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- Claude Code deletes subagent transcripts after the `cleanupPeriodDays` retention period, 30 days by default,
  following the retention sweep rules.
  [sub-agents › Resume subagents](https://code.claude.com/docs/en/sub-agents#resume-subagents)
- The `projects/<project>/<session>/subagents/` directory under `~/.claude/` holds subagent transcripts, which are
  removed with the parent session transcript when it ages out.
  [claude-directory › Cleaned up automatically](https://code.claude.com/docs/en/claude-directory#cleaned-up-automatically)

## Auto-compaction

- Subagents support automatic compaction. Compaction triggers as the subagent's own context window fills.
  [sub-agents › Auto-compaction](https://code.claude.com/docs/en/sub-agents#auto-compaction)
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` sets the percentage (1-100) of the auto-compact window at which auto-compaction
  triggers. Use lower values like `50` to compact earlier; the variable can't raise the threshold, so values above
  the default percentage are ignored. It applies only in sessions that compact before the model's context limit, and
  applies to both main conversations and subagents.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Compaction events are logged in subagent transcript files, and `preTokens` shows how many tokens were used before
  compaction occurred:
  [sub-agents › Auto-compaction](https://code.claude.com/docs/en/sub-agents#auto-compaction)

  ```json
  {
    "type": "system",
    "subtype": "compact_boundary",
    "compactMetadata": {
      "trigger": "auto",
      "preTokens": 167189
    }
  }
  ```

- To make one subagent compact earlier than it otherwise would, set `autoCompactWindow` in its frontmatter to a token
  count from `100000` to `1000000`. If you set `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, the subagent uses that variable's
  window instead and the field has no effect, unless Claude Code ignores the variable's value.
  [sub-agents › Set the auto-compact window for one subagent](https://code.claude.com/docs/en/sub-agents#subagent-auto-compact-window)

  ```yaml
  ---
  name: log-reader
  description: Reads long log files and reports the errors it finds
  autoCompactWindow: 200000
  ---
  ```

- Write `autoCompactWindow` as a plain integer such as `200000`, because in frontmatter Claude Code reads `200k` as
  200, which is outside the allowed range. The subagent still loads and compacts as if the field were absent. To
  check whether Claude Code ignored your value, run `claude --debug` and search the debug log for
  `invalid autoCompactWindow`.
  [sub-agents › Set the auto-compact window for one subagent](https://code.claude.com/docs/en/sub-agents#subagent-auto-compact-window)
- If the `autoCompactWindow` value is in range and you still see no change, check two causes. The value isn't below
  the auto-compact window the subagent would otherwise inherit: to compact earlier, set a value below that window.
  Or you run the whole session as this subagent with `--agent` or the `agent` setting: the field has no effect
  there.
  [sub-agents › Set the auto-compact window for one subagent](https://code.claude.com/docs/en/sub-agents#subagent-auto-compact-window)

## Not stated by the documentation

- How `autoCompactWindow` and `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` combine for one subagent: the documentation states
  each separately and doesn't say how the percentage applies to a subagent's own window.
  [sub-agents › Auto-compaction](https://code.claude.com/docs/en/sub-agents#auto-compaction)
- Whether a fork has persistent memory of its own.
  [sub-agents › Enable persistent memory](https://code.claude.com/docs/en/sub-agents#enable-persistent-memory)

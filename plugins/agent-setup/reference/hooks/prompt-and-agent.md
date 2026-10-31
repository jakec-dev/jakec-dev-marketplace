# Prompt and agent hooks

Writing a `type: "prompt"` or `type: "agent"` hook: supported events, configuration, response schema and limits.

## Contents

- Supported events
- Prompt hooks
- Response schema
- Agent hooks
- Not stated by the documentation

## Supported events

- Prompt hooks (`type: "prompt"`) use an LLM to evaluate whether to allow or block an action; agent hooks
  (`type: "agent"`) spawn an agentic verifier with tool access. Not all events support every hook type.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)
- Events that support all five hook types (`command`, `http`, `mcp_tool`, `prompt`, and `agent`): `PermissionDenied`,
  `PostToolBatch`, `PostToolUse`, `PostToolUseFailure`, `PreToolUse`, `Stop`, `SubagentStop`, `TaskCompleted`,
  `TaskCreated`, `TeammateIdle`, `UserPromptExpansion`, `UserPromptSubmit`.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)
- `PermissionRequest` supports `command`, `http`, `mcp_tool`, and `prompt` hooks but not `agent` hooks. If you
  configure an agent hook on this event, Claude Code skips it and the permission flow proceeds unchanged. To allow
  or deny from a hook, return the decision object from a command or HTTP hook.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)
- Events that support `command`, `http`, and `mcp_tool` hooks but not `prompt` or `agent`: `ConfigChange`,
  `CwdChanged`, `DirectoryAdded`, `Elicitation`, `ElicitationResult`, `FileChanged`, `MessageDisplay`, `Notification`,
  `PostCompact`, `PostModelSwitch`, `PreCompact`, `PreModelSwitch`, `SessionEnd`, `StopFailure`, `SubagentStart`,
  `WorktreeCreate`, `WorktreeRemove`.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)
- `SessionStart` and `Setup` support `command` and `mcp_tool` hooks. They don't support `http`, `prompt`, or `agent`
  hooks.
  [hooks › Prompt-based hooks](https://code.claude.com/docs/en/hooks#prompt-based-hooks)

## Prompt hooks

- For decisions that require judgment rather than deterministic rules, use `type: "prompt"` hooks: instead of
  running a shell command, Claude Code sends your prompt and the hook's input data to a Claude model to make the
  decision. You can specify a different model with the `model` field if you need more capability.
  [hooks-guide › Prompt-based hooks](https://code.claude.com/docs/en/hooks-guide#prompt-based-hooks)
- A prompt hook sends the hook input and your prompt to a Claude model, by default the one Claude Code uses for
  [background functionality](https://code.claude.com/docs/en/costs#background-token-usage). The LLM responds with
  structured JSON containing a decision, and Claude Code processes the decision automatically.
  [hooks › How prompt-based hooks work](https://code.claude.com/docs/en/hooks#how-prompt-based-hooks-work)
- Set `type` to `"prompt"` and provide a `prompt` string instead of a `command`. Use the `$ARGUMENTS` placeholder to
  inject the hook's JSON input data into your prompt text.
  [hooks › Prompt hook configuration](https://code.claude.com/docs/en/hooks#prompt-hook-configuration)

  ```json
  {
    "hooks": {
      "Stop": [
        {
          "hooks": [
            {
              "type": "prompt",
              "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Check if all tasks are complete."
            }
          ]
        }
      ]
    }
  }
  ```

- Fields of a prompt hook, which also accepts the [common fields](https://code.claude.com/docs/en/hooks#common-fields):
  [hooks › Prompt hook configuration](https://code.claude.com/docs/en/hooks#prompt-hook-configuration),
  [hooks › Prompt and agent hook fields](https://code.claude.com/docs/en/hooks#prompt-and-agent-hook-fields)

  | Field | Required | Description |
  | :- | :- | :- |
  | `type` | yes | Must be `"prompt"` |
  | `prompt` | yes | The prompt text to send to the LLM. Use `$ARGUMENTS` as a placeholder for the hook input JSON. If `$ARGUMENTS` is not present, input JSON is appended to the prompt |
  | `model` | no | Model to use for evaluation. Defaults to the model Claude Code uses for [background functionality](https://code.claude.com/docs/en/costs#background-token-usage) |
  | `timeout` | no | Timeout in seconds. Default: 30 |
  | `continueOnBlock` | no | On the events it applies to, `true` feeds an `ok: false` reason back to Claude and continues instead of ending the turn. Default: `false`. See [Response schema](https://code.claude.com/docs/en/hooks#response-schema) for per-event behavior |

- In a prompt or agent hook's `prompt`, escape with a backslash to include literal text: `\$1.00` renders as `$1.00`.
  [hooks › Prompt and agent hook fields](https://code.claude.com/docs/en/hooks#prompt-and-agent-hook-fields)
- A `SubagentStop` hook uses the same prompt format as a `Stop` hook to evaluate whether a subagent should stop. A
  `Stop` prompt can check several conditions at once:
  [hooks › Check multiple conditions before stopping](https://code.claude.com/docs/en/hooks#check-multiple-conditions-before-stopping)

  ```json
  {
    "type": "prompt",
    "prompt": "You are evaluating whether Claude should stop working. Context: $ARGUMENTS\n\nAnalyze the conversation and determine if:\n1. All user-requested tasks are complete\n2. Any errors need to be addressed\n3. Follow-up work is needed\n\nRespond with JSON: {\"ok\": true} to allow stopping, or {\"ok\": false, \"reason\": \"your explanation\"} to continue working.",
    "timeout": 30
  }
  ```

- If a hook's `model` names a model that the managed setting `deniedModels` blocks, such as an agent hook's `model`
  field, that request runs on the session's model instead.
  [model-config › Block specific models or versions](https://code.claude.com/docs/en/model-config#block-specific-models-or-versions)
- Use prompt hooks when the hook input data alone is enough to make a decision.
  [hooks-guide › Agent-based hooks](https://code.claude.com/docs/en/hooks-guide#agent-based-hooks)

## Response schema

- The LLM must respond with JSON containing `ok`, and `reason` when `ok` is `false`; `impossible` is optional.
  [hooks › Response schema](https://code.claude.com/docs/en/hooks#response-schema)

  ```json
  {
    "ok": true | false,
    "reason": "Explanation for the decision",
    "impossible": true | false
  }
  ```

  | Field | Description |
  | :- | :- |
  | `ok` | `true` to allow. For `false`, see the per-event behavior below |
  | `reason` | Required when `ok` is `false` |
  | `impossible` | Optional. The model returns it with `ok: false` when it judges the condition can never be satisfied. On `Stop` and `SubagentStop`, Claude Code then lets the turn end instead of feeding the reason back. Agent hooks and other events ignore it |

- What happens on `ok: false` depends on the event:
  [hooks › Response schema](https://code.claude.com/docs/en/hooks#response-schema)
  - `Stop` and `SubagentStop`: the reason is fed back to Claude as its next instruction and the turn continues,
    unless the response also sets `impossible: true`, in which case Claude Code allows the stop and the turn ends.
  - `PreToolUse`: the tool call is denied; by default the turn ends and the deny reason appears in the chat as a
    warning line. Set `continueOnBlock: true` to instead return the reason to Claude as the tool error so it can
    adjust and continue, equivalent to a command hook's `permissionDecision: "deny"`.
  - `PostToolUse`: by default the turn ends and the reason appears in the chat as a warning line. Set
    `continueOnBlock: true` to feed the reason back to Claude and continue the turn instead.
  - `PostToolBatch`, `UserPromptSubmit`, and `UserPromptExpansion`: the turn ends and the reason appears as a warning
    line. These events end the turn on `decision: "block"` regardless of `continue`.
  - `PostToolUseFailure` and `TaskCreated`: the reason is returned to Claude as a tool error and the turn continues,
    regardless of `continueOnBlock`.
  - `TaskCompleted`: when it fires because a task is marked completed during a turn, the reason is returned to
    Claude as a tool error and the turn continues, regardless of `continueOnBlock`. When it fires because a teammate
    stops, it behaves like `TeammateIdle` and halts the teammate by default.
  - `TeammateIdle`: by default the teammate stops and the reason appears as a warning line. Set
    `continueOnBlock: true` to feed the reason back to the teammate and keep it working instead.
  - `PermissionRequest`: `ok: false` has no effect. To deny an approval from a hook, use a
    [command hook](https://code.claude.com/docs/en/hooks#command-hook-fields) returning
    `hookSpecificOutput.decision.behavior: "deny"`.
  - `PermissionDenied`: `ok: false` has no effect because the denial already happened. The only output this event
    reads is `hookSpecificOutput.retry`, which prompt and agent hooks can't set. They run on this event, but their
    output is discarded. Use a [command hook](https://code.claude.com/docs/en/hooks#command-hook-fields) to return `retry`.
- If you need finer control on any event, use a [command hook](https://code.claude.com/docs/en/hooks#command-hook-fields) with the per-event fields
  described in [Decision control](https://code.claude.com/docs/en/hooks#decision-control).
  [hooks › Response schema](https://code.claude.com/docs/en/hooks#response-schema)

## Agent hooks

- Agent hooks are experimental: behavior and configuration may change in future releases, and for production
  workflows command hooks are preferred.
  [hooks › Agent-based hooks](https://code.claude.com/docs/en/hooks#agent-based-hooks)
- An agent hook (`type: "agent"`) is like a prompt hook but with multi-turn tool access: instead of a single LLM
  call, it spawns a subagent that can read files, search code, and inspect the codebase to verify conditions. Agent
  hooks support the same events as prompt hooks, except `PermissionRequest`.
  [hooks › Agent-based hooks](https://code.claude.com/docs/en/hooks#agent-based-hooks)
- When an agent hook fires, Claude Code spawns a subagent with your prompt and the hook's JSON input. The subagent
  can use tools like Read, Grep, and Glob to investigate. After up to 50 turns, it returns a structured
  `{ "ok": true/false }` decision.
  [hooks › How agent hooks work](https://code.claude.com/docs/en/hooks#how-agent-hooks-work)
- Claude Code allows the action if `ok` is `true`. If `ok` is `false`, it handles the block the same way as a prompt
  hook with `continueOnBlock: true` on that event, so on `PreToolUse` and `PostToolUse` the turn continues.
  [hooks › How agent hooks work](https://code.claude.com/docs/en/hooks#how-agent-hooks-work),
  [hooks-guide › Agent-based hooks](https://code.claude.com/docs/en/hooks-guide#agent-based-hooks)
- Set `type` to `"agent"` and provide a `prompt` string, using `$ARGUMENTS` as a placeholder for the hook input JSON.
  The fields are the same as for prompt hooks, except that agent hooks have a longer default timeout of 60 seconds
  and no `continueOnBlock` field.
  [hooks › Agent hook configuration](https://code.claude.com/docs/en/hooks#agent-hook-configuration)
- The response schema is `{ "ok": true }` to allow or `{ "ok": false, "reason": "..." }` to block. Agent hooks don't
  support the prompt-hook `impossible` field.
  [hooks › Agent hook configuration](https://code.claude.com/docs/en/hooks#agent-hook-configuration)

  ```json
  {
    "type": "agent",
    "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
    "timeout": 120
  }
  ```

- When verification requires inspecting files or running commands, use `type: "agent"` hooks; use them when you need
  to verify something against the actual state of the codebase.
  [hooks-guide › Agent-based hooks](https://code.claude.com/docs/en/hooks-guide#agent-based-hooks)
- In OpenTelemetry metrics, requests from agent-based hooks count in the `"subagent"` category and emit no
  `subagent_completed` event.
  [monitoring-usage › Subagent completed event](https://code.claude.com/docs/en/monitoring-usage#subagent-completed-event)

## Not stated by the documentation

- What a prompt hook's `ok: true` does on `PermissionRequest`: the documentation says `ok: false` has no effect there
  and that allowing or denying needs a command or HTTP hook, but doesn't say whether `ok: true` approves.
  [hooks › Response schema](https://code.claude.com/docs/en/hooks#response-schema)
- Which tools an agent hook's subagent can use beyond "tools like Read, Grep, and Glob", and whether that set can be
  changed.
  [hooks › How agent hooks work](https://code.claude.com/docs/en/hooks#how-agent-hooks-work)

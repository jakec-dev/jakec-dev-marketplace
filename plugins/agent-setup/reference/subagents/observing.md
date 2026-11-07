# Observing subagents

Observing subagents in output, telemetry and gateways: stream-json messages, OpenTelemetry attributes and events,
and gateway headers.

## Contents

- [Seeing subagents in stream-json output](#seeing-subagents-in-stream-json-output)
- [Seeing subagents in OpenTelemetry](#seeing-subagents-in-opentelemetry)
- [Seeing subagents in gateway headers](#seeing-subagents-in-gateway-headers)

## Seeing subagents in stream-json output

- In stream-json output, messages from subagents appear in the stream as `assistant` and `user` messages. Their
  `parent_tool_use_id` field says which run each one belongs to.
  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)
- The first message from a subagent running in the foreground is a `user` message carrying the prompt that drives
  it. With `--forward-subagent-text` or `CLAUDE_CODE_FORWARD_SUBAGENT_TEXT` Claude Code emits the run's text and
  thinking blocks too, beyond the default `tool_use` and `tool_result` blocks, so you can reconstruct each run's
  transcript.
  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)
- Set `CLAUDE_CODE_FORWARD_SUBAGENT_TEXT` to `1` to emit subagent text and thinking blocks in
  `claude -p --output-format stream-json` output, the same behavior as the `--forward-subagent-text` flag. Use the
  variable when a harness invokes `claude` and can't pass the flag itself. Unlike the flag, which exits with an error
  outside non-interactive mode with stream-json output, the variable is ignored there so that nested invocations
  keep working when it's set process-wide.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- When you enable either option, Claude Code forwards messages from subagents at every nesting depth, including those
  spawned with the Agent tool (the skills reference covers forked skills). In `parent_tool_use_id`, a nested
  subagent's messages carry the ID of the Agent tool call that started it, so you can rebuild the full nesting tree by
  following those IDs.
  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)
- Find how the run started in the first column:

  | How the run starts | `parent_tool_use_id` | When its messages arrive |
  | :- | :- | :- |
  | Claude calls the Agent tool from the main conversation | The ID of that Agent `tool_use` block | While the subagent works |

  [headless › Follow subagent messages](https://code.claude.com/docs/en/headless#follow-subagent-messages)

## Seeing subagents in OpenTelemetry

- When the Agent tool, or legacy Task tool, spawns a subagent, the subagent's API and tool spans nest under the
  parent's `claude_code.tool` span:

  ```text
  claude_code.tool
      └── (Agent tool) subagent claude_code.llm_request / claude_code.tool spans
  ```

  [monitoring-usage › Span hierarchy](https://code.claude.com/docs/en/monitoring-usage#span-hierarchy)
- Span attributes that identify a subagent, on `claude_code.llm_request`:

  | Attribute | Description | Gated by |
  | - | - | - |
  | `query_source` | Subsystem that issued the request, such as `repl_main_thread` or a subagent name | `ENABLE_BETA_TRACING_DETAILED` |
  | `query_source_safe` | Bounded form of `query_source`, emitted whether or not detailed beta tracing is active, with values such as `repl_main_thread` or `agent.builtin.general-purpose`. `:` becomes `.` and user-named agents appear as `agent.custom` | |
  | `agent_id` | Identifier of the subagent or teammate that issued the request. Absent on the main session | |
  | `parent_agent_id` | Identifier of the agent that spawned this one. Absent for the main session and for agents spawned directly from it | |

  On `claude_code.tool`:

  | Attribute | Description | Gated by |
  | - | - | - |
  | `agent_id` | Identifier of the subagent or teammate that ran the tool. Absent on the main session | |
  | `parent_agent_id` | Identifier of the agent that spawned this one. Absent for the main session and for agents spawned directly from it | |
  | `subagent_type` | Subagent type for the Agent tool or legacy Task tool | `OTEL_LOG_TOOL_DETAILS` |

  [monitoring-usage › Span attributes](https://code.claude.com/docs/en/monitoring-usage#span-attributes)
- `agent_id` and `parent_agent_id` are event attributes and are never attached to metrics. Events carry `agent_id`:
  the identifier of the subagent that raised the event, such as `a3f2c1b4d5e6f7a80`. Events that carry it include a
  subagent's API and tool events, its `assistant_response` events, and `subagent_completed` for the finished
  subagent. It is absent on main-session and in-process teammate events. The subagent's span `agent_id` is the same
  value, or adds a label after the leading `a` as in `acompact-3f2c1b4d5e6f7a80`.
  [monitoring-usage › Standard attributes](https://code.claude.com/docs/en/monitoring-usage#standard-attributes)
- Events carry `parent_agent_id`: the `agent_id` of the agent that spawned or last resumed the subagent that raised
  the event. It is absent when that agent is the main session.
  [monitoring-usage › Standard attributes](https://code.claude.com/docs/en/monitoring-usage#standard-attributes)
- The cost counter's attributes that name a subagent:
  - `query_source`: Category of the subsystem that issued the request. One of `"main"`, `"subagent"`, or
    `"auxiliary"`
  - `agent.name`: Subagent type that issued the request. Built-in agent names and agents from official-marketplace
    plugins appear verbatim. Other user-defined agent names are replaced with `"custom"` unless
    `OTEL_LOG_TOOL_DETAILS=1` is set. Absent when the request was not issued by a named subagent type.
  - `plugin.name`: Owning plugin when the active skill or subagent is provided by a plugin. Official-marketplace
    plugin names appear verbatim. Third-party plugin names are replaced with `"third-party"` unless
    `OTEL_LOG_TOOL_DETAILS=1` is set. Absent when neither the skill nor the subagent has an owning plugin.

  [monitoring-usage › Cost counter](https://code.claude.com/docs/en/monitoring-usage#cost-counter)
- On the tool result event, `tool_parameters` (when `OTEL_LOG_TOOL_DETAILS=1`) for the Agent tool or legacy Task
  tool includes `subagent_type`.
  [monitoring-usage › Tool result event](https://code.claude.com/docs/en/monitoring-usage#tool-result-event)
- On the tool decision event, `tool_parameters` (when `OTEL_LOG_TOOL_DETAILS=1`) for the Agent tool or legacy Task
  tool includes `subagent_type`. A subagent call reports the subagent's permission mode in `permission_mode`
  rather than the session's.
  [monitoring-usage › Tool decision event](https://code.claude.com/docs/en/monitoring-usage#tool-decision-event)
- The subagent completed event, `claude_code.subagent_completed`, is logged when a subagent finishes and returns its
  result to the conversation that started it. Use it to roll up tool use and run time by subagent type; for token
  or cost rollups, use the token counter and cost counter filtered to `query_source` `"subagent"`, since this
  event's `total_tokens` covers only the final request. That category also counts agent-based hook requests.
  [monitoring-usage › Subagent completed event](https://code.claude.com/docs/en/monitoring-usage#subagent-completed-event)
- Attributes of the subagent completed event:
  - All standard attributes
  - `event.name`: `"subagent_completed"`
  - `event.timestamp`: ISO 8601 timestamp
  - `event.sequence`: per-process counter for ordering events, described under Event correlation attributes
  - `agent_type`: The subagent type. Built-in agent names and agents from official-marketplace plugins appear
    verbatim; other agent names are replaced with `"custom"` unless `OTEL_LOG_TOOL_DETAILS=1` is set
  - `agent.source`: Where the agent definition came from: `built-in`, `plugin`, or the settings source that defined
    a custom agent, such as `userSettings` or `projectSettings`
  - `is_built_in`: Whether the subagent is a built-in agent type
  - `is_async`: Whether the subagent ran in the background
  - `total_tokens`: The token footprint of the subagent's final API request: that one request's input, cache
    creation, cache read, and output tokens, roughly the subagent's context size at completion. Not a sum across
    the run
  - `total_tool_uses`: Number of tool calls the subagent made across the whole run
  - `duration_ms`: Run time in milliseconds
  - `model`: The model the subagent was resolved to run
  - `final_model`: The model that produced the subagent's final response, which differs from `model` after a
    mid-run switch such as a fallback
  - `model_swapped`: Whether more than one model served the subagent's requests
  - `plugin_id_hash`, `plugin.name`: Present for plugin-provided agents. Official-marketplace plugin names appear
    verbatim; other plugin names are replaced with `"third-party"` unless `OTEL_LOG_TOOL_DETAILS=1` is set

  [monitoring-usage › Subagent completed event](https://code.claude.com/docs/en/monitoring-usage#subagent-completed-event)

## Seeing subagents in gateway headers

- Claude Code includes these headers on API requests:

  | Header | Description |
  | :- | :- |
  | `x-claude-code-agent-id` | Identifier of the subagent that issued the request, present only on requests from an agent Claude Code spawned inside the session. Use it with the session ID to attribute cost to parallel agents |
  | `x-claude-code-parent-agent-id` | Identifier of the agent that spawned the requesting agent, present only for nested agents |

  Subagent IDs are generated fresh each time Claude Code spawns a subagent.
  [llm-gateway-protocol › Request headers](https://code.claude.com/docs/en/llm-gateway-protocol#request-headers)
- Claude Code sends gateway hint headers by default on a direct connection to the Anthropic API. On a custom base
  URL they are off by default, and sent when `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1` is set. On any other backend,
  they are sent only when `CLAUDE_CODE_GATEWAY_HINT_HEADERS=1` is set. Setting it to `0` stops them on every
  connection.
  [llm-gateway-protocol › Gateway hint headers](https://code.claude.com/docs/en/llm-gateway-protocol#gateway-hint-headers)
- Routing hint headers that identify subagent requests, sent when the conditions in the previous bullet are met:

  | Header | Description |
  | :- | :- |
  | `x-claude-code-request-class` | What kind of request this is: `main` for a turn of the main conversation, `subagent` for a turn of a [subagent](https://code.claude.com/docs/en/sub-agents), `workflow` for an agent running inside a workflow, `compaction` for the summarization request that compacts a conversation, or `auxiliary` for side requests such as session titles, classifiers, and summaries. Sent on every request |
  | `x-claude-code-agent-type` | The kind of subagent that issued the request: a built-in agent type name such as `Explore`, `Plan`, or `general-purpose`, or `custom` for a user-defined agent, `teammate` for an agent team member running in the lead's process, or `fork` for a fork. Present only on a subagent's own turns; a subagent's compaction or side requests keep the agent ID but carry no type. A user-chosen agent name is never sent |
  | `x-claude-code-prompt-id` | Random UUID that identifies the user prompt a request serves. Requests serving one prompt share the value, including the turns of subagents that prompt started. Requests not attributed to a prompt omit it. Use it to group a session's requests by prompt |

  [llm-gateway-protocol › Gateway hint headers](https://code.claude.com/docs/en/llm-gateway-protocol#gateway-hint-headers)

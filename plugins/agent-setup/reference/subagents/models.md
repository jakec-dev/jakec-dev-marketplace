# Models

Choosing a subagent's model, effort and prompt cache lifetime.

## Contents

- Choosing the model
- Running every subagent on one model
- Effort
- Thinking and the advisor
- Model switches
- Prompt cache lifetime

## Choosing the model

- The `model` field controls which model the subagent uses: a model alias (`sonnet`, `opus`, `haiku` or `fable`), a full model ID such as `claude-opus-5-5` or `claude-sonnet-5` (the same values as the `--model` flag), or `inherit` for the same model as the main conversation. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- When Claude invokes a subagent, it can pass a `model` parameter for that invocation. On an Agent tool call that parameter takes a model alias: `sonnet`, `opus`, `haiku` or `fable`. Claude can't pass a full model ID or `inherit` on that call. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- Claude Code resolves the subagent's model in this order. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
  1. The per-invocation `model` parameter
  2. The subagent definition's `model` frontmatter, where `inherit` selects the main conversation's model
  3. The [`CLAUDE_CODE_SUBAGENT_MODEL`](https://code.claude.com/docs/en/model-config#environment-variables) environment variable, when you set it to a model alias or model ID
  4. The main conversation's model
- If an installed [mod](https://code.claude.com/docs/en/plugins/mods/overview) sets a model in its [`agent.spawn`](https://code.claude.com/docs/en/plugins/mods/reference#subagents) hook, Claude Code uses that model in place of the per-invocation parameter. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- Setting `CLAUDE_CODE_SUBAGENT_MODEL` to `inherit` is the same as leaving it unset. An alias in it always resolves to the version the alias points to, even when it names the main conversation's family. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- Setting `CLAUDE_CODE_SUBAGENT_MODEL` by itself doesn't change the model the built-in Explore and Plan subagents run on. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- A per-invocation `model` parameter also applies when the subagent is resumed or sent a follow-up message, so the subagent stays on that model. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- A family alias such as `opus` in the per-invocation parameter or the frontmatter resolves to the main conversation's model instead of the [version the alias points to](https://code.claude.com/docs/en/model-config#model-aliases) in two cases. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
  - The main conversation's model belongs to that family: the subagent runs on the main conversation's exact model, including any `[1m]` suffix, so it gets the same [extended context](https://code.claude.com/docs/en/model-config#extended-context) window.
  - Claude Code can't tell the main conversation's model family, on [a provider other than the Anthropic API](https://code.claude.com/docs/en/third-party-integrations): this can happen with an [application inference profile ARN](https://code.claude.com/docs/en/amazon-bedrock#iam-configuration) on Amazon Bedrock that Claude Code hasn't resolved to a backing model. This case covers only the `opus` alias, and doesn't apply when you set [`ANTHROPIC_DEFAULT_OPUS_MODEL`](https://code.claude.com/docs/en/model-config#environment-variables), since `opus` then resolves to the model you set.
- With the `[1m]` suffix on a pinned alias, the 1M context window applies to all usage of the pinned alias, including subagents whose `model` frontmatter names the alias. [model-config › Pin models for third-party deployments](https://code.claude.com/docs/en/model-config#pin-models-for-third-party-deployments)
- Claude Code checks the per-invocation parameter, frontmatter and environment variable values against your organization's [`availableModels`](https://code.claude.com/docs/en/model-config#restrict-model-selection) allowlist, and substitutes another model for a blocked value. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
  - When the blocked value is a family alias such as `opus`, Claude Code runs the subagent on the newest version of that family the allowlist permits, following the same [substitution rules and provider scope](https://code.claude.com/docs/en/model-config#restrict-model-selection) as `/model`.
  - For any other blocked value, on providers where that substitution doesn't operate, or when the allowlist permits
    no version of the family, Claude Code runs the subagent on the inherited model instead. If you set
    `CLAUDE_CODE_SUBAGENT_MODEL`, Claude Code tries that model first, under these same rules.
  - In interactive sessions, Claude Code shows a warning naming the requested model and the model the subagent
    runs on, for either substitution.
  - A warning prefixed with an agent name means the restriction applied to that subagent's requested model: the
    subagent runs on the substituted model and your session's model is unchanged. If the restricted model came from the
    subagent's `model` frontmatter, remove or update that value so the notice doesn't recur. [errors › Model is restricted by your organization's settings](https://code.claude.com/docs/en/errors#model-is-restricted-by-your-organizations-settings)
- When the requested model has a scheduled retirement date or is automatically remapped to a newer version, Claude Code shows a warning that names the requested model. The check also covers a `model` set in subagent frontmatter. [model-config › Setting your model](https://code.claude.com/docs/en/model-config#setting-your-model)
- To check which model a subagent is running on, run [`/tasks`](https://code.claude.com/docs/en/commands). Claude Code names the model on the subagent's row, and adds the [effort level](https://code.claude.com/docs/en/model-config#adjust-effort-level) set for that subagent, if any. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- When a subagent makes a git commit, the default `Co-Authored-By` trailer names the subagent's model. [settings-reference › `attribution.commit`](https://code.claude.com/docs/en/settings-reference#attribution-commit)

## Running every subagent on one model

- `CLAUDE_CODE_SUBAGENT_MODEL` is a default, so a subagent's definition or a model Claude passes still takes precedence over it. To apply one model to every subagent, [teammate](https://code.claude.com/docs/en/agent-teams#specify-teammates-and-models) and [workflow agent](https://code.claude.com/docs/en/workflows), also set `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` to `1`. [sub-agents › Run every subagent on one model](https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model)
  - If you set both variables, subagents run on the model in `CLAUDE_CODE_SUBAGENT_MODEL`.
  - If you set only `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`, subagents run on the main conversation's model, except that the built-in Explore subagent runs on the [model listed for it under Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents).
- While `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is [on](https://code.claude.com/docs/en/env-vars), Claude Code ignores the `model` field in subagent definitions, and Claude can't pass a model when it starts a subagent. A [fork](https://code.claude.com/docs/en/sub-agents#fork-the-current-conversation) still runs on the main conversation's model. [sub-agents › Run every subagent on one model](https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model)
- To run every subagent on Haiku, set both variables in the `env` block of a [settings file](https://code.claude.com/docs/en/settings). [sub-agents › Run every subagent on one model](https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model)

  ```json
  {
    "env": {
      "CLAUDE_CODE_SUBAGENT_MODEL": "haiku",
      "CLAUDE_CODE_SUBAGENT_MODEL_FORCE": "1"
    }
  }
  ```

## Effort

- To run a subagent at its own [effort level](https://code.claude.com/docs/en/model-config#adjust-effort-level), set the `effort` field in its definition. [sub-agents › Choose an effort level](https://code.claude.com/docs/en/sub-agents#choose-an-effort-level)
- When you ask Claude to run a non-fork subagent at a specific effort level, it can also pass an `effort` parameter for that invocation. The parameter overrides the `effort` field and stays in effect when the subagent is resumed. The [`CLAUDE_CODE_EFFORT_LEVEL`](https://code.claude.com/docs/en/env-vars#variables) environment variable takes precedence over both. [sub-agents › Choose an effort level](https://code.claude.com/docs/en/sub-agents#choose-an-effort-level)
- The `maxEffortLevel` setting caps the effort level, and any higher level runs at the cap instead, including one from a subagent's `effort` frontmatter; when your organization also sets an effort limit for a model, the lower of the two caps applies. [settings-reference › `maxEffortLevel`](https://code.claude.com/docs/en/settings-reference#maxeffortlevel)

## Thinking and the advisor

- Subagents inherit the main conversation's [extended thinking](https://code.claude.com/docs/en/model-config#extended-thinking) configuration: if thinking is on in your session, it's on for the subagent, and if it's off, it stays off. There is no per-subagent thinking setting. [sub-agents › Choose a model](https://code.claude.com/docs/en/sub-agents#choose-a-model)
- Subagents inherit the configured advisor and apply the same pairing check against their own model: an advisor must rank at or above the model it advises. [advisor › Choose an advisor model](https://code.claude.com/docs/en/advisor#choose-an-advisor-model)
- For an advisor that ranks below the main model, Claude Code doesn't attach it to the main model's requests, but subagents whose own model satisfies the pairing may still use the advisor. [advisor › Choose an advisor model](https://code.claude.com/docs/en/advisor#choose-an-advisor-model)

## Model switches

- If you switch models with `/model`, the switch also reaches [subagents that inherit the main conversation's model](https://code.claude.com/docs/en/sub-agents#choose-a-model), because Claude Code resolves their model from the one your session is using when Claude starts them. To keep a custom subagent on a smaller model, set `model` in its definition. [model-config › Setting your model](https://code.claude.com/docs/en/model-config#setting-your-model)
- When a request is flagged and would switch models, in a subagent Claude Code doesn't show the prompt that **Ask each time** gives (the `/config` "Switch models when a message is flagged" choice, or `switchModelsOnFlag` set to `false`), and the flagged request re-runs on the fallback model. [model-config › Ask before switching](https://code.claude.com/docs/en/model-config#ask-before-switching)

## Prompt cache lifetime

- Claude Code decides the cache TTL per request, and every request falls in one of two fixed buckets. Subagents are in **Everything else**: the requests Claude Code makes outside the main conversation, such as subagents, workflows, in-process teammates, forks, compaction and session titles. [prompt-caching › Which TTL each request gets](https://code.claude.com/docs/en/prompt-caching#which-ttl-each-request-gets)
- This table gives the default TTL for the Everything else bucket under both kinds of billing. [prompt-caching › Which TTL each request gets](https://code.claude.com/docs/en/prompt-caching#which-ttl-each-request-gets)

  | Request bucket | Claude subscription, within plan usage | Usage credits, API key, or cloud provider |
  | - | - | - |
  | Everything else | Five minutes, except the server-controlled helper requests, which get one hour | Five minutes |

- Subagents start their own conversation with their own system prompt and tool set. Their first request doesn't read the parent's cache, because the two prefixes differ, and they warm a cache of their own across their turns. The parent's cache is unaffected. [prompt-caching › Subagents and the cache](https://code.claude.com/docs/en/prompt-caching#subagents-and-the-cache)
- A fork inherits the parent's system prompt, tools and conversation history exactly, so its first request reads the parent's cache. [prompt-caching › Subagents and the cache](https://code.claude.com/docs/en/prompt-caching#subagents-and-the-cache)
- When Claude resumes a subagent, the resumed run's first request can read the cache the original run warmed. [prompt-caching › Subagents and the cache](https://code.claude.com/docs/en/prompt-caching#subagents-and-the-cache)
- The `subagentPromptCacheTtl` setting or the `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL` environment variable sets the TTL for that bucket. Each control takes `5m` or `1h`, and Claude Code ignores any other value. [prompt-caching › Choose the TTL yourself](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself)
- For `subagentPromptCacheTtl`, the first value holds the cache for five minutes and the second for an hour; the one-hour lifetime keeps the cache warm across longer breaks, and the API [bills each cache write at a higher rate](https://platform.claude.com/docs/en/build-with-claude/prompt-caching#pricing) than at the five-minute lifetime. It accepts any settings file scope and is unset by default, so each request gets its default lifetime. [settings-reference › `subagentPromptCacheTtl`](https://code.claude.com/docs/en/settings-reference#subagentpromptcachettl)
- The `subagentPromptCacheTtl` key covers the requests [`promptCacheTtl`](https://code.claude.com/docs/en/settings-reference#promptcachettl) doesn't, so set both to choose a lifetime for every request Claude Code makes. [settings-reference › `subagentPromptCacheTtl`](https://code.claude.com/docs/en/settings-reference#subagentpromptcachettl)
- When more than one control applies, Claude Code takes the first match in this order. [prompt-caching › Choose the TTL yourself](https://code.claude.com/docs/en/prompt-caching#choose-the-ttl-yourself)
  1. `FORCE_PROMPT_CACHING_5M=1`, which forces five minutes for both buckets
  2. The bucket's environment variable
  3. The bucket's setting
  4. For a subagent's requests, the `cacheTtl` value in the subagent's [`experimental` frontmatter field](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields). Claude Code ignores a `1h` there while your Claude subscription is using usage credits
  5. `ENABLE_PROMPT_CACHING_1H=1`, which requests one hour for both buckets
  6. The [default for the request's bucket](https://code.claude.com/docs/en/prompt-caching#which-ttl-each-request-gets)

# Excluding subagents

Disabling or restricting subagents: deny rules, built-in agents, `--bare`, and managed-settings locks.

## Contents

- Deny a subagent or the Agent tool
- Match an Agent call by input parameter
- Remove built-in subagents
- Bare and safe mode
- Managed settings
- Not stated by the documentation

## Deny a subagent or the Agent tool

- Built-in subagents are registered by default in interactive sessions. To prevent Claude from delegating to any
  subagent, deny the `Agent` tool itself with `permissions.deny`.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents)
- To block specific subagents, add `Agent(subagent-name)` to the `deny` array in settings, where `subagent-name`
  matches the subagent's name field. This works for both built-in and custom subagents.
  [sub-agents › Disable specific subagents](https://code.claude.com/docs/en/sub-agents#disable-specific-subagents)

  ```json
  {
    "permissions": {
      "deny": ["Agent(Explore)", "Agent(my-custom-agent)"]
    }
  }
  ```

- The `--disallowedTools` CLI flag takes the same rule, as in `claude --disallowedTools "Agent(Explore)"`.
  [sub-agents › Disable specific subagents](https://code.claude.com/docs/en/sub-agents#disable-specific-subagents)

## Match an Agent call by input parameter

- Deny and ask rules can match one top-level parameter of an Agent call, as in these two rows:
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)

  | Rule | Matches |
  | :- | :- |
  | `Agent(model:opus)` | Agent calls that request the Opus model tier |
  | `Agent(isolation:worktree)` | Agent calls that request a git worktree |

- The parameter name must be a direct field of the tool's input, such as `model` on the Agent tool. Fields nested
  inside an object or array are not matchable.
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- Each rule names one parameter. To gate on both `model` and `isolation`, write two rules, `Agent(model:opus)` and
  `Agent(isolation:worktree)`, rather than combining them in one rule.
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- A parameter the model omits is never matched, so the wildcard rule `Agent(model:*)` (`*` matches any sequence of
  characters; a value without it is exact) doesn't match a call that leaves `model` unset.
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- The value is compared against the literal input Claude sends, before any normalization. `Agent(model:opus)` matches
  the alias `opus` but not a full model ID.
  [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)

## Remove built-in subagents

- To remove only the built-in `Explore` and `Plan` subagents, set `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`. Claude
  explores with its search tools or the general-purpose subagent instead, and plan mode reads files directly rather
  than launching Explore and Plan agents. Custom subagents named `Explore` or `Plan` are unaffected.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- Set `CLAUDE_AGENT_SDK_DISABLE_BUILTIN_AGENTS=1` to remove all built-in types and supply only your own. The
  sub-agents page says it works in non-interactive mode and the Agent SDK; the env-vars row says it applies only in
  non-interactive mode (the `-p` flag). It also removes `general-purpose`, so an Agent call without `subagent_type`
  then fails.
  [sub-agents › Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Bare and safe mode

- `claude -p` with `--bare` skips auto-discovery of subagents. Without it, `claude -p` discovers and loads them as an
  interactive session would, including anything configured in the working directory or `~/.claude`.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- For a directory named with `--add-dir`, bare mode still skips its `.claude/agents/` folder.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- In bare mode Claude has access to the Bash, file read, and file edit tools. Pass any context you need with a flag:
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)

  | To load | Use |
  | - | - |
  | [Custom agents](https://code.claude.com/docs/en/sub-agents#choose-the-subagent-scope) | `--agents <file-or-json>` |

- In bare mode, Claude can't run background subagents, and the other features that
  `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS` turns off are off too.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)

- Setting `CLAUDE_CODE_SIMPLE` to `1` disables auto-discovery of subagents, equivalent to `--bare`.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- `claude --safe-mode` launches a session with your customizations disabled, including custom agents.
  [debug-your-config › Test against a clean configuration](https://code.claude.com/docs/en/debug-your-config#test-against-a-clean-configuration)

## Managed settings

- `strictPluginOnlyCustomization` is a managed setting that can block agents from user and project sources, so they
  come only from plugins or managed settings. Set to `true`, it locks all four kinds, agents included.
  [settings-reference › `strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization)
- Locking the `agents` surface, with the string `"agents"` in the `strictPluginOnlyCustomization` array (scope
  `Managed`, default not locked), stops Claude Code loading agents from `~/.claude/agents/`, `.claude/agents/`, and
  `--add-dir` directories. It keeps loading built-in agents, agents in the managed policy directory, and agents from
  plugins other than skills-directory plugins.
  [settings-reference › `strictPluginOnlyCustomization.agents`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-agents)

  ```json
  {
    "strictPluginOnlyCustomization": ["agents"]
  }
  ```

- `disableSideloadFlags` (scope `Managed`, Boolean, default `false`) set to `true` makes Claude Code reject the
  `--agents` flag at startup, along with `--plugin-dir`, `--plugin-url` and `--mcp-config`, and exit with an error
  naming the rejected flags. Users could otherwise pass these flags to bypass `strictKnownMarketplaces` for a single
  run. With `false`, Claude Code accepts those flags.
  [settings-reference › `disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags)

## Not stated by the documentation

- Whether `--agents` definitions still load when `strictPluginOnlyCustomization` locks `agents`.
  [settings-reference › `strictPluginOnlyCustomization.agents`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization-agents)
- Whether an `Agent(name)` deny rule matches a plugin-scoped name such as `my-plugin:reviewer`.
  [sub-agents › Disable specific subagents](https://code.claude.com/docs/en/sub-agents#disable-specific-subagents)

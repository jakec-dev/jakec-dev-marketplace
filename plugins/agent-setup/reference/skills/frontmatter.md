# Writing skill frontmatter

Writing a skill's frontmatter: every field, how it is parsed, booleans, the subset claude.ai and the API accept,
how `model` and `effort` interact with the session, and frontmatter `hooks`.

## Contents

- Format and parsing
- Fields
- Model
- Effort
- Hooks
- Outside Claude Code
- Not stated by the documentation

## Format and parsing

- Configure a skill with YAML frontmatter between `---` markers at the top of `SKILL.md`, and write the skill's
  instructions as Markdown after the closing `---`. Field names use lowercase words separated by hyphens, except
  `when_to_use`. This example sets four fields:
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)

  ```yaml
  ---
  name: my-skill
  description: What this skill does
  disable-model-invocation: true
  allowed-tools: Read Grep
  ---

  Your skill instructions here...
  ```

- A command file in `.claude/commands/` accepts the same fields except `name` and `paths`.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- A field name must match the table exactly, hyphens included: Claude Code ignores a field it doesn't recognize
  without reporting an error.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- Claude Code reads the frontmatter only when the opening `---` is the file's first line. Otherwise it treats the
  whole file, `---` markers included, as skill content.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- If the YAML between the markers doesn't parse, the skill still loads with no fields set.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- Boolean fields accept `yes`, `no`, `on`, `off`, `1`, and `0` in any letter case, in addition to `true` and
  `false`.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)

## Fields

- Every field Claude Code accepts. All fields are optional; only `description` is recommended so Claude knows when
  to use the skill:
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)

| Field | Required | Description |
| :- | :- | :- |
| `name` | No | Command name shown in the `/` menu. Defaults to the directory name. See [How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name) for how the field interacts with the name you type to invoke the skill. |
| `description` | Recommended | What the skill does and when to use it. Claude uses this to decide when to apply the skill. If omitted, uses the first non-empty line of the markdown content. Put the key use case first: the combined `description` and `when_to_use` text is truncated at 1,536 characters in the skill listing to reduce context usage. |
| `when_to_use` | No | Additional context for when Claude should invoke the skill, such as trigger phrases or example requests. Appended to `description` in the skill listing and counts toward the 1,536-character cap. |
| `argument-hint` | No | Hint shown during autocomplete to indicate expected arguments. Example: `[issue-number]` or `[filename] [format]`. |
| `arguments` | No | Named positional arguments for [`$name` substitution](https://code.claude.com/docs/en/skills#available-string-substitutions) in the skill content. Accepts a space-separated string or a YAML list. Names map to argument positions in order. |
| `disable-model-invocation` | No | Set to `true` to prevent Claude from automatically loading this skill. Use for workflows you want to trigger manually with `/name`. Also prevents the skill from being [preloaded into subagents](https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents). Also prevents the skill from running when a [scheduled task](https://code.claude.com/docs/en/scheduled-tasks) fires with the skill as its prompt. Default: `false`. |
| `user-invocable` | No | Set to `false` when only Claude should invoke the skill: Claude Code hides it from the `/` menu and doesn't run it when you type `/name`. Use for background knowledge users shouldn't invoke directly. Default: `true`. |
| `allowed-tools` | No | Tools Claude can use without asking permission during the turn that invokes this skill. The grant clears when you send your next message. Accepts a space- or comma-separated string, or a YAML list. See [Pre-approve tools for a skill](https://code.claude.com/docs/en/skills#pre-approve-tools-for-a-skill). |
| `disallowed-tools` | No | Tools removed from Claude's available pool while this skill is active. Use for autonomous skills that should never call certain tools, such as `AskUserQuestion` for a background loop. Accepts a space- or comma-separated string, or a YAML list. The restriction clears when you send your next message. Like deny rules, the field can't remove [`EndConversation`](https://code.claude.com/docs/en/tools-reference#endconversation-tool-behavior) while any other tool remains. |
| `model` | No | Model to use when this skill is active. The override applies for the rest of the current turn and isn't saved to settings. The session model resumes when you send your next prompt. Accepts the same values as [`/model`](https://code.claude.com/docs/en/model-config), or `inherit` to keep the active model. A value excluded by your organization's [`availableModels`](https://code.claude.com/docs/en/model-config#restrict-model-selection) allowlist isn't used, and the session keeps its current model. In [auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode), and in [plan mode while the classifier reviews commands](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode), a model that auto mode doesn't support also isn't used, and the session keeps its current model. With `context: fork`, the value sets the [forked subagent's model](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent) instead, and an excluded value follows the [same rules as a subagent model override](https://code.claude.com/docs/en/model-config#restrict-model-selection). |
| `effort` | No | [Effort level](https://code.claude.com/docs/en/model-config#adjust-effort-level) when this skill is active. Overrides the session effort level. When you omit it, the level comes from the [effort resolution order](https://code.claude.com/docs/en/model-config#adjust-effort-level). Options: `low`, `medium`, `high`, `xhigh`, `max`; available levels depend on the model. |
| `context` | No | Set to `fork` to run in a forked subagent context. See [Run skills in a subagent](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent). |
| `agent` | No | Which subagent type to use when `context: fork` is set. |
| `background` | No | Only applies with `context: fork`. Set to `false` to wait for the forked subagent's result in the turn that invoked the skill, instead of [running it in the background](https://code.claude.com/docs/en/skills#run-skills-in-a-subagent). Default: `true`. |
| `hooks` | No | Hooks that Claude Code registers when the skill is invoked and keeps running for the rest of the session. See [Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents) for the configuration format and the `once` option. |
| `paths` | No | Glob patterns that limit when this skill is activated. Accepts a comma-separated string or a YAML list. When set, Claude loads the skill automatically only when working with files matching the patterns. Uses the same format as [path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules). |
| `shell` | No | Shell to use for `` !`command` `` and ` ```! ` blocks in this skill. Accepts `bash` (default) or `powershell`. Setting `powershell` runs inline shell commands via PowerShell when the [PowerShell tool](https://code.claude.com/docs/en/tools-reference#powershell-tool) is enabled: it's on by default on Windows without Git Bash, on by default with Git Bash for claude.ai and Console accounts, and needs `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` in Amazon Bedrock, Google Cloud's Agent Platform, and Microsoft Foundry sessions and on macOS, Linux, and WSL. Set it to `0` to turn the tool off. |
| `metadata` | No | Free-form YAML map for your own key-value data, such as entitlement or catalog fields, read by your own tooling from `SKILL.md`. Claude Code doesn't act on its contents, and drops a value that isn't a map. Don't reuse frontmatter field names such as `paths` as keys. |
| `license` | No | License covering the skill. Part of the [Agent Skills](https://agentskills.io/home) spec; see [Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code). Claude Code accepts the field but doesn't act on it. |
| `compatibility` | No | Environment requirements for the skill, such as intended products or system prerequisites, as defined by the [Agent Skills](https://agentskills.io/home) spec; see [Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code). Accepts a string of up to 500 characters. Claude Code accepts the field but doesn't act on it. |

## Model

- When `availableModels` blocks a skill's or command's `model`, Claude Code ignores even a blocked family alias. A skill
  or command that runs in a subagent follows the subagent behaviour instead: the subagent runs on a fallback model
  rather than failing the request, and in interactive sessions Claude Code warns you, naming the requested and
  substituted models. Where the newest-permitted-version substitution operates, a blocked family alias follows it
  instead of the fallback: on the Anthropic API and Claude Platform on AWS, when the allowlist blocks the alias's usual
  model, Claude Code substitutes the newest version of the family that the allowlist permits and shows a notice naming
  the requested and substituted models.
  [model-config › Restrict model selection](https://code.claude.com/docs/en/model-config#restrict-model-selection)
- A "restricted by your organization's settings" notice prefixed with an agent, skill, or command name means the
  restriction applied to that subagent's requested model: the subagent runs on the substituted model and your
  session's model is unchanged.
  [errors › Model is restricted by your organization's settings](https://code.claude.com/docs/en/errors#model-is-restricted-by-your-organizations-settings)
- If the restricted model was set in the `model` frontmatter of a subagent, skill, or command, remove or update that
  value so the notice doesn't recur.
  [errors › Model is restricted by your organization's settings](https://code.claude.com/docs/en/errors#model-is-restricted-by-your-organizations-settings)
- When a skill or command's frontmatter names a `model` other than the session's current model, that turn is also a
  model switch: the next request reads the entire conversation history with no cache hits.
  [prompt-caching › Switching models](https://code.claude.com/docs/en/prompt-caching#switching-models)
- While `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` is on, Claude Code ignores the `model` field in subagent definitions,
  and Claude can't pass a model when it starts a subagent. A skill that runs in a subagent with `model: inherit`
  still runs on the main conversation's model. With only `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` set, subagents run on
  the main conversation's model, except that the built-in Explore subagent runs on the model listed for it under
  [Built-in subagents](https://code.claude.com/docs/en/sub-agents#built-in-subagents); with `CLAUDE_CODE_SUBAGENT_MODEL` also set, they run on that model.
  [sub-agents › Run every subagent on one model](https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model)

## Effort

- Frontmatter effort in a skill or subagent doesn't override the `CLAUDE_CODE_EFFORT_LEVEL` environment variable. A
  `maxEffortLevel` or organization effort cap still limits the level the skill or subagent runs at.
  [model-config › Set the effort level](https://code.claude.com/docs/en/model-config#set-the-effort-level)
- After an automatic model fallback, a level that a skill's `effort` frontmatter set for the flagged request applies
  to that turn, and later turns run at the level the effort resolution order gives the fallback model.
  [model-config › Effort level after a fallback](https://code.claude.com/docs/en/model-config#effort-level-after-a-fallback)

## Hooks

- Hooks in skill frontmatter use the same configuration format as settings-based hooks. This skill defines a
  `PreToolUse` hook that runs a security validation script before each `Bash` command:
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents)

  ```yaml
  ---
  name: secure-operations
  description: Perform operations with security checks
  hooks:
    PreToolUse:
      - matcher: "Bash"
        hooks:
          - type: command
            command: "./scripts/security-check.sh"
  ---
  ```

- The `once` hook field, from the common fields table:
  [hooks › Common fields](https://code.claude.com/docs/en/hooks#common-fields)

| Field | Required | Description |
| :- | :- | :- |
| `once` | no | If `true`, Claude Code removes the hook after its first successful run. A run that fails, blocks with exit code 2, or times out leaves the hook in place, so it runs again on the next matching event. Only honored for hooks declared in [skill frontmatter](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents); ignored in settings files and agent frontmatter |

- Frontmatter hooks in a project skill follow the same
  [workspace trust rule as hooks in settings files](https://code.claude.com/docs/en/hooks#workspace-trust). Claude Code
  registers them when you or Claude invoke the skill, including in a `-p` run in a folder you haven't trusted.
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents)
- The workspace trust rule for settings-file hooks: in an interactive session, Claude Code holds back hooks from every
  settings file until you accept the workspace trust dialog for the folder, or for a parent directory whose trust
  extends to it. In a `-p` or SDK session, Claude Code never shows the dialog and treats the folder as trusted.
  [hooks › Workspace trust](https://code.claude.com/docs/en/hooks#workspace-trust)
- A handler defined in more than one settings file runs once, but a plugin's or skill's copy of the same handler
  stays separate.
  [hooks › Hook handler fields](https://code.claude.com/docs/en/hooks#hook-handler-fields)
- When a `PreToolUse` hook returns `"ask"`, the permission prompt labels a hook from skill frontmatter `[skill]`.
  [hooks › PreToolUse decision control](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)

## Outside Claude Code

- Outside Claude Code, you can use only the fields in the
  [Agent Skills](https://agentskills.io/home) spec:
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)

| Distribution path | Frontmatter fields you can use |
| :- | :- |
| Claude Code skills at [any level](https://code.claude.com/docs/en/skills#where-skills-live), including [plugin](https://code.claude.com/docs/en/plugins/overview) skills | Every field in the table above |
| claude.ai skill uploads, the Skills API, and packaging with `package_skill.py` from [anthropics/skills](https://github.com/anthropics/skills) | `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` |

- When you enable a personal skill for your claude.ai account, for example to use it in Cowork and cloud sessions
  and routines, you upload it to claude.ai, so the same rules apply.
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)
- If you include any field the spec doesn't allow, packaging or upload fails with a hard error instead of ignoring
  the field:
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)

  ```text
  Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed properties are: allowed-tools, compatibility, description, license, metadata, name
  ```

- Restricting frontmatter to the spec's six fields avoids the unexpected-key error.
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)
- The [Agent Skills spec](https://agentskills.io/home) and the
  [Skills API requirements](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
  define everything else those paths validate.
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)
- Claude Code-only body features, such as dynamic context injection, don't function in claude.ai chat or through the
  API.
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)
- Claude Code accepts all six spec fields, so frontmatter that follows the spec loads in Claude Code without changes.
  [skills › Using skill frontmatter outside Claude Code](https://code.claude.com/docs/en/skills#using-skill-frontmatter-outside-claude-code)

## Not stated by the documentation

- A command file's command name comes from its file name, so `name` doesn't set it; the documentation does not say
  whether `name` or `paths` in a command file has any other effect, such as on matching files or on an error.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference),
  [skills › How a skill gets its command name](https://code.claude.com/docs/en/skills#how-a-skill-gets-its-command-name)
- The documentation does not say whether a `context: fork` skill's `effort` applies to the forked subagent, as
  `model` does.
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- The documentation does not say what a `Stop` hook in skill frontmatter does.
  [hooks › Hooks in skills and agents](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents)
- The documentation does not say whether `allowManagedHooksOnly` or `disableAllHooks` stops hooks in skill
  frontmatter; its lists of what they stop name settings files, plugins and agent frontmatter, never skill
  frontmatter.
  [settings-reference › What runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly)
- The errors page reads a notice prefixed with a skill or command name as a subagent's requested model, while
  model-config says a blocked non-forked skill or command override is ignored; neither says whether a notice
  appears for a non-forked skill's ignored `model`.
  [errors › Model is restricted by your organization's settings](https://code.claude.com/docs/en/errors#model-is-restricted-by-your-organizations-settings)
- The documentation does not say whether `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` overrides the `model` field of a
  `context: fork` skill that names a specific model.
  [sub-agents › Run every subagent on one model](https://code.claude.com/docs/en/sub-agents#run-every-subagent-on-one-model)

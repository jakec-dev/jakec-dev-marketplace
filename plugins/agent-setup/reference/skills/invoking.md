# Invoking skills

Controlling who can invoke a skill and invoking one: the invocation fields, where the name goes, stacking, the
`Skill` tool, `/loop`, the commit-time `verify` and `simplify` instruction, `-p`, and GitHub Actions.

## Contents

- [Who can invoke](#who-can-invoke)
- [Where the name goes](#where-the-name-goes)
- [Which session a typed skill reaches](#which-session-a-typed-skill-reaches)
- [Scheduled runs with /loop](#scheduled-runs-with-loop)
- [Monitors started by a skill](#monitors-started-by-a-skill)
- [Checks before each commit](#checks-before-each-commit)
- [Bundled `/claude-api` skill](#bundled-claude-api-skill)
- [Non-interactive runs](#non-interactive-runs)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## Who can invoke

- By default, both you and Claude can invoke any skill: you type `/skill-name`, and Claude can load it automatically
  when relevant to your conversation. Two frontmatter fields restrict this.
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
  - **`disable-model-invocation: true`**: Claude can't invoke the skill on its own. Use this for workflows with side
    effects or that you want to control timing, like `/commit`, `/deploy`, or `/send-slack-message`.
  - **`user-invocable: false`**: Only Claude can invoke the skill. Use this for background knowledge that isn't
    actionable as a command, such as a `legacy-system-context` skill explaining how an old system works.
- How the two fields affect invocation and context loading:
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)

  | Frontmatter | You can invoke | Claude can invoke | When loaded into context |
  | :- | :- | :- | :- |
  | (default) | Yes | Yes | Description always in context, full skill loads when invoked |
  | `disable-model-invocation: true` | Yes | Not on its own | Description not in context, full skill loads when invoked |
  | `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

  ```yaml
  ---
  name: deploy
  description: Deploy the application to production
  disable-model-invocation: true
  ---
  ```

- For that `deploy` skill, if Claude tries to run it anyway, Claude Code blocks the call and instructs it not to
  reproduce the deploy steps another way, so expect Claude to suggest running `/deploy` yourself.
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
- When you ask Claude in plain language to review your changes, it can run the `/code-review` skill without you typing
  the command.
  [code-review-local › Let Claude start the review](https://code.claude.com/docs/en/code-review-local#let-claude-start-the-review)
- A skill runs through the existing `Skill` tool rather than adding a new tool entry. In the tools reference's tools
  table, the `Permission required` column shows whether the tool prompts in Manual mode for paths inside the working
  directory. [tools-reference › Tools reference](https://code.claude.com/docs/en/tools-reference)

  | Tool | Description | Permission required |
  | :- | :- | :- |
  | `Skill` | Executes a skill within the main conversation | Yes |

## Where the name goes

- To run a skill directly, put its name at the start of your message. After plain text, the name gives Claude
  permission to run the skill but doesn't run it. To write about the skill without permitting a run, leave off the
  slash.
  [skills › Where you write the skill's name](https://code.claude.com/docs/en/skills#where-you-write-the-skill’s-name)

  | Where | Example | What happens |
  | :- | :- | :- |
  | At the start of your message | `/deploy staging` | Claude Code runs the skill directly |
  | After plain text, as a separate word with no punctuation attached | `go ahead and /deploy to staging` | Nothing runs directly. The name counts as your permission for that message: Claude can run the skill while it responds, and judges from your wording whether you asked it to |

- In mid-prompt command completion, a plugin skill matches on its bare name too, so `/deploy` finds a skill named
  `myplugin:deploy-app`. When you insert the match, Claude Code writes the full `/myplugin:deploy-app`.
  [interactive-mode › Complete a command mid-prompt](https://code.claude.com/docs/en/interactive-mode#complete-a-command-mid-prompt)
- When you type at the Claude Code prompt in your terminal, you can stack several skills at the start of one message.
  Typing `/write-tests /fix-issue 123` loads both skills and passes the trailing text `123` as `$ARGUMENTS` to each of
  them. Through the Agent SDK or `claude -p`, Claude Code loads only the first skill, with the rest of the line as its
  arguments.
  [skills › Stack several skills in one message](https://code.claude.com/docs/en/skills#stack-several-skills-in-one-message)
- Claude Code expands the first skill plus up to five more stacked after it. Expansion stops at the first token
  that isn't an inline user-invocable skill. If you stack a skill that runs as a forked subagent, such as
  `/code-review`, or one whose arguments may start with another command, such as `/loop`, expansion ends there. That
  token and everything after it become the argument text for every expanded skill.
  [skills › Stack several skills in one message](https://code.claude.com/docs/en/skills#stack-several-skills-in-one-message)
- Some features are only available in the CLI. For commands and skills, the CLI supports all of them and the VS Code
  extension a subset (type `/` to see what is available). [vs-code › VS Code extension vs. Claude Code CLI](https://code.claude.com/docs/en/vs-code#vs-code-extension-vs-claude-code-cli)
- In a subagent's `initialPrompt`, which is auto-submitted as the first user turn when that agent runs as the main
  session agent (via `--agent` or the `agent` setting), commands and skills are processed. Plugin subagents ignore
  `initialPrompt`.
  [sub-agents › Frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

## Which session a typed skill reaches

- While you're viewing an in-process teammate in an agent team, plain text and skills go to that teammate, and
  built-in commands go to the lead's session.
  [agent-teams › Talk to teammates directly](https://code.claude.com/docs/en/agent-teams#talk-to-teammates-directly)
- With a fork's or subagent's transcript open, follow-up messages and skills go to that agent, and built-in commands
  go to your main conversation.
  [sub-agents › Observe and steer running forks](https://code.claude.com/docs/en/sub-agents#observe-and-steer-running-forks)
- In agent view, skills, your own commands, and prompt-expanding built-ins such as `/init` are sent to a new
  background session as their first prompt.
  [agent-view › Dispatch an agent from agent view](https://code.claude.com/docs/en/agent-view#dispatch-an-agent-from-agent-view)

## Scheduled runs with /loop

- `/loop` is itself a bundled skill. You can pass a skill as the `/loop` prompt, for example
  `/loop 20m /review-pr 1234`, to re-run that skill each iteration. A scheduled fire only runs skills that Claude is
  allowed to invoke on its own. These reach Claude as plain text instead of executing:
  [scheduled-tasks › Run a prompt repeatedly with /loop](https://code.claude.com/docs/en/scheduled-tasks#run-a-prompt-repeatedly-with-/loop)
  - Built-in commands such as `/permissions`, `/model`, or `/clear`
  - Skills marked `disable-model-invocation: true`, including the bundled `/verify` skill
  - Skills withheld from Claude by a `skillOverrides` setting or a `Skill` deny rule
  - MCP prompts such as `/mcp__github__list_prs`
- A session-scoped scheduled task with `/code-review` as its prompt runs the review, but a session-scoped scheduled
  task never launches the cloud review, so schedule `/code-review` without the `ultra` argument.
  [code-review-local › Let Claude start the review](https://code.claude.com/docs/en/code-review-local#let-claude-start-the-review)

## Monitors started by a skill

- `when` is a field of an `experimental.monitors` entry in a plugin. It defaults to `"always"`, which starts the
  monitor at session start and on plugin reload. With `"on-skill-invoke:<skill>"`, the monitor starts the first time
  that skill runs.
  [plugins/manifest-reference › `monitors`](https://code.claude.com/docs/en/plugins/manifest-reference#monitors)

## Checks before each commit

- When a session starts with a skill named `verify` or `simplify` in place, Claude Code's commit instructions tell
  Claude to run it right before each commit, except for changes to docs or tests. Claude gets that instruction when
  all of these hold at the start of the session:
  [skills › Run your checks before each commit](https://code.claude.com/docs/en/skills#run-your-checks-before-each-commit)
  - **Location**: the skill loads from the enterprise, personal, project, or additional-directory location, or from
    a `.claude/commands/` file with that name. The recipe that `/verify` records at your repo root is a project
    skill, so it counts. The bundled `/verify` and `/simplify`, plugin skills, and skills from your claude.ai
    account don't count.
  - **Invocation**: Claude can invoke the skill. With `disable-model-invocation: true`, for example, Claude doesn't
    get the instruction.
  - **Git instructions**: you haven't turned off
    `includeGitInstructions`. Turning it off removes this instruction together with the rest of the built-in commit
    and PR instructions.
- The `includeGitInstructions` setting defaults to `true`. Set it to `false`, or set the
  `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` environment variable to `1`, to remove the built-in commit and pull request
  instructions and the git status snapshot from Claude's context, for example when you use your own git workflow
  skills. `CLAUDE_CODE_DISABLE_GIT_INSTRUCTIONS` takes precedence over the setting when set.
  [settings-reference › `includeGitInstructions`](https://code.claude.com/docs/en/settings-reference#includegitinstructions),
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Bundled `/claude-api` skill

- The bundled `/claude-api` skill loads Claude API and Managed Agents reference material for your project's language.
  Claude also activates it automatically when your code imports `anthropic` or `@anthropic-ai/sdk`. To start one of
  its workflows, type a subcommand after the skill name at the Claude Code prompt, for example `/claude-api migrate`.
  [skills › Work on Claude API projects](https://code.claude.com/docs/en/skills#work-on-claude-api-projects)

  | Subcommand | What it does |
  | :- | :- |
  | `migrate` | Update your existing Claude API code to a newer model |
  | `upgrade` | Upgrade your project's Anthropic SDK to a new major version and update your code for its breaking changes |
  | `api-version` | Update your Claude API code for a newer [API version](https://platform.claude.com/docs/en/api/versioning), then switch your requests to that version |
  | `managed-agents-onboard` | Walk through creating a new Managed Agent |
  | `managed-agents-onboard <url>` | Build the Managed Agent that the page at the URL describes, such as a page in the [Managed Agents docs](https://platform.claude.com/docs/en/managed-agents/overview) |
  | `managed-agents-onboard <quickstart-name>` | Build one of the Console's quickstart templates, such as `deep-researcher`. If you give one word that isn't a template name, Claude lists the valid names |
  | `managed-agents-secure [<agent-id>]` | Read the settings of one Managed Agent and report where they match the [Secure your Managed Agents deployment](https://platform.claude.com/docs/en/managed-agents/secure-deployment) guide or differ from it. Requires the [`ant` CLI](https://platform.claude.com/docs/en/cli-sdks-libraries/cli/quickstart) |
  | `prompt-audit` | Flag instructions written for older models in your prompts, skills, and tool descriptions and propose fixes as a diff |
  | `cost-optimize` | Profile where your project's Claude API spend goes and propose savings from options such as prompt caching, trimming unneeded input and output tokens, batch processing, effort, and model choice, one change at a time |
  | `build-eval` | Build an eval set for your Claude-powered app |
  | `hillclimb` | Iteratively improve your app against an existing eval |
  | `preserved-thinking-migration` | Find the edits your integration makes to earlier turns, its system prompt, or its tool list that invalidate [preserved thinking](https://platform.claude.com/docs/en/build-with-claude/preserved-thinking) blocks, measure how much reasoning each one drops, and propose fixes one at a time, re-measuring after each change |

## Non-interactive runs

- In `-p` mode, user-invoked skills and custom commands work. Include `/skill-name` in the prompt string and Claude
  Code expands it before running. [headless › Create a commit](https://code.claude.com/docs/en/headless#create-a-commit)
- In GitHub Actions, the `prompt` input of `anthropics/claude-code-action` accepts a skill invocation as well as
  plain text. [github-actions › Run a skill](https://code.claude.com/docs/en/github-actions#run-a-skill)
  - For a skill in your repository's `.claude/skills/` directory, run `actions/checkout` before the
    `anthropics/claude-code-action` step so the skill files are available on the runner, then pass `/skill-name` as
    the `prompt`.
  - For a skill packaged in a plugin, install the plugin with the `plugin_marketplaces` and `plugins` inputs, then
    pass the namespaced `/plugin-name:skill-name` as the `prompt`. The `plugins` input takes
    `plugin-name@marketplace-name`, where the marketplace name comes from the marketplace's own manifest rather than
    its repository URL.
- This workflow installs the `code-review` plugin and runs its skill when a pull request is opened, updated,
  reopened, or marked ready for review.
  [github-actions › Run a skill](https://code.claude.com/docs/en/github-actions#run-a-skill)

  ```yaml
  name: Code Review
  on:
    pull_request:
      types: [opened, synchronize, ready_for_review, reopened]
  jobs:
    review:
      runs-on: ubuntu-latest
      permissions:
        contents: read
        pull-requests: read
        issues: read
        id-token: write
      steps:
        - uses: actions/checkout@v6
          with:
            fetch-depth: 1
        - uses: anthropics/claude-code-action@v1
          with:
            anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
            plugin_marketplaces: "https://github.com/anthropics/claude-plugins-official.git"
            plugins: "code-review@claude-plugins-official"
            prompt: "/code-review:code-review --comment ${{ github.repository }}/pull/${{ github.event.pull_request.number }}"
            claude_args: '--allowedTools "mcp__github_inline_comment__create_inline_comment"'
  ```

- In that workflow, `--comment` makes Claude post its review on the pull request, as an inline comment on each issue
  or one summary comment when it finds none; without it, Claude posts nothing and the findings are in the workflow
  run log. Keep the `claude_args` line even though the skill's own `allowed-tools` frontmatter names the same tool,
  because the Claude Code GitHub Action starts the MCP server that posts inline comments only when `--allowedTools`
  in `claude_args` names it. [github-actions › Run a skill](https://code.claude.com/docs/en/github-actions#run-a-skill)
- On public repositories, GitHub withholds secrets from runs triggered by fork pull requests, so that review runs
  only on pull requests from branches in the same repository. Claude skips draft and closed pull requests, pull
  requests it judges not to need a review, such as automated or trivial ones, and pull requests that already have a
  comment from Claude.
  [github-actions › Run a skill](https://code.claude.com/docs/en/github-actions#run-a-skill)

## Not stated by the documentation

- Whether a `verify` skill that `/verify` recorded in a package directory, and that is listed by a nested name such
  as `apps/web:verify`, counts as a skill named `verify` for the commit instruction.
  [skills › Run your checks before each commit](https://code.claude.com/docs/en/skills#run-your-checks-before-each-commit)
- For a monitor with `"on-skill-invoke:<skill>"`, whether `<skill>` is the bare or the namespaced skill name, whether
  a run Claude invokes counts as the skill running, and whether the monitor restarts on a later run.
  [plugins/manifest-reference › `monitors`](https://code.claude.com/docs/en/plugins/manifest-reference#monitors)
- Whether Claude can invoke skills on its own in `-p` mode; the source says only that user-invoked skills work there.
  [headless › Create a commit](https://code.claude.com/docs/en/headless#create-a-commit)

# Troubleshooting skills

For checking whether a skill loads, triggers and works, and finding out why not.

## Contents

- Check that the skill loaded
- Validate skill files
- Skill not triggering
- Skill triggers too often
- Claude stops following a skill
- Measure a skill with evals
- Find unused skills
- Audit skills for outdated instructions
- Personal skills disappeared
- Track skills with OpenTelemetry
- Not stated by the documentation

## Check that the skill loaded

- `/skills` lists available skills:
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)

  | Command | Purpose |
  | :- | :- |
  | `/skills` | List available [skills](https://code.claude.com/docs/en/skills). Type to filter the list by name, description, or source. Press `t` to sort by token count, `Space` or `Enter` to [cycle a skill's visibility to Claude and the `/` menu](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings), and `Esc` to save and close. You can't cycle plugin skills, skills whose frontmatter sets `disable-model-invocation: true`, or skills with a `skillOverrides` entry in managed settings or the `--settings` flag |

- Run `/context` first to confirm whether skill descriptions are present at all. Its skills section also includes
  [bundled skills](https://code.claude.com/docs/en/skills#bundled-skills), which `/skills` doesn't list.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- `/skills` shows available skills from project, user, and plugin sources.
  [debug-your-config › See what loaded into context](https://code.claude.com/docs/en/debug-your-config#see-what-loaded-into-context)
- Two common causes for skills:
  [debug-your-config › Check common causes](https://code.claude.com/docs/en/debug-your-config#check-common-causes)

  | Symptom | Cause | Fix |
  | :- | :- | :- |
  | Skill doesn't appear in `/skills` | Skill file is at `.claude/skills/name.md` instead of in a folder | Use a folder with `SKILL.md` inside: `.claude/skills/name/SKILL.md`. |
  | Skill appears in `/skills` but Claude never invokes it | Skill has `disable-model-invocation: true` in its frontmatter, or its description doesn't match how you phrase the request | Check the badge in `/skills`: a "user-only" label means Claude won't trigger it on its own. See [skill invocation](https://code.claude.com/docs/en/skills). |

- When a plugin is listed under **Installed** with no errors but its skills aren't offered when you type `/`: skills
  load from `skills/` at the plugin root and commands from `commands/` at the plugin root. Only `plugin.json` belongs
  inside `.claude-plugin/`, and a `skills/` directory inside `.claude-plugin/` isn't scanned. Move the directories to
  the plugin root and run `/reload-plugins`; afterward the plugin's details pane in `/plugin` lists the skills, and
  typing `/` offers them.
  [plugins/troubleshooting › Plugin loads but its skills are missing](https://code.claude.com/docs/en/plugins/troubleshooting#plugin-loads-but-its-skills-are-missing)
- Each plugin skill is a directory containing `SKILL.md`.
  [plugins/troubleshooting › Plugin loads but its skills are missing](https://code.claude.com/docs/en/plugins/troubleshooting#plugin-loads-but-its-skills-are-missing)
- If a plugin's skill runs when you type its `/<plugin>:<skill>` command but Claude never invokes it on a plain
  request, check first whether it sets `disable-model-invocation: true`: the template skill in
  [Create your first plugin](https://code.claude.com/docs/en/plugins/create#create-your-first-plugin) sets it. Remove
  the line from a skill you want Claude to invoke on its own.
  [plugins/troubleshooting › Skill loads but Claude never invokes the skill](https://code.claude.com/docs/en/plugins/troubleshooting#skill-loads-but-claude-never-invokes-the-skill)
- After `disable-model-invocation: true` and a description that doesn't match how people ask, the third cause to check
  when a plugin's skill runs from its `/<plugin>:<skill>` command but Claude never invokes it on a plain request is a
  truncated description: when many skills are installed, Claude Code shortens descriptions to fit the listing's
  character budget, which can strip the keywords Claude needs to match a request.
  [plugins/troubleshooting › Skill loads but Claude never invokes the skill](https://code.claude.com/docs/en/plugins/troubleshooting#skill-loads-but-claude-never-invokes-the-skill)
- If a plugin you didn't build loads with no error and its skills still don't appear, open **Installed** in `/plugin`
  and open the plugin's details pane, which lists what the plugin contains. A plugin that lists no skills there has
  none to offer when you type `/`.
  [plugins/troubleshooting › Plugin doesn't appear or its skills don't show up](https://code.claude.com/docs/en/plugins/troubleshooting#plugin-doesnt-appear-or-its-skills-dont-show-up)
- If the Search tool, `@file` mentions, custom agents, or custom skills aren't finding files, the bundled `ripgrep`
  binary may not run on your system: install your platform's `ripgrep` package and set `USE_BUILTIN_RIPGREP` to `0`,
  either in your shell environment or in the `env` block of your `settings.json`. To confirm the switch took effect,
  run `claude doctor` in your terminal and check that the Search line shows the path of your system ripgrep
  instead of `OK (bundled)`.
  [troubleshooting › Search and discovery issues](https://code.claude.com/docs/en/troubleshooting#search-and-discovery-issues)
- Set `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH` to `1` to discover custom commands, subagents, and output styles using
  Node.js file APIs instead of ripgrep, if the bundled ripgrep binary is unavailable or blocked in your environment. It
  doesn't affect the Grep or file search tools.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Validate skill files

- To find `SKILL.md` files whose frontmatter doesn't parse, run
  [`claude plugin validate`](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory) on the skills
  directory, for example `claude plugin validate .claude/skills` for project skills or
  `claude plugin validate ~/.claude/skills` for personal skills.
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)
- Given a directory with no `.claude-plugin/` manifest, `claude plugin validate` picks the component files by the
  directory's name: for a directory named `skills`, `agents`, or `commands`, the files inside it; for a directory
  named `.claude`, the `skills`, `agents`, and `commands` directories inside it; for any other directory, those three
  directories under its `.claude`.
  [plugins/cli-reference › Validate a directory](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)
- Claude Code doesn't follow symlinks inside the directory you name:
  [plugins/cli-reference › Validate a directory](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)
  - **A linked `skills`, `agents`, or `commands` directory under the plugin or `.claude` root**: Claude Code warns
    that nothing in it was read.
  - **A linked entry inside a `skills`, `agents`, or `commands` directory**: Claude Code skips it and warns, per
    directory, how many entries it skipped that a session would load.
  - **The `skills`, `agents`, or `commands` directory you name is itself a symlink, or its parent `.claude` directory
    is**: Claude Code reports an error and checks nothing in it. Name the real directory instead.
- When you run `claude plugin validate` against a plugin directory, Claude Code doesn't check a `SKILL.md` at the
  plugin root. From a marketplace directory, it doesn't open the plugins' skill, agent, command, or hook files, or the
  MCP server files they bundle; to find errors in those files, validate each plugin directory.
  [plugins/cli-reference › Validate a directory](https://code.claude.com/docs/en/plugins/cli-reference#validate-a-directory)
- When `claude plugin validate <path>`, or `/plugin validate <path>` in a session, finds errors, it prints
  `Found N errors` and `Validation failed`, then exits with code 1. The table covers the messages that stop validation
  and two warnings, `No frontmatter block found` and `Unknown field '<key>'`, which stop it only when you pass
  `--strict`. Other warnings, such as a missing description, aren't listed. The skill rows:
  [plugins/troubleshooting › `claude plugin validate` reports errors](https://code.claude.com/docs/en/plugins/troubleshooting#claude-plugin-validate-reports-errors)

  | Message | Cause | Fix |
  | :- | :- | :- |
  | `Path is a file; skills entries must be directories containing SKILL.md` | A `skills` entry points at `SKILL.md` instead of its directory. | Point at the parent directory, or `.` for a root-level `SKILL.md`. |
  | `No frontmatter block found` or `YAML frontmatter failed to parse: <error>` | A skill, agent, or command file has missing or invalid YAML frontmatter. | Add or fix the frontmatter between `---` delimiters. Reported when validating a plugin directory. |

- `claude plugin validate <path> --strict` treats warnings as errors, so unrecognized fields and missing metadata that
  the runtime tolerates fail the run.
  [plugins/cli-reference › plugin validate](https://code.claude.com/docs/en/plugins/cli-reference#plugin-validate)
- `claude plugin validate` prints the file it validated, any errors and warnings with their paths, and a verdict line.
  The exit code follows the verdict:
  [plugins/cli-reference › Output and exit codes](https://code.claude.com/docs/en/plugins/cli-reference#output-and-exit-codes)

  | Exit code | Verdict line | Meaning |
  | :- | :- | :- |
  | `0` | `Validation passed` or `Validation passed with warnings` | The manifest loads. With `--strict`, no warnings either |
  | `1` | `Validation failed` or `Validation failed (--strict treats warnings as errors)` | An error, or a warning under `--strict` |
  | `2` | `Unexpected error during validation: <reason>` | The validator itself failed, such as on an unreadable path |

## Skill not triggering

- If Claude doesn't use your skill when expected:
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)
  1. Check the description includes keywords users would naturally say
  2. Verify the skill appears in `What skills are available?`
  3. Try rephrasing your request to match the description more closely
  4. Invoke it directly with `/skill-name` if the skill is user-invocable
- Claude matches your task against skill descriptions to decide which are relevant. If descriptions are vague or
  overlap, Claude may load the wrong skill or miss one that would help.
  [features-overview › Understand how features load](https://code.claude.com/docs/en/features-overview#understand-how-features-load)
- If the frontmatter YAML is malformed, Claude Code loads the skill body with empty metadata, so `/skill-name` still
  works but Claude can't match against your `description`. Run with `--debug` to see the parse error.
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)
- If the skill ships in a plugin, you can measure how often it triggers across realistic prompts rather than checking
  one at a time: write an eval case with a `tool_used: Skill` grader and run it with `claude plugin eval` after each
  description change.
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)
- In a plugin eval, the most common first finding is a `Δ` near zero with the case's `tool_used: Skill` grader
  failing, which means Claude isn't choosing your skill on natural phrasing. Adjust the skill's
  [`description`](https://code.claude.com/docs/en/skills#frontmatter-reference), run `claude plugin eval .` again,
  and compare.
  [plugin-evals › Create your first eval suite](https://code.claude.com/docs/en/plugin-evals#create-your-first-eval-suite)
- If a case's `tool_used: Skill` grader passes but `Δ` is negative, suspect the judge before the plugin: a small judge
  model can mark a correct answer wrong because it's formatted differently from what the rubric describes. Re-run
  with `--judge-model sonnet`, and tighten the rubric so formatting doesn't decide the verdict.
  [plugin-evals › Choose graders that give a stable signal](https://code.claude.com/docs/en/plugin-evals#choose-graders-that-give-a-stable-signal)

## Skill triggers too often

- If Claude uses your skill when you don't want it:
  [skills › Skill triggers too often](https://code.claude.com/docs/en/skills#skill-triggers-too-often)
  1. Make the description more specific
  2. Add `disable-model-invocation: true` if you only want manual invocation

## Claude stops following a skill

- If Claude follows a skill in its first response and stops following it later, start with whichever case matches:
  [skills › Claude stops following a skill](https://code.claude.com/docs/en/skills#claude-stops-following-a-skill)
  - **Claude skipped a rule that must hold every time**: move the rule into a
    [hook](https://code.claude.com/docs/en/hooks-guide). Claude Code runs a hook every time its event occurs, such as
    before each file edit, whether or not Claude is following the skill. To keep the rule with the skill, define the
    hook in the skill's [`hooks` frontmatter](https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents); that
    hook applies from the time the skill is invoked until the session ends.
  - **Claude skipped guidance it should apply with judgment**: word the guidance so it applies to the whole task, for
    example "Run the tests after every edit" rather than "Run the tests". Claude Code adds the skill's content to the
    conversation when the skill is invoked and
    [doesn't re-read the file](https://code.claude.com/docs/en/skills#skill-content-lifecycle) on later turns.
  - **The conversation was compacted**: invoke the skill again to restore its full content. After compaction, Claude
    Code [can keep only the start of an invoked skill](https://code.claude.com/docs/en/skills#skill-content-lifecycle),
    so put the most important instructions near the top of `SKILL.md`.

## Measure a skill with evals

- Seeing a skill trigger tells you Claude found it, not that it did what you intended. Measure separately whether
  Claude invokes it on the prompts it should, and whether the output matches what you expect when it does.
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
- The check for both is a baseline comparison: collect a few realistic prompts, run each one in a fresh session with
  the skill available and again with it turned off, and compare the results. A fresh session matters because leftover
  context from authoring the skill will mask gaps in the written instructions.
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
- How you turn the skill off for the second run depends on where it comes from:
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
  - **Personal or project skill**: set it to `"off"` in
    [`skillOverrides`](https://code.claude.com/docs/en/skills#override-skill-visibility-from-settings).
  - **Skill that a plugin provides** (`skillOverrides` doesn't apply to it): use
    [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals#the-no-plugin-baseline) instead, which repeats
    each run with no plugin loaded.
- For a skill that ships in a plugin,
  [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) automates the baseline comparison: it runs each
  prompt in an isolated session with and without the plugin, scores it with graders you define or that it writes for
  you, and exits non-zero below a threshold so you can gate CI on it. The skill-creator plugin, below, uses its own
  `evals/evals.json` format, and the two formats aren't interchangeable.
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
- `claude plugin eval init` fails with `<directory> is not a plugin or skill folder` when you run it from a directory
  that isn't a plugin's root, such as your home directory or the root of a repository that keeps the plugin in a
  subdirectory: `init` writes the suite under the working directory, so it stops instead of creating an `evals/`
  directory the plugin would never see. Change to the plugin's root, the directory that holds
  `.claude-plugin/plugin.json` or the skill's `SKILL.md`, and run it again. To scaffold the suite somewhere else on
  purpose, pass `--eval-dir`.
  [plugins/troubleshooting › `<directory> is not a plugin or skill folder` from `claude plugin eval init`](https://code.claude.com/docs/en/plugins/troubleshooting#is-not-a-plugin-or-skill-folder)
- In a plugin eval case's `prompt.md`, write a request one of your skills should handle, phrased the way a user would
  type it rather than naming the skill, and list `Skill` in `allowed_tools`:
  [plugin-evals › Write a case manually](https://code.claude.com/docs/en/plugin-evals#write-a-case-manually)

  ```markdown
  ---
  max_turns: 10
  allowed_tools: [Read, Glob, Grep, Skill]
  ---

  Write me a commit message for this change: I renamed getUser to fetchUser and updated the three call sites.
  ```

- In a plugin eval case, a grader file under `graders/` checks whether your skill produced the answer. Replace
  `your-skill-name` with the skill's directory name under `skills/`, which is the name Claude invokes it by. It passes
  when Claude invoked that skill at least once during the run, including by its namespaced `plugin-name:skill-name`
  form.
  [plugin-evals › Write a case manually](https://code.claude.com/docs/en/plugin-evals#write-a-case-manually)

  ```markdown
  ---
  type: tool_used
  tool: Skill
  input_match: '"skill"\s*:\s*"(?:[\w-]+:)?your-skill-name"'
  ---
  ```

- In a two-arm plugin eval run, some graders are reported with `scored: false`: excluded from the score in both arms
  and reported in the with-arm as pass/fail indicators only, since "the skill was invoked" can never pass without the
  plugin. The excluded set is:
  - every `tool_used` grader whose `tool` is `Skill`
  - every `regex` grader with `target: mock_calls` and every `llm` grader with `focus: mock_calls`, when each mocked
    server in the case is one your plugin declares
  - any grader you mark `arm: with-only`

  Three settings change that exclusion:
  - **Every grader excluded**: if every grader in a case is in the excluded set, they're scored normally instead.
  - **`arm: both`**: set `arm: both` on a grader to score it in both arms regardless, which is what you want for a
    "must not invoke the skill" check with `min: 0` and `max: 0`.
  - **`--ablation none`**: under `--ablation none` nothing is excluded, so the same suite can produce a different
    absolute score in the two modes.
  [plugin-evals › Score against the no-plugin baseline](https://code.claude.com/docs/en/plugin-evals#compare-against-a-no-plugin-baseline)
- The [`skill-creator` plugin](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/skill-creator)
  automates a similar comparison loop for iterating on a single skill inside a Claude Code conversation. In a terminal
  session, install it with `/plugin install skill-creator@claude-plugins-official`; in the VS Code extension or the
  desktop app, install it from the official marketplace.
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
- If the skill-creator install fails, match the message Claude Code reports:
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
  - `Marketplace "claude-plugins-official" not found`: add the marketplace with
    `/plugin marketplace add anthropics/claude-plugins-official`, then retry the install.
  - The plugin is not found in the marketplace: check the plugin name.
- If the install summary reports `Run /reload-plugins to activate.`, Claude Code then runs that reload for you. If the
  reload warns that your next message would re-read the conversation, run `/reload-plugins --force` to make the
  plugin's skills available in the current session.
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
- Then ask Claude to evaluate an existing skill, for example `evaluate my summarize-changes skill with skill-creator`.
  The plugin walks you through writing test cases and runs the loop:
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
  - **Test cases**: stores prompts, input files, and expected behavior in `evals/evals.json` inside the skill directory
  - **Isolated runs**: spawns a subagent per test case so each run starts with a clean context, and records token
    count and duration
  - **Grading**: checks each assertion against the output and writes pass or fail with evidence to `grading.json`
  - **Benchmark**: aggregates pass rate, time, and tokens for with-skill versus without-skill into `benchmark.json`
  - **Version comparison**: runs a blind A/B between two versions of the skill so you can confirm an edit is an
    improvement before committing it
  - **Description tuning**: generates should-trigger and should-not-trigger prompts, measures the hit rate, and
    proposes description edits when the skill activates on the wrong requests
  - **Review viewer**: opens an HTML report where you inspect each output and record qualitative feedback that the
    next iteration reads

## Find unused skills

- Run `/skill-doctor` to see what each of your skills costs in context and how often it gets used, so you can decide
  which ones to turn off. In an interactive session, the report opens in the `/plugin` manager's **Stats** tab. In
  non-interactive mode with `-p`, Claude Code prints it as text.
  [skills › Find unused skills](https://code.claude.com/docs/en/skills#find-unused-skills)
- The report covers the skills in your session other than bundled skills and enterprise skills. It flags skills in the
  listing that have never been invoked and says where to turn them off. Of the skills it tells you where to turn off,
  start with the ones that have the highest context cost. The report also lists plugins you haven't used recently.
  [skills › Find unused skills](https://code.claude.com/docs/en/skills#find-unused-skills)
- `/skill-doctor` isn't available in sessions that skip
  [feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching): with it
  off, you can't run `/skill-doctor` or open its report in the `/plugin` **Stats** tab. Run over Remote Control, it
  replies
  [`Skill usage reports are not available on this connection.`](https://code.claude.com/docs/en/errors#skill-usage-reports-are-not-available-on-this-connection)
  instead; run it in the terminal on the machine where the session is running.
  [skills › Find unused skills](https://code.claude.com/docs/en/skills#find-unused-skills)
  [env-vars › Features that need feature-flag fetching](https://code.claude.com/docs/en/env-vars#features-that-need-feature-flag-fetching)
- The `/doctor` setup checkup also finds unused skills, MCP servers, and plugins versus their context cost.
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- On a Pro, Max, Team, or Enterprise plan, `/usage` shows **Attribution**: recent usage attributed to skills,
  subagents, plugins, and individual MCP servers, each shown as a percentage of the total. The figures are
  approximate and computed from local session history on this machine, so usage from other devices or claude.ai is
  not included.
  [costs › Plan usage breakdown](https://code.claude.com/docs/en/costs#plan-usage-breakdown)

## Audit skills for outdated instructions

- `/claude-api prompt-audit` flags instructions written for older models in your prompts, skills, and tool
  descriptions and proposes fixes as a diff.
  [skills › Work on Claude API projects](https://code.claude.com/docs/en/skills#work-on-claude-api-projects)
- `/doctor prompt-audit` has Claude check your instruction files for outdated or conflicting content. By default it
  covers, among other files, the skills and commands under `.claude/` and `~/.claude/`. To audit one file or
  directory instead, pass its path, for example `/doctor prompt-audit .claude/skills/deploy`.
  [memory › Audit your instruction files](https://code.claude.com/docs/en/memory#audit-your-instruction-files)

## Personal skills disappeared

- If skill folders you created in `~/.claude/skills/` are gone, look in `~/.claude/skills/.trash/`. When Claude Code
  syncs skills from claude.ai, it downloads them into the separate `synced` subfolder and doesn't move or delete the
  folders you create.
  [skills › Personal skills disappeared](https://code.claude.com/docs/en/skills#personal-skills-disappeared)
- A `manifest.json` file in `~/.claude/skills/` doesn't make Claude Code move the skill folders it lists into a
  timestamped folder under `~/.claude/skills/.trash/`.
  [skills › Personal skills disappeared](https://code.claude.com/docs/en/skills#personal-skills-disappeared)
- Claude Code deletes files under `~/.claude/skills/.trash/` once they're older than
  [`cleanupPeriodDays`](https://code.claude.com/docs/en/settings-reference#cleanupperioddays), as long as it can
  safely determine the retention period; the default is 30 days and the minimum is 1, and setting `0` fails with a
  validation error. `skills/.trash/` holds skills that the claude.ai sync removed, such as after you turn one off on
  claude.ai or stop syncing. The files stay there so you can recover them until the sweep deletes them.
  [claude-directory › Cleaned up automatically](https://code.claude.com/docs/en/claude-directory#cleaned-up-automatically)
- To restore a skill, move its folder from the timestamped folder in `.trash/` back into `~/.claude/skills/`. Do this
  before the retention sweep deletes trash entries.
  [skills › Personal skills disappeared](https://code.claude.com/docs/en/skills#personal-skills-disappeared)

## Track skills with OpenTelemetry

- The `claude_code.skill_activated` event is logged when a skill is invoked, whether Claude calls it through the Skill
  tool or you run it as a `/` command. Its attributes, besides the standard attributes:
  [monitoring-usage › Skill activated event](https://code.claude.com/docs/en/monitoring-usage#skill-activated-event)
  - `event.name`: `"skill_activated"`
  - `event.timestamp`: ISO 8601 timestamp
  - `event.sequence`: per-process counter for ordering events
  - `skill.name`: Name of the skill. For user-defined and third-party plugin skills the value is the placeholder
    `"custom_skill"` unless `OTEL_LOG_TOOL_DETAILS=1`
  - `invocation_trigger`: How the skill was triggered (`"user-slash"`, `"claude-proactive"`, or `"nested-skill"`)
  - `skill.source`: Where the skill was loaded from (for example, `"bundled"`, `"userSettings"`, `"projectSettings"`,
    `"plugin"`)
  - `skill.kind`: `"workflow"` when the skill is a workflow skill. Absent otherwise
  - `plugin.name` (when `OTEL_LOG_TOOL_DETAILS=1` or the plugin is from an official marketplace): Name of the owning
    plugin when the skill is provided by a plugin
  - `marketplace.name` (when `OTEL_LOG_TOOL_DETAILS=1` or the plugin is from an official marketplace): Marketplace the
    owning plugin was installed from, when the skill is provided by a plugin
- On the cost counter, `skill.name` is the skill active for the request, set by the Skill tool or a `/` command, or
  inherited by a spawned subagent. Built-in, bundled, user-defined, and official-marketplace plugin skill names appear
  verbatim. Third-party plugin skill names are replaced with `"third-party"`. Absent when no skill is active. That
  replacement is the default: with `OTEL_LOG_TOOL_DETAILS=1` set, the cost and token counters carry the real
  third-party names, and so do the `api_request`, `api_error` and `api_refusal` events.
  [monitoring-usage › Cost counter](https://code.claude.com/docs/en/monitoring-usage#cost-counter)
- With `OTEL_LOG_TOOL_DETAILS=1` (default: disabled), tool events and trace span attributes record skill names, among
  other tool details.
  [monitoring-usage › Common configuration variables](https://code.claude.com/docs/en/monitoring-usage#common-configuration-variables)
- With `OTEL_LOG_TOOL_DETAILS=1`, the `tool_result` and `tool_decision` events carry a `tool_parameters`
  attribute, which for the Skill tool includes `skill_name`.
  [monitoring-usage › Tool result event](https://code.claude.com/docs/en/monitoring-usage#tool-result-event)
  [monitoring-usage › Tool decision event](https://code.claude.com/docs/en/monitoring-usage#tool-decision-event)
  [monitoring-usage › Security and privacy](https://code.claude.com/docs/en/monitoring-usage#security-and-privacy)
- The `claude_code.tool` span has a `skill_name` attribute, the skill name for the Skill tool, gated by
  `OTEL_LOG_TOOL_DETAILS`.
  [monitoring-usage › Span attributes](https://code.claude.com/docs/en/monitoring-usage#span-attributes)
- Set `OTEL_LOG_TOOL_DETAILS` in your shell, user settings, or managed settings: it's ignored in
  [project and local settings](https://code.claude.com/docs/en/settings-reference#variables-claude-code-ignores-in-env),
  apart from the off values that section describes.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Not stated by the documentation

- The validate errors table says `No frontmatter block found` and `YAML frontmatter failed to parse` are reported when
  validating a plugin directory; the documentation does not say which of its messages a run on a directory with no
  `.claude-plugin/` manifest, such as `.claude/skills`, prints.
  [plugins/troubleshooting › `claude plugin validate` reports errors](https://code.claude.com/docs/en/plugins/troubleshooting#claude-plugin-validate-reports-errors)
- The `CLAUDE_CODE_USE_NATIVE_FILE_SEARCH` description names custom commands, subagents, and output styles; the
  documentation does not say whether it also covers custom skills, which the ripgrep fix above names.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)
- The documentation does not say how skill-creator's without-skill runs keep the skill out, or whether you must turn
  it off in `skillOverrides` first.
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
- A skill whose frontmatter YAML is malformed loads with empty metadata; the documentation does not say how such a
  skill is shown in `/skills`.
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)

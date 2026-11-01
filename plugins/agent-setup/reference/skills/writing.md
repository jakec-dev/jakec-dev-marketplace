# Writing skills

Writing a skill's body: content types, conciseness, supporting files, string substitutions, arguments, bundled
scripts and `ultrathink`.

## Contents

- Content types
- Conciseness
- Supporting files
- String substitutions
- Arguments
- Escaping and literal text
- Bundled scripts
- Plugin skills
- Deeper reasoning
- Clarifying questions in auto mode
- Not stated by the documentation

## Content types

- Skill files can contain any instructions; how you want the skill invoked guides what to include.
  [skills › Types of skill content](https://code.claude.com/docs/en/skills#types-of-skill-content)
- **Reference content** adds knowledge Claude applies to your current work: conventions, patterns, style guides,
  domain knowledge. This content runs inline so Claude can use it alongside your conversation context.
  [skills › Types of skill content](https://code.claude.com/docs/en/skills#types-of-skill-content)

  ```yaml
  ---
  name: api-conventions
  description: API design patterns for this codebase
  ---

  When writing API endpoints:
  - Use RESTful naming conventions
  - Return consistent error formats
  ```

- **Task content** gives Claude step-by-step instructions for a specific action, like deployments, commits, or code
  generation. These are often actions you want to invoke directly with `/skill-name`; add
  `disable-model-invocation: true` to prevent Claude from triggering it automatically. The example also sets
  `context: fork`, which runs the skill in its own subagent context.
  [skills › Types of skill content](https://code.claude.com/docs/en/skills#types-of-skill-content)

  ```yaml
  ---
  name: deploy
  description: Deploy the application to production
  context: fork
  disable-model-invocation: true
  ---

  Deploy the application:
  1. Run the test suite
  2. Build the application
  3. Push to the deployment target
  ```

## Conciseness

- Keep the body concise. Once a skill loads, its content stays in context across turns, so every line is a
  recurring token cost. State what to do rather than narrating how or why, and apply the same conciseness test as
  for [CLAUDE.md content](https://code.claude.com/docs/en/best-practices#keep-claude-md-short).
  [skills › Types of skill content](https://code.claude.com/docs/en/skills#types-of-skill-content)
- Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.
  [skills › Add supporting files](https://code.claude.com/docs/en/skills#add-supporting-files)

## Supporting files

- Skills can include multiple files in their directory, keeping `SKILL.md` focused on the essentials while Claude
  accesses detailed reference material only when needed. Large reference docs, API specifications, or example
  collections don't need to load into context every time the skill runs.
  [skills › Add supporting files](https://code.claude.com/docs/en/skills#add-supporting-files)

  ```text
  my-skill/
  ├── SKILL.md (required - overview and navigation)
  ├── reference.md (detailed API docs - loaded when needed)
  ├── examples.md (usage examples - loaded when needed)
  └── scripts/
      └── helper.py (utility script - executed, not loaded)
  ```

- Reference supporting files from `SKILL.md` so Claude knows what each file contains and when to load it:
  [skills › Add supporting files](https://code.claude.com/docs/en/skills#add-supporting-files)

  ```markdown
  ## Additional resources

  - For complete API details, see [reference.md](reference.md)
  - For usage examples, see [examples.md](examples.md)
  ```

- In the documentation's comparison of CLAUDE.md and a skill, both can include files with `@path` imports.
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)

## String substitutions

- Skills support string substitution for dynamic values in the skill content:
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)

| Variable | Description |
| :- | :- |
| `$ARGUMENTS` | All arguments passed when invoking the skill. When no placeholder receives an argument, Claude Code appends them as `ARGUMENTS: <value>`. See [Pass arguments to skills](https://code.claude.com/docs/en/skills#pass-arguments-to-skills). |
| `$ARGUMENTS[N]` | Access a specific argument by 0-based index, such as `$ARGUMENTS[0]` for the first argument. |
| `$N` | Shorthand for `$ARGUMENTS[N]`, such as `$0` for the first argument or `$1` for the second. |
| `$name` | Named argument declared in the `arguments` frontmatter list. Names map to positions in order, so with `arguments: [issue, branch]` the placeholder `$issue` expands to the first argument and `$branch` to the second. |
| `${CLAUDE_SESSION_ID}` | The current session ID. Useful for logging, creating session-specific files, or correlating skill output with sessions. |
| `${CLAUDE_EFFORT}` | The current effort level: `low`, `medium`, `high`, `xhigh`, or `max`. Use this to adapt skill instructions to the active effort setting. |
| `${CLAUDE_SKILL_DIR}` | The directory containing the skill's `SKILL.md` file. For plugin skills, this is the skill's subdirectory within the plugin, not the plugin root. Use this in bash injection commands to reference scripts or files bundled with the skill, regardless of the current working directory. |
| `${CLAUDE_PROJECT_DIR}` | The project root directory. This is the same path [hooks](https://code.claude.com/docs/en/hooks#reference-scripts-by-path) and MCP servers receive as `CLAUDE_PROJECT_DIR`. Use this to reference project-local scripts or files, such as `${CLAUDE_PROJECT_DIR}/.claude/hooks/helper.sh`, independent of where the skill is installed. |
| `${CLAUDE_PLUGIN_ROOT}` | The plugin's installation directory. Substituted only in plugin skills. Use this to reference scripts or files bundled anywhere in the plugin, including resources shared between the plugin's skills. See [plugin environment variables](https://code.claude.com/docs/en/plugins/manifest-reference#environment-variables). |
| `${CLAUDE_PLUGIN_DATA}` | The plugin's [persistent data directory](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data), which survives plugin updates. Substituted only in plugin skills. Use this to reference installed dependencies, generated files, or caches that must outlive an update. |

- Claude Code substitutes `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` in two places: the skill's markdown
  content, and Bash rules in the `allowed-tools` frontmatter. In a plugin skill, it substitutes
  `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` in the same two places.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- Example using substitutions:
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)

  ```yaml
  ---
  name: session-logger
  description: Log activity for this session
  ---

  Log the following to logs/${CLAUDE_SESSION_ID}.log:

  $ARGUMENTS
  ```

## Arguments

- Both you and Claude can pass arguments when invoking a skill. The `$ARGUMENTS` placeholder gets replaced with
  whatever follows the skill name: with `Fix GitHub issue $ARGUMENTS following our coding standards.` in the body,
  `/fix-issue 123` gives Claude "Fix GitHub issue 123 following our coding standards...".
  [skills › Pass arguments to skills](https://code.claude.com/docs/en/skills#pass-arguments-to-skills)
- To access individual arguments by position, use `$ARGUMENTS[N]` or the shorter `$N`. Running
  `/migrate-component SearchBar JavaScript TypeScript` against this body replaces `$ARGUMENTS[0]` with `SearchBar`,
  `$ARGUMENTS[1]` with `JavaScript`, and `$ARGUMENTS[2]` with `TypeScript`:
  [skills › Pass arguments to skills](https://code.claude.com/docs/en/skills#pass-arguments-to-skills)

  ```yaml
  ---
  name: migrate-component
  description: Migrate a component from one language to another
  ---

  Migrate the $ARGUMENTS[0] component from $ARGUMENTS[1] to $ARGUMENTS[2].
  Preserve all existing behavior and tests.
  ```

  The same skill using the `$N` shorthand, where `$0`, `$1` and `$2` stand for those three:

  ```yaml
  ---
  name: migrate-component
  description: Migrate a component from one language to another
  ---

  Migrate the $0 component from $1 to $2.
  Preserve all existing behavior and tests.
  ```

- Indexed arguments use shell-style quoting, so wrap multi-word values in quotes to pass them as a single argument:
  `/my-skill "hello world" second` makes `$0` expand to `hello world` and `$1` to `second`. The `$ARGUMENTS`
  placeholder always expands to the full argument string as typed.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- An indexed placeholder with no corresponding argument, such as `$2` when only one argument was passed, stays in
  the content unchanged and doesn't count as receiving one. A named placeholder from the `arguments` frontmatter
  with no matching argument expands to an empty string, and counts as receiving one even when its position has no
  argument. The appended `ARGUMENTS: <value>` line goes at the end of the skill content. For it, a placeholder is
  `$ARGUMENTS`, an indexed form such as `$1`, or a named argument.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
  [skills › Pass arguments to skills](https://code.claude.com/docs/en/skills#pass-arguments-to-skills)

## Escaping and literal text

- If you pass an argument value that itself contains text such as `$1` or `$ARGUMENTS`, Claude Code inserts it as
  literal text and doesn't expand it: with a body of `Summarize $0`, `/summarize "$ARGUMENTS from yesterday"` gives
  Claude `Summarize $ARGUMENTS from yesterday`. Claude Code still replaces `${CLAUDE_*}` variables such as
  `${CLAUDE_SKILL_DIR}` after it inserts the arguments.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- To include a literal `$` before a digit, `ARGUMENTS`, or a declared argument name, such as `$1.00` in prose,
  escape it with a backslash: `\$1.00`. A backslash before any other `$` is left unchanged. Only a single backslash
  directly before the token escapes it: `\\$1` leaves both backslashes in place, and `$1` still expands.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- The backslash escape covers only the argument placeholders. A backslash doesn't prevent substitution of a
  `${CLAUDE_*}` variable where the variable applies.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)

## Bundled scripts

- Skills can bundle and run scripts in any language, giving Claude capabilities beyond what's possible in a single
  prompt. One pattern is generating visual output: interactive HTML files that open in your browser for exploring
  data, debugging, or creating reports. The pattern works for any visual output: dependency graphs, test coverage
  reports, API documentation, or database schema visualizations. The bundled script does the work while Claude
  handles orchestration.
  [skills › Generate visual output](https://code.claude.com/docs/en/skills#generate-visual-output)
- In the documentation's pattern, `SKILL.md` holds a description that tells Claude when to activate the skill and
  instructions that tell Claude to run the script. The script path uses `${CLAUDE_SKILL_DIR}` so it resolves
  whether the skill is installed at the personal, project, or plugin level:
  [skills › Generate visual output](https://code.claude.com/docs/en/skills#generate-visual-output)

  ````yaml
  ---
  name: codebase-visualizer
  description: Generate an interactive collapsible tree visualization of your codebase. Use when exploring a new repo, understanding project structure, or identifying large files.
  allowed-tools: Bash(python3 *)
  ---

  Run the visualization script from your project root:

  ```bash
  python3 ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
  ```
  ````

- Using the same variable in the body and in an `allowed-tools` Bash rule lets a skill run a bundled script without
  a permission prompt. Installed at `~/.claude/skills/render-chart/`, both occurrences of `${CLAUDE_SKILL_DIR}`
  below expand to that directory, so the rule matches the exact command the body tells Claude to run:
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)

  ```yaml
  ---
  name: render-chart
  description: Render a chart from a CSV file
  allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)
  ---

  Run `${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` to render the chart.
  ```

## Plugin skills

- The plugin page's variables (`CLAUDE_PLUGIN_ROOT`, `CLAUDE_PLUGIN_DATA` and `CLAUDE_PROJECT_DIR`) aren't present in
  the environment of commands Claude runs through the Bash tool, in the main session or in a subagent. In skill,
  command, and agent content, write the `${...}` reference in the Markdown body instead, and Claude Code substitutes the
  path inline when it loads the content.
  [plugins/manifest-reference › Where each variable resolves](https://code.claude.com/docs/en/plugins/manifest-reference#where-each-variable-resolves)
- Each plugin version has its own cache directory, so the `${CLAUDE_PLUGIN_ROOT}` path changes when the plugin
  updates. Don't write state there.
  [plugins/components › Reference plugin paths and store data](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data)
- `${CLAUDE_PLUGIN_DATA}` resolves to `~/.claude/plugins/data/<id>/` and is created when first referenced. In that
  path, `<id>` is the plugin identifier with every character other than letters, digits, `_`, and `-` replaced by
  `-`, so `my-plugin@my-marketplace` becomes `my-plugin-my-marketplace`.
  [plugins/components › Reference plugin paths and store data](https://code.claude.com/docs/en/plugins/components#path-variables-and-persistent-data)
- While the plugin is enabled, Claude Code puts the plugin's `bin/` folder on the `PATH` of the shell it runs
  commands in, so Claude, or a skill's instructions, can run the tool by name without the user installing anything.
  [plugins/components › Explore the plugin directory](https://code.claude.com/docs/en/plugins/components#explore-the-plugin-directory)
- A plugin's saved `${user_config.KEY}` value is substituted in skill and agent content, but only non-sensitive
  values; a sensitive value there becomes a placeholder.
  [plugins/manifest-reference › Reference a saved value](https://code.claude.com/docs/en/plugins/manifest-reference#reference-a-saved-value)

## Deeper reasoning

- To request deeper reasoning when a skill runs, include `ultrathink` anywhere in the skill content. See
  [Use ultrathink for one-off deep reasoning](https://code.claude.com/docs/en/model-config#use-ultrathink-for-one-off-deep-reasoning).
  [skills › Inject dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)

## Clarifying questions in auto mode

- Auto mode nudges Claude to keep working without stopping for clarifying questions, though Claude still asks when
  your prompt or a skill explicitly relies on it.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)

## Not stated by the documentation

- Whether a supporting file such as `reference.md` gets argument placeholders and `${CLAUDE_*}` variables
  substituted: the documentation names "the skill's markdown content" and `allowed-tools` Bash rules for
  `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}`, and does not say whether a supporting file counts.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- What `${CLAUDE_SKILL_DIR}` expands to for a command file in `.claude/commands/`, which has no `SKILL.md`.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- Whether `${CLAUDE_SKILL_DIR}` is present in the environment of commands Claude runs through the Bash tool: the
  plugin page's statement covers the plugin variables.
  [plugins/manifest-reference › Where each variable resolves](https://code.claude.com/docs/en/plugins/manifest-reference#where-each-variable-resolves)
- When an `@path` in `SKILL.md` expands and how: the documentation says only that a skill can include files with
  `@path` imports, and the substitutions section names `${CLAUDE_*}` variables and argument placeholders, not `@`
  references.
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- What placeholder replaces a sensitive `${user_config.KEY}` value in skill content.
  [plugins/manifest-reference › Reference a saved value](https://code.claude.com/docs/en/plugins/manifest-reference#reference-a-saved-value)
- How a skill "explicitly relies on" clarifying questions so that auto mode still asks them.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)

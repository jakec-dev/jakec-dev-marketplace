# Skills topics

- `placing.md`: deciding where a skill or command file goes and what it is called (locations, nested and monorepo
  directories, worktrees, symlinks, reserved names, refused characters in names, name clashes, the added-directory
  prefix, command names, plugin skill layout, recorded `/run` and `/verify` recipes)
- `frontmatter.md`: writing a skill's frontmatter (every field, parsing, booleans, the spec subset for claude.ai and
  the API, `model` and `effort` interactions including the forked subagent's model, frontmatter `hooks`)
- `writing.md`: writing a skill's body (content types, conciseness, supporting files, string substitutions,
  arguments, escaping, bundled scripts, plugin skill variables and `user_config`, `ultrathink`, clarifying questions
  in auto mode)
- `dynamic-context.md`: injecting shell output into a skill (`` !`cmd` `` and ```` ```! ```` blocks, the `shell`
  field, how commands run, failures, permission checks, `disableSkillShellExecution`)
- `invoking.md`: controlling and making invocation (who can invoke, where the name goes, stacking, the Skill tool,
  scheduled tasks and `/loop`, monitors started by a skill, the commit-time `verify` and `simplify` instruction and
  the git-instruction switches, the bundled `/claude-api` subcommands, `-p`, GitHub Actions)
- `permissions.md`: tools during a skill and permission rules on skills (`allowed-tools`, `disallowed-tools`,
  workspace trust, `allowManagedPermissionRulesOnly`, pre-approval lost under the `strictPluginOnlyCustomization`
  hooks lock, `Skill(...)` rules, `UserPromptExpansion` and `PreToolUse`)
- `forking.md`: running a skill in a subagent (`context: fork`, `agent`, `background`, tools, checkpoints, the
  output stream)
- `loading.md`: knowing when skill content enters and stays in context (the listing and its budget, the content
  lifecycle, compaction, live change detection, `/reload-skills`, `reloadSkills`, prompt caching, teammates)
- `sharing.md`: getting skills to more people or sessions (committing, managed deployment, plugins, `--add-dir`,
  skills synced from claude.ai)
- `excluding.md`: stopping skills from loading or being seen (`skillOverrides`, `disableBundledSkills`,
  `CLAUDE_CODE_DISABLE_POLICY_SKILLS`, `strictPluginOnlyCustomization`, skills-directory plugins blocked by managed
  settings, `syncClaudeAiSkills`, removal, `--bare`, `--safe-mode`, `--disable-slash-commands`)
- `troubleshooting.md`: checking whether a skill loads, triggers and works, and why not (troubleshooting sections,
  evals and skill-creator, `/skills`, `/skill-doctor`, validation, error messages, OpenTelemetry)

Skills-directory plugins, skill folders under `~/.claude/skills/` or `.claude/skills/` that carry a
`.claude-plugin/plugin.json`, are split between types: skills owns where they are placed and what shadows or blocks
them (`placing.md`, `excluding.md`); the plugins type owns how they are enabled and what they bundle.

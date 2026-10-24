# Loading skills

When skill content enters Claude's context and how long it stays: the skill listing and its budget, discovery during
a session, invoked content, compaction, changes on disk and teammates.

## Contents

- [The skill listing](#the-skill-listing)
- [The listing's budget](#the-listings-budget)
- [Skills found during a session](#skills-found-during-a-session)
- [Invoked skill content](#invoked-skill-content)
- [After compaction](#after-compaction)
- [Changes on disk](#changes-on-disk)
- [In subagents and agent teams](#in-subagents-and-agent-teams)
- [Not stated by the documentation](#not-stated-by-the-documentation)

## The skill listing

- Unlike CLAUDE.md content, a skill's body loads only when it's used, so long reference material costs almost nothing
  until you need it. In a regular session, skill descriptions are loaded into context so Claude knows what's
  available, but full skill content only loads when invoked.
  [skills › Extend Claude with skills](https://code.claude.com/docs/en/skills),
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
- The list of available skills reaches Claude as a system reminder.
  [glossary › System reminder](https://code.claude.com/docs/en/glossary#system-reminder)
- In bare mode, Claude doesn't get the list of available skills, including skills from an `--add-dir` folder.
  [headless › Start faster with bare mode](https://code.claude.com/docs/en/headless#start-faster-with-bare-mode)
- Claude Code loads a listing of skill names and descriptions into context so Claude knows what's available. The
  listing always contains every skill name, but if you have many skills, Claude Code drops some descriptions to fit
  the listing's character budget, which removes the keywords Claude needs to match your request.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)
- For a skill with `disable-model-invocation: true`, the documentation differs: the invocation table says its
  description is not in context; Restrict Claude's skill access says the field "removes the skill from Claude's context
  entirely"; and features-overview says nothing loads until you invoke it. It does not say plainly whether such a
  skill's name stays in the listing.
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill),
  [skills › Restrict Claude's skill access](https://code.claude.com/docs/en/skills#restrict-claude’s-skill-access),
  [features-overview › Understand how features load](https://code.claude.com/docs/en/features-overview#understand-how-features-load)

## The listing's budget

- The character budget for skill metadata shown to the Skill tool scales dynamically at 1% of the context window, with
  a fallback of 8,000 characters. The `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable overrides it with a fixed
  character count; it is a legacy name kept for backwards compatibility.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables),
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)
- When the listing overflows, Claude Code drops descriptions starting with the skills you invoke least, so the skills
  you use most keep their full text. To free budget for other skills, set low-priority entries to `"name-only"` in
  `skillOverrides` so they list without a description.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)
- A skill whose description is dropped can still be invoked by Claude but is less likely to be chosen on its own.
  Raise `skillListingBudgetFraction` to keep more descriptions visible at the cost of more context per turn.
  - **Scope**: `Any file`
  - **Type**: number, a fraction greater than `0` and at most `1`
  - **Default**: `0.01`

  ```json
  {
    "skillListingBudgetFraction": 0.02
  }
  ```

  [settings-reference › `skillListingBudgetFraction`](https://code.claude.com/docs/en/settings-reference#skilllistingbudgetfraction)
- The listing shows each skill's `description` and `when_to_use` text, and each entry's combined text is capped at
  1,536 characters regardless of budget; longer text is cut at the cap. Put the key use case first.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short),
  [settings-reference › `skillListingMaxDescChars`](https://code.claude.com/docs/en/settings-reference#skilllistingmaxdescchars)
- `skillListingMaxDescChars` sets that per-skill cap. Raise it to keep long descriptions intact at the cost of more
  context per turn; lower it to fit more skills under `skillListingBudgetFraction`.
  - **Scope**: `Any file`
  - **Type**: number of characters, a positive integer
  - **Default**: `1536`

  ```json
  {
    "skillListingMaxDescChars": 2048
  }
  ```

  [settings-reference › `skillListingMaxDescChars`](https://code.claude.com/docs/en/settings-reference#skilllistingmaxdescchars)
- When the listing exceeds its budget, Claude Code writes a warning to the debug log, visible with `--debug`.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)
- The Skills row in `/context` reports the size of the listing after the budget is applied, so it matches what the
  model receives.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)

## Skills found during a session

- Skills in a `.claude/skills/` directory below where you started don't load at startup. They load the first time
  Claude reads or edits a file in that subdirectory and stay available for the rest of the session. Until then they
  don't appear in the `/` menu and you can't invoke them by name. To load them sooner, run `/add-dir` with the
  subdirectory's path.
  [skills › Load skills in monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)
- When you move the session with `/cd`, Claude Code adds the new directory's project skills.
  [skills › Load skills in monorepos and subdirectories](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)

## Invoked skill content

- When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and
  stays there across later turns. This persistence applies to the skill's instructions, not its permissions: an
  `allowed-tools` grant clears when you send your next message.
  [skills › Skill content lifecycle](https://code.claude.com/docs/en/skills#skill-content-lifecycle)
- Claude Code does not re-read the skill file on later turns, so write guidance that should apply throughout a task
  as standing instructions rather than one-time steps.
  [skills › Skill content lifecycle](https://code.claude.com/docs/en/skills#skill-content-lifecycle)
- When Claude re-invokes a skill whose rendered content is identical to the copy already in context, Claude Code adds
  a short note that the skill is already loaded rather than a second copy. When the rendered content differs, because
  the arguments changed or a dynamic context command produced new output, Claude Code appends the full content again.
  [skills › Skill content lifecycle](https://code.claude.com/docs/en/skills#skill-content-lifecycle)
- For prompt caching, skills and commands inject their instructions as user messages at the point of invocation, and
  nothing earlier in the conversation changes.
  [prompt-caching › Invoking skills and commands](https://code.claude.com/docs/en/prompt-caching#invoking-skills-and-commands)
- Claude Code never invalidates the cache for a plugin's skills.
  It appends their content after the existing conversation, so the next request pays for that content and still reads
  everything before it from the cache.
  [prompt-caching › Plugin components that keep the cache](https://code.claude.com/docs/en/prompt-caching#plugin-components-that-keep-the-cache)
- In a mod, the `skill.prompt` event fires when a skill's text is expanded for Claude, and a hook can return `{ text }`
  to rewrite it. Text from `prompt.section`, `prompt.context` or `skill.prompt` hooks that changes between
  requests invalidates the prompt cache.
  [mods reference › Prompts and what Claude reads](https://code.claude.com/docs/en/plugins/mods/reference#prompts-and-what-claude-reads),
  [mods events › Rewrite or add to a prompt](https://code.claude.com/docs/en/plugins/mods/events#rewrite-or-add-to-a-prompt)

## After compaction

- Auto-compaction carries invoked skills forward within a token budget. When the conversation is summarized to free
  context, Claude Code re-attaches the most recent invocation of each skill after the summary, keeping the first
  5,000 tokens of each. Re-attached skills share a combined budget of 25,000 tokens, filled starting from the most
  recently invoked skill, so older skills can be dropped entirely after compaction if you have invoked many in one
  session.
  [skills › Skill content lifecycle](https://code.claude.com/docs/en/skills#skill-content-lifecycle)
- Large skills are truncated to fit the per-skill cap, and truncation keeps the start of the file, so put the most
  important instructions near the top of `SKILL.md`.
  [context-window › What survives compaction](https://code.claude.com/docs/en/context-window#what-survives-compaction)

## Changes on disk

- Claude Code watches skill directories for file changes, except in bare mode. When you add, edit, or remove a skill
  under `~/.claude/skills/`, the project `.claude/skills/`, or a `.claude/skills/` inside an `--add-dir` directory,
  Claude Code picks up the change within the current session, without a restart. Claude Code watches `.claude/skills/`
  in a directory you pass with `--add-dir` at launch. It doesn't watch the added directory's `.claude/commands/` or
  `.claude/agents/`, so restart the session after changing a file there.
  [skills › Edit a skill during a session](https://code.claude.com/docs/en/skills#live-change-detection),
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- If you create a top-level skills directory that didn't exist when the session started, run `/reload-skills` to
  pick up the skills you put there. Claude Code isn't watching that directory yet, so run `/reload-skills` again after
  each later change there.
  [skills › Edit a skill during a session](https://code.claude.com/docs/en/skills#live-change-detection)
- `/reload-skills` re-scans skill and command directories so skills added or changed on disk during the session
  become available without restarting. It reports how many skills are available and how many were added or removed.
  [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- Live change detection covers `SKILL.md` text only. For a skill folder that is also a plugin, changes to `hooks/`,
  `.mcp.json`, `agents/`, and `output-styles/` need `/reload-plugins` to take effect.
  [skills › Edit a skill during a session](https://code.claude.com/docs/en/skills#live-change-detection)
- Skill discovery normally runs before SessionStart hooks finish, so files a SessionStart hook writes into
  `~/.claude/skills/` or `.claude/skills/` would otherwise only appear in the next session. When the hook returns
  `reloadSkills: true` (a boolean), Claude Code re-scans the skill and command directories after the SessionStart
  hooks complete, so skills the hook installed are available in the same session, starting with the first prompt.
  This example syncs a shared skills repository, whose URL is a placeholder, and requests the re-scan:

  ```bash
  #!/bin/bash

  git -C ~/.claude/skills/team-skills pull --quiet 2>/dev/null || \
    git clone --quiet https://git.example.com/your-org/team-skills.git ~/.claude/skills/team-skills

  echo '{"hookSpecificOutput": {"hookEventName": "SessionStart", "reloadSkills": true}}'
  ```

  Stderr from a SessionStart hook that exits 0 is informational only, so with the placeholder URL the clone fails
  with a `fatal:` message and the `reloadSkills` request still applies.
  [hooks › SessionStart decision control](https://code.claude.com/docs/en/hooks#sessionstart-decision-control)
- Claude Code runs ConfigChange hooks when a skill file changes. The `skills` matcher fires when a skill file in
  `.claude/skills/` changes. When a ConfigChange hook blocks a change, the new settings are not applied to the running
  session.
  [hooks › ConfigChange](https://code.claude.com/docs/en/hooks#configchange),
  [hooks › ConfigChange decision control](https://code.claude.com/docs/en/hooks#configchange-decision-control)

## In subagents and agent teams

- A non-fork subagent starts with a fresh, isolated context window and doesn't see the skills you've already invoked.
  Built-in agents don't preload skills.
  [sub-agents › What loads at startup](https://code.claude.com/docs/en/sub-agents#what-loads-at-startup)
- Subagents with preloaded skills get the full skill content injected at startup.
  [skills › Control who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)
- A subagent's `skills` field controls which skills are preloaded, not which skills it can access: without it, the
  subagent can still discover and invoke project, user, and plugin skills through the Skill tool during execution. To
  prevent a subagent from invoking skills entirely, omit `Skill` from its `tools` list or add it to `disallowedTools`.
  If a listed skill is missing or disabled, for example by your organization's policy, Claude Code skips it and logs a
  warning to the debug log.
  [sub-agents › Preload skills into subagents](https://code.claude.com/docs/en/sub-agents#preload-skills-into-subagents)
- When a teammate is spawned, it loads the same project context as a regular session, including skills. If you start
  the lead with `--setting-sources`, teammates load from the same restricted list of sources.
  [agent-teams › Context and communication](https://code.claude.com/docs/en/agent-teams#context-and-communication)
- When a teammate is spawned from a subagent definition, Claude Code doesn't apply the definition's `skills` to it in
  either display mode. The teammate loads skills from your project and user settings.
  [agent-teams › Use subagent definitions for teammates](https://code.claude.com/docs/en/agent-teams#use-subagent-definitions-for-teammates)

## Not stated by the documentation

- The documentation does not say whether a nested `.claude/skills/` directory, loaded because Claude read or edited a
  file there, is watched for later changes or needs `/reload-skills`.
  [skills › Edit a skill during a session](https://code.claude.com/docs/en/skills#live-change-detection)
- The documentation does not say whether a directory added mid-session with `/add-dir` is watched; it says only that
  `.claude/skills/` in a directory passed with `--add-dir` is watched "at launch".
  [skills › Load skills from a directory outside the project](https://code.claude.com/docs/en/skills#skills-from-additional-directories)
- The documentation does not say which wins when both `skillListingBudgetFraction` and
  `SLASH_COMMAND_TOOL_CHAR_BUDGET` are set.
  [skills › Skill descriptions are cut short](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short)
- The documentation does not say whether a hook that blocks a `skills` change stops a changed `SKILL.md` being picked
  up, or whether the `skills` matcher fires for changes under `~/.claude/skills/`.
  [hooks › ConfigChange](https://code.claude.com/docs/en/hooks#configchange),
  [hooks › ConfigChange decision control](https://code.claude.com/docs/en/hooks#configchange-decision-control)

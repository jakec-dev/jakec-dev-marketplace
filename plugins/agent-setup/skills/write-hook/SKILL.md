---
name: write-hook
description: Writes, fixes or explains a Claude Code hook, or says when another tool fits better. Use when the user wants something to happen automatically at a point in Claude's work, such as before or after a tool call, when a session starts or when Claude stops, or asks why a hook isn't firing, blocking or having an effect.
allowed-tools: Read, Glob, Grep
---

# Write a hook

Base the work on the plugin's reference, which says how Claude Code finds, runs and reads hooks, and its guidance,
which says what makes a hook good. Not on memory: a hook with the wrong exit code, matcher or JSON shape fails
silently.

1. **Read both indexes in full:** `${CLAUDE_PLUGIN_ROOT}/reference/hooks/index.md` and
   `${CLAUDE_PLUGIN_ROOT}/guidance/index.md`. Their key facts and key principles apply to every task.
2. **Read `${CLAUDE_PLUGIN_ROOT}/guidance/write-hooks.md` in full,** then pick the other sections the task needs
   from the two Topics lists, always including the section for each event the hook uses. Read each one: find its
   `## ` heading with Grep, then Read from that line to the next `## ` heading.
3. **Find the hooks that already exist** with Grep for `"hooks"` in `.claude/settings.json`,
   `.claude/settings.local.json` and `~/.claude/settings.json`, in `hooks/hooks.json` in a plugin, and in the
   frontmatter of `.claude/skills/*/SKILL.md` and `.claude/agents/*.md`. Read the ones on the same event, so that the
   new hook doesn't repeat one or conflict with its decision.
4. **Check that a hook is the right tool** against the `choose.md` sections. If it is guidance Claude should weigh,
   a fixed fact for every session, or a permission a rule can state, say which tool fits and why, and offer that
   instead. Write the hook anyway only if the user still wants it.
5. **Do the task:** write or fix the hook entry and its script, or answer the question. Follow the reference for
   every event, field, exit code and output, and make the result pass the `Check:` line of every guidance section
   you read. Where the reference lists something as not stated by the documentation, say so rather than guess.
6. **Say how to verify it:** how to confirm the hook loaded, an action that should trigger it and one that should
   not, and where to see that it acted.

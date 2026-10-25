---
name: write-skill
description: Writes, fixes or explains a Claude Code skill or custom command, or says when another tool fits better. Use when the user wants a reusable procedure or reference that Claude loads on demand or runs with /name, or asks why a skill isn't loading, triggering or working.
allowed-tools: Read, Glob, Grep
---

# Write a skill

Base the work on the plugin's reference, which says how Claude Code finds, loads and runs skills, and its guidance,
which says what makes a skill good. Not on memory: much of what goes wrong with a skill fails silently.

1. **Read both indexes in full:** `${CLAUDE_PLUGIN_ROOT}/reference/skills/index.md` and
   `${CLAUDE_PLUGIN_ROOT}/guidance/index.md`. Their key facts and key principles apply to every task.
2. **Read `${CLAUDE_PLUGIN_ROOT}/guidance/write-skills.md` in full,** then pick the other sections the task needs
   from the two Topics lists. Read each one: find its `## ` heading with Grep, then Read from that line to the next
   `## ` heading.
3. **Find the skills that already exist** with Glob: `.claude/skills/*/SKILL.md` and `.claude/commands/**/*.md` at
   any depth, and `skills/*/SKILL.md` in a plugin. Read the ones whose name or description is close to the new
   skill's, so that it doesn't clash with a name or overlap a description.
4. **Check that a skill is the right tool** against the `choose.md` sections. If it must happen every time, should
   be in every session, or connects to an outside service, say which tool fits and why, and offer that instead.
   Write the skill anyway only if the user still wants it.
5. **Do the task:** write or fix the skill folder and its `SKILL.md`, or answer the question. Follow the reference
   for every field, path and command, and make the result pass the `Check:` line of every guidance section you read.
   Where the reference lists something as not stated by the documentation, say so rather than guess.
6. **Say how to verify it:** how to confirm the skill loaded, a prompt that should trigger it and one that should
   not, and how to compare its output with a run without it.

---
name: write-rule
description: Writes, fixes or explains a Claude Code rule in .claude/rules/, or says when another tool fits better. Use when the user wants Claude to follow certain instructions for some files or every session, or asks why a rule is or isn't loading.
allowed-tools: Read, Glob, Grep
---

# Write a rule

Base the work on the plugin's reference, which says how rules behave, and its guidance, which says what makes a rule
good. Not on memory.

1. **Read both indexes in full:** `${CLAUDE_PLUGIN_ROOT}/reference/rules/index.md` and
   `${CLAUDE_PLUGIN_ROOT}/guidance/index.md`. Their key facts and key principles apply to every task.
2. **Pick the sections the task needs** from the two Topics lists. Read each one: find its `## ` heading with Grep,
   then Read from that line to the next `## ` heading.
3. **Check that a rule is the right tool** against the `choose.md` sections. If the instruction must hold every time
   or run at a fixed point, needs a procedure, or is about the response rather than the project, say which tool fits
   and why, and offer that instead. Write the rule anyway only if the user still wants it.
4. **Do the task:** write or fix the rule file, or answer the question. Follow the reference for how the rule must be
   written, and make the result pass the `Check:` line of every guidance section you read. Where the reference lists
   something as not stated by the documentation, say so rather than guess.
5. **Say how to verify it:** how to confirm the rule loaded and what to try to see it change Claude's behaviour.

---
name: write-rule
description: Writes, fixes or explains a Claude Code rule in .claude/rules/. Use when the user wants Claude to follow certain instructions for some files or every session, or asks why a rule is or isn't loading.
allowed-tools: Read, Glob, Grep
---

# Write a rule

Base the rule on the plugin's knowledge of how rules work, not on memory.

1. Read `${CLAUDE_PLUGIN_ROOT}/reference/rules/index.md` and decide which topic files the task needs.
2. Read those topic files in full.
3. Do the task: write or fix the rule file, or answer the question, following what the knowledge says. Where the
   knowledge lists something as not stated by the documentation, say so rather than guess.

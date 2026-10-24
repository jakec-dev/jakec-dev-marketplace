---
description: A forked skill asked to work from the conversation, which its subagent never sees.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Create a project skill called recap that runs in a forked subagent (`context: fork`) so it doesn't clutter my
session, and summarises the decisions we've made so far in this conversation.

---
description: A glob for a folder name containing a square bracket.
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

We keep scanned photos in a folder literally named "photos [2024" at the repo root (yes, with an unclosed
bracket). Add a rule that applies only to files inside that folder, telling Claude never to rename them.

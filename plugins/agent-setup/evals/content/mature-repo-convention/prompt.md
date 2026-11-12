---
description: The same component convention, given at session start, where every component does the opposite.
tags: [content]
plugins: ["plugin"]
runs: 5
max_turns: 20
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Write, Edit]
---

Add a StatCard component in src/components/stat-card.tsx that shows a label, a large value, an optional
trend (up or down, with a percentage) and an optional footer link. Export it from src/components/index.ts. Make the
change, then stop.

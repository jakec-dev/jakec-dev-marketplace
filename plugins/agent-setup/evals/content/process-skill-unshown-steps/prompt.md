---
description: A process skill whose steps are partly shown by an example in the code and partly not.
tags: [content]
plugins: ["plugin"]
runs: 5
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add an invoices feature: GET /invoices lists invoices and GET /invoices/:id returns one, or a 404 when there is no
such invoice. Keep the invoices in an in-memory array for now. Make the change, then stop.

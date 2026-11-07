---
description: An MCP server only one subagent needs, defined inline in its mcpServers with a matching tools entry.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

Add a project subagent that checks our checkout flow in a real browser using the Playwright MCP server
(`npx -y @playwright/mcp@latest`). Nothing else in the project needs Playwright.

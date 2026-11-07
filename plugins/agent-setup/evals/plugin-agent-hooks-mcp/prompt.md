---
description: A plugin agent asked for hooks and mcpServers in its frontmatter, which plugin agents ignore.
tags: [subagents]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

In our acme-plugin, add a db-reader agent that answers questions by running SQL through the Postgres MCP server
(`npx -y @modelcontextprotocol/server-postgres postgresql://localhost/shop`), with a PreToolUse hook that blocks
anything but SELECT queries. Put the MCP server and the hook in the agent's frontmatter.

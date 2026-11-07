---
type: llm
---

PASS if the answer says that plugin agents ignore both `hooks` and `mcpServers` in their frontmatter, and either
proposes a project or user agent in `.claude/agents/` or `~/.claude/agents/` instead, or puts or proposes the MCP
server in the plugin's MCP configuration (such as its `.mcp.json`) and the hook in the plugin's hooks configuration
(such as `hooks/hooks.json`), saying that the hook then applies whenever the plugin is enabled rather than only
inside the subagent.
FAIL if it misses either field, writes them into the plugin agent's frontmatter as if they would work, or moves the
hook to the plugin's hooks configuration without saying it then applies beyond the subagent.

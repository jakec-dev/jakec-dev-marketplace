---
type: llm
---

PASS if the answer says that plugin agents ignore both `permissionMode` and `initialPrompt`, and gives copying the
agent file into `.claude/agents/` or `~/.claude/agents/` as the fix for both. It may also offer
`permissions.allow` rules in settings for the permission prompts, but only as a fix for `permissionMode`, saying
that they are not limited to the agent, such as that they apply to the whole session or project.
FAIL if it misses either field, doesn't offer copying the agent out of the plugin, offers allow rules as a fix for
`initialPrompt`, or offers allow rules without saying they are not limited to the agent.

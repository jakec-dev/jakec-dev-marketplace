# Combining tools

Making several tools work together, and keeping the whole setup within Claude's context.

## Each tool does what it is best at

- "Each extension solves a different problem: CLAUDE.md handles always-on context, skills handle on-demand knowledge
  and workflows, MCP handles external connections, subagents handle isolation, and hooks handle automation."

  | Pattern | How it works | Example |
  | - | - | - |
  | **Skill + MCP** | MCP provides the connection; a skill teaches Claude how to use it well | MCP connects to your database, a skill documents your schema and query patterns |
  | **Skill + Subagent** | A skill spawns subagents for parallel work | `/audit` skill kicks off security, performance, and style subagents that work in isolated context |
  | **CLAUDE.md + Skills** | CLAUDE.md holds always-on rules; skills hold reference material loaded on demand | CLAUDE.md says "follow our API conventions," a skill contains the full API style guide |
  | **Hook + MCP** | A hook triggers external actions through MCP | Post-edit hook sends a Slack notification when Claude modifies critical files |

  [features-overview › Combine features](https://code.claude.com/docs/en/features-overview#combine-features)
- "Hook output lands in context. A `PostToolUse` hook that runs your linter feeds results back as text Claude reads;
  a `/fix-lint` skill tells Claude how to resolve them."
  [features-overview › Compare similar features](https://code.claude.com/docs/en/features-overview#compare-similar-features)
- Check: where a hook reports problems Claude must fix, Claude has the knowledge to fix them.

## Instructions at several levels add up

- "CLAUDE.md files are additive: all levels contribute content to Claude's context simultaneously." "When
  instructions conflict, Claude uses judgment to reconcile them."
  [features-overview › Understand how features layer](https://code.claude.com/docs/en/features-overview#understand-how-features-layer)
- Check: a new instruction is placed at one level, and does not repeat or contradict one at another level.

## The whole setup has a context budget

- "Every feature you add consumes some of Claude's context. Too much can fill up your context window, but it can
  also add noise that makes Claude less effective; skills may not trigger correctly, or Claude may lose track of
  your conventions."

  | Feature | When it loads | What loads | Context cost |
  | - | - | - | - |
  | **CLAUDE.md** | Session start | Full content | Every request |
  | **Output styles** | Session start, and again when you switch styles | The active style's full instructions; nothing for the Default style | Every request |
  | **Skills** | Session start + when used | Descriptions at start, full content when used | Low (descriptions every request)\* |
  | **MCP servers** | Session start | Tool names; full schemas on demand | Low until a tool is used |
  | **Code intelligence** | After file edits and on demand | Diagnostics after edits; symbol locations on lookup | Low; reduces file reads elsewhere |
  | **Subagents** | When spawned | Fresh context with specified skills, or the parent conversation for a fork | Isolated from main session |
  | **Hooks** | On trigger | Nothing (runs externally) | Zero, unless hook returns additional context |

  \*Setting `disable-model-invocation: true` in a skill's frontmatter keeps its description out of Claude's context.
  [features-overview › Understand context costs](https://code.claude.com/docs/en/features-overview#understand-context-costs)
  [features-overview › Context cost by feature](https://code.claude.com/docs/en/features-overview#context-cost-by-feature)
- Check: a proposal says what it adds to every request, and prefers the tool that loads only when needed.

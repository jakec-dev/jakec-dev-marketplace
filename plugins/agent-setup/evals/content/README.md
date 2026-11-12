# Content cases

These cases measure what a piece of Claude tool content does to Claude's work, not what the agent-setup plugin
does. Each case ships the content under test as a small plugin in its own `plugin/` directory and names it in
`plugins:`, so the with-arm runs with that content and the no-plugin baseline runs without it. Guidance cites them
for decisions about what to write down: whether a convention needs a tool at all, and what a process skill needs to
say.

Eval runs never load a project's `CLAUDE.md` or `.claude/rules/`, even ones a fixture writes, so an instruction that
stands in for an always-loaded rule is printed into Claude's context by the fixture plugin's `SessionStart` hook,
which puts it there at launch as such a rule would be. A path-scoped rule can't be measured this way.

- `new-repo-convention`: a component convention, given at session start, in a library with no components yet.
  `uses-parts` checks that the new component is built from compound parts.
- `mature-repo-convention`: the same convention and grader, in a library of six components that all take their
  content as props.
- `process-skill-unshown-steps`: a four-step add-feature skill, in a service fresh from a template with an example
  feature. `registers-routes` checks a step the example shows; `audits-feature` and `removes-example` check steps
  no code shows.

Results on Claude Code 2.1.322, default model, 5 runs per arm (with the content / without it):

| Case | Grader | With | Without |
| :- | :- | :- | :- |
| `new-repo-convention` | `uses-parts` | 5/5 | 0/5 |
| `mature-repo-convention` | `uses-parts` | 5/5 | 0/5 |
| `process-skill-unshown-steps` | `registers-routes` | 5/5 | 5/5 |
| `process-skill-unshown-steps` | `audits-feature` | 5/5 | 0/5 |
| `process-skill-unshown-steps` | `removes-example` | 5/5 | 0/5 |

Without the instruction, Claude copies whatever the code shows: no parts in either repository, since the mature
repository's components all take content props. With it, Claude follows the instruction even where every component
does the opposite. The skill changes only the steps the example feature doesn't show.

Run them from the plugin root:

```sh
claude plugin eval . --tag content --scaffold --allow-tools Write Edit
```

# component-conventions (eval fixture)

The plugin under test for this case. Eval runs never load a project's `CLAUDE.md` or `.claude/rules/`, so this
plugin's `SessionStart` hook prints `conventions.md` into Claude's context instead, which puts it there at launch
the way an always-loaded rule or `CLAUDE.md` does. The `new-repo-convention` and `mature-repo-convention` cases carry
identical copies of this plugin, so the instruction and its delivery match and only the repository differs.

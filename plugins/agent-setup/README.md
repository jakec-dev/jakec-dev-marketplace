# agent-setup

A Claude Code plugin that keeps a repository's Claude Code setup current as Claude Code changes.

A Claude Code setup is everything that shapes how Claude Code behaves in a repository: the instruction file
(`CLAUDE.md` or `AGENTS.md`), rules in `.claude/rules/`, skills, subagents, hooks and settings. Claude Code's
behaviour changes often, and a setup written carefully a month ago can describe behaviour that no longer exists.
`agent-setup` notices those changes, works out which parts of a repository's setup they affect, and proposes the
fix as a pull request for review.

## Status

In development. Three skills are ready to use; the rest of the setup, and the automatic updates, are still to come.

## Skills

| Skill | What it does |
| --- | --- |
| `/agent-setup:write-hook` | Writes, fixes or explains a hook, or says when another tool fits better |
| `/agent-setup:write-rule` | Writes, fixes or explains a rule in `.claude/rules/`, or says when another tool fits better |
| `/agent-setup:write-skill` | Writes, fixes or explains a skill or custom command, or says when another tool fits better |

Claude also uses each skill on its own when a request matches its description. Each reads the plugin's reference,
built from Claude Code's documentation, and its guidance on what makes a Claude tool good, before it writes
anything.

## Install

```text
/plugin marketplace add jakec-dev/jakec-dev-marketplace
/plugin install agent-setup@jakec-dev-marketplace
```

## Licence

[MIT](../../LICENSE).

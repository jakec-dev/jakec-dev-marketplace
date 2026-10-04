# agent-setup

A Claude Code plugin that keeps a repository's Claude Code setup current as Claude Code changes.

A Claude Code setup is everything that shapes how Claude Code behaves in a repository: the instruction file
(`CLAUDE.md` or `AGENTS.md`), rules in `.claude/rules/`, skills, subagents, hooks and settings. Claude Code's
behaviour changes often, and a setup written carefully a month ago can describe behaviour that no longer exists.
`agent-setup` notices those changes, works out which parts of a repository's setup they affect, and proposes the
fix as a pull request for review.

## Status

In development. The plugin installs but has no skills yet.

## Install

```text
/plugin marketplace add jakec-dev/jakec-dev-marketplace
/plugin install agent-setup@jakec-dev-marketplace
```

## Licence

[MIT](../../LICENSE).

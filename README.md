# jakec-dev-marketplace

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugins/install#add-a-marketplace): a catalogue of
plugins that Claude Code can install from this repository.

## Status

Early development. No plugin has been released yet, so the install steps below will not work until the first one is.

## Plugins

| Plugin | What it does | Status |
| --- | --- | --- |
| `agent-setup` | Keeps a repository's Claude Code setup current and healthy | In development |

A Claude Code setup is everything that shapes how Claude Code behaves in a repository: the instruction file
(`CLAUDE.md` or `AGENTS.md`), rules, skills, subagents, hooks and settings. `agent-setup` notices when Claude Code's
behaviour or guidance changes, works out which parts of a repository's setup are affected, and proposes the fix for
review. Each plugin has its own README with the detail.

## Install

Add the marketplace once, from a Claude Code session:

```text
/plugin marketplace add jakec-dev/jakec-dev-marketplace
```

Then install a plugin from it:

```text
/plugin install agent-setup@jakec-dev-marketplace
```

From your shell, `claude plugin marketplace add` and `claude plugin install` take the same arguments.

Plugins run code on your machine, including hooks that Claude Code starts automatically. Read a plugin's README and
source before you install it.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md). Please do not open a public issue.

## Licence

[MIT](LICENSE).

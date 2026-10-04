# jakec-dev-marketplace

A [Claude Code plugin marketplace](https://code.claude.com/docs/en/plugins/install#add-a-marketplace): a catalogue of
plugins that Claude Code can install from this repository.

## Status

Early development. The plugins install, but none is ready for use yet.

## Plugins

| Plugin | What it does | Status |
| --- | --- | --- |
| [`agent-setup`](plugins/agent-setup) | Keeps a repository's Claude Code setup current | In development |

Each plugin's README describes it in full.

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

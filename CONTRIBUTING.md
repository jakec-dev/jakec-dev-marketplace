# Contributing

Thank you for helping. This repository is a Claude Code plugin marketplace maintained by one person, so the process is
kept small and will grow as contributions show what it needs. Everyone taking part is expected to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## Reporting a bug or suggesting a change

Open an issue first. Say what you expected, what happened instead, and how to reproduce it, including your Claude
Code version (`claude --version`) and operating system.

For a security problem, do not open an issue. Follow [SECURITY.md](SECURITY.md) instead.

## Setting up

Install [lefthook](https://lefthook.dev/), [ShellCheck](https://www.shellcheck.net/) and
[shfmt](https://github.com/mvdan/sh), for example with `brew install lefthook shellcheck shfmt`, then run
`lefthook install` once in your clone. From then on, every commit has its message checked, and any shell script it
stages is linted with ShellCheck and formatted with shfmt.

## Commit messages

Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```text
type(scope)!: description

Optional body explaining what changed and why.

Closes #12
```

- `type` is one of `feat`, `fix`, `docs`, `refactor`, `test`, `build`, `ci`, `chore` and `revert`.
- `scope` is optional and is usually a plugin name, `marketplace`, `ci`, `deps` or `docs`.
- `!` marks a breaking change. Explain it in a `BREAKING CHANGE:` footer.
- The header is at most 72 characters and does not end with a full stop.
- Refer to an issue in the footer, as `Closes #12` or `Refs #12`, not in the header.

`scripts/check-commit-msg.sh` enforces these rules in the `commit-msg` hook.

## Branches

Name a branch `type/short-description`, using the same types as commits, for example `feat/write-skill` or
`fix/hook-timeout`.

## Pull requests

- For anything larger than a small fix, open an issue to agree the approach before you write the code.
- Keep each pull request to one change, and explain what it changes and why.
- Run `claude plugin validate --strict` on every plugin you changed, and say in the pull request that it passed.
- Shell scripts must run under `/bin/bash` 3.2, the version macOS ships, and must not assume Node.js is installed.
  Run a script's test suite under it with `BASH_UNDER_TEST=/bin/bash /bin/bash scripts/<name>.test.sh`.
- Follow `.editorconfig` for line endings, indentation and line length.

## Licence

By contributing, you agree that your contribution is licensed under the [MIT licence](LICENSE) that covers this
repository.

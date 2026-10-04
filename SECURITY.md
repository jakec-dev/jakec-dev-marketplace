# Security policy

The plugins in this marketplace run on developers' machines. Their hooks are shell scripts that Claude Code starts
automatically, so a flaw in one can affect every repository that installs it. Please report a suspected
vulnerability privately so it can be fixed before it is public.

## Reporting a vulnerability

Report it through GitHub's private vulnerability reporting: on the repository's Security tab, choose
[Report a vulnerability](https://github.com/jakec-dev/jakec-dev-marketplace/security/advisories/new). Only you and the
maintainer can see the report. Please do not open a public issue or pull request.

Include what you can of the following:

- the plugin and the version, tag or commit affected;
- what an attacker could do, and what they would need first;
- steps or a minimal repository that reproduces it.

You should get a first reply within seven days. Once a fix is released, the advisory is published with credit to
you, unless you would rather not be named.

## Supported versions

Only the latest release of each plugin receives security fixes. Pin to a release tag if you need a fixed version,
and move to the newest tag when a fix is announced.

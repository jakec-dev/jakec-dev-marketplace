# Credentials

Protecting credentials from sandboxed commands with `sandbox.credentials`: `deny`, masking, AWS re-signing and
plaintext injection.

## Contents

- Declaring credentials
- Scope and trust
- Masking requirements
- Environment variables
- Credential files
- AWS re-signing
- Plaintext injection
- Invalid entries in managed settings

## Declaring credentials

- `sandbox.credentials` declares credential files and environment variables to protect from sandboxed commands. Each entry names a file `path` or a variable `name` and a `mode`: `deny` hides the credential inside the sandbox, and `mask` replaces it with a placeholder, as Masking requirements describes. The type is an object with `files`, `envVars`, `allowPlaintextInject`, `awsPairs` and `sigv4`; the default is unset. [settings-reference › `sandbox.credentials`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials)
- There is no built-in credential deny list: Claude Code protects only the entries you list. [settings-reference › `sandbox.credentials`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials)
- The dedicated `credentials` block keeps credential rules grouped together and separate from general filesystem rules. [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials)
- `sandbox.credentials` affects sandboxed Bash commands only. To strip credentials from all subprocesses regardless of sandboxing, set `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`. [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials)
- Example: blocks reads of the AWS credentials file and the SSH directory and removes `GITHUB_TOKEN` and `NPM_TOKEN` from the environment of sandboxed commands. [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials)

```json
{
  "sandbox": {
    "enabled": true,
    "credentials": {
      "files": [
        { "path": "~/.aws/credentials", "mode": "deny" },
        { "path": "~/.ssh", "mode": "deny" }
      ],
      "envVars": [
        { "name": "GITHUB_TOKEN", "mode": "deny" },
        { "name": "NPM_TOKEN", "mode": "deny" }
      ]
    }
  }
}
```

- `sandbox.credentials.files` protects credential files or directories. With `"mode": "deny"`, Claude Code blocks reads of the path inside the sandbox, the same read block as `sandbox.filesystem.denyRead`. The type is an array of objects, each with `path` and a `mode` of `"deny"` or `"mask"`, plus the optional mask fields for files; the default is unset, so no credential files are protected. [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files)
- File paths use the same prefixes as the `sandbox.filesystem.*` settings. [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files)
- `sandbox.credentials.envVars` protects environment variables. With `"mode": "deny"`, Claude Code removes the variable from the environment of sandboxed commands. The type is an array of objects, each with `name` and a `mode` of `"deny"` or `"mask"`, plus the optional mask fields for environment variables; the default is unset. The `name` must start with a letter or underscore and contain only letters, digits and underscores. [settings-reference › `sandbox.credentials.envVars`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-envvars)
- Claude Code accepts but ignores the `mask` fields on a `deny` entry. [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files), [settings-reference › `sandbox.credentials.envVars`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-envvars)

## Scope and trust

- Claude Code merges the `files` and `envVars` arrays from every settings scope the session loads. A `deny` entry only ever narrows access, so any scope can add one, but no scope can remove one that another scope added. When the same variable appears with both modes, `deny` applies (takes precedence in any scope). [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials), [settings-reference › `sandbox.credentials.envVars`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-envvars)
- Scope of `sandbox.credentials`, `files` and `envVars` is any settings file, but Claude Code drops `mask` entries from project `.claude/settings.json` and local `.claude/settings.local.json`. It honors `mask` entries, `network.tlsTerminate`, `allowPlaintextInject`, `awsPairs` and `sigv4` only from user settings, managed settings and the `--settings` flag, because masking authorizes the proxy to send your real credential somewhere. [sandboxing › Mask credentials](https://code.claude.com/docs/en/sandboxing#mask-credentials), [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files)
- The settings reference gives a narrower Scope for some of these keys, `User or managed`, without the `--settings`
  flag: `allowPlaintextInject`, `awsPairs` and `sigv4`, with `network.tlsTerminate` likewise read from user or managed
  settings.
  [settings-reference › `sandbox.credentials.allowPlaintextInject`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-allowplaintextinject),
  [settings-reference › `sandbox.credentials.awsPairs`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-awspairs),
  [settings-reference › `sandbox.credentials.sigv4`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-sigv4),
  [settings-reference › `sandbox.network.tlsTerminate`](https://code.claude.com/docs/en/settings-reference#sandbox-network-tlsterminate)
- When you exclude project or local settings as a settings source, Claude Code applies none of their `credentials` entries. [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials)
- When you exclude user settings as a source, Claude Code still applies the `deny` entries in `~/.claude/settings.json` and keeps its file `mask` entries as restrictions that no longer authorize the proxy to substitute the real value, but drops its environment variable `mask` entries. [sandboxing › Protect credentials](https://code.claude.com/docs/en/sandboxing#protect-credentials)
- A valid `mask` entry doesn't lock the `filesystem.disabled` key, even when Claude Code falls back to `deny` for it at startup. List a path that can't be masked, such as a credential directory, as an explicit `deny` entry in managed settings, which locks the key. [sandboxing › Which settings can disable it](https://code.claude.com/docs/en/sandboxing#which-settings-can-disable-it)

## Masking requirements

- When you mask a credential, sandboxed commands see a per-session placeholder called the sentinel, and the sandbox proxy substitutes the real value on outbound requests to hosts you allow. A `deny` entry blocks the credential instead. [sandboxing › Mask credentials](https://code.claude.com/docs/en/sandboxing#mask-credentials)
- Masking requires TLS termination: set `network.tlsTerminate` so the proxy terminates TLS itself and sees the request contents. Without it, masking fails without exposing anything: the command still sees only the sentinel, but the sentinel reaches the server unchanged and authentication fails. To check for this misconfiguration, run `claude doctor` in your terminal and look for the `TLS termination is unavailable` warning. [sandboxing › Mask credentials](https://code.claude.com/docs/en/sandboxing#mask-credentials)
- Masking requires an allowed destination. The proxy injects only on connections the domain allowlist admits, so each `injectHosts` host must also be reachable through `network.allowedDomains`. For a `mask` entry with no `injectHosts`, the proxy substitutes the real value on requests to every host in `network.allowedDomains`. [sandboxing › Mask credentials](https://code.claude.com/docs/en/sandboxing#mask-credentials)
- `mask` substitution runs only through the sandbox proxy; for plain-HTTP test networks, set `allowPlaintextInject` instead. [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files)

## Environment variables

- To mask an environment variable, set `"mode": "mask"` on its `credentials.envVars` entry. The command and anything it logs never hold the real credential, but its requests still authenticate. Tools such as `gh` and `npm` keep authenticating without ever holding the real credential. [sandboxing › Mask environment variables](https://code.claude.com/docs/en/sandboxing#mask-environment-variables), [settings-reference › `sandbox.credentials.envVars`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-envvars)
- Example: `GH_TOKEN` is substituted only on requests to `api.github.com`, while `NPM_TOKEN` has no `injectHosts` and is substituted on requests to every host in `network.allowedDomains`. [sandboxing › Mask environment variables](https://code.claude.com/docs/en/sandboxing#mask-environment-variables)

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "tlsTerminate": {},
      "allowedDomains": ["*.github.com", "registry.npmjs.org"]
    },
    "credentials": {
      "envVars": [
        { "name": "GH_TOKEN", "mode": "mask", "injectHosts": ["api.github.com"] },
        { "name": "NPM_TOKEN", "mode": "mask" }
      ]
    }
  }
}
```

- The proxy matches each `injectHosts` entry against the connection's bare destination address, ignoring ports, so a bracketed, zone-ID or differently compressed IPv6 spelling never matches. `claude doctor` flags entries that can never match with the warning `Sandbox credential injectHosts entries can never match their destination`. [sandboxing › Mask environment variables](https://code.claude.com/docs/en/sandboxing#mask-environment-variables)
- A `mask` entry for an environment variable accepts these optional fields. Without `extract` or `decode`, Claude Code replaces the entire value with one sentinel. `extract` and `decode` can't be combined on the same entry. [settings-reference › Mask fields for environment variables](https://code.claude.com/docs/en/settings-reference#mask-fields-for-environment-variables)

| Field | Type | What it does |
| :- | :- | :- |
| `extract` | string, a regular expression with at least one capturing group | Mask only the text captured by group 1 of each match, such as the password inside a `DATABASE_URL` connection string, so the rest of the value stays parseable |
| `onExtractNoMatch` | `"warn"`, `"deny"`, or `"error"`; default `"warn"`. On an entry with `decode`, only `"warn"` is accepted | What happens when `extract` matches nothing. `warn` passes the variable through unmasked, `deny` unsets it inside the sandbox, and `error` stops sandbox setup until you fix the configuration |
| `decode` | the string `"jwt"` | Verify the whole value is a JWT and replace it with a structurally valid fake token, so code inside the sandbox that decodes the token keeps working; the proxy substitutes the whole real token on egress. A value that doesn't verify passes through unmasked with a warning |
| `maskClaims` | array of strings, at least one claim name; requires `decode` | Mask only the named top-level payload claims inside the decoded JWT and rebuild the token around the modified payload, so the other claims stay readable. When no named claim matches, the variable passes through unmasked with a warning |
| `injectHosts` | array of strings, each a host that [`sandbox.network.allowedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-alloweddomains) also admits | Narrow the hosts where the sandbox proxy substitutes the real value. When unset, the proxy substitutes it on requests to every host in `sandbox.network.allowedDomains`. Write an IPv6 destination as the bare compressed address, such as `"::1"`, not the bracketed form; see [IPv6 destinations in `injectHosts`](https://code.claude.com/docs/en/sandboxing#ipv6-destinations-in-injecthosts) |

- Example: masks only the password inside `DATABASE_URL`, unsets the variable if the pattern matches nothing, and masks a JWT in `SERVICE_JWT` while leaving every claim except `api_key` readable. [settings-reference › Mask fields for environment variables](https://code.claude.com/docs/en/settings-reference#mask-fields-for-environment-variables)

```json
{
  "sandbox": {
    "credentials": {
      "envVars": [
        {
          "name": "DATABASE_URL",
          "mode": "mask",
          "extract": "://[^:]+:([^@]+)@",
          "onExtractNoMatch": "deny"
        },
        {
          "name": "SERVICE_JWT",
          "mode": "mask",
          "decode": "jwt",
          "maskClaims": ["api_key"]
        }
      ]
    }
  }
}
```

## Credential files

- With `"mode": "mask"` on a `credentials.files` entry, what a sandboxed command sees depends on the platform. On Linux and WSL2, sandboxed commands read a sentinel copy of the file, and the proxy substitutes the real value on outbound requests to that entry's `injectHosts`. On macOS, sandboxed commands can't read the file at all: Claude Code builds no sentinel copy, so tools that authenticate with the file don't work inside the sandbox, the same effect as `deny`. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files), [settings-reference › `sandbox.credentials.files`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-files)
- On macOS, the read block for a masked file holds even when you disable filesystem isolation. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)
- `mask` applies to a single file, so list each credential file individually. Claude Code falls back to `deny` for a `mask` entry it can't mask safely: a directory path, a glob pattern, a file larger than 8 MiB, or a file that isn't UTF-8 text. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)
- Example: masks a GitHub token stored in `~/.config/gh/hosts.yml`. The `extract` pattern marks which part of the file is the secret, so on Linux and WSL2 `gh` still parses the rest of its config. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)

```json
{
  "sandbox": {
    "enabled": true,
    "network": {
      "tlsTerminate": {},
      "allowedDomains": ["*.github.com"]
    },
    "credentials": {
      "files": [
        {
          "path": "~/.config/gh/hosts.yml",
          "mode": "mask",
          "extract": "oauth_token:\\s*(\\S+)",
          "injectHosts": ["api.github.com"]
        }
      ]
    }
  }
}
```

- To confirm the mask is active, ask Claude to run `cat ~/.config/gh/hosts.yml` in a sandboxed command. On Linux and WSL2 the output shows a sentinel in place of the token, and on macOS the read fails. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)
- Without `extract` or `decode`, Claude Code replaces the entire file with one sentinel, which suits a file holding a single bare secret. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)
- When matching finds nothing to mask, the default `onExtractNoMatch` value, `warn`, skips the entry, so sandboxed commands can read the real file unmasked. The default suits credentials that may be legitimately absent. If the secret might be present but the pattern might miss it, use `deny`. On macOS, Claude Code applies `mask` entries as `deny` before the pattern runs whenever filesystem isolation is on, so the no-match outcomes take effect there only when filesystem isolation is off. [sandboxing › Mask credential files](https://code.claude.com/docs/en/sandboxing#mask-credential-files)
- A `mask` entry for a file accepts these optional fields. [settings-reference › Mask fields for files](https://code.claude.com/docs/en/settings-reference#mask-fields-for-files)

| Field | Type | What it does |
| :- | :- | :- |
| `extract` | string, a regular expression with at least one capturing group | Mask only the text captured by group 1 of each match, so the rest of the file stays parseable. With `decode` also set, Claude Code checks each capture as a possible JWT instead of replacing it outright |
| `onExtractNoMatch` | `"warn"`, `"deny"`, or `"error"`; default `"warn"` | What happens when `extract` or `decode` finds nothing to mask. `warn` leaves the file readable as-is inside the sandbox, `deny` makes it unreadable, and `error` stops sandbox setup until you fix the configuration. Claude Code treats `deny` as `error` when the read block wouldn't be enforced, because you [disable filesystem isolation](https://code.claude.com/docs/en/sandboxing#disable-filesystem-isolation) or a [`sandbox.filesystem.allowRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowread) entry re-opens the path |
| `decode` | the string `"jwt"` | Find JSON Web Tokens (JWTs) in the file, with a built-in pattern or with `extract` when set, verify each candidate, and replace it with a structurally valid fake token, so code inside the sandbox that decodes the token keeps working. When no candidate verifies, `onExtractNoMatch` governs the outcome |
| `maskClaims` | array of strings, at least one claim name; requires `decode` | Mask only the named top-level payload claims inside each verified JWT and rebuild the token around the modified payload, so the other claims stay readable. When no named claim matches, `onExtractNoMatch` governs the outcome |
| `maskDuplicates` | Boolean, default `false` | Also replace verbatim copies of each masked value elsewhere in the file, such as a secret pasted into a comment. Claude Code matches raw substrings, so reserve it for long, high-entropy secrets. Consulted only when `extract` or `decode` is set |
| `injectHosts` | array of strings, each a host that [`sandbox.network.allowedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-alloweddomains) also admits | Narrow the hosts where the sandbox proxy substitutes the real value. When unset, the proxy substitutes it on requests to every host in `sandbox.network.allowedDomains` |

- Example: masks only the `oauth_token` value in the `gh` hosts file, replaces every other copy of it in the file, makes the file unreadable if the pattern matches nothing, and substitutes the real token only on requests to `api.github.com`. [settings-reference › Mask fields for files](https://code.claude.com/docs/en/settings-reference#mask-fields-for-files)

```json
{
  "sandbox": {
    "credentials": {
      "files": [
        {
          "path": "~/.config/gh/hosts.yml",
          "mode": "mask",
          "extract": "oauth_token:\\s*(\\S+)",
          "maskDuplicates": true,
          "onExtractNoMatch": "deny",
          "injectHosts": ["api.github.com"]
        }
      ]
    }
  }
}
```

## AWS re-signing

- AWS requests carry SigV4 signatures over the request contents, so mask `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` together. The proxy detects a SigV4 request by the access key's sentinel and re-signs the request with the real values. If you mask only the secret, requests are signed with a placeholder the proxy can't detect, so they fail at AWS. [sandboxing › Re-sign AWS requests](https://code.claude.com/docs/en/sandboxing#re-sign-aws-requests)
- Claude Code links the conventional `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` variables into one credential automatically when you mask their whole values. [sandboxing › Re-sign AWS requests](https://code.claude.com/docs/en/sandboxing#re-sign-aws-requests)
- `sandbox.credentials.awsPairs` groups masked environment variables that form one AWS credential when your credential lives in variables with non-standard names; you need it only for other names. The type is an array of objects, each with `accessKeyIdVar`, `secretAccessKeyVar` and optionally `sessionTokenVar`, naming `sandbox.credentials.envVars` entries. The default is unset, so only the conventional trio is paired. [settings-reference › `sandbox.credentials.awsPairs`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-awspairs)
  This example shows only the `awsPairs` entry; the three variables it names must also be declared as `mask` entries
  in `sandbox.credentials.envVars`.

```json
{
  "sandbox": {
    "credentials": {
      "awsPairs": [
        {
          "accessKeyIdVar": "MY_KEY_ID",
          "secretAccessKeyVar": "MY_SECRET_KEY",
          "sessionTokenVar": "MY_SESSION_TOKEN"
        }
      ]
    }
  }
}
```

- Each variable named in `awsPairs` must be a whole-value `mask` entry in `sandbox.credentials.envVars`, without `extract` or `decode`, and can fill only one slot across all pairs. The proxy re-signs requests on the hosts listed in the access key ID entry's `injectHosts`. When `sessionTokenVar` is set, the proxy sends the real token as `x-amz-security-token` on re-signed requests. Naming any of the conventional variables in a pair replaces the automatic pairing. [settings-reference › `sandbox.credentials.awsPairs`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-awspairs)
- Streaming uploads, presigned URLs and SigV4A requests carry signatures the proxy can't recompute. When one of these requests is signed with a masked pair's placeholder, the proxy fails it rather than forward a broken signature. Requests signed with unmasked credentials aren't affected. [sandboxing › Re-sign AWS requests](https://code.claude.com/docs/en/sandboxing#re-sign-aws-requests)
- `sandbox.credentials.sigv4` chooses what the proxy does with those request forms: `streaming` for aws-chunked streaming uploads, `presigned` for presigned URLs and `sigv4a` for SigV4A asymmetric signatures. It applies only to requests signed with a masked pair's placeholder access key ID. The type is an object with `streaming`, `presigned` and `sigv4a`, each `"deny"` (the proxy fails the request) or `"passthrough"` (the proxy forwards the request signed with the masked placeholder, so the tool receives AWS's own rejection). The default is unset, so every form is `"deny"`. [settings-reference › `sandbox.credentials.sigv4`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-sigv4)

```json
{
  "sandbox": {
    "credentials": {
      "sigv4": {
        "streaming": "passthrough"
      }
    }
  }
}
```

## Plaintext injection

- `sandbox.credentials.allowPlaintextInject` is a Boolean, default `false`: `true` allows `mask` substitution on plain HTTP requests as well as TLS-terminated HTTPS; `false` allows it only on TLS-terminated HTTPS. On plain HTTP the upstream identity is unverified and the credential travels in cleartext, so leave it off outside trusted test networks. [settings-reference › `sandbox.credentials.allowPlaintextInject`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-allowplaintextinject)

```json
{
  "sandbox": {
    "credentials": {
      "allowPlaintextInject": true
    }
  }
}
```

## Invalid entries in managed settings

- When a managed `sandbox.credentials` entry fails validation, Claude Code keeps protecting the credential where it can. An entry in `files` or `envVars` that still has a valid `path` or `name` and a `mode` of `mask` or `deny`, such as one whose `extract` pattern has no capturing group, is degraded to `mode: "deny"` with a warning, so the credential stays blocked, not masked, until you fix the entry. [settings-reference › Invalid credential entries in managed settings](https://code.claude.com/docs/en/settings-reference#invalid-credential-entries-in-managed-settings)
- A degraded `files` entry pins `filesystem.disabled` like an explicit `deny` entry, and the warning notes that its read block isn't enforced if managed settings turn filesystem isolation off. [settings-reference › Invalid credential entries in managed settings](https://code.claude.com/docs/en/settings-reference#invalid-credential-entries-in-managed-settings)
- An entry with an unknown `mode` or an invalid `path` or `name` is stripped. Each case warns; whether an entry is degraded or stripped, the remaining valid entries are still enforced. [settings-reference › Invalid credential entries in managed settings](https://code.claude.com/docs/en/settings-reference#invalid-credential-entries-in-managed-settings)

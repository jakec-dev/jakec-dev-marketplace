# Managed settings

Delivering organisation-managed settings: files, MDM, server-managed settings, how sources combine, and checking a
policy.

## Contents

- Deploy a managed settings file
- Choose a delivery mechanism
- Where and when a policy applies
- Where each mechanism stores the policy
- Split a file-based policy across teams
- How managed sources combine
- Keys read from every admin source
- Login keys
- Compose every managed source
- Compute the policy with a helper program
- Parent settings from an embedding host
- WSL and the Windows policy chain
- Keys only a managed source can set
- Pin endpoints for `allowedProviders`
- Block sideloading
- Server-managed settings
- Fetch and caching
- Fail-closed startup
- Security approval dialogs
- Platform availability
- Check that a policy is in force
- What a developer can change
- Security considerations
- Dev containers

## Deploy a managed settings file

- Managed settings are the settings an organisation deploys to every developer's machine. Claude Code applies them above every other level, so no user, project, local or `--settings` value overrides them, apart from a few security-sensitive exceptions where a stricter value from a lower level still counts. [managed-settings › Deploy managed settings](https://code.claude.com/docs/en/managed-settings)
- A `managed-settings.json` file holds the keys to enforce, in the same JSON shape as `settings.json`. Each entry in the settings reference says whether a managed source can set it. This file blocks two file reads, turns off bypass mode, and makes Claude Code ignore permission rules from user, project, and local files and from `--allowedTools`. [managed-settings › Deploy a managed settings file](https://code.claude.com/docs/en/managed-settings#deploy-a-managed-settings-file)

  ```json managed-settings.json
  {
    "permissions": {
      "deny": [
        "Read(./.env)",
        "Read(./secrets/**)"
      ],
      "disableBypassPermissionsMode": "disable"
    },
    "allowManagedPermissionRulesOnly": true
  }
  ```

- Save the file as `managed-settings.json` in the system directory for the operating system. [managed-settings › Deploy a managed settings file](https://code.claude.com/docs/en/managed-settings#deploy-a-managed-settings-file)
  - **macOS**: `/Library/Application Support/ClaudeCode/managed-settings.json`
  - **Linux and WSL**: `/etc/claude-code/managed-settings.json`
  - **Windows**: `C:\Program Files\ClaudeCode\managed-settings.json`

## Choose a delivery mechanism

- A managed settings file is one of four ways to get managed settings onto a machine. Every mechanism carries the same policy keys as a `settings.json` file, so the settings reference applies to all of them. A few keys are tied to particular sources, and each entry's Scope line says which. [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)
  - **Delivery controls**: `policyHelper`, `wslInheritsWindowsSettings` and `managedSourcesBehavior`
  - **Gateway login keys**: `forceLoginGatewayUrl`, `gatewayInternalNetworks` and the `"gateway"` value of
    `forceLoginMethod`
- A managed settings file or an MDM profile applies one policy to everyone it reaches. To give one group of developers a different policy, deploy a different file or profile to that group; a self-hosted Claude apps gateway delivers managed settings per IdP group. [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)
- When more than one mechanism delivers a policy to the same machine, Claude Code by default uses one and ignores the others. [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)
- The MDM and file rows are together called endpoint-managed settings, because the policy is stored on the developer's device, as opposed to the server-managed row, where Claude Code fetches it. [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)

| Mechanism | How you deliver it | When Claude Code reads it | Use it when |
| :- | :- | :- | :- |
| [Server-managed settings](https://code.claude.com/docs/en/server-managed-settings) | In the claude.ai admin console, or on a self-hosted [Claude apps gateway](https://code.claude.com/docs/en/claude-apps-gateway) | Fetched at startup and polled hourly; see [changes that need approval](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies) | You want one place to change policy for a claude.ai organization without touching each machine |
| MDM or OS-level policy | As a macOS configuration profile or a Windows `HKLM` registry value, through Jamf, Intune, Group Policy, or a similar tool; see [where each mechanism stores the policy](https://code.claude.com/docs/en/managed-settings#where-each-mechanism-stores-the-policy) | Read at startup and checked for changes every 30 minutes | You already manage devices with MDM or Group Policy |
| File-based | As `managed-settings.json` in a system directory on each machine; see [where each mechanism stores the policy](https://code.claude.com/docs/en/managed-settings#where-each-mechanism-stores-the-policy) | Read at startup and reloaded when a file changes | Machines without MDM, Linux hosts, or images you build yourself |
| HKCU registry, Windows and WSL | As a Windows `HKCU` registry value; see [where each mechanism stores the policy](https://code.claude.com/docs/en/managed-settings#where-each-mechanism-stores-the-policy) | Read at startup and checked for changes every 30 minutes; Claude Code uses it only when [no admin document is present above it](https://code.claude.com/docs/en/managed-settings#present-admin-documents) and no [host-supplied parent settings](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy) supply a restrictive key | You can't write the machine-level `HKLM` key |

- Starter templates for Jamf, Iru, Intune and Group Policy are in the [MDM examples repository](https://github.com/anthropics/claude-code/tree/main/examples/mdm). For the HIPAA configuration, `settings-hipaa.json` and `README-hipaa.md` in the [settings examples repository](https://github.com/anthropics/claude-code/tree/main/examples/settings) give a fuller `managed-settings.json` with sandboxing, a network allowlist, credential protections and local data retention. [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)
- A Claude apps gateway's `cli` or `code` document is a complete `managed-settings.json` document that Claude Code applies at the managed tier, in place of server-managed settings. It therefore ignores the settings restricted to OS-level policy sources, such as `policyHelper` and `wslInheritsWindowsSettings`. [claude-apps-gateway-config › What goes in `cli`](https://code.claude.com/docs/en/claude-apps-gateway-config#what-goes-in-cli)
- Managed settings apply wherever Claude Code runs on this machine. They most commonly reach a developer through server-managed settings, MDM or OS-level policies and `managed-settings.json` files in a system directory. [settings › Check what your organization enforces](https://code.claude.com/docs/en/settings#check-what-your-organization-enforces)

## Where and when a policy applies

- On the developer's machine, the terminal and the VS Code and JetBrains extensions read all of the managed sources. [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)
- A cloud session in an Anthropic-hosted environment doesn't read a device's MDM profile or file, so policy for it has to come from server-managed settings. A session in a [self-hosted environment](https://code.claude.com/docs/en/self-hosted-environments) also reads the managed settings file in its runner image, by default only when server-managed settings deliver no policy key, apart from the keys Claude Code reads from every admin source. Claude Tag sessions run in cloud environments but don't receive server-managed settings; in a self-hosted environment they still read the managed settings file in the runner image. [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)
- Most changes reach a running session on the schedule in the delivery table, without a restart. Managed settings that arrive through MDM or from the claude.ai console reach a running session on a schedule rather than on save. [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies), [settings › When edits take effect](https://code.claude.com/docs/en/settings#when-edits-take-effect), [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
  - Changes to `forceRemoteSettingsRefresh`, `requiredMinimumVersion` and some user-editable keys take effect at the
    next session start. Some updates also apply only at the next launch, including OpenTelemetry exporter configuration,
    the `model` key, and the removal of a variable from the `env` block.
  - A new or changed `policyHelper` entry takes effect at the next launch.
- Apart from the updates that wait for the next launch, a server-managed change to a setting that needs approval, such as an `env` variable, waits for the developer to accept the dialog in an interactive session. In a session an IDE extension or the Agent SDK hosts, it applies for the current run. Other server-managed changes apply on the next poll. [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)
- A session left open for weeks can still lag a rollout. `requiredMinimumVersion` blocks an outdated binary from starting and doesn't end a session that's already running. [managed-settings › Where and when a policy applies](https://code.claude.com/docs/en/managed-settings#where-and-when-a-policy-applies)

## Where each mechanism stores the policy

- The keys are the same everywhere, but each mechanism stores them in a different place and shape.
  [managed-settings › Where each mechanism stores the policy](https://code.claude.com/docs/en/managed-settings#where-each-mechanism-stores-the-policy)

  - **Server-managed**: Anthropic's servers, or your gateway, hold the policy. Claude Code keeps a local cache that it
    applies at startup and replaces on each successful fetch.
  - **macOS configuration profile**: the `com.anthropic.claudecode` managed preferences domain. Use the same top-level
    keys as `managed-settings.json`, with nested settings as dictionaries and lists as plist arrays.
  - **Windows HKLM registry**: the JSON as a `REG_SZ` or `REG_EXPAND_SZ` value named `Settings` under
    `HKLM\SOFTWARE\Policies\ClaudeCode`.
  - **File-based**: `managed-settings.json`, an optional `managed-settings.d/` directory, and `managed-mcp.json` in the
    system directory. Claude Code doesn't read the legacy Windows path
    `C:\ProgramData\ClaudeCode\managed-settings.json`.
  - **Windows HKCU registry**: the same `Settings` value under `HKCU\SOFTWARE\Policies\ClaudeCode`.
  - You can deploy any of the files as a symbolic link, and Claude Code reads the file the link leads to. The policy
    still applies when the link leads outside the system directory or Claude Code can't confirm that it stays inside. A
    warning naming the file then appears in `/status` and `claude doctor`. To clear the warning, point the link at a
    target inside the system directory.

## Split a file-based policy across teams

- Where several teams own parts of one policy, put each part in its own file in `managed-settings.d/`, next to `managed-settings.json` in the same system directory. [managed-settings › Split a file-based policy across teams](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams)
- Claude Code merges `managed-settings.json` first, then every `*.json` file in the directory in alphabetical order. Name the files with numeric prefixes to control the order, such as `10-telemetry.json` and `20-security.json`. Claude Code ignores hidden files and files that don't end in `.json`. [managed-settings › Split a file-based policy across teams](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams)
- When two files set the same key, Claude Code combines them by these rules. [managed-settings › Split a file-based policy across teams](https://code.claude.com/docs/en/managed-settings#split-a-file-based-policy-across-teams)
  - **Single values**, such as `"model": "opus"` or `"cleanupPeriodDays": 7`: the later file's value replaces the
    earlier one.
  - **Lists**, such as `permissions.deny` or `sandbox.network.allowedDomains`: the two lists combine, with duplicates
    removed.
  - **Nested blocks**, such as `env` or `sandbox`: the two blocks merge key by key, and each key inside follows these
    same rules.
  - **`fallbackModel`**: the later chain replaces the earlier one whole.
  - **`extraKnownMarketplaces` and `managedMcpServers`**: a later entry with the same name replaces the earlier one
    whole.
  - **`modelPicker`**: the later lineup replaces the earlier one whole.

## How managed sources combine

- When an organisation delivers more than one managed source to the same machine, the `managedSourcesBehavior` key decides what Claude Code does with the others. [managed-settings › How Claude Code combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources)
  - **`"first-wins"`, the default**: Claude Code uses the highest-ranked source that delivers at least one policy key
    and ignores the rest rather than merging them, apart from the keys in Keys read from every admin source. Claude Code
    shows no warning for the sources it skips; `/status` names the source it used and the ones it skipped.
  - **`"merge"`**: Claude Code applies every admin source that delivers a policy key and combines them by kind of key:
    on most keys the higher-ranked source's value applies, lists union, and locks take the strictest value.
- **Policy key**: any settings key other than the two control keys, `wslInheritsWindowsSettings` and `managedSourcesBehavior`. A managed settings file or MDM policy that contains only those doesn't count, and Claude Code moves on to the next source. [managed-settings › How Claude Code combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources)
- **Admin source**: one of the first three sources below. The HKCU registry is user-writable and isn't one. [managed-settings › How Claude Code combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources)
- Claude Code checks the sources in this order, highest priority first. Both settings rank the sources the same way. [managed-settings › How Claude Code combines managed sources](https://code.claude.com/docs/en/managed-settings#how-claude-code-combines-managed-sources)
  1. Remote settings, delivered from claude.ai as server-managed settings or by a Claude apps gateway.
  2. MDM or OS-level policies: the macOS plist or the HKLM registry key.
  3. Managed settings files, `managed-settings.d/*.json` and `managed-settings.json` merged together.
  4. The HKCU registry, on Windows, and on WSL once the HKLM registry or the Windows managed settings file turns
     `wslInheritsWindowsSettings` on and the HKCU value also sets it. Claude Code reads it only when no admin document
     is present above it and no host-supplied parent settings supply a restrictive key.
- A document is present, so that Claude Code never applies the user-writable HKCU registry beneath it, when it sets any policy key to a value other than `null`, even a value Claude Code can't read, or when it is an HKLM value, managed settings file, or `managed-settings.d` directory that exists but can't be read. On WSL, `/etc/claude-code` is user-writable as well. [managed-settings › When an admin document counts as present](https://code.claude.com/docs/en/managed-settings#present-admin-documents)

## Keys read from every admin source

- Under the default `"first-wins"` setting, Claude Code reads most keys only from the selected source, and ignores a value in a lower-ranked source even when the selected source leaves that key unset. [managed-settings › Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source)
- A few keys work differently: Claude Code reads them from every admin source, so a lower-ranked MDM policy or managed settings file can still set them when the selected source doesn't. Claude Code leaves the user-writable HKCU registry out of that scan; when HKCU is the only source and no host supplies parent settings, HKCU applies like any selected source. [managed-settings › Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source)
- The cross-source keys include these. [managed-settings › Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source)
  - `sandbox.network.allowManagedDomainsOnly` and `sandbox.filesystem.allowManagedReadPathsOnly`: a `true` in any admin
    source turns the lock on. While a lock is on, Claude Code unions the allowlist it locks,
    `sandbox.network.allowedDomains` together with `WebFetch(domain:...)` allow rules, or
    `sandbox.filesystem.allowRead`, across every admin source. Without the lock, Claude Code treats the allowlist like
    any other key, so under `"first-wins"` an unselected admin source's allowlist is ignored.
  - `allowAllClaudeAiMcps`.
  - `allowManagedMcpServersOnly`: a `true` in any admin source turns the MCP allowlist lock on. While the lock is on,
    the managed `allowedMcpServers` list comes from the highest-ranked admin source that sets one. A server-managed list
    replaces a lower source's list rather than combining with it. If no admin source sets a list, every server that
    passes the denylist loads, unless parent settings supply a list. Without the lock, Claude Code reads
    `allowedMcpServers` from the managed source it applies, so under `"first-wins"` an unselected admin source's list is
    ignored.
  - `deniedMcpServers` and `disableClaudeAiConnectors`: an entry or a `true` in any admin source applies.
  - The sandbox binary paths `sandbox.bwrapPath` and `sandbox.socatPath`.
  - The sandbox `ripgrep` binary, `sandbox.ripgrep`.
  - `sandbox.filesystem.disabled` and `sandbox.network.strictAllowlist`.
  - `useAutoModeDuringPlan` and `syncClaudeAiPlugins`, where a `false` from any admin source turns the behavior off. A
    `false` in the developer's user or local settings turns it off too; each key can only deny.
  - `enableArtifact`, where a `false` from any admin source turns the Artifact tool off. A `false` in the developer's
    user, project, or local settings turns it off too, and no source turns it back on.
  - `maxEffortLevel`, where the lowest cap in any admin source applies. If a developer sets a lower cap in their own
    settings or with `--settings`, Claude Code applies that one; no source can raise the cap.
  - A commit-trailer opt-out in `attribution`, or in the deprecated `includeCoAuthoredBy`, from any tier.
  - `forceRemoteSettingsRefresh`.
  - `env`: merged per variable across admin sources; each variable comes from the highest-priority source that defines
    it, so lower sources fill in variables the higher ones leave unset.
- When an admin source sets `allowManagedMcpServersOnly` or an `allowedMcpServers` list and that value isn't the one in force, `/status` and `claude doctor` name that source and key. [managed-settings › Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source)

## Login keys

- On a machine with an MDM policy or managed settings file, Claude Code takes the login keys from that policy or file, even for a key remote settings also set. Settings from the claude.ai admin console are remote settings, so set login keys such as `forceLoginOrgUUID` in the MDM policy or file. [managed-settings › Which managed source supplies login keys](https://code.claude.com/docs/en/managed-settings#which-managed-source-supplies-login-keys)
- If a machine has both an MDM policy and a managed settings file, use the MDM policy. When that policy sets any policy key, Claude Code ignores login keys in the file, even under `managedSourcesBehavior: "merge"`. [managed-settings › Which managed source supplies login keys](https://code.claude.com/docs/en/managed-settings#which-managed-source-supplies-login-keys)
- `forceLoginOrgUUID` and `forceLoginMethod` set to `"claudeai"` or `"console"`: if the policy or file omits either key, the value in remote settings applies. [managed-settings › Which managed source supplies login keys](https://code.claude.com/docs/en/managed-settings#which-managed-source-supplies-login-keys)

## Compose every managed source

- To have Claude Code apply every admin source the organisation delivers, set `managedSourcesBehavior` to `"merge"` in the highest-ranked source you deploy. Claude Code reads the key only from the highest-ranked source that carries either the key or a policy key, so a lower source can't opt itself into merging with the source above it, and a machine that never receives server-managed settings needs the key in its MDM profile too. The user-writable HKCU registry never merges with another source. [managed-settings › Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)
- Under `"merge"`, Claude Code adds a lower source's list entries, such as `permissions.allow` rules and hooks, to the policy, so turn it on only when every source ranked below your highest one is under an administrator's control. [managed-settings › Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)
- A `managed-settings.json` file is the lowest-ranked admin source, so `"merge"` set there has no source below it to combine with. In server-managed settings, the key looks like `{ "managedSourcesBehavior": "merge" }`. [settings-reference › `managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior)
- Parent settings from an embedding host don't take part in the merge. [settings-reference › `managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior)

Under `"merge"`, Claude Code combines each key by its kind. This table gives the rule for each kind. The restriction allowlist, values-taken-whole and highest-source-only rows name every key they cover, and the other rows give examples. [settings-reference › `managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior)

| Kind of key | How Claude Code combines it | Keys |
| :- | :- | :- |
| Lists | Combines entries from every source | [`permissions.allow`](https://code.claude.com/docs/en/settings-reference#permissions-allow), [`sandbox.network.allowedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-alloweddomains), and other list keys |
| Locks | Applies the strictest value any source sets. When no source sets a strict value, applies a looser value only from the highest source | [`allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly), [`permissions.disableBypassPermissionsMode`](https://code.claude.com/docs/en/settings-reference#permissions-disablebypasspermissionsmode), and other boolean or enum locks |
| Restriction allowlists | Takes the list whole from the highest source that sets it, without adding entries from lower sources. When the highest source doesn't set one, takes it whole from the next source down | [`availableModels`](https://code.claude.com/docs/en/settings-reference#availablemodels), [`allowedMcpServers`](https://code.claude.com/docs/en/settings-reference#allowedmcpservers), [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders), [`strictKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#strictknownmarketplaces), [`allowedChannelPlugins`](https://code.claude.com/docs/en/settings-reference#allowedchannelplugins), and the [`fallbackModel`](https://code.claude.com/docs/en/settings-reference#fallbackmodel) chain |
| Values taken whole | Takes the value whole from the highest source that sets it, without combining entries or fields from lower sources. When the highest source doesn't set it, takes it whole from the next source down | [`sandbox.credentials.awsPairs`](https://code.claude.com/docs/en/settings-reference#sandbox-credentials-awspairs), [`sandbox.ripgrep`](https://code.claude.com/docs/en/settings-reference#sandbox-ripgrep) |
| Provided MCP servers | Combines the server names from every source. When two sources set the same name, applies the higher source's whole entry | [`managedMcpServers`](https://code.claude.com/docs/en/settings-reference#managedmcpservers) |
| Read from the highest-priority source only | Reads the key only from the highest-priority source that carries a policy key, so a lower source's value is ignored even when the highest source sets none | [`apiKeyHelper`](https://code.claude.com/docs/en/settings-reference#apikeyhelper), [`awsAuthRefresh`](https://code.claude.com/docs/en/settings-reference#awsauthrefresh), [`awsCredentialExport`](https://code.claude.com/docs/en/settings-reference#awscredentialexport), [`gcpAuthRefresh`](https://code.claude.com/docs/en/settings-reference#gcpauthrefresh), [`otelHeadersHelper`](https://code.claude.com/docs/en/settings-reference#otelheadershelper), `proxyAuthHelper`, [`parentSettingsBehavior`](https://code.claude.com/docs/en/settings-reference#parentsettingsbehavior), [`modelPicker`](https://code.claude.com/docs/en/settings-reference#modelpicker), [`policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper), [`permissions.defaultMode`](https://code.claude.com/docs/en/settings-reference#permissions-defaultmode) |
| `env` | [Merges per variable across admin sources](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source), under both `"first-wins"` and `"merge"` | [`env`](https://code.claude.com/docs/en/settings-reference#env) |
| Every other key | Takes the value from the highest source that sets it | [`cleanupPeriodDays`](https://code.claude.com/docs/en/settings-reference#cleanupperioddays), [`model`](https://code.claude.com/docs/en/settings-reference#model) |

- `deniedModels` also combines as a list, and `crossSessionInbound` and `availableModelsMatch` combine as locks. [managed-settings › Compose every managed source](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source)
- A few keys add a condition that the table doesn't show. [settings-reference › `managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior)
  - **`modelOverrides`**: pairs with `availableModels`. Claude Code takes `modelOverrides` from the highest source that
    sets it, unless a higher source sets `availableModels` without `modelOverrides`. In that case it ignores
    `modelOverrides` from every source.
  - **Gateway login keys** (`forceLoginGatewayUrl`, `gatewayInternalNetworks` and the `"gateway"` value of `forceLoginMethod`): Claude Code never reads any of them from server-managed settings, so a value there neither applies nor hides one set in an MDM policy or managed settings file. Among the admin sources on the machine, only the highest-ranked one that carries a policy key supplies them, whether or not server-managed settings are also present. [server-managed-settings › Per-key exceptions across managed sources](https://code.claude.com/docs/en/server-managed-settings#per-key-exceptions-across-managed-sources) says the same.
  - **`allowedProviders`**: after the table's rule, a list the machine's own admin sources set still limits the result,
    so a server-managed list can narrow what the machine allows but never widen it.

## Compute the policy with a helper program

- A `policyHelper` is an executable run to compute managed settings, so policy can derive from device posture, identity or a remote service instead of a static file. Claude Code runs it before it accepts the first prompt and treats the settings it emits as the managed settings for the session. The key's value is an object with `path`, `timeoutMs` and `refreshIntervalMs`, and it is unset by default, so no helper runs. [settings-reference › `policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper)
- Scope: Claude Code reads the key from the macOS plist, the Windows HKLM registry, or the managed settings file. It reads it from the highest-priority managed source that carries a policy key and runs the helper only when that source is one of those three; it ignores the key in server-managed settings, the HKCU registry and host-supplied parent settings. [settings-reference › `policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper)
- When server-managed settings deliver the policy at launch, they take precedence over the helper's source and the helper doesn't run. If a later settings fetch reports the server-managed settings removed, Claude Code runs the helper at that point rather than waiting for the next launch. Its output governs the rest of the session, and a run that fails ends the session with the same message as a failed startup run. [settings-reference › `policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper)
- This example runs the helper with a 5-second timeout and re-runs it every five minutes. [settings-reference › `policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper)

  ```json managed-settings.json
  {
    "policyHelper": {
      "path": "/usr/local/bin/claude-policy",
      "timeoutMs": 5000,
      "refreshIntervalMs": 300000
    }
  }
  ```

- `policyHelper.path` names the helper executable. It is required when `policyHelper` is set, with no default. It is a string holding an absolute path in normalized form, without `.` or `..` segments; on Windows, a drive-letter or UNC path that ends in `.exe`. Like `policyHelper`, it is read from the macOS plist, the Windows HKLM registry, or the managed settings file. [settings-reference › `policyHelper.path`](https://code.claude.com/docs/en/settings-reference#policyhelper-path)
- `policyHelper.timeoutMs` sets how long Claude Code waits for the helper before treating the run as failed. A timed-out run fails the same way as a non-zero exit, so at startup Claude Code refuses to start. It is an integer in milliseconds, minimum `1000`, default `10000`, read from the same three sources. [settings-reference › `policyHelper.timeoutMs`](https://code.claude.com/docs/en/settings-reference#policyhelper-timeoutms)
- `policyHelper.refreshIntervalMs` has Claude Code re-run the helper in the background on an interval so policy changes reach a running session. When a refresh succeeds, its output replaces the previous managed settings without a restart. It is an integer in milliseconds: `0` to disable refresh, otherwise at least `60000`. Unset by default, so Claude Code runs the helper once at startup. It is read from the same three sources. [settings-reference › `policyHelper.refreshIntervalMs`](https://code.claude.com/docs/en/settings-reference#policyhelper-refreshintervalms)
- Claude Code runs the helper with no arguments, sets `CLAUDE_CODE_VERSION` in its environment, and reads a JSON envelope from stdout, capped at 1 MiB. [settings-reference › Write the helper output](https://code.claude.com/docs/en/settings-reference#write-the-helper-output)
- Put the settings under a `managedSettings` key. A bare settings object with no `managedSettings` key parses with `managedSettings` undefined and applies nothing, and Claude Code reports no error. [settings-reference › Write the helper output](https://code.claude.com/docs/en/settings-reference#write-the-helper-output)

  ```json
  {
    "managedSettings": {
      "permissions": { "deny": ["Read(//etc/secrets/**)"] }
    }
  }
  ```

- When the helper emits `managedSettings`, that object becomes the only managed settings source for the run: Claude Code ignores the MDM, file and HKCU sources, reads the cross-source keys from the helper's output alone, and never merges parent settings. The startup `forceRemoteSettingsRefresh` check runs before the helper and reads any admin source. A helper that exits `0` with an envelope that omits `managedSettings` contributes no managed settings, and the other sources apply as usual. [settings-reference › Write the helper output](https://code.claude.com/docs/en/settings-reference#write-the-helper-output)
- A helper run fails when any of these holds. [settings-reference › Helper failures](https://code.claude.com/docs/en/settings-reference#helper-failures)
  - `path` breaks the rules in `policyHelper.path`.
  - No regular file is at `path`. Claude Code checks for the file before starting the helper, within the same
    `timeoutMs` budget, so an unresponsive network mount can cause the run to fail.
  - The helper exits non-zero, is still running when `timeoutMs` elapses, or doesn't start at all, for example because
    it isn't executable.
  - The helper writes more than 1 MiB to stdout or to stderr.
  - stdout isn't a single JSON object, or its `managedSettings` has a schema violation Claude Code can't repair.
- When the startup run fails, Claude Code prints the reason and refuses to start. After a non-zero exit, the reason includes the helper's stderr, or its stdout when stderr is empty. After a timeout, the reason names the `timeoutMs` limit and includes none of the helper's output. The refusal covers interactive sessions, `claude -p`, Agent SDK sessions, background sessions, and most subcommands. It is deliberate, so a helper that needs outage resilience should serve from its own cache and exit `0`. [settings-reference › Helper failures](https://code.claude.com/docs/en/settings-reference#helper-failures)
- When a background refresh fails, Claude Code keeps the last successful policy in effect, and `/status` shows the failing refresh with its reason until a refresh succeeds. Each refresh runs under the same `timeoutMs` and failure rules as the startup run. With `--debug`, Claude Code writes the helper's stderr from every run to the debug log. [settings-reference › Helper failures](https://code.claude.com/docs/en/settings-reference#helper-failures)
- Claude Code reports an invalid `policyHelper` value, such as a bare path string or a `timeoutMs` below its minimum, as a dropped entry and starts the session on the remaining managed settings without running a helper. To turn a helper off, remove the key from the source that sets it. [settings-reference › Helper failures](https://code.claude.com/docs/en/settings-reference#helper-failures)

## Parent settings from an embedding host

- When another application launches Claude Code, such as Claude Desktop, an IDE extension, or an Agent SDK app, that host can pass its own managed settings through the SDK `managedSettings` option. Claude Code calls these parent settings. By default it ignores them whenever an admin source is present: server-managed settings, an MDM or OS-level policy, or a managed settings file. [managed-settings › Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy)
- `parentSettingsBehavior` chooses whether Claude Code applies parent settings when an admin-deployed managed tier is also present. `"first-wins"` (the default) drops the host-supplied settings. `"merge"` applies them under the admin tier through a restrictive-only filter; set it when a host needs to pass its own restrictions to the sessions it launches. Claude Code reads the key from the highest-priority admin-controlled managed source only. [settings-reference › `parentSettingsBehavior`](https://code.claude.com/docs/en/settings-reference#parentsettingsbehavior)

  ```json managed-settings.json
  {
    "parentSettingsBehavior": "merge"
  }
  ```

- `parentSettingsBehavior` has no effect when no admin-deployed managed tier exists: the host's settings then apply as the only managed tier, still filtered to restrictive values. [settings-reference › `parentSettingsBehavior`](https://code.claude.com/docs/en/settings-reference#parentsettingsbehavior)
- Under `"merge"`, Claude Code keeps only the host's values that restrict what Claude can do, with one gap: unless the `allowManaged*Only` locks are also set, the host's permission allow rules and sandbox allowlists still apply. A `policyHelper` can turn parent merging off regardless of this key. [managed-settings › Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy)
- Once `parentSettingsBehavior: "merge"` is deployed, any host process that launches Claude Code can supply parent settings, not only Claude Desktop but also an Agent SDK application or an IDE extension. Claude Code filters them against an allowlist of restrictive keys, but some allowed keys can grant access rather than restrict it. The policy's deny and ask rules stay in force either way. [claude-apps-gateway › Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings)
- To keep parent settings as close to restriction-only as the filter supports, add all five `allowManaged*Only` locks (`allowManagedPermissionRulesOnly`, `allowManagedMcpServersOnly`, `allowManagedHooksOnly`, `sandbox.network.allowManagedDomainsOnly` and `sandbox.filesystem.allowManagedReadPathsOnly`), and the allowlists they govern, to the same sources as the merge opt-in. An OS policy, such as an HKLM registry policy or a managed-preferences plist, outranks the managed settings file, so deliver them through it instead of the file when one exists. [claude-apps-gateway › Deploy the locks](https://code.claude.com/docs/en/claude-apps-gateway#deploy-the-locks)
- The locks and their allowlists go in the same sources as the merge opt-in, as in this example. [claude-apps-gateway › Deploy the locks](https://code.claude.com/docs/en/claude-apps-gateway#deploy-the-locks)

  ```json
  {
    "parentSettingsBehavior": "merge",
    "allowManagedPermissionRulesOnly": true,
    "allowManagedMcpServersOnly": true,
    "allowManagedHooksOnly": true,
    "allowedMcpServers": [{ "serverUrl": "https://mcp.internal.example.com/*" }],
    "sandbox": {
      "network": {
        "allowManagedDomainsOnly": true,
        "allowedDomains": ["github.com", "*.npmjs.org"]
      },
      "filesystem": {
        "allowManagedReadPathsOnly": true,
        "denyRead": ["~/"],
        "allowRead": ["~/projects"]
      }
    }
  }
  ```

- The gateway's remote managed settings outrank the OS policy and file sources but reach only connected clients. Mirror the locks, the allowlists and the merge opt-in into the policy's [`cli` or `code` block](https://code.claude.com/docs/en/claude-apps-gateway-config#managed) and keep the managed settings file deployed, because machines that never connect get their policy from the file alone. [claude-apps-gateway › Deploy the locks](https://code.claude.com/docs/en/claude-apps-gateway#deploy-the-locks)
- Setting one lock doesn't restrict the others. [claude-apps-gateway › Lock behavior across sources](https://code.claude.com/docs/en/claude-apps-gateway#lock-behavior-across-sources)
- The hooks lock and `allowManagedPermissionRulesOnly`'s effect on the developer's own rules need the winning source by default; under the `managedSourcesBehavior` merge opt-in, Claude Code applies the strictest value any source sets for every lock. [claude-apps-gateway › Lock behavior across sources](https://code.claude.com/docs/en/claude-apps-gateway#lock-behavior-across-sources)
- When any admin source sets `allowManagedPermissionRulesOnly`, Claude Code drops parent-supplied permission allow rules and `additionalDirectories` as it reads them, even when a higher-priority source leaves the key unset. When parent settings apply, the key treats them as part of the managed tier: it drops their `allow` rules and `additionalDirectories`, and keeps their `deny` and `ask` rules except `Read` and `Edit` rules whose pattern starts with `!`. A host can't carve paths out of the managed rules with a `!` rule, whether or not you set this key. [managed-settings › Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
- Claude Code forwards parent-supplied `sandbox.credentials` entries in stripped form. [claude-apps-gateway › Restrict parent settings](https://code.claude.com/docs/en/claude-apps-gateway#restrict-parent-settings)
  - **`deny` entries**: forwarded with only their `path` or `name` and the mode.
  - **File entries with `mode: mask`**: forwarded sentinel-only, as a whole-file mask whose `injectHosts` is the empty
    list, so the proxy never substitutes the real value for a parent-supplied entry on any platform. All
    structured-masking fields are dropped too, so a parent-supplied extract pattern can't displace a stricter mask
    another source sets for the same path.
  - **`envVars` entries with `mode: mask`**: not forwarded. `deny` is the only restriction the parent channel can
    express through `envVars` entries.
  - **`awsPairs` and `sigv4`**: forwarded restriction-only. From `sigv4`, only `deny` values are kept, and a parent that
    defines a `sigv4` block at all pins all three request forms, `streaming`, `presigned` and `sigv4a`, to `deny`. An
    `awsPairs` pair is never forwarded in a form that can re-sign; a pair that names one of the conventional AWS
    variables is replaced by an inert entry that keeps the automatic pairing of `AWS_ACCESS_KEY_ID`,
    `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN` suppressed.
- These parent-supplied settings pass the filter even with all five locks set. [managed-settings › Let an embedding host add policy](https://code.claude.com/docs/en/managed-settings#let-an-embedding-host-add-policy), [claude-apps-gateway › Settings the locks don't cover](https://code.claude.com/docs/en/claude-apps-gateway#settings-the-locks-don’t-cover)
  - **`forceLoginOrgUUID`**: an org UUID in the managed settings Claude Code applies blocks the parent's value and is
    the one Claude Code enforces. Claude Code honors a parent-supplied value only when those managed settings don't set
    one. Gateway sign-in doesn't check this key.
  - **`allowedMcpServers`**: a list in the managed settings Claude Code applies blocks a parent-supplied one. The
    parent's list applies when no admin source sets one, and `allowManagedMcpServersOnly` doesn't block it, because the
    lock enforces whichever list wins as the managed value. Set `allowedMcpServers` in the winning source, next to the
    lock.
  - **`availableModels`**: the managed value blocks a parent-supplied list; the parent's list applies when the winning
    managed source doesn't set one. If the fleet restricts models, set `availableModels` in the winning source.
  - **`strictKnownMarketplaces`**: the managed list blocks a parent-supplied one; the parent's list applies when the
    winning managed source doesn't set one. If the fleet restricts marketplaces, set `strictKnownMarketplaces` in the
    winning source.
  - **`allowedProviders`**: a list in the selected managed source blocks a parent-supplied one, and under the
    `managedSourcesBehavior` `"merge"` opt-in a list in any admin source does. The parent's list applies when the
    winning managed source doesn't set one. If the fleet restricts which API providers developers can use, set
    `allowedProviders` in the winning source.
  - **`blockedMarketplaces`**: a parent-supplied blocklist applies in addition to any blocklist that a managed source
    sets, since a blocklist can only restrict further.
  - **`strictPluginOnlyCustomization`**: this key passes the filter regardless of any lock, and it makes Claude Code
    ignore the developer's own customization, including protective hooks. No lock blocks it.

## WSL and the Windows policy chain

- `wslInheritsWindowsSettings` has Claude Code on WSL read managed settings from the Windows policy chain, with HKLM and the Windows managed settings file taking priority over `/etc/claude-code` and HKCU below it. While the chain is on, Claude Code reads `/etc/claude-code` only when no Windows admin document is present in the HKLM registry value or the `C:\Program Files\ClaudeCode\` folder. Claude Code honors it only when set in the HKLM registry key or in a managed settings file or drop-in under `C:\Program Files\ClaudeCode\`, both of which require Windows admin to write. [settings-reference › `wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings)
- Its type is Boolean, default `false`: `false` has WSL read only `/etc/claude-code`. [settings-reference › `wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings)

  ```json managed-settings.json
  {
    "wslInheritsWindowsSettings": true
  }
  ```

- Once an admin source turns the chain on, HKCU policy joins it on WSL only when HKCU also sets the key to `true`. That copy doesn't turn the chain on by itself. A Windows source that contains only this key, set to `true` or `false`, doesn't count as a policy source, so a lower-priority source still supplies the policy. The key has no effect on native Windows. [settings-reference › `wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings)
- Claude Code reads `true` and `false` with or without quotes and reads `null` as removing the key. An admin-controlled Windows source that holds any other value counts as a present admin document with the chain turned on: neither `/etc/claude-code` nor HKCU applies, and a startup warning names the key. An HKLM value or Windows-folder file that exists but can't be read also keeps `/etc/claude-code` from applying whether or not the chain is on. [settings-reference › `wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings)

## Keys only a managed source can set

- Claude Code reads the keys in the table only from a managed source; placing them in user or project settings files has no effect. Most are locks: the value a lock governs, such as permission rules or `sandbox.network.allowedDomains`, is an ordinary key that any level can set, and the lock tells Claude Code to honor only the managed value. The table covers the permission, plugin and delivery controls; for any key not listed, the Scope column of the settings reference index says whether it's managed-only. [managed-settings › Keys only a managed source can set](https://code.claude.com/docs/en/managed-settings#keys-only-a-managed-source-can-set)

| Setting | Description |
| :- | :- |
| [`allowAllClaudeAiMcps`](https://code.claude.com/docs/en/settings-reference#allowallclaudeaimcps) | Load the claude.ai connectors Claude Code fetches itself alongside a deployed `managed-mcp.json` instead of suppressing them |
| [`allowedChannelPlugins`](https://code.claude.com/docs/en/settings-reference#allowedchannelplugins) | Allowlist of channel plugins that may push messages. Replaces the default Anthropic allowlist when set. Requires `channelsEnabled: true`. See [Restrict which channel plugins can run](https://code.claude.com/docs/en/channels#restrict-which-channel-plugins-can-run) |
| [`allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedhooksonly) | When `true`, restricts which hooks run; see [what runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly) for the full effect list |
| [`allowManagedMcpServersOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedmcpserversonly) | When `true`, only `allowedMcpServers` from managed settings are respected. `deniedMcpServers` still merges from all sources. See [Keys read from every admin source](https://code.claude.com/docs/en/managed-settings#keys-read-from-every-admin-source) for which managed sources can set it, and [Managed MCP configuration](https://code.claude.com/docs/en/managed-mcp) |
| [`allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly) | Makes managed settings the only settings source of permission rules. The entry lists every source it ignores |
| [`blockedMarketplaces`](https://code.claude.com/docs/en/settings-reference#blockedmarketplaces) | Blocklist of marketplace sources. Blocked sources are checked before downloading, so they never touch the filesystem. See [managed marketplace restrictions](https://code.claude.com/docs/en/plugins/org#restrict-what-users-can-install) |
| [`channelsEnabled`](https://code.claude.com/docs/en/settings-reference#channelsenabled) | Allow [channels](https://code.claude.com/docs/en/channels) for the organization. See [enterprise controls](https://code.claude.com/docs/en/channels#enterprise-controls) for the default on each plan |
| [`disableCommandPluginSources`](https://code.claude.com/docs/en/settings-reference#disablecommandpluginsources) | When `true`, blocks [`command` plugin sources](https://code.claude.com/docs/en/plugins/marketplace-reference#command-plugin-source) entirely, so the marketplace-declared command never runs. Also blocks marketplace [`headersHelper` commands](https://code.claude.com/docs/en/plugins/host-marketplace#authenticate-archive-downloads), except for a marketplace that managed settings themselves declare. When unset, follows `allowManagedHooksOnly` |
| [`disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags) | Reject the `--plugin-dir`, `--plugin-url`, `--agents`, and `--mcp-config` flags at startup. In cloud sessions, Claude Code instead starts the session and drops the server-delivered `--mcp-config` servers, apart from the exceptions its [reference entry](https://code.claude.com/docs/en/settings-reference#disablesideloadflags) lists |
| [`forceRemoteSettingsRefresh`](https://code.claude.com/docs/en/settings-reference#forceremotesettingsrefresh) | When `true`, blocks CLI startup until remote managed settings are freshly fetched and exits if the fetch fails. See [fail-closed enforcement](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup) |
| [`managedMcpServers`](https://code.claude.com/docs/en/settings-reference#managedmcpservers) | Remote MCP servers provided to every user alongside their own. It provides servers rather than locking anything down. See [Provide servers through managed settings](https://code.claude.com/docs/en/managed-mcp#provide-servers-through-managed-settings) |
| [`managedSourcesBehavior`](https://code.claude.com/docs/en/settings-reference#managedsourcesbehavior) | Whether Claude Code applies only the highest-priority managed source or [composes every one of them](https://code.claude.com/docs/en/managed-settings#compose-every-managed-source) |
| [`parentSettingsBehavior`](https://code.claude.com/docs/en/settings-reference#parentsettingsbehavior) | Whether host-supplied parent settings merge under the managed policy |
| [`pluginSuggestionMarketplaces`](https://code.claude.com/docs/en/settings-reference#pluginsuggestionmarketplaces) | Marketplaces whose plugins Claude Code may suggest to users in the terminal |
| [`pluginTrustMessage`](https://code.claude.com/docs/en/settings-reference#plugintrustmessage) | Custom message appended to the plugin trust warning shown before installation |
| [`policyHelper`](https://code.claude.com/docs/en/settings-reference#policyhelper) | Executable that computes managed settings at startup; see [Compute managed settings with a policy helper](https://code.claude.com/docs/en/settings-reference#policyhelper) |
| [`sandbox.filesystem.allowManagedReadPathsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowmanagedreadpathsonly) | When `true`, only `filesystem.allowRead` paths from managed settings are respected. `denyRead` still merges from all sources |
| [`sandbox.network.allowManagedDomainsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowmanageddomainsonly) | Honor only managed `allowedDomains` and `WebFetch(domain:...)` allow rules; block other domains without prompting |
| [`strictKnownMarketplaces`](https://code.claude.com/docs/en/settings-reference#strictknownmarketplaces) | Controls which plugin marketplace sources users can add and install plugins from. See [managed marketplace restrictions](https://code.claude.com/docs/en/plugins/org#restrict-what-users-can-install) |
| [`strictPluginOnlyCustomization`](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization) | Block skills, agents, hooks, and MCP servers from user and project sources; `true` locks all four, an array names which |
| [`wslInheritsWindowsSettings`](https://code.claude.com/docs/en/settings-reference#wslinheritswindowssettings) | When set in the HKLM registry or a file under `C:\Program Files\ClaudeCode`, have WSL read the Windows policy chain, and read `/etc/claude-code` only when [no Windows admin document is present](https://code.claude.com/docs/en/managed-settings#present-admin-documents); the entry gives the order |

## Pin endpoints for `allowedProviders`

- A pin is an endpoint variable's value set in a managed `env` block. When a session sends a provider's traffic somewhere other than that provider's own service, Claude Code admits it only if the session's value is the same as the pin. [settings-reference › Endpoints that need a pin in managed `env`](https://code.claude.com/docs/en/settings-reference#endpoints-that-need-a-pin-in-managed-env)
  - **`"customEndpoint"` sessions**: the variable that names the host, such as `ANTHROPIC_BASE_URL`.
  - **Amazon Bedrock**: the AWS SDK's `AWS_ENDPOINT_URL`, `AWS_ENDPOINT_URL_BEDROCK` and
    `AWS_ENDPOINT_URL_BEDROCK_RUNTIME` variables when they point outside Bedrock's own service. The session stays under
    `"bedrock"` rather than `"customEndpoint"`.
  - **A gateway sign-in's URL**: the session stays under `"gateway"`, and `forceLoginGatewayUrl` also counts as the pin.
- Which `env` blocks count as pins depends on where the list is set. If an administrator source on the machine sets a list, only the `env` blocks of the machine's own administrator sources count. If only server-managed settings set a list, an `env` value in those server-managed settings counts too. [settings-reference › Endpoints that need a pin in managed `env`](https://code.claude.com/docs/en/settings-reference#endpoints-that-need-a-pin-in-managed-env)
- The list doesn't judge a cloud provider's credential and tenancy variables or the network path, such as `HTTPS_PROXY` and certificate settings. Set those for the fleet in the managed `env` block. [settings-reference › Endpoints that need a pin in managed `env`](https://code.claude.com/docs/en/settings-reference#endpoints-that-need-a-pin-in-managed-env)

## Block sideloading

- `disableSideloadFlags` (Boolean, default `false`, Scope Managed) rejects the `--plugin-dir`, `--plugin-url`, `--agents` and `--mcp-config` CLI flags at startup, which users could otherwise pass to bypass `strictKnownMarketplaces` for a single run. [settings-reference › `disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags)
  - `true`: Claude Code rejects `--plugin-dir`, `--plugin-url`, `--agents` and `--mcp-config` at startup and exits with
    an error naming the flags. In cloud sessions, it instead starts the session and drops every server-delivered
    `--mcp-config` entry except in-process `type: "sdk"` entries and a Claude Tag session's Slack tools.
  - `false`: Claude Code accepts those flags.
- With `disableSideloadFlags`, Claude Code still accepts a `--mcp-config` whose servers are all in-process `type: "sdk"` entries, so the Agent SDK and VS Code extension keep working. Users can still add servers with `claude mcp add` or a `.mcp.json` file; for per-server control, set `allowedMcpServers` as well. [settings-reference › `disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags)
- `disableSideloadFlags` also rejects plugin folders from the `CLAUDE_CODE_PLUGIN_DIRS` environment variable: when the variable names a plugin folder, Claude Code exits at startup with an error that names the variable and says to unset it. [settings-reference › `disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags)
- In cloud sessions, Claude Code with `disableSideloadFlags` also ignores server-delivered mid-session MCP updates, the path behind cloud session configuration and SDK `setMcpServers()` calls that reach those sessions. In-process `type: "sdk"` entries and a Claude Tag session's Slack tools stay exempt there too. [settings-reference › `disableSideloadFlags`](https://code.claude.com/docs/en/settings-reference#disablesideloadflags)

## Server-managed settings

- Server-managed settings need a Claude for Teams or Claude for Enterprise plan, the Owner or Primary Owner role in the Claude organisation to view and edit the configuration, and network access to `api.anthropic.com`. [server-managed-settings › Requirements](https://code.claude.com/docs/en/server-managed-settings#requirements)
- Server-managed settings deliver configuration from Anthropic's servers. If devices are enrolled in an MDM or endpoint management solution, endpoint-managed settings provide stronger security guarantees because the settings file can be protected from user modification at the OS level. [server-managed-settings › Choose between server-managed and endpoint-managed settings](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings)
- To configure them, open **Organization settings > Claude Code > Managed settings** in the claude.ai console. In a Team or Enterprise organization, if the page says you don't have access, ask an Owner or Primary Owner to make the change. [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings)
- Add the configuration as JSON. All settings available in `settings.json` are supported except those restricted to OS-level policy delivery. This includes environment variables and managed-only settings like `allowManagedPermissionRulesOnly`. This example enforces a permission deny list, prevents users from bypassing permissions, and restricts permission rules to those defined in managed settings. [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings)

  ```json
  {
    "permissions": {
      "deny": [
        "Read(./.env)",
        "Read(./.env.*)",
        "Read(./secrets/**)"
      ],
      "disableBypassPermissionsMode": "disable"
    },
    "allowManagedPermissionRulesOnly": true
  }
  ```

- Claude Code clients receive saved settings on their next startup or hourly polling cycle. The editor checks the JSON against the published JSON schema for Claude Code settings. If it finds a problem in JSON that parses, it shows a warning and relabels the save button: **Update with errors** when settings are already saved, **Add with errors** when none are saved yet. That button still saves, because a schema warning doesn't block the save. [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings)
- The schema can lag behind the newest releases, so the editor can flag a key or value that the settings reference documents. Claude Code receives the keys and values you saved and runs its own validation when it loads them. [server-managed-settings › Configure server-managed settings](https://code.claude.com/docs/en/server-managed-settings#configure-server-managed-settings)
- To verify delivery, ask a user to restart Claude Code. If the configuration includes settings that trigger the security approval dialog, the user sees a prompt describing the managed settings the next time Claude Code fetches them: at the next start, or within an hour in a running interactive session. A user can also run `/permissions` to view their effective permission rules and so check that managed permission rules are active. [server-managed-settings › Verify settings delivery](https://code.claude.com/docs/en/server-managed-settings#verify-settings-delivery)
- To check the fetch outcome on a specific machine, have the user run `claude doctor` and read the `Managed settings (remote)` line. It reports one of four outcomes: the delivered settings loaded; the organisation has no server-managed settings configured; the fetch failed, with the cause and whether a cached policy still applies; or Claude Code skipped the fetch, with the reason. While the fetch is still in progress, the line reports that instead. In a running session, `/status` shows the same line after a failed fetch, and for some skipped-fetch causes, such as a third-party provider variable or a custom `ANTHROPIC_BASE_URL` exported in the user's shell. [server-managed-settings › Verify settings delivery](https://code.claude.com/docs/en/server-managed-settings#verify-settings-delivery)
- Restrict access to trusted personnel, as settings changes apply to all users in the organisation. [server-managed-settings › Access control](https://code.claude.com/docs/en/server-managed-settings#access-control)
- Server-managed settings from the claude.ai console apply uniformly to all users in the organisation; per-group configurations are not yet supported there. [server-managed-settings › Current limitations](https://code.claude.com/docs/en/server-managed-settings#current-limitations), [managed-settings › Choose a delivery mechanism](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism)
- You can't distribute a `managed-mcp.json` file through server-managed settings. Deliver the `allowedMcpServers` and `deniedMcpServers` policy keys there instead. Claude Code reads a `managed-mcp.json` deployed at its system path separately from the managed settings tier, so the file still applies when server-managed settings are in effect. [server-managed-settings › Current limitations](https://code.claude.com/docs/en/server-managed-settings#current-limitations)
- Settings restricted to OS-level policy sources, such as `wslInheritsWindowsSettings`, aren't honored in server-managed settings. Deploy them through MDM or a system `managed-settings.json` file instead. [server-managed-settings › Current limitations](https://code.claude.com/docs/en/server-managed-settings#current-limitations)
- If you clear the server-managed configuration in the admin console with the intent of falling back to an endpoint-managed plist or registry policy, cached settings persist on client machines until the next successful fetch. [server-managed-settings › Settings precedence](https://code.claude.com/docs/en/server-managed-settings#settings-precedence)
- For the `env` block, apart from the telemetry unit and routing variables paired with a credential key, an endpoint-managed `env` entry applies whenever the server-managed configuration leaves that variable unset, or while a cached server value for it is withheld pending server confirmation. [server-managed-settings › Per-key exceptions across managed sources](https://code.claude.com/docs/en/server-managed-settings#per-key-exceptions-across-managed-sources)
  - **Telemetry unit**: the `OTEL_EXPORTER_OTLP_*` exporter keys, the `OTEL_LOG_*` content-capture toggles,
    `OTEL_LOGS_EXPORTER`, and the beta tracing variables `ENABLE_BETA_TRACING_DETAILED` and `BETA_TRACING_ENDPOINT`
    follow the highest source that sets any of them as a unit. A source that delivers the `otelHeadersHelper` credential
    key claims the unit too, but lands these variables only when it is the selected source: a source that isn't selected
    but delivers the key contributes none of them and still blocks lower sources from filling them in. Either way, an
    exporter endpoint from one source can never pair with credentials from another.
  - **Credential-paired routing**: a source that pairs routing variables with a selected-source-only credential key,
    such as `apiKeyHelper` or `otelHeadersHelper`, contributes those routing variables only when it wins the slot.
- Audit log events for settings changes are available through the compliance API or audit log export; contact your Anthropic account team for access. Audit events include the type of action performed, the account and device that performed the action, and references to the previous and new values. [server-managed-settings › Audit logging](https://code.claude.com/docs/en/server-managed-settings#audit-logging)

## Fetch and caching

- Claude Code fetches settings from Anthropic's servers at startup and polls for updates hourly during active sessions. A client signed in through a Claude apps gateway fetches its settings from the gateway and waits for that fetch before the session starts, so the fetch behaviour in the lists below doesn't apply to it. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
- First launch without cached settings. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
  - When a developer signs in at startup, such as on a first run or after `/logout`, Claude Code waits up to five
    seconds for the fetch before it opens the session. When the policy arrives in time, Claude Code enforces it from the
    first screen and shows your `companyAnnouncements` on it. When the payload needs security approval, Claude Code ends
    the wait and applies the payload once the developer approves.
  - In any other startup, and when that five-second wait runs out, Claude Code opens the session while the fetch
    continues, so a brief window passes before the settings load and the restrictions take effect.
  - If the fetch fails, Claude Code continues without server-managed settings and warns in interactive sessions that no
    remote policy applies; endpoint-managed settings still apply. If a managed source sets `forceRemoteSettingsRefresh`,
    Claude Code exits instead.
- Subsequent launches with cached settings. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
  - Cached settings apply immediately at startup, except for the values in the bullets below and the environment
    variables that Claude Code withholds.
  - A cached `modelPricing` doesn't apply until the session's fetch confirms the payload. Until then, the cost figures
    developers see in `/usage` and the status line are at list price.
  - A cached `managedMcpServers` block doesn't apply until the session's fetch confirms the payload. Claude Code waits
    up to 30 seconds for that fetch before connecting MCP servers. If the fetch fails or times out, the session starts
    without the organisation's servers, `/status` says so, and they connect once a later fetch confirms them.
  - A cached `prependPlugins`, `appendPlugins` or `enabledPlugins` value can't remove the built-in guard, change its
    position, or turn it off until the session's fetch confirms the payload.
  - On a machine where an endpoint-managed source lists or enables plugins of its own, a plugin that only a cached list
    enables counts as the user's, not the organisation's, until the fetch confirms the payload.
  - Claude Code fetches fresh settings in the background.
  - If the startup fetch fails, Claude Code warns in interactive sessions that the cached policy is in effect.
  - Until a fetch succeeds, the values withheld at startup stay withheld.
- Claude Code withholds several categories of variables in the cached `env` block until the server confirms the payload for the session. This keeps a cached proxy, certificate authority, endpoint or credential value from redirecting, intercepting or re-authenticating the settings fetch that confirms the payload. The hardening applies only to the server-fetched settings cache: endpoint-managed settings deployed through MDM or `managed-settings.json` are unaffected. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
  - Proxy and TLS configuration, such as `HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS`, and the mTLS client certificate variables
    `CLAUDE_CODE_CLIENT_CERT` and `CLAUDE_CODE_CLIENT_KEY`.
  - API routing and provider selection, including `ANTHROPIC_BASE_URL`, the provider selection variables such as
    `CLAUDE_CODE_USE_BEDROCK` and `CLAUDE_CODE_USE_VERTEX`, and the provider endpoint URLs such as
    `ANTHROPIC_BEDROCK_BASE_URL`.
  - Authentication credentials, such as `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN` and `CLAUDE_CODE_OAUTH_TOKEN`.
  - The configuration-directory selector `CLAUDE_CONFIG_DIR`.
  - Credential-source and configuration-directory selectors: the Workload Identity Federation variables such as
    `ANTHROPIC_FEDERATION_RULE_ID` and `ANTHROPIC_IDENTITY_TOKEN`, the profile and configuration-directory selectors
    `ANTHROPIC_PROFILE` and `ANTHROPIC_CONFIG_DIR`, and the operating-system directory variables `HOME`,
    `XDG_CONFIG_HOME`, `APPDATA` and `USERPROFILE`.
- Claude Code reads the Workload Identity Federation variables and the `ANTHROPIC_PROFILE` and `ANTHROPIC_CONFIG_DIR` selectors only at startup, so a server-delivered value for them doesn't switch the session's credential source even after the fetch succeeds. To deliver those selectors, use endpoint-managed settings such as MDM or `managed-settings.json`. For `CLAUDE_CONFIG_DIR` and the operating-system directory variables, the withholding itself is the protection: the cached value stays out of the environment until the server confirms the payload. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
- Every other key in the cached `env` block applies at startup. Once the server confirms the payload, and you approve it if it needs security approval, the withheld variables apply for the rest of the session. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)
- If the organisation needs a proxy to reach `api.anthropic.com`, the withholding only affects the server-delivered `env` block itself: a proxy set in an endpoint-managed `env` block through MDM or `managed-settings.json`, in the shell environment, or in user settings reaches the settings fetch. The cached server-managed proxy value is withheld until the fetch confirms it, so the endpoint-managed value fills in per key and reaches the fetch itself. The first launch has no cache, so an endpoint-managed source, the shell environment, or user settings is still required for the initial fetch. [server-managed-settings › Fetch and caching behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior)

## Fail-closed startup

- By default, if the remote settings fetch fails at startup, the CLI continues with the settings cached from the last successful fetch, except for the values Claude Code withholds until a fetch succeeds. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)
- To stop clients from starting on cached or absent server-managed settings, set `forceRemoteSettingsRefresh: true` in the managed settings. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)

  ```json
  {
    "forceRemoteSettingsRefresh": true
  }
  ```

- A reply from Anthropic's API that the organisation has no server-managed settings counts as a successful fetch. [self-hosted-environments-configuration › Stop sessions that fail to fetch server-managed settings](https://code.claude.com/docs/en/self-hosted-environments-configuration#stop-sessions-that-fail-to-fetch-server-managed-settings)
- When this setting is active in a session that fetches server-managed settings, the CLI blocks at startup until remote settings are freshly fetched. If the fetch fails, the CLI exits rather than proceeding without the policy. This setting self-perpetuates: once delivered from the server, it is also cached locally so that subsequent startups enforce the same behavior even before the first successful fetch of a new session. A session that doesn't fetch server-managed settings starts without waiting. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)
- `forceRemoteSettingsRefresh` is Boolean, default `false`. Claude Code honors a `true` from any admin-controlled managed source, even one that isn't the highest-priority source. Set it when the environment can't accept even a brief window in which a session runs without its managed policy. When it is unset, Claude Code doesn't block startup on the fetch. [settings-reference › `forceRemoteSettingsRefresh`](https://code.claude.com/docs/en/settings-reference#forceremotesettingsrefresh)
- Set `forceRemoteSettingsRefresh` in an MDM profile or the managed settings file to enforce fail-closed startup before the first server payload arrives. [settings-reference › `forceRemoteSettingsRefresh`](https://code.claude.com/docs/en/settings-reference#forceremotesettingsrefresh)
- Clients signed in through a Claude apps gateway wait for the startup fetch whether or not you set this, and handle a failed fetch as follows. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)
  - If the gateway answers an attended interactive launch with a `401` and this setting is off, the gateway has ended
    that sign-in. Claude Code prints `Cloud gateway session expired — run /login to reconnect.` and opens the session
    signed out of the gateway until the user runs `/login`.
  - When the fetch fails in any other way, or in any other kind of launch except a `claude auth` subcommand, the client
    exits with an error.
- The settings fetch also sends a `Cache-Control: no-cache` header so intermediate HTTP proxies don't serve a stale response. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)
- Before enabling this setting, ensure network policies allow connectivity to `api.anthropic.com`. If that endpoint is unreachable, the CLI exits at startup and users cannot start Claude Code. The `claude auth` subcommands such as `claude auth login` are exempt from this check and from the gateway startup exit, so users can re-authenticate when expired credentials are the reason the settings fetch fails. [server-managed-settings › Enforce fail-closed startup](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup)

## Security approval dialogs

- Certain settings that could pose security risks require explicit user approval before Claude Code applies them in an interactive session. [server-managed-settings › Security approval dialogs](https://code.claude.com/docs/en/server-managed-settings#security-approval-dialogs)
  - **Shell command settings**: settings that execute shell commands, such as `apiKeyHelper`, `statusLine` and
    `otelHeadersHelper`.
  - **Sandbox binary settings**: `sandbox.bwrapPath`, `sandbox.socatPath` and `sandbox.ripgrep`. Each of these settings
    points at an executable, and Claude Code runs that executable.
  - **Sandbox network and isolation settings**: sandbox settings that let the sandbox proxy read, reroute or
    authenticate traffic, or that weaken the sandbox's isolation: `sandbox.network.tlsTerminate`,
    `sandbox.network.httpProxyPort`, `sandbox.network.socksProxyPort`, `sandbox.credentials`,
    `sandbox.allowAppleEvents`, `sandbox.allowNestedUserNamespaces`, `sandbox.enableWeakerNestedSandbox`,
    `sandbox.enableWeakerNetworkIsolation`, `sandbox.filesystem.disabled`, `sandbox.network.allowAllUnixSockets`,
    `sandbox.network.allowUnixSockets` and `sandbox.network.allowMachLookup`. A `sandbox.credentials` block that
    contains only `deny` rules doesn't need approval, since it restricts the sandbox without giving the proxy a
    credential.
  - **Custom environment variables**: delivered `env` variables that require the user's approval, such as proxy and
    base-URL variables.
  - **Hook configurations**: any hook definition.
- When these settings are present, users see a security dialog explaining what is being configured. Users must approve to proceed. If a user rejects the settings, Claude Code exits. [server-managed-settings › Security approval dialogs](https://code.claude.com/docs/en/server-managed-settings#security-approval-dialogs)
- Claude Code records your approval in your configuration directory, `~/.claude` unless you set `CLAUDE_CONFIG_DIR`. What it records depends on the credential the settings fetch uses. [server-managed-settings › Approval memory](https://code.claude.com/docs/en/server-managed-settings#approval-memory)
  - **A claude.ai login saved by `/login` or `claude auth login`, or the keyless Console sign-in**: one approval per
    organisation, held by the account that approved most recently.
  - **A Claude apps gateway sign-in**: one approval per gateway. If you sign out and back in to the same gateway, Claude
    Code doesn't show the dialog again while the settings that require approval are unchanged. It shows it again when
    those settings change, when you sign in to a different gateway, and when you accept a new certificate for the same
    gateway. Claude Code saves no approval for a loopback development gateway reached over plain HTTP, so the dialog
    appears again after each sign-in.
  - **Any other credential**, such as an API key or `CLAUDE_CODE_OAUTH_TOKEN`: one approval for the delivered settings,
    kept with the cached copy of the settings in that configuration directory. Claude Code shows the dialog again when
    the settings that require approval change, and after you run `/logout` or `claude auth logout`, either of which
    deletes the cached copy.
- An approval for `sandbox.credentials` or `sandbox.network.tlsTerminate` also covers the `sandbox.network.allowedDomains` entries in those same delivered settings, because both settings act on that allowlist. The dialog appears again when the administrator adds or removes one of those entries, even though `sandbox.network.allowedDomains` doesn't require approval on its own. [server-managed-settings › Approval memory](https://code.claude.com/docs/en/server-managed-settings#approval-memory)
- With a saved claude.ai login: if you sign out and back in, or switch to another organisation and later return, Claude Code doesn't show the dialog again while those settings are unchanged, unless another account approved them for that organisation in the same configuration directory in between. If you sign in to the same organisation with a different account, Claude Code shows the dialog again even when the settings are unchanged; that account's approval replaces the previous one, so when you switch back, Claude Code shows the dialog once more. [server-managed-settings › Approval memory](https://code.claude.com/docs/en/server-managed-settings#approval-memory)
- Claude Code can't always show the dialog. Each case says which settings apply when it can't and when you next see the dialog. [server-managed-settings › Approval memory](https://code.claude.com/docs/en/server-managed-settings#approval-memory)
  - **An interactive session that can't show the dialog**: Claude Code doesn't apply the delivered settings and keeps
    the last-approved settings. The dialog appears in the next session that can show it.
  - **`claude install` or `claude update`**: Claude Code doesn't show the dialog during either command. The command runs
    with the last-approved settings, and the dialog appears in your next interactive session. If Claude Code waits for
    the settings fetch at startup, such as with `forceRemoteSettingsRefresh` set or on a Claude apps gateway deployment,
    it shows the dialog during the command instead, and an install run from a pipe fails.
  - **A `claude plugin` command that prints to a terminal but can't read from the keyboard**: when Claude Code doesn't
    wait for the settings fetch at startup, the command doesn't apply the delivered settings. Without cached settings, a
    command that changes your plugins or marketplaces stops with an error. With cached settings, it runs with the
    last-approved settings. The dialog appears when you next run `claude` in a terminal. The command can't read from the
    keyboard when you pipe or redirect its input and, on macOS and Linux, it also can't open `/dev/tty`. If you pipe or
    redirect its output too, the run is non-interactive instead, and the delivered settings apply for that run only.
  - **An error closes the dialog before you answer**: Claude Code doesn't apply the delivered settings and keeps the
    last-approved settings. It shows the dialog again in the next session that can show it.
  - **A non-interactive run**, such as `claude -p`, an Agent SDK session, or a session in the VS Code extension's chat
    panel or the desktop app's Code tab: Claude Code can't show the dialog. When the delivered settings would require
    approval, they apply for that run only. Claude Code doesn't record the settings as approved or write them to the
    local cache, and the next interactive session shows the dialog. Until a user approves in an interactive session,
    each non-interactive run fetches the settings again at startup.
- Claude Code applies some delivered `env` variables without showing the dialog, including feature and command toggles; model selection and behavior settings, such as `ANTHROPIC_MODEL`, `DISABLE_PROMPT_CACHING` and `CLAUDE_CODE_EFFORT_LEVEL`; context window and compaction settings, such as `DISABLE_AUTO_COMPACT`, but not `CLAUDE_CODE_DISABLE_1M_CONTEXT`; terminal UI and accessibility options; and numeric limits, budgets and timeouts. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)
- Other delivered variables can require the user's approval before they take effect. In interactive sessions these always do, at any non-empty value: a proxy or base-URL variable, `OTEL_EXPORTER_OTLP_ENDPOINT` and `CLAUDE_CODE_DISABLE_1M_CONTEXT`. When a delivered variable needs approval, the dialog names it. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)
- Server-managed settings can set `OTEL_LOG_MANAGED_SETTINGS` without showing the security approval dialog, because the variable only adds your organisation's own redacted policy to an event your organisation already receives. [monitoring-usage › Managed settings resolved event](https://code.claude.com/docs/en/monitoring-usage#managed-settings-resolved-event)
- Claude Code decides whether four privacy toggles need approval by the delivered value rather than by the variable name: `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`, `DISABLE_ERROR_REPORTING`, `DISABLE_TELEMETRY` and `DO_NOT_TRACK`. A truthy value such as `1` or `true` only turns tracking, reporting or other nonessential traffic off, so Claude Code applies it without asking the user. For any other non-empty value, Claude Code shows the dialog. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)
- Claude Code also decides whether `API_FORCE_IDLE_TIMEOUT` needs approval by the delivered value: a truthy value only turns the body idle timeout on, so Claude Code applies it without asking the user. For any other non-empty value, Claude Code shows the dialog. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)
- Whether `ANTHROPIC_CUSTOM_HEADERS` needs approval depends on the delivered value. Headers that only tag requests, such as `Accept-Language`, apply without the dialog. A line that names a credential, an org or tenant selector, a routing or host override, or an API-behavior header, such as `Authorization`, `X-Api-Key`, `Host`, `anthropic-beta` or the `X-Amzn-Bedrock-*` headers, requires approval. A line also requires approval when its name isn't a valid HTTP header token or its value contains a character an HTTP header can't carry. The check matches words inside the header name, so `X-Client-Version`, which contains `client` and `version`, requires approval too. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)
- A falsy value such as `0` or `false` for `ENABLE_BETA_TRACING_DETAILED` or `OTEL_LOG_RAW_API_BODIES` applies without the dialog, because it only turns detailed tracing or raw API body capture off. Any other non-empty value for either variable requires approval. [server-managed-settings › Environment variables and the approval dialog](https://code.claude.com/docs/en/server-managed-settings#environment-variables-and-the-approval-dialog)

## Platform availability

- Server-managed settings require a direct connection to `api.anthropic.com`. Delivery also requires the session to authenticate with one of these credentials: a Team or Enterprise OAuth login; an OAuth token supplied through `CLAUDE_CODE_OAUTH_TOKEN`; a directly configured API key; or a `user_oauth` Anthropic profile, unless the profile sets a `base_url` other than the Anthropic API. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
- Neither keys returned by an `apiKeyHelper` script nor Workload Identity Federation credentials trigger the settings fetch. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
- A session receives the managed settings of the organisation that owns the credential it authenticates with. An API key from the Claude Console belongs to the Console organisation it was created in, which is a separate organisation from the claude.ai Team or Enterprise organisation, so settings configured in claude.ai Admin Settings don't reach a session that authenticates with that key, such as a CI job that uses the company's Console API key. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
  - **OAuth token**: generate a token with `claude setup-token`, authorize it for your Team or Enterprise organisation,
    and set it as `CLAUDE_CODE_OAUTH_TOKEN` in the job's environment. Remove any credential that takes precedence over
    the token from that environment, such as `ANTHROPIC_API_KEY`. This option doesn't apply to a job that runs with
    `--bare`, because bare mode doesn't read `CLAUDE_CODE_OAUTH_TOKEN`.
  - **Endpoint-managed settings**: deploy a managed settings file to the machine that runs the job.
- If you export a `CLAUDE_CODE_USE_*` provider variable or a non-default `ANTHROPIC_BASE_URL` in your shell, Claude Code skips the settings fetch for your sessions. `claude doctor` and `/status` report the skipped fetch and its cause. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
- You can't clear the export with a server-managed `env` block, because the block arrives through the fetch that the export prevents. An endpoint-managed `env` block doesn't restore the fetch either: Claude Code checks eligibility before it applies managed `env` blocks, so the endpoint-managed value changes the session's provider selection but the fetch stays skipped. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
- To restore server-managed delivery, remove the export from your shell, or set the variable to `""` in your user settings `env` block, which applies before the eligibility check. To enforce policy without relying on users to change their shells, deliver the settings through the endpoint-managed channel instead. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)
- Deployments on Amazon Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry can use one of the file-based or OS-level mechanisms instead of server-managed settings. The macOS plist and HKLM registry locations work with any provider and resist tampering because they require admin privileges to write. [admin-setup › Decide how settings reach devices](https://code.claude.com/docs/en/admin-setup#decide-how-settings-reach-devices)
- For Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry and Claude Platform on AWS deployments, a self-hosted Claude apps gateway provides the equivalent remote managed-settings delivery: gateway-signed-in clients fetch managed settings from the gateway instead of `api.anthropic.com`. The failure semantics differ at startup: a gateway client that can't reach the gateway exits with an error instead of falling back to cached settings, while the hourly background refresh is fail-open on both channels. [server-managed-settings › Platform availability](https://code.claude.com/docs/en/server-managed-settings#platform-availability)

## Check that a policy is in force

- When a developer reports that a policy isn't applying, or before pushing a rollout to the fleet, two commands on that machine answer it: `/status` shows which managed source Claude Code selected, and `claude doctor` lists what it dropped. [managed-settings › Check that a policy is in force](https://code.claude.com/docs/en/managed-settings#check-that-a-policy-is-in-force)
- Read the `Setting sources` line in `/status`. When a managed source is in effect, the line lists `Enterprise managed settings` with the source Claude Code selected in parentheses. [managed-settings › Read the source in /status](https://code.claude.com/docs/en/managed-settings#read-the-source-in-/status)
  - `(remote)`: server-managed settings from claude.ai or a gateway
  - `(plist)` or `(HKLM)`: an MDM or OS policy
  - `(file)`, `(drop-ins)` or `(file + drop-ins)`: `managed-settings.json`, the drop-in directory, or both
  - `(remote + file, merged)`, or another list ending in `, merged`: the organisation composes every managed source, and
    Claude Code merged the listed sources into the policy. A lower source can still supply `env` variables without
    appearing in the list.
  - `(HKCU)`: the user-writable registry fallback
  - `(parent process)`: an embedding host supplied restrictive settings
  - `(helper)`: a `policyHelper` configured by the selected MDM or file source
- When Claude Code found a managed source on the machine and didn't select it, a second line, `Skipped sources`, names each such source. Read it to distinguish a policy that never reached the machine from one that reached it and that a higher-priority source overrode. [managed-settings › Read the source in /status](https://code.claude.com/docs/en/managed-settings#read-the-source-in-/status)
- After deploying `allowedProviders` set to `["anthropic"]`, sign in with a Claude Enterprise account and run `/status` on a machine that has the settings. The `Setting sources` line lists `Enterprise managed settings` with the source in parentheses, such as `(file)`, and the `Allowed providers` line reads `Anthropic API (managed allowedProviders)`. If `Setting sources` doesn't list it, or the `Allowed providers` line is missing, use this section. [hipaa-setup › Deploy managed settings](https://code.claude.com/docs/en/hipaa-setup#deploy-managed-settings)
- If the `Setting sources` line is missing, Claude Code found no managed source that delivers a policy key. For a deployed managed settings file, check that it sits at the path for the OS and that it contains a policy key rather than only the control keys. A file that isn't valid JSON doesn't produce this state; Claude Code refuses to start instead. For server-managed settings, run `claude doctor`, which reports the fetch outcome. [managed-settings › Read the source in /status](https://code.claude.com/docs/en/managed-settings#read-the-source-in-/status)
- If the line names a source other than the one you deployed, a higher-priority source is present and Claude Code ignored yours, and `Skipped sources` lists it. [managed-settings › Read the source in /status](https://code.claude.com/docs/en/managed-settings#read-the-source-in-/status)
- To check whether the Remote Control and cloud-session organization settings reached a machine, run `claude doctor` there and read the `Organization policy` line, which says where Claude Code loaded the policy from or why it didn't load. In a running session, `/status` shows the same line when the policy didn't load. [managed-settings › Keys only a managed source can set](https://code.claude.com/docs/en/managed-settings#keys-only-a-managed-source-can-set)
- The `managed_settings_resolved` OpenTelemetry event, logged at session start, when the managed settings or the policy helper's state changes, and when Claude Code refuses to start or ends the session, shows machines running on an unexpected managed source, machines whose policy helper is failing, and, in its `error.type` attribute on refused events, the reason a machine refused to start. [monitoring-usage › Managed settings resolved event](https://code.claude.com/docs/en/monitoring-usage#managed-settings-resolved-event)
- For a managed settings file with invalid entries, Claude Code keeps enforcing the rest of the file. [settings › Fix a broken settings file](https://code.claude.com/docs/en/settings#fix-a-broken-settings-file), [errors › Managed settings document could not be parsed](https://code.claude.com/docs/en/errors#managed-settings-document-could-not-be-parsed)

## What a developer can change

- A developer's own settings files, `--settings` values and project files never override a managed value; the
  exceptions only let a stricter lower-level value count. These cases sit outside that rule.
  [managed-settings › What a developer can change](https://code.claude.com/docs/en/managed-settings#what-a-developer-can-change)

  - **The model for a session**: a managed `model` is a default, not a lock. `--model` and `ANTHROPIC_MODEL` still pick
    the model for that session, so deploy `availableModels` to restrict the choice.
  - **The auto-compact window for a session**: a managed `autoCompactWindow` is a default too. The `--autocompact` flag
    and the `CLAUDE_CODE_AUTO_COMPACT_WINDOW` variable still set the auto-compact window for that session.
  - **Local admin rights**: a developer who is an administrator on the machine can edit the managed source itself, which
    is why MDM tooling can redeploy the profile or file on a schedule and why the HKLM registry and the macOS managed
    preferences domain exist.
  - **The server-managed cache**: server-managed settings come from Anthropic's servers, and an edit to the local cache
    lasts only until the next successful fetch.
  - **Other tools**: managed settings bind Claude Code only. A developer who calls the API from another tool isn't under
    them.

## Security considerations

- Server-managed settings provide centralised policy enforcement, but they operate as a client-side control, not a security boundary. On unmanaged devices, a user doesn't need admin or sudo access to bypass them. [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)
- The documentation lists these scenarios. [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)

| Scenario | Behavior |
| :- | :- |
| User edits the cached settings file | Tampered file applies at startup, except for the [values Claude Code withholds](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior) until the server confirms the payload. The next server fetch restores the correct settings, except for the [keys that apply only at the next launch](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior), such as `model` or a variable added to the `env` block, which stay in effect until relaunch |
| User deletes the cached settings file | [First-launch behavior](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior) occurs |
| User runs a modified Claude Code binary | A user who can run a modified client can bypass any client-side control |
| User runs an older Claude Code version | Versions that predate server-managed settings don't fetch or apply them |
| API is unavailable | Cached settings apply if available, except for the [values Claude Code withholds](https://code.claude.com/docs/en/server-managed-settings#fetch-and-caching-behavior) until a fetch succeeds. Without a cache, Claude Code enforces no server-managed settings until the next successful fetch and still applies any [endpoint-managed settings](https://code.claude.com/docs/en/managed-settings#choose-a-delivery-mechanism) on the device. With `forceRemoteSettingsRefresh: true`, the CLI exits instead of continuing, except for [`claude auth` subcommands](https://code.claude.com/docs/en/server-managed-settings#enforce-fail-closed-startup). Clients signed in through a [Claude apps gateway](https://code.claude.com/docs/en/server-managed-settings#platform-availability) exit at startup without that setting, with the same `claude auth` exemption |
| User authenticates with a different organization | Settings are not delivered for accounts outside the managed organization, including a session that authenticates with a [Console API key](https://code.claude.com/docs/en/server-managed-settings#platform-availability) |
| User configures a [third-party model provider](https://code.claude.com/docs/en/server-managed-settings#platform-availability) | Server-managed settings are bypassed. This includes setting `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_MANTLE`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`, `CLAUDE_CODE_USE_ANTHROPIC_AWS`, or a non-default `ANTHROPIC_BASE_URL` |
| Network traffic is intercepted or redirected | Disabled TLS validation or intercepted traffic can alter the settings the client receives |

- To restrict which organisations users can access with credentials the client supplies, see [Enforce network-level access control with Tenant Restrictions](https://support.claude.com/en/articles/13198485-enforce-network-level-access-control-with-tenant-restrictions) in the Claude Help Center. [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)

## Dev containers

- In a dev container, Claude Code applies a `managed-settings.json` in the Linux system directory at the highest precedence in the settings hierarchy, so values there override anything an engineer sets in `~/.claude` or the project's `.claude/` directory. Copy the file into place from the Dockerfile. [devcontainer › Enforce organization policy](https://code.claude.com/docs/en/devcontainer#enforce-organization-policy)

  ```dockerfile
  RUN mkdir -p /etc/claude-code
  COPY managed-settings.json /etc/claude-code/managed-settings.json
  ```

- Because the Dockerfile lives in the repository, anyone with write access can change or remove this step. For policy that engineers cannot bypass by editing repository files, deliver managed settings through server-managed settings or MDM instead. [devcontainer › Enforce organization policy](https://code.claude.com/docs/en/devcontainer#enforce-organization-policy)




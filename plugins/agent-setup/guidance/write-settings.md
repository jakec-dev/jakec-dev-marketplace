# Writing settings

Choosing the permission mode, permission rules, the sandbox and other isolation, and what to enforce through managed
settings.

These sections draw on Claude Code's permission modes, sandbox environments, sandboxing, dev container and auto mode
configuration pages, with the best practices and security pages for which control fits a rule, and the admin setup,
server-managed settings and HIPAA setup pages for what an organisation enforces.

## Contents

- The permission mode matches the goal
- bypassPermissions runs only inside a container, a VM or the sandbox runtime
- Isolation matches what the run is exposed to
- A container or sandbox runtime keeps secrets out and writes narrow
- A sandbox relied on as a control runs in strict mode and doesn't fall back
- A sandbox relied on as a control keeps its exceptions narrow
- Routine auto mode blocks are taught to the classifier, not approved each time
- Frequent read-only prompts in Manual mode go on an allowlist
- A permission rule lives in the scope of the people it applies to
- Sensitive repositories have project-specific permission settings
- Organisation policy uses the managed control that covers it
- Managed policy that must hold comes from an OS-protected source
- Required isolation is enforced, not only committed
- HIPAA-ready organisations using Claude Code (local mode) start managed settings from the recommended sample

## The permission mode matches the goal

- "Permission modes decide whether Claude asks before an action, and the Bash sandbox and outer isolation boundaries
  decide what an action can reach once it runs. Each row below pairs a goal with the flags or settings that get you
  there and the isolation it needs, as a starting point."

  | You want to | Start with | Isolation needed | Notes |
  | :- | :- | :- | :- |
  | Review every action yourself | Manual mode: `claude --permission-mode default` | None | Sensitive work, unfamiliar code |
  | Iterate locally with fewer prompts, without a classifier | Manual mode plus the Bash sandbox in [auto-allow mode](https://code.claude.com/docs/en/sandboxing#sandbox-modes): `claude --permission-mode default`, then run `/sandbox` and select auto-allow | The built-in Bash sandbox, on macOS, Linux, and WSL2 | Deny rules still apply, and ask rules that name a command, such as `Bash(git push *)`, still prompt. [Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode) covers other commands that can prompt. To turn the sandbox on from a settings file instead, set [`sandbox.enabled`](https://code.claude.com/docs/en/settings-reference#sandbox-enabled) to `true` |
  | Explore before changing anything | `claude --permission-mode plan` | None | Claude Code blocks edits until you [approve a plan](https://code.claude.com/docs/en/permission-modes#review-and-approve-a-plan) |
  | Work hands-off in auto mode | `claude --permission-mode auto`, the [built-in starting permission mode](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in) | None; a sandbox or container adds defense in depth | Requires a [supported model](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode), and your organization can [turn auto mode off](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) |
  | Run in CI with an exact allowlist | `claude -p "run the test suite" --permission-mode dontAsk --allowedTools "Bash(npm test)" "Read"` | None beyond what your CI runner provides | [Cloud sessions](https://code.claude.com/docs/en/claude-code-on-the-web) ignore `dontAsk` from settings files |
  | Run fully unattended inside a container | `claude -p "<prompt>" --dangerously-skip-permissions` | Required: a container, VM, or the [sandbox runtime](https://code.claude.com/docs/en/sandbox-environments#sandbox-runtime); on Linux and macOS, run it as a [non-root user](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) | Cloud sessions ignore this mode from settings files. In this `-p` run, the [few calls that would still prompt](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) are denied instead |

  "The Bash sandbox and auto mode work independently and combine, with the exceptions listed under Sandbox modes."
  [permission-modes › Common setups](https://code.claude.com/docs/en/permission-modes#common-setups)
- The Available modes table gives what runs without a prompt in each mode, and what each is best for. Manual mode
  appears under its config value, `default`.

  | Mode | What runs without asking | Best for |
  | :- | :- | :- |
  | `default` | Reads only | Reviewing every action yourself, sensitive work |
  | `acceptEdits` | Reads, file edits, and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`, etc.) | Iterating on code you're reviewing |
  | `plan` | Reads, plus classifier-approved commands when auto mode is available | Exploring a codebase before changing it |
  | `auto` | Everything, with background safety checks | Long tasks, reducing prompt fatigue |
  | `dontAsk` | File reads inside your working directories and pre-approved tools; anything that would prompt is denied, though a [mod](https://code.claude.com/docs/en/plugins/mods/overview) you installed can still approve some of those calls | Locked-down CI and scripts |
  | `bypassPermissions` | Everything | Isolated containers and VMs only |

  [permission-modes › Available modes](https://code.claude.com/docs/en/permission-modes#available-modes)
- A new terminal session takes its permission mode from the first of these that applies: the `--permission-mode`
  flag or `--dangerously-skip-permissions`, then `permissions.defaultMode` in a settings file, then the built-in
  default. If you set `"auto"` in `.claude/settings.json` or `.claude/settings.local.json`, the value doesn't take
  effect and Claude Code uses the built-in default rather than a `defaultMode` from `~/.claude/settings.json`; if you
  set `"bypassPermissions"` in those two files, it doesn't take effect either and the session starts in Manual mode.
  The other values apply from any settings file.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- Check: does the mode a session starts in, by flag, an effective `defaultMode` or the built-in default, match the
  Common setups row or the Available modes "Best for" entry for its goal?

## bypassPermissions runs only inside a container, a VM or the sandbox runtime

- "Always run `--dangerously-skip-permissions` sessions inside a container, a VM, or the sandbox runtime, so that file
  tools, MCP servers, and hooks are also inside the boundary. On Linux and macOS, Claude Code refuses to start with
  this flag when running as root, so run the container, VM, or sandbox runtime as a non-root user."
  [sandbox-environments › How isolation relates to permission modes](https://code.claude.com/docs/en/sandbox-environments#how-isolation-relates-to-permission-modes)
- permission-modes adds that the refusal also covers `sudo`, and that "The check is skipped automatically inside a
  recognized sandbox."
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- On where the mode is safe, two pages say different things. permission-modes warns: "Only use this mode in isolated
  environments like containers, VMs, or dev containers without internet access, where Claude Code cannot damage your
  host system." The dev container page instead says to pair the flag with network egress restrictions, so that
  they limit what a bypassed session can reach.
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
  [devcontainer › Run without permission prompts](https://code.claude.com/docs/en/devcontainer#run-without-permission-prompts)
- "`bypassPermissions` offers no protection against prompt injection or unintended actions. For background safety
  checks with far fewer permission prompts, use auto mode instead."
  [permission-modes › Skip all checks with bypassPermissions mode](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode)
- `bypassPermissions` "approves everything your deny and ask rules don't cover, which only makes sense in a disposable
  container."
  [best-practices › Change the permission mode](https://code.claude.com/docs/en/best-practices#change-the-permission-mode)
- The example dev container has a default-deny iptables firewall; "Because the firewall blocks unapproved egress, a
  configuration like this supports running Claude Code with `--dangerously-skip-permissions` for unattended work."
  [sandbox-environments › Dev containers](https://code.claude.com/docs/en/sandbox-environments#dev-containers)
- "When executed with `--dangerously-skip-permissions`, dev containers do not prevent a malicious project from
  exfiltrating anything accessible inside the container, including the Claude Code credentials stored in
  `~/.claude`. Only use dev containers when developing with trusted repositories, and monitor Claude's activities."
  [devcontainer › Development containers](https://code.claude.com/docs/en/devcontainer#page-title)
- In a dev container, "Skipping permission prompts removes your opportunity to review tool calls before they run.
  Claude can still modify any file in the bind-mounted workspace, which appears directly on your host, and reach
  anything the container's network policy allows." The reference container's firewall script and its
  `NET_ADMIN` and `NET_RAW` capabilities "are not required for Claude Code itself: you can leave them out and rely on
  your own network controls instead."
  [devcontainer › Run without permission prompts](https://code.claude.com/docs/en/devcontainer#run-without-permission-prompts)
  [devcontainer › Restrict network egress](https://code.claude.com/docs/en/devcontainer#restrict-network-egress)
- Check: does every use of `--dangerously-skip-permissions` or `bypassPermissions` run inside a container, a VM or the
  sandbox runtime, with network egress restricted or blocked, on Linux and macOS as a non-root user, and in a dev
  container only for a trusted repository?

## Isolation matches what the run is exposed to

- Isolating Claude Code "limits what a session can read, write, and reach on the network. This matters most when you
  let Claude work with fewer permission prompts, run it unattended, or point it at code you do not fully trust."
  [sandbox-environments › Choose a sandbox environment](https://code.claude.com/docs/en/sandbox-environments#page-title)
- "Match your goal to a row below, then read the detail section that follows."

  | You want to | Start with |
  | :- | :- |
  | Reduce permission prompts during everyday work on your own machine | The [sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing), configured with `/sandbox` |
  | Let Claude work unattended with `--dangerously-skip-permissions` or auto mode | The preconfigured [dev container](https://code.claude.com/docs/en/devcontainer), any container or VM, or the [sandbox runtime](https://code.claude.com/docs/en/sandbox-environments#sandbox-runtime) |
  | Isolate MCP servers and hooks as well as Bash, without Docker | The sandbox runtime |
  | Work on an untrusted repository | A dedicated virtual machine, or a [cloud session](https://code.claude.com/docs/en/claude-code-on-the-web) if you have a Claude subscription; GitHub is not required when you launch with `claude --cloud` |
  | Standardize a sandboxed environment across a team | The preconfigured [dev container](https://code.claude.com/docs/en/devcontainer), copied into your repository |
  | Require isolation for every developer in your organization | [Enforce isolation across an organization](https://code.claude.com/docs/en/sandbox-environments#enforce-isolation-across-an-organization) |
  | Work on a native Windows host | A container or VM, or run the Bash sandbox inside WSL2 |

  [sandbox-environments › Choose an approach](https://code.claude.com/docs/en/sandbox-environments#choose-an-approach)
- Auto mode "replaces the prompt with a classifier that reviews actions. The classifier is a per-action control, not
  an isolation boundary, so an isolation boundary still adds defense in depth for unattended runs, and is not
  required the way it is for `--dangerously-skip-permissions`." The sandboxed Bash tool "on its own constrains only
  shell commands, so it is not sufficient for fully unattended runs in either mode. You can layer approaches: running
  the sandboxed Bash tool inside a container or VM gives you OS-level command restrictions on top of the outer
  environment boundary."
  [sandbox-environments › How isolation relates to permission modes](https://code.claude.com/docs/en/sandbox-environments#how-isolation-relates-to-permission-modes)
- The sandboxed Bash tool isolates "Bash, PowerShell, and Monitor tool commands and their child processes"; "Built-in
  file tools, MCP servers, and hooks still run directly on your host. Every other approach in the table puts the whole
  Claude Code process inside the isolation boundary, so file tools, MCP servers, and hooks are restricted too."
  [sandbox-environments › Compare sandboxing approaches](https://code.claude.com/docs/en/sandbox-environments#compare-sandboxing-approaches)
- A virtual machine: "Use this approach when you are evaluating untrusted code, when your security policy requires
  kernel-level separation between the agent and the host, or when no host-level approach meets your compliance
  requirements."
  [sandbox-environments › Virtual machine](https://code.claude.com/docs/en/sandbox-environments#virtual-machine)
- For working with untrusted content: "Use virtual machines (VMs) to run scripts and make tool calls, especially when
  interacting with external web services".
  [security › Additional safeguards](https://code.claude.com/docs/en/security#additional-safeguards)
- For working with sensitive code: "For additional isolation, run the whole Claude Code (local mode) process inside
  the sandbox runtime or a dev container".
  [security › Working with sensitive code](https://code.claude.com/docs/en/security#working-with-sensitive-code)
- Check: does the isolation match the Choose an approach row for the goal, where one fits, with auto mode's row read as
  defence in depth rather than a requirement, and is an isolated, fully unattended run inside more than the sandboxed
  Bash tool?

## A container or sandbox runtime keeps secrets out and writes narrow

- "Sandbox isolation reduces the impact of a breach, but it does not eliminate risk. Any approach that allows network
  egress can still leak data the agent can read, and any approach that mounts your project directory writable can
  still modify that code." "Isolation also does not change what is sent to the model. Your prompts and the files
  Claude reads are transmitted to the Anthropic API or your configured provider with or without a sandbox."
  [sandbox-environments › Compare sandboxing approaches](https://code.claude.com/docs/en/sandbox-environments#compare-sandboxing-approaches)
- For a dev container: "Avoid mounting host secrets such as `~/.ssh` or cloud credential files into the container;
  prefer repository-scoped or short-lived tokens."
  [devcontainer › Development containers](https://code.claude.com/docs/en/devcontainer#page-title)
- For a custom container, "The same checklist applies as for any container you operate: review what is mounted
  writable, what credentials and tokens are reachable inside it, and what the network egress policy allows."
  [sandbox-environments › Custom container](https://code.claude.com/docs/en/sandbox-environments#custom-container)
- For the sandbox runtime, allow write access to at least your project directory, Claude Code's configuration paths
  `~/.claude` and `~/.claude.json`, and the directory where Claude Code writes runtime files, which unless you set
  `CLAUDE_CODE_TMPDIR` is `/tmp` on Linux and WSL2 and `/private/tmp` on macOS ("`/tmp` is a symlink to that
  directory, and Seatbelt checks the resolved path"). "On Linux and WSL2, the runtime applies write grants only to
  paths that already exist. In a fresh environment, create Claude Code's configuration paths before the first
  launch." Allow `api.anthropic.com` or your provider's endpoint; on a third-party provider keep `api.anthropic.com`
  as well, because the WebFetch domain safety check still calls it by default unless you set
  `skipWebFetchPreflight: true`. Allow `claude.ai` and `platform.claude.com`, which OAuth sign-in and token refresh
  require; "Runs authenticated with an API key can drop these two." Install the runtime "globally, under a prefix
  outside every path you allow writes to".
  [sandbox-environments › Set up and launch the runtime](https://code.claude.com/docs/en/sandbox-environments#set-up-and-launch-the-runtime)
- "`denyWrite` takes precedence over `allowWrite`."
  [sandbox-environments › What the runtime blocks on its own](https://code.claude.com/docs/en/sandbox-environments#what-the-runtime-blocks-on-its-own)
- If `~/.srt-settings.json` doesn't exist and you don't pass `--settings`, the runtime starts anyway, blocks network
  access and confines writes to built-in runtime paths: "Don't take a clean start as proof your settings loaded."
  "Your write grants still include other paths Claude Code loads configuration from, so deny those with `denyWrite`. A
  sandboxed session that can write them can persist hooks, permission rules, or MCP servers that run unsandboxed the
  next time you launch Claude Code."
  [sandbox-environments › What the runtime blocks on its own](https://code.claude.com/docs/en/sandbox-environments#what-the-runtime-blocks-on-its-own)
- "On Linux and WSL2, the runtime builds the deny list once at launch", and it "does not cover anything the session
  creates later, such as `git init`, `git clone`, or scaffolding."
  [sandbox-environments › What the runtime blocks on its own](https://code.claude.com/docs/en/sandbox-environments#what-the-runtime-blocks-on-its-own)
- After unattended runs, "Review the paths you kept writable. On Linux and WSL2, also review anything the session
  created."
  [sandbox-environments › After unattended runs](https://code.claude.com/docs/en/sandbox-environments#after-unattended-runs)
- Check: does a dev container mount no host secrets such as `~/.ssh` or cloud credential files, does a custom
  container's setup review its writable mounts, reachable credentials and egress policy, and does a sandbox runtime
  setup grant writes to at least the project directory, `~/.claude`, `~/.claude.json` and the runtime directory
  (`CLAUDE_CODE_TMPDIR`, else `/tmp` on Linux and WSL2 and `/private/tmp` on macOS), with those paths existing before
  launch on Linux and WSL2, allow `api.anthropic.com` or its provider's endpoint (both, on a third-party provider,
  unless `skipWebFetchPreflight` is `true`) and, unless it authenticates with an API key, `claude.ai` and
  `platform.claude.com`, deny writes to the other configuration paths its grants include, install the runtime outside
  every writable path, and review the writable paths after an unattended run?

## A sandbox relied on as a control runs in strict mode and doesn't fall back

- "By default Claude can still ask to retry a blocked command outside the sandbox, and that request goes through the
  normal permission flow. Strict sandbox mode, in the `/sandbox` **Overrides** tab, turns that retry off."
  [best-practices › Limit access with permission rules and the sandbox](https://code.claude.com/docs/en/best-practices#limit-access-with-permission-rules-and-the-sandbox)
- The documentation lists the sandbox in strict mode among the deterministic controls for what Claude can touch, with
  deny rules and managed settings; auto mode's classifier is the non-deterministic one.
  [best-practices › Deterministic and non-deterministic instructions](https://code.claude.com/docs/en/best-practices#deterministic-and-non-deterministic-instructions)
- Set `"allowUnsandboxedCommands": false` in your sandbox settings to disable the unsandboxed retry. "With the retry
  disabled, Claude Code ignores the `dangerouslyDisableSandbox` parameter. While the sandbox is running, commands
  Claude runs are then sandboxed unless they match an `excludedCommands` entry. To keep Claude Code from running
  commands unsandboxed when the sandbox can't start, also set `failIfUnavailable`."
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)
- Strict sandbox mode applies to the commands Claude runs. Commands you type yourself at the `!` shell-mode prompt run
  outside the sandbox unless the session is a background session (strict sandbox mode covers shell-mode commands too)
  or a Linux session with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` set (every command runs sandboxed).
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)
- "The sandbox doesn't run on native Windows, so with `failIfUnavailable` set, Claude Code exits at startup on those
  machines."
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- "A `false` in your user settings, `--settings`, or managed settings holds even when a project's settings set
  `true`."
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)
- Check: with `sandbox.enabled` `true`, is `allowUnsandboxedCommands` `false` in user, `--settings` or managed
  settings, with no `excludedCommands` entry for a command that must stay sandboxed, and, where it must not fall back
  to running unsandboxed, `failIfUnavailable` `true` on macOS, Linux and WSL2 hosts?

## A sandbox relied on as a control keeps its exceptions narrow

- "Allowing broad domains such as `github.com` can create paths for data exfiltration. Because the proxy makes its
  allow decision from the client-supplied hostname without inspecting TLS, code running inside the sandbox can
  potentially use domain fronting or similar techniques to reach hosts outside the allowlist. If your threat model
  requires stronger guarantees, configure a custom proxy that terminates TLS and inspects traffic, and install its CA
  certificate inside the sandbox."
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- The `allowUnixSockets` configuration "can inadvertently grant access to system services that could lead to sandbox
  bypasses. For example, allowing access to `/var/run/docker.sock` effectively grants access to the host system
  through the Docker socket."
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- "Allowing writes to directories containing executables in `$PATH`, system configuration directories, or user shell
  configuration files such as `.bashrc` or `.zshrc` can lead to code execution in different security contexts when
  other users or system processes access these files."
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- `enableWeakerNestedSandbox` "considerably weakens security and should only be used when additional isolation is
  otherwise enforced."
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- On macOS, `allowAppleEvents` "removes code-execution isolation: sandboxed commands can launch other applications
  unsandboxed with no user prompt". It is only honored from user, managed, or CLI settings. On Linux and WSL2, setting
  `allowNestedUserNamespaces` to `true` "turn[s] off a security boundary: code from a sandboxed command can end up
  running outside the sandbox."
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- "Effective sandboxing requires both filesystem and network isolation." When you widen the defaults, "check that an
  `allowWrite` path, a broad `allowedDomains` entry, or an `excludedCommands` exception does not undo a restriction on
  the other side."
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)
- Check: does the sandbox keep both filesystem and network isolation, with no `allowWrite` path, broad
  `allowedDomains` entry or `excludedCommands` exception that undoes a restriction on the other side, no broad domain,
  socket, `$PATH` or shell configuration write that the limitations name, and none of `enableWeakerNestedSandbox`,
  `allowAppleEvents` and `allowNestedUserNamespaces` set, except `enableWeakerNestedSandbox` where isolation is
  enforced outside the sandbox?

## Routine auto mode blocks are taught to the classifier, not approved each time

- "The opposite problem is the classifier repeatedly stopping something that's routine in your setup. Rather than
  approving it manually every time, add it to `autoMode.allow` or describe your trusted infrastructure in the auto
  mode configuration. It's plain English rather than patterns, and `/auto-mode-setup` can draft the `environment` part
  for you from your project and recent sessions":

  ```json
  {
    "autoMode": {
      "environment": [
        "$defaults",
        "Source control: github.com/example-org and every repo under it"
      ],
      "allow": [
        "$defaults",
        "Deploying to the staging namespace is fine, it's isolated from production and resets nightly"
      ]
    }
  }
  ```

  The example is a `~/.claude/settings.json`. "Keep `"$defaults"` in every list you set, because without it your
  entries *replace* that list's built-in rules instead of adding to them. For `environment` and `allow` you'd lose
  the built-in context and exceptions, and a `soft_deny` list without it drops the built-in blocks on force pushes and
  production deploys." "The `autoMode` block also has to live in
  `~/.claude/settings.json` rather than the project, because the classifier ignores `autoMode` in project settings."
  [best-practices › Change the permission mode](https://code.claude.com/docs/en/best-practices#change-the-permission-mode)
- For a call the classifier judged unsafe, shown as `Denied by auto mode classifier` with a reason, pick the fix from
  what the call was trying to reach or do: a destination Claude needs throughout the
  task, such as a package registry, an internal domain, or a repository host, goes in `autoMode.environment`; a
  command you want to run without review from now on is an `allow` rule; for a one-off action you did intend, state
  that intent in your next message and let Claude retry.
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)
- "For most organizations, `autoMode.environment` is the only field you need to set." A reasonable rollout: "start
  with the defaults and add your source control org and key internal services, which resolves the most common false
  positives like pushing to your own repos. Add trusted domains and cloud buckets next. Fill the rest as blocks come
  up."
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
- The classifier reads the same CLAUDE.md content Claude itself loads, so an instruction like "never force push" in a
  project's CLAUDE.md steers both. It reads `autoMode` from these scopes:

  | Scope | File | Use for |
  | :- | :- | :- |
  | One developer | `~/.claude/settings.json` | Personal trusted infrastructure |
  | Organization-wide | [Managed settings](https://code.claude.com/docs/en/server-managed-settings) | Trusted infrastructure distributed to all developers |
  | `--settings` flag or Agent SDK | Inline JSON | Per-invocation overrides for automation |

  "The classifier doesn't read `autoMode` from project settings in `.claude/settings.json` or
  `.claude/settings.local.json`", because a checked-in repo or a build step could otherwise inject its own allow rules.
  "Because allow rules act as exceptions to soft block rules inside the classifier, a developer-added `allow` entry can
  override an organization `soft_deny` entry: the combination is additive, not a hard policy boundary." For a
  never-rule see choose.md › Never-rules are deny rules or hooks, not auto mode.
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)
- "Only omit `"$defaults"` when you intend to take full ownership of the list. To do that safely, run `claude
  auto-mode defaults` to print the built-in rules, copy them into your settings file, then review each rule against
  your own pipeline and risk tolerance." "`hard_deny` rules block
  unconditionally. User intent and `allow` exceptions don't apply."
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- When you accept the `/auto-mode-setup` draft, Claude Code "writes the `environment` list without `"$defaults"`,
  because the draft spells out the built-in entries it left unchanged".
  [auto-mode-config › Review and save the draft](https://code.claude.com/docs/en/auto-mode-config#review-and-save-the-draft)
- Check: is a destination the classifier keeps blocking in `autoMode.environment` and a command to run without review
  in `autoMode.allow`, in `~/.claude/settings.json`, managed settings or a `--settings` file and not the project's
  settings files, with `"$defaults"` in each list unless the list spells out the built-in entries itself?

## Frequent read-only prompts in Manual mode go on an allowlist

- In Manual mode, "you approve every edit and every command that isn't read-only yourself. Safe, but after the tenth
  prompt you start approving without reading, and nothing moves while you're away from the keyboard." "if Manual then
  asks too often, `/fewer-permission-prompts` scans your recent transcripts for common read-only Bash and MCP calls and
  adds them to an allowlist in `.claude/settings.json`."
  [best-practices › Change the permission mode](https://code.claude.com/docs/en/best-practices#change-the-permission-mode)
- `/doctor` checks **Permissions**: "an offer to make auto mode your default permission mode and to pre-approve
  read-only commands that you frequently deny".
  [skills › Check your setup with /doctor](https://code.claude.com/docs/en/skills#check-your-setup-with-/doctor)
- Check: in Manual mode, are read-only commands that prompt often pre-approved on an allowlist rather than approved one
  at a time?

## A permission rule lives in the scope of the people it applies to

- "Where a rule lives decides who it applies to." `.claude/settings.local.json` and `~/.claude/settings.json` "are
  yours alone. When you select **Yes, and don't ask again** for a command, Claude Code saves that rule to the local
  file." `.claude/settings.json` belongs to the repo: "Once you commit them, they apply to everyone who works in the
  repo. Its deny rules apply right away. Its `allow` rules wait until each person accepts the trust dialog for that
  folder". Managed settings belong to the organisation, and "no personal settings file can override them, which makes
  them the only place for a security team's policy"; "Organisation policy uses the managed control that covers it"
  says which key.
  [best-practices › Choose who a rule applies to](https://code.claude.com/docs/en/best-practices#choose-who-a-rule-applies-to)
- `.claude/settings.local.json` "is normally your own file, so Claude Code applies its allow rules and additional
  directories without the trust step. When the file is tracked in git, or `.claude` is a symlink, Claude Code treats
  it as repository-supplied instead and holds its rules until you trust the folder." It runs git to tell the two apart
  only once you've trusted the folder or in a `-p` or SDK session; until then, outside your configuration home, it
  "holds the file's rules like project settings".
  [permissions › When your local settings file needs trust](https://code.claude.com/docs/en/permissions#when-your-local-settings-file-needs-trust)
- "Claude Code shows the trust dialog in interactive sessions only. A `claude -p` run or an SDK session never shows
  it", so in a folder never trusted, `permissions.allow` rules and `additionalDirectories` in `.claude/settings.json`
  are "Not used. Claude Code prints a `this workspace has not been trusted` warning to stderr".
  [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
  [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- "Share approved permission configurations through version control".
  [security › Team security](https://code.claude.com/docs/en/security#team-security)
- Check: is each permission rule in the file that matches who it is for: one person's in an untracked
  `.claude/settings.local.json` (not under a symlinked `.claude`) or `~/.claude/settings.json`, the team's committed in
  `.claude/settings.json`, with a security team's policy in managed settings, and are allow rules and
  `additionalDirectories` entries a `claude -p` run or SDK session needs in a folder never trusted not left only in the
  project's `.claude/settings.json`?

## Sensitive repositories have project-specific permission settings

- "Use project-specific permission settings for sensitive repositories".
  [security › Working with sensitive code](https://code.claude.com/docs/en/security#working-with-sensitive-code)
- Check: does a sensitive repository have project-specific permission settings?

## Organisation policy uses the managed control that covers it

- "Managed settings can lock down tools, sandbox execution, restrict MCP servers and plugin sources, and control which
  hooks run. Each row is a control surface with the setting keys that drive it."

  | Control | What it does | Key settings |
  | :- | :- | :- |
  | [Permission rules](https://code.claude.com/docs/en/permissions) | Allow, ask, or deny specific tools and commands | `permissions.allow`, `permissions.deny` |
  | [Permission lockdown](https://code.claude.com/docs/en/permissions#managed-only-settings) | Make managed settings the [only settings source of permission rules](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly). Disable `--dangerously-skip-permissions` | `allowManagedPermissionRulesOnly`, `permissions.disableBypassPermissionsMode` |
  | [Starting permission mode](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in) | Choose the permission mode your developers' terminal sessions start in instead of the built-in starting permission mode, or remove auto mode. [Switch permission modes](https://code.claude.com/docs/en/permission-modes#switch-permission-modes) lists when the VS Code extension reads a `defaultMode` you set | `permissions.defaultMode`, `permissions.disableAutoMode` |
  | [Sandboxing](https://code.claude.com/docs/en/sandboxing) | OS-level filesystem and network isolation with domain allowlists | `sandbox.enabled`, `sandbox.network.allowedDomains` |
  | [Customization lockdown](https://code.claude.com/docs/en/settings-reference#strictpluginonlycustomization) | Block skills, agents, hooks, and MCP servers from user and project sources, so they can only come from plugins or managed settings. Locking skills also stops the [skills your developers enable on claude.ai](https://code.claude.com/docs/en/skills#where-synced-skills-load) from syncing | `strictPluginOnlyCustomization` |
  | [Hook restrictions](https://code.claude.com/docs/en/settings-reference#allowmanagedhooksonly) | Restrict which hooks run and restrict HTTP hook URLs; see [what runs under `allowManagedHooksOnly`](https://code.claude.com/docs/en/settings-reference#what-runs-under-allowmanagedhooksonly) for the full effect list | `allowManagedHooksOnly`, `allowedHttpHookUrls` |

  [admin-setup › Decide what to enforce](https://code.claude.com/docs/en/admin-setup#decide-what-to-enforce)
- Check: is each permission, sandbox, hook or customisation requirement the organisation must enforce set in managed
  settings through the key the table names?

## Managed policy that must hold comes from an OS-protected source

- "If your devices are enrolled in an MDM or endpoint management solution, endpoint-managed settings provide stronger
  security guarantees because the settings file can be protected from user modification at the OS level.
  Endpoint-managed settings don't reach cloud sessions in Anthropic-hosted environments, so organizations whose
  developers run cloud sessions should configure server-managed settings as well."

  | Approach | Best for |
  | :- | :- |
  | **Server-managed settings** | Organizations without MDM, or users on unmanaged devices |
  | **[Endpoint-managed settings](https://code.claude.com/docs/en/managed-settings#delivery-mechanisms)** | Organizations with MDM or endpoint management |

  [server-managed-settings › Choose between server-managed and endpoint-managed settings](https://code.claude.com/docs/en/server-managed-settings#choose-between-server-managed-and-endpoint-managed-settings)
- "Server-managed settings provide centralized policy enforcement, but they operate as a client-side control, not a
  security boundary. On unmanaged devices, a user doesn't need admin or sudo access to bypass them." When a user
  configures a third-party model provider, "Server-managed settings are bypassed". "For stronger enforcement
  guarantees, use endpoint-managed settings on devices enrolled in an MDM solution."
  [server-managed-settings › Security considerations](https://code.claude.com/docs/en/server-managed-settings#security-considerations)
- "Delivery through the claude.ai admin console requires a Claude for Teams or Enterprise plan." Deployments on Amazon
  Bedrock, Google Cloud's Agent Platform, or Microsoft Foundry "can get the same remote delivery by running a Claude
  apps gateway, or use one of the file-based or OS-level mechanisms instead." "If your organization mixes providers,
  configure server-managed settings for claude.ai users plus a file-based or plist/registry fallback so other users
  still receive managed policy." "The plist and HKLM registry locations work with any provider and resist tampering
  because they require admin privileges to write. The Windows user registry at HKCU is writable without elevation, so
  treat it as a convenience default rather than an enforcement channel."
  [admin-setup › Decide how settings reach devices](https://code.claude.com/docs/en/admin-setup#decide-how-settings-reach-devices)
- In a dev container, a Dockerfile step can copy `managed-settings.json` into place, but "Because the Dockerfile lives
  in the repository, anyone with write access can change or remove this step. For policy that engineers cannot bypass
  by editing repository files, deliver managed settings through server-managed settings or your MDM instead."
  [devcontainer › Enforce organization policy](https://code.claude.com/docs/en/devcontainer#enforce-organization-policy)
- "On WSL, `/etc/claude-code` is user-writable as well."
  [managed-settings › When an admin document counts as present](https://code.claude.com/docs/en/managed-settings#present-admin-documents)
  "By default, WSL reads only the Linux file path at `/etc/claude-code`. To extend your Windows registry and
  `C:\Program Files\ClaudeCode` policy to WSL on the same machine, set `wslInheritsWindowsSettings: true` in either of
  those admin-only Windows sources."
  [admin-setup › Decide how settings reach devices](https://code.claude.com/docs/en/admin-setup#decide-how-settings-reach-devices)
- Check: is policy that must hold against developers delivered through MDM, the plist or HKLM registry, or a managed
  file the OS protects from user writes (on WSL, the Windows sources through `wslInheritsWindowsSettings`, not
  `/etc/claude-code`), not HKCU, a file a repository's Dockerfile installs, or, on devices enrolled in MDM,
  server-managed settings alone; and where developers run cloud sessions in Anthropic-hosted environments or the
  organisation mixes providers, is it in server-managed settings too, where the plan or a gateway allows?

## Required isolation is enforced, not only committed

- Dev containers: "commit the example dev container to your repositories to standardize the environment across a team.
  This is a convention rather than an enforcement boundary, because Claude Code does not require a container. If
  developers should not be able to run Claude Code outside it, enforce that with your organization's device
  management or software allowlisting tools." Custom containers and VMs: "distribute Claude Code through the approved
  image and use your organization's device management or software allowlisting tools to prevent installation outside
  it."
  [sandbox-environments › Enforce isolation across an organization](https://code.claude.com/docs/en/sandbox-environments#enforce-isolation-across-an-organization)
- "To require the sandbox for every developer, deliver the `sandbox` keys through managed settings, either as a file
  managed by your MDM or through server-managed settings on claude.ai." The documented managed configuration sets
  `sandbox.enabled` to `true` and the two keys covered under "A sandbox relied on as a control runs in strict mode and
  doesn't fall back". Consider these additions: `excludedCommands` for any organization-approved tools that must run
  without isolation, because this configuration stops a repository's settings from taking commands out of the sandbox;
  and `sandbox.credentials` entries for credential directories such as `~/.aws` and `~/.ssh` and for secret
  environment variables, since the default read policy still allows them.
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- That configuration makes the sandbox admin-required: "Add the `excludedCommands`, `allowWrite`, and socket entries
  that your approved tools need to managed settings, because a repository can't supply them." A repository's deny
  entries and `autoAllowBashIfSandboxed` value still apply: "Set the key in managed settings to keep a repository from
  changing it."
  [sandboxing › Repository settings under an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
- If your fleet includes Windows hosts, you can deliver the configuration by operating system, through your MDM or as a
  managed settings file on macOS and Linux machines only (server-managed settings apply to all users in the
  organization); or move Windows users into a supported environment by having them run Claude Code inside WSL2 or a
  container.
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- "When managed settings set a Boolean key such as `enabled` or `failIfUnavailable`, Claude Code uses the managed value
  and ignores anything a developer sets locally. For array keys such as `allowRead`, Claude Code merges entries from
  the scopes the session loads, so a developer can append entries that widen the policy unless a lock covers that
  key." Unless managed settings set them, a developer's user settings or `--settings` can turn on keys that each weaken
  the sandbox, and a repository's `.claude/settings.json` can too, unless the sandbox is admin-required. Set each to
  `false` in managed settings if you don't want it used: `enableWeakerNetworkIsolation`,
  `network.allowAllUnixSockets`, `network.allowLocalBinding`, and the three keys named under "A sandbox relied on as a
  control keeps its exceptions narrow"; a repository can't turn on `allowAppleEvents` or `allowNestedUserNamespaces`.
  "When managed settings configure `sandbox.filesystem` or list any `sandbox.credentials.files` entry with `"mode":
  "deny"`, only managed settings can set `filesystem.disabled`, so developers can't turn filesystem isolation off with
  that key."
  [sandboxing › Keep developers from widening the policy](https://code.claude.com/docs/en/sandboxing#keep-developers-from-widening-the-policy)
- "Set `allowManagedReadPathsOnly` to `true` in managed settings so that only `allowRead` entries from managed settings
  are honored." "To lock network domains to the managed values the same way, set `allowManagedDomainsOnly`."
  [sandboxing › Keep developers from widening the policy](https://code.claude.com/docs/en/sandboxing#keep-developers-from-widening-the-policy)
- Check: where every developer must run isolated, is the chosen approach enforced: for the Bash sandbox, managed
  `sandbox` keys in strict mode as "A sandbox relied on as a control runs in strict mode and doesn't fall back"
  asks, with the six weakening keys `false` unless the organisation needs them, `sandbox.filesystem` configured so
  developers can't set `filesystem.disabled`, and `allowManagedReadPathsOnly` and `allowManagedDomainsOnly` set where
  developers must not widen reads or domains; for a container or VM, device management or software allowlisting
  rather than a committed dev container alone?

## HIPAA-ready organisations using Claude Code (local mode) start managed settings from the recommended sample

- Managed settings can "direct developers to sign in with a Claude Enterprise account, to block cloud providers and
  gateways, and to set how many days every computer keeps local session data. The settings apply whether or not the
  HIPAA configuration is in effect." "The settings in this section are a sample that we recommend as a starting
  point. Your organization is responsible for deciding what its own environment needs and for confirming that its
  configuration meets those needs." The sample sets four keys:

  ```json
  {
    "forceLoginMethod": "claudeai",
    "forceLoginOrgUUID": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "allowedProviders": ["anthropic"],
    "cleanupPeriodDays": 30
  }
  ```

  [hipaa-setup › Deploy managed settings](https://code.claude.com/docs/en/hipaa-setup#deploy-managed-settings)
- What to set each key to and what Claude Code enforces:

  | Key | Set it to | What Claude Code enforces |
  | :- | :- | :- |
  | [`forceLoginMethod`](https://code.claude.com/docs/en/settings-reference#forceloginmethod) | `"claudeai"` | Claude Code directs developers to claude.ai sign-in instead of Claude Console |
  | [`forceLoginOrgUUID`](https://code.claude.com/docs/en/settings-reference#forceloginorguuid) | Your organization ID, which an [Owner](https://code.claude.com/docs/en/server-managed-settings#access-control) can copy from claude.ai admin settings | Claude Code exits at startup when the claude.ai sign-in belongs to another organization |
  | [`allowedProviders`](https://code.claude.com/docs/en/settings-reference#allowedproviders) | `["anthropic"]` | Claude Code refuses to start on a cloud provider or a gateway |
  | [`cleanupPeriodDays`](https://code.claude.com/docs/en/settings-reference#cleanupperioddays) | The number of days your records policy lets a computer keep session data | Every computer deletes old session data after the same number of days |

  "Check the `forceLoginOrgUUID` value before you deploy it. If it doesn't match your organization ID, Claude Code exits
  at startup for every developer who signs in with a claude.ai account." "The HIPAA configuration doesn't limit
  `cleanupPeriodDays`, so a developer can raise it in their own settings. When you set it in managed settings, Claude
  Code ignores the developer's value." "With `forceLoginMethod` or `forceLoginOrgUUID` set, Claude Code also refuses
  sessions that authenticate with `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `apiKeyHelper`."
  [hipaa-setup › What each key does](https://code.claude.com/docs/en/hipaa-setup#what-each-key-does)
- Even with these keys deployed, some sessions can still run without the HIPAA configuration. `forceLoginOrgUUID`
  checks only claude.ai sign-ins, so Claude Console sign-ins and federation credentials are not checked. And "if your
  organization also uses server-managed settings, have an Owner add the same keys there."
  [hipaa-setup › Sessions the managed settings keys don't block](https://code.claude.com/docs/en/hipaa-setup#sessions-the-managed-settings-keys-don’t-block)
- Check: for a HIPAA-ready organisation using Claude Code (local mode), do its managed settings start from the sample's
  four keys, with `forceLoginOrgUUID` checked against the organisation ID and `cleanupPeriodDays` set to its records
  policy, and the same keys in server-managed settings where it uses them?

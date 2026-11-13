# Sandbox

Configuring the sandbox: what it restricts, how to turn it on, and the filesystem, network and organisation settings.

## Contents

- What the sandbox covers
- Turning it on
- Linux and WSL2 setup
- Sandbox modes
- The unsandboxed retry and strict sandbox mode
- Temporary directories
- Filesystem settings
- Sandbox path prefixes
- Filesystem isolation and protected paths
- Disabling filesystem isolation
- Excluded commands
- Network isolation
- Network settings
- Proxies
- Permission rules and permission modes
- Enforcing the sandbox for an organisation
- Repository settings under an admin-required sandbox
- Settings for special environments
- Security limitations and scope

## What the sandbox covers

- The sandbox is a boundary that the operating system enforces around the shell commands Claude runs. The limits apply
  to Bash, PowerShell, and Monitor commands and the processes they start. Because the operating system applies the
  limits while a command runs, Claude Code can run sandboxed commands without asking you to approve each one.
  [sandboxing › Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing#page-title)
- The sandbox runs on macOS, Linux, and WSL2. On native Windows, Claude Code runs commands unsandboxed; to use the
  sandbox on a Windows machine, run Claude Code inside a WSL2 distribution.
  [sandboxing › Configure the sandboxed Bash tool](https://code.claude.com/docs/en/sandboxing#page-title)
- Sandboxing works on every provider.
  [feature-availability › Features available on every provider](https://code.claude.com/docs/en/feature-availability#features-available-on-every-provider)
- Claude Code uses Seatbelt on macOS and [bubblewrap](https://github.com/containers/bubblewrap) on Linux and WSL2. It
  builds the sandbox on the open source [`@anthropic-ai/sandbox-runtime`](https://github.com/anthropics/sandbox-runtime)
  package, which you can also run on its own to wrap the Claude Code process.
  [sandboxing › OS-level enforcement](https://code.claude.com/docs/en/sandboxing#os-level-enforcement),
  [sandboxing › What the sandbox restricts](https://code.claude.com/docs/en/sandboxing#what-the-sandbox-restricts)
- This table shows what a sandboxed command can reach by default and the settings that change each default.
  [sandboxing › What the sandbox restricts](https://code.claude.com/docs/en/sandboxing#what-the-sandbox-restricts)

  | Access | Default | Change it with |
  | :- | :- | :- |
  | Writes | The working directory, a per-user temp directory, and [directories you've added](https://code.claude.com/docs/en/permissions#additional-directories-grant-file-access-not-configuration). [Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths) stay write-denied | [`filesystem.allowWrite`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowwrite), [`filesystem.denyWrite`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-denywrite) |
  | Reads | Most of the machine, including credential files such as `~/.ssh` and `~/.aws/credentials` | [`filesystem.denyRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-denyread), [`credentials`](https://code.claude.com/docs/en/sandboxing#protect-credentials) |
  | Network | No direct route out. Connections go through a proxy on your machine that checks each host against your allowed domains, which start empty. Your permission mode decides [what happens to other hosts](https://code.claude.com/docs/en/sandboxing#hosts-outside-your-allowed-domains) | [`network.allowedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-alloweddomains), [`network.deniedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-denieddomains) |
  | Environment variables | Inherited from Claude Code, including any secrets in its environment | [`credentials`](https://code.claude.com/docs/en/sandboxing#protect-credentials), [`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`](https://code.claude.com/docs/en/env-vars) |

- These tools and processes run outside the sandbox: the built-in file and web tools such as Read, Edit, Write,
  WebFetch, and WebSearch, which follow permission rules instead (a `denyRead` entry doesn't stop the Read tool, and
  `allowedDomains` doesn't limit WebFetch). Local MCP servers, plugin monitors, LSP servers, and helper commands such as
  your status line command and `apiKeyHelper` run with your full access.
  [sandboxing › What runs outside the sandbox](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox)
- Some shell commands also run outside the sandbox, depending on your settings: a command you type at the `!` shell-mode
  prompt runs unsandboxed in most sessions; commands that match `excludedCommands` run unsandboxed; and Claude can ask
  to run a command unsandboxed, usually after it fails in the sandbox.
  [sandboxing › What runs outside the sandbox](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox)
- To put those tools, processes, and commands behind one boundary, run the Claude Code process itself in a container,
  virtual machine, or the sandbox runtime. For local mode, that means running it inside the sandbox runtime with a
  network allowlist limited to the hosts you approve, or in the dev container with its firewall script.
  [sandboxing › What runs outside the sandbox](https://code.claude.com/docs/en/sandboxing#what-runs-outside-the-sandbox),
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)
- A mod is a plugin that runs its own code inside Claude Code, and a process that a mod starts runs outside the sandbox.
  The sandbox isolates the Bash commands Claude runs.
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope),
  [plugins/mods/overview › What a mod can reach](https://code.claude.com/docs/en/plugins/mods/overview#what-a-mod-can-reach)
- When Claude controls your screen with computer use, it runs on your actual desktop rather than in an isolated
  environment, and per-app permission prompts gate each application.
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)
- A background session runs in its own process, and its Bash commands are sandboxed when its settings enable sandboxing.
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)
- Effective sandboxing requires both filesystem and network isolation. Without network isolation, a compromised agent
  could exfiltrate sensitive files like SSH keys. Without filesystem isolation, whether from a permissive policy or from
  disabling the filesystem layer, a compromised agent could backdoor system resources to gain network access. When you
  widen the defaults, check that an `allowWrite` path, a broad `allowedDomains` entry, or an `excludedCommands`
  exception does not undo a restriction on the other side.
  [sandboxing › Scope](https://code.claude.com/docs/en/sandboxing#scope)

## Turning it on

- `sandbox` is an object in any settings file with the keys `enabled`, `failIfUnavailable`, `autoAllowBashIfSandboxed`,
  `excludedCommands`, `allowUnsandboxedCommands`, `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`,
  `allowAppleEvents`, `allowNestedUserNamespaces`, `bwrapPath`, `socatPath`, `ignoreViolations`, and `ripgrep`, plus the
  `filesystem`, `network`, and `credentials` objects. It is unset by default, so Claude Code runs commands without a
  sandbox. [settings-reference › `sandbox`](https://code.claude.com/docs/en/settings-reference#sandbox)
- `sandbox.enabled` is a Boolean, `false` by default, that turns sandboxing on for Bash commands. It can be set in any
  file, with limits on project and local settings. Set it in `~/.claude/settings.json` to sandbox every project; when
  you pick a mode in the `/sandbox` panel, Claude Code writes the key to `.claude/settings.local.json` for the current
  project. [settings-reference › `sandbox.enabled`](https://code.claude.com/docs/en/settings-reference#sandbox-enabled)

  ```json
  {
    "sandbox": {
      "enabled": true
    }
  }
  ```

- By default, if the sandbox can't start because a dependency is missing or the platform is unsupported, Claude Code
  runs commands without sandboxing. `sandbox.failIfUnavailable` is a Boolean, `false` by default; set it to `true` to
  make Claude Code exit with an error at startup when `sandbox.enabled` is `true` but the sandbox can't start. Managed
  deployments that require sandboxing as a security gate can use it. It can be set in any file, with limits on project
  and local settings.
  [settings-reference › `sandbox.failIfUnavailable`](https://code.claude.com/docs/en/settings-reference#sandbox-failifunavailable),
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started)
- Run `/sandbox` in a session to open the sandbox panel. It has a **Mode** tab (choose how sandboxed commands are
  approved), an **Overrides** tab (choose whether commands that fail under the sandbox can fall back to running
  unsandboxed, which is the `allowUnsandboxedCommands` setting), and a **Config** tab (view the resolved sandbox
  settings). On Linux it also has a Dependencies tab when the optional seccomp filter is missing.
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started)
- On macOS, sandboxing uses the built-in Seatbelt framework, so nothing needs installing. On Linux and WSL2 the sandbox
  relies on `bubblewrap` and `socat`; you can start with `/sandbox` before installing them, because its panel shows
  whether anything is missing. If the panel shows only a Dependencies tab, a required package is missing: install it,
  restart Claude Code, and run `/sandbox` again.
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started)
- On the Mode tab, select auto-allow or regular permissions.
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started)
- In Manual mode and `acceptEdits` mode, the first time a sandboxed command needs a new network domain, Claude Code
  prompts for approval; the table under Network isolation gives the other modes.
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started),
  [sandboxing › Hosts outside your allowed domains](https://code.claude.com/docs/en/sandboxing#hosts-outside-your-allowed-domains)
- To change the sandbox for one session without writing to a settings file, start Claude Code with `--settings`. This
  starts a sandboxed session in which Claude can't retry a blocked command outside the sandbox:
  [sandboxing › Get started](https://code.claude.com/docs/en/sandboxing#get-started)

  ```bash
  claude --settings '{"sandbox": {"enabled": true, "allowUnsandboxedCommands": false}}'
  ```

- To confirm the sandbox works, ask Claude to run each line in the table. What you type at the `!` prompt usually runs
  outside the sandbox, so typing a line yourself doesn't test it.
  [sandboxing › Confirm commands run inside the sandbox](https://code.claude.com/docs/en/sandboxing#confirm-commands-run-inside-the-sandbox)

  | Command | Result inside the sandbox |
  | :- | :- |
  | `touch ~/sandbox-probe` | Fails with `Operation not permitted` on macOS, or `Read-only file system` on Linux and WSL2 |
  | `curl --noproxy '*' https://example.com` | Fails with `Could not resolve host`, because the command has no route around the sandbox proxy |

- If Claude asks to retry a failed command outside the sandbox, decline the retry. If `touch` succeeds and your home
  directory isn't one of the directories the sandbox lets commands write to, delete `~/sandbox-probe`, then run
  `/sandbox` to check that the sandbox is on and its dependencies are installed.
  [sandboxing › Confirm commands run inside the sandbox](https://code.claude.com/docs/en/sandboxing#confirm-commands-run-inside-the-sandbox)

## Linux and WSL2 setup

- On Linux and WSL2 the sandbox relies on `bubblewrap`, the unprivileged sandboxing tool that enforces filesystem
  isolation, and `socat`, the relay that routes network traffic through the sandbox proxy. Install them with `sudo
  apt-get install bubblewrap socat` on Ubuntu/Debian or `sudo dnf install bubblewrap socat` on Fedora.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- When a dependency is missing, the Dependencies tab in `/sandbox` lists which of `ripgrep`, `bubblewrap`, `socat`, and
  the seccomp filter your platform lacks. If you don't see the tab after installing and restarting Claude Code, all
  dependencies are present.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- Ripgrep is bundled with the native Claude Code binary. The seccomp filter is optional and adds Unix domain socket
  blocking; install it with `npm install -g @anthropic-ai/sandbox-runtime` if it is missing.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- When a required dependency is missing, the Dependencies tab is the only tab shown until you install it. When only the
  optional seccomp filter is missing, the Dependencies tab appears alongside the other tabs. The dependency check runs
  at startup, so restart Claude Code after installing packages for `/sandbox` to detect them.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- On Ubuntu 24.04 and later, the default AppArmor policy prevents bubblewrap from creating the user namespaces it needs.
  Run `sysctl kernel.apparmor_restrict_unprivileged_userns` (this also works inside WSL2): if it returns `0`, or prints
  a `No such file or directory` error because the key doesn't exist, skip this step. If it returns `1`, add an AppArmor
  profile that grants `bwrap` the capability, then reload AppArmor with `sudo systemctl reload apparmor`. The profile
  applies only to `bwrap` itself, not to the commands it runs inside the sandbox.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)

  ```bash
  sudo tee /etc/apparmor.d/bwrap > /dev/null <<'EOF'
  abi <abi/4.0>,
  include <tunables/global>

  profile bwrap /usr/bin/bwrap flags=(unconfined) {
    userns,
    include if exists <local/bwrap>
  }
  EOF
  ```

- Check your WSL version with `wsl -l -v` from PowerShell. If you see `Sandboxing requires WSL2`, your distribution is
  running WSL1: upgrade it to WSL2 or run Claude Code without sandboxing.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- On WSL2, WSL hands a launch of a Windows binary such as `cmd.exe`, `powershell.exe`, or anything under `/mnt/c/` to
  the Windows host over a Unix socket, so whether a sandboxed command can launch one follows the sandbox's Unix-socket
  settings. The optional seccomp filter has to be installed to block the socket in the first place.
  [sandboxing › Set up Linux and WSL2](https://code.claude.com/docs/en/sandboxing#set-up-linux-and-wsl2)
- `sandbox.bwrapPath` points the sandbox at a bubblewrap binary installed outside `PATH`, such as a vendored copy on an
  air-gapped host. Claude Code uses the path both for the startup dependency check and when it wraps each sandboxed
  command. It is a string holding an absolute path (Claude Code drops a relative path and falls back to `PATH` lookup),
  unset by default so Claude Code finds `bwrap` on `PATH`, and read only from managed settings so a user, project, or
  local file can't point the sandbox at a different binary. Linux and WSL2 only.
  [settings-reference › `sandbox.bwrapPath`](https://code.claude.com/docs/en/settings-reference#sandbox-bwrappath)
- `sandbox.socatPath` points the sandbox network proxy at a `socat` binary installed outside `PATH`. It is a string
  holding an absolute path (Claude Code drops a relative path and falls back to `PATH` lookup), unset by default so
  Claude Code finds `socat` on `PATH`, and read only from managed settings. Linux and WSL2 only.
  [settings-reference › `sandbox.socatPath`](https://code.claude.com/docs/en/settings-reference#sandbox-socatpath)

  In `managed-settings.json`:

  ```json
  {
    "sandbox": {
      "enabled": true,
      "bwrapPath": "/opt/admin/bwrap",
      "socatPath": "/opt/admin/socat"
    }
  }
  ```

## Sandbox modes

- Claude Code offers two sandbox modes. In both, the sandbox enforces the same filesystem and network restrictions; the
  difference is only in whether sandboxed commands are auto-approved or require explicit permission.
  [sandboxing › Sandbox modes](https://code.claude.com/docs/en/sandboxing#sandbox-modes)
- In regular permissions mode, all Bash commands go through the regular permission flow, even when sandboxed. This
  provides more control but requires more approvals.
  [sandboxing › Regular permissions mode](https://code.claude.com/docs/en/sandboxing#regular-permissions-mode)
- In auto-allow mode, Claude Code approves a command automatically, with no prompt, when the command runs inside the
  sandbox. A command goes through the regular permission flow when it runs outside the sandbox because it matches
  `excludedCommands` or because Claude retries it unsandboxed. A sandboxed command that connects to a host you haven't
  allowed stays in the sandbox.
  [sandboxing › Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)
- `sandbox.autoAllowBashIfSandboxed` is a Boolean, `true` by default, that can be set in any file. With `true`, Claude
  Code runs sandboxed Bash commands without a permission prompt, except in the cases that auto-allow mode describes, and
  `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` turns auto-allow off. With `false`, sandboxed commands go through the regular
  permission flow, so your allow rules and permission mode decide; the `/sandbox` **Mode** tab calls this regular
  permissions mode. Commands that can't run in the sandbox still go through the regular permission flow.
  [settings-reference › `sandbox.autoAllowBashIfSandboxed`](https://code.claude.com/docs/en/settings-reference#sandbox-autoallowbashifsandboxed)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "autoAllowBashIfSandboxed": false
    }
  }
  ```

- Even in auto-allow mode, a command in a form that a `Bash` deny rule matches is still blocked; `rm` or `rmdir`
  commands recognized as targeting a critical path still go through the regular permission flow; and content-scoped ask
  rules like `Bash(git push *)` still force a prompt even for sandboxed commands.
  [sandboxing › Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)
- Monitor tool commands aren't approved automatically in auto-allow mode, though they still run in the sandbox. To skip
  the prompt, add an allow rule that matches the command, such as `Bash(npm run *)`.
  [sandboxing › Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)
- Some sandboxed commands go through the regular permission flow instead of being approved automatically: commands such
  as `FOO=bar npm test`, where a variable set in front of a command can change which program runs, and `make CC=clang`
  or `eval "ls"`. Your allow rules and permission mode then decide whether you see a prompt, and the command still runs
  inside the sandbox. An allow rule that matches the command stops a recurring prompt:
  [sandboxing › Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)
  - `Bash(make *)` approves `make CC=clang`
  - `Bash(FOO=bar npm *)` approves `FOO=bar npm test`. When the command starts with a variable assignment, include the
    assignment in the rule
  - `Bash(eval "ls")` approves `eval "ls"`. A wildcard rule such as `Bash(eval *)` doesn't stop this prompt, so write a
    rule that matches the whole command
- Auto-allow mode works independently of your permission mode setting, with three exceptions: plan mode, an auto mode
  command that carries per-command allowed domains, and server-side classifier review of sandboxed commands in auto
  mode. Even if you're not in "accept edits" mode, sandboxed Bash commands run automatically when auto-allow is enabled,
  so Bash commands that modify files within the sandbox boundaries execute without prompting, even in Manual mode, where
  the file edit tools would prompt. In plan mode, auto-allow doesn't widen approvals.
  [sandboxing › Auto-allow mode](https://code.claude.com/docs/en/sandboxing#auto-allow-mode)

## The unsandboxed retry and strict sandbox mode

- The unsandboxed retry is an escape hatch for commands that fail inside the sandbox, such as tools that are
  incompatible with it. When the sandbox blocks a network connection, Claude Code names the denied host in the command's
  result. Claude analyzes the failure and may retry the command with the `dangerouslyDisableSandbox` parameter, and the
  retried command runs unsandboxed.
  [sandboxing › The unsandboxed retry escape hatch](https://code.claude.com/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch)
- In an interactive terminal session, who approves the retry depends on your permission mode: in `bypassPermissions`
  mode the retry runs without a prompt; in Manual mode and `acceptEdits` mode you get a prompt titled "Bash command
  (unsandboxed)"; in auto mode a separate classifier model evaluates the underlying command; in `dontAsk` mode Claude
  Code denies the retry; plan mode follows
  [how Claude Code gates commands while you plan](https://code.claude.com/docs/en/permission-modes#analyze-before-you-edit-with-plan-mode).
  [sandboxing › The unsandboxed retry escape hatch](https://code.claude.com/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch)
- A matching allow rule such as `Bash(curl *)` also approves the retry, so the command runs outside the sandbox with no
  prompt. An ask rule for `Bash(dangerouslyDisableSandbox:true)` prompts you on Bash retries, including in auto mode and
  `bypassPermissions` mode, and takes precedence over a matching allow rule.
  [sandboxing › The unsandboxed retry escape hatch](https://code.claude.com/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch)
- While `permissions.blockReadsOutsideWorkingDirectories` is on, some retries prompt that no mode auto-approves;
  [Actions no mode auto-approves](https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves) covers
  which.
  [sandboxing › The unsandboxed retry escape hatch](https://code.claude.com/docs/en/sandboxing#the-unsandboxed-retry-escape-hatch)
- `sandbox.allowUnsandboxedCommands` is a Boolean, `true` by default, that can be set in any file with a limit on
  project and local settings. With `true`, Claude can retry a command outside the sandbox with the
  `dangerouslyDisableSandbox` parameter after the sandbox blocks it. With `false`, Claude Code ignores that parameter,
  so while the sandbox is running, commands Claude runs are sandboxed unless they match an `excludedCommands` entry. The
  `/sandbox` **Overrides** tab shows that state as **Strict sandbox mode**, and a `false` in managed settings turns on
  strict sandbox mode for the developers it covers. To keep Claude Code from running commands unsandboxed when the
  sandbox can't start, also set `failIfUnavailable`.
  [settings-reference › `sandbox.allowUnsandboxedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-allowunsandboxedcommands),
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "allowUnsandboxedCommands": false
    }
  }
  ```

- A `false` in your user settings, `--settings`, or managed settings holds even when a project's settings set `true`. A
  `false` in your user settings doesn't make the sandbox admin-required, so a project's other sandbox settings still
  apply.
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode),
  [settings-reference › `sandbox.allowUnsandboxedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-allowunsandboxedcommands)
- If you or your administrator disable the retry in managed settings or with the `--settings` flag, Claude Code ignores
  the settings in a repository's files that loosen the sandbox, `excludedCommands` entries included.
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)
- Strict sandbox mode applies to the commands Claude runs. Commands you type yourself at the `!` shell-mode prompt run
  outside the sandbox unless the session is a background session (strict sandbox mode covers shell-mode commands too) or
  a Linux session with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` set (every command runs sandboxed, shell-mode commands
  included).
  [sandboxing › Turn off the retry with strict sandbox mode](https://code.claude.com/docs/en/sandboxing#turn-off-the-retry-with-strict-sandbox-mode)

## Temporary directories

- Unless you disable filesystem isolation, Claude Code sets `$TMPDIR` to the per-user temp directory for sandboxed
  commands, so tools that write temporary files work without extra configuration.
  [sandboxing › Temporary directories](https://code.claude.com/docs/en/sandboxing#temporary-directories)
- Unsandboxed commands inherit your shell's `$TMPDIR` when it is set, so while filesystem isolation is on, sandboxed and
  unsandboxed commands resolve `$TMPDIR` to different directories. If your shell leaves `$TMPDIR` unset or empty, an
  unsandboxed command that references `$TMPDIR` receives your `CLAUDE_CODE_TMPDIR` override, or the operating system's
  temp directory when you haven't set one or the override is a long path, so the variable doesn't expand to an empty
  string. To pass temporary files between the two, write them under the working directory instead.
  [sandboxing › Temporary directories](https://code.claude.com/docs/en/sandboxing#temporary-directories)
- On macOS and Linux, sandboxed Bash subprocesses receive a short fallback `$TMPDIR` under the system default when the
  `CLAUDE_CODE_TMPDIR` override is a long path, since some tools fail when temp paths get too long.
  [env-vars › Variables](https://code.claude.com/docs/en/env-vars#variables)

## Filesystem settings

- `sandbox.filesystem` controls which paths sandboxed commands can read and write. Any file can set it. It is an object
  with the `allowWrite`, `denyWrite`, `denyRead`, and `allowRead` arrays, plus the `allowManagedReadPathsOnly` and
  `disabled` Booleans, and it is unset by default so the default read and write boundaries apply.
  [settings-reference › `sandbox.filesystem`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem)

  ```json
  {
    "sandbox": {
      "filesystem": {
        "allowWrite": ["/tmp/build", "~/.kube"],
        "denyRead": ["~/.aws/credentials"]
      }
    }
  }
  ```

- Claude Code enforces these lists at the OS sandbox boundary, so they apply to every subprocess a sandboxed command
  starts, such as `kubectl`, `terraform`, or `npm`.
  [settings-reference › `sandbox.filesystem`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem),
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)
- Claude Code adds your permission rules to the same lists: `Edit` allow and deny rules to `allowWrite` and `denyWrite`,
  `Read` deny rules to `denyRead`, and `WebFetch(domain:...)` allow and deny rules to the `network` domain lists.
  [settings-reference › `sandbox.filesystem`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem)
- If you exclude a source with `--setting-sources` on the CLI or `settingSources` in the Agent SDK, Claude Code ignores
  its `sandbox.filesystem` entries, its `Edit` permission rules, and its `Read` deny rules when building the sandbox
  configuration. [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)
- When you edit these filesystem lists during a session, Claude Code applies the change to the running session, so the
  next sandboxed command runs under the new paths.
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)
- `sandbox.filesystem.allowWrite` adds paths where sandboxed commands can write, beyond the working directory, the
  per-user temp directory, and the directories you've added with `--add-dir`, `/add-dir`, or
  `permissions.additionalDirectories`. Use it when a subprocess such as `kubectl` or a build tool needs to write outside
  the project. It is an array of path strings that can be set in any file, with limits on project and local settings,
  and is unset by default.
  [settings-reference › `sandbox.filesystem.allowWrite`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowwrite)
- Claude Code merges `allowWrite` entries and the paths from your `Edit(...)` allow permission rules across the settings
  scopes the session loads, leaving out the ones from repository settings while
  `permissions.blockReadsOutsideWorkingDirectories` is on. Repository locks can leave out a repository's entries too.
  [settings-reference › `sandbox.filesystem.allowWrite`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowwrite)
- `sandbox.filesystem.denyWrite` blocks sandboxed commands from writing to specific paths, including paths inside a
  directory that is otherwise writable. It is an array of path strings, unset by default, and can be set in any file.
  Claude Code merges entries across every settings scope the session loads, and adds the paths from your `Edit(...)`
  deny permission rules.
  [settings-reference › `sandbox.filesystem.denyWrite`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-denywrite)

  ```json
  {
    "sandbox": {
      "filesystem": {
        "denyWrite": ["/etc", "/usr/local/bin"]
      }
    }
  }
  ```

- `sandbox.filesystem.denyRead` blocks sandboxed commands from reading specific paths, such as credential files that the
  default read policy would otherwise expose. It is an array of path strings that can be set in any file; unset by
  default, so sandboxed commands keep the default read access, which includes credential files such as
  `~/.aws/credentials`. To protect a credential file and keep it usable through the sandbox proxy, use
  `sandbox.credentials` instead. Claude Code merges entries across every settings scope the session loads, and adds the
  paths from your `Read(...)` deny permission rules.
  [settings-reference › `sandbox.filesystem.denyRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-denyread)
- `sandbox.filesystem.allowRead` re-opens reading for specific paths inside a region that `denyRead` blocks, to build
  workspace-only read access. It is an array of path strings, unset by default, that can be set in any file with limits
  on project and local settings. An exact or wildcard `denyRead` entry stays blocked inside a broader `allowRead`. When
  a wildcard `denyRead` entry such as `~/**/.env` matches a directory, Claude Code blocks reads of its contents as well.
  [settings-reference › `sandbox.filesystem.allowRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowread)
- Claude Code resolves a `.` entry to the project root in project settings and to `~/.claude` in user settings. It
  merges `allowRead` entries across the settings files the session loads unless `allowManagedReadPathsOnly` is set, and
  leaves out entries from repository settings while `permissions.blockReadsOutsideWorkingDirectories` is on. Repository
  locks can leave out a repository's entries too.
  [settings-reference › `sandbox.filesystem.allowRead`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowread)
- When read rules overlap, the rule with the narrower path applies:
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)

  | Example rules | Result |
  | :- | :- |
  | `"denyRead": ["~/"]` with `"allowRead": ["~/projects"]` | `~/projects` is readable and the rest of the home directory stays blocked. The narrower allow re-opens that part of the denied region |
  | `"allowRead": ["~/"]` with `"denyRead": ["~/.env"]` | `~/.env` stays blocked and the rest of the home directory is readable. The deny holds inside a wider allow, so a broad allow can't silently re-expose a secret |
  | `"allowRead": ["~/"]` with `"denyRead": ["~/**/.env"]` | Every `.env` under the home directory stays blocked and the rest is readable. A [wildcard deny](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes) holds inside a wider allow the same way an exact path does |

- This example blocks reading from the entire home directory while still allowing reads from the current project. Place
  it in your project's `.claude/settings.json`, because the relative path `.` resolves to the project root when the
  configuration lives in project settings. If you placed the same configuration in `~/.claude/settings.json`, `.` would
  resolve to `~/.claude` instead, and project files would remain blocked by the `denyRead` rule.
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "filesystem": {
        "denyRead": ["~/"],
        "allowRead": ["."]
      }
    }
  }
  ```

- To deny sandboxed commands read access to home directories and mounted volumes while keeping the working directories
  readable, set `permissions.blockReadsOutsideWorkingDirectories` instead of writing path rules.
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)
- When `permissions.blockReadsOutsideWorkingDirectories` is on and sandboxing is on, the block also covers sandboxed
  commands. Claude Code denies them read access to your home directory and to the other roots that hold user files:
  `/Users`, `/home`, `/root`, `/Volumes`, `/mnt`, `/media`, `/run/media`, and `/srv`. It then re-opens the working
  directories, worktrees Claude Code creates in the session, the session temp directory, and the parts of `~/.claude`
  that commands need, such as skills and plugins. While the block is in force, `allowRead` and `allowWrite` entries from
  repository settings don't count.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block),
  [sandboxing › Filesystem isolation](https://code.claude.com/docs/en/sandboxing#filesystem-isolation)
- When the session's working directory is a linked git worktree, including one Claude Code entered mid-session, the
  repository's common `.git` directory stays readable and writable to sandboxed commands, so git keeps working there;
  writes to `hooks/` and `config` inside that directory remain denied.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block),
  [sandboxing › Filesystem isolation](https://code.claude.com/docs/en/sandboxing#filesystem-isolation)
- The block doesn't reach sandboxed commands, while Claude's file tools keep enforcing it, when filesystem isolation is
  off through `sandbox.filesystem.disabled`, when `allowManagedReadPathsOnly` is set, or when the path of the directory
  you started Claude Code in contains a glob character such as `*`, `?`, or `[`.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block)
- Under the block, Claude Code re-opens your global git configuration files to sandboxed commands so `git` keeps your
  identity and settings: `~/.gitconfig`; the `config`, `ignore`, and `attributes` files under `$XDG_CONFIG_HOME/git`,
  which defaults to `~/.config/git`; and files your global git configuration names through `[include]`, `[includeIf]`,
  `core.excludesFile`, or `core.attributesFile`.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block)
- Claude Code judges each re-opened file separately. When a file lies where a sandboxed command can write, directly or
  through a symlink, Claude Code doesn't re-open the files it names. On Linux and WSL2, a configuration file that is a
  symlink can stay unreadable at its own path, and `git` then runs without it. `~/.git-credentials` and
  `$XDG_CONFIG_HOME/git/credentials` stay blocked.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block)
- If a re-opened file holds a secret, such as an `http.extraHeader` token, add its path to
  `sandbox.filesystem.denyRead`. A `denyRead` entry that covers a file always takes precedence over this re-open.
  [settings-reference › Sandboxed commands under the block](https://code.claude.com/docs/en/settings-reference#sandboxed-commands-under-the-block)
- `sandbox.filesystem.allowManagedReadPathsOnly` is a Boolean, `false` by default, read from managed settings only. With
  `true`, Claude Code honors only the `allowRead` entries from managed settings, so developers can't re-open read access
  to paths your organization blocked; with `false`, `allowRead` entries from other settings files can merge in. Claude
  Code still merges `denyRead` entries from every settings scope the session loads.
  [settings-reference › `sandbox.filesystem.allowManagedReadPathsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-allowmanagedreadpathsonly)

  ```json
  {
    "sandbox": {
      "filesystem": {
        "denyRead": ["~/"],
        "allowRead": ["~/work"],
        "allowManagedReadPathsOnly": true
      }
    }
  }
  ```

- `sandbox.ignoreViolations` silences sandbox violation reports for paths you expect a command to probe and be refused,
  such as a tool that checks `/etc/hosts` on startup, so those denials don't show up as violations or in what Claude
  sees. The sandbox still blocks the access; only the report is suppressed. Keys are substrings to match against the
  command, with `*` matching every command, and values are substrings of the violation to ignore for that command, such
  as a filesystem path. It can be set in any file, with limits on project and local settings, and is unset by default so
  every violation is reported.
  [settings-reference › `sandbox.ignoreViolations`](https://code.claude.com/docs/en/settings-reference#sandbox-ignoreviolations)

  ```json
  {
    "sandbox": {
      "ignoreViolations": {
        "*": ["/etc/hosts"]
      }
    }
  }
  ```

## Sandbox path prefixes

- Paths in `allowWrite`, `denyWrite`, `denyRead`, `allowRead`, and `credentials.files` resolve by their prefix:
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)

  | Prefix | Meaning | Example |
  | :- | :- | :- |
  | `/` | Absolute path from filesystem root | `/tmp/build` stays `/tmp/build` |
  | `~/` | Relative to home directory | `~/.kube` becomes `$HOME/.kube` |
  | `./` or no prefix | Relative to the project root for project settings, or to `~/.claude` for user settings | `./output` in `.claude/settings.json` resolves to `<project-root>/output` |

- The `//path` prefix for absolute paths also works. If you use single-slash `/path` expecting project-relative
  resolution, switch to `./path`. Sandbox filesystem paths differ from Read and Edit permission rules, which use
  `//path` for absolute and `/path` for project-relative: sandbox filesystem paths use standard conventions, so
  `/tmp/build` is an absolute path and `~/.kube` is relative to your home directory.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes),
  [sandboxing › Configure sandboxing](https://code.claude.com/docs/en/sandboxing#configure-sandboxing)
- Claude Code strips a trailing slash from a directory path, so `~/.aws` and `~/.aws/` match the same directory.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)
- The wildcards `*`, `?`, and `**` work in all four `sandbox.filesystem` path lists on macOS and in fewer places on
  Linux and WSL2.
  [settings-reference › Where wildcards work in sandbox paths](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)

  | `sandbox.filesystem` list | What works on Linux and WSL2 | Example that doesn't work on Linux and WSL2 | What to write instead |
  | :- | :- | :- | :- |
  | `denyRead`, `allowRead` | A trailing `/**` works, so `~/build/**` covers the same directory as `~/build`. Any other wildcard works only after the first directory name of the entry's [full path](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes). | `/**/*.pem` in `denyRead` covers nothing, so it blocks no reads | `/srv/**/*.pem`, with one entry for each top-level directory |
  | `allowWrite`, `denyWrite` | Only a trailing `/**` works, so `~/build/**` covers the same directory as `~/build` | `./src/*` covers only a file or directory in `src` that is itself named `*`, and nothing when there is none | `./src`, which covers everything under `src`, or one entry for each path |

- In `~/keys/*.pem`, the wildcard comes after the first directory name, which is `home` for a home directory of
  `/home/alice` (the entry's full path is `/home/alice/keys/*.pem`). On Linux and WSL2, the **Config** tab of `/sandbox`
  warns about `Edit` permission rules that contain a wildcard other than a trailing `/**`; those wildcards don't work
  for sandboxed commands, so add each path the rule should cover, or the directory that holds them, to `allowWrite` for
  an allow rule or `denyWrite` for a deny rule.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)
- To allow or block a directory whose name contains brackets, write the name as it is, such as `./app/[slug]`, where
  `[slug]` is the directory's real name. That entry covers everything under the directory, so leave off a trailing
  `/**`. On macOS and on Linux and WSL2, the `app/[slug]` directory has to exist when the sandboxed command starts.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)
- Brackets such as `[slug]`: in every list on macOS, and in `denyRead` and `allowRead` on Linux and WSL2, the brackets
  in `./app/[slug]` are also a pattern, so the entry also matches any path under `app` named with one character from
  `slug`, such as `app/s` or `app/g`. With that entry in `allowRead`, or in `allowWrite` on macOS, sandboxed commands
  can reach those paths as well; rename any they shouldn't reach.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)
- Brackets such as `[user-id]` or `[post-id]`, where the hyphen's left character sorts after its right:
  `./app/[user-id]` covers only the directory with exactly that name, in every list on every platform.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)
- Braces and parentheses are ordinary characters, so `~/data/{keys,tokens}` covers one directory named `{keys,tokens}`,
  not two alternatives. To cover `~/data/keys` and `~/data/tokens`, add each as its own entry.
  [settings-reference › Sandbox path prefixes](https://code.claude.com/docs/en/settings-reference#sandbox-path-prefixes)

## Filesystem isolation and protected paths

- Inside the directories that sandboxed commands can write to, the sandbox still denies writes to the files Claude Code
  loads configuration and code from, because a command that could edit them could grant itself permissions or add a hook
  or MCP server that Claude Code runs outside the sandbox. The permission system has its own protected paths, which
  control what Claude Code approves before a tool runs; the sandbox's list applies to a command that is already running.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
- The sandbox's protected paths cover four groups:
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
  - **In your working directory and the directories above it**: the `.claude` settings files, the `.claude/skills`,
    `.claude/agents`, `.claude/commands`, and `.claude/hooks` directories, `.mcp.json`, and the files Claude Code runs
    on its own, such as `.claude/workflows` and `.claude/scheduled_tasks.json`
  - **In your working directory only**: shell startup files such as `.bashrc` and `.zshrc`, `.gitconfig`, the `.vscode`
    and `.idea` directories, and `hooks` and `config` inside `.git`
  - **Files that would turn your working directory into a bare git repository**: `HEAD`, `objects`, and `refs` at the
    top level, plus existing `config` and `hooks` entries there when a `HEAD` file or symlink sits beside them. A file
    named `config` is denied even with no `HEAD`. On Linux and WSL2, a sandboxed command can create one where none
    exists
  - **In `~/.claude`, or the directory `CLAUDE_CONFIG_DIR` points to**: most of its contents, plus `~/.claude.json` and
    the `.credentials.json` credential store
- If a symlink appears at a protected settings file's path during the session, the sandbox also denies writes to the
  file it points to, starting with the next command.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
- If you add an `allowWrite` entry or an `Edit` allow rule that covers a protected path, the protection still applies.
  To turn the protection off, set `filesystem.disabled`, which also turns off the rest of filesystem isolation.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
- If you set `allowNestedUserNamespaces` to `true` on Linux or WSL2, don't rely on protected paths.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
- To see most protected paths resolved for your machine, run `/sandbox` and open the **Config** tab, which lists them
  under **Denied within allowed**, mixed in with your own `denyWrite` entries.
  [sandboxing › Protected paths](https://code.claude.com/docs/en/sandboxing#protected-paths)
- After a sandboxed command ends, a newer top-level `HEAD`, `objects`, or `refs` entry in your working directory is
  deleted unless it's a folder with contents. Newer means the entry wasn't there when the sandbox last built its
  configuration: at session start, or after a change such as `/cd`.
  [sandboxing › When the sandbox deletes `HEAD`, `objects`, or `refs`](https://code.claude.com/docs/en/sandboxing#when-the-sandbox-deletes-head-objects-or-refs)
- A newer `objects` or `refs` folder with contents is deleted too, with its contents, when a `HEAD` file or symlink was
  there the last time the sandbox built its configuration.
  [sandboxing › When the sandbox deletes `HEAD`, `objects`, or `refs`](https://code.claude.com/docs/en/sandboxing#when-the-sandbox-deletes-head-objects-or-refs)
- On macOS, when a denied path passes through a symlink, such as a `~/.claude` that is a link into a dotfiles
  repository, the sandbox also denies the path's real location. This covers the sandbox's own denials and your literal
  `denyWrite` and `denyRead` entries. A `denyWrite` entry that contains `*`, `?`, or `[` is also covered when a folder
  before the first of those characters is a symlink: `~/.claude/*.json` is also denied under the real location of
  `~/.claude`.
  [sandboxing › Denied paths that pass through a symlink](https://code.claude.com/docs/en/sandboxing#denied-paths-that-pass-through-a-symlink)

## Disabling filesystem isolation

- `sandbox.filesystem.disabled` is a Boolean, `false` by default, that skips filesystem isolation while keeping network
  isolation. Sandboxed commands get unrestricted read and write access to the host filesystem, and their network egress
  stays confined to `network.allowedDomains`. Use it when you sandbox to control where commands connect rather than what
  they write.
  [settings-reference › `sandbox.filesystem.disabled`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-disabled),
  [sandboxing › Disable filesystem isolation](https://code.claude.com/docs/en/sandboxing#disable-filesystem-isolation)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "filesystem": {
        "disabled": true
      },
      "network": {
        "allowedDomains": ["github.com", "*.npmjs.org"]
      }
    }
  }
  ```

- The sandbox has two independent layers: filesystem isolation controls which paths sandboxed commands can read and
  write, and network isolation controls which domains they can reach.
  [sandboxing › Disable filesystem isolation](https://code.claude.com/docs/en/sandboxing#disable-filesystem-isolation)
- With filesystem isolation off and commands auto-allowed, a sandboxed command can write files that later commands run
  or read, such as shell startup files, executables on `$PATH`, or `~/.claude/settings.json`, and use them to widen its
  own access on the next run. Set `filesystem.disabled` to `true` only for workloads you trust not to escalate their own
  access. Locking network domains with `allowManagedDomainsOnly` narrows the risk but doesn't remove it, since that lock
  applies only to commands running inside the sandbox.
  [sandboxing › Disable filesystem isolation](https://code.claude.com/docs/en/sandboxing#disable-filesystem-isolation)
- Scope of `filesystem.disabled`: user or managed settings. Claude Code honors it from user settings, managed settings,
  and the `--settings` CLI flag; project settings in `.claude/settings.json` and `.claude/settings.local.json` can't set
  it, so a checked-out project can't switch filesystem isolation off.
  [settings-reference › `sandbox.filesystem.disabled`](https://code.claude.com/docs/en/settings-reference#sandbox-filesystem-disabled),
  [sandboxing › Which settings can disable it](https://code.claude.com/docs/en/sandboxing#which-settings-can-disable-it)
- When managed settings configure `sandbox.filesystem` at all, or list any `sandbox.credentials.files` entry with
  `"mode": "deny"`, only managed settings can set `filesystem.disabled`. This keeps developers from turning filesystem
  isolation off in such a deployment; to turn it off for everyone, set `"disabled": true` in managed settings.
  [sandboxing › Which settings can disable it](https://code.claude.com/docs/en/sandboxing#which-settings-can-disable-it)
- When `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` is set, Claude Code ignores `filesystem.disabled` from every source, including
  managed settings, and keeps filesystem isolation on.
  [sandboxing › Which settings can disable it](https://code.claude.com/docs/en/sandboxing#which-settings-can-disable-it)
- Setting `filesystem.disabled` lifts the protections the filesystem layer itself enforces; protections that other
  layers enforce keep applying.
  [sandboxing › What changes when filesystem isolation is off](https://code.claude.com/docs/en/sandboxing#what-changes-when-filesystem-isolation-is-off)

  | Protection | With filesystem isolation off |
  | - | - |
  | `filesystem.denyRead` and [`credentials.files`](https://code.claude.com/docs/en/sandboxing#protect-credentials) `deny` read blocks | Not enforced. The filesystem layer applies both |
  | `credentials.envVars` `deny` and `mask` entries | Enforced. Environment variable scrubbing is independent of the filesystem layer |
  | [`credentials.files` `mask` entries](https://code.claude.com/docs/en/sandboxing#mask-credential-files) applied as masks | Enforced: masking is independent of the filesystem layer. An entry that [fell back to `deny`](https://code.claude.com/docs/en/sandboxing#mask-credential-files) is not enforced, like any `deny` entry |

- With filesystem isolation off, sandboxed commands inherit your shell's `$TMPDIR` instead of the per-user temp
  directory, because every temp directory is writable and Claude Code no longer redirects commands to the per-user one.
  On Linux the variable is often unset in the parent shell; the Bash tool guidance tells Claude to create scratch
  directories with `mktemp -d` instead of relying on `$TMPDIR`.
  [sandboxing › What changes when filesystem isolation is off](https://code.claude.com/docs/en/sandboxing#what-changes-when-filesystem-isolation-is-off)
- With filesystem isolation off, `autoAllowBashIfSandboxed` still defaults to `true`, so sandboxed commands keep running
  without prompts. Set it to `false` to prompt for sandboxed commands.
  [sandboxing › What changes when filesystem isolation is off](https://code.claude.com/docs/en/sandboxing#what-changes-when-filesystem-isolation-is-off)

## Excluded commands

- `sandbox.excludedCommands` names commands that Claude Code runs outside the sandbox, such as tools that don't work
  under it, which means no filesystem restrictions and no network proxy. Use it for a tool that can't work inside the
  sandbox and that you trust with your full access. A tool that needs one more directory or one more host may work with
  `allowWrite` or `allowedDomains`, which keep the command sandboxed.
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands),
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
- It is an array of command patterns, unset by default so no command is excluded, and can be set in any file, with
  limits on project and local settings. Each entry uses the same syntax as the content of a `Bash(...)` permission rule:
  an exact command, a prefix such as `docker *`, or a wildcard pattern. A pattern with no wildcard is an exact match, so
  `docker` matches only `docker` with no arguments, while `docker *` matches `docker` with or without arguments.
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands),
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "excludedCommands": ["docker compose *"]
    }
  }
  ```

  Saved in `~/.claude/settings.json`, this example takes `docker compose` commands out of the sandbox for all of your
  projects.
- Claude Code checks your entries against each Bash and Monitor call, which is the whole command line Claude sends and
  can chain several commands. Entries take a Bash call out of the sandbox only when they cover every command in it: `npm
  ci && docker compose build` stays sandboxed unless another entry covers `npm ci`.
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands),
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
- Claude Code matches the text of the call: a script or `make` target that calls `docker` internally doesn't match, and
  neither does `/usr/local/bin/docker`.
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands)
- Claude Code keeps a Bash call sandboxed when it has one of these shapes, among others:
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
  - A command starting with `sudo`, `eval`, or `xargs`
  - A `cd`, `pushd`, or `popd`, wherever it appears in the call
  - A command substitution, a subshell, or a control-flow block such as `if` or `for`
  - A redirection, such as `docker build . > build.log` or a `<<EOF` heredoc, other than one that only duplicates a file
    descriptor, as `2>&1` does
  - A command name that comes from a variable
  - A `git clone`, `git init`, `git worktree add`, `git worktree move`, or `git bundle create` with a path argument that
    is absolute, starts with `~`, or contains a `..` segment
- For example, `cd build && docker compose up` stays sandboxed under a `docker *` entry, and adding a `cd` entry doesn't
  change that. Under a `git *` entry, `git clone <url> vendor/lib` runs outside the sandbox, but `git clone <url>
  ~/tools` stays sandboxed, because a clone writes a whole tree of files, possibly executable ones, wherever its
  destination path points. If the clone can go inside your working directory, ask Claude to use a relative path with no
  `..` segment, such as `vendor/lib`.
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands),
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands)
- Entries from the settings scopes the session loads combine into one list unless the sandbox is admin-required. While
  it is, Claude Code ignores entries in `.claude/settings.json` and `.claude/settings.local.json`, so a cloned
  repository can't take commands out of the sandbox. Entries in managed settings, `--settings`, and your
  `~/.claude/settings.json` still apply, and no managed-only lock covers this list.
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
- An excluded command goes through the regular permission flow: read-only commands and commands your allow rules cover
  run without a prompt; in auto mode, the classifier reviews other excluded commands; in `bypassPermissions` mode, an
  excluded command runs without a prompt unless an ask rule matches it. Exclusion is a convenience, not a security
  boundary.
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands),
  [settings-reference › `sandbox.excludedCommands`](https://code.claude.com/docs/en/settings-reference#sandbox-excludedcommands)
- To confirm an entry matches, switch to Manual mode and ask Claude to run a matching command that changes something,
  such as `docker compose up -d`. The permission prompt is titled "Bash command (unsandboxed)".
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands)
- An excluded command runs with your full access. A broad entry such as `docker *` covers everything that tool can do.
  If you write a pattern that covers an interpreter, a script inside your working directory, or a tool that acts on a
  file there, as `docker compose` does with its compose file, Claude can write that file and then run it outside the
  sandbox. A narrower pattern leaves less that Claude can run outside the sandbox.
  [sandboxing › Run commands outside the sandbox with `excludedCommands`](https://code.claude.com/docs/en/sandboxing#run-commands-outside-the-sandbox-with-excludedcommands)

## Network isolation

- A sandboxed command has no direct route to the network. On Linux and WSL2, the command runs in a separate network
  namespace that has no connection to your network; on macOS, the Seatbelt sandbox framework by default blocks
  connections other than the one to the sandbox proxy.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- Claude Code runs the sandbox proxy on your machine, outside the sandbox, and directs commands to it with `HTTP_PROXY`,
  `HTTPS_PROXY`, `ALL_PROXY`, and related environment variables. The proxy checks the hostname of each connection
  against your allowed and denied domains.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- What a tool can reach depends on whether it uses the proxy: tools that read the proxy variables (`curl`, `npm`, `git`
  over HTTPS, and similar) connect once their host is allowed, and an `allowedDomains` entry with no port allows every
  port on that host; tools that ignore the proxy variables (plain `ssh`, most database drivers, and similar) can't
  connect, even to an allowed host; anything that isn't TCP (UDP, HTTP/3 over QUIC, and ICMP tools such as `ping`) can't
  leave the sandbox. [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- Your allowed domains start empty. If you choose Yes when prompted for a new host, Claude Code allows the host for the
  rest of the current session. If you choose "Yes, and don't ask again", Claude Code saves a `WebFetch(domain:...)`
  allow rule to your local settings, so the host stays allowed in future sessions; while the sandbox is admin-required,
  Claude Code saves the rule to your user settings, where it applies in every project.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- Pre-allow domains with `allowedDomains` to avoid the prompt entirely. Claude Code also pre-allows domains from
  `WebFetch(domain:...)` allow rules.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- In a `WebFetch(domain:...)` rule, the sandbox honors two wildcard forms: a leading `*.`, such as `*.example.com`, and
  a bare `*`. A wildcard in any other position, such as `WebFetch(domain:example.*)`, still matches fetches but has no
  effect on sandboxed commands.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- Sandboxed commands don't inherit WebFetch's built-in set of preapproved documentation domains. To let a sandboxed
  command reach a domain without a prompt, add the domain to `allowedDomains` or allow it with a `WebFetch(domain:...)`
  rule, which the sandbox also honors. WebFetch never reads the sandbox allowlist in return, so adding a domain to a
  sandbox or organization network allowlist doesn't stop WebFetch from prompting for it.
  [tools-reference › WebFetch tool behavior](https://code.claude.com/docs/en/tools-reference#webfetch-tool-behavior)
- Corporate proxy: when your network requires outbound traffic to go through a corporate proxy, set `HTTPS_PROXY`,
  `HTTP_PROXY`, and `NO_PROXY` as
  [proxy configuration](https://code.claude.com/docs/en/network-config#proxy-configuration) describes, in the `env`
  block of your settings so that
  [background agents](https://code.claude.com/docs/en/network-config#set-network-variables-in-settings-not-the-shell)
  get them too, or in the environment you launch Claude Code from. Claude Code enforces the domain allowlist and then
  tunnels allowed connections through that upstream proxy. `http://` and `https://` proxy URLs work, with basic
  authentication in the URL if you need it.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- The built-in proxy enforces the allowlist based on the requested hostname and, by default, does not terminate or
  inspect TLS traffic. The experimental `network.tlsTerminate` setting makes the built-in proxy terminate TLS itself,
  which `mask` credential entries require. Use a custom proxy if your threat model requires TLS inspection.
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- When a sandboxed command connects to a host that isn't in your allowed domains, the command stays in the sandbox and
  waits for a decision. In an interactive terminal session, the decision depends on your permission mode:
  [sandboxing › Hosts outside your allowed domains](https://code.claude.com/docs/en/sandboxing#hosts-outside-your-allowed-domains)

  | Permission mode | What happens to the connection |
  | :- | :- |
  | `bypassPermissions` mode, and plan mode with [bypass permissions available](https://code.claude.com/docs/en/permission-modes#skip-all-checks-with-bypasspermissions-mode) | Allowed without a prompt |
  | Manual mode, `acceptEdits` mode, and plan mode otherwise | You get a prompt |
  | Auto mode | Refused unless the command [listed the host](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode) and the classifier approved the list |
  | `dontAsk` mode | Refused |

- With `strictAllowlist` or `allowManagedDomainsOnly` on, the built-in sandbox proxy refuses the connection in every
  permission mode. In `bypassPermissions` mode, hosts outside your allowed domains are allowed unless one of them is on.
  A connection to a host in `deniedDomains` is refused in every permission mode too.
  [sandboxing › Hosts outside your allowed domains](https://code.claude.com/docs/en/sandboxing#hosts-outside-your-allowed-domains)
- After a hostname passes the allowlist, the sandbox proxy resolves it and refuses the connection when the name resolves
  only to local addresses: loopback addresses such as `127.0.0.1`, link-local addresses such as the `169.254.169.254`
  cloud metadata endpoint, and addresses assigned to your own machine. The names `localhost` and `*.localhost` are
  allowed to resolve to loopback.
  [sandboxing › Hostnames that resolve to local addresses](https://code.claude.com/docs/en/sandboxing#hostnames-that-resolve-to-local-addresses)
- An allowed intranet hostname that resolves to a private range such as `10.0.0.0/8` connects. To let a name resolve to
  a refused address, add that IP address to `allowedDomains`, such as `"127.0.0.1:8080"`. The check applies to
  hostnames; your allowed domains and permission mode decide a connection to an IP address. The proxy also skips the
  check for connections it sends through an upstream corporate proxy, because that proxy resolves the name.
  [sandboxing › Hostnames that resolve to local addresses](https://code.claude.com/docs/en/sandboxing#hostnames-that-resolve-to-local-addresses)
- In auto mode with sandboxing on, Claude names the hosts a command needs on the command itself instead of triggering a
  network approval for each connection. Each Bash, PowerShell, or Monitor command that runs in the sandbox can carry a
  list of hosts beyond the sandbox's allowlist: a domain such as `registry.npmjs.org`, a wildcard such as
  `*.pythonhosted.org`, or an IP address, each with an optional `:port`. The classifier reviews the hosts together with
  the command.
  [sandboxing › Per-command allowed domains in auto mode](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode)
- An approved list opens those hosts for that one command alone, for as long as it runs. Nothing is added to your
  session's allowed hosts or your settings; the next command names its own hosts.
  [sandboxing › Per-command allowed domains in auto mode](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode)
- A command that carries hosts goes to the classifier instead of being approved by a permission rule or the sandbox's
  auto-allow mode. If an ask rule forces a prompt for the command, the permission dialog in your terminal lists the
  hosts beside it, and approving there covers both.
  [sandboxing › Per-command allowed domains in auto mode](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode)
- A per-command list widens only what the sandbox denies by default: `deniedDomains` entries still block. When
  `strictAllowlist` or `allowManagedDomainsOnly` locks the allowlist, Claude Code refuses per-command lists.
  [sandboxing › Per-command allowed domains in auto mode](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode)
- While per-command lists apply, Claude Code refuses a connection to a host that no approved command listed, without a
  prompt or a classifier check. The refusal names the host in the command's result, and Claude re-runs the command with
  the host added.
  [sandboxing › Per-command allowed domains in auto mode](https://code.claude.com/docs/en/sandboxing#per-command-allowed-domains-in-auto-mode)
- To match an IPv6 address in `allowedDomains`, `deniedDomains`, or a `WebFetch(domain:...)` rule, write the address in
  brackets: `"[::1]"` matches that address on every port, and `"[::1]:443"` matches it on port 443 only.
  [sandboxing › IPv6 addresses in domain lists](https://code.claude.com/docs/en/sandboxing#ipv6-addresses-in-domain-lists)
- An unbracketed entry such as `::1:443` is ambiguous between an address and an address with a port. In deny lists,
  Claude Code denies every reading the entry parses as; for an entry with no parseable reading, it blocks nothing. In
  allow lists, Claude Code never allows more than you wrote: it rewrites an ambiguous entry to its host-and-port reading
  when that reading parses cleanly, and may drop the entry entirely rather than widen the allowlist.
  [sandboxing › IPv6 addresses in domain lists](https://code.claude.com/docs/en/sandboxing#ipv6-addresses-in-domain-lists)
- To find ambiguous entries, run `claude doctor` in your terminal and look for the `Sandbox network domain entries have
  unreliable spellings` warning. Rewrite each ambiguous entry in the bracketed form.
  [sandboxing › IPv6 addresses in domain lists](https://code.claude.com/docs/en/sandboxing#ipv6-addresses-in-domain-lists)

## Network settings

- `sandbox.network` controls which hosts, ports, and sockets sandboxed commands can reach. It is an object with the
  sub-keys below, unset by default, so no domains are pre-allowed and your permission mode decides what happens to each
  new host. It can be set in any file; `strictAllowlist`, `allowManagedDomainsOnly`, and `tlsTerminate` are read from
  fewer sources, as their entries say.
  [settings-reference › `sandbox.network`](https://code.claude.com/docs/en/settings-reference#sandbox-network)

  ```json
  {
    "sandbox": {
      "network": {
        "allowedDomains": ["github.com", "*.npmjs.org"],
        "deniedDomains": ["uploads.github.com"],
        "allowLocalBinding": true
      }
    }
  }
  ```

- `sandbox.network.allowedDomains` pre-allows domains for outbound traffic from sandboxed commands, so the sandbox
  doesn't prompt for them. Wildcards such as `*.example.com` match subdomains, and an optional `:port` suffix limits an
  entry to one port; an entry without a port matches every port. It is an array of strings, each a domain, wildcard
  pattern, or IP literal, unset by default. It can be set in any file, with limits on project and local settings, and
  only from managed settings when `allowManagedDomainsOnly` is set.
  [settings-reference › `sandbox.network.allowedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-alloweddomains)

  ```json
  {
    "sandbox": {
      "network": {
        "allowedDomains": ["github.com", "*.npmjs.org", "api.example.com:443"]
      }
    }
  }
  ```

  This pre-allows GitHub on every port, every npm subdomain, and one API host on port 443 only.
- `sandbox.network.deniedDomains` blocks domains for outbound traffic from sandboxed commands, using the same wildcard,
  port, and IPv6 syntax as `allowedDomains`. A denied domain stays blocked even when an `allowedDomains` entry matches
  it too. It is an array of strings, unset by default, and can be set in any file. Claude Code merges this list from
  every settings source the session loads even when `allowManagedDomainsOnly` is set, so a developer can always tighten
  the deny list. An entry written with the trailing dot that marks a fully qualified domain name, such as
  `example.com.`, blocks the same connections as `example.com`.
  [settings-reference › `sandbox.network.deniedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-denieddomains)
- For the Monitor tool's WebSocket watch, Claude Code denies a host listed in `sandbox.network.deniedDomains` and, when
  `sandbox.network.allowManagedDomainsOnly` is set in managed settings, any host outside the managed allowlist. The
  `deniedDomains` list itself applies to sandboxed commands.
  [tools-reference › WebSocket source](https://code.claude.com/docs/en/tools-reference#websocket-source),
  [settings-reference › `sandbox.network.deniedDomains`](https://code.claude.com/docs/en/settings-reference#sandbox-network-denieddomains)
- `sandbox.network.strictAllowlist` denies sandboxed commands access to hosts outside the allowlist instead of prompting
  for approval. The allowlist is `allowedDomains` plus domains from `WebFetch(domain:...)` allow rules, or only the
  managed settings entries when `allowManagedDomainsOnly` is set. It is a Boolean, `false` by default, read from user or
  managed settings (and the `--settings` flag); a repository can't turn it on or off, and setting it in a repository's
  `.claude/settings.json` or `.claude/settings.local.json` has no effect.
  [settings-reference › `sandbox.network.strictAllowlist`](https://code.claude.com/docs/en/settings-reference#sandbox-network-strictallowlist),
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)
- With `strictAllowlist` `false`, unless another trusted settings file sets `true`, Claude Code decides a host outside
  the allowlist by permission mode: in auto mode it checks the host against the command's per-command allowed domains,
  in `dontAsk` mode it denies, in `bypassPermissions` mode and in interactive terminal plan-mode sessions where bypass
  is available it allows, and otherwise it asks you. When any of the honored sources sets it to `true`, it stays on.
  Claude Code enforces it for sandboxed commands only; in-process tools such as `WebFetch` still follow their permission
  rules.
  [settings-reference › `sandbox.network.strictAllowlist`](https://code.claude.com/docs/en/settings-reference#sandbox-network-strictallowlist)

  ```json
  {
    "sandbox": {
      "network": {
        "strictAllowlist": true
      }
    }
  }
  ```

- `sandbox.network.allowManagedDomainsOnly` locks the network allowlist to what managed settings define. It is a
  Boolean, `false` by default, read from managed settings only. With `true`, Claude Code honors only `allowedDomains`
  and `WebFetch(domain:...)` allow rules from managed settings, ignores domains from user, project, local, and
  `--settings` settings, and blocks a non-allowed domain automatically instead of prompting; with `false`, domains from
  other settings files can merge into the allowlist. While the key is `true`, the sandbox is admin-required.
  [settings-reference › `sandbox.network.allowManagedDomainsOnly`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowmanageddomainsonly),
  [sandboxing › Network isolation](https://code.claude.com/docs/en/sandboxing#network-isolation)

  ```json
  {
    "sandbox": {
      "network": {
        "allowManagedDomainsOnly": true,
        "allowedDomains": ["github.com", "*.npmjs.org"]
      }
    }
  }
  ```

- Locking network domains with `allowManagedDomainsOnly` and an empty managed domain list blocks all sandboxed outbound
  traffic.
  [claude-apps-gateway › Lock behavior across sources](https://code.claude.com/docs/en/claude-apps-gateway#lock-behavior-across-sources)
- `sandbox.network.allowUnixSockets` lists the Unix socket paths sandboxed commands can connect to on macOS. Claude Code
  ignores this list on Linux and WSL2, where the seccomp filter can't inspect socket paths; use `allowAllUnixSockets`
  there instead. It is an array of strings, each a socket path, unset by default so the macOS sandbox blocks every Unix
  socket, and can be set in any file with limits on project and local settings.
  [settings-reference › `sandbox.network.allowUnixSockets`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowunixsockets)

  ```json
  {
    "sandbox": {
      "network": {
        "allowUnixSockets": ["~/.ssh/agent-socket"]
      }
    }
  }
  ```

- A socket path can grant broad access: allowing `/var/run/docker.sock`, for example, lets a sandboxed command control
  the Docker daemon, which effectively grants access to the host system. Consider carefully any Unix sockets that you
  allow through the sandbox.
  [settings-reference › `sandbox.network.allowUnixSockets`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowunixsockets),
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- `sandbox.network.allowAllUnixSockets` lets sandboxed commands connect to every Unix socket, and on Linux and WSL2 also
  to VM sockets, the `AF_VSOCK` address family. On Linux and WSL2, the sandbox's seccomp filter blocks `socket(AF_UNIX,
  ...)` calls, so this is the only way to permit Unix sockets there; when the filter is missing, which `/sandbox`
  reports on its Dependencies tab, the sandbox doesn't block Unix-socket calls. On WSL2, `true` also reopens the interop
  socket that launches Windows binaries such as `cmd.exe` and `powershell.exe`. With `false`, the sandbox blocks
  Unix-socket connections: on macOS except the paths in `allowUnixSockets`, and on Linux and WSL2 through the seccomp
  filter when it's present. It is a Boolean, `false` by default, that can be set in any file with limits on project and
  local settings.
  [settings-reference › `sandbox.network.allowAllUnixSockets`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowallunixsockets)
- `sandbox.network.allowLocalBinding` lets sandboxed commands on macOS listen on network ports, for example to start a
  dev server, and connect to any port on localhost; with `false`, they can't listen on a port or connect directly to
  servers on localhost. Any port on localhost includes every other service listening there, and a localhost service
  that doesn't require authentication, such as a debugger, can then act for the command outside the sandbox. A command
  that listens on a non-loopback address accepts connections from other machines. The key has no effect on Linux and
  WSL2, where each sandboxed command has its own loopback interface. It is a Boolean, `false` by default, that can be
  set in any file with limits on project and local settings.
  [settings-reference › `sandbox.network.allowLocalBinding`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowlocalbinding),
  [sandboxing › A command fails to reach a server on localhost](https://code.claude.com/docs/en/sandboxing#a-command-fails-to-reach-a-server-on-localhost)
- `sandbox.network.allowMachLookup` lists additional XPC and Mach service names the macOS sandbox may look up. Tools
  that communicate over XPC, such as the iOS Simulator or Playwright, need their services listed here. It is an array of
  strings, each a service name; a single trailing `*` matches a prefix, and `"*"` alone matches every service. It is
  unset by default and can be set in any file, with limits on project and local settings.
  [settings-reference › `sandbox.network.allowMachLookup`](https://code.claude.com/docs/en/settings-reference#sandbox-network-allowmachlookup)

  ```json
  {
    "sandbox": {
      "network": {
        "allowMachLookup": ["com.apple.CoreSimulator.*"]
      }
    }
  }
  ```

- `sandbox.network.tlsTerminate` makes the sandbox proxy terminate TLS so it can read the contents of HTTPS requests. It
  is experimental: it terminates TLS at the proxy for `mask` credential substitution, which requires it, but does not
  add content filtering. Set `{}` to generate an ephemeral certificate authority for the session, or set `caCertPath`
  and `caKeyPath` (each a file path) to use your own. It is unset by default, so the proxy doesn't terminate or inspect
  TLS.
  [settings-reference › `sandbox.network.tlsTerminate`](https://code.claude.com/docs/en/settings-reference#sandbox-network-tlsterminate)
- `tlsTerminate` is read from user or managed settings; a repository can't switch it on or supply a certificate
  authority. When more than one honored source sets it, Claude Code uses the value from the highest-precedence source:
  managed settings, then the `--settings` flag, then user settings.
  [settings-reference › `sandbox.network.tlsTerminate`](https://code.claude.com/docs/en/settings-reference#sandbox-network-tlsterminate)

  ```json
  {
    "sandbox": {
      "network": {
        "tlsTerminate": {}
      }
    }
  }
  ```

## Proxies

- To inspect, filter, or log sandbox traffic with your own tooling, replace the built-in sandbox proxy with a proxy you
  run on the same machine. To route sandbox traffic through a corporate proxy elsewhere on your network, set
  `HTTPS_PROXY` instead, as the Corporate proxy entry under Network isolation describes, so that Claude Code's allowlist
  still applies.
  [sandboxing › Custom proxy configuration](https://code.claude.com/docs/en/sandboxing#custom-proxy-configuration)
- `sandbox.network.httpProxyPort` points the sandbox at your own HTTP proxy instead of the one Claude Code runs;
  `sandbox.network.socksProxyPort` points it at your own SOCKS5 proxy. Each is a number, a local TCP port, unset by
  default so Claude Code runs its own proxy. With only one of the two set, Claude Code still runs its own proxy for the
  other protocol.
  [settings-reference › `sandbox.network.httpProxyPort`](https://code.claude.com/docs/en/settings-reference#sandbox-network-httpproxyport),
  [settings-reference › `sandbox.network.socksProxyPort`](https://code.claude.com/docs/en/settings-reference#sandbox-network-socksproxyport)

  ```json
  {
    "sandbox": {
      "network": {
        "httpProxyPort": 8080,
        "socksProxyPort": 8081
      }
    }
  }
  ```

- If you set a port and also set `HTTPS_PROXY` or `HTTP_PROXY`, Claude Code doesn't forward what sandboxed commands send
  to your proxy on to the proxy those variables name. To reach a corporate proxy, configure your own proxy to forward to
  it. [sandboxing › Custom proxy configuration](https://code.claude.com/docs/en/sandboxing#custom-proxy-configuration)
- Which files can set a port depends on your other sandbox settings; the first case that matches applies, and Claude
  Code ignores a port set anywhere else. If `allowManagedDomainsOnly` is on: managed settings only. If the sandbox is
  admin-required, or a narrower network lock applies: managed settings, `--settings`, and user settings. Otherwise: any
  settings file.
  [sandboxing › Custom proxy configuration](https://code.claude.com/docs/en/sandboxing#custom-proxy-configuration),
  [settings-reference › `sandbox.network.httpProxyPort`](https://code.claude.com/docs/en/settings-reference#sandbox-network-httpproxyport)
- Once either port applies, your proxy is responsible for filtering everything sent to it. Claude Code's own network
  controls, such as `allowedDomains`, `deniedDomains`, `strictAllowlist`, approval prompts, and the local-address check,
  stop applying to that traffic. A sandboxed command can connect to either proxy, so if you set only one port, Claude
  Code's domain lists on the other proxy don't limit what the command reaches through yours.
  [sandboxing › Custom proxy configuration](https://code.claude.com/docs/en/sandboxing#custom-proxy-configuration)

## Permission rules and permission modes

- Sandboxing, permission rules, and permission modes are complementary layers.
  [sandboxing › How sandboxing relates to permissions and permission modes](https://code.claude.com/docs/en/sandboxing#how-sandboxing-relates-to-permissions-and-permission-modes)
- Claude Code evaluates permission decisions before a command runs, based on the command string and, in auto mode, a
  separate classifier's judgment about whether the command is safe. The operating system enforces the sandbox boundary
  on the running process, so it holds regardless of what the model chose to run and even if an allowed command does more
  than its name suggests. [sandboxing › Permission rules](https://code.claude.com/docs/en/sandboxing#permission-rules)
- Filesystem and network restrictions are configured through both sandbox settings and permission rules, and paths and
  domains from both are merged into the final sandbox configuration:
  [sandboxing › Permission rules](https://code.claude.com/docs/en/sandboxing#permission-rules)

  | Setting or rule | What it does |
  | :- | :- |
  | `sandbox.filesystem.allowWrite` | Grants subprocess write access to paths outside the working directory |
  | `sandbox.filesystem.denyWrite` and `sandbox.filesystem.denyRead` | Block subprocess access to specific paths |
  | `sandbox.filesystem.allowRead` | Re-allows reading specific paths within a `denyRead` region |
  | [`sandbox.filesystem.disabled`](https://code.claude.com/docs/en/sandboxing#disable-filesystem-isolation) | Turns the filesystem layer off entirely while keeping network isolation |
  | `Edit` allow rules | Grant write access to specific paths, the same way `sandbox.filesystem.allowWrite` does |
  | `Read` and `Edit` deny rules | Block access to specific files or directories |
  | `WebFetch(domain:...)` allow and deny rules | Control domain access |
  | Sandbox `allowedDomains` | Controls which domains Bash commands can reach |
  | Sandbox `deniedDomains` | Blocks specific domains even when a broader `allowedDomains` wildcard would otherwise permit them |

- `/sandbox` is not a permission mode. Permission modes decide whether a tool call runs and whether you are prompted
  first, while the sandbox restricts what a Bash command can access once it runs. They differ in what they control and
  what replaces the per-action prompt:
  [sandboxing › Permission modes](https://code.claude.com/docs/en/sandboxing#permission-modes)

  | | What it controls | What replaces the prompt |
  | :- | :- | :- |
  | `/sandbox` | What a Bash command can access once it runs | The sandbox boundary itself, in [auto-allow mode](https://code.claude.com/docs/en/sandboxing#sandbox-modes) |
  | [Auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode) | Whether each tool call runs | A classifier that reviews actions |
  | `--dangerously-skip-permissions` | Whether each tool call runs | Nothing. [Protected path](https://code.claude.com/docs/en/permission-modes#protected-paths) checks are also skipped; the [actions no mode auto-approves](https://code.claude.com/docs/en/permission-modes#actions-no-mode-auto-approves) still apply |

- The sandbox's auto-allow mode is separate from auto mode: auto-allow approves Bash commands because the sandbox
  boundary contains them, while auto mode uses a classifier to review actions. The two work independently and can be
  combined, with the exceptions listed under Sandbox modes. Permission modes and sandbox pairings with the flags that
  start each one are in [Common setups](https://code.claude.com/docs/en/permission-modes#common-setups).
  [sandboxing › Permission modes](https://code.claude.com/docs/en/sandboxing#permission-modes)

## Enforcing the sandbox for an organisation

- The built-in Bash sandbox is the only isolation approach Claude Code enforces itself. A dev container is a convention
  rather than an enforcement boundary, because Claude Code does not require a container; to stop developers running
  Claude Code outside one, use your organization's device management or software allowlisting tools.
  [sandbox-environments › Enforce isolation across an organization](https://code.claude.com/docs/en/sandbox-environments#enforce-isolation-across-an-organization)
- To require the sandbox for every developer, deliver the `sandbox` keys through managed settings, either as a file
  managed by your MDM or through server-managed settings on claude.ai. This managed settings configuration enables the
  sandbox, refuses to start Claude Code when the platform is unsupported or a dependency is missing, and prevents the
  model from retrying commands outside the sandbox:
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)

  ```json
  {
    "sandbox": {
      "enabled": true,
      "failIfUnavailable": true,
      "allowUnsandboxedCommands": false
    }
  }
  ```

- Add `excludedCommands` for any organization-approved tools that must run without isolation, because this configuration
  stops a repository's settings from taking commands out of the sandbox. Add `sandbox.credentials` entries for
  credential directories such as `~/.aws` and `~/.ssh` and for secret environment variables, since the default read
  policy still allows them.
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- This configuration sandboxes the commands Claude runs; a command a developer types at the `!` shell-mode prompt still
  runs outside the sandbox.
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- On a platform the sandbox doesn't support, Claude Code doesn't start with `failIfUnavailable` on. The sandbox doesn't
  run on native Windows, so with `failIfUnavailable` set, Claude Code exits at startup on those machines. If your fleet
  includes Windows hosts, deliver the configuration by operating system, through your MDM or as a managed settings file
  on macOS and Linux machines only (server-managed settings apply to all users in the organization), or move Windows
  users into a supported environment by having them run Claude Code inside WSL2 or a container.
  [sandboxing › Enforce sandboxing with managed settings](https://code.claude.com/docs/en/sandboxing#enforce-sandboxing-with-managed-settings)
- When managed settings set a Boolean key such as `enabled` or `failIfUnavailable`, Claude Code uses the managed value
  and ignores anything a developer sets locally. For array keys such as `allowRead`, Claude Code merges entries from the
  scopes the session loads, so a developer can append entries that widen the policy unless a lock covers that key.
  [sandboxing › Keep developers from widening the policy](https://code.claude.com/docs/en/sandboxing#keep-developers-from-widening-the-policy)
- Unless managed settings set them, a developer's user settings or `--settings` can turn on the following keys, and a
  repository's `.claude/settings.json` can too, unless the sandbox is admin-required. Each one weakens the sandbox, so
  set it to `false` in managed settings if you don't want it used: `enableWeakerNestedSandbox`,
  `enableWeakerNetworkIsolation`, `network.allowAllUnixSockets`, `network.allowLocalBinding`, `allowAppleEvents` (which
  a repository can't turn on), and `allowNestedUserNamespaces` (which a repository can't turn on).
  [sandboxing › Keep developers from widening the policy](https://code.claude.com/docs/en/sandboxing#keep-developers-from-widening-the-policy)
- Locks that apply without an admin-required sandbox: some settings make Claude Code ignore the repository keys that
  directly override one restriction. Each has this effect only when you set it in a file its row names, and the
  repository's other sandbox settings still apply.
  [sandboxing › Locks that apply without an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#locks-that-apply-without-an-admin-required-sandbox)

  | Setting | Where you set it | What Claude Code ignores in a repository's settings |
  | :- | :- | :- |
  | `network.deniedDomains` or a `WebFetch(domain:...)` deny rule | Managed settings, `--settings` | `httpProxyPort` and `socksProxyPort` |
  | `network.strictAllowlist` | Managed settings, `--settings`, user settings | The proxy ports, `allowedDomains`, and `WebFetch(domain:...)` allow rules |
  | `filesystem.denyRead`, a `Read(...)` deny rule, or a `credentials.files` entry | Managed settings, `--settings` | An `allowRead`, `allowWrite`, `Edit(...)` allow, or `additionalDirectories` entry at or under a path that managed settings, `--settings`, or user settings deny reading, or a glob that could match one |

- These locks change what sandboxed commands can reach. The WebFetch tool and Claude's file tools still follow a
  repository's rules and additional directories.
  [sandboxing › Locks that apply without an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#locks-that-apply-without-an-admin-required-sandbox)

## Repository settings under an admin-required sandbox

- The sandbox is admin-required while one of these settings is in effect: `allowUnsandboxedCommands` set to `false` in
  managed settings, or with the `--settings` flag unless managed settings set it to `true`; or `allowManagedDomainsOnly`
  set to `true` in managed settings. These settings don't turn the sandbox on, so set `enabled` as well.
  [sandboxing › Repository settings under an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
- While the sandbox is admin-required, Claude Code takes the settings that loosen it only from managed settings, the
  `--settings` flag, and each developer's `~/.claude/settings.json`. It ignores these settings in a repository's
  `.claude/settings.json` and `.claude/settings.local.json`:
  [sandboxing › Repository settings under an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)

  | Repository setting | What Claude Code ignores |
  | :- | :- |
  | `excludedCommands`, `ignoreViolations`, `network.allowedDomains`, `network.allowUnixSockets`, `network.allowMachLookup`, `network.httpProxyPort`, `network.socksProxyPort` | Every entry |
  | `filesystem.allowWrite`, `Edit(...)` allow rules, `permissions.additionalDirectories` | The write access each entry gives sandboxed commands. Claude's file tools still follow the `Edit(...)` rules and additional directories |
  | `WebFetch(domain:...)` allow rules | The host each rule adds to the sandbox allowlist. The WebFetch tool still follows the rule |
  | `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`, `network.allowAllUnixSockets`, `network.allowLocalBinding` | `true`. A `false` still applies |
  | `enabled`, `failIfUnavailable` | `false`, when the developer's `~/.claude/settings.json` sets `true` |
  | `filesystem.allowRead` | An entry at or under a path that managed settings, `--settings`, or user settings deny reading, or a glob that could match one |

- These settings still apply while the sandbox is admin-required. In a repository's files: deny entries and the
  `autoAllowBashIfSandboxed` value; set the key in managed settings to keep a repository from changing it. In a
  developer's own settings: the settings in the table still apply from `~/.claude/settings.json` or `--settings`, unless
  a managed-only lock such as `allowManagedDomainsOnly` covers them; most of them, such as `excludedCommands` and
  `filesystem.allowWrite`, have no managed-only lock.
  [sandboxing › Repository settings under an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)
- The configuration under Enforce sandboxing with managed settings makes the sandbox admin-required. Add the
  `excludedCommands`, `allowWrite`, and socket entries that your approved tools need to managed settings, because a
  repository can't supply them.
  [sandboxing › Repository settings under an admin-required sandbox](https://code.claude.com/docs/en/sandboxing#repository-settings-under-an-admin-required-sandbox)

## Settings for special environments

- `sandbox.enableWeakerNestedSandbox` runs the Linux sandbox inside an unprivileged Docker container, where bubblewrap
  can't mount a fresh `/proc`. Instead the inner sandbox bind-mounts the container's existing `/proc`, which exposes
  process information that a fresh mount would hide. This considerably weakens security; use it only when the outer
  container already provides the isolation you need. It is a Boolean, `false` by default (a fresh `/proc` doesn't work
  in an unprivileged Docker container), can be set in any file with limits on project and local settings, and is Linux
  and WSL2 only.
  [settings-reference › `sandbox.enableWeakerNestedSandbox`](https://code.claude.com/docs/en/settings-reference#sandbox-enableweakernestedsandbox),
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- `sandbox.enableWeakerNetworkIsolation` lets sandboxed commands on macOS reach the system TLS trust service,
  `com.apple.trustd.agent`. Go-based tools such as `gh`, `gcloud`, and `terraform` need it to verify TLS certificates
  when you use `network.httpProxyPort` with a MITM proxy and a custom CA. This reduces security by opening a potential
  data exfiltration path through the trust service. It is a Boolean, `false` by default, can be set in any file with
  limits on project and local settings. If you don't use a MITM proxy, list the failing tools in `excludedCommands`
  instead.
  [settings-reference › `sandbox.enableWeakerNetworkIsolation`](https://code.claude.com/docs/en/settings-reference#sandbox-enableweakernetworkisolation)
- `sandbox.allowAppleEvents` lets sandboxed commands on macOS send Apple Events, which `open`, `osascript`, and tools
  that open URLs in a browser need; without it they fail with error `-600`. It removes code-execution isolation:
  sandboxed commands can launch other applications unsandboxed with no user prompt, and can send AppleScript commands to
  running applications such as Terminal, subject to the per-app macOS automation-consent prompt (TCC). It is a Boolean,
  `false` by default, and a user or managed setting that is only honored from user, managed, or CLI settings; project
  settings cannot enable it. To keep isolation and still run one such tool, add it to `excludedCommands` instead.
  [settings-reference › `sandbox.allowAppleEvents`](https://code.claude.com/docs/en/settings-reference#sandbox-allowappleevents),
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- `sandbox.allowNestedUserNamespaces` lets sandboxed commands on Linux and WSL2 create user namespaces, which Chromium's
  and Electron's own sandbox, a nested bubblewrap, and `unshare` need. By default sandboxed commands can't create user
  namespaces. If you set it to `true`, you turn off a security boundary: code from a sandboxed command can end up
  running outside the sandbox. For rootless Podman or Buildah, use `excludedCommands` instead, because the sandbox stops
  them in other ways too. It is a Boolean, `false` by default.
  [settings-reference › `sandbox.allowNestedUserNamespaces`](https://code.claude.com/docs/en/settings-reference#sandbox-allownestedusernamespaces),
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- A `true` for `allowNestedUserNamespaces` counts from `~/.claude/settings.json`, JSON passed with `--settings`, or
  managed settings; Claude Code ignores a `true` in a project's `.claude/settings.json` or
  `.claude/settings.local.json`. In a session with `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` set to `1`, Claude Code ignores a
  `true` from every source. A `false` counts from any file, by settings precedence; with `false`, the key allows nothing
  extra and the sandbox's default applies.
  [settings-reference › `sandbox.allowNestedUserNamespaces`](https://code.claude.com/docs/en/settings-reference#sandbox-allownestedusernamespaces)
- With `allowNestedUserNamespaces` on, don't rely on any of the sandbox's restrictions, including protected paths and
  `credentials.files` entries, to stop a malicious command. In auto-allow mode, that command can run without a
  permission prompt. If your organization has a security team, check with them before you turn the key on.
  [settings-reference › `sandbox.allowNestedUserNamespaces`](https://code.claude.com/docs/en/settings-reference#sandbox-allownestedusernamespaces)

- `sandbox.ripgrep` points the sandbox at a ripgrep binary of your own, for example when your platform needs a
  differently built `rg`. It is an object with `command` (the path to the ripgrep binary) and optional `args` (an array
  of arguments to prepend). Scope: user or managed settings. It is unset by default, so the sandbox uses the same
  ripgrep binary as Claude Code: the bundled binary unless you set `USE_BUILTIN_RIPGREP` to `0`.
  [settings-reference › `sandbox.ripgrep`](https://code.claude.com/docs/en/settings-reference#sandbox-ripgrep)

  ```json
  {
    "sandbox": {
      "ripgrep": {
        "command": "/usr/local/bin/rg"
      }
    }
  }
  ```

## Security limitations and scope

- Sandboxing reduces risk but is not a complete isolation boundary.
  [sandboxing › Limitations](https://code.claude.com/docs/en/sandboxing#limitations)
- You are responsible for ensuring that only trusted domains are allowed in your policy.
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- Allowing broad domains such as `github.com` can create paths for data exfiltration. Because the proxy makes its allow
  decision from the client-supplied hostname without inspecting TLS, code running inside the sandbox can potentially use
  domain fronting or similar techniques to reach hosts outside the allowlist. If your threat model requires stronger
  guarantees, configure a custom proxy that terminates TLS and inspects traffic, and install its CA certificate inside
  the sandbox. [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)
- Filesystem permission escalation: overly broad filesystem write permissions can enable privilege escalation attacks.
  Allowing writes to directories containing executables in `$PATH`, system configuration directories, or user shell
  configuration files such as `.bashrc` or `.zshrc` can lead to code execution in different security contexts when other
  users or system processes access these files.
  [sandboxing › Security limitations](https://code.claude.com/docs/en/sandboxing#security-limitations)

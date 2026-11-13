# Permissions

Writing permission rules: the `permissions` key, `allow`, `ask` and `deny` rules, their syntax and wildcards, the
tool-specific rules, working directories, workspace trust and managed-only rules.

## Contents

- How prompts, saved rules and rule order work
- The `permissions` key and its arrays
- Rule syntax and wildcards
- Bash rules
- PowerShell rules
- Read and Edit rules
- Symlinks
- Network paths
- WebFetch rules
- MCP rules
- Cd rules
- Rules for other tools
- Working directories
- Moving the session with `/cd`
- Project allow rules and workspace trust
- Managed-only permission rules
- How permissions meet the sandbox
- Blocking reads outside the working directories
- Command-line flags

## How prompts, saved rules and rule order work

- The table shows, for each tool type, whether Manual mode asks before the action runs and what "Yes, and don't ask again" does. The other permission modes change which of these ask you. [permissions › Permission system](https://code.claude.com/docs/en/permissions#permission-system)

  | Tool type | Example | Approval required | "Yes, and don't ask again" behavior |
  | :- | :- | :- | :- |
  | Read-only | File reads, Grep | No, within the working directory and additional directories | N/A |
  | Bash commands | Shell execution | Yes, except a built-in set of read-only commands | Permanently per repository and command |
  | File modification | Edit/write files | Yes | Until session end |
  | Web fetch | WebFetch | Yes, except a built-in set of preapproved documentation domains | Permanently per repository and domain |
  | Web search | WebSearch | Yes | Permanently per repository |

- When you choose "Yes, and don't ask again" and the approval saves permanently, such as for a Bash command or a WebFetch domain, Claude Code saves the rule to `.claude/settings.local.json`. The rule applies to future sessions anywhere in that repository, including sessions started in subdirectories and in worktrees. A file-modification approval isn't saved to the file: it lasts until the session ends. [permissions › Permission system](https://code.claude.com/docs/en/permissions#permission-system)
- Sometimes a permission prompt offers only a one-time approval, with no "don't ask again" option and no option to allow the action for the rest of the session. Claude Code offers those options only when the prompt can show you everything they would allow, so a rule you save from a prompt covers only what its option named. When a prompt offers only the one-time approval, approve the action once, or add the rule yourself in `/permissions`. [permissions › Permission system](https://code.claude.com/docs/en/permissions#permission-system)
- On most permission prompts, including Bash, PowerShell, file, and MCP tool prompts, move to **Yes** or **No** and press `Tab` to open a comment field on that option. WebFetch and browser prompts don't offer the field, and the options that allow the action for the rest of the session or save a rule don't take one either. [permissions › Add a comment when you answer a permission prompt](https://code.claude.com/docs/en/permissions#add-a-comment-when-you-answer-a-permission-prompt)
- With the comment field open, `Enter` submits your answer with the comment attached (an empty field submits no comment), and `Tab` closes the field without answering, keeping the text you typed and still sending it if you answer with that option. On a file prompt, such as an Edit or Write prompt, `Shift+Tab` closes the field the same as `Tab`. [permissions › Add a comment when you answer a permission prompt](https://code.claude.com/docs/en/permissions#add-a-comment-when-you-answer-a-permission-prompt)
- Claude Code delivers the comment by answer. **Yes**: it runs the action, then sends your comment to Claude after the result. **No**: it sends your comment to Claude as the reason for the denial and Claude continues working; a **No** without a comment on a prompt from the main conversation stops the turn. [permissions › Add a comment when you answer a permission prompt](https://code.claude.com/docs/en/permissions#add-a-comment-when-you-answer-a-permission-prompt)
- `/permissions` lists all permission rules and the `settings.json` file each rule comes from. You can open it while Claude is working: when you add or remove a rule, Claude Code applies the change starting with Claude's next tool call in the same turn. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- `/fewer-permission-prompts` is a bundled skill that scans your recent transcripts for common read-only Bash and MCP tool calls and adds a prioritized allowlist to the project `.claude/settings.json`, to reduce permission prompts. [best-practices › Change the permission mode](https://code.claude.com/docs/en/best-practices#change-the-permission-mode) [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- The `/permissions` dialog lets you view rules by scope, add or remove rules and manage working directories, and it has the alias `/allowed-tools`. [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- Allow rules let Claude Code use the specified tool without manual approval, ask rules prompt for confirmation whenever Claude Code tries to use it, and deny rules prevent Claude Code from using it. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- Rules are evaluated in order: deny, then ask, then allow. The first match in that order determines the outcome, and rule specificity doesn't change the order. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- A broad deny rule like `Bash(aws *)` blocks every matching call, including calls that also match a narrower allow rule like `Bash(aws s3 ls)`: an allow rule can't carve an exception out of a deny rule. The same precedence applies between ask and allow: a matching ask rule prompts even when a more specific allow rule also matches the same call. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- A bare tool name in a deny rule, like `Bash`, removes the tool from Claude's context entirely, so Claude never sees it; if you add such a rule mid-session, Claude can't call the tool from its next tool call on. A scoped rule like `Bash(rm *)` leaves the tool available and blocks matching calls when Claude attempts them. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- Bare-name removal applies to every tool except `EndConversation` (a deny or ask rule can't block it while any other tool remains; see Rules for other tools). [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- Claude Code enforces permission rules, not the model. Instructions in your prompt or `CLAUDE.md` shape what Claude tries but don't change what Claude Code allows. To grant or revoke access, use `/permissions`, the rules described here, a permission mode, or a PreToolUse hook. [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)
- If a tool is denied at any level, no other level can allow it: a managed settings deny can't be overridden by `--allowedTools`, and `--disallowedTools` can add restrictions beyond what managed settings define. [permissions › Settings precedence](https://code.claude.com/docs/en/permissions#settings-precedence)
- The same holds across settings scopes: if user settings allow a permission and project settings deny it, the deny rule blocks it, and a user-level deny blocks a project-level allow, because deny rules from any scope are evaluated before allow rules. [permissions › Settings precedence](https://code.claude.com/docs/en/permissions#settings-precedence)
- Administrators deploy managed settings that user and project settings can't override, apart from a few security-sensitive keys. [permissions › Managed settings](https://code.claude.com/docs/en/permissions#managed-settings)

## The `permissions` key and its arrays

- `permissions` controls which tools Claude can use without asking, which ones always prompt, and which ones are blocked, and sets the permission mode a session starts in; every `permissions.*` key nests under it. Its scope is any settings file, its type is an object with `allow`, `ask`, `deny`, `additionalDirectories`, `blockReadsOutsideWorkingDirectories`, `defaultMode`, `disableBypassPermissionsMode` and `disableAutoMode`, and it is unset by default. [settings-reference › `permissions`](https://code.claude.com/docs/en/settings-reference#permissions)

```json
{
  "permissions": {
    "allow": ["Bash(npm run *)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Read(./.env)"],
    "defaultMode": "acceptEdits"
  }
}
```

- `permissions.allow` lists the tool uses Claude Code approves without asking you. Scope: any file. Type: array of permission rule strings. Default: unset. `--allowedTools` adds allow rules for one session. [settings-reference › `permissions.allow`](https://code.claude.com/docs/en/settings-reference#permissions-allow)
- `permissions.ask` lists the tool uses that prompt you for confirmation even in a permission mode that would otherwise approve them, such as `acceptEdits` or `bypassPermissions`. Scope: any file. Type: array of permission rule strings. Default: unset. [settings-reference › `permissions.ask`](https://code.claude.com/docs/en/settings-reference#permissions-ask)
- `permissions.deny` lists the tool uses Claude Code blocks. Use it for files that hold API keys, secrets, or environment values: Claude Code excludes matching files from file discovery and search results, denies reads of them, and blocks the Edit and Write tools on the matching paths. Scope: any file. Type: array of permission rule strings. Default: unset. `--disallowedTools` adds deny rules for one session alongside this key. Claude Code applies `Read` deny rules to the built-in Grep and Glob tools on a best-effort basis, and a Bash search such as `grep -r` or `find` over a directory that contains denied files still includes them in its output. [settings-reference › `permissions.deny`](https://code.claude.com/docs/en/settings-reference#permissions-deny) [large-codebases › Block reads of generated and vendored code](https://code.claude.com/docs/en/large-codebases#block-reads-of-generated-and-vendored-code)

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Bash(curl *)"
    ]
  }
}
```

- The `deny` example denies reads of `.env` files, the `secrets` directory and a credentials file, and blocks `curl`
  commands. [settings-reference › `permissions.deny`](https://code.claude.com/docs/en/settings-reference#permissions-deny)

## Rule syntax and wildcards

- Permission rules follow the format `Tool` or `Tool(specifier)`. Parentheses inside the specifier are literal, so a command or path that contains them needs no escaping. [permissions › Permission rule syntax](https://code.claude.com/docs/en/permissions#permission-rule-syntax)
- To match all uses of a tool, use only the tool name without parentheses. `Bash(*)` is equivalent to `Bash`, and as a deny rule both forms remove the tool from Claude's context. [permissions › Match all uses of a tool](https://code.claude.com/docs/en/permissions#match-all-uses-of-a-tool)

  | Rule | Effect |
  | :- | :- |
  | `Bash` | Matches all Bash commands |
  | `WebFetch` | Matches all web fetch requests |
  | `Read` | Matches all file reads |

- The label shown for a tool in the transcript and permission dialog can differ from its canonical name: the tool labeled `Stop Task` in the transcript has the canonical name `TaskStop`. Permission rules don't match the label, so a rule written as `Stop Task` doesn't match. Use the canonical names listed in the tools reference. [permissions › Match all uses of a tool](https://code.claude.com/docs/en/permissions#match-all-uses-of-a-tool)
- Add a specifier in parentheses to match specific tool uses. [permissions › Use specifiers for fine-grained control](https://code.claude.com/docs/en/permissions#use-specifiers-for-fine-grained-control)

  | Rule | Effect |
  | :- | :- |
  | `Bash(npm run build)` | Matches the exact command `npm run build` |
  | `Read(./.env)` | Matches reading the `.env` file in the current directory |
  | `WebFetch(domain:example.com)` | Matches fetch requests to example.com |

- Wherever you name tools in permission rules (`permissions.allow` and `permissions.deny`, `/permissions`,
  `--allowedTools` and `--disallowedTools`), the rule format is `ToolName(specifier)`. The specifier depends on the tool, and several tools share a format. [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)

  | Rule format | Applies to | Details |
  | :- | :- | :- |
  | `Bash(npm run *)` | Bash, Monitor | Command pattern matching |
  | `PowerShell(Get-ChildItem *)` | PowerShell | Command pattern matching |
  | `Read(~/secrets/**)` | Read, Grep, Glob, LSP | Path pattern matching |
  | `Edit(/src/**)` | Edit, Write, NotebookEdit | Path pattern matching |
  | `Skill(deploy *)` | Skill | Skill name matching |
  | `Agent(Explore)` | Agent | Subagent type matching |
  | `WebFetch(domain:example.com)` | WebFetch | Domain matching |
  | `WebSearch` | WebSearch | No specifier; allow or deny the tool as a whole |

- Tools not listed in that table, such as `ExitPlanMode` or `ShareOnboardingGuide`, accept only the bare tool name with no specifier. [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)
- An `Edit(...)` allow rule also grants read access to the same path, so you don't need a matching `Read(...)` rule. [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)
- Deny and ask rules can match a top-level input parameter on any built-in tool with `Tool(param:value)`. A parameter rule matches when Claude calls the tool with that parameter set to that exact value. An allow rule for one parameter value wouldn't establish that the call is safe overall, so allow rules continue to use each tool's own specifier syntax. This works for any scalar parameter the tool accepts, such as `Bash(run_in_background:true)`, which matches Bash calls that run in the background. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- In a parameter rule the value supports `*` as a wildcard that matches any sequence of characters; without `*` the match is exact. Whitespace around the colon is ignored, and `--verbose` shows the exact parameter names and values in each tool call. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- The parameter name must be a direct field of the tool's input; fields nested inside an object or array are not matchable. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- Each rule names one parameter, so gating on two parameters takes two rules. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- A parameter the model omits is never matched, so a `*` value doesn't match a call that leaves the parameter unset. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- The value is compared against the literal input Claude sends, before any normalization. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- To match a parameter on an MCP tool, pass a deny rule with `--disallowedTools`. When Claude Code loads a settings file, it skips any `mcp__` rule that has parentheses, and lists the skipped rule in the invalid-settings dialog when an interactive session starts and in `claude doctor` output. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- You can't match a tool's primary content field with a parameter rule: `command` for Bash and PowerShell, `file_path` for Read, Edit, and Write, `path` for Grep and Glob, `notebook_path` for NotebookEdit, and `url` for WebFetch. A rule like `Bash(command:rm *)` would be bypassable by a compound command, so Claude Code ignores it and emits a startup warning. Use `Bash(rm *)`, `Read(./path)`, or `WebFetch(domain:host)` instead. [permissions › Match by input parameter](https://code.claude.com/docs/en/permissions#match-by-input-parameter)
- A `*` in a Bash rule matches any text, including spaces, so one rule covers a family of commands. A rule with no `*` matches one exact command. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)
- Put the `*` after the subcommand. In `git log --oneline main`, `git` is the program and `log` is the subcommand. Claude Code matches everything before the first `*` as written, so those words limit the rule: `Bash(git log *)` allows only `git log` commands, and `Bash(git *)` allows every git command. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)
- This configuration runs npm scripts and git commits without asking and refuses commands that begin with `git push`. A push written another way, such as `git -C . push`, isn't matched. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)"
    ],
    "deny": [
      "Bash(git push *)"
    ]
  }
}
```

- A `*` can go anywhere in the rule: at the start, in the middle, or at the end. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)

  | You write | Matches | Doesn't match |
  | :- | :- | :- |
  | `Bash(npm run build)` | `npm run build` | `npm run build --watch` |
  | `Bash(npm run *)` | `npm run build`, `npm run test --watch`, `npm run` | `npm install` |
  | `Bash(git log * main)` | `git log --oneline main`, `git log -5 main`, `git log --output=<file> main` | `git log main`, `git push origin main` |
  | `Bash(git * main)` | `git merge main`, `git push origin main`, `git -c core.fsmonitor=<script> diff main` | `git log` |
  | `Bash(* --version)` | `node --version`, `bash -c 'echo hi' --version` | `node -v` |
  | `Bash(ls *)` | `ls -la`, `ls` | `lsof` |
  | `Bash(ls*)` | `ls -la`, `lsof` | |
  | `Bash(* --help *)` | `npm --help x` | `npm --help` |

- Three matching rules produce those rows. The `*` stands in for whatever text is in its place: in `Bash(git * main)` it stands in for the subcommand, so every git subcommand and every option before it matches, including `-c`, which makes git run a program you name; in `Bash(* --version)` it stands in for the program, so any program matches. A `*` at the end with a space before it also matches the bare command, but only when the trailing `*` is the rule's only wildcard: `Bash(* --help *)` matches `npm --help x` but not `npm --help`. The space before a trailing `*` is part of the rule: `Bash(ls *)` requires a space after `ls`, so `lsof` doesn't match, while `Bash(ls*)` matches `lsof` too. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)
- The `:*` suffix is an equivalent way to write a trailing wildcard, so `Bash(ls:*)` matches the same commands as `Bash(ls *)`. It is only recognized at the end of a pattern: in `Bash(git:* push)` the colon is a literal character and won't match git commands. The permission dialog writes the space-separated form when you select "Yes, and don't ask again" for a command prefix. [permissions › Wildcard patterns](https://code.claude.com/docs/en/permissions#wildcard-patterns)
- Deny and ask rules also accept glob patterns in the tool-name position. The pattern must match the full tool name: `"*"` matches every tool, and `"mcp__*"` matches every MCP tool across all servers. A tool matched by a bare-name glob deny rule is removed from Claude's context, the same as a bare tool name (with the same `EndConversation` exception). [permissions › Tool name wildcards](https://code.claude.com/docs/en/permissions#tool-name-wildcards)

```json
{
  "permissions": {
    "deny": [
      "mcp__*"
    ]
  }
}
```

- Allow rules accept tool-name globs only after a literal `mcp__<server>__` prefix, and the server segment must be glob-free so the rule names a specific server you configured. `mcp__puppeteer__*` matches every tool from the `puppeteer` server, and `mcp__github__get_*` matches its `get_` tools. An unanchored allow glob such as `"*"`, `"B*"`, or `"mcp__*"` is skipped and doesn't auto-approve anything. [permissions › Tool name wildcards](https://code.claude.com/docs/en/permissions#tool-name-wildcards)

## Bash rules

- Bash rules match the whole command text, with `*` standing in for any text. [permissions › Bash](https://code.claude.com/docs/en/permissions#bash)
- Claude Code is aware of shell operators, so a rule like `Bash(safe-cmd *)` won't give it permission to run `safe-cmd && other-cmd`. The recognized command separators are `&&`, `||`, `;`, `|`, `|&`, `&`, and newlines. Every subcommand must be allowed for a compound command to run without a prompt, for example because it matches an allow rule or is a read-only command. [permissions › Compound commands](https://code.claude.com/docs/en/permissions#compound-commands)
- Deny and ask rules apply when any subcommand matches them, including a command nested inside a subshell, a command substitution, or a control-flow body such as a `for` loop. An ask rule like `Bash(git clean *)` still prompts for `cd /tmp && git clean -f` or `echo "$(git clean -f)"`, even in auto mode. [permissions › Compound commands](https://code.claude.com/docs/en/permissions#compound-commands)
- When `&&` or `||` has nothing after it, such as in `npm test &&`, Claude Code treats the command as unparseable and doesn't split it into subcommands for allow-rule matching, so a rule such as `Bash(npm *)` doesn't approve it. [permissions › Compound commands](https://code.claude.com/docs/en/permissions#compound-commands)
- When you approve a compound command with "Yes, and don't ask again", Claude Code saves a separate rule for each subcommand that requires approval, rather than a single rule for the full compound string. Approving `git status && npm test` saves a rule for `npm test`, so future `npm test` invocations are recognized regardless of what precedes the `&&`. A `cd` into a directory outside your working directories generates its own Read rule for that path. Up to 5 rules may be saved for a single compound command. [permissions › Compound commands](https://code.claude.com/docs/en/permissions#compound-commands)
- Before matching Bash rules, Claude Code strips a fixed set of wrappers, so `Bash(npm test *)` also matches `timeout 30 npm test`. The stripped wrappers are `timeout`, `time`, `nice`, `nohup`, and `stdbuf`, plus the shell builtins `command` and `builtin`, and zsh's `noglob`. Each runs its argument as the actual command. The query form `command -v` and zsh's `nocorrect` aren't stripped. [permissions › Wrappers](https://code.claude.com/docs/en/permissions#process-wrappers)
- Claude Code also strips a leading assignment of certain known-safe environment variables, so `Bash(npm test *)` matches `NODE_ENV=test npm test`. An allow rule won't match past an assignment of any other variable. A deny or ask rule matches past any leading assignment, so `Bash(rm *)` in deny still matches `FOO=bar rm -rf tmp/`. [permissions › Wrappers](https://code.claude.com/docs/en/permissions#process-wrappers)
- Bare `xargs` is also stripped, so `Bash(grep *)` matches `xargs grep pattern`. Stripping applies only when `xargs` has no flags: `xargs -n1 grep pattern` is matched as an `xargs` command, so rules written for the inner command do not cover it. [permissions › Wrappers](https://code.claude.com/docs/en/permissions#process-wrappers)
- The wrapper list is built in and not configurable. Development environment runners such as `direnv exec`, `devbox run`, `mise exec`, `npx`, and `docker exec` are not in it, so a rule like `Bash(devbox run *)` matches whatever comes after `run`, including `devbox run rm -rf .`. To approve work inside a runner, write a specific rule that includes both the runner and the inner command, such as `Bash(devbox run npm test)`, one rule per inner command. [permissions › Wrappers](https://code.claude.com/docs/en/permissions#process-wrappers)
- A prefix rule like `Bash(watch *)` or `Bash(find *)` can't auto-approve exec wrappers such as `watch`, `setsid`, `ionice`, and `flock`, or `find` with an action that runs commands, deletes files, or writes files (`-exec`, `-delete`, `-rm`, `-fprint`) or with `-files0-from`. In Manual mode they prompt. [permissions › Exec wrappers and `find` actions](https://code.claude.com/docs/en/permissions#exec-wrappers-and-find-actions)
- To approve a specific invocation that has no `*` in it, write an exact-match rule for the full command string, such as `Bash(find build -type f -delete)`. When the command has a `*`, as in `find . -name '*.tmp' -delete`, Claude Code reads the rule as a wildcard pattern, not an exact match, so the command still prompts: approve it each time, or use a PreToolUse hook that returns `"allow"` for it. [permissions › Exec wrappers and `find` actions](https://code.claude.com/docs/en/permissions#exec-wrappers-and-find-actions)
- A Bash rule matches the command text Claude writes, after Claude Code splits compound commands and strips wrappers. It doesn't match the same program invoked in a different form, so a deny or ask rule covers the invocation Claude usually produces and isn't a security boundary around the program. [permissions › What a Bash rule doesn't match](https://code.claude.com/docs/en/permissions#bash-rule-limits)

  | Rule | Stops | Doesn't stop |
  | :- | :- | :- |
  | `Bash(curl *)` | `curl https://example.com` | `/usr/bin/curl https://example.com`, `sh -c 'curl https://example.com'` |
  | `Bash(rm *)` | `rm -rf build/` | `/bin/rm -rf build/`, `bash -c 'rm -rf build/'` |
  | `Bash(git push *)` | `git push origin main` | `git -C . push origin main`, `git -c push.default=current push origin main`, `git 'push' origin main` |

- Your other rules and the permission mode decide the commands in the "Doesn't stop" column. For filesystem and network enforcement that doesn't depend on the command text, use sandboxing; to inspect the full command text with your own logic before it runs, use a PreToolUse hook. [permissions › What a Bash rule doesn't match](https://code.claude.com/docs/en/permissions#bash-rule-limits)
- Claude Code recognizes a built-in set of Bash commands as read-only and runs them without a permission prompt in every mode, except as `permissions.blockReadsOutsideWorkingDirectories` changes for paths outside your working directories. The set includes `ls`, `cat`, `echo`, `pwd`, `head`, `tail`, `grep`, `find`, `wc`, `which`, `diff`, `stat`, `du`, `cd`, and read-only forms of `git`. It is not configurable; to require a prompt for one of these commands, add an `ask` or `deny` rule for it. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- A redirect such as `ls > out.txt` adds a check on the target. Unquoted glob patterns are permitted for commands whose every flag is read-only, so `ls *.ts` and `wc -l src/*.py` run without a prompt. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- In Manual mode, commands from the read-only set still prompt in these cases. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
  - Unquoted globs for commands with write-capable or exec-capable flags, such as `find`, `sort`, `sed`, and `git`,
    because the glob could expand to a flag like `-delete`.
  - Read-only forms of `docker` that carry a flag selecting a different daemon, such as `-H`, `--context`, or Podman's
    `--url` and `--connection`.
  - `file` with `-m`/`--magic-file` or `-f`/`--files-from`, because those flags make `file` open the paths named in the
    flag's value.
  - `ps` when one of its arguments could act as the `e` option, such as in `ps auxe` or `ps aux -e`, because that option
    prints process environment variables. `ps aux` and `ps -ef` run without a prompt.
  - A command that sets, unsets, or loops over certain special shell variables, such as `PATH` or `IFS`, even when the
    rest of the command is read-only.
- A `cd` into a path inside your working directory or an additional directory is also read-only, and a compound command like `cd packages/api && ls` runs without a prompt when each part qualifies on its own. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- These combinations prompt even when each part is read-only. `cd` with `git` prompts when the `cd` changes into a different directory, since running `git` in a new directory can execute that directory's hooks; a `cd` whose target resolves to the current working directory is a no-op and doesn't trigger the prompt. `cd` with a redirect prompts when Claude Code can't determine which directory the redirect target resolves against after the `cd` runs; a command whose only redirect target is `/dev/null`, such as `cd app; grep -r pattern . 2>/dev/null`, doesn't prompt. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- Bash permission patterns that try to constrain command arguments are fragile. `Bash(curl http://github.com/ *)` intends to restrict curl to GitHub URLs but won't match options before the URL (`curl -X GET http://github.com/...`), a different protocol (`curl https://github.com/...`), redirects (`curl -L http://short.example.com/xyz`, which redirects to GitHub) or variables (`URL=http://github.com && curl $URL`). [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- For more reliable URL filtering, use deny rules to stop `curl`, `wget` and similar commands and allow domains through `WebFetch(domain:github.com)`; a deny rule doesn't match the same program by path or inside `sh -c`, so pair it with the sandbox network allowlist when the restriction must hold. Or use a PreToolUse hook that validates URLs in Bash commands. Describing allowed curl patterns in `CLAUDE.md` shapes what Claude tries but doesn't enforce a boundary. Using WebFetch alone doesn't prevent network access: if Bash is allowed, Claude can still use `curl`, `wget`, or other tools to reach any URL. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)
- Commands that fetch content from the web, such as `curl` and `wget`, are not auto-approved by default. In Manual mode they prompt like any other non-read-only Bash command, so you can approve once or add an explicit allow rule like `Bash(curl *)`. [security › Core protections](https://code.claude.com/docs/en/security#core-protections)
- When a command redirects output or input, Claude Code checks the redirect target against your file rules as if Claude wrote or read that file directly. [permissions › Redirections](https://code.claude.com/docs/en/permissions#redirections)
  - For `> file`, `>> file`, or `2> file`, the check covers your `Edit` allow and deny rules, protected paths, and the
    working directories. A rule such as `Bash(git commit *)` allows the command, not the target. A target that starts
    with `~` or contains a glob character needs your approval.
  - For `< file`, the check covers your `Read` allow and deny rules and the working directories. A target outside the
    working directories needs your approval unless an allow rule covers it. A target that contains a glob pattern, or a
    relative path that follows a `cd` in the same command, needs your approval even when an allow rule covers it.
- Targets with no file behind them aren't checked: `/dev/null`, file-descriptor forms such as `2>&1` and `<&3`, and here-docs and here-strings. [permissions › Redirections](https://code.claude.com/docs/en/permissions#redirections)
- Claude Code also checks the files a `tee` command writes, including in a pipeline such as `make | tee build.log`, against your `Edit` allow and deny rules, protected paths, and the working directories. An allow rule such as `Bash(tee *)` doesn't cover a destination outside the working directories. [permissions › Redirections](https://code.claude.com/docs/en/permissions#redirections)
- In Manual mode, Claude Code asks before running a Bash command it can't fully analyze, and doesn't treat it as read-only. Commands longer than 10,000 characters always prompt because they exceed what the analysis parses. An allow rule for part of a command, such as `Bash(git *)`, doesn't skip that prompt, and sandboxed commands can run without it. [permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands) [security › Additional safeguards](https://code.claude.com/docs/en/security#additional-safeguards)

## PowerShell rules

- PowerShell permission rules use the same shape as Bash rules, and a bare `PowerShell` or `PowerShell(*)` matches every command. [permissions › PowerShell](https://code.claude.com/docs/en/permissions#powershell)

```json
{
  "permissions": {
    "allow": [
      "PowerShell(Get-ChildItem *)",
      "PowerShell(git commit *)"
    ],
    "deny": [
      "PowerShell(Remove-Item *)"
    ]
  }
}
```

- Common aliases are canonicalized before matching, so a rule written for the cmdlet name also matches its aliases: `PowerShell(Get-ChildItem *)` matches `gci`, `ls`, and `dir`. Matching is case-insensitive. [permissions › PowerShell](https://code.claude.com/docs/en/permissions#powershell)
- Claude Code parses the PowerShell AST and checks each command in a compound command independently. Pipeline operators `|`, statement separators `;`, and on PowerShell 7+ the chain operators `&&` and `||` split a compound command into subcommands. Every subcommand must be allowed for the compound command to run without a prompt, for example by matching an allow rule. [permissions › PowerShell](https://code.claude.com/docs/en/permissions#powershell)
- On Windows with Git Bash installed, denying Bash also turns the PowerShell tool off for the session. This applies to scoped rules such as `Bash(git push *)` as well as a bare `Bash`, and to rules from one of your settings files or `--disallowedTools`, because a `Bash` rule doesn't restrict the PowerShell tool, which has its own permission rules. [tools-reference › Bash deny rules also turn off the PowerShell tool](https://code.claude.com/docs/en/tools-reference#bash-deny-rules-also-turn-off-the-powershell-tool)
- To keep the PowerShell tool on alongside a Bash deny rule, add a scoped `PowerShell` permission rule to a settings file, such as a `PowerShell(git push *)` deny rule; setting `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` in the environment or the `env` block of a settings file also does it. Without one of these, a scoped Bash deny rule leaves the Bash tool available, and Claude Code turns PowerShell off without a warning. A rule that removes the whole Bash tool leaves Claude with no shell tool for the session. [tools-reference › Bash deny rules also turn off the PowerShell tool](https://code.claude.com/docs/en/tools-reference#bash-deny-rules-also-turn-off-the-powershell-tool)

## Read and Edit rules

- To block Claude's file tools from reading a file or directory, add a `Read` deny rule for its path, such as `Read(./.env)` or `Read(./secrets/**)`. A `.claudeignore` file has no effect, so move its entries into `Read` deny rules. [permissions › Read and Edit](https://code.claude.com/docs/en/permissions#read-and-edit)
- `Edit` rules apply to all built-in tools that edit files. Claude makes a best-effort attempt to apply `Read` rules to all built-in tools that read files like Grep and Glob, to `@file` mentions in your prompts, and to the selection and open-file context that a connected IDE shares with Claude. [permissions › What `Read` and `Edit` rules cover](https://code.claude.com/docs/en/permissions#what-read-and-edit-rules-cover)
- A `Read(path)` deny rule also covers attachments, matching each one on either the named path or the file it resolves to, and Claude Code leaves an attachment out of the conversation when a rule matches it. `@`-mentions: a refused file leaves nothing in the conversation, and a directory's listing leaves out the file and directory names the rule matches. Pasted images: when you paste an image's path or drag an image file into your prompt in the terminal and the rule matches that path, Claude Code doesn't attach the image, and if the paste holds no other image the path stays in your prompt as text. Changed files that Claude Code re-reads after they change on disk and the selection and open-file context a connected IDE shares are covered too. [permissions › What `Read` and `Edit` rules cover](https://code.claude.com/docs/en/permissions#what-read-and-edit-rules-cover) [permissions › Attachments through a symlink](https://code.claude.com/docs/en/permissions#symlinks)
- A `Read` deny rule also blocks the Edit and Write tools on the same path, including creating a new file there. NotebookEdit isn't covered, so add an `Edit` deny rule for paths no tool may change. [permissions › What `Read` and `Edit` rules cover](https://code.claude.com/docs/en/permissions#what-read-and-edit-rules-cover)
- Read and Edit deny rules apply to Claude's built-in file tools, to file commands Claude Code recognizes in Bash, such as `cat`, `head`, `tail`, `sed`, and `tee`, and to the targets of Bash redirections such as `> file` and `< file`. They don't apply to a command that reads files without naming them, such as `grep -r pattern .` run from the directory that holds the file, or to arbitrary subprocesses that read or write files indirectly, like a Python or Node script that opens files itself. For OS-level enforcement that blocks all processes from accessing a path, enable the sandbox. [permissions › What `Read` and `Edit` rules cover](https://code.claude.com/docs/en/permissions#what-read-and-edit-rules-cover)
- Claude Code checks file permissions against `Edit(path)` and `Read(path)` rules only. If you write a path rule for `Write`, `NotebookEdit`, `Glob`, or legacy `MultiEdit`, Claude Code accepts the rule but never matches a read or edit against it. [permissions › `Write(path)`, `NotebookEdit(path)`, and `Glob(path)` rules never match](https://code.claude.com/docs/en/permissions#path-rules-that-never-match)
- Use `Edit(docs/**)` in place of `Write(docs/**)`, `NotebookEdit(docs/**)`, or `MultiEdit(docs/**)`, and `Read(docs/**)` in place of `Glob(docs/**)`. To match every use of the Write, NotebookEdit, or Glob tool regardless of path, write only the tool name. [permissions › `Write(path)`, `NotebookEdit(path)`, and `Glob(path)` rules never match](https://code.claude.com/docs/en/permissions#path-rules-that-never-match)
- Read and Edit rules both use gitignore pattern syntax with four distinct pattern types. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)

  | Pattern | Meaning | Example | Matches |
  | - | - | - | - |
  | `//path` | Absolute path from filesystem root | `Read(//Users/alice/secrets/**)` | `/Users/alice/secrets/**` |
  | `~/path` | Path from home directory | `Read(~/Documents/*.pdf)` | `/Users/alice/Documents/*.pdf` |
  | `/path` | Path relative to the settings source | `Edit(/src/**/*.ts)` | `<primary working directory>/src/**/*.ts` in project settings |
  | `path` or `./path` | Path relative to current directory | `Read(*.env)` | `<cwd>/*.env` |

- A pattern like `/Users/alice/file` isn't an absolute path: the single leading slash anchors at the settings source, not the filesystem root. Use `//Users/alice/file` for absolute paths. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- A `/path` pattern anchors at a directory associated with the settings source that defines it, so the same rule matches different locations depending on where you put it. A rule you add through `/permissions` follows the row for the settings file you save it to. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)

  | Rule defined in | `/path` resolves to |
  | :- | :- |
  | Project settings at `.claude/settings.json` | `<primary working directory>/path` |
  | Local settings at `.claude/settings.local.json` | `<primary working directory>/path` |
  | User settings at `~/.claude/settings.json` | `~/.claude/path` |
  | A file passed with `--settings <file>` | `<directory of file>/path` |
  | CLI flags or session rules | `<primary working directory>/path` |

- Local settings rules anchor at the session's primary working directory, not at the repository root where Claude Code stores the file. In a session started at the repository root the two are the same; in a worktree session, a shared rule such as `Edit(/src/**)` matches that worktree's own `src/` directory. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- A deny rule such as `Read(/secrets/**)` in user settings blocks `~/.claude/secrets/**`, not a `secrets` directory in your project. To write a rule in user settings that applies inside every project, use a `//` absolute path or a `~/` home-relative path instead. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- On Windows, paths are normalized to POSIX form before matching: `C:\Users\alice` becomes `/c/Users/alice`, so use `//c/**/.env` to match `.env` files anywhere on that drive, or `//**/.env` to match across all drives. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- Examples of anchored rules. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
  - `Edit(/docs/**)`: edits in `<primary working directory>/docs/`, not `/docs/` or `<primary working
    directory>/.claude/docs/`
  - `Read(~/.zshrc)`: reads your home directory's `.zshrc`
  - `Edit(//tmp/scratch.txt)`: edits the absolute path `/tmp/scratch.txt`
- A rule only matches files under its anchor; within that bound, matching depth depends on the pattern shape and, for single-segment directory patterns, the rule type. Bare filenames follow gitignore semantics and match at any depth, so `Read(.env)` and `Read(**/.env)` are equivalent. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)

  | Deny rule | Blocks | Does not block |
  | - | - | - |
  | `Read(.env)` or `Read(**/.env)` | any `.env` at or under the current directory | `.env` in a parent directory or another project |
  | `Read(//**/.env)` | any `.env` anywhere on the filesystem | nothing; the rule is anchored at the filesystem root |

- A relative pattern with a single directory segment, such as `src/**`, matches at different depths by rule type. As an allow rule, `Edit(src/**)` matches only `<cwd>/src` and the files under it; to allow a directory name at any depth, write `Edit(**/src/**)`. As a deny or ask rule, `Read(secrets/**)` matches a directory named `secrets` at any depth under the current directory, so the rule also applies to nested copies. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- Every other pattern shape matches at the same depth in every rule type: `Edit(/src/**)` and `Edit(src/components/**)` match only at their anchored location, while `Edit(**/src/**)` matches at any depth. In gitignore patterns, `*` matches within a single path segment and can appear at any position in the pattern, while `**` matches across directories. [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)
- Against a project with a top-level `src/` directory and a nested copy at `vendor/pkg/src/`: [permissions › How path patterns match](https://code.claude.com/docs/en/permissions#how-path-patterns-match)

  | Rule | Matches `src/app.ts` | Matches `vendor/pkg/src/lib.js` |
  | :- | :- | :- |
  | `Edit(src/**)` as an allow rule | Yes | No |
  | `Edit(src/**)` as a deny or ask rule | Yes | Yes |
  | `Edit(/src/**)` in any rule type | Yes | No |
  | `Edit(**/src/**)` in any rule type | Yes | Yes |

- Directory patterns that end `/**/*` rather than `/**` cover everything inside the directory but not the directory itself, so Claude can still list those directories or change into them, for example with `ls dist` or `cd build`. [large-codebases › Block reads of generated and vendored code](https://code.claude.com/docs/en/large-codebases#block-reads-of-generated-and-vendored-code)
- To share rules that block reads of generated or vendored code with everyone working in the repository, commit them to `.claude/settings.json` at the repository root if you start Claude there, or in each package's `.claude/` if you start from subdirectories; that file isn't inherited from parent directories. In `.claude/settings.local.json`, relative patterns like `Read(./**/vendor/**/*)` still anchor at the session's current working directory rather than the repository root, so if you start sessions from subdirectories, write the rules there as `//`-absolute paths, such as `Read(//absolute/path/to/repo/**/vendor/**/*)`. [large-codebases › Block reads of generated and vendored code](https://code.claude.com/docs/en/large-codebases#block-reads-of-generated-and-vendored-code)
- When you approve a file path with "Yes, and don't ask again", Claude Code escapes gitignore pattern characters in that path, such as `[`, `]`, and `*`, so the generated rule matches only the literal path you approved. Rules you write yourself aren't escaped. [permissions › Special characters and `!` negation](https://code.claude.com/docs/en/permissions#special-characters-and-negation)
- You don't need to escape parentheses in a path, so `Edit(./Finance (2024)/**)` matches the `Finance (2024)` folder as spelled. A deny or ask rule whose path isn't usable as a gitignore pattern still guards that exact path; an allow rule with an unusable pattern doesn't approve anything. [permissions › Special characters and `!` negation](https://code.claude.com/docs/en/permissions#special-characters-and-negation)
- A deny or ask pattern that starts with `!` is a gitignore negation. It carves the paths it matches out of the `path` or `./path` rules listed before it. In one settings file's `deny` list, `Read(*.env)` followed by `Read(!sample.env)` blocks every file whose name ends in `.env` at any depth, except files named `sample.env`. A `!` rule listed first carves nothing out. [permissions › Special characters and `!` negation](https://code.claude.com/docs/en/permissions#special-characters-and-negation)
- The carve-out reaches only rules from the same source: a `Read(!.env)` in project settings or in `--disallowedTools` doesn't cancel a `Read(./.env)` deny from managed settings or any other settings file. [permissions › Special characters and `!` negation](https://code.claude.com/docs/en/permissions#special-characters-and-negation)
- Two limits narrow what a `!` pattern can carve out. Claude Code reads a `!` pattern relative to the current directory even when `/`, `~/`, or `//` follows the `!`, so `Read(!~/notes/public/**)` carves nothing out of `Read(~/notes/**)`. And a carve-out can't reopen a file inside a directory that a rule blocks as a whole: with `Read(secrets/**)` and `Read(!secrets/public/**)`, Claude Code still blocks `secrets/public` along with the rest of `secrets`. [permissions › Special characters and `!` negation](https://code.claude.com/docs/en/permissions#special-characters-and-negation)

## Symlinks

- When a file path Claude requests goes through a symlink, the permission check covers two paths: the one Claude requested and the file it resolves to. This applies to symbolic links on macOS, Linux, and Windows, and to directory junctions on Windows. [permissions › Symlinks](https://code.claude.com/docs/en/permissions#symlinks)
- Allow rules apply only when both the requested path and the file it resolves to match, so a read through a symlink inside an allowed directory that points outside it doesn't match the rule. [permissions › How rules match a symlinked path](https://code.claude.com/docs/en/permissions#symlinks)
- Deny rules apply when either the requested path or the file it resolves to matches, so a symlink that points to a denied file is itself denied. With `Read(./project/**)` allowed and `Read(~/.ssh/**)` denied, a symlink at `./project/key` pointing to `~/.ssh/id_rsa` is blocked: the target fails the allow rule and matches the deny rule. [permissions › How rules match a symlinked path](https://code.claude.com/docs/en/permissions#symlinks)
- On macOS and Linux, a deny or ask rule written through a symlinked directory with a `//`, `~/`, or `/` pattern also applies at the directory's real location. On macOS, where `/etc` resolves to `/private/etc`, `Read(//etc/**)` blocks `/private/etc/hosts` too. [permissions › How rules match a symlinked path](https://code.claude.com/docs/en/permissions#symlinks)
- Grep and Glob search the directory the `path` argument resolves to, and Claude Code applies `Read` deny rules to that directory. [permissions › How rules match a symlinked path](https://code.claude.com/docs/en/permissions#symlinks)
- With `permissions.blockReadsOutsideWorkingDirectories` on, or in a `--restricted` session, these attachments are also left out when they come from a path where that setting or flag refuses Claude's file reads. [permissions › Attachments through a symlink](https://code.claude.com/docs/en/permissions#symlinks)
- The line `Referenced <path> (not read: could not be examined)` in place of a file you `@`-mentioned means Claude Code couldn't work out where the path leads, for example because its symlinks form a loop. Claude is told to read the path with its file tools instead, which can succeed when Claude Code only ran out of time to examine the path. When the path's symlinks don't resolve, that read is refused too, so fix the link on disk or `@`-mention the file by a path that resolves. [permissions › Attachments through a symlink](https://code.claude.com/docs/en/permissions#symlinks)
- If the path Claude asks to edit or write is itself a symlink, the Edit and Write tools refuse the write and direct Claude to the link's target. [permissions › Writes through a symlink](https://code.claude.com/docs/en/permissions#symlinks)
- A write can still pass through a symlink when a directory on the way to the file is a symlink, or when a Bash or PowerShell command does the writing. For those writes, what happens depends on where the file the write resolves to sits relative to your working directories and the protected paths. [permissions › Writes through a symlink](https://code.claude.com/docs/en/permissions#symlinks)
  - When the requested path is inside your working directories and the file it resolves to isn't, the write isn't
    auto-approved in `acceptEdits` mode. In auto mode, unless an allow rule approves the write, you're prompted for it
    instead of the classifier deciding, and the prompt names the path the write resolves to.
  - When the write resolves to a protected path that the requested path doesn't name, the protected paths table gives
    the outcome for each permission mode, except that where the table routes the write to the classifier, this write
    prompts you instead.
- When Claude Code can't determine where a path leads on disk, for example because symlinks on it form a loop, the Read, Edit, and Write tools refuse the operation. When a tool then opens the approved file, it confirms that the path still resolves to the location the permission check approved. [permissions › Paths that can't be resolved or that change](https://code.claude.com/docs/en/permissions#symlinks)

## Network paths

- When Claude's file-reading tools, such as Read, Grep, and Glob, read from a network path, the read gets its own permission check. A network path is one that can reach another computer: on Windows, a UNC path such as `\\server\share\file`, and on macOS and Linux, a `/net` automount path such as `/net/fileserver/notes.txt`. Looking up such a path can contact the host it names, and on Windows that contact can send the host your credentials. [permissions › Network paths](https://code.claude.com/docs/en/permissions#network-paths)
- Shell commands have their own check: in Manual mode, a read-only Bash or PowerShell command whose arguments include a UNC path still prompts on Windows. [permissions › Network paths](https://code.claude.com/docs/en/permissions#network-paths)
- The read prompts even with an allow rule, including a rule for the whole tool such as `Read`, and in auto mode the prompt comes to you and the classifier doesn't decide the read. [permissions › Network paths](https://code.claude.com/docs/en/permissions#network-paths)
- In `dontAsk` mode, Claude Code denies the read instead of prompting. In `bypassPermissions` mode, and in interactive terminal sessions in plan mode with bypass permissions available, the read runs without this prompt. [permissions › Network paths](https://code.claude.com/docs/en/permissions#network-paths)
- To read files on a network share without this prompt, give the share a local path first. On Windows, map the share to a drive letter and pass the drive with `--add-dir` when you launch Claude Code, such as `claude --add-dir Z:\` in PowerShell for a share mapped to `Z:`. On macOS and Linux, mount the share at a local path, such as a directory under `/mnt` or `/Volumes`, and read the files from there. [permissions › Network paths](https://code.claude.com/docs/en/permissions#network-paths)
- Claude Code doesn't add network paths as working directories. Looking up a network path can contact the host it names, so it refuses the path without looking it up. Running `/add-dir` with a network path gives `\\server\share is a network path, which cannot be added as a working directory.` and the message notes that a drive letter added mid-session does not yet carry remote-read trust, so pass the drive with `--add-dir` at launch. [errors › Working directory is a network path](https://code.claude.com/docs/en/errors#working-directory-is-a-network-path)
- When you pass a network path at startup, with `--add-dir` or in `permissions.additionalDirectories`, Claude Code starts without that directory. In an interactive session you don't see the message at startup, because it goes to the debug log with the other startup warnings. [errors › Working directory is a network path](https://code.claude.com/docs/en/errors#working-directory-is-a-network-path)
- Paths that Claude Code refuses as working directories include UNC shares such as `\\server\share`, automount paths such as `/net/<host>` (unless you launched Claude Code from a directory under that host's automount; reads under that automount still go through the network path check), and local paths that reach a network location through a symbolic link or junction. Mapped drive letters and `\\wsl$` paths don't count as network paths. [errors › Working directory is a network path](https://code.claude.com/docs/en/errors#working-directory-is-a-network-path)
- Extra steps for a refused path: on Windows, `net use Z: \\server\share` maps the share before `claude --add-dir Z:\` in PowerShell, and if the path is in `permissions.additionalDirectories`, remove it from the settings file that lists it. [errors › Working directory is a network path](https://code.claude.com/docs/en/errors#working-directory-is-a-network-path)
- On Windows, the documentation recommends against enabling WebDAV or allowing Claude Code to access paths such as `\\*` that may contain WebDAV subdirectories: enabling WebDAV may allow Claude Code to trigger network requests to remote hosts, bypassing the permission system. [security › Additional safeguards](https://code.claude.com/docs/en/security#additional-safeguards)

## WebFetch rules

- WebFetch rules use a `domain:` prefix and match against the hostname of the requested URL. Matching is case-insensitive, supports `*` wildcards, and strips a trailing `.` from both the rule and the hostname, so `example.com.` and `example.com` are treated the same. [permissions › WebFetch](https://code.claude.com/docs/en/permissions#webfetch)
  - `WebFetch(domain:example.com)` matches requests to `example.com` only. To also cover subdomains such as
    `api.example.com`, add a `WebFetch(domain:*.example.com)` rule.
  - `WebFetch(domain:*.example.com)` matches any subdomain at any depth, such as `api.example.com` or `a.b.example.com`,
    but not `example.com` itself.
  - `WebFetch(domain:*)` matches every domain. It isn't the same as a bare `WebFetch` rule.
- In any position other than a leading `*.` or a bare `*`, the wildcard matches only the text between two dots. `WebFetch(domain:example.*)` matches `example.org` but not `example.evil.com`, where `*` would have to become `evil.com` and cross a dot. This keeps a trailing wildcard from matching domains an attacker could register. [permissions › WebFetch](https://code.claude.com/docs/en/permissions#webfetch)
- A bare `WebFetch` rule is the tool name with no `domain:` part, such as `"deny": ["WebFetch"]`. Both it and `WebFetch(domain:*)` cover every URL, but Claude Code applies them differently, and only the `domain:` form also adds its domain to the sandbox's allowed or denied domain list. [permissions › Allow or deny every fetch](https://code.claude.com/docs/en/permissions#allow-or-deny-every-fetch)

  | Rule | In `allow` | In `deny` |
  | :- | :- | :- |
  | `WebFetch` | Claude fetches without prompting you. Doesn't change which hosts sandboxed commands can reach. | Claude Code removes the `WebFetch` tool, so Claude can't fetch at all. Doesn't change which hosts sandboxed commands can reach. |
  | `WebFetch(domain:*)` | Claude fetches without prompting you, and sandboxed commands can reach any host. | Claude Code keeps the tool and refuses each fetch, and sandboxed commands can't reach any host. |

- The two forms also differ on reads of artifacts, the pages the Artifact tool publishes on claude.ai. A bare `WebFetch` deny or ask rule doesn't apply to those reads. A `domain:` rule covering `claude.ai` or the `*.claudeusercontent.com` content host, such as `WebFetch(domain:claude.ai)` or `WebFetch(domain:*)`, denies each read or prompts before it, and an `Artifact` rule does the same. When a rule blocks a read, the denial names the rule. [permissions › Allow or deny every fetch](https://code.claude.com/docs/en/permissions#allow-or-deny-every-fetch)
- To let Claude fetch freely while keeping the sandbox allowlist as it is, use the bare form. When you ask Claude to run a sandboxed `curl` against a host outside the sandbox allowlist, Claude Code still prompts you for that host, because the bare rule didn't add the host to the allowlist. [permissions › Allow or deny every fetch](https://code.claude.com/docs/en/permissions#allow-or-deny-every-fetch)

```json
{
  "permissions": {
    "allow": ["WebFetch"]
  }
}
```

- In Manual and `acceptEdits` permission modes, WebFetch prompts before fetching, except for domains your permission rules already allow or deny and a built-in set of preapproved documentation domains that fetch without a prompt. Whatever your rules allow, a fetch also passes the WebFetch domain safety check first. [tools-reference › WebFetch tool behavior](https://code.claude.com/docs/en/tools-reference#webfetch-tool-behavior)
- With `skipWebFetchPreflight` set, WebFetch attempts any URL without consulting the blocklist, so pair it with `WebFetch` permission rules if you need to restrict which domains Claude can reach. [settings-reference › `skipWebFetchPreflight`](https://code.claude.com/docs/en/settings-reference#skipwebfetchpreflight)
- The WebFetch prompt offers three options. **Yes** approves this fetch only, and the next WebFetch call prompts again, even for the same domain. **Yes, and don't ask again for `<domain>`** approves the fetch and saves a `WebFetch(domain:...)` allow rule for that domain to `.claude/settings.local.json` for that repository; when your organization sets `allowManagedPermissionRulesOnly`, Claude Code hides this option. **No, and tell Claude what to do differently** rejects the fetch. [tools-reference › WebFetch tool behavior](https://code.claude.com/docs/en/tools-reference#webfetch-tool-behavior)
- To allow a domain in advance without a prompt, add an allow rule like `WebFetch(domain:example.com)`; `WebFetch(domain:*)` allows every domain. The `auto` and `bypassPermissions` permission modes skip the prompt, except for a domain an explicit `ask` rule matches. [tools-reference › WebFetch tool behavior](https://code.claude.com/docs/en/tools-reference#webfetch-tool-behavior)
- An explicit `WebFetch(domain:...)` rule in `deny`, `ask`, or `allow` takes precedence over the preapproved set, so you can block a preapproved domain or require a prompt for it. [tools-reference › WebFetch tool behavior](https://code.claude.com/docs/en/tools-reference#webfetch-tool-behavior)

## MCP rules

- To match every tool from an MCP server, write `mcp__<server>__*`; to match one tool, write its full name, `mcp__<server>__<tool>`. `mcp__puppeteer` matches any tool provided by the `puppeteer` server, `mcp__puppeteer__*` also matches all of them, and `mcp__puppeteer__puppeteer_navigate` matches the `puppeteer_navigate` tool. [permissions › MCP](https://code.claude.com/docs/en/permissions#mcp)
- For `<server>`, write the server's name the way it appears in that server's tool names. [permissions › MCP](https://code.claude.com/docs/en/permissions#mcp)
  - Characters such as `.` or spaces become `_`, so for a server you configured as `my.server`, write
    `mcp__my_server__*`.
  - A server that a plugin provides takes the plugin-scoped form: for the `database-tools` server in a plugin named
    `my-plugin`, write `mcp__plugin_my-plugin_database-tools__*`.
  - For a `<server>` that contains `__` or ends in `_`, write the wildcard form with the whole name: for a server named
    `reports__v2`, write `mcp__reports__v2__*`. The bare `mcp__reports__v2` and the shorter `mcp__reports` don't match
    its tools as allow rules, because Claude Code reads both as rules for a server named `reports`. As a deny or ask
    rule, each of those two names also covers every tool of the `reports__v2` server. To cover a server named `reports`
    alone, write one rule per tool in the `mcp__reports__<tool>` form, or rename one of the servers.
- If your organization has set a claude.ai connector tool to `ask` and that setting reaches Claude Code in your session, allow rules for that tool don't take effect: Claude Code prompts on every call, even in `auto` and `bypassPermissions` modes. In `dontAsk` mode, which never prompts, Claude Code denies the call instead. Tools from connectors Claude Code fetches itself appear as `mcp__claude_ai_<server>__<tool>`. [permissions › MCP](https://code.claude.com/docs/en/permissions#mcp)
- In a Cowork session in the Claude Desktop app, Claude runs shell commands through Cowork's `mcp__workspace__bash` tool rather than the built-in `Bash` tool, and Cowork likewise provides `mcp__workspace__web_fetch` for web fetches. Claude Code also applies deny rules that name the whole `Bash` or `WebFetch` tool to these Cowork tools, so a managed `Bash` deny rule stops Claude from running shell commands in Cowork, and the message names the Cowork tool: `Permission to use mcp__workspace__bash has been denied.` Allow rules don't carry over: Claude Code never applies a `Bash` allow rule to `mcp__workspace__bash`. [permissions › MCP](https://code.claude.com/docs/en/permissions#mcp)

## Cd rules

- `Cd` rules control which directories the `/cd` command can move the session to. `Cd` is not a model-invocable tool: Claude can't call it, and the rules apply only when you run `/cd` yourself. [permissions › Cd](https://code.claude.com/docs/en/permissions#cd)
- A bare `Cd` deny rule disables `/cd` entirely. A `Cd(<path-pattern>)` deny rule blocks matching targets, and deny rules check every spelling of the target, including each symlink hop it resolves through, so a rule written for one path also blocks targets that resolve to it. [permissions › Cd](https://code.claude.com/docs/en/permissions#cd)
- Adding any `Cd` allow rule switches `/cd` to allowlist mode: the resolved target directory must match one of your allow rules, or `/cd` refuses. With no `Cd` rules configured, `/cd` keeps its default behavior and prompts you to trust an unfamiliar directory. [permissions › Cd](https://code.claude.com/docs/en/permissions#cd)
- Path patterns share the `//`, `~/`, and `/` anchors from Read and Edit rules, but matching is anchored to the whole directory path rather than gitignore-style. `*` matches exactly one path segment and `**` matches across segments; a trailing `/**` also matches its named root. [permissions › Cd](https://code.claude.com/docs/en/permissions#cd)

  | Rule | Matches | Does not match |
  | - | - | - |
  | `Cd(~/code/*)` | `~/code/app` | `~/code/app/src`, `~/code` |
  | `Cd(~/code/**)` | `~/code` and any directory under it | directories outside `~/code` |
  | `Cd(**/node_modules)` | any `node_modules` directory at any depth under the current directory | `node_modules/pkg` |

## Rules for other tools

- In `claude -p` and Agent SDK runs, where the plan prompt never shows, a `Workflow` allow rule lets every workflow start and `Workflow(<name>)` lets one saved workflow start by name. [workflows › Approve the plan before it runs](https://code.claude.com/docs/en/workflows#approve-the-plan-before-it-runs)
- A workflow's agents' tool calls receive the same permission checks and sandboxing as any other tool call in the session; the `ultracode` keyword, or asking for a workflow in your own words, only chooses how Claude structures the work. In `claude -p` and the Agent SDK, deny rules, ask rules and `dontAsk` mode apply to the Workflow launch as they apply to every tool call. To avoid prompts on a long run, add the tools the agents need to your allow rules before starting. [workflows › Ask for a workflow in your prompt](https://code.claude.com/docs/en/workflows#ask-for-a-workflow-in-your-prompt) [workflows › Approve the plan before it runs](https://code.claude.com/docs/en/workflows#approve-the-plan-before-it-runs)
- The workflows page uses `Workflow(<name>)`, but the tools-reference specifier table doesn't list `Workflow`, so the two pages disagree on whether `Workflow` takes a specifier. [tools-reference › Configure tools with permission rules and hooks](https://code.claude.com/docs/en/tools-reference#configure-tools-with-permission-rules-and-hooks)
- For a Monitor tool WebSocket watch, opening a WebSocket prompts for approval, in auto mode the classifier decides instead, and the prompt doesn't offer an option to skip future prompts for the same host. [tools-reference › WebSocket source](https://code.claude.com/docs/en/tools-reference#websocket-source)
- While any other tool remains, you can't block `EndConversation`: deny and ask rules naming it have no effect, and neither `--disallowedTools` nor a `--tools` list can remove it. When your deny rules remove every other tool and also match `EndConversation`, as `"*"` does, Claude Code removes it too rather than leaving it as the only tool, unless an allow rule names `EndConversation` explicitly. A deny list that removes every other tool without matching `EndConversation` leaves it in place. [tools-reference › EndConversation tool behavior](https://code.claude.com/docs/en/tools-reference#endconversation-tool-behavior)

## Working directories

- By default, Claude has access to files in the directory where you launched it. That directory is the session's primary working directory until you move the session with `/cd`. [permissions › Working directories](https://code.claude.com/docs/en/permissions#working-directories)
- In Manual mode, Claude Code asks you before its file tools read or write outside the folder where it was started and its subfolders. The boundary is a permission prompt, so a Bash command you approve can still write anywhere your user account can; to restrict Bash commands at the operating system level, turn on sandboxing. [security › Built-in protections](https://code.claude.com/docs/en/security#built-in-protections)
- You can extend access during startup with `--add-dir <path>`, during the session with `/add-dir`, or persistently by adding to `additionalDirectories` in settings files. [permissions › Working directories](https://code.claude.com/docs/en/permissions#working-directories)
- `--add-dir` adds additional working directories for Claude to read and edit files, and Claude Code validates that each path exists as a directory. [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- When you run `/add-dir` while Claude is responding, Claude Code asks you to confirm the directory right away, and once you confirm, Claude's next tool call in the same turn can access it. [commands › All commands](https://code.claude.com/docs/en/commands#all-commands)
- Files in additional directories follow the same permission rules as the original working directory: they become readable without prompts apart from the network path check, and file editing permissions follow the current permission mode. [permissions › Working directories](https://code.claude.com/docs/en/permissions#working-directories)
- `permissions.additionalDirectories` gives Claude file access to directories outside the one you started in, as additional working directories. Scope: any file. Type: array of directory paths. Default: unset. `--add-dir` and `/add-dir` add directories for one session alongside this key. [settings-reference › `permissions.additionalDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-additionaldirectories)

```json
{
  "permissions": {
    "additionalDirectories": ["../docs/"]
  }
}
```

- `--restricted` confines the built-in file tools to the working directories. [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)

## Moving the session with `/cd`

- To move the session to a different primary working directory, rather than adding a directory alongside the current one, run `/cd <path>`. Claude Code prompts you to trust the workspace if you haven't worked in it before. [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- As soon as you move, Claude Code applies the new directory's project settings, including their permission rules, and its `env` values, applied on top of the environment variables from the previous directory's settings, which stay in effect. [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- Claude Code takes additional directories from the new directory's settings instead of the previous one's, and keeps the directories you added with `--add-dir` or `/add-dir`. [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)
- When the new directory isn't trusted yet, Claude Code lists in the trust prompt the allow rules, additional directories and helper commands the directory's settings would activate, so you can review them before you accept. If you decline, the session stays where it is. [permissions › Move the session to another directory](https://code.claude.com/docs/en/permissions#move-the-session-to-another-directory)

## Project allow rules and workspace trust

- `permissions.allow` rules and `permissions.additionalDirectories` entries in a project's `.claude/settings.json` grant capability, so Claude Code applies them only after you accept the workspace trust dialog for that folder. The dialog lists the rules and directories the folder would grant so you can review them first. `deny` and `ask` rules aren't affected, since they only restrict. [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
- Claude Code keys and stores the trust you accept according to where you start it. [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
  - In a repository, it keys the trust on the git repository root, so the trust covers the whole repository apart from
    any git repository nested inside it, such as a submodule. In a worktree, it uses the main checkout's root, as it
    does for saved rules.
  - Outside a repository, it keys the trust on the directory you started it from, and the trust covers any subdirectory
    of that directory apart from a git repository nested inside it, such as a clone. Each covered subdirectory then
    counts as a folder whose parent you trusted.
- When you start in your home directory, Claude Code holds the trust for the current session only and doesn't write it to disk, so the prompt reappears on each launch, and there is no setting to persist it. [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust) [security › Additional safeguards](https://code.claude.com/docs/en/security#additional-safeguards)
- The security page says that when you start Claude Code from a project subdirectory, trust acceptance is saved per directory, while the permissions page keys trust on the git repository root inside a repository. [security › Additional safeguards](https://code.claude.com/docs/en/security#additional-safeguards), [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
- Claude Code shows the trust dialog in interactive sessions only. A `claude -p` run or an SDK session never shows it, and trusting a parent folder doesn't count for these rules. [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
- Before it starts or restarts a background session, Claude Code also checks workspace trust for the directory the session runs in. If you run `claude --bg` from a terminal in a directory you haven't trusted, the trust dialog appears first and the session starts once you accept it. Where no dialog can appear, such as in a script, the command exits with a `Workspace not trusted` error instead. [permissions › Project allow rules and workspace trust](https://code.claude.com/docs/en/permissions#project-allow-rules-and-workspace-trust)
- `.claude/settings.local.json` is normally your own file, so Claude Code applies its allow rules and additional directories without the trust step. When the file is tracked in git, or `.claude` is a symlink, Claude Code treats it as repository-supplied instead and holds its rules until you trust the folder. [permissions › When your local settings file needs trust](https://code.claude.com/docs/en/permissions#when-your-local-settings-file-needs-trust)
- Claude Code runs git to tell the two apart, and it runs git only once you've trusted the folder: you accepted the trust dialog for it or for a parent directory whose trust extends to it, or you're in a `-p` or SDK session, which counts as accepted. Until then, where you started Claude Code decides what happens to the file's rules. [permissions › When your local settings file needs trust](https://code.claude.com/docs/en/permissions#when-your-local-settings-file-needs-trust)
  - In your configuration home, Claude Code applies that folder's `.claude/settings.local.json` right away without
    running git. Your configuration home is your home directory, or a directory whose `.claude` subdirectory you've set
    as `CLAUDE_CONFIG_DIR`. If that `CLAUDE_CONFIG_DIR` directory sits inside a git repository and Claude Code keeps
    your local settings at the repository root instead, it holds the rules like anywhere else.
  - Anywhere else, Claude Code holds the file's rules like project settings. Once the check has run, it applies the
    rules of an untracked file, or of a file in a directory outside any git repository, even though you haven't trusted
    that exact folder.
- When you haven't trusted the folder itself, because you trusted only a parent folder or ran `claude -p` or the SDK there, two kinds of repository content differ: [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
  - The `env` block and helper commands such as `apiKeyHelper` in settings files are used in both situations.
  - `permissions.allow` rules and `additionalDirectories` in `.claude/settings.json` are not used. With only a parent
    folder trusted, they wait until you accept the trust dialog, which appears again listing them. In `claude -p` or the
    SDK with the folder never trusted, Claude Code prints a `this workspace has not been trusted` warning to stderr.
- The parent-folder situation doesn't apply inside a nested repository: in an interactive session Claude Code shows the trust dialog for it, and a `claude -p` or SDK run there follows the `claude -p` situation. [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)
- `extraKnownMarketplaces` entries from the repository or an `--add-dir` directory are not used when you trusted only a parent folder (and no dialog is offered) or in `claude -p` or the SDK with the folder never trusted, and Claude Code ignores them without a message. In an interactive session it registers the marketplace only after you accept the trust dialog for that folder; in a `-p` run the entries apply only in a folder whose trust you already accepted interactively, or whose `hasTrustDialogAccepted` flag you set in `~/.claude.json`. Until then, teammates who clone the repository don't get plugins from a marketplace the file declares. [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder), [plugins/org › Require plugins per repository](https://code.claude.com/docs/en/plugins/org#require-plugins-per-repository), [settings › A committed key doesn't reach teammates](https://code.claude.com/docs/en/settings#a-committed-key-doesn’t-reach-teammates)
- A custom status line and a custom file suggestion command (`statusLine`, `fileSuggestion`, `subagentStatusLine`) are off entirely when the folder isn't trusted under the same workspace trust rule as hooks in settings files: the status line is disabled, and `@` autocomplete falls back to the built-in file suggestion. [settings-reference › Status line and file suggestion gates](https://code.claude.com/docs/en/settings-reference#status-line-and-file-suggestion-gates)
- For content that needs this exact folder trusted, trust it by hand: set `projects["<path>"].hasTrustDialogAccepted` to `true` in `~/.claude.json`, where `<path>` is the repository root, or the folder itself outside a repository. Claude Code prints the exact key in the stderr warning for skipped allow rules. [permissions › What runs before you trust a folder](https://code.claude.com/docs/en/permissions#what-runs-before-you-trust-a-folder)

## Managed-only permission rules

- `allowManagedPermissionRulesOnly` makes managed settings the only settings source of permission rules. Claude Code then ignores `allow`, `ask`, and `deny` rules in user, project, local, and `--settings` files, ignores `--allowedTools`, hides the always-allow choices in permission prompts, and stops saving new rules. [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
- `--disallowedTools` rules and the current session's `deny` and `ask` rules still apply, including after Claude Code reloads settings mid-session. They only restrict, so they can't widen what the managed rules grant. [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)
- With managed-only rules, allow rules must live in the managed source Claude Code selects. On an MDM-managed fleet that is the MDM policy, not a separate managed settings file. [managed-settings › Keep Cowork folder access when only managed rules apply](https://code.claude.com/docs/en/managed-settings#keep-cowork-folder-access-when-only-managed-rules-apply)
- Scope: `Managed`. Type: Boolean. `true`: managed settings become the only settings source of permission rules. `false`: Claude Code applies permission rules from user, project, local, and `--settings` files in addition to the managed ones. Default: unset, so Claude Code applies permission rules from user, project, and local settings and from `--settings`, in addition to the managed ones. [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)

```json
{
  "allowManagedPermissionRulesOnly": true
}
```

- The key doesn't lock down the MCP server allowlist; for that, set `allowManagedMcpServersOnly`. [settings-reference › `allowManagedPermissionRulesOnly`](https://code.claude.com/docs/en/settings-reference#allowmanagedpermissionrulesonly)

## How permissions meet the sandbox

- Permissions control which tools Claude Code can use and which files or domains it can access, and apply to Bash, Read, Edit, WebFetch, MCP, and every other tool, except that a deny or ask rule can't block `EndConversation` while any other tool remains. Sandboxing provides OS-level enforcement that restricts shell commands' filesystem and network access, applying to Bash, PowerShell, and Monitor tool commands and their child processes. [permissions › How permissions interact with sandboxing](https://code.claude.com/docs/en/permissions#how-permissions-interact-with-sandboxing)
- Sandbox restrictions still apply even if a prompt injection bypasses Claude's decision-making, so use both for defense-in-depth. [permissions › How permissions interact with sandboxing](https://code.claude.com/docs/en/permissions#how-permissions-interact-with-sandboxing)
- When you enable sandboxing and leave `autoAllowBashIfSandboxed` at its default of `true`, sandboxed Bash commands run without prompting even if your permissions include a bare `Bash` ask rule, or the equivalent `Bash(*)` form: the sandbox boundary substitutes for that whole-tool prompt. [permissions › How permissions interact with sandboxing](https://code.claude.com/docs/en/permissions#how-permissions-interact-with-sandboxing)
- In plan mode, Claude Code skips this substitution. Without an ask rule, the built-in read-only commands still run without prompting, and any other shell command goes through the regular permission flow while you are still planning. With a bare `Bash` ask rule, every Bash command prompts, including sandboxed read-only commands, the same as outside sandboxing. [permissions › How permissions interact with sandboxing](https://code.claude.com/docs/en/permissions#how-permissions-interact-with-sandboxing)
- Commands that won't run sandboxed, such as excluded commands, respect the bare `Bash` ask rule as usual. [permissions › How permissions interact with sandboxing](https://code.claude.com/docs/en/permissions#how-permissions-interact-with-sandboxing)

## Blocking reads outside the working directories

- `permissions.blockReadsOutsideWorkingDirectories` makes Claude's file tools refuse reads outside your working directories in every permission mode, including `bypassPermissions`. Claude Code denies `Read`, `Grep`, `Glob`, and `LSP` calls on those paths and tells Claude to ask you to add the directory with `/add-dir`. Files Claude Code itself needs stay readable, such as your skills, plugins, rules, agents, commands, and the `CLAUDE.md` memory file under `~/.claude/`. [settings-reference › `permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories)
- Shell commands aren't refused the same way. A Bash command the shell parser can't trace, such as one that changes directory more than once or runs a subshell, prompts you even in auto mode and `bypassPermissions` mode, even when the command names no path outside the working directories. This prompt doesn't apply when the command runs in the sandbox and the sandbox enforces the block. [settings-reference › `permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories)
- Scope: any file. A `true` in any file applies, so a repository can turn the block on for itself but can't lift yours. Type: Boolean. `true`: Claude's file tools refuse reads outside the working directories. `false`: the same as unset; the block still applies if another file sets `true`. Default: unset, so reads outside the working directories follow your permission mode. [settings-reference › `permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories)

```json
{
  "permissions": {
    "blockReadsOutsideWorkingDirectories": true
  }
}
```

- Directories you add with `--add-dir`, `/add-dir`, or `additionalDirectories` in your user or managed settings count as working directories for the block. Directories added only in repository settings don't count: those in `.claude/settings.json`, and those in `.claude/settings.local.json` unless git reports that file as untracked. In a directory that isn't a git repository, or when git tracks the file, Claude Code treats `.claude/settings.local.json` as repository settings, so put directories you want to keep readable in your user settings instead. [settings-reference › `permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories)
- To lift the block, remove the key from every settings file that sets it, then start a new session. [settings-reference › `permissions.blockReadsOutsideWorkingDirectories`](https://code.claude.com/docs/en/settings-reference#permissions-blockreadsoutsideworkingdirectories)
- While the setting is off, file reads other than reads from network paths run without a prompt in auto mode, including reads outside the working directories, but the first time Claude uses the Read, Grep, or Glob tool on a path outside them, Claude Code asks whether to allow that read. The prompt doesn't appear in non-interactive `-p` runs or background sessions, where reads run as before. Whatever you answer, Claude keeps working. [permission-modes › The first read outside the working directories](https://code.claude.com/docs/en/permission-modes#first-read-outside-the-working-directories)
  - **Yes, and keep allowing any reads outside the working directories**: the read runs, later reads outside the working
    directories run as before, and Claude Code records your answer so the prompt doesn't appear again.
  - **No, and block reads outside the working directories from now on**: the read is refused, and Claude Code sets
    `permissions.blockReadsOutsideWorkingDirectories` to `true` in your user settings, which makes the file tools refuse
    such reads in every later session and every permission mode. To let Claude read such a path later, add its directory
    with `/add-dir` or remove the setting.
  - **No, and ask again next time**: the read is refused, and the next read outside the working directories prompts
    again.
  - **Yes, but ask again next time**: the read runs, nothing is saved, and the next read outside the working directories
    prompts again.

## Command-line flags

- `--allowedTools`, `--allowed-tools` lists tools that execute without prompting for permission, apart from reads from network paths. To restrict which tools are available, use `--tools` instead. [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- `--disallowedTools`, `--disallowed-tools` entries are deny rules. [cli-reference › CLI flags](https://code.claude.com/docs/en/cli-reference#cli-flags)
- An in-process agent team teammate runs under the lead's live allow and deny rules, so `--disallowedTools`, `--tools` and `--allowedTools` all apply to it. A split-pane teammate starts with the lead's command-line deny rules and tool list (`--disallowedTools` and `--tools`) but doesn't receive `--allowedTools`, so an action you allowed only with that flag isn't pre-approved there. To approve those actions ahead of time, put the rules under `permissions.allow` in `--settings` when you start the lead, such as `claude --settings '{"permissions":{"allow":["Bash(npm *)"]}}'`; the rules then apply to the lead and each split-pane teammate for that session. [agent-teams › Permissions](https://code.claude.com/docs/en/agent-teams#permissions)

# Auto mode

Configuring auto mode: the classifier and its model, what it blocks by default, the `autoMode` setting,
`/auto-mode-setup`, the keys that tune or disable it, fallback, and reviewing and fixing denials.

## Contents

- Availability and the classifier
- Disabling auto mode
- Server-side classifier review
- The classifier model
- What the classifier blocks and allows by default
- Boundaries and approvals stated in conversation
- When auto mode falls back
- How actions are evaluated
- Where the classifier reads `autoMode`
- Human checkpoints with ask and deny rules
- Define trusted infrastructure
- Generate environment entries with `/auto-mode-setup`
- Override the block and allow rules
- Related settings keys
- The `claude auto-mode` subcommands
- Review and fix denials

## Availability and the classifier

- Auto mode lets Claude execute without routine permission prompts. A separate classifier model reviews actions before
  they run, blocking anything that escalates beyond your request, targets unrecognized infrastructure, or appears driven
  by hostile content Claude read.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
- The classifier also reviews each message Claude sends to another agent with `SendMessage`, whether plain text or a
  structured agent team message, before Claude Code delivers it, both in auto mode and in plan mode while the classifier
  reviews commands.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
- Auto mode reduces permission prompts but does not guarantee safety. Use it for tasks where you trust the general
  direction, not as a replacement for review on sensitive operations.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
- Auto mode is available only when the account meets all of these requirements:
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
  - **Plan**: All plans.
  - **Organization**: on Team and Enterprise, auto mode is available by default.
  - **Model**: on the Anthropic API and Claude Platform on AWS, Claude Opus 4.6 or later, Sonnet 4.6 or later,
    Haiku 5.5, or a Fable model. On Amazon Bedrock, Google Cloud's Agent Platform, Microsoft Foundry, and signed-in
    Claude apps gateway sessions, only Claude Sonnet 5 or later, Opus 4.7 or later, Haiku 5.5, and the Fable models.
    Older models, including Sonnet 4.5, Opus 4.5, Haiku 4.5, and claude-3 models, are not supported on any provider.
  - **Provider**: available by default on the Anthropic API, Claude Platform on AWS, Amazon Bedrock, Google Cloud's
    Agent Platform, Microsoft Foundry, and signed-in Claude apps gateway sessions.
- If Claude Code reports auto mode as unavailable, first check these requirements and whether any settings file sets
  `disableAutoMode`. Anthropic may also have turned auto mode off server-side, or the server may have rejected auto
  mode for your account. A session that received either answer keeps auto mode off until the session ends, so start a
  new session later.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
- The first time the built-in default starts one of your sessions in auto mode, Claude Code shows a notice that links
  to the permission modes page: in a terminal, once, at the top of the session; in the VS Code extension, as a card on
  the new-conversation screen that stays until you dismiss it.
  [permission-modes › Which mode a session starts in](https://code.claude.com/docs/en/permission-modes#which-mode-a-session-starts-in)
- In a run that starts in auto mode, Claude Code drops a bare `Bash` entry in `--allowedTools` as a broad allow rule,
  and auto mode evaluates each command instead.
  [headless › Auto-approve tools](https://code.claude.com/docs/en/headless#auto-approve-tools)

## Disabling auto mode

- `disableAutoMode` removes auto mode from the `Shift+Tab` cycle, and a session started with `--permission-mode auto`
  starts in Manual instead. Administrators set it to `"disable"` in managed settings to prevent developers in their
  organization from using auto mode; on Team and Enterprise this turns auto mode off for the organization. A session
  already running in auto mode leaves it when the setting reaches that session from an admin-deployed source, and shows
  `auto mode disabled by settings`.
  [permission-modes › Eliminate permission prompts with auto mode](https://code.claude.com/docs/en/permission-modes#eliminate-prompts-with-auto-mode)
  [settings-reference › `disableAutoMode`](https://code.claude.com/docs/en/settings-reference#disableautomode)
  [permission-modes › Auto mode on Bedrock, Agent Platform, or Foundry](https://code.claude.com/docs/en/permission-modes#enable-auto-mode-on-bedrock-agent-platform-or-foundry)
- `disableAutoMode`: scope is any file, most useful in managed settings, where users can't override it. It is also
  accepted under `permissions` as `permissions.disableAutoMode`, including in an organization with the HIPAA
  configuration applied. Type: the string `"disable"`. Default: unset.
  [settings-reference › `disableAutoMode`](https://code.claude.com/docs/en/settings-reference#disableautomode)
  [permission-modes › Permission modes with the HIPAA configuration](https://code.claude.com/docs/en/permission-modes#hipaa-configuration)

  ```json
  {
    "disableAutoMode": "disable"
  }
  ```
- Setting `permissions.defaultMode` in managed settings makes terminal sessions in your organization start in that mode
  while people can still switch to auto mode; to remove auto mode so nobody can select it, set
  `permissions.disableAutoMode` to `"disable"` instead.
  [permission-modes › Start in a different permission mode](https://code.claude.com/docs/en/permission-modes#start-in-a-different-mode)

## Server-side classifier review

- In auto mode, Claude Code can ask the server to check the actions that the decision order sends for review, as part
  of the session's model requests, in place of sending its own classifier requests. These sessions ask:
  [permission-modes › Server-side classifier review](https://code.claude.com/docs/en/permission-modes#server-side-classifier-review)
  - **A direct connection to the Anthropic API**: in interactive terminal sessions and in `-p`, Agent SDK, VS Code
    extension, and desktop app sessions, whatever your plan or account type, as Anthropic rolls it out. A session that
    doesn't fetch feature flags, for example because you turned telemetry off, asks the server by default in any kind
    of session.
  - **A cloud provider, or an LLM gateway or proxy**: on Claude Platform on AWS, Amazon Bedrock, Google Cloud's Agent
    Platform, and Microsoft Foundry, and whenever you point `ANTHROPIC_BASE_URL` at an LLM gateway or proxy, whatever
    your plan.
  - **A signed-in Claude apps gateway session**.
  - **A cloud session in an Anthropic-hosted environment**: whatever your plan, when you start it from the web, the
    mobile app, or the desktop app with **Cloud** selected. Sessions started by a cloud scheduled task ask the server
    as Anthropic rolls it out.
- Where the server reviews the actions, its verdicts decide them. Two other outcomes are possible:
  [permission-modes › Server-side classifier review](https://code.claude.com/docs/en/permission-modes#server-side-classifier-review)
  - **The server doesn't review the session**: a response completes with no review results, or the server answers
    that it doesn't review this session. The most common causes are an LLM gateway or proxy that drops the request for
    review or the results, and a platform, region, or credential that doesn't have server-side checks yet. Claude Code
    falls back to its own classifier requests. Once that fallback holds for the rest of the session, it shows a notice
    about classifier request charges on accounts where those requests are billed.
  - **The server gives no verdict for an action**: Claude Code denies the action rather than run it unreviewed. On any
    connection, this happens when the response ends before the review results arrive or the results arrive in a form
    Claude Code can't read. An LLM gateway or proxy that cuts responses short or rewrites the results can cause either.
    On a direct connection to the Anthropic API, it also happens when the server's check fails for the action, for
    example by timing out.
- To skip asking the server and always use Claude Code's own classifier requests, set `CLAUDE_CODE_AUTO_MODE_SERVER=0`.
  Setting it to `1` on a direct connection to the Anthropic API turns server review on in a session that doesn't have
  it yet, unless you've also set `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1`. If you set
  `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` and leave `CLAUDE_CODE_AUTO_MODE_SERVER` unset, Claude Code also stops
  asking the server, except as described under pre-release capabilities.
  [permission-modes › Server-side classifier review](https://code.claude.com/docs/en/permission-modes#server-side-classifier-review)
- When a host platform that embeds Claude Code sets `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`,
  `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` doesn't stop auto mode sessions on Amazon Bedrock, Google Cloud's Agent
  Platform, Microsoft Foundry, or a Claude apps gateway from asking the server for classifier review. That review adds
  an `anthropic-beta` value and a `safeguards` request field. Set `CLAUDE_CODE_AUTO_MODE_SERVER=0` to stop it there.
  [llm-gateway-protocol › Disable pre-release capabilities](https://code.claude.com/docs/en/llm-gateway-protocol#disable-pre-release-capabilities)
- When Claude Code falls back to its own classifier requests on an account where those requests are billed, it shows
  this notice: "We're changing auto mode to no longer charge for classifier requests in Claude Code. However, this
  session isn't eligible." Claude Code holds the first action it would check that way until you answer; auto mode keeps
  working, and its classifier requests are billed as token usage. When Claude Code can identify an LLM gateway or proxy
  in the path, the notice names it. Wherever server-side checks are on, the server performs them as part of the
  session's own model requests, at no charge.
  [auto-mode-classifier-billing › Auto mode classifier request charges](https://code.claude.com/docs/en/auto-mode-classifier-billing)
- Respond to the notice:
  [auto-mode-classifier-billing › Respond to the notice](https://code.claude.com/docs/en/auto-mode-classifier-billing#respond-to-the-notice)
  - **Enter** continues: the held action and the rest of the session use Claude Code's own classifier requests, billed
    as token usage as before, and the notice doesn't appear again in that session. When the notice named a gateway,
    acknowledging it keeps it from reappearing on this machine for 24 hours. When it didn't, the notice returns the
    next time a session falls back.
  - **Esc** or **Ctrl+C** cancels: the held action doesn't run and the current turn stops, with the session still in
    auto mode. Nothing is remembered, so the notice appears again before the next checked action.
  - To stop using auto mode instead, switch permission modes with `Shift+Tab` after you answer.
- Where the notice can't wait for an answer, Claude Code reports the same text and the session continues in auto mode,
  unless a gateway acknowledgment on this machine in the last 24 hours has dismissed it. In non-interactive mode with
  `-p` it prints the text to stderr, and in `stream-json` output it emits a `system` warning message, which Agent SDK
  applications can read from the message stream.
  [auto-mode-classifier-billing › Respond to the notice](https://code.claude.com/docs/en/auto-mode-classifier-billing#respond-to-the-notice)
- On a Pro, Max, Ultra, or Team plan, you never see the notice. If you see it, the usual causes are an LLM gateway or
  proxy in the path that strips or rewrites request headers, drops request fields it doesn't recognize, or edits
  responses, or server-side checks that haven't reached your platform, region, or credential yet (the likely cause if
  the notice keeps appearing with no gateway or proxy in the path; to confirm, contact support or your company's admin,
  or report it with `/feedback`).
  [auto-mode-classifier-billing › Why the notice appears](https://code.claude.com/docs/en/auto-mode-classifier-billing#why-the-notice-appears)
- In a session in auto mode, the **Auto mode server** row in `/status` reads `Enabled` while the server's checks decide
  the session's actions and `Disabled` once the session has fallen back.
  [auto-mode-classifier-billing › Why the notice appears](https://code.claude.com/docs/en/auto-mode-classifier-billing#why-the-notice-appears)
- To make the session eligible when a gateway is the cause, ask your company's admin or your gateway provider to pass
  requests and replies through unchanged: forward request headers and body fields as they are, including ones the
  gateway doesn't recognize such as the `safeguards` request field, and return responses and streaming events without
  dropping keys such as the `safeguard_results` field or rewriting tool-use IDs. New sessions then use the server's
  checks again.
  [auto-mode-classifier-billing › Make the session eligible](https://code.claude.com/docs/en/auto-mode-classifier-billing#make-the-session-eligible)
- If you already know your gateway can't provide the server's checks, set `CLAUDE_CODE_AUTO_MODE_SERVER` to `0` before
  you start the session, in your shell or in the `env` settings key. Classifier requests are then always Claude Code's
  own, billed the same way, and the notice doesn't appear. `CLAUDE_CODE_AUTO_MODE_SERVER` is a temporary setting and
  may be removed in a later release.
  [auto-mode-classifier-billing › Make the session eligible](https://code.claude.com/docs/en/auto-mode-classifier-billing#make-the-session-eligible)

## The classifier model

- By default, classifier requests go to Claude Sonnet 5. If `/status` shows `Auto mode server` as `Enabled`, they're
  sent only for calls outside the server's review.
  [permission-modes › Default classifier model](https://code.claude.com/docs/en/permission-modes#default-classifier-model)
- Find the first row in this table that matches your session. You get that row's model in place of Sonnet 5.
  [permission-modes › Default classifier model](https://code.claude.com/docs/en/permission-modes#default-classifier-model)

  | Your session | Classifier model |
  | - | - |
  | Has an Anthropic-configured classifier model | The configured model. Check the debug log to see which |
  | Runs on Claude Sonnet 4.6 | Sonnet 4.6 |
  | Has `ANTHROPIC_DEFAULT_SONNET_MODEL` set | Its value, or Sonnet 5 if its value is Claude Sonnet 5.5 or Claude Opus 5.5 |

- If Sonnet 5 or the model in `ANTHROPIC_DEFAULT_SONNET_MODEL` is unavailable from your provider or excluded by your
  organization's model policy (the `availableModels` allowlist), Claude Code uses a fallback model: your session's
  model, or an Opus model in a Fable session. On providers other than the Anthropic API, that Opus fallback runs on the
  model you set in `ANTHROPIC_DEFAULT_OPUS_MODEL`, or otherwise on Opus 5, without consulting the allowlist.
  [permission-modes › Default classifier model](https://code.claude.com/docs/en/permission-modes#default-classifier-model)
  [model-config › Restrict model selection](https://code.claude.com/docs/en/model-config#restrict-model-selection)
- To run the classifier on a model other than the default, set `CLAUDE_CODE_AUTO_MODE_MODEL` to a full model ID. Your
  cloud provider's own full model IDs work too. This `~/.claude/settings.json` example sets Claude Sonnet 4.6:
  [permission-modes › Choose the classifier model](https://code.claude.com/docs/en/permission-modes#choose-the-classifier-model)

  ```json
  {
    "env": {
      "CLAUDE_CODE_AUTO_MODE_MODEL": "claude-sonnet-4-6"
    }
  }
  ```
- When the model you set doesn't review, go by the first situation listed that applies:
  [permission-modes › When your model doesn't review](https://code.claude.com/docs/en/permission-modes#classifier-model-not-reviewing)

  | Situation | What happens | What to do |
  | - | - | - |
  | The debug log reports an Anthropic-configured classifier model | That model reviews | None needed |
  | You set Claude Opus 5, Sonnet 5.5, Opus 5.5 or one your organization's model policy excludes | The default classifier model reviews | Set another model |
  | Your provider can't serve the model | Classifier checks fail, so Claude Code denies each action it checks | Set a model it serves, or remove the variable |
  | In a session, `/status` shows `Auto mode server` as `Enabled` | The server reviews without your model | None needed |

- To check which model the classifier used, start an auto mode session from your shell with
  `claude --permission-mode auto --debug-file classifier-debug.log`, have Claude run a shell command that isn't
  read-only, then search the log for `classifier_request_started`:
  [permission-modes › Check which model the classifier used](https://code.claude.com/docs/en/permission-modes#classifier-model-check)
  - **Your model after `model=`**: the variable took effect.
  - **A different model after `model=`**: search the log for `ignoring CLAUDE_CODE_AUTO_MODE_MODEL`, which gives the
    reason and any step to take.
  - **No such line**: read `Auto mode server` in `/status` at the Claude Code prompt. `Enabled`: the server is set to
    review this session's calls. `Disabled`: make sure the permission mode is auto, then have Claude run another
    command that isn't read-only.

## What the classifier blocks and allows by default

- The classifier trusts your working directory and the remotes that were configured for it when the session started.
  A remote added or repointed during the session with `git remote add` or `git remote set-url` isn't trusted, and
  everything else is treated as external until you configure trusted infrastructure.
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)
- Blocked by default:
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)
  - Downloading and executing code, like `curl | bash`.
  - Sending sensitive data to external endpoints.
  - Production deploys and migrations.
  - Mass deletion on cloud storage.
  - Granting IAM or repo permissions.
  - Modifying shared infrastructure.
  - Irreversibly destroying files that existed before the session.
  - Force push.
  - Committing or pushing a change that would send secrets or sensitive data outside the repository when it runs, or
    widen what a deploy exposes. This covers a CI workflow or deploy configuration that passes a secret to a
    destination that doesn't already receive it, a script or setup step that reads a secret store and sends the data
    out, and a config change that widens what a deploy publishes, such as a registry, visibility, artifact, or
    sourcemap setting. The check applies on any branch, applies even when the repository is public, and fires when
    the change is committed or pushed, whether or not that commit or push triggers the pipeline; clearing it requires
    naming the execution effect, not only the commit or push.
  - `git reset --hard`, `git checkout -- .`, `git restore .`, `git clean -fd`, `git stash drop`, or
    `git stash clear`, which the classifier presumes would discard uncommitted changes.
  - `git commit --amend` when the commit at HEAD was not created in this session, or has already been pushed. A
    message-only reword is not blocked: `--amend -m` with nothing newly staged, on a commit that Claude created
    during this session.
  - `terraform destroy`, `pulumi destroy`, `cdk destroy`, or `terragrunt destroy`, and applying a plan that destroys
    resources.
  - Writing to a secret manager, or changing DNS records or TLS certificates.
  - Merging a pull request no human has approved, approving Claude's own pull request, or disabling CI checks.
  - Posting a comment that is itself a command to automation, such as `atlantis apply` or a bot's `/deploy` or
    `/merge`.
  - Toggling, ramping, or deleting a production feature flag.
  - Applying infrastructure changes to a protected IaC scope, or draining and removing cluster nodes.
  - Writes to a shared compute cluster that reach beyond the resource you named, such as a label selector or `--all`
    that catches other users' jobs.
  - Creating Kubernetes resources that run on every node or intercept cluster traffic, such as DaemonSets and
    admission webhooks.
  - Interactive shells or port-forwards into a sensitive remote target.
  - Opening a tunnel or reverse shell that makes a local service reachable from the public internet.
  - Printing a live credential or token into the transcript or a file.
  - Accessing a location listed as a sensitive data location in your environment, copying data out of one, or sending
    data from one to an audience the entry excludes.
  - Routing a package install around your internal package registry to a public registry. This applies when an
    internal registry or mirror is listed in your environment or when you've told Claude in the conversation that one
    exists.
  - Running a command with a flag that disarms a safety guard, like `--insecure`.
  - Launching an autonomous agent loop that runs without human approval or a sandbox, such as one started with
    `--dangerously-skip-permissions` or `--no-sandbox`. This includes running a third-party agent or eval harness with
    isolation and per-action approval disabled, such as a runner started with `--yes-always`.
  - Claude in Chrome browser actions that could send page content, cookies, or credentials off-origin.
  - Deleting files in `/tmp`, `$TMPDIR`, or another shared scratch or cache directory by wildcard, glob, or age filter
    rather than by a specific named path.
  - Including sensitive details in content sent, uploaded, published, or written to other people or shared systems,
    when your own message didn't authorize those details for that recipient. PR and issue bodies, commit messages, and
    comments count as this kind of outbound content when the repository is outside the trust boundary or public,
    including your organization's own public repositories; internal file paths, code names, live API response data
    such as emails or account identifiers, and infrastructure identifiers count as sensitive details. Live personal
    data from an API response in a PR or issue body, such as an email address, an account or organization identifier,
    or a usage metric, requires you to name those details and the recipient regardless of the repository's visibility
    or trust boundary.
  - Sending keystrokes to Claude Code's own tmux pane to drive its own interface, which the classifier treats as
    Claude changing its own permissions or oversight.
  - Commenting out, deleting, or force-passing a test or assertion that guards security behavior, such as auth,
    access control, input validation, or sandboxing.
  - Deleting or tearing down a stateful resource Claude didn't create in the session, when no more specific deletion
    rule applies and you didn't name that resource.
  - Repointing an API base URL, proxy endpoint, webhook receiver, or registry mirror at a third-party host that
    doesn't fit the task, including in example files like `.env.example`.
  - Changing where pushes go with `git remote set-url` or `git remote add`, unless you named the new remote.
  - Pushing secrets or personal or entrusted data to a repository known to be public, or pushing confidential
    material there that isn't part of that repository's own work. A dotfiles repository's own subject matter is the
    one exception for personal or entrusted data, and content from a private repository reaching any public surface is
    blocked the same way. When a repository's visibility isn't established, the classifier doesn't block on that
    alone; it judges the content against the other rules instead.
  - Opening a pull request against a different repository or organization, forking with `gh repo fork`, or pushing to
    a third-party repository, unless you named that external target.
  - Content from a sensitive local store, or from a file whose name, path, or type marks it as sensitive, entering a
    commit, a push, PR or issue text, a gist or paste, or a package publish, unless you named both the source and the
    destination. Session transcripts and conversation logs, credential and configuration dot-folders such as SSH
    keys, cloud credentials, browser profiles, and shell history, and user-data exports all count, and the repository
    being private doesn't clear it.
  - Writing to Claude Code session transcripts, the `.jsonl` history files under `~/.claude/projects/` or your
    configured config directory, whether directly or through a shell command. The rule also covers the metadata lines
    Claude Code appends to each transcript entry for its own checks. Reading a transcript isn't blocked.
  - A recursive forced delete such as `rm -rf "$VAR"` or `Remove-Item -Recurse -Force $dir` whose target is a shell
    variable that isn't assigned anywhere in the conversation the classifier sees, or a glob rooted at such a
    variable. The value came only from earlier command output, which the classifier never receives, so the classifier
    can't verify the deletion target against the other deletion rules. The block clears when you name the exact path
    being deleted, or when Claude re-runs the delete with the resolved literal path written into the command. Deletes
    whose target the classifier can resolve aren't affected. A glob directly under the variable, as in
    `rm -rf "$VAR"/*`, is a critical path instead. `Remove-Item` targets that are a bare `*` or end in `/*` or `\*`
    never reach the classifier: Claude Code denies them outright.
  - Requesting credentials from the cloud instance-metadata endpoint, such as `169.254.169.254`, or explicitly
    authenticating a cloud, cluster, or registry call with the machine's own service-account or node identity.
  - Reaching a public host by a route other than a direct request, such as a tunnel, a reverse shell, or a resolver or
    proxy configuration rewritten to point outside.
  - Reading credentials that belong to the host rather than to your task, such as node certificates or the node's
    container-registry auth.
  - Connecting to or scanning sibling containers, pods, or VMs that Claude didn't start, or the node beneath the
    container.
  - Posting or writing a link to a public paste, diagram, or data-sharing service in a message, PR or issue text, a
    document, or anywhere else the link will be opened or fetched, when the URL itself carries the content being
    shared, unless you named that service.
- Several of these categories depend on environment entries, such as sensitive remote targets and protected IaC
  scopes, that you can narrow to concrete names. If Claude Code runs somewhere that is meant to allow one of the
  host-level blocks (metadata-endpoint credentials, non-direct routes to public hosts, host credentials, or sibling
  containers or pods), describe that setup in a Host containment entry in `autoMode.environment`.
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)
- Allowed by default:
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)
  - Local file operations in your working directory.
  - Installing dependencies declared in your lock files or manifests.
  - Reading `.env` and sending credentials to their matching API.
  - Read-only HTTP requests.
  - Deleting the exact jobs Claude created earlier in the same session.
  - Reading, reviewing, or writing security-related code, configs, and threat models as part of your task.
  - Messages between agents working together in the same multi-agent session.
  - Sending data to the trusted domains, buckets, and services you list in `environment`. This covers data flow only,
    not destructive or credential operations on the same infrastructure.
  - Claude in Chrome navigation to a trusted internal domain, localhost, or a URL you named.
- The remote's own branch protection still applies to pushes, and `permissions.deny` rules can still block push
  commands as written in every mode.
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)
- If routine actions get blocked, an administrator can add trusted repos, buckets, and services via the
  `autoMode.environment` setting.
  [permission-modes › What the classifier blocks by default](https://code.claude.com/docs/en/permission-modes#what-the-classifier-blocks-by-default)

## Boundaries and approvals stated in conversation

- The classifier treats boundaries you state in the conversation as a block signal. If you tell Claude "don't push" or
  "wait until I review before deploying", the classifier blocks matching actions even when the default rules would
  allow them. A boundary stays in force until you lift it in a later message. Claude's own judgment that a condition
  was met does not lift it.
  [permission-modes › Boundaries you state in conversation](https://code.claude.com/docs/en/permission-modes#boundaries-you-state-in-conversation)
- Boundaries are not stored as rules. The classifier re-reads them from the transcript on each check, so a boundary can
  be lost if context compaction removes the message that stated it. For a durable guarantee, use an ask or deny rule
  instead.
  [permission-modes › Boundaries you state in conversation](https://code.claude.com/docs/en/permission-modes#boundaries-you-state-in-conversation),
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)
- If you tell Claude that a blocked action is allowed, the classifier reads that as your approval and can clear the
  block. How you worded it decides whether the action runs, and how far the approval reaches:
  [permission-modes › Approvals you state in conversation](https://code.claude.com/docs/en/permission-modes#approvals-you-state-in-conversation)
  - **Name the action and its specifics**: your message has to name the action and the specific thing that makes it
    dangerous, such as the branch of a force push. Naming the verb alone clears nothing, so "you can force-push"
    leaves the block in place.
  - **Expect it to cover one action**: an approval covers the destructive action you named, so a later action is
    blocked again unless you granted the approval as standing. To stop approving a routine pattern one action at a
    time, add it to `autoMode.allow`.
  - **Some blocks stay in place**: the classifier's precedence order sets out which blocks your approval can reach. To
    run a step it won't clear, leave auto mode and answer the permission prompt.

## When auto mode falls back

- A blocked action: Claude Code shows a notification and lists the action in `/permissions`.
  [permission-modes › When auto mode falls back](https://code.claude.com/docs/en/permission-modes#when-auto-mode-falls-back)
- Repeated blocks: if the classifier blocks an action 3 times in a row or 20 times total, auto mode pauses and Claude
  Code resumes prompting. Approving the prompted action resumes auto mode.
  [permission-modes › When auto mode falls back](https://code.claude.com/docs/en/permission-modes#when-auto-mode-falls-back)
- A mode switch during a check: if you switch permission modes while a classifier check is pending, Claude Code
  discards a verdict the new mode wouldn't have requested. You're prompted for approval instead, or the action is
  auto-denied in `dontAsk` mode.
  [permission-modes › When auto mode falls back](https://code.claude.com/docs/en/permission-modes#when-auto-mode-falls-back)
- The thresholds of 3 blocks in a row and 20 blocks total are not configurable. The total counter persists for the
  session and resets only when its own limit triggers a fallback. Claude Code doesn't count a denial toward either
  threshold when a safety check separate from auto mode refuses the classifier's own request.
  [permission-modes › Repeated-block thresholds](https://code.claude.com/docs/en/permission-modes#repeated-block-thresholds)
- A non-interactive `-p` run without a `--permission-prompt-tool` has no prompt to fall back to. When repeated blocks
  reach a threshold, the action doesn't run and Claude keeps working. Claude Code doesn't stop the run.
  [permission-modes › Repeated-block thresholds](https://code.claude.com/docs/en/permission-modes#repeated-block-thresholds)
- Repeated blocks usually mean the classifier is missing context about your infrastructure. Use `/feedback` to report
  false positives, or have an administrator configure trusted infrastructure.
  [permission-modes › Repeated-block thresholds](https://code.claude.com/docs/en/permission-modes#repeated-block-thresholds)

## How actions are evaluated

- Each action goes through a fixed decision order. The first matching step wins:
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
  1. Actions matching your allow, ask, or deny rules resolve immediately, with these exceptions:
     - Writes to protected paths route to the classifier even when an allow rule matches. When the protected path is
       the file that a symlinked settings file points to, the write can prompt you instead.
     - No allow rule approves recognized `rm` and `rmdir` critical-path removals.
     - MCP tools marked `requiresUserInteraction` prompt you directly even when an allow rule matches, and so do
       connector tools your organization set to `ask` in sessions where that setting reaches Claude Code.
     - A shell command that carries per-command allowed domains also routes to the classifier even when an allow rule
       matches, because a rule approves the command, not its hosts.
     - Ask rules that match on a command's content, such as `Bash(git push *)`, prompt.
     - A write that the symlink check resolves to a protected path prompts you when the path Claude requested isn't
       itself protected.
     - A read from a network path prompts you even when an allow rule matches.
  2. Read-only actions and file edits in your working directory are auto-approved, except writes to protected paths
     and the first read outside the working directories, which prompts you.
     - In a session with server-side classifier review, read-only and sandboxed shell commands wait for that review
       and are blocked if it flags them; in auto mode the built-in read-only Bash commands can also wait for the
       classifier's review ([permissions › Read-only commands](https://code.claude.com/docs/en/permissions#read-only-commands)).
     - A write inside your working directory that the symlink check resolves to a location outside it prompts you.
     - When Claude reads an artifact someone else made, the approval cases listed in the artifacts documentation apply.
     - A read from a network path prompts you.
  3. Everything else goes to the classifier, apart from critical-path removals under their default handling. The
     connector tools and `requiresUserInteraction` MCP tools that prompt you directly in step 1 never reach the
     classifier either, so neither an org-required approval nor a consent step is auto-approved.
  4. If the classifier blocks, Claude receives the reason. In most sessions the reason names the rule the classifier
     matched, such as `[Data Exfiltration]`, rather than giving a written explanation.
- On entering auto mode, broad allow rules that grant arbitrary code execution are dropped: blanket `Bash(*)` or
  `PowerShell(*)`, wildcarded interpreters like `Bash(python*)`, package-manager run commands, `Agent` allow rules,
  and `Monitor` allow rules, because Claude Code runs Monitor commands through the shell. Narrow rules like
  `Bash(npm test)` stay in effect. Claude Code restores the dropped rules when you leave auto mode.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
- Claude Code also runs `git status` itself before a command that would discard uncommitted work, such as
  `git reset --hard` or `rm -rf`, and shows the classifier whether staged, modified, or untracked work is present.
  Claude Code reports untracked files in that check even when the repository's git configuration sets
  `status.showUntrackedFiles=no`.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
- In the classifier requests sent by Claude Code itself, the classifier sees your messages and the commands Claude
  runs, meaning user messages and tool calls other than read-only lookups such as file reads and searches, and your
  CLAUDE.md content, not their output. Tool results are stripped from those requests, so hostile content in a file or
  web page can't manipulate the classifier directly. A separate server-side probe scans incoming tool results and
  flags suspicious content before Claude reads it.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
- While a subagent runs under auto mode, any `permissionMode` in the subagent's frontmatter is ignored.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
- Cost and latency: Claude Code's classifier requests can run on a model other than your `/model` selection. On
  Enterprise plans and on accounts that use the Claude API, Claude Platform on AWS, Amazon Bedrock, Google Cloud's
  Agent Platform, or Microsoft Foundry, classifier calls count toward your token usage. Each check sends a portion of
  the transcript plus the pending action, adding a round-trip before execution. Reads and working-directory edits
  outside protected paths skip the classifier, so the overhead comes mainly from shell commands and network operations.
  Where the server reviews the actions as part of the session's model requests, there are no separate classifier calls
  to count.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)
- Sandboxed network access adds no per-connection classifier requests: Claude Code checks each connection against the
  approved list without calling the classifier again.
  [permission-modes › How auto mode evaluates actions](https://code.claude.com/docs/en/permission-modes#how-auto-mode-evaluates-actions)

## Where the classifier reads `autoMode`

- For rules that apply across projects, such as trusted infrastructure or organization-wide deny rules, use the
  `autoMode` settings block. The classifier reads `autoMode` from these scopes:
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)

  | Scope | File | Use for |
  | :- | :- | :- |
  | One developer | `~/.claude/settings.json` | Personal trusted infrastructure |
  | Organization-wide | Managed settings | Trusted infrastructure distributed to all developers |
  | `--settings` flag or Agent SDK | Inline JSON | Per-invocation overrides for automation |

- The classifier doesn't read `autoMode` from project settings in `.claude/settings.json` or
  `.claude/settings.local.json`. Both files live in the repo directory, so a checked-in repo or a build step could
  otherwise inject its own allow rules. Move any `autoMode` block in `.claude/settings.local.json` to
  `~/.claude/settings.json`.
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)
- Entries from each scope are combined. A developer can extend `environment`, `allow`, `soft_deny`, and `hard_deny`
  with personal entries but can't remove entries that managed settings provide. Because allow rules act as exceptions
  to soft block rules inside the classifier, a developer-added `allow` entry can override an organization `soft_deny`
  entry: the combination is additive, not a hard policy boundary.
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)
- The classifier is a second gate that runs after the permissions system. For actions that must never run regardless
  of user intent or classifier configuration, use `permissions.deny` in managed settings, which blocks the action
  before the classifier is consulted and can't be overridden.
  [auto-mode-config › Where the classifier reads configuration](https://code.claude.com/docs/en/auto-mode-config#where-the-classifier-reads-configuration)
- `autoMode` adds your own rules to what the classifier blocks and allows. Its scope is user or managed. Type: object
  with `environment`, `allow`, `soft_deny`, and `hard_deny` arrays of prose rules, plus the `classifyAllShell` Boolean.
  Default: unset, so the classifier uses only its built-in rules. Include the literal string `"$defaults"` in an array
  to keep the built-in rules at that position and add yours around them; leave it out to replace them with yours.
  [settings-reference › `autoMode`](https://code.claude.com/docs/en/settings-reference#automode)

## Human checkpoints with ask and deny rules

- Auto mode allows pushes to any branch of the repository you're working in, including the default branch, and pull
  request creation by default. A non-default branch whose name marks it as a deploy or publication target, such as
  `production`, `release`, or `gh-pages`, isn't covered by that default: the classifier judges a push there on its own
  terms, including as a production deploy. The push's content is also still checked, so a force push, a secret
  entering the commit, or a change that would send secrets outside the repository when CI or a deploy pipeline runs it
  stays blocked.
  [auto-mode-config › Common boundaries](https://code.claude.com/docs/en/auto-mode-config#common-boundaries)
- To add a human checkpoint before Claude's push and pull request commands while keeping auto mode on for everything
  else, use `permissions.ask`. Content-scoped ask rules are evaluated before the classifier and always force a
  permission prompt, even in auto mode, because an explicit ask rule is your stated intent to be prompted for that
  action. Add the rules in your settings:
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)

  ```json
  {
    "permissions": {
      "ask": [
        "Bash(git push *)",
        "Bash(gh pr create *)"
      ]
    }
  }
  ```
- These rules match commands that begin with `git push` or `gh pr create`. A push Claude writes another way, such as
  `git -C <dir> push` or `git -c <key>=<value> push`, doesn't match the rule, so it isn't checkpointed.
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)
- Pick the mechanism that matches how firm the boundary needs to be:
  [auto-mode-config › Add a human checkpoint](https://code.claude.com/docs/en/auto-mode-config#add-a-human-checkpoint)

  | Boundary | Mechanism | Behavior in auto mode |
  | :- | :- | :- |
  | Prompt before the action | `permissions.ask` | Always prompts for a command that matches a content-scoped rule like the recipe above. The classifier cannot auto-approve a matching action. |
  | Never run the action | `permissions.deny` | Blocks before the classifier is consulted. Neither the classifier nor user intent can override it. |

## Define trusted infrastructure

- For most organizations, `autoMode.environment` is the only field you need to set. It tells the classifier which
  repos, buckets, and domains are trusted: the classifier uses it to decide what "external" means, so any destination
  not listed is a potential exfiltration target.
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
- `claude auto-mode defaults` prints three kinds of environment entry:
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
  - **Context slots** describe your organization, stack, and security posture so the classifier reads the other rules
    in your context. Each defaults to `None configured` or to the conservative assumption named next to it:
    - **Organization**.
    - **Primary use of Claude Code**: defaults to software development.
    - **Cloud provider(s)**.
    - **Repository visibility**: a repository is assumed private unless its remote host and name indicate otherwise,
      or the classifier reads a visibility check earlier in the conversation showing it is public. The evidence has
      to be something the classifier can read, such as your own message naming the repository as public; the output of
      a `gh repo view` on its own doesn't reach it.
    - **Internal sharing / snippet hosting**: public paste and gist services are treated as outside the trust
      boundary until you name one.
    - **Org-specific CLIs**.
    - **Secrets management**.
    - **CI/CD deploy targets**.
    - **Network posture**.
    - **Host containment**: defaults to an ordinary developer machine or CI runner with open internet. If Claude Code
      runs in a container, VM, or pod with an egress allow-list or neighbors it must not touch, name the allowed
      hosts, whether the cloud metadata endpoint should be reachable, and which cloud project, cluster, or registry
      the task uses and under what identity. Until this entry names that identity, the classifier blocks requests for
      the host's own credentials.
    - **Protected deployment namespaces / environments**: falls back to the Sensitive remote targets heuristic until
      you name them.
    - **Data retention / declassification**.
  - **Trust slots** name what the classifier treats as inside your boundary. The slots are Trusted repo, Source
    control, Trusted internal domains, Trusted cloud buckets, Key internal services, and Internal package registry.
    The repo and source-control entries default to the working repository and its configured remotes. Every other
    trust slot defaults to `None configured`, so nothing else is trusted until you add it. A repository's visibility
    scopes only confidential material: a private repository is an acceptable destination for confidential material,
    but making a repository private never clears secrets or personal or entrusted data into it, and the classifier
    treats content ported, repointed, or first read from outside the working repository as not that repository's own
    work.
  - **Sensitivity slots** name what the protective rules treat as high-risk. The slots are Sensitive data locations &
    audiences, Sensitive remote targets, and Protected IaC scopes. Each defaults to a broad heuristic, such as
    treating any host or namespace whose name carries `prod` or `production` as a sensitive remote target, so the
    protective rules are active before you configure anything. Naming concrete targets in a sensitivity slot makes
    those rules apply to the named targets instead of the heuristic.
- This example keeps the default entries and adds an organization's repos, buckets, domains, and services:
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)

  ```json
  {
    "autoMode": {
      "environment": [
        "$defaults",
        "Source control: github.example.com/acme-corp and all repos under it",
        "Trusted cloud buckets: s3://acme-build-artifacts, gs://acme-ml-datasets",
        "Trusted internal domains: *.corp.example.com, api.internal.example.com",
        "Key internal services: Jenkins at ci.example.com, Artifactory at artifacts.example.com"
      ]
    }
  }
  ```
- After you save your settings, run `claude auto-mode config` to confirm the effective rules include your entries.
  Entries are prose, not regex or tool patterns: the classifier reads them as natural-language rules. Write them the
  way you would describe your infrastructure to a new engineer.
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
- A thorough environment section covers:
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)
  - **Organization**: your company name and what Claude Code is primarily used for, like software development,
    infrastructure automation, or data engineering.
  - **Source control**: every GitHub, GitLab, or Bitbucket org your developers push to.
  - **Cloud providers and trusted buckets**: bucket names or prefixes that Claude should be able to read from and
    write to.
  - **Trusted internal domains**: hostnames for APIs, dashboards, and services inside your network, like
    `*.internal.example.com`.
  - **Key internal services**: CI, artifact registries, internal package indexes, incident tooling.
  - **Internal package registry**: the private npm, PyPI, or other registry that installs should route through, so
    installs that bypass it for a public registry get blocked.
  - **Sensitive data locations & audiences**: the buckets, databases, or paths that hold personal data, confidential
    business data, credentials, regulated data, or similarly sensitive material, and the audiences that data in each
    location may be shared with, so the classifier protects those locations instead of guessing from content.
  - **Sensitive remote targets**: the namespaces, hosts, or containers that count as production, so remote shells and
    port-forwards into them need your explicit approval.
  - **Protected IaC scopes**: the infrastructure resources whose apply or destroy should always require you to name
    the change.
  - **Additional context**: regulated-industry constraints, multi-tenant infrastructure, or compliance requirements
    that affect what the classifier should treat as risky.
- A useful starting template, with the bracketed fields filled in and lines that don't apply removed:
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)

  ```json
  {
    "autoMode": {
      "environment": [
        "$defaults",
        "Organization: {COMPANY_NAME}. Primary use: {PRIMARY_USE_CASE, e.g. software development, infrastructure automation}",
        "Source control: {SOURCE_CONTROL, e.g. GitHub org github.example.com/acme-corp}",
        "Cloud provider(s): {CLOUD_PROVIDERS, e.g. AWS, GCP, Azure}",
        "Trusted cloud buckets: {TRUSTED_BUCKETS, e.g. s3://acme-builds, gs://acme-datasets}",
        "Trusted internal domains: {TRUSTED_DOMAINS, e.g. *.internal.example.com, api.example.com}",
        "Key internal services: {SERVICES, e.g. Jenkins at ci.example.com, Artifactory at artifacts.example.com}",
        "Additional context: {EXTRA, e.g. regulated industry, multi-tenant infrastructure, compliance requirements}"
      ]
    }
  }
  ```
- You don't need to fill everything in at once. A reasonable rollout: start with the defaults and add your source
  control org and key internal services, which resolves the most common false positives like pushing to your own
  repos. Add trusted domains and cloud buckets next. Fill the rest as blocks come up.
  [auto-mode-config › Define trusted infrastructure](https://code.claude.com/docs/en/auto-mode-config#define-trusted-infrastructure)

## Generate environment entries with `/auto-mode-setup`

- Run `/auto-mode-setup` to have Claude Code draft `autoMode.environment` entries, and sometimes rule entries too,
  from your project and your recent sessions in it. If you accept the draft, Claude Code writes it to
  `~/.claude/settings.json`.
  [auto-mode-config › Generate environment entries with `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#generate-environment-entries)
- `/auto-mode-setup` is available on Pro, Max, Ultra, Team, and Enterprise plans and with a Claude Console API key.
  [auto-mode-config › Generate environment entries with `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#generate-environment-entries)
- If `~/.claude/settings.json` already holds `autoMode` entries, Claude Code starts by asking whether to add to your
  environment list or replace it, and keeps the rules you wrote either way. Claude Code then asks how you use this
  project and offers two optional scans before it scans anything.
  [auto-mode-config › What `/auto-mode-setup` reads](https://code.claude.com/docs/en/auto-mode-config#what-auto-mode-setup-reads)
- In the scan, Claude Code always reads this project's `CLAUDE.md`, `README.md`, config files, and git remotes; your
  `autoMode` and `permissions.allow` settings; and the hosts, buckets, and command names from the commands Claude ran
  in your recent sessions in this project, never your messages. The two optional scans add one source each: the first
  word of each command in your shell history, and the remote hosts and names of the repositories under your home
  directory.
  [auto-mode-config › What `/auto-mode-setup` reads](https://code.claude.com/docs/en/auto-mode-config#what-auto-mode-setup-reads)
- Claude Code scans in the background, then shows you the draft. You accept or discard it as a whole, so edit
  `~/.claude/settings.json` afterwards to adjust single entries. When you accept, Claude Code writes the draft and
  reconciles it with the settings you already have:
  [auto-mode-config › Review and save the draft](https://code.claude.com/docs/en/auto-mode-config#review-and-save-the-draft)
  - Claude Code writes the `environment` list without `"$defaults"`, because the draft spells out the built-in entries
    it left unchanged.
  - Claude Code includes `"$defaults"` in each of the `allow`, `soft_deny`, and `hard_deny` lists the draft adds
    entries to, unless you already wrote an `allow` list without it, so the built-in rules you haven't replaced stay
    in effect.
  - After saving, Claude Code offers to remove `permissions.allow` rules in `~/.claude/settings.json` that auto mode
    ignores, such as `Bash(*)`, or that auto-approve destructive commands.
- Then run `claude auto-mode config` to see the effective result.
  [auto-mode-config › Review and save the draft](https://code.claude.com/docs/en/auto-mode-config#review-and-save-the-draft)
- Once auto mode has blocked several actions and you still have no `autoMode.environment` entries, Claude Code shows a
  dialog titled "Teach auto mode about your environment?" at the end of a turn and offers to run `/auto-mode-setup` for
  you. To stop the offer but keep the command, select **Don't show again** in that dialog.
  [auto-mode-config › Turn off `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#turn-off-auto-mode-setup)
- To turn off both the command and the offer, add this `skillOverrides` entry to `~/.claude/settings.json`:
  [auto-mode-config › Turn off `/auto-mode-setup`](https://code.claude.com/docs/en/auto-mode-config#turn-off-auto-mode-setup)

  ```json
  {
    "skillOverrides": {
      "auto-mode-setup": "off"
    }
  }
  ```
- If typing `/auto-mode-setup` at the Claude Code prompt prints `Unknown command: /auto-mode-setup`, check for these
  causes:
  [auto-mode-config › `/auto-mode-setup` returns "Unknown command"](https://code.claude.com/docs/en/auto-mode-config#auto-mode-setup-returns-unknown-command)
  - **First session after an install or upgrade**: start a new session.
  - **Outdated version**: run `claude --version` in your shell. If the version is below the minimum for your plan,
    update Claude Code.
  - **Telemetry off, third-party provider, or Claude apps gateway**: if the command is missing in a session where
    feature-flag fetching is off, update Claude Code.
- In a cloud session, the command prints `/auto-mode-setup isn't available in this environment.` instead. Run it in an
  interactive session in your terminal.
  [auto-mode-config › `/auto-mode-setup` returns "Unknown command"](https://code.claude.com/docs/en/auto-mode-config#auto-mode-setup-returns-unknown-command)

## Override the block and allow rules

- Three additional fields let you replace the classifier's built-in rule lists: `autoMode.hard_deny` (unconditional
  security boundaries), `autoMode.soft_deny` (destructive actions that user intent can clear) and `autoMode.allow`
  (exceptions to soft block rules). Each is an array of prose descriptions, read as natural-language rules.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- Inside the classifier, precedence works in four tiers:
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
  - `hard_deny` rules block unconditionally. User intent and `allow` exceptions don't apply.
  - `soft_deny` rules block next. User intent and `allow` exceptions can override these.
  - `allow` rules then override matching `soft_deny` rules as exceptions.
  - Explicit user intent overrides the remaining soft blocks: if the user's message directly and specifically
    describes the exact action Claude is about to take, the classifier allows it even when a `soft_deny` rule matches.
- General requests don't count as explicit intent. Asking Claude to "clean up the repo" doesn't authorize
  force-pushing, but asking Claude to "force-push this branch" does.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- To loosen, add to `allow` when the classifier repeatedly flags a routine pattern the default exceptions don't cover.
  To tighten, add to `soft_deny` for destructive risks specific to your environment that the defaults miss, or to
  `hard_deny` for security boundaries that must never be crossed.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- This example keeps the defaults in all four lists and adds organization-specific rules to each:
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)

  ```json
  {
    "autoMode": {
      "environment": [
        "$defaults",
        "Source control: github.example.com/acme-corp and all repos under it"
      ],
      "allow": [
        "$defaults",
        "Deploying to the staging namespace is allowed: staging is isolated from production and resets nightly",
        "Writing to s3://acme-scratch/ is allowed: ephemeral bucket with a 7-day lifecycle policy"
      ],
      "soft_deny": [
        "$defaults",
        "Never run database migrations outside the migrations CLI, even against dev databases",
        "Never modify files under infra/terraform/prod/: production infrastructure changes go through the review workflow"
      ],
      "hard_deny": [
        "$defaults",
        "Never send repository contents to third-party code-review APIs"
      ]
    }
  }
  ```
- Setting any of `environment`, `allow`, `soft_deny`, or `hard_deny` without `"$defaults"` replaces the entire default
  list for that section. If you set an array without `"$defaults"`, you discard the built-in rules for that section:
  for `soft_deny`, every built-in soft block rule, including force push, `curl | bash`, production deploys, and
  auto-mode bypass; for `hard_deny`, the built-in data exfiltration rule.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- With `"$defaults"` you continue to inherit updates as the built-in list changes across releases.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- Each section is evaluated independently, so setting `environment` alone leaves the default `allow`, `soft_deny`, and
  `hard_deny` lists intact. Only omit `"$defaults"` when you intend to take full ownership of the list. To do that
  safely, run `claude auto-mode defaults` to print the built-in rules, copy them into your settings file, then review
  each rule against your own pipeline and risk tolerance.
  [auto-mode-config › Override the block and allow rules](https://code.claude.com/docs/en/auto-mode-config#override-the-block-and-allow-rules)
- To view and edit classifier rules and `environment` entries without opening a settings file, run `/permissions` and
  select the **Auto mode** tab. The tab appears only when auto mode is available to your session. Claude Code shows
  entries from managed settings or the `--settings` flag as read-only, and saves every change you make on the tab to
  `~/.claude/settings.json`.
  [auto-mode-config › Edit rules from `/permissions`](https://code.claude.com/docs/en/auto-mode-config#edit-rules-from-permissions)
  [permissions › Manage permissions](https://code.claude.com/docs/en/permissions#manage-permissions)

## Related settings keys

- `autoMode.classifyAllShell` sends every Bash and PowerShell command through the auto mode classifier while auto mode
  is active. By default, auto mode suspends only allow rules that could run arbitrary code: tool-wide and wildcard
  rules such as `Bash(*)`, and interpreter or shell-wrapper prefixes such as `Bash(python *)`. A command that any other
  allow rule matches, such as `Bash(npm test)`, skips the classifier unless it carries per-command allowed domains.
  When it skips, a destructive argument the rule's prefix didn't anticipate can get through unseen. Setting this key
  suspends every shell allow rule for the session so the classifier sees every command.
  [settings-reference › `autoMode.classifyAllShell`](https://code.claude.com/docs/en/settings-reference#automode-classifyallshell)
- `autoMode.classifyAllShell`: scope is user or managed, read wherever `autoMode` is read. Type: Boolean. Default:
  `false`.
  [settings-reference › `autoMode.classifyAllShell`](https://code.claude.com/docs/en/settings-reference#automode-classifyallshell)

  ```json
  {
    "autoMode": {
      "classifyAllShell": true
    }
  }
  ```
- `classifyAllShell` trades latency for coverage: a command that an allow rule would have approved instantly now waits
  for a classifier decision, and each shell command counts as a classifier call. Critical-path removals are still
  excepted. The setting applies only while auto mode is active, and your allow rules behave normally in other
  permission modes.
  [auto-mode-config › Route all shell commands through the classifier](https://code.claude.com/docs/en/auto-mode-config#route-all-shell-commands-through-the-classifier)
- `useAutoModeDuringPlan` chooses whether Claude Code uses the auto mode classifier to review shell commands in plan
  mode. Appears in `/config` as **Use auto mode during plan**.
  [settings-reference › `useAutoModeDuringPlan`](https://code.claude.com/docs/en/settings-reference#useautomodeduringplan)
- `useAutoModeDuringPlan`: scope is user, local, or managed; a repository can't turn it off for you. Type: Boolean;
  `true` is the same as unset, and a `false` in any of these files still turns it off. Default: `true`.
  [settings-reference › `useAutoModeDuringPlan`](https://code.claude.com/docs/en/settings-reference#useautomodeduringplan)

  ```json
  {
    "useAutoModeDuringPlan": false
  }
  ```
- `skipAutoPermissionPrompt` skips the one-time notice describing auto mode that Claude Code shows when you first enter
  auto mode yourself, for example through your own settings or the mode selector, rather than when the built-in
  default starts a session in it. Claude Code shows that notice once and then records that it was shown, so this key
  only matters where the notice hasn't appeared yet.
  [settings-reference › `skipAutoPermissionPrompt`](https://code.claude.com/docs/en/settings-reference#skipautopermissionprompt)
- `skipAutoPermissionPrompt`: scope is user or managed; a repository can't set it for you. Type: Boolean; `false` is
  the same as unset, so the notice appears once unless another of these files sets `true`. Default: unset, so the
  notice appears once.
  [settings-reference › `skipAutoPermissionPrompt`](https://code.claude.com/docs/en/settings-reference#skipautopermissionprompt)

  ```json
  {
    "skipAutoPermissionPrompt": true
  }
  ```

## The `claude auto-mode` subcommands

- `claude auto-mode defaults` prints the built-in `environment`, `allow`, `soft_deny`, and `hard_deny` rules as JSON.
  To read one rule's full wording without piping through `jq`, pass `--label` with the start of the rule's label, such
  as `claude auto-mode defaults --label 'Git Destructive'`. Matching is a case-insensitive prefix on each rule's
  label, and sections with no match print as empty lists.
  [auto-mode-config › Inspect the defaults and your effective config](https://code.claude.com/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config)
- `claude auto-mode config` prints what the classifier actually uses as JSON, with your settings applied where set and
  defaults otherwise. Both `defaults` and `config` print the four rule lists as a single JSON object, with each rule
  as a prose string.
  [auto-mode-config › Inspect the defaults and your effective config](https://code.claude.com/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config)
- `claude auto-mode critique` gets AI feedback on your custom `allow`, `soft_deny`, `hard_deny`, and `environment`
  entries: it flags entries that are ambiguous, redundant, or likely to cause false positives.
  [auto-mode-config › Inspect the defaults and your effective config](https://code.claude.com/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config)
- `claude auto-mode reset` discards your customizations and returns to the built-in defaults by removing the
  `autoMode` section from your user settings file. The command summarizes what it will remove and asks
  `Reset auto mode configuration to defaults?` before writing; pass `--yes` to skip the confirmation. Reset changes
  only `~/.claude/settings.json`: `autoMode` rules from managed settings or the `--settings` flag still apply.
  [auto-mode-config › Inspect the defaults and your effective config](https://code.claude.com/docs/en/auto-mode-config#inspect-the-defaults-and-your-effective-config)

## Review and fix denials

- To review and retry actions the auto mode classifier denied, open `/permissions` and select the **Recently denied**
  tab, where Claude Code records each denial. Press `r` on a denied action to retry it with a manual approval: when you
  exit the dialog, Claude Code sends a message telling the model it may retry that tool call and resumes the
  conversation.
  [permission-modes › When auto mode falls back](https://code.claude.com/docs/en/permission-modes#when-auto-mode-falls-back)
  [auto-mode-config › Review denials](https://code.claude.com/docs/en/auto-mode-config#review-denials)
- When the classifier produces no verdict on the action, because a safety check separate from auto mode refused the
  classifier's own request or its response didn't parse, Claude Code denies the action without the notification or the
  **Recently denied** entry.
  [permission-modes › When auto mode falls back](https://code.claude.com/docs/en/permission-modes#when-auto-mode-falls-back)
  [auto-mode-config › Review denials](https://code.claude.com/docs/en/auto-mode-config#review-denials)
- To read the command or URL behind a notice such as `bash denied by auto mode · [Data Exfiltration] · /permissions`,
  use the **Recently denied** tab or the conversation:
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)
  - **Recently denied tab**: in the `/permissions` dialog, highlight a denied Bash or PowerShell action to read its
    command below the list. In screen reader mode, all the commands appear before the list instead.
  - **Conversation**: find the tool call. If the call appears shortened or folded into a summary line such as
    `Ran 3 shell commands`, press `Ctrl+O` to open the transcript viewer, which expands it.
- The text beneath the call tells you whether there is anything to fix. A dim
  `Not run · auto mode's check had no usable answer` row, or text that reports a problem with the classifier itself,
  such as `Auto mode could not evaluate this action`, means Claude Code blocked the call without a verdict from the
  classifier. For a `Not run` row, press `Ctrl+O` to read the full message.
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)
- A line reading `Denied by auto mode classifier` with a reason such as `[Production Deploy]` or
  `Blocked by classifier` means the classifier judged the call unsafe, so pick the fix from what the call was trying to
  reach or do:
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)
  - A destination Claude needs throughout the task, such as a package registry, an internal domain, or a repository
    host: add it to `autoMode.environment`.
  - A command you want to run without review from now on: add an `allow` rule.
  - A one-off action you did intend: state that intent in your next message and let Claude retry.
- The text in square brackets, such as `[Data Exfiltration]`, is the name of the rule the classifier matched; to read
  that rule's full wording, use `claude auto-mode defaults`.
  [auto-mode-config › Fix a denial with an allow rule, an environment entry, or a retry](https://code.claude.com/docs/en/auto-mode-config#fix-a-denial-with-an-allow-rule-an-environment-entry-or-a-retry)

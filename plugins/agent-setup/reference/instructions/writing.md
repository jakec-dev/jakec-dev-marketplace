# Writing instruction files

Writing the body of a CLAUDE.md or rule file: `@path` imports, HTML comments, size, contradicting instructions and
compaction instructions.

## Contents

- Imports
- HTML comments
- Size
- Contradicting instructions
- Compaction instructions
- Reasoning instructions
- Not stated by the documentation

## Imports

- CLAUDE.md files can import additional files using `@path/to/import` syntax. Imported files are expanded and loaded
  into context alongside the CLAUDE.md that references them.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- Both relative and absolute paths are allowed. Relative paths resolve relative to the file containing the import,
  not the working directory.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- Imported files can recursively import other files, with a maximum depth of four hops.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- An `@` import can go anywhere in a CLAUDE.md. This example pulls in a README, `package.json` and a workflow
  guide:
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

  ```text
  See @README for project overview and @package.json for available npm commands for this project.

  # Additional Instructions
  - git workflow @docs/git-instructions.md
  ```

- To import a file whose path contains spaces, put a backslash before each space. Without the backslashes, the path
  ends at the first space, even when the import is on a line of its own. A path wrapped in quotes isn't imported at
  all, with or without the backslashes. This import loads a file from a folder named `Design Docs`:
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

  ```text
  - API conventions @Design\ Docs/api-conventions.md
  ```

- Import parsing skips Markdown code spans and fenced code blocks. To mention a path in a CLAUDE.md without
  importing it, wrap it in backticks: `` `@README` `` keeps the text literal, while `@README` outside backticks
  imports the file.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

## HTML comments

- Block-level HTML comments (`<!-- maintainer notes -->`) in CLAUDE.md files are stripped before the content is
  injected into Claude's context, so they hold notes for human maintainers without spending context tokens.
  Comments inside code blocks are preserved.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- When you open a CLAUDE.md file directly with the Read tool, comments remain visible.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)

## Size

- For CLAUDE.md files, files over 200 lines consume more context and may reduce adherence.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Splitting a CLAUDE.md into `@path` imports helps organization but doesn't reduce its context cost, because
  imported files load together with the CLAUDE.md that imports them.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Claude gets the whole of each CLAUDE.md file that loads at launch, as long as the file is 4 MiB or smaller. Claude
  Code skips a file over 4 MiB and loads none of it.
  [memory › How it works](https://code.claude.com/docs/en/memory#how-it-works),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Keep each path-scoped rules file within its per-file limit.
  [memory › How it works](https://code.claude.com/docs/en/memory#how-it-works),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- When a subdirectory `CLAUDE.md` or a rules file that loads on demand is over a per-file size limit, Claude
  receives only the start of it. That part ends with a note telling Claude to read the rest with the Read tool, and
  until Claude chooses to, the later instructions aren't in its context.
  [memory › Claude ignores the end of my subdirectory CLAUDE.md](https://code.claude.com/docs/en/memory#claude-ignores-the-end-of-my-subdirectory-claude-md)
- The per-file limit applies to these files, which load on demand:
  [memory › Claude ignores the end of my subdirectory CLAUDE.md](https://code.claude.com/docs/en/memory#claude-ignores-the-end-of-my-subdirectory-claude-md)
  - `CLAUDE.md` and `CLAUDE.local.md` in a subdirectory of the directory where you started Claude Code, and the files
    they import with `@path`
  - Rules files in a subdirectory's `.claude/rules/`
  - Path-scoped rules in your project's `.claude/rules/` or in `~/.claude/rules/`
- The per-file limit depends on your session's context window:
  [memory › Claude ignores the end of my subdirectory CLAUDE.md](https://code.claude.com/docs/en/memory#claude-ignores-the-end-of-my-subdirectory-claude-md)
  - 200K context window: 40,000 characters
  - 1M context window: 200,000 characters on Claude Opus 4.6 and Claude Sonnet 4.6, and 150,000 characters on later
    models

## Contradicting instructions

- If two instructions contradict each other, Claude may pick one arbitrarily.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- CLAUDE.md files are additive across levels: all levels contribute content to Claude's context simultaneously. When
  instructions conflict, Claude uses judgment to reconcile them.
  [features-overview › Understand how features layer](https://code.claude.com/docs/en/features-overview#understand-how-features-layer)

## Compaction instructions

- To control what's preserved during compaction, add a "Compact Instructions" section to CLAUDE.md.
  [how-claude-code-works › When context fills up](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up)
- You can customize compaction behavior in your CLAUDE.md file at the root of your project:
  [costs › Manage context proactively](https://code.claude.com/docs/en/costs#manage-context-proactively)

  ```markdown
  # Compact instructions

  When you are using compact, please focus on test output and code changes
  ```

## Reasoning instructions

- Remove or reword any instruction in CLAUDE.md that asks Claude to write out its thinking or reasoning verbatim or in
  a fixed format, such as a `<thinking>` section, a scratchpad section or a `reasoning` field in JSON output. Such an
  instruction can make the API decline the request.
  [errors › Safeguards flagged a request for Claude's reasoning](https://code.claude.com/docs/en/errors#safeguards-flagged-a-request-for-claudes-reasoning)

## Not stated by the documentation

- Block-level HTML comments are stated to be stripped from CLAUDE.md files; the documentation does not say whether
  they are stripped from `.claude/rules/` files or `AGENTS.md`.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- The documentation does not say whether the 4 MiB limit counts a CLAUDE.md together with its imports.
  [memory › How it works](https://code.claude.com/docs/en/memory#how-it-works)
- The documentation does not say whether an import that would exceed four hops is skipped silently or reported.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- One page names the CLAUDE.md section "Compact Instructions" and another shows the heading `# Compact instructions`.
  The documentation does not say whether the heading must match either spelling. For the Agent SDK, the agent loop
  page says the compactor matches on intent, so the section header is free-form.
  [how-claude-code-works › When context fills up](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up),
  [costs › Manage context proactively](https://code.claude.com/docs/en/costs#manage-context-proactively),
  [agent-sdk/agent-loop › Automatic compaction](https://code.claude.com/docs/en/agent-sdk/agent-loop#automatic-compaction)

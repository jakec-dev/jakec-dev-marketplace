# Writing instruction files

Writing the body of a CLAUDE.md, `AGENTS.md` or rule file: format, `@path` imports, HTML comments, size and
contradicting instructions, compaction instructions.

## Contents

- Format
- Imports
- HTML comments
- Size
- Contradicting instructions
- Compaction instructions
- Not stated by the documentation

## Format

- There's no required format for CLAUDE.md files.
  [best-practices › Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md)

## Imports

- CLAUDE.md files can import additional files using `@path/to/import` syntax. Imported files are expanded and loaded
  into context at launch alongside the CLAUDE.md that references them. They are also expanded in an `AGENTS.md`
  that Claude reads, where an external import loads only if already approved.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files),
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md),
  [memory › Where AGENTS.md differs from CLAUDE.md](https://code.claude.com/docs/en/memory#where-agents-md-differs-from-claude-md)
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

- To import a path containing spaces, put a backslash before each space. Without the backslashes, the path ends at
  the first space, even when the import is on a line of its own. A path wrapped in quotes isn't imported at all,
  with or without the backslashes. This import loads a file from a folder named `Design Docs`:
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)

  ```text
  - API conventions @Design\ Docs/api-conventions.md
  ```

- Import parsing skips Markdown code spans and fenced code blocks. To mention a path in a CLAUDE.md without
  importing it, wrap it in backticks: `` `@README` `` stays literal, while `@README` outside backticks imports the
  file.
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
  imported files also load at launch.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Claude Code loads a CLAUDE.md file of up to 4 MiB in full and skips a larger file.
  [memory › How it works](https://code.claude.com/docs/en/memory#how-it-works),
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)

## Contradicting instructions

- If two instructions contradict each other, Claude may pick one arbitrarily.
  [memory › Write effective instructions](https://code.claude.com/docs/en/memory#write-effective-instructions)
- The pages differ: for CLAUDE.md files at different levels, which are additive, features-overview says that when
  their instructions conflict, Claude uses judgment to reconcile them.
  [features-overview › Understand how features layer](https://code.claude.com/docs/en/features-overview#understand-how-features-layer)

## Compaction instructions

- To control what's preserved during compaction, add a "Compact Instructions" section to CLAUDE.md; costs places it
  in the CLAUDE.md file at the root of your project, and shows it with this heading:
  [how-claude-code-works › When context fills up](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up),
  [costs › Manage context proactively](https://code.claude.com/docs/en/costs#manage-context-proactively)

  ```markdown
  # Compact instructions

  When you are using compact, please focus on test output and code changes
  ```

## Not stated by the documentation

- Block-level HTML comments are stated to be stripped from CLAUDE.md files; the documentation does not say whether
  they are stripped from `.claude/rules/` files or `AGENTS.md`.
  [memory › How CLAUDE.md files load](https://code.claude.com/docs/en/memory#how-claude-md-files-load)
- The documentation does not say whether a file over 4 MiB that is a rule file or an `@path` import is skipped
  alone, or whether the limit counts a CLAUDE.md together with its imports.
  [memory › My CLAUDE.md is too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)
- Imports in user-scope `~/.claude/rules/` files are stated to load; the documentation does not say whether an
  `@path` import in a project `.claude/rules/` file is expanded.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- The documentation does not say whether an import that would exceed four hops is skipped silently or reported.
  [memory › Import additional files](https://code.claude.com/docs/en/memory#import-additional-files)
- One page names the CLAUDE.md section "Compact Instructions" and another shows the heading `# Compact instructions`;
  a third gives only the wording of an instruction, without saying where in CLAUDE.md it goes. The documentation
  does not say whether the heading must match either spelling. For the Agent SDK, the agent loop page says the
  compactor matches on intent, so the section header is free-form.
  [how-claude-code-works › When context fills up](https://code.claude.com/docs/en/how-claude-code-works#when-context-fills-up),
  [costs › Manage context proactively](https://code.claude.com/docs/en/costs#manage-context-proactively),
  [agent-sdk/agent-loop › Automatic compaction](https://code.claude.com/docs/en/agent-sdk/agent-loop#automatic-compaction),
  [best-practices › Manage context aggressively](https://code.claude.com/docs/en/best-practices#manage-context-aggressively)

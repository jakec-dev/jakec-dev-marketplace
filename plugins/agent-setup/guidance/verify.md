# Verifying a tool

Proving that a tool works before calling it done.

## It loaded

- For a project CLAUDE.md: "To confirm the file loaded, run `/context` in a session and check the list under
  **Memory files**." The `InstructionsLoaded` hook logs "which `CLAUDE.md` and rules files are loaded, when they
  load, and why", which the documentation calls "useful for debugging path-specific rules or lazy-loaded files in
  subdirectories".
  [memory › Set up a project CLAUDE.md](https://code.claude.com/docs/en/memory#set-up-a-project-claude-md)
  [memory › Claude isn't following my CLAUDE.md](https://code.claude.com/docs/en/memory#claude-isn’t-following-my-claude-md)
- For an `AGENTS.md` that Claude reads through the **Project instructions** setting, `InstructionsLoaded` hooks
  don't fire; they fire as usual for an `AGENTS.md` that a `CLAUDE.md` imports or symlinks to.
  [memory › Where AGENTS.md differs from CLAUDE.md](https://code.claude.com/docs/en/memory#where-agents-md-differs-from-claude-md)
- When Claude reads `AGENTS.md` at session start, an interactive session shows a line such as
  `no CLAUDE.md found; AGENTS.md loaded: /home/you/repo/AGENTS.md`. "To check whether Claude read your `AGENTS.md`,
  run `/memory` and look for its path in the list."
  [memory › When Claude Code reads AGENTS.md](https://code.claude.com/docs/en/memory#when-claude-code-reads-agents-md)
  [memory › My AGENTS.md isn't loading](https://code.claude.com/docs/en/memory#my-agents-md-isn’t-loading)
- Check: the tool's user is told how to confirm it loaded, and for a path-scoped rule, which file to open to trigger
  it.

## It changes what Claude does

- For CLAUDE.md: "test changes by observing whether Claude's behavior actually shifts."
  [best-practices › Write an effective CLAUDE.md](https://code.claude.com/docs/en/best-practices#write-an-effective-claude-md)
- Check: each new instruction comes with a prompt or task that shows the behaviour it should change.

## Work the tool does has a check

- "Give Claude a check it can run: tests, a build, a screenshot to compare." "Give Claude something that produces a
  pass or fail, and the loop closes on its own." How hard the check gates the stop:
  - In one prompt: ask Claude to run the check and iterate in the same message.
  - Across a session: set the check as a `/goal` condition.
  - As a deterministic gate: a Stop hook runs the check as a script and blocks the turn from ending until it passes.
  - By a second opinion: a verification subagent or a dynamic workflow has a fresh model try to refute the result.

  [best-practices › Give Claude a way to verify its work](https://code.claude.com/docs/en/best-practices#give-claude-a-way-to-verify-its-work)
- "Have Claude show evidence rather than asserting success: the test output, the command it ran and what it
  returned, or a screenshot of the result."
  [best-practices › Give Claude a way to verify its work](https://code.claude.com/docs/en/best-practices#give-claude-a-way-to-verify-its-work)
- Check: a tool that directs work names the check that ends it and asks for evidence, not a claim of success.

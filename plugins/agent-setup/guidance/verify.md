# Verifying a tool

Proving that a tool works before calling it done.

## Contents

- [It loaded](#it-loaded)
- [Work the tool does has a check](#work-the-tool-does-has-a-check)
- [A hook is seen to load and to act](#a-hook-is-seen-to-load-and-to-act)
- [A skill is checked for triggering and for output, separately](#a-skill-is-checked-for-triggering-and-for-output-separately)
- [A skill is compared with a fresh run without it](#a-skill-is-compared-with-a-fresh-run-without-it)
- [Watch which bundled files Claude opens](#watch-which-bundled-files-claude-opens)
- [A skill is tested on every model it will run on](#a-skill-is-tested-on-every-model-it-will-run-on)
- [Skills that change many files validate a plan first](#skills-that-change-many-files-validate-a-plan-first)
- [A skill's validation script names the problem](#a-skills-validation-script-names-the-problem)
- [A skill's steps loop until validation passes](#a-skills-steps-loop-until-validation-passes)
- [A skill is tried on real tasks and by its users](#a-skill-is-tried-on-real-tasks-and-by-its-users)

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

## Work the tool does has a check

- "Give Claude something it can run that comes back pass or fail. Once it has that, it can keep going on its own and
  you don't have to watch." "If your repo already has one of these, the single most useful line in your `CLAUDE.md` is
  the command that runs it." How strict the check is goes "from Claude deciding for itself all the way to Claude Code
  enforcing it":
  - In the prompt, such as `run the auth tests after, and keep going until they pass`: "Claude decides for itself when
    it's satisfied."
  - As a goal: `/goal` "sets a condition that a separate model checks against the conversation after every turn, and
    Claude keeps going until it's met"; it "matters for long background runs". If Claude stalls, Claude Code
    eventually stops the run with the goal still set.
  - As a Stop hook: it "runs your script whenever Claude tries to end its turn, and sends Claude back to work if the
    script exits with code 2", enforced by Claude Code. The block has a cap: after stop hooks have continued the turn
    eight times in a row, Claude Code overrides the next block and ends the turn. "The count of consecutive
    continuations resets each time Claude calls a tool." `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP` raises the cap.
  - By someone who didn't write the code: in the terminal, `/code-review` "reviews the diff in a fresh subagent that
    never saw your conversation."

  [best-practices › Give Claude a check to run](https://code.claude.com/docs/en/best-practices#give-claude-a-check-to-run)
  [hooks › Stop input](https://code.claude.com/docs/en/hooks#stop-input)
  [goal › How evaluation works](https://code.claude.com/docs/en/goal#how-evaluation-works)
- "Whichever option you use, ask Claude for *evidence*: the command it ran and its output, or the screenshot. "All
  tests pass" on its own tells you very little".
  [best-practices › Give Claude a check to run](https://code.claude.com/docs/en/best-practices#give-claude-a-check-to-run)
- Telling Claude to "keep going, loop until done, don't be lazy" is advice current models have made unnecessary:
  "lines like that are more likely to cause over-work than fix a stall. Giving Claude a check to pass is different,
  and still worth doing."
  [best-practices › What you can stop doing](https://code.claude.com/docs/en/best-practices#what-you-can-stop-doing)
- Check: does a tool that directs work name a check that comes back pass or fail, ask for evidence such as the command
  and its output rather than a claim of success, and use no "keep going" line in place of a check?

## A hook is seen to load and to act

- For a `PreToolUse` hook that rewrites a Bash command, as in the documentation's example: "To verify the setup, run
  `/hooks` and check that the hook appears under PreToolUse." Start Claude Code with
  `claude --debug-file ./claude-debug.txt` and ask Claude to run `npm test`; when the hook rewrites the command, that
  log file contains a `modified tool input keys` line listing `command` and the other Bash input fields.
  [costs › Offload processing to hooks and skills](https://code.claude.com/docs/en/costs#offload-processing-to-hooks-and-skills)
- Because command hooks run with your full user permissions: "Review and test all hook commands before adding them to
  your configuration."
  [hooks › Disclaimer](https://code.claude.com/docs/en/hooks#disclaimer)
- Run a task that should trigger the hook and look for its effect. For the page's formatter hook: "To check the hook,
  ask Claude to add a badly indented line to a file Prettier formats. The saved file comes back with the indentation
  fixed."
  [best-practices › Enforce steps with hooks](https://code.claude.com/docs/en/best-practices#enforce-steps-with-hooks)
  For its typecheck Stop hook: "To see it work, ask Claude for a change that breaks a type: instead of finishing, it
  gets the compiler errors back and keeps going until `tsc` passes."
  [best-practices › Enforce the check with a Stop hook](https://code.claude.com/docs/en/best-practices#enforce-the-check-with-a-stop-hook)
- Check: was each hook command tested before it was added, seen under its event in `/hooks`, and shown to have its
  effect on a task that should trigger it, and, for a hook that rewrites a tool's input, does the debug log show a
  `modified tool input keys` line after such a task?

## A skill is checked for triggering and for output, separately

- "Seeing a skill trigger tells you Claude found it, not that it did what you intended. To know a skill is working,
  measure separately whether Claude invokes it on the prompts it should, and whether the output matches what you
  expect when it does." The skill-creator plugin's description tuning "generates should-trigger and
  should-not-trigger prompts, measures the hit rate, and proposes description edits when the skill activates on the
  wrong requests".
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
  [skills › Run evals with skill-creator](https://code.claude.com/docs/en/skills#run-evals-with-skill-creator)
- Check: Do the test prompts include some where the skill should trigger and some where it should not, and is the
  output checked when it does?

## A skill is compared with a fresh run without it

- "Collect a few realistic prompts, run each one in a fresh session with the skill available and again with it
  turned off, and compare the results. A fresh session matters because leftover context from authoring the skill
  will mask gaps in the written instructions."
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
- To turn the skill off for the second run: for a personal or project skill, set it to `"off"` in `skillOverrides`.
  `skillOverrides` doesn't apply to a skill a plugin provides; use `claude plugin eval`, which repeats each run with no
  plugin loaded.
  [skills › Evaluate and iterate on a skill](https://code.claude.com/docs/en/skills#evaluate-and-iterate-on-a-skill)
- Check: Was the skill's output compared with a fresh-session run of the same prompts with the skill turned off?

## Watch which bundled files Claude opens

- When iterating on a skill, watch how Claude uses it. "**Ignored content:** If Claude never accesses a bundled
  file, it might be unnecessary or poorly signaled in the main instructions". "**Missed connections:** Does Claude
  fail to follow references to important files? Your links might need to be more explicit or prominent".
  [best-practices › Observe how Claude navigates Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#observe-how-claude-navigates-skills)
- Check: For a skill with bundled files, has a real run been checked for files Claude never opened?

## A skill is tested on every model it will run on

- "Skills act as additions to models, so effectiveness depends on the underlying model. Test your Skill with all the
  models you plan to use it with."
  [best-practices › Test with all models you plan to use](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#test-with-all-models-you-plan-to-use)
- Check: Has the skill been run on each model it is expected to run on?

## Skills that change many files validate a plan first

- "The "plan-validate-execute" pattern catches errors early by having Claude first create a plan in a structured
  format, then validate that plan with a script before executing it." When to use it: "Batch operations,
  destructive changes, complex validation rules, high-stakes operations."
  [best-practices › Create verifiable intermediate outputs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#create-verifiable-intermediate-outputs)
- Check: Does a skill that makes batch or destructive changes write a plan file and validate it with a script before
  applying it?

## A skill's validation script names the problem

- For the plan-validate-execute pattern: "Make validation scripts verbose with specific error messages such as "Field
  'signature_date' not found. Available fields: customer_name, order_total, signature_date_signed" to help Claude fix
  issues."
  [best-practices › Create verifiable intermediate outputs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#create-verifiable-intermediate-outputs)
- Check: Does the validation script's error message say which item failed and what would have been valid?

## A skill's steps loop until validation passes

- "**Common pattern:** Run validator → fix errors → repeat". The validator can be a script or a reference document
  such as a style guide that Claude reads and compares against. The source's script example tells Claude to validate
  right after an edit, fix the errors, validate again, and "Only proceed when validation passes"; its style-guide
  example ends "Only proceed when all requirements are met".
  [best-practices › Implement feedback loops](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#implement-feedback-loops)
- Check: Do the skill's steps say to fix the errors and validate again, and to proceed only when validation passes?

## A skill is tried on real tasks and by its users

- When iterating on an existing skill, give Claude (with the skill loaded) "actual tasks, not test scenarios", and
  observe where it struggles, succeeds or makes unexpected choices. To gather team feedback, share the skill with
  teammates, observe their usage, and ask: "Does the Skill activate when expected? Are instructions clear? What's
  missing?"
  [best-practices › Develop Skills iteratively with Claude](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#develop-skills-iteratively-with-claude)
  [best-practices › Checklist for effective Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#checklist-for-effective-skills)
- Check: Has the skill been run on real tasks, and has someone who uses it said whether it activates when expected?

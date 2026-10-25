# Guidance

What makes a Claude tool good: when to make one, which kind, how to write it and how to prove it works. Read the key
principles for every task, then the sections your task needs. Each section ends with a `Check:` line that the writer
follows and the auditor applies.

## Contents

- [Key principles](#key-principles)
- [Topics](#topics)

## Key principles

- Make a tool only for a trigger that has happened, such as Claude getting a convention wrong twice.
  See [discover.md › Add a tool when a trigger appears](discover.md).
- Leave out what Claude can work out from the code or already knows.
  See [discover.md › What the codebase already says](discover.md).
- In a repository that relies on `AGENTS.md`, never add a lone `CLAUDE.md` or `CLAUDE.local.md`: Claude then stops
  reading `AGENTS.md`. See [choose.md › The instruction file the repository already uses](choose.md).
- What must happen every time is a hook; an instruction is a request, not a guarantee.
  See [choose.md › Must happen every time: a hook](choose.md).
- Load an instruction only where it is needed: every session, some paths, or on demand.
  See [choose.md › One part of the codebase: a path-scoped rule or a nested CLAUDE.md](choose.md).
- Keep a line only if removing it would cause Claude to make mistakes.
  See [write.md › Earn every line](write.md).
- Write instructions concrete enough that someone could tell whether they were followed.
  See [write.md › Concrete enough to verify](write.md).
- Every tool adds to Claude's context; prefer the tool that loads only when needed.
  See [compose.md › The whole setup has a context budget](compose.md).
- A tool is done when there is evidence it loads and changes what Claude does.
  See [verify.md › It changes what Claude does](verify.md).
- An audit deletes instructions the current model no longer needs.
  See [maintain.md › Prune, and revisit after model releases](maintain.md).

## Topics

- [discover.md](discover.md): deciding what in a repository or a way of working deserves a Claude tool, and what does
  not
  - Add a tool when a trigger appears
  - Signs that something belongs in CLAUDE.md
  - What the codebase already says
  - Update what exists before adding
  - A skill closes a gap seen without it

- [choose.md](choose.md): picking the kind of Claude tool that fits a goal
  - The instruction file the repository already uses
  - Must happen every time: a hook
  - Every session needs it: CLAUDE.md
  - One part of the codebase: a path-scoped rule or a nested CLAUDE.md
  - Needed sometimes, or a procedure: a skill
  - Context Claude would otherwise explore for: a skill
  - A skill with side effects is user-only
  - Background knowledge is a skill only Claude invokes
  - About the response, not the project: an output style
  - Isolated or parallel work: a subagent or a dynamic workflow
  - An external system: MCP, with a skill for using it
  - The same setup in another repository: a plugin
  - Instructions shipped in a plugin are skills

- [write.md](write.md): writing the content of CLAUDE.md files, AGENTS.md files and rules so that Claude follows it
  - Earn every line
  - Concrete enough to verify
  - Short files
  - Headings and bullets
  - No contradictions
  - Emphasis on one line, not many

- [write-skills.md](write-skills.md): writing a skill's description, body and bundled files so that Claude finds the
  skill and follows it
  - Skill descriptions say what and when
  - Skill descriptions use the words a user would say
  - Skill descriptions are in the third person
  - Skill bodies hold only what Claude lacks
  - Skill steps match how fragile the task is
  - Skill files link one level deep from SKILL.md
  - Long skill files open with a contents list
  - Skill workflows are ordered steps, with a checklist when complex
  - Skill examples show input and output
  - Skill output templates match how strict the format is
  - Skill scripts handle their own errors
  - Bundled scripts have advantages over generated code
  - Skill instructions say whether Claude runs a script or reads it
  - Skills list the packages they need

- [compose.md](compose.md): making several tools work together within Claude's context
  - Each tool does what it is best at
  - Instructions at several levels add up
  - The whole setup has a context budget
  - Skill descriptions do not overlap

- [verify.md](verify.md): proving that a tool works before calling it done
  - It loaded
  - It changes what Claude does
  - Work the tool does has a check
  - A skill is checked for triggering and for output, separately
  - A skill is compared with a fresh run without it
  - Watch which bundled files Claude opens
  - A skill is tested on every model it will run on
  - Skills that change many files validate a plan first
  - A skill's validation script names the problem
  - A skill's steps loop until validation passes
  - A skill is tried on real tasks and by its users

- [maintain.md](maintain.md): keeping existing tools useful, and finding the ones to cut
  - Read the symptoms
  - Prune, and revisit after model releases
  - Use the built-in audits
  - Capture a gap while it is fresh
  - Cut skills that are never invoked
  - Review allowed-tools before running a repository's skills

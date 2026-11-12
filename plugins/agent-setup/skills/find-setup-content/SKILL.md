---
name: find-setup-content
description: Finds what a repository's Claude Code setup should hold and what it holds that does nothing, duplicates enforcement or contradicts the code, and proposes each change with its evidence, its tool and a test. Use when the user asks what to put in CLAUDE.md, AGENTS.md, rules, skills, subagents or hooks, wants to set Claude Code up for a repository, or wants an existing setup audited.
allowed-tools: Read, Glob, Grep, Bash(git log *), Bash(git show *), Bash(git ls-files *), Bash(git shortlog *)
---

# Find setup content

Experimental. Produces a report of proposals; it writes no tool. The `write-rule`, `write-skill`, `write-subagent`
and `write-hook` skills write each proposal the user accepts.

Base every proposal on evidence from this repository, not on a list of what repositories usually hold. Most of what a
setup could say makes no difference: Claude copies what the code already shows. What earns its place is what Claude
would get wrong without it, and only a run without it settles that, so every proposal ends in a test.

1. **Read `${CLAUDE_PLUGIN_ROOT}/guidance/index.md` in full,** then `discover.md` and `choose.md` in full. Read the
   `write-*.md` section a proposal's tool needs before proposing it.
2. **Take stock of the setup** with Glob and Read: `CLAUDE.md`, `CLAUDE.local.md` and `AGENTS.md` at every level,
   `.claude/rules/`, `.claude/skills/`, `.claude/agents/`, hooks and `enabledPlugins` in `.claude/settings.json`,
   and the instruction files of other tools (`.cursor/rules/`, `.github/copilot-instructions.md`). Note the plugins
   the repository enables: a convention a shared plugin already carries needs no copy here.
3. **Find candidates** in the evidence the repository leaves, without starting from categories:
   - **Repeated shapes in the code:** many sibling files or directories built the same way. The next one will be
     built the same way, so the shape is a candidate convention or process.
   - **Repeated change shapes in history:** run `git log --name-status` over the last few hundred commits and group
     commits by the roles of the files they touch together, such as a module, its test, its story and an export.
     A shape that recurs is a candidate process; the files it touches beyond the obvious one are its hidden steps.
   - **Tools that half-do a job:** package scripts, generators, CLIs, templates, codegen. The candidate is the
     process around the tool: what it leaves for someone to do.
   - **Processes people wrote down:** READMEs, contributing guides, merge request templates, docs, decision records.
   - **Corrections and repeated instructions,** when the user can point to them: review comments that recur across
     merge requests, things they keep telling Claude, auto memory `feedback` notes. Ask before reading transcripts.
   - **First-time work:** for a new repository, or a new area of an old one, the organisation's conventions that the
     code cannot yet show.

   For each candidate, record its kind (convention, process, fact or guardrail), the evidence with counts and
   examples, and, for a process, the steps no single finished example shows.
4. **Filter.** Drop a candidate that:
   - Claude could find by reading the code and would go and look for (`discover.md › What the codebase already
     says`). A convention the code shows consistently is one: count the examples that follow it and any that don't.
   - is generic advice, or a one-off incident.
   - a linter, type check, CI job or hook can enforce: propose the enforcement instead (`choose.md › Must happen
     every time: a hook`).

   Keep a process only where Claude would miss steps without it: commands to run, files to change elsewhere, an
   order, a check that proves it done, or a nearest example that is incomplete or misleading.
5. **Audit what exists,** most dangerous first:
   - **Stale:** an instruction that contradicts the current code, scripts or configuration, such as a command that
     no longer exists. Cite both sides. Claude can follow an instruction file over the code that contradicts
     it, so these mislead silently. Before calling a skill, command or agent missing, check the places a name
     resolves outside the repository: Claude Code's bundled skills, such as `/verify`, the enabled plugins and the
     user's own `~/.claude/`.
   - **Duplicated enforcement:** prose for what a linter, type check, CI job or hook already enforces.
   - **Duplicated content:** the same fact in two files, or a README restated in an instruction file.
   - **Always loaded but sometimes needed:** move it to a path-scoped rule or a skill (`compose.md › The whole setup
     has a context budget`).
   - **Likely inert:** a convention the code already shows consistently. Propose testing it, not deleting it: it
     still matters in new areas and new repositories, and costs little where it loads only on demand.
6. **Place each proposal** by `choose.md`, and by where the knowledge is used:
   - Work done for the first time in an empty area needs a skill, not a path-scoped rule: a path rule loads only
     once Claude reads, edits or writes a matching file, so in an area with none yet it arrives after the first file
     is written, not while Claude plans the work.
   - A convention for every repository belongs in a shared plugin, not copied into each repository.
   - A process whose steps no example shows is a user-invoked or Claude-invoked skill
     (`choose.md › Needed sometimes, or a procedure: a skill`). It holds those steps, such as deleting the example
     a generator leaves, and points to the nearest example for the rest: a step the code already shows changes
     nothing.

   Check every claim a proposal makes about this repository against the code before reporting it: a file it says
   shows a pattern, a command it names, what a linter or CI job rejects. A wrong claim is a stale instruction from
   the day it is written.
7. **Write a test for each proposal.** The user, or the `write-*` skill, runs it before keeping the change:
   - one realistic task prompt that would need the knowledge;
   - the difference to look for, such as "no `interface` declarations" or "the key ladder has all five rungs"; for
     a process, the steps no example shows, such as "no file of the generator's example is left";
   - at least three runs with it and three without, each in a fresh checkout, with hooks off if a hook would hide
     the difference, and `claude plugin eval` for a skill that ships in a plugin
     (`verify.md › A skill is compared with a fresh run without it`).

   A proposal whose runs show no difference is not added, and an existing item whose runs show no difference is cut
   only if it is always loaded.
8. **Report** in four groups, stale first: **Fix** (stale), **Cut or move**, **Add**, **Test before deciding**.
   Each item gives the evidence, the proposed tool and file, and its test. End with what was not checked, such as
   history beyond the commits read, or sessions the user did not share.

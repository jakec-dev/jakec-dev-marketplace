---
name: knowledge
description: Builds the agent-setup plugin's knowledge files for one Claude tool type, such as rules or hooks, from the local copy of Claude Code's documentation. Use when adding or rebuilding knowledge for a tool type.
argument-hint: build <type>
disable-model-invocation: true
allowed-tools: Read, Grep, Write, Edit, Bash(scripts/docs-toc.sh *), Bash(scripts/check-knowledge.sh *), Bash(scripts/check-links.sh *)
---

# Build knowledge for a tool type

Writes `plugins/agent-setup/knowledge/<type>/` and `maintenance/ledger/<type>.tsv` to the rules in `format.md`, in
this skill's directory. Read `format.md` before starting.

1. **Check the inputs**. The argument must be `build <type>`, where `<type>` is a lowercase tool type such as
   `rules`. `upstream/claude-code/llms-full.txt` must exist. If either is missing, stop and say what is needed.
2. **Map the documentation**. Run `scripts/docs-toc.sh upstream/claude-code/llms-full.txt` and save its output to
   `upstream/claude-code/toc.tsv`. Every section is then a row: page, level, heading, start, end, subtree end.
   Read sections by line range with the Read tool, never by guessing a heading or searching for its text.
3. **Find candidate sections**. Search the table of contents and the documentation for the tool type: its
   directory and file names, its settings and frontmatter fields, its events and commands.
   - A candidate is a section whose subject is this type, or a section on another page that states how this type
     behaves there, such as at subagent startup or after compaction.
   - A section whose subject is another tool type is not a candidate because it mentions this one; mark it
     excluded and name the type it belongs to. The exception is a section that documents how to configure or
     observe this type, such as a hook event that reports when it loads. Advice on choosing between tool types
     belongs to `choosing.md`.
   - Describe the terminal Claude Code that consumers run. A section about the Agent SDK, the web or the desktop
     app is excluded, even when it states something the terminal pages do not.
   - Always choose the most specific section. Never take a parent section to pick rows out of it.
4. **Propose topics and candidates to the user, and wait for confirmation**. Show the topic files you would write,
   one line each on what question it answers, and every candidate section as a plain list, one line each:
   `page › heading (lines) → topic`, or `→ excluded: reason`. Do not use a table. Change the list as the user
   asks. Do not write anything until the user confirms.
5. **Write the topic files**. Start one `knowledge-writer` agent per topic, in parallel. Give each the tool type,
   its topic file name and the question it answers, and its sections as page, heading, start and subtree end
   lines. Each writes its file and returns ledger rows.
6. **Write the index and the ledger**. Write `index.md` with one bullet per topic file, as `format.md` shows. Write
   the ledger: the writers' rows, plus an `excluded` row with the agreed reason for every candidate no writer
   used.
7. **Run the checks**. Run `scripts/check-knowledge.sh plugins/agent-setup/knowledge maintenance/ledger
   upstream/claude-code/toc.tsv` and `scripts/check-links.sh` on every new file. Fix what they report and run them
   again until both exit 0.
8. **Review**. Start one `knowledge-reviewer` agent per topic file, in parallel, giving each the file and its
   ledger rows. Fix each finding the documentation supports, then run the checks again.
9. **Report**. List the files written with their line counts, every excluded section with its reason, the
   reviewers' findings and what was done about each, and the final exit status of each check.

---
name: knowledge
description: Builds the agent-setup plugin's knowledge files for one Claude tool type, such as rules or hooks, from the local copy of Claude Code's documentation. Use when adding or rebuilding knowledge for a tool type.
argument-hint: build <type>
disable-model-invocation: true
allowed-tools: Read, Grep, Write, Edit, Bash(scripts/docs-toc.sh *), Bash(scripts/docs-find.sh *), Bash(scripts/check-knowledge.sh *), Bash(scripts/check-links.sh *), Bash(mkdir -p maintenance/ledger maintenance/topics), Bash(sed -n *)
---

# Build knowledge for a tool type

Writes `plugins/agent-setup/knowledge/<type>/` and `maintenance/ledger/<type>.tsv` to the rules in `format.md`, in
this skill's directory. Read `format.md` before starting.

1. **Check the inputs**. The argument must be `build <type>`, where `<type>` is a lowercase tool type such as
   `rules`. `upstream/claude-code/llms-full.txt` must exist. If either is missing, stop and say what is needed.
2. **Map the documentation**. Run `scripts/docs-toc.sh upstream/claude-code/llms-full.txt` and save its output to
   `upstream/claude-code/toc.tsv`. Every section is then a row: page, level, heading, the line it starts on, the
   last line of its own text, and the last line including its subsections. Read sections by line range, with the
   Read tool or `sed -n '<start>,<end>p'`, never by guessing a heading or searching for its text.
3. **Find candidate sections**. Search for the tool type's directory and file names, settings, frontmatter
   fields, events and commands with `scripts/docs-find.sh upstream/claude-code/llms-full.txt
   upstream/claude-code/toc.tsv '<pattern>'`, which lists the sections whose own text matches. Start with
   path-shaped and distinctive patterns, such as a directory name; a broad word will match unrelated sections.
   A match where the word means something else is not a candidate: summarise those matches in one line at step 4
   instead of listing them. Then read the type's own sections and search again for every command, setting, event
   and environment variable they name, to find the other pages that document them.
   - A candidate is a section whose subject is this type, or a section on another page that states how this type
     behaves there, such as at subagent startup or after compaction.
   - A section whose subject is another tool type is not a candidate because it mentions this one; mark it
     excluded and name the type it belongs to. The exceptions: a section that documents how to configure or
     observe this type, such as a hook event that reports when it loads, and a sentence that names this type and
     states how it behaves, which makes the section a candidate for that sentence. Advice on choosing between tool types
     belongs to `choosing.md`.
   - Describe the terminal Claude Code that consumers run. A section about the Agent SDK, the web or the desktop
     app is excluded, even when it states something the terminal pages do not.
   - Always choose the most specific section. Never take a parent section, or a section covering many events,
     fields or types, to pick one row out of it, unless that row is the only place the documentation states the
     fact; then take the section and name the row.
4. **Propose topics and candidates to the user, and wait for confirmation**. If `maintenance/topics/<type>.md`
   exists, use its topic files and assign every candidate to one of them; propose a new, split, merged or
   renamed topic only where a candidate fits none or a topic no longer serves one task, and say why. If it does
   not exist, propose topic files, one line each on the task it serves. Then show every candidate section as a
   plain list, one line each: `page › heading (lines) → topic`, or `→ excluded: reason`. Do not use a table.
   Change the list as the user asks. Do not write anything until the user confirms.
5. **Write the topic files**. Start one `knowledge-writer` agent per topic, in parallel. Give each the tool type,
   its topic file name and the task it serves, the other topic files and their tasks so it leaves those
   to them, and its sections as page, heading, start and end lines: each section's own range, with subsections
   listed separately, and the row named for a section taken for one row. Assign whole sections otherwise: the
   writer decides, after reading, which parts its file needs. Each writes its file and returns ledger rows.
6. **Write the index and the ledger**. Write `index.md` with one bullet per topic file, as `format.md` shows,
   describing what each file contains. Create `maintenance/ledger/` and `maintenance/topics/` if they are missing.
   Write or update `maintenance/topics/<type>.md` with the confirmed topics, each line covering every section
   assigned to it, then write the ledger: the
   writers' rows, plus an `excluded` row with the agreed reason for every candidate no writer used.
7. **Run the checks**. Run `scripts/check-knowledge.sh plugins/agent-setup/knowledge maintenance
   upstream/claude-code/toc.tsv` and `scripts/check-links.sh` on every new file. Fix what they report and run them
   again until both exit 0.
8. **Review**. Start one `knowledge-reviewer` agent per topic file, in parallel, giving each the file and its
   `included` ledger rows and the other topic files, and one more giving it the type's `excluded` rows, the
   exclusion grounds from step 3 and the topic files. Fix each finding the documentation supports. Where you
   disagree with a finding, keep the narrower statement unless the documentation states the broader one outright.
   - Moving a fact to the topic file whose task it serves is a fix. Changing the topics themselves is a proposal
     to bring to the user; change them only if the user agrees.
   - If a finding needs a section the user agreed to exclude, or one not in the ledger, ask the user first.
   - Run the checks again, then give every changed file to a fresh reviewer once more. Report anything still open
     after that second pass rather than reviewing a third time.
9. **Report**. List the files written with their line counts, every excluded section with its reason, the
   reviewers' findings and what was done about each, and the final exit status of each check.

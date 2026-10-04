---
name: knowledge
description: Builds the agent-setup plugin's knowledge files for one Claude tool type, such as rules or hooks, from the local copy of Claude Code's documentation. Use when adding or rebuilding knowledge for a tool type.
argument-hint: build <type>
disable-model-invocation: true
allowed-tools: Read, Grep, Write, Edit, Bash(scripts/docs-toc.sh *), Bash(scripts/docs-find.sh *), Bash(scripts/check-knowledge.sh *), Bash(scripts/check-links.sh *), Bash(mkdir -p maintenance/ledger maintenance/topics), Bash(sed -n *)
---

# Build knowledge for a tool type

Writes `plugins/agent-setup/knowledge/<type>/`, `maintenance/topics/<type>.md` and `maintenance/ledger/<type>.tsv`
by the rules in `format.md`, in this skill's directory. Read `format.md` first; its order of priorities settles any
conflict between instructions.

1. **Check the inputs.** The argument must be `build <type>`, where `<type>` is a lowercase tool type such as
   `rules`, and `upstream/claude-code/llms-full.txt` must exist. If either is missing, stop and say what is needed.
2. **Map the documentation.** Run `scripts/docs-toc.sh upstream/claude-code/llms-full.txt` and save the output as
   `upstream/claude-code/toc.tsv`. Its columns are page, level, heading, the line a section starts on, the last
   line of its own text, and the last line including its subsections. Read sections by line range, with the Read
   tool or `sed -n '<start>,<end>p'`.
3. **Find candidate sections.** Run `scripts/docs-find.sh upstream/claude-code/llms-full.txt
   upstream/claude-code/toc.tsv '<pattern>'` for the type's directory and file names, then for every field,
   setting, command, event and environment variable its own sections name, adding the type's name as a fourth
   argument so that only sections mentioning the type are listed. Repeat with what those sections name, until a
   round finds nothing new. Prefer distinctive patterns; matches where a word means something else are not
   candidates.
   - A candidate is a section that states how this type behaves, or how to configure or observe it, in at least
     one sentence that names it. A subsection of a candidate is a candidate with it.
   - Exclude sections about the Agent SDK, the web or the desktop app, sections whose point is comparing tool
     types or recommending one (they belong to `choosing.md`), release notes, and sections that only repeat an
     included one.
   - Take the most specific section. From a broad table, take one row only when no other section states its fact,
     and name the row.
4. **Propose, and wait for confirmation.** If `maintenance/topics/<type>.md` exists, keep its topics and propose a
   change only where a candidate fits none, with the reason. Otherwise propose topic files, one line each on its
   task. Then list every candidate, one line each, as `page › heading (lines) → owning file` or
   `→ excluded: reason`, adding `, the sentence on <subject> → <file>` where one sentence goes to another file.
   Summarise in one line the matches that meant something else. Use plain lists, not tables. Change the list as
   the user asks, and write nothing until the user confirms.
5. **Write.** Create `maintenance/ledger/` and `maintenance/topics/` if they are missing, and write the confirmed
   topics. Start one `knowledge-writer` per topic file, in parallel, giving each: the type; its file and task; the
   other files and their tasks; and the sections it owns, as page, heading, start and end lines, naming any row or
   sentence taken alone and any sentence handed to another file.
6. **Index and ledger.** Write `index.md` from what each file contains. Write the ledger: one `included` row per
   owned section, one per sentence or row handed to another file, and an `excluded` row with its agreed reason
   for every other candidate.
7. **Check.** Run `scripts/check-knowledge.sh plugins/agent-setup/knowledge maintenance
   upstream/claude-code/toc.tsv` and `scripts/check-links.sh` on every file of the type, and fix until both exit 0.
8. **Review.** Start one `knowledge-reviewer` per topic file, in parallel, with the file, its ledger rows, the
   other files and the exclusion grounds of step 3, and one more with the `excluded` rows and those grounds.
   - Fix each finding the documentation supports, by `format.md`'s order of priorities. Moving a fact to the file
     that owns its section is a fix; changing the topics needs the user's agreement.
   - Ask the user before using a section that was excluded or is not in the ledger.
   - After fixing, give each changed file to a fresh reviewer with the changed bullets marked, to review those
     bullets only. Repeat until a round changes nothing, and run step 7 again.
9. **Report.** Give each file's line count, each excluded section with its reason, each finding with what was done,
   anything left open for the user, and the final exit status of both checks. List the documentation's gaps
   separately: facts stated only on excluded pages, and questions about the type the documentation leaves open.

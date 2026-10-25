---
name: knowledge
description: Builds the agent-setup plugin's knowledge files from local copies of Claude Code's documentation and the Anthropic pages it links to, either the reference for one Claude tool type, such as rules or hooks, or the guidance. Use when adding or rebuilding reference or guidance.
argument-hint: build <type> | build guidance
disable-model-invocation: true
allowed-tools: Read, Grep, Write, Edit, Bash(scripts/docs-toc.sh *), Bash(scripts/fetch-sources.sh *), Bash(cat upstream/claude-code/toc.tsv upstream/anthropic/toc.tsv *), Bash(scripts/docs-find.sh *), Bash(scripts/check-knowledge.sh *), Bash(scripts/check-links.sh *), Bash(mkdir -p maintenance/ledger maintenance/topics), Bash(sed -n *), Bash(scripts/knowledge-index.sh *)
---

# Build reference or guidance

`build <type>` follows the steps below. `build guidance` follows them with the changes under "Build guidance".

## Build reference for a tool type

Writes `plugins/agent-setup/reference/<type>/`, `maintenance/topics/<type>.md` and `maintenance/ledger/<type>.tsv`
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
   setting, command, event, environment variable and concept (such as frontmatter) its own sections name. Add a
   fourth argument that matches only this type, such as its directory and file names and the phrases its pages
   use for it, so that only sections about it are listed; the type's bare name may also mean something else.
   Repeat with what those sections name, until a round finds nothing new, and read every section each search
   lists before setting it aside. Run each command directly rather than building it in a shell variable. Matches
   where a word means something else are not candidates.
   - A candidate is a section that states how this type behaves, or how to configure or observe it, in at least
     one sentence that names it. A subsection of a candidate is a candidate with it.
   - Exclude sections about the Agent SDK, the web or the desktop app, sections whose point is comparing tool
     types or recommending one (they belong to guidance), release notes, sections that only repeat an included
     one, and sections that belong to another tool type: the section's subject is another tool type, and it
     states nothing about this type that an included section doesn't. Each excluded row's reason names one of
     these grounds. The last ground never drops a fact about this type: take that sentence or clause by name.
   - Read `maintenance/ledger/*.tsv` for the other types. A section another type owns whole is excluded here; one
     it takes in part leaves its other parts free. Where one sentence lists several types, take this type's
     clause by name.
   - Take the most specific section. From a broad table, take one row only when no other section states its fact,
     and name the row.
   - Where a candidate's sentence leaves its detail to a link, the linked section's detail is a candidate too, by
     `format.md`'s rule on linked detail, whatever the linked section's type.
4. **Propose, and wait for confirmation.** If `maintenance/topics/<type>.md` exists, keep its topics and propose a
   change only where a candidate fits none, with the reason. If `maintenance/ledger/<type>.tsv` exists, every
   section in it appears in the new list, included or excluded, so nothing drops out unseen. Otherwise propose
   topic files, one line each on its task. Then list every candidate, one line each, as
   `page › heading (lines) → owning file` or `→ excluded: reason`. Read each included section for sentences or
   clauses that serve another file's task, including a current fact carried inside a history sentence, and for
   facts that two sections both state, which go to one file only. Add `, the sentence on <subject> → <file>` (or
   `the clause on …`) for each, so the user agrees every hand-over before writing. Summarise in one line the
   matches that meant something else. Use plain lists, not tables. Change the list as the user asks, and write
   nothing until the user confirms.
5. **Write.** Create `maintenance/ledger/` and `maintenance/topics/` if they are missing, and write the confirmed
   topics. Start one `knowledge-writer` per topic file, in parallel, giving each: the type; its file and task; the
   other files and their tasks; and the sections it owns, as page, heading, start and end lines, naming any row or
   sentence taken alone and any sentence handed to another file.
6. **Ledger and index.** Write the ledger: one `included` row per owned section, with an empty reason; one per
   sentence, clause or row handed to another file, naming it; and an `excluded` row with its agreed reason for
   every other candidate. Before writing an `excluded` reason that says a section, or the rest of one, repeats
   another or is not about this type, check whether step 3's `scripts/docs-find.sh` searches for the type's names,
   fields, settings and commands list that section, and read each match in it; a `repeats` reason names a part that
   some file states. Write `index.md`: a title and a sentence, the key facts as `format.md` describes them, then
   the output of `scripts/knowledge-index.sh plugins/agent-setup/reference/<type> maintenance/topics/<type>.md`.
7. **Check.** Run `scripts/check-knowledge.sh plugins/agent-setup/reference maintenance
   upstream/claude-code/toc.tsv` and `scripts/check-links.sh` on every file of the type, and fix until both exit 0.
8. **Review.** Start one `knowledge-reviewer` per topic file, in parallel, with the file, its ledger rows, the
   other files and the exclusion grounds of step 3, and one more with the `excluded` rows and those grounds.
   - Fix each finding the documentation supports, by `format.md`'s order of priorities. Moving a fact to the file
     that owns its section is a fix; changing the topics needs the user's agreement.
   - Ask the user before using a section that was excluded or is not in the ledger, before a new hand-over,
     before widening what a row takes, and before excluding a section the user agreed to include. Recording a
     newly found section as excluded on an agreed ground needs no question.
   - After fixing, give each changed file to a fresh reviewer with the changed bullets marked, the other files and
     the `excluded` rows. Repeat until a round changes no stated fact. A finding that only rewords a `Not stated`
     bullet, without showing it wrong or incomplete, is not applied.
   - Regenerate the Topics section of `index.md`, check each key fact still matches the bullet it summarises, and
     run step 7 again.
9. **Report.** Give each file's line count, each excluded section with its reason, each finding with what was done,
   anything left open for the user, and the final exit status of both checks. List the documentation's gaps
   separately: facts stated only on excluded pages, and questions about the type the documentation leaves open.

## Build guidance

Writes `plugins/agent-setup/guidance/`, `maintenance/topics/guidance.md` and `maintenance/ledger/guidance.tsv` by
`format.md`'s Guidance section. The steps above apply, with these changes.

1. **Check the inputs.** `maintenance/sources.tsv` must exist. Ask the user for any eval results to draw on; without
   them, only Anthropic's statements can support a guideline.
2. **Map the sources.** Run step 2, then `scripts/fetch-sources.sh maintenance/sources.tsv
   upstream/anthropic/pages.txt` and `scripts/docs-toc.sh upstream/anthropic/pages.txt`, saving the output as
   `upstream/anthropic/toc.tsv`. Then run `cat upstream/claude-code/toc.tsv upstream/anthropic/toc.tsv >
   upstream/guidance-toc.tsv` for the checker. Read a page in `pages.txt` by the line ranges in its own table of
   contents.
3. **Find candidates.** They are every section a reference ledger excludes on the guidance ground (`compares` or
   `recommends` in its reason), every section of the pages in `sources.tsv`, every section `guidance.tsv` already
   lists, and the eval cases the user supplies. Read each in full. Leave out what any capable model does unprompted,
   and a source's statement that Claude Code's documentation contradicts or that applies only to another surface,
   such as the API's code execution environment.
4. **Propose, and wait for confirmation.** Keep the topics in `maintenance/topics/guidance.md`; propose a change only
   where a guideline fits none. List each guideline on one line as `## <heading> → <file>, support: <page> ›
   <heading> or eval case <case>, Check: <question>`, then each candidate left out with its reason. Write nothing
   until the user confirms.
5. **Write.** Start one `knowledge-writer` per guidance file that gains or changes a guideline, in parallel, saying
   it is writing guidance, and giving each: its file and decision, the other files and their decisions, its
   guidelines with their support as page, heading, file (`llms-full.txt` or `pages.txt`) and lines, and the
   `index.md` of each reference type a guideline touches.
6. **Ledger and index.** Write the ledger rows the writers return, and an `excluded` row with its reason for each
   candidate source section left out. Write `index.md` with `## Key principles`, then the generated Topics.
7. **Check.** Run `scripts/check-knowledge.sh plugins/agent-setup/guidance maintenance upstream/guidance-toc.tsv` and
   `scripts/check-links.sh` on every guidance file, and fix until both exit 0.
8. **Review.** Start one `knowledge-reviewer` per changed file, saying it is reviewing guidance, with the file, its
   ledger rows and the other files; one more with the `excluded` rows; and one more that compares every changed
   guideline with the reference files of the types it touches and reports any guideline that contradicts a
   reference fact. Fix and repeat as in step 8 above.
9. **Report** as in step 9 above, listing separately each source statement left out because Claude Code's
   documentation contradicts it.

# Knowledge format

How knowledge files, topic lists and ledgers are written. The writer follows it, the reviewer checks against it, and
`scripts/check-knowledge.sh` enforces the mechanical parts.

## Contents

- Purpose
- When rules pull against each other
- Layout
- Key facts
- Owning sections
- Writing facts
- Examples
- Leaving out
- The ledger

## Purpose

The plugin's agents read knowledge files to build and check Claude tools (rules, hooks, skills, subagents,
instruction files and the rest) the way Claude Code's documentation says. A knowledge file compresses the sections
it draws on: shorter than the source, in plain statements, with nothing an agent needs left out. Consumers run the
latest Claude Code, so knowledge describes current behaviour only.

## When rules pull against each other

Settle it in this order:

1. **Accurate**: every statement is supported by the section it links to, with the source's own subject and
   conditions.
2. **Complete**: everything in the file's sections that an agent needs for the file's task is there.
3. **Placed**: each fact is in the file that owns its section.
4. **Compact**: the shortest wording that keeps 1 to 3.

## Layout

```text
plugins/agent-setup/reference/<type>/index.md     lists the type's topic files
plugins/agent-setup/reference/<type>/<topic>.md   one file per task an agent does with the type
maintenance/topics/<type>.md                      the topic files and the task each serves, agreed with the user
maintenance/ledger/<type>.tsv                     every section considered, and which file owns it
```

- A task is what an agent is doing when it opens the file, such as placing the tool, writing its configuration,
  sharing it, excluding it, knowing when it takes effect, or finding out why it did not. One task, one file.
- The topic list is agreed with the user on a type's first build and kept between builds. Only a proposal the user
  agrees to changes it: a new, split, merged or renamed topic, with a reason.
- `index.md` is the entry an agent always reads: a title and a sentence, then `## Key facts`, then `## Topics`.
  The Topics section lists every topic file with its task and its `##` sections; `scripts/knowledge-index.sh`
  generates it from the topic list, and nobody edits it by hand. Only the index links to topic files, so every
  read is one step from the index, and an agent reads only the sections its task needs.

## Key facts

- Ten to twenty one-line facts that most tasks with this type need, chosen by evidence, strongest first:
  1. A model gets it wrong without the knowledge: the eval suite's baseline arm fails on it.
  2. Getting it wrong fails silently, such as an ignored field, a pattern that matches nothing or a write that is
     refused.
  3. It sits in a section the documentation changed recently, so a model's training may predate it.
- Each key fact summarises a bullet a topic file states in full, and ends with a pointer to it on its own line:
  `See [loading.md › After compaction](loading.md).`, naming the file and its `##` heading. The checker confirms the
  heading exists. A key fact is the one deliberate repeat of a fact.

## Owning sections

- Every section has exactly one owner: the topic file whose task it mainly serves. The owner states everything in
  the section that an agent needs for its task.
- Where one sentence, clause or table row of a section serves another file's task, the ledger may hand it to that
  file by name. That file states it; the owner leaves it out. A file never hands a fact away in prose, such as
  "covered in loading.md": either it states the fact, or the ledger hands it on.
- Another file may mention an owned fact in a few words, inside one of its own bullets, keeping any condition
  without which the mention misleads. Keep such a mention where a hand-over would otherwise leave this file's fact
  without the fix or caveat that makes it usable, such as a symptom without its cure.
- One fact, one file. Where two sections state the same fact, it is stated once, in the file whose task it serves:
  the other section's sentence is handed to that file, or its owner leaves it out.

## Writing facts

- Start a topic file with `# <Title>` and a sentence or phrase naming its task. A file over 100 lines then has a
  `## Contents` section listing its `##` headings; never cut wording to stay under 100 lines.
- One fact per bullet, as current behaviour, in one to three sentences. Each bullet links to the section that
  supports it as `[<page> › <heading>](https://code.claude.com/docs/en/<page>#<anchor>)`; a nested bullet, table
  or example straight after it shares that link.
- **Keep the source's subject.** When you keep a sentence, keep the subject it names and the conditions it gives.
  Where the source says "CLAUDE.md files", "memory files" or "in Cowork", so does the fact: "For CLAUDE.md files,
  …". Never widen it to this type, and never add a detail from another sentence, such as a number the sentence
  itself does not give. Leave out sentences the file's task does not need.
- Copy exactly: field names, values, defaults, limits, messages, and names of settings, events, commands and tools.
  A copied table keeps its header, its columns and any sentence that limits how to read it, and may drop rows that
  serve no task here.
- Links in copied text become absolute `https://code.claude.com/docs/en/…` links. Copy an anchor from the
  heading's `id` in the live page exactly. Where an anchor exists only in the browser, such as an interactive
  explorer's, link the nearest heading instead and keep the text. A copied word that points elsewhere on the page,
  such as "below", may be replaced by the name of what it points to.
- When two pages disagree, state both, each with its link.
- A file may end with a `## Not stated by the documentation` section: one bullet per question an agent working
  with this type will meet that the documentation leaves open, linked to the section closest to it, such as
  "Stated for CLAUDE.md files; the documentation does not say whether it applies to rules." It holds questions,
  never answers. Where an excluded page, such as an Agent SDK page, states the point for its own surface, the
  question says so. A question the documentation answers in its own words, even in part or through another fact in
  the file, is not open: state the answer instead, or ask only the part that is open. An answer that rests on
  reading between the lines, such as the force of a single word, does not close a question.
- Lines stay within 120 characters, except a line holding a link, a table row and a line inside a code block, so
  that the documentation's own examples are copied whole.

## Examples

- Keep an example when it shows what a statement cannot, such as the shape of a configuration or where quoting
  goes; one per pattern. Use the documentation's own, shortened to the lines that carry the point, still valid,
  with its own values. Where it shows a value other than the one this file is about, say what it shows.
- Never invent a field, value or behaviour.

## Leaving out

- History: version numbers, minimum versions, and what used to happen. From a sentence describing a change, keep
  what is true now, in the source's words and inside the setting it came from; where the sentence states only the
  old behaviour, the current behaviour is its opposite, linked to that sentence. The changelog and release notes are
  never a source.
- Sections about the Agent SDK, the web or the desktop app, and sections whose point is to compare tool types or
  recommend one over another, which belong to `choosing.md`. These are excluded at the section level; inside an
  included section, keep each sentence with its subject.
- Tutorial steps, marketing, statements about how the documentation is written (apart from the `Not stated`
  section), and what any capable model knows.

## The ledger

`maintenance/ledger/<type>.tsv` is tab-separated, with this header row:

```text
page	heading	decision	file	reason
```

- One row per candidate section, with `page` and `heading` exactly as `scripts/docs-toc.sh` prints them.
- `included` rows name the owning file; `reason` is empty, or names the one row, sentence or clause the file takes.
  A file taking one table row also takes any sentence that tells you how to read the table.
- `excluded` rows leave `file` empty and give the reason in a few words.
- Every topic file owns at least one section, and no section has two owners, apart from a named row, sentence or
  clause handed to another file.

# Knowledge format

How knowledge files and ledger rows are written. The writer follows it, the reviewer checks against it, and
`scripts/check-knowledge.sh` enforces the mechanical parts.

## Purpose

The plugin's agents read knowledge files to build and check Claude tools (rules, hooks, skills, subagents,
instruction files and the rest) the way Claude Code's documentation says. The files compress the documentation:
smaller than the source, in plain statements, without losing anything an agent needs to get a Claude tool right.
Consumers run the latest Claude Code, so knowledge describes current behaviour only.

## Layout

```text
plugins/agent-setup/knowledge/<type>/index.md     one per tool type
plugins/agent-setup/knowledge/<type>/<topic>.md   one file per kind of question an agent asks
maintenance/ledger/<type>.tsv                     every documentation section considered for the type
```

- `<type>` and `<topic>` are lowercase words joined by hyphens, such as `rules` and `loading.md`.
- `index.md` lists every topic file in the directory, one bullet each:
  `- [loading.md](loading.md): when a rule enters Claude's context. Read when choosing paths or debugging.`
- Only `index.md` links to topic files. A topic file never links to another knowledge file, so every read is one
  level deep from the index.

## Knowledge files

- Start with `# <Title>` and one sentence saying what the file answers.
- A file over 100 lines has a `## Contents` section listing its `##` headings, straight after that sentence.
- Group facts under `##` headings. Split a topic into two files rather than let one file cover two kinds of
  question.
- Identifiers, field names and messages exactly as Claude Code spells them. Lines at most 120 characters, not
  counting links. A copied table keeps its rows whatever their length; do not turn a table into a list to fit.

## Facts

- One fact per top-level bullet, stated as current behaviour in one to three sentences.
- Each bullet carries at least one source link to the section that supports it, written
  `[<page> › <heading>](https://code.claude.com/docs/en/<page>#<anchor>)`. Copy the anchor from the heading's `id`
  in the live page; never build one from the heading text, which often differs. `scripts/check-links.sh` checks
  every link.
- Every claim must be supported by the linked section of the documentation copy. If the documentation does not say
  it, leave it out, however sure you are.
- State a fact no more broadly than its source. A statement made about one setting, mode, surface or case stays
  scoped to it, and nothing is added to it, such as when it does or does not happen.
- Copy word for word: tables of fields and their values, defaults, limits, exact messages, and names of settings,
  events and tools. Paraphrase only explanation.
- When two pages disagree, state both, each with its link, and say which to rely on only if the documentation does.

## Examples

- Keep an example when it shows something a statement cannot, such as the shape of a configuration or where
  quoting goes. One representative example per pattern.
- Prefer the documentation's own example. Shorten a long one to the lines that carry the point. A shortened example
  must still be valid (it parses, and every field and value appears in the documentation) and must keep every
  detail the point depends on.
- Never invent a field, value or behaviour for an example.

## What to leave out

- Version history: no "since", "before", "now" or "new", and no description of earlier behaviour. A sentence that
  describes a change supports its current half: state that, without the history. Status the
  documentation gives for current use, such as "legacy" or "deprecated", stays.
- Tutorial steps, marketing, and anything about other surfaces (web, desktop, SDK) unless it changes how a Claude
  tool in a repository behaves.
- Advice on choosing between tool types, such as using a skill instead of the type being written, even when the
  type's own pages give it. That advice belongs to `choosing.md`.
- Facts any capable model already knows, such as YAML syntax.

## The ledger

`maintenance/ledger/<type>.tsv` is tab-separated, with this header row:

```text
page	heading	decision	file	reason
```

- One row for every section that was a candidate for the type: `page` and `heading` exactly as
  `scripts/docs-toc.sh` prints them.
- `decision` is `included` or `excluded`.
- An `included` row names the topic file that draws on the section in `file`, and leaves `reason` empty. A section
  used by two files has two rows.
- An `excluded` row leaves `file` empty and says why in `reason`, in a few words.
- Every topic file appears in at least one `included` row.

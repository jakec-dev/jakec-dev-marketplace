# Writing skills

Writing a skill's description, body and bundled files so that Claude finds the skill and follows it.

These sections draw on Anthropic's skill authoring guidance, which writes for skills on every Claude surface, and
Claude Code's skills page. Where they disagree, Claude Code's documentation wins. The CLAUDE.md principle that every
line must earn its place applies to a skill's body too.

## Contents

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

## Skill descriptions say what and when

- A skill's "`description` field enables Skill discovery and should include both what the Skill does and when to use
  it."
  [best-practices › Writing effective descriptions](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#writing-effective-descriptions)
- Claude Code's `description` field is "What the skill does and when to use it. Claude uses this to decide when to
  apply the skill."
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- In the `description` field's row: "Put the key use case first: the combined `description` and `when_to_use` text is
  truncated at 1,536 characters in the skill listing to reduce context usage."
  [skills › Frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
- Check: does each skill's `description` state what the skill does and when to use it, and does the key use come
  first in the combined `description` and `when_to_use` text?

## Skill descriptions use the words a user would say

- "**Be specific and include key terms**", with "specific triggers/contexts for when to use it". The page's examples
  to avoid are vague descriptions such as "Helps with documents", "Processes data" and "Does stuff with files".
  [best-practices › Writing effective descriptions](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#writing-effective-descriptions)
- When a skill does not trigger as expected, the first check is that "the description includes keywords users would
  naturally say".
  [skills › Skill not triggering](https://code.claude.com/docs/en/skills#skill-not-triggering)
- Check: does each `description` contain terms or situations a user would actually mention, and no vague phrase such
  as "Helps with documents"?

## Skill descriptions are in the third person

- Anthropic's skill authoring guidance says "**Always write in third person**", because inconsistent point of view
  "can cause discovery problems". Good: "Processes Excel files and
  generates reports"; avoid "I can help you process Excel files" and "You can use this to process Excel files".
  [best-practices › Writing effective descriptions](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#writing-effective-descriptions)
- Check: is each `description` written as "Processes Excel files", not "I can help you process Excel files" or "You
  can use this"?

## Skill bodies hold only what Claude lacks

- In a skill, "Keep the body itself concise. Once a skill loads, its content stays in context across turns, so every
  line is a recurring token cost. State what to do rather than narrating how or why, and apply the same conciseness
  test you would for CLAUDE.md content."
  [skills › Types of skill content](https://code.claude.com/docs/en/skills#types-of-skill-content)
- "Only add context Claude doesn't already have. Challenge each piece of information": does Claude really need the
  explanation, can it be assumed that Claude knows this, and does the paragraph justify its token cost?
  [best-practices › Concise is key](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#concise-is-key)
- Check: would removing each paragraph of the skill body cause Claude to make mistakes?

## Skill steps match how fragile the task is

- "Match the level of specificity to the task's fragility and variability." Use specific scripts with few or no
  parameters ("low freedom") where operations are fragile and error-prone, consistency is critical or a specific
  sequence must be followed, such as "Run exactly this script" for a database migration. Use text-based instructions
  ("high freedom") where several approaches are valid, decisions depend on context or heuristics guide the approach.
  [best-practices › Set appropriate degrees of freedom](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#set-appropriate-degrees-of-freedom)
- Check: does the skill give an exact command for each step where a mistake is costly or the order matters, and leave
  room where several approaches are valid or the decision depends on context?

## Skill files link one level deep from SKILL.md

- "**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to
  ensure Claude reads complete files when needed." The reason: "Claude may partially read files when they're
  referenced from other referenced files", so it might preview one with `head -100` and get incomplete information.
  [best-practices › Avoid deeply nested references](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-deeply-nested-references)
- Claude Code: "Reference supporting files from `SKILL.md` so Claude knows what each file contains and when to load
  it".
  [skills › Add supporting files](https://code.claude.com/docs/en/skills#add-supporting-files)
- Check: does every supporting file link directly from SKILL.md, with none reached only through another supporting
  file?

## Long skill files open with a contents list

- "For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see
  the full scope of available information even when previewing with partial reads."
  [best-practices › Structure longer reference files with table of contents](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#structure-longer-reference-files-with-table-of-contents)
- Check: does every supporting file over 100 lines open with a contents list?

## Skill workflows are ordered steps, with a checklist when complex

- "Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist
  that Claude can copy into its response and check off as it progresses."
  [best-practices › Use workflows for complex tasks](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#use-workflows-for-complex-tasks)
- For a conditional workflow, the page's tip: "If workflows become large or complicated with many steps, consider
  pushing them into separate files and tell Claude to read the appropriate file based on the task at hand."
  [best-practices › Conditional workflow pattern](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#conditional-workflow-pattern)
- Check: does a complex multi-step workflow in the skill give a checklist that Claude can copy into its response and
  tick off, and does a large workflow sit in a separate file that SKILL.md tells Claude to read for the task?

## Skill examples show input and output

- "For Skills where output quality depends on seeing examples, provide input/output pairs just like in regular
  prompting". "Examples convey the desired style and level of detail to Claude more clearly than descriptions
  alone."
  [best-practices › Examples pattern](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#examples-pattern)
- Check: where the skill's output must match a style, does it give input and output examples?

## Skill output templates match how strict the format is

- "Provide templates for output format. Match the level of strictness to your needs." For strict requirements, such
  as API responses or data formats, the page's example says "ALWAYS use this exact template structure". For flexible
  guidance, when adaptation is useful, it says "Here is a sensible default format, but use your best judgment based on
  the analysis".
  [best-practices › Template pattern](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#template-pattern)
- Check: does each output template say whether Claude must follow it exactly or may adapt it, to match how strict the
  format really is?

## Skill scripts handle their own errors

- "When writing scripts for Skills, handle error conditions rather than deferring to Claude." The page's good example
  catches a missing file or a permission error and falls back to a default; its bad example opens the file and lets
  the failure reach Claude.
  [best-practices › Solve, don't defer](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#solve-dont-punt)
- Check: does each bundled script handle its likely failures itself instead of failing and leaving Claude to work
  out the cause?

## Bundled scripts have advantages over generated code

- "Even if Claude could write a script, pre-made scripts offer advantages": they are more reliable than generated
  code, save tokens (no code in context), save time (no code generation) and ensure consistency across uses.
  [best-practices › Provide utility scripts](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#provide-utility-scripts)
- Check: where a step would otherwise have Claude write the same code each time, did the author weigh bundling a
  script for its reliability, token, time and consistency advantages?

## Skill instructions say whether Claude runs a script or reads it

- "**Important distinction:** Make clear in your instructions whether Claude should" "Execute the script (most
  common)", as in "Run `analyze_form.py` to extract fields", or "Read it as reference (for complex logic)", as in
  "See `analyze_form.py` for the field extraction algorithm".
  [best-practices › Provide utility scripts](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#provide-utility-scripts)
- In Claude Code, the documented pattern has the instructions tell Claude to run the script, with the script path
  using `${CLAUDE_SKILL_DIR}` "so it resolves correctly whether the skill is installed at the personal, project, or
  plugin level". `${CLAUDE_PLUGIN_ROOT}` is "Substituted only in plugin skills" and references "scripts or files bundled
  anywhere in the plugin".
  [skills › Generate visual output](https://code.claude.com/docs/en/skills#generate-visual-output) and
  [skills › Available string substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)
- Check: does each script that SKILL.md mentions say whether Claude should run it or read it, and in Claude Code does
  each path in a command Claude runs use `${CLAUDE_SKILL_DIR}` (or `${CLAUDE_PLUGIN_ROOT}` in a plugin skill)
  rather than a bare relative path?

## Skills list the packages they need

- "Don't assume packages are available": the page's bad example is "Use the pdf library to process the file."; its good
  example is "Install required package: `pip install pypdf`", followed by the code that uses it.
  [best-practices › Avoid assuming tools are installed](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#avoid-assuming-tools-are-installed)
- Check: does the skill install or name each package its scripts need, rather than assuming it is available?

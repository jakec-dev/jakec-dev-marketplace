#!/usr/bin/env bash
# shellcheck disable=SC2016 # Backticks in the fixtures are literal Markdown, not command substitution.
# Builds a clean knowledge tree, then plants one defect per case and asserts check-knowledge.sh's exit status, so a
# check that has stopped firing fails here instead of passing every tree.
# BASH_UNDER_TEST picks the shell that runs the check, such as macOS's /bin/bash 3.2.

set -euo pipefail

check="$(cd "$(dirname "$0")" && pwd)/check-knowledge.sh"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0
tab=$'\t'
link='[memory › Path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)'

# Creates a clean tree for one case and enters it.
fixture() {
  local dir="$root/$cases"
  mkdir -p "$dir/knowledge/rules" "$dir/maintenance/ledger" "$dir/maintenance/topics"
  cd "$dir"
  printf 'memory\t2\tPath-specific rules\t1\t2\t2\nmemory\t2\tAuto memory\t3\t4\t4\n' >toc.tsv
  cat >knowledge/rules/index.md <<'EOF'
# Rules knowledge

- [loading.md](loading.md): when a rule enters Claude's context. Read when choosing paths.
EOF
  cat >knowledge/rules/loading.md <<EOF
# Rule loading

When a rule in \`.claude/rules/\` enters Claude's context.

## Path-scoped rules

- A rule with a \`paths\` list loads when Claude uses the Read, Write or Edit tool on a matching file.
  $link

  \`\`\`yaml
  # a comment in an example, not a heading
  paths:
    - "src/**/*.ts"
  \`\`\`
EOF
  printf '# Rules topics\n\n- `loading.md`: knowing when a rule enters context\n' >maintenance/topics/rules.md
  printf 'page\theading\tdecision\tfile\treason\n' >maintenance/ledger/rules.tsv
  printf 'memory\tPath-specific rules\tincluded\tloading.md\t\n' >>maintenance/ledger/rules.tsv
  printf 'memory\tAuto memory\texcluded\t\tnot about rules\n' >>maintenance/ledger/rules.tsv
}

# Runs the check on the case's tree and compares the exit status with the expected one.
expect() {
  local want=$1 name=$2 status=0
  "$shell" "$check" knowledge maintenance toc.tsv >"$root/out" 2>&1 || status=$?
  if [ "$status" -ne "$want" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want" "$status"
    sed 's/^/  /' "$root/out"
    return 1
  fi
  printf 'ok   %s\n' "$name"
}

run() {
  cases=$((cases + 1))
  (fixture && "$@") || failures=$((failures + 1))
}

# Appends a line to the topic file, or a row to the ledger.
topic_line() { printf '%s\n' "$1" >>knowledge/rules/loading.md; }
ledger_row() { printf '%s\n' "$1" >>maintenance/ledger/rules.tsv; }
hundred_facts() { for i in $(seq 1 100); do printf -- '- Fact %s. %s\n' "$i" "$link"; done; }

clean() { expect 0 'clean tree passes'; }
no_index() { rm knowledge/rules/index.md && expect 1 'missing index.md'; }
# The file is otherwise valid and in the ledger, so the missing index entry is the only defect.
unlisted_topic() {
  printf '# Extra\n\nText.\n' >knowledge/rules/extra.md
  echo '- `extra.md`: an extra task' >>maintenance/topics/rules.md
  ledger_row "memory${tab}Auto memory${tab}included${tab}extra.md${tab}"
  expect 1 'topic file not in the index'
}
listed_missing() {
  echo '- [gone.md](gone.md): gone.' >>knowledge/rules/index.md
  expect 1 'index lists a missing file'
}
no_title() { sed -i.bak '1s/^# //' knowledge/rules/loading.md && expect 1 'first line is not a title'; }
uncited() { topic_line '- A fact with no source.' && expect 1 'bullet without a link'; }
cross_link() {
  topic_line "- See [frontmatter](frontmatter.md). $link"
  expect 1 'link to another knowledge file'
}
relative_link() { topic_line "- See [skills](/docs/en/skills). $link" && expect 1 'relative link'; }
version_word() { topic_line "- Rules load on Write since 2.1.288. $link" && expect 1 'version history in words'; }
version_number() { topic_line "- Requires v2.1.288. $link" && expect 1 'version number'; }
long_line() {
  topic_line "- A fact. $link"
  topic_line "  $(printf 'x%.0s' {1..130})"
  expect 1 'line over 120 characters'
}
long_line_with_link() { topic_line "- $(printf 'x%.0s' {1..130}) $link" && expect 0 'long line holding a link passes'; }
long_code_line() {
  topic_line "- An example. $link"
  topic_line '  ```json'
  topic_line "  {\"command\": \"$(printf 'x%.0s' {1..130})\"}"
  topic_line '  ```'
  expect 0 'long line inside a code block passes'
}
long_index_line() {
  echo "- $(printf 'x%.0s' {1..130})" >>knowledge/rules/index.md
  expect 1 'long line in index.md'
}
two_sentences_same_file() {
  ledger_row "memory${tab}Auto memory${tab}included${tab}loading.md${tab}the sentence on order"
  ledger_row "memory${tab}Auto memory${tab}included${tab}loading.md${tab}the sentence on priority"
  expect 0 'two named sentences of one section to one file pass'
}
long_table_row() {
  topic_line "| \`field\` | $(printf 'x%.0s' {1..130}) |"
  expect 0 'long table row passes'
}
no_contents() { hundred_facts >>knowledge/rules/loading.md && expect 1 'over 100 lines without contents'; }
with_contents() {
  {
    printf '# Rule loading\n\nWhen a rule loads.\n\n## Contents\n\n- Facts\n\n## Facts\n\n'
    hundred_facts
  } >knowledge/rules/loading.md
  expect 0 'over 100 lines with contents passes'
}
no_ledger() { rm maintenance/ledger/rules.tsv && expect 1 'missing ledger'; }
bad_header() { sed -i.bak '1s/.*/page heading/' maintenance/ledger/rules.tsv && expect 1 'ledger header'; }
unknown_section() {
  ledger_row "memory${tab}No such heading${tab}excluded${tab}${tab}x"
  expect 1 'section not in the table of contents'
}
bad_decision() {
  ledger_row "memory${tab}Auto memory${tab}maybe${tab}${tab}x"
  expect 1 'decision not included or excluded'
}
excluded_no_reason() {
  sed -i.bak 's/\tnot about rules$/\t/' maintenance/ledger/rules.tsv
  expect 1 'excluded row without a reason'
}
included_missing() {
  ledger_row "memory${tab}Auto memory${tab}included${tab}gone.md${tab}"
  expect 1 'included row names a missing file'
}
included_with_scope() {
  ledger_row "memory${tab}Auto memory${tab}included${tab}loading.md${tab}only the sentences on rules"
  expect 0 'included row with a scope note passes'
}
included_no_file() {
  # A section with no other empty-file row, so the missing file is the only defect.
  ledger_row "memory${tab}Path-specific rules${tab}included${tab}${tab}"
  expect 1 'included row without a file'
}
no_topics() { rm maintenance/topics/rules.md && expect 1 'missing topics file'; }
topic_not_in_topics() {
  printf '# Extra\n\nText.\n' >knowledge/rules/extra.md
  echo '- [extra.md](extra.md): extra.' >>knowledge/rules/index.md
  ledger_row "memory${tab}Auto memory${tab}included${tab}extra.md${tab}"
  expect 1 'topic file not in the topics list'
}
listed_topic_missing() {
  echo '- `gone.md`: a task with no file' >>maintenance/topics/rules.md
  expect 1 'topics list names a missing file'
}
topic_not_in_ledger() {
  printf '# Extra\n\nText.\n' >knowledge/rules/extra.md
  echo '- [extra.md](extra.md): extra.' >>knowledge/rules/index.md
  echo '- `extra.md`: an extra task' >>maintenance/topics/rules.md
  expect 1 'topic file with no included row'
}
two_owners() {
  printf '# Extra\n\nText.\n' >knowledge/rules/extra.md
  echo '- [extra.md](extra.md): extra.' >>knowledge/rules/index.md
  echo '- `extra.md`: an extra task' >>maintenance/topics/rules.md
  ledger_row "memory${tab}Path-specific rules${tab}included${tab}extra.md${tab}"
  expect 1 'section with two owners'
}
handed_sentence() {
  printf '# Extra\n\nText.\n' >knowledge/rules/extra.md
  echo '- [extra.md](extra.md): extra.' >>knowledge/rules/index.md
  echo '- `extra.md`: an extra task' >>maintenance/topics/rules.md
  ledger_row "memory${tab}Path-specific rules${tab}included${tab}extra.md${tab}the sentence on symlinks"
  expect 0 'a named sentence handed to a second file passes'
}
duplicate_row() {
  ledger_row "memory${tab}Auto memory${tab}excluded${tab}${tab}not about rules"
  expect 1 'duplicate ledger row'
}

for test in clean no_index unlisted_topic listed_missing no_title uncited cross_link relative_link version_word \
  version_number long_line long_line_with_link long_code_line long_index_line two_sentences_same_file \
  long_table_row no_contents with_contents no_ledger bad_header unknown_section bad_decision excluded_no_reason \
  included_missing included_with_scope included_no_file no_topics topic_not_in_topics listed_topic_missing \
  topic_not_in_ledger two_owners handed_sentence duplicate_row; do
  run "$test"
done

cases=$((cases + 1))
status=0
"$shell" "$check" >/dev/null 2>&1 || status=$?
if [ "$status" -eq 2 ]; then echo 'ok   no arguments'; else
  echo "FAIL no arguments: want exit 2, got $status"
  failures=$((failures + 1))
fi

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]

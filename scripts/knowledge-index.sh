#!/usr/bin/env bash
# Prints the `## Topics` section of a tool type's knowledge index: every topic file, in the order the type's topic
# list gives, with the task it serves and, under it, each of its `##` sections. An agent reads the index, then only
# the sections its task needs.
#
# Usage: knowledge-index.sh <type-dir> <topics.md>
#   <type-dir>   a tool type's knowledge directory, such as plugins/agent-setup/reference/rules
#   <topics.md>  its topic list, such as maintenance/topics/rules.md
# Exit status: 0 on success, 1 when a listed topic file is missing, 2 on a usage error.

set -euo pipefail

if [ $# -ne 2 ] || [ ! -d "$1" ] || [ ! -f "$2" ]; then
  echo 'usage: knowledge-index.sh <type-dir> <topics.md>' >&2
  exit 2
fi
dir=${1%/}

printf '## Topics\n'
# Each topic line reads "- `name.md`: task", possibly wrapped onto indented lines.
# shellcheck disable=SC2016 # The backticks are literal Markdown, not command substitution.
awk '
  /^- `[a-z0-9-]+\.md`:/ {
    if (name) print name "\t" task
    match($0, /`[^`]+`/); name = substr($0, RSTART + 1, RLENGTH - 2)
    sub(/^- `[^`]+`: */, ""); task = $0
    next
  }
  name && /^  / { sub(/^ +/, ""); task = task " " $0; next }
  { if (name) print name "\t" task; name = "" }
  END { if (name) print name "\t" task }
' "$2" | while IFS=$'\t' read -r name task; do
  if [ ! -f "$dir/$name" ]; then
    echo "knowledge-index: $2 lists $name, which does not exist" >&2
    exit 1
  fi
  # Wraps the entry at 120 characters, continuing on lines indented by two spaces.
  printf '\n- [%s](%s): %s\n' "$name" "$name" "$task" | awk '
    {
      line = ""; n = split($0, words, " ")
      for (i = 1; i <= n; i++) {
        if (line != "" && length(line) + 1 + length(words[i]) > 120) { print line; line = "  " words[i] }
        else line = (line == "" ? words[i] : line " " words[i])
      }
      print line
    }
  '
  awk '
    /^[ \t]*(```|~~~)/ { fence = !fence }
    !fence && /^## / && $0 != "## Contents" { print "  - " substr($0, 4) }
  ' "$dir/$name"
done

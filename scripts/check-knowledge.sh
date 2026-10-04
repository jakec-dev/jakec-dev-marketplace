#!/usr/bin/env bash
# Checks the structure of the plugin's knowledge files and their ledgers against .claude/skills/knowledge/format.md.
# It checks shape, not truth: whether a fact is right is the reviewer's job, and links are check-links.sh's.
#
# Usage: check-knowledge.sh <knowledge-dir> <ledger-dir> <toc.tsv>
#   <knowledge-dir>  holds one directory per tool type, such as plugins/agent-setup/knowledge
#   <ledger-dir>     holds <type>.tsv for each of them, such as maintenance/ledger
#   <toc.tsv>        is the output of scripts/docs-toc.sh for the documentation copy the knowledge was written from
# Exit status: 0 when everything passes, 1 when anything fails, 2 on a usage error.

set -euo pipefail

if [ $# -ne 3 ] || [ ! -d "$1" ] || [ ! -d "$2" ] || [ ! -f "$3" ]; then
  echo 'usage: check-knowledge.sh <knowledge-dir> <ledger-dir> <toc.tsv>' >&2
  exit 2
fi
knowledge=$1
ledgers=$2
toc=$3

problems=0
report() {
  printf '%s\n' "$1"
  problems=$((problems + 1))
}

# Prints a problem for each line of one topic file that breaks the format, as "<file>:<line>: <problem>".
check_topic() {
  awk -v file="$1" '
    function flush() {
      if (bullet && !cited) print file ":" bullet ": bullet has no link to the documentation"
      bullet = 0; cited = 0
    }
    FNR == 1 && !/^# / { print file ":1: first line is not a # title" }
    /^## / { in_contents = ($0 == "## Contents"); if (in_contents) contents = 1 }
    /^[ \t]*(```|~~~)/ { fence = !fence }
    { bare = $0; gsub(/https?:\/\/[^) ]+/, "", bare) }
    length(bare) > 120 && !/^[ \t]*\|/ { print file ":" FNR ": line longer than 120 characters, not counting links" }
    !fence {
      rest = $0
      while (match(rest, /\]\([^)]+\)/)) {
        target = substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH)
        if (target !~ /^https?:/ && target ~ /\.md(#.*)?$/) print file ":" FNR ": links to another knowledge file"
      }
    }
    !fence && tolower($0) ~ /(^|[^a-z])(since|before|until) v?[0-9]+\.[0-9]+/ { print file ":" FNR ": version history" }
    !fence && /(^|[^0-9a-z])v[0-9]+\.[0-9]+\.[0-9]+/ { print file ":" FNR ": version history" }
    !fence && /^- / { flush(); if (!in_contents) bullet = FNR }
    !fence && /^#/ { flush() }
    bullet && /\]\(https:\/\/code\.claude\.com\/docs\/en\// { cited = 1 }
    END {
      flush()
      if (FNR > 100 && !contents) print file ": over 100 lines with no ## Contents section"
    }
  ' "$1"
}

found_type=0
for dir in "$knowledge"/*/; do
  [ -d "$dir" ] || continue
  found_type=1
  type=$(basename "$dir")
  index="$dir/index.md"
  ledger="$ledgers/$type.tsv"

  if [ ! -f "$index" ]; then
    report "$dir: no index.md"
    continue
  fi

  # Every topic file is listed in the index, and every file the index lists exists.
  for topic in "$dir"*.md; do
    name=$(basename "$topic")
    [ "$name" = index.md ] && continue
    grep -qF "]($name)" "$index" || report "$index: does not list $name"
    while IFS= read -r line; do report "$line"; done < <(check_topic "$topic")
  done
  while IFS= read -r name; do
    [ -f "$dir$name" ] || report "$index: lists $name, which does not exist"
  done < <(grep -o -E '\]\([a-z0-9-]+\.md\)' "$index" | sed -E 's/^\]\(//; s/\)$//')

  if [ ! -f "$ledger" ]; then
    report "$ledger: missing"
    continue
  fi
  while IFS= read -r line; do report "$line"; done < <(
    awk -F '\t' -v ledger="$ledger" -v dir="$dir" '
      NR == FNR { known[$1 "\t" $3] = 1; next }
      { at = ledger ":" FNR ": " }
      FNR == 1 {
        if ($0 != "page\theading\tdecision\tfile\treason") print at "header is not: page heading decision file reason"
        next
      }
      NF != 5 { print at "has " NF " fields, not 5"; next }
      !(($1 "\t" $2) in known) { print at "no section \"" $2 "\" on page " $1 " in the table of contents" }
      seen[$1 "\t" $2 "\t" $4]++ { print at "duplicate row" }
      $3 == "included" {
        if ($4 == "" || $5 != "") { print at "an included row must name a file and give no reason"; next }
        used[$4] = 1
        if ((getline probe < (dir $4)) < 0) print at $4 " does not exist"
        close(dir $4)
        next
      }
      $3 == "excluded" {
        if ($4 != "" || $5 == "") print at "an excluded row must give a reason and name no file"
        next
      }
      { print at "decision is not included or excluded" }
      END {
        cmd = "ls \"" dir "\""
        while ((cmd | getline name) > 0) if (name ~ /\.md$/ && name != "index.md" && !(name in used)) {
          print ledger ": no included row for " name
        }
        close(cmd)
      }
    ' "$toc" "$ledger"
  )
done

[ "$found_type" -eq 1 ] || report "$knowledge: no tool type directories"
printf 'check-knowledge: %s problems\n' "$problems"
[ "$problems" -eq 0 ]

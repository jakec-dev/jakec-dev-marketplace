#!/usr/bin/env bash
# Checks the structure of the plugin's knowledge files, their topic lists and their ledgers against
# .claude/skills/knowledge/format.md.
# It checks shape, not truth: whether a fact is right is the reviewer's job, and links are check-links.sh's.
#
# Usage: check-knowledge.sh <knowledge-dir> <maintenance-dir> <toc.tsv>
#   <knowledge-dir>    holds one directory per tool type, such as plugins/agent-setup/reference, or is itself one
#                      such directory when it holds an index.md, such as plugins/agent-setup/guidance
#   <maintenance-dir>  holds ledger/<type>.tsv and topics/<type>.md for each of them, such as maintenance
#   <toc.tsv>        is the output of scripts/docs-toc.sh for the documentation copy the knowledge was written from
# Exit status: 0 when everything passes, 1 when anything fails, 2 on a usage error.

set -euo pipefail

if [ $# -ne 3 ] || [ ! -d "$1" ] || [ ! -d "$2" ] || [ ! -f "$3" ]; then
  echo 'usage: check-knowledge.sh <knowledge-dir> <maintenance-dir> <toc.tsv>' >&2
  exit 2
fi
here=$(cd "$(dirname "$0")" && pwd)
knowledge=$1
maintenance=$2
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
    # format.md exempts a line holding a link, a table row and a line inside a code block from the length limit.
    !fence && length($0) > 120 && !/\]\(https?:/ && !/^[ \t]*\|/ {
      print file ":" FNR ": line longer than 120 characters"
    }
    !fence {
      rest = $0
      while (match(rest, /\]\([^)]+\)/)) {
        target = substr(rest, RSTART + 2, RLENGTH - 3); rest = substr(rest, RSTART + RLENGTH)
        if (target ~ /^\//) print file ":" FNR ": relative link to " target "; use the absolute https link"
        else if (target !~ /^https?:/ && target ~ /\.md(#.*)?$/) print file ":" FNR ": links to another knowledge file"
      }
    }
    !fence && tolower($0) ~ /(^|[^a-z])(since|before|until) v?[0-9]+\.[0-9]+/ { print file ":" FNR ": version history" }
    !fence && /(^|[^0-9a-z])v[0-9]+\.[0-9]+\.[0-9]+/ { print file ":" FNR ": version history" }
    # A guideline'"'"'s closing Check and Evidence bullets rest on the bullets above them, so they need no link.
    !fence && /^- / { flush(); if (!in_contents && !/^- (Check|Evidence): /) bullet = FNR }
    !fence && /^#/ { flush() }
    bullet && /\]\(https:\/\/code\.claude\.com\/docs\/en\// { cited = 1 }
    END {
      flush()
      if (FNR > 100 && !contents) print file ": over 100 lines with no ## Contents section"
    }
  ' "$1"
}

found_type=0
if [ -f "$knowledge/index.md" ]; then set -- "${knowledge%/}/"; else set -- "$knowledge"/*/; fi
for dir in "$@"; do
  [ -d "$dir" ] || continue
  found_type=1
  type=$(basename "$dir")
  index="$dir/index.md"
  ledger="$maintenance/ledger/$type.tsv"
  topics="$maintenance/topics/$type.md"

  if [ ! -f "$index" ]; then
    report "$dir: no index.md"
    continue
  fi
  while IFS= read -r line; do report "$line"; done < <(
    awk -v file="$index" '
      length($0) > 120 && !/\]\(https?:/ { print file ":" FNR ": line longer than 120 characters" }
    ' "$index"
  )

  for topic in "$dir"*.md; do
    [ "$(basename "$topic")" = index.md ] && continue
    while IFS= read -r line; do report "$line"; done < <(check_topic "$topic")
  done

  # The topic list and the topic files match exactly.
  if [ ! -f "$topics" ]; then
    report "$topics: missing"
  else
    # shellcheck disable=SC2016 # The backticks are literal Markdown, not command substitution.
    while IFS= read -r name; do
      [ -f "$dir$name" ] || report "$topics: lists $name, which does not exist"
    done < <(grep -o -E '^- `[a-z0-9-]+\.md`' "$topics" | sed -E 's/^- `//; s/`$//')
    for topic in "$dir"*.md; do
      name=$(basename "$topic")
      [ "$name" = index.md ] && continue
      grep -qF -- "- \`$name\`" "$topics" || report "$topics: does not list $name"
    done
    # Every key fact's pointer, written [file.md › heading](file.md), names a heading that exists in that file.
    while IFS= read -r pointer; do
      file=${pointer#[}
      file=${file%% › *}
      heading=${pointer#* › }
      heading=${heading%](*}
      if [ ! -f "$dir$file" ] || ! grep -qxF "## $heading" "$dir$file"; then
        report "$index: $pointer points to a section that does not exist"
      fi
    done < <(grep -o '\[[a-z0-9-]*\.md › [^]]*\]([a-z0-9-]*\.md)' "$index" || true)
    # The index's Topics section is generated, so it must match the generator exactly.
    if ! generated=$("$here/knowledge-index.sh" "$dir" "$topics" 2>/dev/null); then
      report "$topics: knowledge-index.sh could not build the Topics section"
    elif [ "$(sed -n '/^## Topics$/,$p' "$index")" != "$generated" ]; then
      report "$index: the Topics section is out of date; regenerate it with scripts/knowledge-index.sh"
    fi
  fi

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
      seen[$0]++ { print at "duplicate row" }
      $3 == "included" {
        if ($4 == "") { print at "an included row must name a file"; next }
        # A row with a reason hands one named sentence or row of the section to this file, so it is not an owner.
        if ($5 == "" && owner[$1 "\t" $2]++) print at "section already has an owner"
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

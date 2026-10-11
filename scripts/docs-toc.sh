#!/usr/bin/env bash
# Prints a table of contents for Claude Code's documentation export (llms-full.txt), one tab-separated row per
# section:
#
#   page  level  heading  start  end  subtree_end
#
# `page` is the path after https://code.claude.com/docs/en/, taken from the `Source:` line under each page's title.
# `start` is the heading's line. `end` is the last line of the section's own text, before the next heading of any
# level; `subtree_end` is the last line before the next heading at the same or a higher level, so it includes the
# section's subsections. Read a section with its line range rather than searching for its text.
#
# A heading is a markdown heading or an HTML one (`<h4 id="...">` with the title on the following lines), never a
# line inside a code fence. A heading repeated within a page gets " (2)", " (3)" and so on, so that page and heading
# together identify one section.
#
# Usage: docs-toc.sh <llms-full.txt>
# Exit status: 0 on success, 1 when the file has no pages, 2 on a usage error.

set -euo pipefail

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo 'usage: docs-toc.sh <llms-full.txt>' >&2
  exit 2
fi

# The first pass records each page's title line: a `# ` line directly followed by its `Source:` line. The second
# pass resets the fence state at every page, so an unclosed fence on one page cannot hide the next page's headings.
awk -F '\t' '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  # Open sections form a stack of strictly rising levels; a heading at level L ends every open section at L or deeper.
  function pop_to(level, upto) { while (sp > 0 && lvl[stack[sp]] >= level) { sub_end[stack[sp]] = upto; sp-- } }
  function add(level, text, line,    key) {
    text = trim(text)
    if (n && own[n] == "") own[n] = line - 1
    pop_to(level, line - 1)
    seen[page, text]++
    key = seen[page, text] > 1 ? text " (" seen[page, text] ")" : text
    n++; pg[n] = page; lvl[n] = level; head[n] = key; start[n] = line
    stack[++sp] = n
  }
  NR == FNR {
    if (prev ~ /^# / && $0 ~ /^Source: https:\/\/code\.claude\.com\/docs\/en\//) title[FNR - 1] = 1
    prev = $0
    next
  }
  FNR in title { fence = ""; html_level = 0; pending = substr($0, 3); next }
  pending != "" {
    page = $0; sub(/^Source: https:\/\/code\.claude\.com\/docs\/en\//, "", page)
    add(1, pending, FNR - 1); pending = ""; pages++
    next
  }
  !pages { next }
  html_level {
    if ($0 ~ "^[ \t]*</h" html_level ">") { add(html_level, html_text, html_line); html_level = 0 }
    else html_text = html_text " " trim($0)
    next
  }
  match($0, /^[ \t]*(```+|~~~+)/) {
    marker = substr($0, RSTART, RLENGTH); sub(/^[ \t]+/, "", marker)
    if (fence == "") fence = marker
    else if (substr(marker, 1, 1) == substr(fence, 1, 1) && length(marker) >= length(fence) &&
             trim(substr($0, RSTART + RLENGTH)) == "") fence = ""
    next
  }
  fence != "" { next }
  match($0, /^#+ /) && RLENGTH <= 7 { add(RLENGTH - 1, substr($0, RLENGTH + 1), FNR); next }
  /^[ \t]*<h[1-6][ >]/ {
    html_level = substr(trim($0), 3, 1); html_line = FNR
    rest = $0; sub(/^[ \t]*<h[1-6][^>]*>/, "", rest)
    if (rest ~ "</h" html_level ">") {
      sub("</h" html_level ">.*", "", rest); add(html_level, rest, FNR); html_level = 0
    } else html_text = trim(rest)
  }
  END {
    if (!pages) exit 1
    if (own[n] == "") own[n] = FNR
    pop_to(1, FNR)
    for (i = 1; i <= n; i++) print pg[i] "\t" lvl[i] "\t" head[i] "\t" start[i] "\t" own[i] "\t" sub_end[i]
  }
' "$1" "$1"

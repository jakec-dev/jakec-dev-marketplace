#!/usr/bin/env bash
# Fetches the Anthropic pages that guidance draws on, which Claude Code's documentation links to but llms-full.txt
# does not contain, and writes them as one export in llms-full.txt's shape, so scripts/docs-toc.sh, docs-find.sh
# and check-knowledge.sh read them as they read Claude Code's own pages:
#
#   # <title>
#   Source: <url>
#
#   <the page's Markdown, without its frontmatter>
#
# Each page is fetched as Markdown from <url>.md, whose YAML frontmatter gives the title.
#
# Usage: fetch-sources.sh <sources.tsv> <out-file>
#   <sources.tsv>  tab-separated, with the header row `url	linked_from`: one row per page, its URL under
#                  https://platform.claude.com/docs/en/ without .md, and the Claude Code section that links to it
#   <out-file>     written only when every page is fetched, so a failed run leaves the previous copy in place
# Exit status: 0 on success, 1 when a page cannot be fetched or has no title, 2 on a usage error.

set -euo pipefail

if [ $# -ne 2 ] || [ ! -f "$1" ]; then
  echo 'usage: fetch-sources.sh <sources.tsv> <out-file>' >&2
  exit 2
fi
sources=$1
out=$2

if [ "$(head -n 1 "$sources")" != "$(printf 'url\tlinked_from')" ]; then
  echo "$sources: header is not: url linked_from" >&2
  exit 2
fi

tmp=$(mktemp)
page=$(mktemp)
trap 'rm -f "$tmp" "$page"' EXIT

count=0
while IFS=$'\t' read -r url _; do
  [ -n "$url" ] || continue
  case $url in
    https://platform.claude.com/docs/en/*) ;;
    *)
      echo "$sources: $url is not a page under https://platform.claude.com/docs/en/" >&2
      exit 1
      ;;
  esac
  if ! curl -sSfL -o "$page" "$url.md"; then
    echo "$url: could not fetch $url.md" >&2
    exit 1
  fi
  # The title comes from the frontmatter that opens the file; the body starts after its closing ---.
  title=$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && /^---$/ { exit } NR > 1 && /^title: / { sub(/^title: /, ""); print; exit }' "$page")
  if [ -z "$title" ]; then
    echo "$url: no title in the frontmatter of $url.md" >&2
    exit 1
  fi
  [ "$count" -eq 0 ] || printf '\n' >>"$tmp"
  printf '# %s\nSource: %s\n\n' "$title" "$url" >>"$tmp"
  awk 'body { if (started || NF) { started = 1; print }; next } NR > 1 && /^---$/ { body = 1 }' "$page" >>"$tmp"
  count=$((count + 1))
done < <(tail -n +2 "$sources")

if [ "$count" -eq 0 ]; then
  echo "$sources: no pages listed" >&2
  exit 1
fi
mkdir -p "$(dirname "$out")"
mv "$tmp" "$out"
printf 'fetch-sources: %s pages written to %s\n' "$count" "$out"

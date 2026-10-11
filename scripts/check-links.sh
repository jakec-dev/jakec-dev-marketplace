#!/usr/bin/env bash
# Checks every http(s) link written as [text](url) in the given Markdown files. A link passes when its page answers
# 200 without a redirect and, if the link has a #fragment, the page contains an element with that id.
#
# Usage: check-links.sh <file>...
# Exit status: 0 when every link passes, 1 when any fails, 2 on a usage error.

set -euo pipefail

if [ $# -eq 0 ]; then
  echo 'usage: check-links.sh <file>...' >&2
  exit 2
fi
for file in "$@"; do
  if [ ! -f "$file" ]; then
    echo "check-links: no such file: $file" >&2
    exit 2
  fi
done

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT

# Fetches a page once per run and prints "<status> <redirect target>"; the body is kept in the cache.
fetch() {
  local key
  key=$(printf '%s' "$1" | cksum | cut -d ' ' -f 1)
  if [ ! -f "$cache/$key.status" ]; then
    curl -s -o "$cache/$key.body" -w '%{http_code} %{redirect_url}' --max-time 30 "$1" >"$cache/$key.status" ||
      printf '000 ' >"$cache/$key.status"
  fi
  printf '%s\n' "$cache/$key"
}

failures=0
checked=0
for file in "$@"; do
  while IFS= read -r match; do
    line=${match%%:*}
    url=${match#*:](}
    url=${url%)}
    page=${url%%#*}
    fragment=
    case $url in *'#'*) fragment=${url#*#} ;; esac

    checked=$((checked + 1))
    entry=$(fetch "$page")
    read -r status target <"$entry.status" || true
    if [ "$status" != 200 ]; then
      printf '%s:%s: %s answered %s%s\n' "$file" "$line" "$page" "$status" "${target:+, redirecting to $target}"
      failures=$((failures + 1))
    elif [ -n "$fragment" ] && ! grep -qF "id=\"$fragment\"" "$entry.body"; then
      printf '%s:%s: %s has no element with id "%s"\n' "$file" "$line" "$page" "$fragment"
      failures=$((failures + 1))
    fi
  done < <(grep -n -o -E '\]\(https?://[^) ]+\)' "$file" || true)
done

printf 'check-links: %s links, %s failed\n' "$checked" "$failures"
[ "$failures" -eq 0 ]

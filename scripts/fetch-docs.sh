#!/usr/bin/env bash
# Fetches Claude Code's documentation export, every page in one file, which scripts/docs-toc.sh,
# docs-fingerprint.sh and docs-find.sh read. The export is Anthropic's text, so it stays out of the repository; its
# table of contents and fingerprints are what get committed.
#
# Usage: fetch-docs.sh <out-file>
#   <out-file>  written only when the fetch succeeds and the result has at least one page, so a failed run leaves
#               the previous copy in place
# DOCS_URL overrides the source, for tests.
# Exit status: 0 on success, 1 when the fetch fails or the result has no pages, 2 on a usage error.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo 'usage: fetch-docs.sh <out-file>' >&2
  exit 2
fi
out=$1
url=${DOCS_URL:-https://code.claude.com/docs/llms-full.txt}

tmp=$(mktemp "$out.XXXXXX")
trap 'rm -f "$tmp"' EXIT

if ! curl -fsSL --retry 2 "$url" -o "$tmp"; then
  echo "$url: fetch failed" >&2
  exit 1
fi
if ! grep -q '^Source: https://code\.claude\.com/docs/en/' "$tmp"; then
  echo "$url: no pages in the result" >&2
  exit 1
fi
mv "$tmp" "$out"

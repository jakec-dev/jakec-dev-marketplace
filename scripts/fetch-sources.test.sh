#!/usr/bin/env bash
# Runs fetch-sources.sh against a stub curl that serves local files, and checks the export it writes, that
# docs-toc.sh reads that export, and that a failed run leaves the previous export untouched.
# BASH_UNDER_TEST picks the shell that runs the script, such as macOS's /bin/bash 3.2.

set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

failures=0
cases=0
pass() { printf 'ok   %s\n' "$1"; }
fail() {
  printf 'FAIL %s: %s\n' "$1" "$2"
  failures=$((failures + 1))
}

# The stub serves https://platform.claude.com/docs/en/<path>.md from $root/site/<path>.md, failing like curl -f
# when the file is missing.
mkdir -p "$root/bin" "$root/site/a"
cat >"$root/bin/curl" <<EOF
#!/usr/bin/env bash
out=; url=
while [ \$# -gt 0 ]; do
  case \$1 in -o) out=\$2; shift 2 ;; -*) shift ;; *) url=\$1; shift ;; esac
done
file="$root/site/\${url#https://platform.claude.com/docs/en/}"
[ -f "\$file" ] || { echo "curl: (22) The requested URL returned error: 404" >&2; exit 22; }
cp "\$file" "\$out"
EOF
chmod +x "$root/bin/curl"

cat >"$root/site/a/one.md" <<'EOF'
---
title: First page
url: https://platform.claude.com/docs/en/a/one
---

Intro.

## Section

```markdown
# Not a heading
```
EOF
cat >"$root/site/two.md" <<'EOF'
---
description: no title here
title: Second page
---
Body of two.
EOF
printf 'no frontmatter\n' >"$root/site/bare.md"

tab=$'\t'
sources() {
  printf 'url%slinked_from\n' "$tab" >"$root/sources.tsv"
  for url in "$@"; do printf '%s%sskills › Related resources\n' "$url" "$tab" >>"$root/sources.tsv"; done
}

# Runs the script with the stub curl first on PATH and records its status.
run() {
  status=0
  PATH="$root/bin:$PATH" "$shell" "$dir/fetch-sources.sh" "$@" >"$root/stdout" 2>"$root/stderr" || status=$?
}

cases=$((cases + 1))
sources https://platform.claude.com/docs/en/a/one https://platform.claude.com/docs/en/two
run "$root/sources.tsv" "$root/out/export.txt"
want="# First page
Source: https://platform.claude.com/docs/en/a/one

Intro.

## Section

\`\`\`markdown
# Not a heading
\`\`\`

# Second page
Source: https://platform.claude.com/docs/en/two

Body of two."
if [ "$status" -ne 0 ]; then
  fail 'pages written in llms-full.txt shape' "exit $status: $(cat "$root/stderr")"
elif [ "$(cat "$root/out/export.txt")" != "$want" ]; then
  fail 'pages written in llms-full.txt shape' 'unexpected export'
  diff <(printf '%s\n' "$want") "$root/out/export.txt" | sed 's/^/  /'
else
  pass 'pages written in llms-full.txt shape'
fi

cases=$((cases + 1))
toc=$("$shell" "$dir/docs-toc.sh" "$root/out/export.txt")
want_toc="platform.claude.com/a/one${tab}1${tab}First page${tab}1${tab}5${tab}11
platform.claude.com/a/one${tab}2${tab}Section${tab}6${tab}11${tab}11
platform.claude.com/two${tab}1${tab}Second page${tab}12${tab}15${tab}15"
if [ "$toc" = "$want_toc" ]; then pass 'docs-toc.sh reads the export'; else
  fail 'docs-toc.sh reads the export' 'unexpected table of contents'
  diff <(printf '%s\n' "$want_toc") <(printf '%s\n' "$toc") | sed 's/^/  /'
fi

# Each failure must exit 1 and leave the export from the first case as it was.
expect_failure() {
  local name=$1
  shift
  cases=$((cases + 1))
  sources "$@"
  run "$root/sources.tsv" "$root/out/export.txt"
  if [ "$status" -ne 1 ]; then
    fail "$name" "want exit 1, got $status"
  elif [ "$(cat "$root/out/export.txt")" != "$want" ]; then
    fail "$name" 'the previous export changed'
  else
    pass "$name"
  fi
}
expect_failure 'a page that cannot be fetched' https://platform.claude.com/docs/en/a/one \
  https://platform.claude.com/docs/en/missing
expect_failure 'a page with no title' https://platform.claude.com/docs/en/bare
expect_failure 'a URL outside platform.claude.com' https://example.com/docs/en/a/one
expect_failure 'no pages listed'

cases=$((cases + 1))
printf 'url\n' >"$root/bad.tsv"
run "$root/bad.tsv" "$root/out/export.txt"
if [ "$status" -eq 2 ]; then pass 'wrong header'; else fail 'wrong header' "want exit 2, got $status"; fi

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]

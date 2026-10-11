#!/usr/bin/env bash
# Serves fixture pages from a local HTTP server and asserts check-links.sh's exit status for each kind of link, so a
# check that has stopped firing fails here instead of passing every link.
# BASH_UNDER_TEST picks the shell that runs the check, such as macOS's /bin/bash 3.2. Needs python3 for the server.

set -euo pipefail

check="$(cd "$(dirname "$0")" && pwd)/check-links.sh"
shell=${BASH_UNDER_TEST:-bash}
root=$(mktemp -d)
mkdir -p "$root/site/folder"
printf '<h2 id="present">Present</h2>\n' >"$root/site/page.html"
printf 'index\n' >"$root/site/folder/index.html"

# Port 0 asks the OS for a free port; the server prints the one it got.
python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$root/site" >"$root/server.log" 2>&1 &
server=$!
# Keeps the suite's own exit status: waiting on the killed server would otherwise replace it.
trap 'status=$?; kill "$server" 2>/dev/null; wait "$server" 2>/dev/null || true; rm -rf "$root"; exit "$status"' EXIT
# A cold CI machine can take many seconds to start Python, so this waits up to 60.
port=
for _ in $(seq 1 60); do
  port=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$root/server.log" | head -n 1)
  [ -n "$port" ] && break
  kill -0 "$server" 2>/dev/null || break
  sleep 1
done
if [ -z "$port" ]; then
  echo 'FAIL the fixture server did not start; its output:'
  sed 's/^/  /' "$root/server.log"
  exit 1
fi
base="http://127.0.0.1:$port"

failures=0
cases=0

# Writes the Markdown to a file, runs the check on it and compares the exit status with the expected one.
expect() {
  local want=$1 name=$2 markdown=$3 status=0
  cases=$((cases + 1))
  printf '%s\n' "$markdown" >"$root/doc.md"
  "$shell" "$check" "$root/doc.md" >"$root/out" 2>&1 || status=$?
  if [ "$status" -ne "$want" ]; then
    printf 'FAIL %s: want exit %s, got %s\n' "$name" "$want" "$status"
    sed 's/^/  /' "$root/out"
    failures=$((failures + 1))
  else
    printf 'ok   %s\n' "$name"
  fi
}

expect 0 'page that exists' "See [the page]($base/page.html)."
expect 0 'fragment that exists' "See [the section]($base/page.html#present)."
expect 0 'same page linked twice' "[a]($base/page.html#present) and [b]($base/page.html)"
expect 0 'no links' 'Plain text with no links.'
expect 1 'missing page' "See [gone]($base/missing.html)."
expect 1 'missing fragment' "See [gone]($base/page.html#absent)."
expect 1 'redirect' "See [folder]($base/folder)."
expect 1 'one bad link among good ones' "[a]($base/page.html) [b]($base/missing.html)"

cases=$((cases + 1))
status=0
"$shell" "$check" >/dev/null 2>&1 || status=$?
if [ "$status" -eq 2 ]; then echo 'ok   no arguments'; else
  echo "FAIL no arguments: want exit 2, got $status"
  failures=$((failures + 1))
fi

printf '%s cases, %s failed\n' "$cases" "$failures"
[ "$failures" -eq 0 ]

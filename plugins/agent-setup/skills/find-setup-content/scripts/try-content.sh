#!/usr/bin/env bash
# Runs a with-and-without test of one piece of Claude Code setup content in the current git repository, so a
# proposal is kept only when it changes what Claude does.
#
# A spec is a directory holding:
#
#   prompt.txt   a realistic task that would need the content
#   check.sh     run with bash in the trial's checkout after Claude stops; exit 0 means the difference is there
#   add.txt      optional: one line per file the with-arm gets, as `<file in the spec> <repository path>`, such as
#                `rule.md .claude/rules/types.md`. A list rather than a tree of files, since Claude Code treats
#                any path holding .claude/ as sensitive and asks before writing one.
#   remove.txt   optional: repository paths, one per line, that the without-arm loses, to test content the
#                repository already holds
#   without.txt  optional: lines as in add.txt that the without-arm gets, such as a copy of AGENTS.md with one
#                section cut, to test part of a file the repository already holds
#
# A spec needs at least one of add.txt, remove.txt and without.txt. Each trial is a fresh shared clone of the
# repository, detached at HEAD, so uncommitted changes are not tested and nothing is left in the repository. The
# with-arm gets add.txt's files; the without-arm loses remove.txt's paths and gets without.txt's files. Either way
# the change is hidden from git status and git diff, so neither points Claude at it. Claude runs with only the
# project's settings and instructions (--setting-sources project,local), so the user's own CLAUDE.md, rules, skills
# and plugins stay out; managed settings still apply.
#
# Usage: try-content.sh [options] <spec-dir> <out-dir>
#        try-content.sh --show <out-dir> [<arm>-<run>]
#   -n <runs>     runs per arm (default 3)
#   -j <jobs>     trials at once (default: every trial at once)
#   -m <model>    model for Claude (default: Claude Code's default)
#   --no-hooks    turn off every hook, for a repository whose hooks would hide the difference. Without the
#                 InstructionsLoaded hook, what loaded is inferred from where each instruction file sits and what
#                 Claude touched: `launch` for a rule without `paths`, the root CLAUDE.md, or the root AGENTS.md
#                 where no CLAUDE.md is there, which load at launch; `touched` for a path rule or a nested CLAUDE.md
#                 or AGENTS.md whose files Claude read, edited or wrote, which is what loads them. A rule loaded
#                 through a Bash read of a matching file is missed.
#
# Writes <out-dir>/<arm>-<run>/ for each trial (prompt, transcript, diff, check output, instructions loaded),
# <out-dir>/results.tsv with one row per trial, and prints a summary per arm. --show prints results.tsv, or one
# trial's tool calls, check output and diff, so a session that may not read <out-dir> can still see them.
# Exit status: 0 when every trial ran, 1 when a trial could not be set up or Claude failed, 2 on a usage error.

set -euo pipefail

usage() {
  cat >&2 <<'TXT'
usage: try-content.sh [-n runs] [-j jobs] [-m model] [--no-hooks] <spec-dir> <out-dir>
       try-content.sh --show <out-dir> [<arm>-<run>]
  -n <runs>     runs per arm (default 3)
  -j <jobs>     trials at once (default: every trial at once)
  -m <model>    model for Claude (default: Claude Code's default)
  --no-hooks    turn off every hook, for a repository whose hooks would hide the difference
TXT
  exit 2
}

suffix="

Dependencies are not installed here, so don't install them or run builds, tests, type checks or codegen. Make the
change, then stop."

# A placement list's lines (add.txt or without.txt) without blank lines, as `<file> <path>`.
placements() {
  if [ -f "$1" ]; then sed -e '/^[[:space:]]*$/d' "$1"; fi
}

# The paths a spec adds, removes or replaces, relative to the repository root, one per line.
watched_paths() {
  local spec=$1
  { placements "$spec/add.txt" && placements "$spec/without.txt"; } | awk '{ print $2 }' | sed 's#^\./##' | sort -u
  if [ -f "$spec/remove.txt" ]; then sed -e 's#^\./##' -e 's#/*$##' -e '/^[[:space:]]*$/d' "$spec/remove.txt"; fi
}

# Copies a placement list's files into the checkout, each hidden from git status and git diff.
place() {
  local spec=$1 list=$2 checkout=$3 exclude=$4 file path
  while read -r file path; do
    path=${path#./}
    mkdir -p "$(dirname "$checkout/$path")"
    cp "$spec/$file" "$checkout/$path"
    if [ -n "$(git -C "$checkout" ls-files -- "$path")" ]; then
      hide_tracked "$checkout" "$path"
    else
      printf '/%s\n' "$path" >>"$exclude"
    fi
  done < <(placements "$list")
}

# The repository paths Claude read, edited or wrote in a transcript, one per line.
touched_files() {
  local checkout=$1 transcript=$2
  { grep -oE '"name":"(Read|Edit|Write)","input":\{[^}]*"file_path":"[^"]*"' "$transcript" || true; } |
    sed -E -e 's/.*"file_path":"//' -e 's/"$//' -e "s#^($checkout|$(cd "$checkout" && pwd -P))/##"
}

# A rule's `paths` patterns, one per line, with each {a,b} expanded, and each `**/` also given dropped, since it
# matches no directory as well as any, which a shell pattern's `*` doesn't.
rule_paths() {
  awk '
    function expand(p, i, j, n, k, parts) {
      i = index(p, "{")
      if (!i) { emit(p); return }
      j = i + index(substr(p, i), "}") - 1
      n = split(substr(p, i + 1, j - i - 1), parts, ",")
      for (k = 1; k <= n; k++) expand(substr(p, 1, i - 1) parts[k] substr(p, j + 1))
    }
    function emit(p, q) {
      print p
      q = p
      gsub(/\*\*\//, "", q)
      if (q != p) print q
    }
    # Splits a line of patterns at commas and spaces outside braces.
    function items(line, c, i, depth, item) {
      item = ""
      for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)
        if (c == "{") depth++
        if (c == "}") depth--
        if (depth == 0 && (c == "," || c == " " || c == "\t")) {
          if (item != "") expand(item)
          item = ""
        } else item = item c
      }
      if (item != "") expand(item)
    }
    NR == 1 && !/^---$/ { exit }
    NR > 1 && /^---$/ { exit }
    /^paths:/ { list = 1; sub(/^paths:[[:space:]]*/, ""); if ($0 == "") next }
    list && /^[A-Za-z_]+:/ { list = 0 }
    list {
      gsub(/[]["\047]/, " ")
      sub(/^[[:space:]]*-[[:space:]]/, " ")
      items($0)
    }' "$1"
}

# How an instruction file in the checkout loaded when no hook records it: `launch`, `touched` or `no`.
loaded_without_hooks() {
  local checkout=$1 path=$2 transcript=$3 patterns file pattern
  [ -f "$checkout/$path" ] || return 0
  case $path in
    CLAUDE.md | .claude/CLAUDE.md) echo launch && return 0 ;;
    AGENTS.md | .claude/AGENTS.md)
      # Claude reads AGENTS.md only where no CLAUDE.md takes its place.
      if [ -f "$checkout/CLAUDE.md" ] || [ -f "$checkout/.claude/CLAUDE.md" ] ||
        [ -f "$checkout/CLAUDE.local.md" ]; then
        echo no
      else
        echo launch
      fi
      return 0
      ;;
    */CLAUDE.md | */AGENTS.md)
      if touched_files "$checkout" "$transcript" | grep -q "^${path%/*}/"; then echo touched; else echo no; fi
      return 0
      ;;
    .claude/rules/*.md) ;;
    *) echo no && return 0 ;;
  esac
  patterns=$(rule_paths "$checkout/$path")
  if [ -z "$patterns" ]; then echo launch && return 0; fi
  while IFS= read -r file; do
    while IFS= read -r pattern; do
      # shellcheck disable=SC2254 # the pattern is meant to match as a glob.
      case $file in $pattern) echo touched && return 0 ;; esac
    done <<<"$patterns"
  done < <(touched_files "$checkout" "$transcript")
  echo no
}

hide_tracked() {
  local checkout=$1 path=$2
  git -C "$checkout" ls-files -z -- "$path" | xargs -0 -n 50 git -C "$checkout" update-index --skip-worktree --
}

# One trial: try-content.sh --trial <spec> <out> <arm> <run>, with settings in TRY_* variables.
trial() {
  local spec=$1 out=$2 arm=$3 run=$4
  local dest="$out/$arm-$run" checkout status start settings log path exclude
  mkdir -p "$dest"
  checkout=$(cd "$(mktemp -d "${TMPDIR:-/tmp}/try-content.XXXXXX")" && pwd)
  # shellcheck disable=SC2064 # expand now: the trap must remove this trial's checkout.
  trap "rm -rf '$checkout'" EXIT
  # A clone, not a linked worktree: a worktree shares the repository's info/exclude, and the trial must not write
  # to it.
  git clone -q --shared --no-checkout "$TRY_REPO" "$checkout"
  git -C "$checkout" checkout -q --detach "$TRY_HEAD"

  exclude="$checkout/.git/info/exclude"
  mkdir -p "$(dirname "$exclude")"
  if [ "$arm" = with ]; then place "$spec" "$spec/add.txt" "$checkout" "$exclude"; fi
  if [ "$arm" = without ] && [ -f "$spec/remove.txt" ]; then
    while IFS= read -r path; do
      hide_tracked "$checkout" "$path"
      rm -rf "${checkout:?}/$path"
    done < <(sed -e 's#^\./##' -e 's#/*$##' -e '/^[[:space:]]*$/d' "$spec/remove.txt")
  fi
  if [ "$arm" = without ]; then place "$spec" "$spec/without.txt" "$checkout" "$exclude"; fi

  if [ "$TRY_NO_HOOKS" = 1 ]; then
    settings='{"disableAllHooks":true}'
  else
    log="cat >> '$dest/instructions.jsonl'; echo >> '$dest/instructions.jsonl'"
    settings="{\"hooks\":{\"InstructionsLoaded\":[{\"hooks\":[{\"type\":\"command\",\"command\":\"$log\"}]}]}}"
  fi
  printf '%s%s\n' "$(cat "$spec/prompt.txt")" "$suffix" >"$dest/prompt.txt"

  start=$(date +%s)
  status=0
  (
    cd "$checkout"
    set -- -p "$(cat "$dest/prompt.txt")" --setting-sources project,local --settings "$settings" \
      --permission-mode acceptEdits --max-turns 60 --output-format stream-json --verbose
    if [ -n "$TRY_MODEL" ]; then set -- "$@" --model "$TRY_MODEL"; fi
    claude "$@" </dev/null >"$dest/transcript.jsonl" 2>"$dest/stderr.txt"
  ) || status=$?

  git -C "$checkout" add -A -N
  git -C "$checkout" diff HEAD >"$dest/diff.patch"
  local check=fail
  if (cd "$checkout" && TRY_ARM=$arm bash "$spec/check.sh") >"$dest/check.txt" 2>&1; then check=pass; fi

  # What of the spec's content loaded: the load reasons InstructionsLoaded gave for a watched file, and the
  # Skill calls naming a skill the spec adds or removes.
  local loaded='' skills=0 name reason cost
  if [ "$TRY_NO_HOOKS" = 1 ]; then
    while IFS= read -r path; do
      case $path in .claude/skills/*) continue ;; esac
      reason=$(loaded_without_hooks "$checkout" "$path" "$dest/transcript.jsonl")
      if [ -n "$reason" ] && [ "$reason" != no ]; then loaded="${loaded:+$loaded,}$reason"; fi
    done < <(watched_paths "$spec")
  elif [ -f "$dest/instructions.jsonl" ]; then
    while IFS= read -r path; do
      reason=$(grep -F "/$path\"" "$dest/instructions.jsonl" | sed -n 's/.*"load_reason" *: *"\([^"]*\)".*/\1/p' |
        sort -u | paste -sd , - || true)
      if [ -n "$reason" ]; then loaded="${loaded:+$loaded,}$reason"; fi
    done < <(watched_paths "$spec")
  fi
  while IFS= read -r name; do
    skills=$((skills + $(grep -c "\"name\":\"Skill\",\"input\":{[^}]*\"skill\":\"\([^\"]*:\)\{0,1\}$name\"" \
      "$dest/transcript.jsonl" || true)))
  done < <(watched_paths "$spec" | sed -n 's#^\(.*/\)\{0,1\}\.claude/skills/\([^/]*\).*#\2#p' | sort -u)
  cost=$(grep -o '"total_cost_usd":[0-9.e-]*' "$dest/transcript.jsonl" | tail -1 | cut -d: -f2 || true)
  # Each Read, Glob, Grep and Bash call by its first input, with the checkout's path taken out, as Claude may see it
  # either as it is or with its symbolic links resolved, such as /var as /private/var on macOS.
  { grep -oE '"name":"(Read|Glob|Grep|Bash)","input":\{"[a-z_]*":"([^"\\]|\\.)*"' "$dest/transcript.jsonl" || true; } |
    sed -E -e 's/^"name":"([A-Za-z]*)","input":\{"[a-z_]*":"/\1 /' -e 's/"$//' \
      -e "s#($checkout|$(cd "$checkout" && pwd -P))/?##g" >"$dest/looked.txt"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$arm" "$run" "$check" "${loaded:-no}" "$skills" "${cost:--}" \
    "$(($(date +%s) - start))" "$status" >"$dest/result.tsv"
  [ "$status" -eq 0 ]
}

if [ "${1:-}" = --trial ]; then
  shift
  trial "$@"
  exit
fi

if [ "${1:-}" = --show ]; then
  [ $# -eq 2 ] || [ $# -eq 3 ] || usage
  if [ $# -eq 2 ]; then
    cat "$2/results.tsv"
  else
    [ -d "$2/$3" ] || {
      echo "try-content: no trial $3 in $2" >&2
      exit 2
    }
    printf '== what Claude looked at\n'
    cat "$2/$3/looked.txt"
    printf '== check\n'
    cat "$2/$3/check.txt"
    printf '== diff\n'
    cat "$2/$3/diff.patch"
  fi
  exit
fi

runs=3
jobs=
TRY_MODEL=
TRY_NO_HOOKS=0
while [ $# -gt 0 ]; do
  case $1 in
    -n)
      runs=${2:-}
      shift 2 || usage
      ;;
    -j)
      jobs=${2:-}
      shift 2 || usage
      ;;
    -m)
      TRY_MODEL=${2:-}
      shift 2 || usage
      ;;
    --no-hooks)
      TRY_NO_HOOKS=1
      shift
      ;;
    -*) usage ;;
    *) break ;;
  esac
done
[ $# -eq 2 ] || usage
case $runs in *[!0-9]* | '') usage ;; esac
[ "$runs" -ge 1 ] || usage
jobs=${jobs:-$((runs * 2))}
case $jobs in *[!0-9]* | '') usage ;; esac
[ "$jobs" -ge 1 ] || usage

spec=$(cd "$1" 2>/dev/null && pwd) || {
  echo "try-content: no such spec directory: $1" >&2
  exit 2
}
[ -f "$spec/prompt.txt" ] || {
  echo "try-content: $spec has no prompt.txt" >&2
  exit 2
}
[ -f "$spec/check.sh" ] || {
  echo "try-content: $spec has no check.sh" >&2
  exit 2
}
if [ ! -f "$spec/add.txt" ] && [ ! -f "$spec/remove.txt" ] && [ ! -f "$spec/without.txt" ]; then
  echo "try-content: $spec needs add.txt, remove.txt or without.txt" >&2
  exit 2
fi
while read -r file path; do
  if [ -z "$path" ] || [ ! -f "$spec/$file" ]; then
    echo "try-content: each add.txt line is '<file in the spec> <repository path>', naming a file that exists:" \
      "$file $path" >&2
    exit 2
  fi
done < <(placements "$spec/add.txt" && placements "$spec/without.txt")
TRY_REPO=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo 'try-content: not in a git repository' >&2
  exit 2
}
TRY_HEAD=$(git -C "$TRY_REPO" rev-parse HEAD)
command -v claude >/dev/null || {
  echo 'try-content: claude is not on PATH' >&2
  exit 2
}
mkdir -p "$2"
out=$(cd "$2" && pwd)
case $out in *"'"* | *'"'*)
  echo "try-content: the out-dir path must not hold a quote: $out" >&2
  exit 2
  ;;
esac
export TRY_REPO TRY_HEAD TRY_MODEL TRY_NO_HOOKS

status=0
for arm in with without; do
  i=1
  while [ "$i" -le "$runs" ]; do
    printf '%s\0%s\0%s\0%s\0' "$spec" "$out" "$arm" "$i"
    i=$((i + 1))
  done
done | xargs -0 -n 4 -P "$jobs" bash "$0" --trial || status=1

printf 'arm\trun\tcheck\tloaded\tskill_calls\tcost_usd\tseconds\tclaude_exit\n' >"$out/results.tsv"
for arm in with without; do
  i=1
  while [ "$i" -le "$runs" ]; do
    if [ -f "$out/$arm-$i/result.tsv" ]; then cat "$out/$arm-$i/result.tsv" >>"$out/results.tsv"; else status=1; fi
    i=$((i + 1))
  done
done

has_skills=0
has_instructions=0
if watched_paths "$spec" | grep -q '\.claude/skills/'; then has_skills=1; fi
if watched_paths "$spec" | grep -qv '\.claude/skills/'; then has_instructions=1; fi
for arm in with without; do
  awk -F '\t' -v arm="$arm" -v skills="$has_skills" -v instructions="$has_instructions" '
    NR > 1 && $1 == arm {
      n++; if ($3 == "pass") pass++
      if ($4 != "no") loaded++
      if ($5 > 0) skill++
    }
    END {
      printf "%s: check passed %d/%d", arm, pass, n
      if (instructions) printf "; instructions loaded %d/%d", loaded, n
      if (skills) printf "; skill invoked %d/%d", skill, n
      printf "\n"
    }' "$out/results.tsv"
done
echo 'Trials:'
for arm in with without; do
  i=1
  while [ "$i" -le "$runs" ]; do
    d="$out/$arm-$i"
    if [ -f "$d/result.tsv" ]; then
      printf '%s-%s %s | %s | looked at: %s\n' "$arm" "$i" "$(cut -f3 "$d/result.tsv")" \
        "$(tail -1 "$d/check.txt" 2>/dev/null)" "$(cut -c1-80 "$d/looked.txt" | paste -sd ';' - | sed 's/;/; /g')"
    fi
    i=$((i + 1))
  done
done
echo "Results: $out/results.tsv"
exit "$status"

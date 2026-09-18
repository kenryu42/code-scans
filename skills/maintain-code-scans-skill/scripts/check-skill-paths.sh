#!/usr/bin/env bash
# Verify that every repo path a Markdown file names in backticks still exists.
#
# Usage: check-skill-paths.sh <SKILL.md> [repo-root]
#
# Repo root defaults to the git toplevel of the Markdown file's location.
# A backtick span counts as a path when it has no spaces and either contains
# a slash or looks like a top-level file (AGENTS.md, package.json). Spans that
# start with "-", "origin/" or "refs/", or contain "<", "{", "(", ":" or
# "http" are flags, git refs, placeholders, calls, file:line refs, or URLs and
# are skipped. Globs (`src/**/*.ts`,
# `packages/*/src`) are matched as git pathspecs.
#
# Output: one line per distinct path, prefixed with "ok", "untracked" (exists on
# disk but not in git, e.g. generated output), or "MISSING". Exit 1 when any
# path is missing.
set -euo pipefail

file=${1:?usage: check-skill-paths.sh <SKILL.md> [repo-root]}
if [ -n "${2:-}" ]; then
  root=$2
else
  root=$(git -C "$(dirname "$file")" rev-parse --show-toplevel)
fi
file=$(cd "$(dirname "$file")" && pwd)/$(basename "$file")
cd "$root"

missing=0
while IFS= read -r span; do
  p=${span#\`}
  p=${p%\`}
  p=${p%%[,;:.]}   # trailing punctuation inside the backticks
  p=${p%/}
  case "$p" in
    ''|*' '*|-*|*'<'*|*'('*|*'{'*|*':'*|http*|origin/*|refs/*|.|..) continue ;;
  esac
  if [[ "$p" != */* && "$p" != *.* ]]; then continue; fi
  if [[ "$p" == *.* && "$p" != */* && ! "$p" =~ ^[A-Za-z0-9_.-]+\.[A-Za-z0-9]+$ ]]; then continue; fi
  if [[ "$p" == *'*'* ]]; then
    if [ -n "$(git ls-files -- ":(glob)$p" ":(glob)$p/**" | head -1)" ]; then
      echo "ok         $p"
    else
      echo "MISSING    $p"; missing=$((missing + 1))
    fi
  elif [ -n "$(git ls-files -- "$p" | head -1)" ]; then
    echo "ok         $p"
  elif [ -e "$p" ]; then
    echo "untracked  $p"
  else
    echo "MISSING    $p"; missing=$((missing + 1))
  fi
done < <(grep -o '`[^`]*`' "$file" | sort -u)

if [ "$missing" -gt 0 ]; then
  echo "$missing missing path(s) in $file" >&2
  exit 1
fi

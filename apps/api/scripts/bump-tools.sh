#!/usr/bin/env bash
# Interactively bump pinned Go tool versions in the Makefile `install:` target.
# Parses each `go install <path>@vX.Y.Z` line, queries the latest version for
# the corresponding module, and prompts the user to update in place.

set -euo pipefail

MAKEFILE="${1:-Makefile}"

if [ ! -f "$MAKEFILE" ]; then
  echo "Error: $MAKEFILE not found" >&2
  exit 1
fi

echo "Checking pinned Go tools in $MAKEFILE..."
echo

# Pre-extract install lines to a tempfile so the read prompt doesn't fight
# with a pipeline subshell. Uses a while loop (portable to bash 3.2 on macOS).
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
grep -E '^[[:space:]]*go install .*@v[0-9]' "$MAKEFILE" > "$TMP" || true

if [ ! -s "$TMP" ]; then
  echo "No pinned 'go install ...@vX.Y.Z' lines found."
  exit 0
fi

bumped=0
while IFS= read -r line; do
  full_pkg=$(echo "$line" | sed -nE "s|.*go install (-tags '?[^ ']+'? )?([^ ]+)@(v[0-9][^ ']*).*|\2|p")
  current=$(echo "$line" | sed -nE "s|.*go install (-tags '?[^ ']+'? )?([^ ]+)@(v[0-9][^ ']*).*|\3|p")

  if [ -z "$full_pkg" ] || [ -z "$current" ]; then
    echo "  ! could not parse: $line"
    continue
  fi

  module=$(echo "$full_pkg" | sed -E 's|/cmd/[^/]+$||')
  latest=$(go list -m -versions "$module" 2>/dev/null | awk '{print $NF}')

  if [ -z "$latest" ] || [ "$latest" = "$module" ]; then
    printf "  ? %-60s could not query versions\n" "$module"
    continue
  fi

  if [ "$current" = "$latest" ]; then
    printf "  = %-60s %s\n" "$module" "$current"
    continue
  fi

  printf "\n  > %s\n    %s -> %s\n" "$module" "$current" "$latest"
  printf "    bump? [y/N] "
  read -r ans </dev/tty || ans=""
  if [ "$ans" = "y" ] || [ "$ans" = "Y" ]; then
    # Replace exact "<full_pkg>@<current>" occurrence in Makefile.
    # sed delimiter is `|`, so / does not need escaping. Escape `.` (regex
    # meta) in the search and `&` (back-reference) in the replacement; in
    # both, escape `|` itself in case a future module path contains one.
    esc=$(printf '%s' "${full_pkg}@${current}" | sed 's|[.|]|\\&|g')
    repl=$(printf '%s' "${full_pkg}@${latest}" | sed 's|[&|]|\\&|g')
    sed -i.bak -E "s|${esc}|${repl}|" "$MAKEFILE"
    rm -f "${MAKEFILE}.bak"
    bumped=$((bumped + 1))
    echo "    updated"
  fi
done < "$TMP"

echo
if [ "$bumped" -gt 0 ]; then
  echo "Bumped $bumped tool(s). Run 'make install' to apply."
else
  echo "No changes made."
fi

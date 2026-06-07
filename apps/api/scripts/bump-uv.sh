#!/usr/bin/env bash
# Interactively bump outdated Python dependencies in the LLM service via uv.
# Lists outdated packages, then prompts for which to upgrade.

set -euo pipefail

LLM_DIR="${1:-llm}"

if [ ! -f "$LLM_DIR/pyproject.toml" ]; then
  echo "Error: $LLM_DIR/pyproject.toml not found" >&2
  exit 1
fi

cd "$LLM_DIR"

echo "Outdated Python packages in $LLM_DIR:"
echo
uv pip list --outdated || true
echo

printf "Package(s) to upgrade (space-separated; 'all' to upgrade everything; blank to skip): "
read -r pkgs </dev/tty || pkgs=""

if [ -z "$pkgs" ]; then
  echo "Skipped."
  exit 0
fi

if [ "$pkgs" = "all" ]; then
  uv lock --upgrade
else
  for p in $pkgs; do
    uv lock --upgrade-package "$p"
  done
fi

uv sync
echo "Done."

#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/agent-worktree.sh setup [--skip-install] [--skip-generate] [--no-env]
  scripts/agent-worktree.sh create <codex|claude|shared> <branch-name> [from-branch] [setup flags]

Examples:
  bash scripts/agent-worktree.sh setup
  bash scripts/agent-worktree.sh create codex feat/example
  bash scripts/agent-worktree.sh create claude review/pr-123 main --skip-install

The setup command is intended to run inside any Codex, Claude Code, or plain
git worktree. It copies local .env files from the primary checkout, initializes
submodules, installs dependencies, and regenerates generated code.
EOF
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

repo_root() {
  git rev-parse --show-toplevel
}

primary_worktree_root() {
  git worktree list --porcelain | sed -n 's/^worktree //p' | head -n 1
}

default_branch() {
  local head_ref
  head_ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)
  if [[ -n "$head_ref" ]]; then
    printf '%s\n' "${head_ref#refs/remotes/origin/}"
  else
    printf '%s\n' "main"
  fi
}

copy_env_files() {
  local source_root="$1"
  local target_root="$2"
  local copied=0
  local kept=0

  if [[ -z "$source_root" || ! -d "$source_root" ]]; then
    printf 'Environment files: source checkout "%s" is empty or missing; skipping copy\n' "$source_root" >&2
    return
  fi

  if [[ "$source_root" == "$target_root" ]]; then
    printf 'Environment files: primary checkout; no copy needed\n'
    return
  fi

  printf 'Environment files:\n'

  shopt -s nullglob
  for source in "$source_root"/.env*; do
    [[ -f "$source" ]] || continue

    local name
    name=$(basename "$source")
    case "$name" in
      .envrc|*.example|*.backup|*.bak)
        continue
        ;;
    esac

    local dest="$target_root/$name"
    if [[ -e "$dest" ]]; then
      printf '  Kept existing %s\n' "$name"
      kept=$((kept + 1))
      continue
    fi

    cp "$source" "$dest"
    printf '  Copied %s\n' "$name"
    copied=$((copied + 1))
  done
  shopt -u nullglob

  if [[ $copied -eq 0 && $kept -eq 0 ]]; then
    printf '  No local .env files found in %s\n' "$source_root"
  fi
}

run_step() {
  printf '\n==> %s\n' "$*"
  "$@"
}

setup_worktree() {
  local skip_install=false
  local skip_generate=false
  local copy_env=true

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-install)
        skip_install=true
        ;;
      --skip-generate)
        skip_generate=true
        ;;
      --no-env)
        copy_env=false
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        fail "unknown setup flag: $1"
        ;;
    esac
    shift
  done

  local target_root
  target_root=$(repo_root)

  local source_root
  source_root="${AGENT_WORKTREE_SOURCE:-$(primary_worktree_root)}"

  printf 'Setting up agent worktree: %s\n' "$target_root"

  if [[ "$copy_env" == true ]]; then
    copy_env_files "$source_root" "$target_root"
  fi

  run_step git submodule update --init --recursive

  if [[ "$skip_install" == false ]]; then
    if [[ -f package-lock.json ]]; then
      if command -v npm >/dev/null 2>&1; then
        run_step npm ci
      else
        printf 'warning: package-lock.json found but npm is not installed; skipping npm ci\n' >&2
      fi
    fi
    run_step make install-all
  fi

  if [[ "$skip_generate" == false ]]; then
    run_step make regenerate-all
  fi
}

create_worktree() {
  local tool="${1:-}"
  local branch_name="${2:-}"
  shift 2 2>/dev/null || true

  [[ -n "$tool" ]] || fail "worktree tool is required"
  [[ -n "$branch_name" ]] || fail "branch name is required"

  if ! git check-ref-format --branch "$branch_name" >/dev/null 2>&1; then
    fail "invalid branch name: $branch_name"
  fi

  local from_branch=""
  local setup_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --skip-install|--skip-generate|--no-env)
        setup_args+=("$1")
        ;;
      -h|--help)
        usage
        return 0
        ;;
      -*)
        fail "unknown create flag: $1"
        ;;
      *)
        if [[ -n "$from_branch" ]]; then
          fail "only one from-branch is supported"
        fi
        from_branch="$1"
        ;;
    esac
    shift
  done

  local root
  root=$(primary_worktree_root)
  if [[ -z "$root" || ! -d "$root" ]]; then
    fail "could not determine primary worktree root"
  fi

  local parent_dir
  case "$tool" in
    codex)
      parent_dir="$root/.codex/worktrees"
      ;;
    claude)
      parent_dir="$root/.claude/worktrees"
      ;;
    shared)
      parent_dir="$root/.worktrees"
      ;;
    *)
      fail "tool must be one of: codex, claude, shared"
      ;;
  esac

  from_branch="${from_branch:-$(default_branch)}"

  local fetch_branch="$from_branch"
  local base_ref="origin/$from_branch"
  if [[ "$from_branch" == origin/* ]]; then
    fetch_branch="${from_branch#origin/}"
    base_ref="$from_branch"
  fi

  local worktree_path="$parent_dir/$branch_name"
  if [[ -e "$worktree_path" ]]; then
    fail "worktree already exists at $worktree_path"
  fi

  mkdir -p "$(dirname "$worktree_path")"

  printf 'Creating %s worktree %s from %s\n' "$tool" "$branch_name" "$from_branch"

  if ! git fetch origin "$fetch_branch" --quiet; then
    printf 'warning: could not fetch origin/%s; using local ref if available\n' "$fetch_branch" >&2
  fi

  if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    base_ref="$from_branch"
  fi

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git worktree add "$worktree_path" "$branch_name"
  else
    git worktree add -b "$branch_name" "$worktree_path" "$base_ref"
  fi

  (
    cd "$worktree_path"
    AGENT_WORKTREE_SOURCE="$root" bash "$root/scripts/agent-worktree.sh" setup "${setup_args[@]}"
  )

  printf '\nWorktree ready: %s\n' "$worktree_path"
}

main() {
  local command="${1:-setup}"
  shift || true

  case "$command" in
    setup)
      setup_worktree "$@"
      ;;
    create)
      create_worktree "$@"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      fail "unknown command: $command"
      ;;
  esac
}

main "$@"

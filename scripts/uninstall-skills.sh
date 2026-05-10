#!/usr/bin/env bash
set -euo pipefail

CLAUDE_TARGET="$HOME/.claude/skills"
VSCODE_PROMPTS_TARGET="$HOME/Library/Application Support/Code/User/prompts/my-dev-skills"

usage() {
  cat <<'EOF'
Uninstall globally linked/copied shared skills.

Usage:
  scripts/uninstall-skills.sh [--with-vscode-prompts] [--force]

Options:
  --with-vscode-prompts  Also remove VS Code prompts mirror path.
  --force                Remove without confirmation.
  -h, --help             Show help.
EOF
}

WITH_VSCODE_PROMPTS="false"
FORCE_MODE="false"

confirm_remove() {
  local target="$1"
  if [[ "$FORCE_MODE" == "true" ]]; then
    return 0
  fi
  printf "Remove %s ? [y/N]: " "$target"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

remove_one() {
  local target="$1"
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    echo "Skip (not found): $target"
    return 0
  fi
  if confirm_remove "$target"; then
    rm -rf "$target"
    echo "Removed: $target"
  else
    echo "Skip: $target"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-vscode-prompts)
      WITH_VSCODE_PROMPTS="true"
      shift
      ;;
    --force)
      FORCE_MODE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

remove_one "$CLAUDE_TARGET"

if [[ "$WITH_VSCODE_PROMPTS" == "true" ]]; then
  remove_one "$VSCODE_PROMPTS_TARGET"
fi

echo "Done."

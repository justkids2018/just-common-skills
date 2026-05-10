#!/usr/bin/env bash
set -euo pipefail

# Install shared skills for local Copilot/Claude runtimes by linking this repo's
# skills directory into standard global paths.
#
# Default behavior:
# - Link to: ~/.claude/skills
# Optional:
# - --with-vscode-prompts: also link to VS Code prompts mirror directory
# - --copy: copy files instead of symlink
# - --force: replace existing target without interactive prompt

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SKILLS="$HUB_ROOT/skills"

CLAUDE_TARGET="$HOME/.claude/skills"
VSCODE_PROMPTS_BASE_DEFAULT="$HOME/Library/Application Support/Code/User/prompts"
VSCODE_PROMPTS_TARGET="$VSCODE_PROMPTS_BASE_DEFAULT/my-dev-skills"

WITH_VSCODE_PROMPTS="false"
COPY_MODE="false"
FORCE_MODE="false"

usage() {
  cat <<'EOF'
Install shared skills from this repository.

Usage:
  scripts/install-skills.sh [options]

Options:
  --with-vscode-prompts  Also install to VS Code prompts mirror path.
  --copy                 Copy files instead of creating symlink.
  --force                Replace existing targets without confirmation.
  -h, --help             Show this help.

Installed targets:
  1) ~/.claude/skills
  2) ~/Library/Application Support/Code/User/prompts/my-dev-skills (optional)

Notes:
  - Symlink mode keeps skills always up to date with this repo.
  - Copy mode creates a snapshot and does not auto-sync.
EOF
}

confirm_replace() {
  local target="$1"
  if [[ "$FORCE_MODE" == "true" ]]; then
    return 0
  fi
  printf "Target exists: %s\nReplace it? [y/N]: " "$target"
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

install_one() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -e "$target" || -L "$target" ]]; then
    if ! confirm_replace "$target"; then
      echo "Skip: $target"
      return 0
    fi
    rm -rf "$target"
  fi

  if [[ "$COPY_MODE" == "true" ]]; then
    mkdir -p "$target"
    cp -R "$source"/. "$target"/
    echo "Copied: $source -> $target"
  else
    ln -s "$source" "$target"
    echo "Linked: $target -> $source"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-vscode-prompts)
      WITH_VSCODE_PROMPTS="true"
      shift
      ;;
    --copy)
      COPY_MODE="true"
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

if [[ ! -d "$SOURCE_SKILLS" ]]; then
  echo "Source skills directory not found: $SOURCE_SKILLS" >&2
  exit 2
fi

install_one "$SOURCE_SKILLS" "$CLAUDE_TARGET"

if [[ "$WITH_VSCODE_PROMPTS" == "true" ]]; then
  install_one "$SOURCE_SKILLS" "$VSCODE_PROMPTS_TARGET"
fi

echo "Done."

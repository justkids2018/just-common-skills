#!/usr/bin/env bash
set -euo pipefail

CLAUDE_TARGET="$HOME/.claude/skills"
VSCODE_PROMPTS_BASE_DEFAULT="${VSCODE_PROMPTS_BASE:-$HOME/Library/Application Support/Code/User/prompts}"
VSCODE_PROMPTS_NAME="${VSCODE_PROMPTS_NAME:-just-common-skills}"
VSCODE_PROMPTS_TARGET="${VSCODE_PROMPTS_TARGET:-$VSCODE_PROMPTS_BASE_DEFAULT/$VSCODE_PROMPTS_NAME}"

usage() {
  cat <<'EOF'
Uninstall globally linked/copied shared skills.

Usage:
  scripts/uninstall-skills.sh [options]

Options:
  --with-vscode-prompts  Also remove VS Code prompts mirror path.
  --force                Remove without confirmation.
  -h, --help             Show help.

Environment overrides:
  VSCODE_PROMPTS_BASE    Base prompts directory (default: ~/Library/Application Support/Code/User/prompts)
  VSCODE_PROMPTS_NAME    Subdirectory name under base (default: just-common-skills)
  VSCODE_PROMPTS_TARGET  Full target path. If set, overrides BASE/NAME composition.

Examples:
  # Uninstall from Claude Code
  ./scripts/uninstall-skills.sh

  # Uninstall from both Claude Code and VS Code
  ./scripts/uninstall-skills.sh --with-vscode-prompts

  # Force uninstall without confirmation
  ./scripts/uninstall-skills.sh --force
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
    echo "⏭️  Skip (not found): $target"
    return 0
  fi

  # Show what will be removed
  if [[ -L "$target" ]]; then
    local link_target
    link_target="$(readlink "$target")"
    echo "Found symlink: $target -> $link_target"
  else
    echo "Found directory: $target"
  fi

  if confirm_remove "$target"; then
    rm -rf "$target"
    echo "🗑️  Removed: $target"
  else
    echo "⏭️  Skip: $target"
  fi
}

# Parse arguments
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
      echo "❌ Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

echo "🗑️  Just-Common-Skills Uninstaller"
echo "=================================="
echo ""

# Uninstall from Claude Code
echo "Uninstalling from Claude Code..."
remove_one "$CLAUDE_TARGET"

# Uninstall from VS Code (optional)
if [[ "$WITH_VSCODE_PROMPTS" == "true" ]]; then
  echo ""
  echo "Uninstalling from VS Code prompts..."
  remove_one "$VSCODE_PROMPTS_TARGET"
fi

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Note: This only removes global installations."
echo "To remove project-specific injections, delete the symlinks manually:"
echo "  rm -rf <project>/.github/skills"
echo "  rm -rf <project>/.claude/skills"
echo "  rm -rf <project>/.ai/common-prompt"
echo "  rm -rf <project>/.ai/system-platform"

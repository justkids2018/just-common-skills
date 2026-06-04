#!/usr/bin/env bash
set -euo pipefail

# Global target directories for all AI assistants
CLAUDE_TARGET="$HOME/.claude/skills"
COPILOT_TARGET="$HOME/.github/skills"
CODEX_TARGET="$HOME/.codex/skills"
CURSOR_TARGET="$HOME/.cursor/skills"
GEMINI_TARGET="$HOME/.gemini/skills"

usage() {
  cat <<'EOF'
Uninstall globally linked shared skills from all AI programming assistants.

Usage:
  scripts/uninstall-skills.sh [options]

Options:
  --force                Remove without confirmation.
  -h, --help             Show help.

Uninstalled targets (all by default):
  1) ~/.claude/skills    (Claude Code)
  2) ~/.github/skills    (GitHub Copilot)
  3) ~/.codex/skills     (Codex)
  4) ~/.cursor/skills    (Cursor / OpenAI)
  5) ~/.gemini/skills    (Google Gemini)

Examples:
  # Uninstall from all AI assistants
  ./scripts/uninstall-skills.sh

  # Force uninstall without confirmation
  ./scripts/uninstall-skills.sh --force
EOF
}

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
  local name="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    echo "⏭️  $name: not found, skipping"
    return 0
  fi

  # Show what will be removed
  if [[ -L "$target" ]]; then
    local link_target
    link_target="$(readlink "$target")"
    echo "Found $name symlink: $target -> $link_target"
  else
    echo "Found $name directory: $target"
  fi

  if confirm_remove "$target"; then
    rm -rf "$target"
    echo "🗑️  $name: removed"
  else
    echo "⏭️  $name: skipped"
  fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
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

echo "🗑️  Just-Common-Skills Global Uninstaller"
echo "=========================================="
echo ""

echo "Uninstalling from all AI assistants..."
echo ""

remove_one "$CLAUDE_TARGET" "Claude Code"
remove_one "$COPILOT_TARGET" "GitHub Copilot"
remove_one "$CODEX_TARGET" "Codex"
remove_one "$CURSOR_TARGET" "Cursor"
remove_one "$GEMINI_TARGET" "Google Gemini"

echo ""
echo "✅ Uninstall complete!"

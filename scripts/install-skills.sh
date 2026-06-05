#!/usr/bin/env bash
set -euo pipefail

# Install shared skills globally to all AI programming assistants
# Supports: Claude Code, GitHub Copilot, Codex
# Default: symlink mode for auto-update

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SKILLS="$HUB_ROOT/skills"

# Global target directories for all AI assistants
CLAUDE_TARGET="$HOME/.claude/skills"
COPILOT_TARGET="$HOME/.github/skills"
CODEX_TARGET="$HOME/.codex/skills"
CURSOR_TARGET="$HOME/.cursor/skills"
GEMINI_TARGET="$HOME/.gemini/skills"

FORCE_MODE="false"

usage() {
  cat <<'EOF'
Install shared skills globally to all AI programming assistants.

Usage:
  scripts/install-skills.sh [options]

Options:
  --force                Replace existing targets without confirmation.
  -h, --help             Show this help.

Installed targets (all by default):
  1) ~/.claude/skills    (Claude Code)
  2) ~/.github/skills    (GitHub Copilot)
  3) ~/.codex/skills     (Codex)
  4) ~/.cursor/skills    (Cursor / OpenAI)
  5) ~/.gemini/skills    (Google Gemini)

Notes:
  - Uses symlink mode to keep skills always up to date with this repo.
  - Automatically creates target directories if they don't exist.
  - Recommended for centralized skill management across all AI assistants.

Examples:
  # Install to all AI assistants (default)
  ./scripts/install-skills.sh

  # Force replace existing installation
  ./scripts/install-skills.sh --force
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
  local name="$3"

  # Force create parent directory
  mkdir -p "$(dirname "$target")"

  if [[ -e "$target" || -L "$target" ]]; then
    if ! confirm_replace "$target"; then
      echo "⏭️  Skip: $name ($target)"
      return 0
    fi
    rm -rf "$target"
  fi

  # Always use symlink mode
  ln -s "$source" "$target"
  echo "🔗 $name: $target -> $source"
}

verify_installation() {
  local target="$1"
  local name="$2"

  if [[ ! -e "$target" ]]; then
    echo "❌ $name: target does not exist"
    return 1
  fi

  if [[ ! -L "$target" ]]; then
    echo "❌ $name: not a symlink"
    return 1
  fi

  local link_target
  link_target="$(readlink "$target")"
  if [[ "$link_target" != "$SOURCE_SKILLS" ]]; then
    echo "❌ $name: points to wrong location"
    return 1
  fi

  local skill_count
  skill_count=$(find "$target/just-"* -maxdepth 0 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$skill_count" -eq 0 ]]; then
    echo "❌ $name: no skills found"
    return 1
  fi

  echo "✅ $name: verified ($skill_count skills)"
  return 0
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

# Validate source
if [[ ! -d "$SOURCE_SKILLS" ]]; then
  echo "❌ Source skills directory not found: $SOURCE_SKILLS" >&2
  exit 2
fi

# Count skills
SKILL_COUNT=$(find "$SOURCE_SKILLS/just-"* -maxdepth 0 -type d 2>/dev/null | wc -l | tr -d ' ')
if [[ "$SKILL_COUNT" -eq 0 ]]; then
  echo "❌ No skills found in $SOURCE_SKILLS" >&2
  exit 3
fi

echo "📦 Just-Common-Skills Global Installer"
echo "======================================="
echo "Source: $HUB_ROOT"
echo "Skills: $SKILL_COUNT"
echo "Mode:   symlink (auto-update)"
echo ""

# Install to all AI assistants
echo "Installing to all AI assistants..."
echo ""

install_one "$SOURCE_SKILLS" "$CLAUDE_TARGET" "Claude Code"
install_one "$SOURCE_SKILLS" "$COPILOT_TARGET" "GitHub Copilot"
install_one "$SOURCE_SKILLS" "$CODEX_TARGET" "Codex"
install_one "$SOURCE_SKILLS" "$CURSOR_TARGET" "Cursor"
install_one "$SOURCE_SKILLS" "$GEMINI_TARGET" "Google Gemini"

# Verify installations
echo ""
echo "Verifying installations..."
verify_installation "$CLAUDE_TARGET" "Claude Code"
verify_installation "$COPILOT_TARGET" "GitHub Copilot"
verify_installation "$CODEX_TARGET" "Codex"
verify_installation "$CURSOR_TARGET" "Cursor"
verify_installation "$GEMINI_TARGET" "Google Gemini"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Installed to:"
echo "  • Claude Code: ~/.claude/skills"
echo "  • GitHub Copilot: ~/.github/skills"
echo "  • Codex: ~/.codex/skills"
echo "  • Cursor: ~/.cursor/skills"
echo "  • Google Gemini: ~/.gemini/skills"
echo ""
echo "Next steps:"
echo "  1. Restart your AI assistant"
echo "  2. Type /just-dev-pipeline to start using skills"
echo ""
echo "To update: run this script again"
echo "To uninstall: ./scripts/uninstall-skills.sh --force"

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
VSCODE_PROMPTS_BASE_DEFAULT="${VSCODE_PROMPTS_BASE:-$HOME/Library/Application Support/Code/User/prompts}"
VSCODE_PROMPTS_NAME="${VSCODE_PROMPTS_NAME:-just-common-skills}"
VSCODE_PROMPTS_TARGET="${VSCODE_PROMPTS_TARGET:-$VSCODE_PROMPTS_BASE_DEFAULT/$VSCODE_PROMPTS_NAME}"

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
  --copy                 Copy files instead of creating symlink (not recommended).
  --force                Replace existing targets without confirmation.
  -h, --help             Show this help.

Environment overrides:
  VSCODE_PROMPTS_BASE    Base prompts directory (default: ~/Library/Application Support/Code/User/prompts)
  VSCODE_PROMPTS_NAME    Subdirectory name under base (default: just-common-skills)
  VSCODE_PROMPTS_TARGET  Full target path. If set, overrides BASE/NAME composition.

Installed targets:
  1) ~/.claude/skills
  2) $VSCODE_PROMPTS_TARGET (optional)

Notes:
  - Symlink mode (default) keeps skills always up to date with this repo.
  - Copy mode creates a snapshot and does not auto-sync.
  - Recommended: use symlink mode for automatic updates.

Examples:
  # Install to Claude Code (symlink mode)
  ./scripts/install-skills.sh

  # Install to both Claude Code and VS Code
  ./scripts/install-skills.sh --with-vscode-prompts

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

  mkdir -p "$(dirname "$target")"

  if [[ -e "$target" || -L "$target" ]]; then
    if ! confirm_replace "$target"; then
      echo "⏭️  Skip: $target"
      return 0
    fi
    rm -rf "$target"
  fi

  if [[ "$COPY_MODE" == "true" ]]; then
    mkdir -p "$target"
    cp -R "$source"/. "$target"/
    echo "📦 Copied: $source -> $target"
  else
    ln -s "$source" "$target"
    echo "🔗 Linked: $target -> $source"
  fi
}

verify_installation() {
  local target="$1"
  local mode="$2"

  if [[ ! -e "$target" ]]; then
    echo "❌ Verification failed: $target does not exist"
    return 1
  fi

  if [[ "$mode" == "symlink" ]]; then
    if [[ ! -L "$target" ]]; then
      echo "❌ Verification failed: $target is not a symlink"
      return 1
    fi
    local link_target
    link_target="$(readlink "$target")"
    if [[ "$link_target" != "$SOURCE_SKILLS" ]]; then
      echo "❌ Verification failed: $target points to wrong location"
      return 1
    fi
  fi

  local skill_count
  skill_count=$(find "$target/just-"* -maxdepth 0 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$skill_count" -eq 0 ]]; then
    echo "❌ Verification failed: no skills found in $target"
    return 1
  fi

  echo "✅ Verified: $target ($skill_count skills)"
  return 0
}

# Parse arguments
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

echo "📦 Just-Common-Skills Installer"
echo "================================"
echo "Source: $HUB_ROOT"
echo "Skills: $SKILL_COUNT"
echo "Mode:   $([ "$COPY_MODE" == "true" ] && echo "copy (snapshot)" || echo "symlink (auto-update)")"
echo ""

# Install to Claude Code
echo "Installing to Claude Code..."
install_one "$SOURCE_SKILLS" "$CLAUDE_TARGET"

# Install to VS Code (optional)
if [[ "$WITH_VSCODE_PROMPTS" == "true" ]]; then
  echo ""
  echo "Installing to VS Code prompts..."
  install_one "$SOURCE_SKILLS" "$VSCODE_PROMPTS_TARGET"
fi

# Verify installations
echo ""
echo "Verifying installations..."
VERIFY_MODE=$([ "$COPY_MODE" == "true" ] && echo "copy" || echo "symlink")
verify_installation "$CLAUDE_TARGET" "$VERIFY_MODE"

if [[ "$WITH_VSCODE_PROMPTS" == "true" ]]; then
  verify_installation "$VSCODE_PROMPTS_TARGET" "$VERIFY_MODE"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart Claude Code or VS Code"
echo "  2. Type /just-dev-pipeline to start using skills"
echo "  3. Run 'make test' to verify the installation"
echo ""
echo "To uninstall, run: ./scripts/uninstall-skills.sh"

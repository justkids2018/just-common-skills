#!/usr/bin/env bash
set -euo pipefail

# Unified injector for both new and existing projects.
# - Missing governance files are created.
# - Existing governance files keep original content and receive/update a managed block.
# - Shared directories are always wired via symlink (soft reference).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC_AGENTS="$HUB_ROOT/AGENTS.md"
SRC_CLAUDE="$HUB_ROOT/CLAUDE.md"
SRC_COPILOT="$HUB_ROOT/.github/copilot-instructions.md"
SRC_SKILLS="$HUB_ROOT/skills"
SRC_COMMON_PROMPT="$HUB_ROOT/common-prompt"

BEGIN_MARK="# BEGIN JUST-COMMON-SKILLS MANAGED BLOCK"
END_MARK="# END JUST-COMMON-SKILLS MANAGED BLOCK"

usage() {
  cat <<'EOF'
Inject/merge shared skills and governance into a project (symlink mode only).

Usage:
  scripts/inject-current-project.sh [target-project-path]

Examples:
  # Run inside target project (defaults to current directory)
  bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh

  # Explicit target path
  bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh /absolute/path/to/my-new-project

Notes:
  - Always symlink (soft reference), never copy.
  - Existing AGENTS.md / CLAUDE.md / .github/copilot-instructions.md are merged,
    not fully overwritten.
  - Missing files are created automatically.

Compatibility:
  - '--force' is accepted as a no-op for old command habits.
EOF
}

merge_text_file() {
  local source_file="$1"
  local target_file="$2"

  mkdir -p "$(dirname "$target_file")"

  if [[ ! -f "$target_file" ]]; then
    cp "$source_file" "$target_file"
    echo "Created: $target_file"
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if rg -n "^${BEGIN_MARK}$|^${END_MARK}$" "$target_file" >/dev/null 2>&1; then
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" -v src="$source_file" '
      BEGIN {
        in_block = 0
        while ((getline line < src) > 0) {
          block = block line "\n"
        }
        close(src)
      }
      $0 == begin {
        print begin
        printf "%s", block
        in_block = 1
        next
      }
      $0 == end {
        print end
        in_block = 0
        next
      }
      in_block == 0 {
        print $0
      }
    ' "$target_file" > "$tmp_file"
    mv "$tmp_file" "$target_file"
    echo "Updated managed block: $target_file"
  else
    {
      cat "$target_file"
      printf "\n\n%s\n" "$BEGIN_MARK"
      cat "$source_file"
      printf "\n%s\n" "$END_MARK"
    } > "$tmp_file"
    mv "$tmp_file" "$target_file"
    echo "Merged by append: $target_file"
  fi
}

link_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf "$target"
  fi
  ln -s "$source" "$target"
  echo "Linked: $target -> $source"
}

TARGET_PROJECT="$PWD"
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --force)
      # Compatibility no-op: this script is non-interactive by design.
      shift
      ;;
    -* )
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#ARGS[@]} -gt 1 ]]; then
  echo "Too many positional arguments." >&2
  usage >&2
  exit 1
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  TARGET_PROJECT="${ARGS[0]}"
fi

ABS_TARGET="$(cd "$TARGET_PROJECT" && pwd)"

if [[ ! -d "$ABS_TARGET" ]]; then
  echo "Target project not found: $TARGET_PROJECT" >&2
  exit 2
fi

if [[ ! -f "$SRC_AGENTS" || ! -f "$SRC_CLAUDE" || ! -f "$SRC_COPILOT" ]]; then
  echo "Hub source files are incomplete under: $HUB_ROOT" >&2
  exit 3
fi

if [[ ! -d "$SRC_SKILLS" || ! -d "$SRC_COMMON_PROMPT" ]]; then
  echo "Hub source directories are incomplete under: $HUB_ROOT" >&2
  exit 4
fi

merge_text_file "$SRC_AGENTS" "$ABS_TARGET/AGENTS.md"
merge_text_file "$SRC_CLAUDE" "$ABS_TARGET/CLAUDE.md"
merge_text_file "$SRC_COPILOT" "$ABS_TARGET/.github/copilot-instructions.md"

link_path "$SRC_SKILLS" "$ABS_TARGET/.github/skills"

mkdir -p "$ABS_TARGET/.claude"
if [[ -e "$ABS_TARGET/.claude/skills" || -L "$ABS_TARGET/.claude/skills" ]]; then
  rm -rf "$ABS_TARGET/.claude/skills"
fi
ln -s ../.github/skills "$ABS_TARGET/.claude/skills"
echo "Linked: $ABS_TARGET/.claude/skills -> ../.github/skills"

link_path "$SRC_COMMON_PROMPT" "$ABS_TARGET/.ai/common-prompt"

echo "Done. Injection completed for: $ABS_TARGET"
echo "Mode: symlink (soft reference)"

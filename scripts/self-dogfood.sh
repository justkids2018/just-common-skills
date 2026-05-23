#!/usr/bin/env bash
set -euo pipefail

# 让 hub 仓库自身消费自己的 skills（dogfooding 模式）。
# 安全设计：只链接 skills 和参考目录，不修改 AGENTS.md / CLAUDE.md。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

link_path() {
  local source="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf "$target"
  fi
  ln -s "$source" "$target"
  echo "  Linked: $target → $source"
}

echo "Self-dogfood: $HUB_ROOT"
echo ""

# skills
link_path "$HUB_ROOT/skills" "$HUB_ROOT/.github/skills"

mkdir -p "$HUB_ROOT/.claude"
if [[ -e "$HUB_ROOT/.claude/skills" || -L "$HUB_ROOT/.claude/skills" ]]; then
  rm -rf "$HUB_ROOT/.claude/skills"
fi
ln -s ../.github/skills "$HUB_ROOT/.claude/skills"
echo "  Linked: .claude/skills → ../.github/skills"

# reference dirs
link_path "$HUB_ROOT/common-prompt" "$HUB_ROOT/.ai/common-prompt"
link_path "$HUB_ROOT/system-platform" "$HUB_ROOT/.ai/system-platform"

echo ""
echo "✅ Self-dogfood enabled"

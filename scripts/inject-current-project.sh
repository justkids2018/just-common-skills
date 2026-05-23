#!/usr/bin/env bash
set -euo pipefail

# 统一注入脚本：将共享 skills、baseline、system-platform 注入到目标项目。
# 规则：有则追加(merge)，无则创建。Symlink 指向始终更新。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC_AGENTS="$HUB_ROOT/AGENTS.md"
SRC_CLAUDE="$HUB_ROOT/CLAUDE.md"
SRC_COPILOT="$HUB_ROOT/.github/copilot-instructions.md"
SRC_SKILLS="$HUB_ROOT/skills"
SRC_COMMON_PROMPT="$HUB_ROOT/common-prompt"
SRC_SYSTEM_PLATFORM="$HUB_ROOT/system-platform"

BEGIN_MARK="# BEGIN JUST-COMMON-SKILLS MANAGED BLOCK"
END_MARK="# END JUST-COMMON-SKILLS MANAGED BLOCK"

# --- Usage ---
usage() {
  cat <<'EOF'
将共享 skills 和治理规则注入到目标项目。

用法:
  scripts/inject-current-project.sh <target-project-path>

示例:
  bash scripts/inject-current-project.sh /path/to/my-project

行为:
  - AGENTS.md / CLAUDE.md / copilot-instructions.md:
    • 文件不存在 → 创建
    • 文件已存在 → 保留原有内容，追加/更新 managed block
  - .github/skills / .claude/skills / .ai/common-prompt / .ai/system-platform:
    • 始终创建 symlink 指向 hub（已有则更新）
EOF
}

# --- Merge Logic ---
# 如果目标文件已有 managed block，则更新 block 内容；
# 如果没有 managed block，则在末尾追加；
# 如果文件不存在，则直接创建。
merge_file() {
  local source_file="$1"
  local target_file="$2"

  mkdir -p "$(dirname "$target_file")"

  if [[ ! -f "$target_file" ]]; then
    cp "$source_file" "$target_file"
    echo "  Created: $target_file"
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp)"

  if grep -q "^${BEGIN_MARK}$" "$target_file" 2>/dev/null; then
    # 已有 managed block → 替换 block 内容
    awk -v begin="$BEGIN_MARK" -v end="$END_MARK" -v src="$source_file" '
      BEGIN { in_block = 0; while ((getline line < src) > 0) { block = block line "\n" }; close(src) }
      $0 == begin { print begin; printf "%s", block; in_block = 1; next }
      $0 == end   { print end; in_block = 0; next }
      in_block == 0 { print $0 }
    ' "$target_file" > "$tmp_file"
    mv "$tmp_file" "$target_file"
    echo "  Updated: $target_file (managed block refreshed)"
  else
    # 无 managed block → 追加
    {
      cat "$target_file"
      printf "\n\n%s\n" "$BEGIN_MARK"
      cat "$source_file"
      printf "\n%s\n" "$END_MARK"
    } > "$tmp_file"
    mv "$tmp_file" "$target_file"
    echo "  Merged: $target_file (block appended)"
  fi
}

# --- Symlink Logic ---
link_dir() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    rm -rf "$target"
  fi
  ln -s "$source" "$target"
  echo "  Linked: $target → $source"
}

# --- Main ---
if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 0
fi

# 源文件完整性检查
for f in "$SRC_AGENTS" "$SRC_CLAUDE" "$SRC_COPILOT"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: Hub 源文件缺失: $f" >&2
    exit 2
  fi
done
for d in "$SRC_SKILLS" "$SRC_COMMON_PROMPT" "$SRC_SYSTEM_PLATFORM"; do
  if [[ ! -d "$d" ]]; then
    echo "Error: Hub 源目录缺失: $d" >&2
    exit 3
  fi
done

TARGET_PROJECT="$1"

if [[ ! -d "$TARGET_PROJECT" ]]; then
  echo "Error: 目标项目不存在: $TARGET_PROJECT" >&2
  exit 1
fi

ABS_TARGET="$(cd "$TARGET_PROJECT" && pwd)"

echo "注入目标: $ABS_TARGET"
echo "Hub 源:   $HUB_ROOT"
echo ""

# 1. 合并文本文件
echo "[1/2] 合并治理文件..."
merge_file "$SRC_AGENTS" "$ABS_TARGET/AGENTS.md"
merge_file "$SRC_CLAUDE" "$ABS_TARGET/CLAUDE.md"
merge_file "$SRC_COPILOT" "$ABS_TARGET/.github/copilot-instructions.md"

# 2. 创建 symlink
echo ""
echo "[2/2] 链接共享目录..."
link_dir "$SRC_SKILLS" "$ABS_TARGET/.github/skills"

mkdir -p "$ABS_TARGET/.claude"
if [[ -e "$ABS_TARGET/.claude/skills" || -L "$ABS_TARGET/.claude/skills" ]]; then
  rm -rf "$ABS_TARGET/.claude/skills"
fi
ln -s ../.github/skills "$ABS_TARGET/.claude/skills"
echo "  Linked: .claude/skills → ../.github/skills"

link_dir "$SRC_COMMON_PROMPT" "$ABS_TARGET/.ai/common-prompt"
link_dir "$SRC_SYSTEM_PLATFORM" "$ABS_TARGET/.ai/system-platform"

echo ""
echo "✅ 注入完成"

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

FORCE_MODE="false"
REFERENCE_ENTRY_MODE="false"

# --- Usage ---
usage() {
  cat <<'EOF'
将共享 skills 和治理规则注入到目标项目。

用法:
  scripts/inject-current-project.sh [options] <target-project-path>

选项:
  --force              强制执行，不询问确认
  --reference-entry    使用引用入口模式（精简治理文件）
  -h, --help           显示帮助

示例:
  # 基本注入
  bash scripts/inject-current-project.sh /path/to/my-project

  # 强制注入（不询问）
  bash scripts/inject-current-project.sh --force /path/to/my-project

  # 引用入口模式（推荐用于中心化治理）
  bash scripts/inject-current-project.sh --reference-entry /path/to/my-project

  # 在目标项目内运行
  cd /path/to/my-project
  bash /path/to/just-common-skills/scripts/inject-current-project.sh --force

行为:
  - AGENTS.md / CLAUDE.md / copilot-instructions.md:
    • 文件不存在 → 创建
    • 文件已存在 → 保留原有内容，追加/更新 managed block
  - .github/skills / .claude/skills / .ai/common-prompt / .ai/system-platform:
    • 始终创建 symlink 指向 hub（已有则更新）

注入后的项目结构:
  target-project/
  ├── AGENTS.md                    # 项目级规则真源
  ├── CLAUDE.md                    # 软引用适配器
  ├── .github/
  │   ├── copilot-instructions.md  # Copilot 技能路由
  │   └── skills/                  # -> just-common-skills/skills/
  ├── .claude/
  │   └── skills/                  # -> .github/skills
  └── .ai/
      ├── common-prompt/           # -> just-common-skills/common-prompt/
      └── system-platform/         # -> just-common-skills/system-platform/
EOF
}

# --- Merge Logic ---
merge_file() {
  local source_file="$1"
  local target_file="$2"

  mkdir -p "$(dirname "$target_file")"

  if [[ ! -f "$target_file" ]]; then
    cp "$source_file" "$target_file"
    echo "  ✅ Created: $target_file"
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
    echo "  🔄 Updated: $target_file (managed block refreshed)"
  else
    # 无 managed block → 追加
    {
      cat "$target_file"
      printf "\n\n%s\n" "$BEGIN_MARK"
      cat "$source_file"
      printf "\n%s\n" "$END_MARK"
    } > "$tmp_file"
    mv "$tmp_file" "$target_file"
    echo "  ➕ Merged: $target_file (block appended)"
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
  echo "  🔗 Linked: $target → $source"
}

# --- Verification ---
verify_injection() {
  local target_project="$1"
  local errors=0

  echo ""
  echo "验证注入结果..."

  # Check files
  for file in "AGENTS.md" "CLAUDE.md" ".github/copilot-instructions.md"; do
    if [[ ! -f "$target_project/$file" ]]; then
      echo "  ❌ Missing: $file"
      ((errors++))
    else
      echo "  ✅ Found: $file"
    fi
  done

  # Check symlinks
  for link in ".github/skills" ".claude/skills" ".ai/common-prompt" ".ai/system-platform"; do
    if [[ ! -L "$target_project/$link" ]]; then
      echo "  ❌ Not a symlink: $link"
      ((errors++))
    else
      echo "  ✅ Symlink: $link"
    fi
  done

  # Count skills
  local skill_count
  skill_count=$(find "$target_project/.github/skills/just-"* -maxdepth 0 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$skill_count" -eq 0 ]]; then
    echo "  ❌ No skills found"
    ((errors++))
  else
    echo "  ✅ Skills: $skill_count"
  fi

  if [[ $errors -gt 0 ]]; then
    echo ""
    echo "❌ Verification failed with $errors error(s)"
    return 1
  fi

  echo ""
  echo "✅ Verification passed"
  return 0
}

# --- Parse Arguments ---
TARGET_PROJECT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE_MODE="true"
      shift
      ;;
    --reference-entry)
      REFERENCE_ENTRY_MODE="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "❌ Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      TARGET_PROJECT="$1"
      shift
      ;;
  esac
done

# If no target specified, use current directory
if [[ -z "$TARGET_PROJECT" ]]; then
  TARGET_PROJECT="$(pwd)"
fi

# --- Validate Sources ---
echo "📦 Just-Common-Skills Project Injector"
echo "======================================"
echo ""

for f in "$SRC_AGENTS" "$SRC_CLAUDE" "$SRC_COPILOT"; do
  if [[ ! -f "$f" ]]; then
    echo "❌ Hub 源文件缺失: $f" >&2
    exit 2
  fi
done

for d in "$SRC_SKILLS" "$SRC_COMMON_PROMPT" "$SRC_SYSTEM_PLATFORM"; do
  if [[ ! -d "$d" ]]; then
    echo "❌ Hub 源目录缺失: $d" >&2
    exit 3
  fi
done

# --- Validate Target ---
if [[ ! -d "$TARGET_PROJECT" ]]; then
  echo "❌ 目标项目不存在: $TARGET_PROJECT" >&2
  exit 1
fi

ABS_TARGET="$(cd "$TARGET_PROJECT" && pwd)"

# Check if target is the hub itself
if [[ "$ABS_TARGET" == "$HUB_ROOT" ]]; then
  echo "⚠️  Warning: Target is the hub itself. Use ./scripts/self-dogfood.sh instead."
  if [[ "$FORCE_MODE" != "true" ]]; then
    echo "Use --force to proceed anyway."
    exit 1
  fi
fi

echo "注入目标: $ABS_TARGET"
echo "Hub 源:   $HUB_ROOT"
echo "模式:     $([ "$REFERENCE_ENTRY_MODE" == "true" ] && echo "引用入口" || echo "标准")"
echo ""

# Confirm if not in force mode
if [[ "$FORCE_MODE" != "true" ]]; then
  printf "继续注入? [y/N]: "
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "取消注入"
    exit 0
  fi
fi

# --- Execute Injection ---
echo ""
echo "[1/2] 合并治理文件..."
merge_file "$SRC_AGENTS" "$ABS_TARGET/AGENTS.md"
merge_file "$SRC_CLAUDE" "$ABS_TARGET/CLAUDE.md"
merge_file "$SRC_COPILOT" "$ABS_TARGET/.github/copilot-instructions.md"

echo ""
echo "[2/2] 链接共享目录..."
link_dir "$SRC_SKILLS" "$ABS_TARGET/.github/skills"

mkdir -p "$ABS_TARGET/.claude"
if [[ -e "$ABS_TARGET/.claude/skills" || -L "$ABS_TARGET/.claude/skills" ]]; then
  rm -rf "$ABS_TARGET/.claude/skills"
fi
ln -s ../.github/skills "$ABS_TARGET/.claude/skills"
echo "  🔗 Linked: .claude/skills → ../.github/skills"

link_dir "$SRC_COMMON_PROMPT" "$ABS_TARGET/.ai/common-prompt"
link_dir "$SRC_SYSTEM_PLATFORM" "$ABS_TARGET/.ai/system-platform"

# --- Verify ---
verify_injection "$ABS_TARGET"

echo ""
echo "✅ 注入完成"
echo ""
echo "下一步:"
echo "  1. 在目标项目中运行 'git status' 查看改动"
echo "  2. 提交改动: git add AGENTS.md CLAUDE.md .github/ .claude/ .ai/"
echo "  3. 在 Claude Code 中输入 /just-dev-pipeline 开始使用"
echo ""
echo "要撤销注入，删除 symlinks 和 managed blocks 即可"

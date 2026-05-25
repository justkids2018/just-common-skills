#!/usr/bin/env bash
set -euo pipefail

# Just-Common-Skills 一键安装脚本
# 自动安装到 Claude Code, GitHub Copilot, Codex

REPO_URL="https://github.com/qisd/just-common-skills.git"
INSTALL_DIR="$HOME/.just-common-skills"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Just-Common-Skills 安装程序${NC}"
echo ""

# 检查 git
if ! command -v git &> /dev/null; then
    echo "❌ 需要安装 git"
    exit 1
fi

# 克隆或更新仓库
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}📂 检测到已有安装，正在更新...${NC}"
    cd "$INSTALL_DIR"
    git pull origin main
else
    echo -e "${BLUE}📥 正在克隆仓库...${NC}"
    git clone "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo ""
echo -e "${BLUE}🔗 正在安装技能（软链接模式）...${NC}"

# 定义目标目录
declare -A TARGETS=(
    ["Claude Code"]="$HOME/.claude/skills"
    ["GitHub Copilot"]="$HOME/.github/skills"
    ["Codex"]="$HOME/.codex/skills"
)

installed_count=0

# 安装到各个目标
for name in "${!TARGETS[@]}"; do
    target_dir="${TARGETS[$name]}"

    # 创建目标目录
    mkdir -p "$target_dir"

    # 为每个技能创建软链接
    for skill_dir in "$INSTALL_DIR"/skills/just-*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            link_path="$target_dir/$skill_name"

            # 删除旧链接（如果存在）
            if [ -L "$link_path" ] || [ -e "$link_path" ]; then
                rm -rf "$link_path"
            fi

            # 创建新链接
            ln -s "$skill_dir" "$link_path"
        fi
    done

    echo -e "  ${GREEN}✓${NC} $name: $target_dir"
    ((installed_count++))
done

echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
echo ""
echo "已安装到 $installed_count 个位置："
echo "  • Claude Code: ~/.claude/skills"
echo "  • GitHub Copilot: ~/.github/skills"
echo "  • Codex: ~/.codex/skills"
echo ""
echo "可用技能："
echo "  • just-dev-pipeline (端到端开发流程)"
echo "  • just-plan-eng-review (工程评审)"
echo "  • just-qa (质量验证)"
echo "  • just-review (代码审查)"
echo "  • just-ship (提交发布)"
echo "  • 以及更多..."
echo ""
echo "更新技能："
echo "  bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)"
echo ""
echo "卸载："
echo "  rm -rf ~/.just-common-skills"
echo "  rm -rf ~/.claude/skills/just-*"
echo "  rm -rf ~/.github/skills/just-*"
echo "  rm -rf ~/.codex/skills/just-*"

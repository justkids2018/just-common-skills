# Just-Common-Skills

Engineering workflows you can reuse across projects.

简洁目标：一个入口词（jcs），两个核心动作（安装、卸载）。

## Why

- 多项目复用同一套 skills 与规则
- 全局软链接模式，中心更新立即生效
- 支持五种 AI 编程助手：Claude Code、GitHub Copilot、Codex、Cursor、Google Gemini
- 保持最小命令面，降低学习成本

## Skills

- 编排器：just-dev-pipeline
- 核心工作器：just-plan-eng-review, just-qa, just-review, just-ship, just-document-release, just-investigate, just-careful
- 专用技能：CI/CD, 部署, 投研发布, 卡片工作流, 文档生成等
- UI 规范检测修复：just-ui-compliance（默认 iOS 移动端，兼容 Web Apple 风格，项目规范优先）

## Install and Update

推荐方式（免 npm）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)
```

npm 方式（全局后用短命令）：

```bash
npm i -g @qisd/just-common-skills
jcs i
```

更新：

```bash
jcs i
```

**安装位置：**
- `~/.claude/skills` (Claude Code)
- `~/.github/skills` (GitHub Copilot)
- `~/.codex/skills` (Codex)
- `~/.cursor/skills` (Cursor / OpenAI)
- `~/.gemini/skills` (Google Gemini)

## Uninstall

```bash
jcs u --force
```

## Public Commands

1. `jcs i` - 安装到所有 AI 助手
2. `jcs u` - 从所有 AI 助手卸载

## Docs

- 对比分析：[docs/framework-comparison-waza-vs-just-cn.md](docs/framework-comparison-waza-vs-just-cn.md)
- 脚本说明：[scripts/README.md](scripts/README.md)

# Scripts

对外公开命令只保留两条：

```bash
jcs i          # 安装到所有 AI 助手
jcs u --force  # 从所有 AI 助手卸载
```

等价脚本：

```bash
bash scripts/install-skills.sh --force
bash scripts/uninstall-skills.sh --force
```

## 安装目标

全局软链接到五个 AI 编程助手：

- `~/.claude/skills` (Claude Code)
- `~/.github/skills` (GitHub Copilot)  
- `~/.codex/skills` (Codex)
- `~/.cursor/skills` (Cursor / OpenAI)
- `~/.gemini/skills` (Google Gemini)

## 内部维护脚本

- `new-skill.sh` - 创建新技能
- `validate-skills.sh` - 验证技能格式
- `package-skill.sh` - 打包技能
- `self-dogfood.sh` - 本仓库自测

这些脚本属于内部维护，不作为对外主入口。

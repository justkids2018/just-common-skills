# Quickstart: 在新项目一键接入公共 Skills 规范

这份文档用于快速把以下能力注入到任意新项目：

- AGENTS 规范（AGENTS.md）
- CLAUDE 软引用（CLAUDE.md）
- Copilot 路由规范（.github/copilot-instructions.md）
- 公共 skills（.github/skills）
- 兼容链接（.claude/skills -> .github/skills）
- 公共 baseline（.ai/common-prompt）

## 0. 前置条件

- 已拉取本仓库到本地，例如：/absolute/path/to/just-common-skills
- 目标项目目录已存在

## 1. 一键注入（推荐）

在本仓库根目录执行：

```bash
cd /absolute/path/to/just-common-skills
./scripts/bootstrap-project.sh /absolute/path/to/your-project
```

示例：

```bash
cd /absolute/path/to/just-common-skills
./scripts/bootstrap-project.sh /absolute/path/to/my-new-project
```

默认是链接模式（link）：后续更新本仓库 skills，会自动反映到目标项目。

## 1.1 在新项目目录直接执行（软引用）

无论新项目还是老项目，都使用同一个脚本。你在项目目录里直接执行：

```bash
cd /absolute/path/to/your-project
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

说明：

- 软链接（软引用）模式：`skills` 与 `common-prompt` 都使用 symlink
- 有文件就合并追加/更新管理区块（不直接清空原内容）
- 没有文件就自动创建
- 目标项目默认是当前目录（`$PWD`）
- `--force` 兼容旧习惯，当前脚本会自动非交互执行
- 如需显式指定目标路径：

```bash
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh /absolute/path/to/your-project --force
```

## 2. 常用选项

1. 覆盖已存在文件（不交互确认）

```bash
./scripts/bootstrap-project.sh /absolute/path/to/your-project --force
```

2. 快照拷贝模式（不使用软链接）

```bash
./scripts/bootstrap-project.sh /absolute/path/to/your-project --copy
```

适用场景：

- link：团队统一维护，实时同步
- copy：项目隔离，需要冻结版本

## 3. 注入完成后如何验证

在目标项目执行：

```bash
cd /absolute/path/to/your-project
ls -la AGENTS.md CLAUDE.md .github/copilot-instructions.md
ls -la .github/skills
ls -la .claude/skills
ls -la .ai/common-prompt
```

你应当看到：

- AGENTS.md、CLAUDE.md、.github/copilot-instructions.md 存在
- .github/skills 存在
- .claude/skills 指向 .github/skills
- .ai/common-prompt 存在

## 4. 在新项目里如何触发 skills

进入目标项目后，Copilot 会根据 .github/copilot-instructions.md 的路由规则优先触发技能。

常见触发语句示例：

- 端到端开发一个功能 -> just-dev-pipeline
- 根据代码反向生成功能文档 -> just-feature-doc-generator
- 设计评审 -> just-plan-eng-review
- QA 验证 -> just-qa
- 提交前审查 -> just-review
- 根因排查 -> just-investigate
- 提交和 PR 收口 -> just-ship + just-document-release
- 高风险操作保护 -> just-careful

## 5. 快速回滚（可选）

如果你要移除注入内容，可以手动删除以下路径：

```bash
cd /absolute/path/to/your-project
rm -rf AGENTS.md CLAUDE.md .github/copilot-instructions.md .github/skills .claude/skills
rm -rf .ai/common-prompt
```

## 6. 故障排查

1. 报错 target project not found
- 目标目录路径写错，先确认目录存在

2. 提示目标已存在并询问替换
- 加 --force 可直接覆盖

3. 想看脚本参数

```bash
./scripts/bootstrap-project.sh --help
```

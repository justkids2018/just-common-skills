# Quickstart: 在新项目一键接入公共 Skills 规范

这份文档用于快速把以下能力注入到任意新项目：

- AGENTS 规范（AGENTS.md）
- CLAUDE 软引用（CLAUDE.md）
- Copilot 路由规范（.github/copilot-instructions.md）
- 公共 skills（.github/skills）
- 兼容链接（.claude/skills -> .github/skills）
- 公共 baseline（.ai/common-prompt）
- 公共平台规范（.ai/system-platform）

## 0. 前置条件

- 已拉取本仓库到本地，例如：/absolute/path/to/just-common-skills
- 目标项目目录已存在

## 1. 一键注入（软引用）

目的：把公共规则与公共 skills 接入项目，且始终使用软链接（symlink）。

方式 A：在公共仓库目录执行（传目标项目路径）

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/inject-current-project.sh /absolute/path/to/your-project --force
```

方式 B：在目标项目目录执行（调用公共脚本）

```bash
cd /absolute/path/to/your-project
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

## 2. 执行结果

- 软链接（软引用）模式：`skills` 与 `common-prompt` 都使用 symlink
- 有文件就合并追加/更新管理区块（不直接清空原内容）
- 没有文件就自动创建

AI 指令模板（可复制）：

```text
先读 /Users/qisd/Documents/development/ai/just-common-skills/README.md。
然后对当前项目执行软引用接入（不要 copy）：
bash /Users/qisd/Documents/development/ai/just-common-skills/scripts/inject-current-project.sh --force
执行后校验 .github/skills 和 .ai/common-prompt 为 symlink。
```

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
- .ai/system-platform 存在

任务收尾建议：执行
[system-platform/06-compliance-checklist.md](../system-platform/06-compliance-checklist.md)
中的 Task-Level Checklist，确认四件套完整。

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

发布建议（强烈推荐）：

- 每个版本发布前，由 `just-document-release` 产出
	`docs/releases/<version>/architecture-record.md`
- 模板参考：
	`system-platform/templates/architecture-record.template.md`

## 5. 快速回滚（可选）

如果你要移除注入内容，可以手动删除以下路径：

```bash
cd /absolute/path/to/your-project
rm -rf AGENTS.md CLAUDE.md .github/copilot-instructions.md .github/skills .claude/skills
rm -rf .ai/common-prompt
rm -rf .ai/system-platform
```

## 6. 故障排查

1. 报错 target project not found
- 目标目录路径写错，先确认目录存在

2. 想看脚本参数

```bash
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --help
```

3. 公共仓库本身也要启用同一套能力（self-dogfooding）

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/self-dogfood.sh
```

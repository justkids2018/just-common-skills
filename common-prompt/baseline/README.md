# 开发宪法 (Baseline)

> 仓库级公共 baseline 的唯一真源。精简版——每篇只保留规则，不含解释性文字。
> Agent 行为规则见 `AGENTS.md`，此处只定义代码质量标准。

## 优先级

```
AGENTS.md (行为规则) > baseline (质量标准) > 项目 ARCHITECTURE.md > 个人偏好
```

## 6 篇规则

| # | 文档 | 一句话 |
|---|------|--------|
| 01 | [01-design-principles.md](01-design-principles.md) | SOLID + KISS/DRY/YAGNI |
| 02 | [02-architecture.md](02-architecture.md) | 分层 + 边界 + AI 解耦 |
| 03 | [03-coding-standards.md](03-coding-standards.md) | 命名 + 复杂度 + 安全 |
| 04 | [04-testing-standards.md](04-testing-standards.md) | 金字塔 + 验证意图 |
| 05 | [05-git-workflow.md](05-git-workflow.md) | commit + PR + 风险操作 |
| 06 | [06-skill-workflow-standards.md](06-skill-workflow-standards.md) | 三问 + 触发 + workflow 恢复 |

## 设计约束

- 每篇 ≤ 50 行，只含规则与禁止项。
- 不含解释性散文、检查清单和正反例（这些放到 skill 层按需引用）。

## 给 AI Agent 的硬性要求

1. 任何代码改动必须通过 baseline 检查（01~06，其中 02 已包含 AI 解耦规则）。
2. 不得绕过 baseline 走快路径；需要例外时必须显式说明风险。
3. baseline 与临时需求冲突时，先停下来确认，再执行。

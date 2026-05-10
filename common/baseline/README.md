# 开发宪法 (Baseline)

> 这是仓库级公共 baseline 的唯一真源。
> Agent runtime 文件（如 `AGENTS.md`、`CLAUDE.md`）只引用，不复制规则正文。

## 目录定位

- Canonical: `common/baseline/`
- 要求：镜像目录内容必须与 canonical 保持一致

## 优先级

```
common/baseline/  >  项目 ARCHITECTURE.md  >  个人偏好
```

冲突时严格按上述顺序。baseline 永远优先。

## 5 条规则总览

| # | 文档 | 目标 |
|---|------|------|
| 01 | [01-design-principles.md](01-design-principles.md) | 设计原则：SOLID、KISS、DRY、YAGNI |
| 02 | [02-architecture.md](02-architecture.md) | 分层架构：Clean Architecture + DDD + AI 解耦 |
| 03 | [03-coding-standards.md](03-coding-standards.md) | 编码规范：命名、注释、错误处理、安全 |
| 04 | [04-testing-standards.md](04-testing-standards.md) | 测试规范：单元、集成、E2E 边界 |
| 05 | [05-git-workflow.md](05-git-workflow.md) | 交付流程：分支、commit、PR、push 安全 |

## 文档风格约束

- baseline 只定义原则、边界、检查项和禁区。
- baseline 不包含业务实现细节，不做代码逻辑分析。
- 具体技术栈和实现方案放到项目级文档（如 `ARCHITECTURE.md`、`docs/specs/`）。

## 建议阅读顺序

1. 先读 01、02（原则 + 架构 + AI 解耦）
2. 再读 03、04（实现与验证）
3. 最后读 05（提交与发布）

## 给 AI Agent 的硬性要求

1. 任何代码改动必须通过 baseline 检查（01~05，其中 02 已包含 AI 解耦规则）。
2. 不得绕过 baseline 走快路径；需要例外时必须显式说明风险。
3. baseline 与临时需求冲突时，先停下来确认，再执行。

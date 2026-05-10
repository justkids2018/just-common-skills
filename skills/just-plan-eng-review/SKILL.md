---
name: just-plan-eng-review
description: 开发前工程设计评审技能。用于在实现前收敛架构风险、边界条件与验证策略。
---

# just-plan-eng-review

## Purpose

在编码前审查技术方案，降低返工与实现阶段风险。

## Inputs

- 需求文档路径（通常为 doc/features/<feature>/01-requirement.md）
- 设计文档路径（通常为 doc/features/<feature>/03-design.md）
- 约束条件（性能、兼容性、上线窗口）

## Outputs

- 评审结论（通过/有条件通过/不通过）
- 风险清单（高/中/低）
- 必改项与建议项

## Steps

1. 核对需求范围与设计边界是否一致。
2. 审查关键技术决策、依赖影响与回滚路径。
3. 给出评审结论和可执行修改建议。

## Constraints

- 不直接改业务代码。
- 建议必须可执行，禁止抽象空话。
- 高风险项必须显式标记并阻断进入实现阶段。

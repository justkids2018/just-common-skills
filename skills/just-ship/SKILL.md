---
name: just-ship
description: 提交与 PR 流程技能。用于按任务粒度提交、推送并生成可审阅 PR 草稿。
---

# just-ship

## Purpose

把已完成并通过验证的改动，转换为规范的提交与 PR 产物。

## Inputs

- 变更文件与任务编号
- 提交规范
- PR 模板要求

## Outputs

- 规范 commit 记录
- PR 草稿（标题、摘要、验证、风险、回滚）

## Steps

1. 检查工作区状态和提交粒度。
2. 按任务分批提交并编写规范 commit message。
3. 生成 PR 草稿并附上验证证据。

## Constraints

- 禁止把多个无关任务压成一个大提交。
- 禁止跳过验证证据直接发 PR。
- 涉及破坏性操作时必须先确认。

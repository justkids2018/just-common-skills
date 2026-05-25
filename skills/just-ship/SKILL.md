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

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Convert verified changes into standardized commits and PR artifacts. Check workspace state, create task-granular commits with proper messages, push to remote, and generate reviewable PR draft with title, summary, verification evidence, risks, and rollback plan.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "ship this" or "commit and push"
2. "create a PR" or "prepare pull request"
3. "ready to submit" or "time to commit"
4. "push these changes" or "send for review"
5. "finalize and ship" or "commit this work"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: clean task-granular commits with conventional messages, pushed branch, and complete PR draft with all required sections (summary, changes, verification, risks, rollback).

Example:
```
✅ Shipped: User Profile Edit

Commits:
- feat(profile): add edit form UI (task-01)
- feat(profile): implement save logic (task-02)
- test(profile): add validation tests (task-03)

Branch: feature/profile-edit
Remote: pushed to origin

PR Draft (07-pr.md):
Title: Add user profile editing feature
Summary: Implements profile edit form with validation...
Changes: 3 files, +245 -12 lines
Verification: All tests pass, UI verified on Android emulator
Risks: None identified
Rollback: Revert commits in reverse order

Ready for review: https://github.com/org/repo/pull/42
```

## Constraints

- 禁止把多个无关任务压成一个大提交。
- 禁止跳过验证证据直接发 PR。
- 涉及破坏性操作时必须先确认。

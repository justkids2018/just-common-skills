---
name: just-review
description: 提交前代码审查技能。用于识别逻辑风险、回归风险、可维护性问题与文档影响点。
---

# just-review

## Purpose

在提交前执行结构化审查，确保代码可维护、可验证、可上线。

## Inputs

- 变更文件列表
- 测试结果
- 需求与设计文档

## Outputs

- 问题清单（阻断/建议）
- 修复建议
- 审查结论

## Steps

1. 审查关键改动是否满足需求并保持兼容。
2. 标记阻断问题与建议问题。
3. 输出结论，并要求阻断项修复后复审。

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Execute structured pre-commit code review to identify logic risks, regression risks, maintainability issues, and documentation impacts. Output categorized issues (blocking vs. advisory) with evidence and require blocking items to be fixed before approval.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "review this code" or "code review needed"
2. "check my changes before commit"
3. "self-review" or "pre-commit review"
4. "any issues with this?" or "is this safe to merge?"
5. "review before shipping" or "audit these changes"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: categorized issue list (blocking/advisory), fix recommendations with file:line references, documentation impact notes, and a clear verdict (APPROVED / BLOCKED / APPROVED_WITH_CONCERNS).

Example:
```
## Review Result: APPROVED_WITH_CONCERNS

### Blocking Issues
None.

### Advisory Issues
1. [auth_service.dart:45] Consider adding timeout to HTTP client
2. [user_model.dart:12] Missing null check for optional email field

### Documentation Impact
- Update API.md: new `timeout` parameter in AuthService
- Update CHANGELOG.md: mention email field now optional

### Verdict
APPROVED_WITH_CONCERNS - safe to commit, address advisory items in follow-up.

Evidence: doc/features/auth-timeout/06-review.md
```

## Constraints

- 以风险为主，不做无关格式挑刺。
- 结论必须附证据（文件和行为影响）。
- 有阻断项时不得放行提交。

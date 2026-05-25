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

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Review technical design before coding to converge architectural risks, boundary conditions, and verification strategies. Verify requirement-design alignment, audit key technical decisions, dependencies, and rollback paths, then output verdict (APPROVED / CONDITIONAL / REJECTED) with actionable fix items.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "review this design" or "design review needed"
2. "check the technical plan" or "audit the architecture"
3. "is this design sound?" or "any risks in this approach?"
4. "engineering review before implementation"
5. "validate the design doc" or "pre-coding review"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: verdict (APPROVED/CONDITIONAL/REJECTED), categorized risk list (HIGH/MEDIUM/LOW), must-fix items vs. advisory items, and actionable recommendations with file/section references.

Example:
```
## Engineering Review Result: CONDITIONAL

### Verdict
CONDITIONAL - can proceed after addressing 2 HIGH risks

### Risk Assessment

HIGH Risks:
1. [03-design.md:45] No database migration rollback strategy defined
2. [03-design.md:67] Auth token refresh not specified - will break 30min+ sessions

MEDIUM Risks:
1. [03-design.md:89] Performance impact on large datasets not analyzed

LOW Risks:
None.

### Must-Fix Items (before implementation)
1. Add migration rollback section to 03-design.md
2. Specify token refresh mechanism in auth flow diagram
3. Add load testing plan for 10K+ user scenario

### Advisory Items
- Consider adding caching layer for frequently accessed profiles
- Document API rate limits in design

Evidence: doc/features/profile-edit/design-review.md
```

## Constraints

- 不直接改业务代码。
- 建议必须可执行，禁止抽象空话。
- 高风险项必须显式标记并阻断进入实现阶段。

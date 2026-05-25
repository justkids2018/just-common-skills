---
name: just-document-release
description: 发布后文档同步技能。用于让设计、任务、测试与发布文档与最终代码一致。
---

# just-document-release

## Purpose

在提交或发布前后，完成文档收口并消除文档与代码偏差。

## Inputs

- 代码最终变更
- 设计/任务/测试/PR 文档
- 文档规范

## Outputs

- 更新后的文档列表
- 文档差异说明
- 待补文档清单（如有）
- 版本架构记录（`docs/releases/<version>/architecture-record.md`）
- 可发布的 HTML 文档包（按需）

## Steps

1. 对照代码核验文档内容是否过时。
2. 按 `system-platform/07-architecture-version-record.md` 生成本版本架构记录。
3. 更新关键文档并补充遗漏项。
4. 对外发布场景下，将关键文档导出为 HTML 展示版（保留 Markdown 真源），并遵循 `system-platform/08-html-output-standard.md`。
5. 输出文档同步结果与残留事项。

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Synchronize documentation with final code after commit/release. Verify design/task/test/PR docs match code reality, generate version architecture record per `07-architecture-version-record.md`, update outdated docs, optionally export HTML per `08-html-output-standard.md`, and output sync results with remaining gaps.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "sync the docs" or "update documentation"
2. "finalize release docs" or "close documentation loop"
3. "docs out of sync" or "align docs with code"
4. "generate architecture record" or "version documentation"
5. "export docs for release" or "publish documentation"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: updated doc list with change summary, architecture record for the version, doc-code diff report, remaining gaps list (if any), and optionally HTML export package for external distribution.

Example:
```
✅ Documentation Release: v1.2.0

Updated Documents:
- doc/features/profile-edit/03-design.md (added token refresh section)
- doc/features/profile-edit/04-tasks.md (updated task-02 scope)
- doc/features/profile-edit/05-test-result.md (final test results)

Architecture Record:
- docs/releases/v1.2.0/architecture-record.md ✓

Doc-Code Alignment:
- All design decisions reflected in code ✓
- All tasks completed and verified ✓
- Test results match final implementation ✓

Remaining Gaps:
None.

HTML Export (optional):
- docs/releases/v1.2.0/html/index.html
- Ready for external distribution

Status: DONE
```

## Constraints

- 不允许只改代码不改文档。
- 不允许编造未执行的测试结论。
- 文档改动必须可追溯到代码改动。
- 每个发布版本必须有且仅有一份架构记录。
- Markdown 是单一真源；HTML 仅用于展示与分发。

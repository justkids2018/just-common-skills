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

## Constraints

- 不允许只改代码不改文档。
- 不允许编造未执行的测试结论。
- 文档改动必须可追溯到代码改动。
- 每个发布版本必须有且仅有一份架构记录。
- Markdown 是单一真源；HTML 仅用于展示与分发。

---
name: just-qa
description: 实现后验证与缺陷修复技能。用于执行构建、测试、手动验证并输出修复结果。
---

# just-qa

## Purpose

在任务实现后完成质量验证，发现并修复阻断问题。

## Inputs

- 当前任务变更文件
- 测试命令与运行环境
- 验收标准

## Outputs

- 测试结果摘要（通过/失败）
- 缺陷清单与修复记录
- 剩余风险说明
- `RUN_LOG.md`（标准运行证据）
- UI 验收截图与问题标注（移动端优先）

## Steps

1. 执行 build 与 test，并记录失败项。
2. 进行关键路径手动验证（按项目类型执行）。
3. 修复阻断问题并复测，输出最终结果。
4. 以统一格式写入或更新 `RUN_LOG.md`。

## Mobile UI 验收流程（Android / Flutter / iOS）

在任务涉及 UI 改动时，执行以下步骤：

1. 启动目标应用（模拟器或真机）。
2. 定位并进入“当前改动页面”（按任务说明中的页面路径）。
3. 在关键状态点截图，至少包括：
	- 页面初始态
	- 关键交互后状态（点击、输入、切换、滚动）
4. 检查 UI 与交互：
	- 布局：对齐、间距、遮挡、溢出、截断、适配
	- 视觉：字体层级、颜色对比、组件状态一致性
	- 交互：可点击区域、反馈、禁用态、异常提示
5. 记录问题并给出结论：
	- `PASS`：无阻断问题
	- `FAIL`：列出问题、严重级别、复现步骤

推荐证据目录：`doc/features/<feature>/runs/<task-id>/ui/`

推荐命名：

- `01-initial.png`
- `02-after-action.png`
- `03-error-state.png`（如有）

## 平台差异说明

- Flutter：优先热重载后复验同一路径页面。
- Android / iOS 原生：每次修复后重新构建并复验关键路径。
- Web（后续支持）：沿用同样流程，增加断点尺寸检查（mobile/tablet/desktop）。

## UI QA 输出模板（建议）

~~~md
## UI Validation

### Target Page
<route/page name>

### Device/Runtime
<android emulator / ios simulator / flutter hot reload>

### Screenshots
- ui/01-initial.png
- ui/02-after-action.png

### Findings
- [Severity] <issue summary> | <repro step>

### Verdict
PASS | FAIL
~~~

## RUN_LOG 模板（建议）

~~~md
## Result
PASS | FAIL

## Command
<exact command(s)>

## Exit Code
<int>

## Stdout
```text
<verbatim output>
```

## Stderr / Traceback
```text
<verbatim output>
```

## Summary
<1-3 lines>
~~~

## Constraints

- 测试失败不得忽略，必须处理或阻断。
- 不允许“假通过”报告。
- 修复范围应限定在当前任务边界。
- `RUN_LOG.md` 必须保留可复现命令与退出码。
- 涉及 UI 改动时，截图与页面定位步骤不可省略。

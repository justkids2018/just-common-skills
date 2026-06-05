---
name: just-ui-compliance
description: 移动端优先的 UI 视觉规范检测与修复技能。只管视觉显示（字号/排版/布局/热区），不涉及颜色。先读取项目 AGENTS.md/Agent.md 规则，项目无规则时回退到本技能默认规范。
---

# just-ui-compliance

## Purpose

对现有 UI 做视觉规范检测并直接修复问题，默认使用移动端规范，同时支持 Web 规范。

**不检查颜色**：颜色属于设计稿主观范畴，不在本技能范围内。

**核心关注点**：
- 文字在容器里是否**显示得出来**（不被裁切、不溢出、不被遮挡）
- 字号层级是否合理（title/body/hint 各自清晰）
- 按钮内文字为什么看不见（字号 + padding 比例失调）
- 触控热区是否足够

## Inputs

- 项目代码与样式文件（Flutter/SwiftUI/React/Vue/CSS 等）
- 页面入口或关键路由
- 项目规则文档（优先）：`AGENTS.md`、`Agent.md`、`copilot-instructions.md`、设计规范文档

## Outputs

- UI 问题清单（按阻断/高/中）
- 已修复变更（代码级）
- 验证证据（截图或关键状态说明）
- 最终合规结论（PASS/FAIL + remaining risks）

## Rule Precedence

规则优先级必须严格执行：

1. 项目规则（`AGENTS.md`/`Agent.md`/项目 design docs）
2. 本技能默认规则（`rules/mobile-baseline.md`、`rules/web-baseline.md`）

合并策略：

- 项目规则与默认规则冲突时，以项目规则为准。
- 项目规则缺失时，使用默认规则补齐。
- 最终输出一份“本次生效规则摘要”。

## Default Scope

- 默认模式：`mobile`
- 可选模式：`web`
- 未明确模式时，先执行 `mobile`，再补充 `web` 基础检查。

## Steps

1. 识别平台与页面范围（移动端优先）。
2. 读取项目规范文件并生成“生效规则集”。
3. 按生效规则做 UI 检测（文字、字号、圆角、触控区、遮挡、截断、对齐、状态反馈、可访问性）。
4. 输出问题清单并标记严重级别。
5. 直接修改代码修复问题（禁止只给建议不改）。
6. 复验关键页面与关键交互（初始态、交互后、错误态）。
7. 输出结果：修复项、未修复风险、下一步建议。

## Mandatory Checks

> **不检查颜色**。所有检查项均针对"文字/内容是否能被看见和阅读"。

### A. Typography — 字号层级

- 各级字号是否在规范区间内（见 `rules/mobile-baseline.md` 字体层级表）
- 行高是否导致文字拥挤或行间相互遮挡
- 字号层级是否倒置（次要文字比主要文字大）

### B. Text Visibility — 文字是否显示得出来（重点）

- 文字是否被容器裁切（overflow hidden 导致底部/顶部半行消失）
- 按钮内文字是否完整显示（字号 + padding 比例是否合法，见规范公式）
- 输入框占位文字是否被边框遮挡
- 长文本是否有正确的 ellipsis 或换行策略，而不是静默消失
- 多行文字的末行是否完整（不能只露出一半高度）
- 图标是否与标签文字重叠

### C. Component Shape — 组件形状与尺寸

- Button/输入框/Card 圆角是否在规范范围内
- 圆角过大导致文字被角落裁切的问题
- 组件高度是否能容纳字号 + 上下 padding（见规范高度公式）
- 图标与文字垂直对齐是否正确

### D. Touch Target — 触控热区

- 所有可点击元素最小触控区域是否达标（移动端 44×44 pt）
- 主流程按钮是否满足最小热区
- 键盘弹出后输入区域是否被遮挡，用户还能否操作

### E. Layout Integrity — 布局完整性

- 安全区（刘海/Home 指示条区域）内容是否正确保护
- 小屏（320 pt 宽）与大屏是否出现内容溢出或遮挡
- 多语言或超长文案是否导致布局破坏
- 字体缩放到 115% 时，文字是否仍在容器内正确显示

## Severity Rules

- `BLOCKER`: 文字完全不可见 / 被裁切到无法阅读 / 按钮内容无法显示 / 主流程按钮不可点
- `HIGH`: 字号明显偏离规范层级 / 热区不足 / 末行文字只露出一半 / 布局在小屏溢出
- `MEDIUM`: 字号层级一致性问题 / 间距不符合 8pt 网格 / 圆角偏差

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Run visual UI compliance audit and direct remediation for mobile and web. Detects and fixes problems where text is not visible, clipped, or overflowing containers — especially buttons where font size plus padding causes text to disappear. Does NOT check colors. Resolves rules from project docs first, falls back to defaults.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "检查这个页面的 UI 规范"
2. "按钮里的字显示不出来"
3. "按钮文字是不是太大了"
4. "做一轮移动端 UI 视觉 QA"
5. "检查字号层级是否合理"
6. "文字被截断了 / 内容放不进去"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: active rule source summary, categorized issue list with file:line references, concrete code fixes applied, and verification at default + 115% text scale.

Example:

```md
## UI Compliance Result: PASS_WITH_MINOR_RISKS

### Effective Rules
- Source priority: project AGENTS.md > mobile-baseline.md
- Active mode: mobile
- No color checks applied

### Fixed Issues (BLOCKER)
1. [src/ui/login_button.dart:24] Button label size 22 -> 17; height 40 -> 52
   Reason: font 22pt + padding 16pt*2 = required height 54.8 but was 40pt → text clipped
2. [src/ui/profile_header.dart:67] overflow = visible -> ellipsis; maxLines added
   Reason: long name silently overflowed container, last 40% invisible

### Fixed Issues (HIGH)
3. [src/theme/text_styles.dart:12] Caption size 10 -> 12 (below 12pt minimum)

### Verification
- Emulator: initial / after tap / error state checked at 100% and 115% text scale
- No text clipping detected

### Remaining Risks
- Terms page: section header slightly above grid (MEDIUM, not blocking)
```

## Constraints

- 以“检测 + 修复”为主，不允许只输出建议。
- 涉及 UI 修复时，必须复验关键状态。
- 若连续 3 轮修复后仍无法稳定通过，转入 `just-investigate`。
- 不得覆盖或违背项目已有规范（项目规则优先）。

---
name: just-dev-pipeline
description: 端到端 6 步开发 Workflow Skill — 需求澄清 → 代码/文档分析 → 设计与任务拆解 → 实现与运行迭代 → 自审修复 → 提交与 PR + 文档收口。所有产物统一落盘到项目 doc/ 目录。
---

# Dev Pipeline — 端到端开发 Workflow Skill

> **目的**：把“给需求就开干”的黑盒开发，变成可审计、可回滚、可持续维护的 Feature Workflow。

## 触发

| 方式 | 命令 |
|------|------|
| 显式 | `/just-dev-pipeline <功能名>` |
| 隐式 | 用户说"新增/增加/开发/实现 XX"、"我想做 XX 功能"、"我的需求是 XX"、"帮我出 PR"、"顺便更新文档" |

## 三档模式（默认 fast）

| 模式 | 触发 | Gate 行为 |
|------|------|----------|
| **fast**（默认） | 直接触发 / `/fast` | 需求确认、提交前停 |
| **strict** | `/strict` 或 "严格模式" | 每段都停，等 `/confirm` |
| **yolo** | `/yolo` 或 "全自动" | 自动推进，但破坏性操作仍需确认 |

> **任何模式下**，破坏性操作（删表 / 删文件 / `down -v` / force push / 删迁移）必须显式确认。

## 六步流程

```
1. 需求澄清 + 验收边界
2. 现状分析（代码 + 现有 doc）
3. 技术设计 + 任务拆分
4. 代码实现 + 运行 + 迭代修改
5. 自审 + 修复
6. 提交与 PR + 文档收口
```

## 1+7 执行技能路由

本技能是唯一主流程入口，负责编排 6 步流程；执行动作由下列 7 个技能负责：

1. `just-plan-eng-review`：设计评审与风险收敛
2. `just-qa`：实现后验证与缺陷修复
3. `just-review`：提交前代码审查
4. `just-ship`：提交、推送、PR 流程
5. `just-document-release`：发布后文档同步
6. `just-investigate`：问题定位与根因分析
7. `just-careful`：危险操作前确认

说明：上面是能力清单，不是执行顺序。真实执行顺序严格按“六步流程”。

### 主流程运行时序（关键）

1. 段 1 需求澄清：主流程自己执行，不调用 worker。
2. 段 2 现状分析：主流程自己执行，不调用 worker。
3. 段 3 设计与拆分：调用 `just-plan-eng-review`。
4. 段 4 代码实现与验证：先写代码，再调用 `just-qa`；失败时调用 `just-investigate`。
5. 段 5 自审修复：调用 `just-review`；复杂问题调用 `just-investigate`。
6. 段 6 提交与收口：调用 `just-ship` + `just-document-release`。
7. 任意步骤遇到破坏性操作前：先调用 `just-careful`。

### 路由原则

1. 主流程仍按 6 步推进，不允许跳步。
2. 进入具体执行场景时，优先调用对应执行技能，不做临场即兴流程。
3. 任意步骤出现失败或异常时，先调用 `just-investigate` 定位根因，再继续。
4. 任意破坏性操作前，必须先走 `just-careful` 的确认流程。

### 完成状态协议

每一步结束都必须明确给出一种状态：

- `DONE`：本步已完成，且可进入下一步。
- `DONE_WITH_CONCERNS`：已完成但存在风险，必须列出风险点。
- `BLOCKED`：无法继续，必须列出阻塞原因与下一动作。

### 段 1 — 需求澄清（强制多轮）

**Agent 必须做的：**
1. 把用户原始需求**拆成 N 个独立子需求点**
2. 对每个子需求点，逐一向用户提问澄清（有疑点继续问，没疑点也至少 1 轮整体复述）
3. 全部对齐后，按 [`references/01-requirement.md`](references/01-requirement.md) 模板生成
4. 落盘到 `doc/features/<feature>/01-requirement.md`
5. 输出："需求文档已生成，请审阅。回复 `/confirm` 或修订意见。"
6. **【硬 Gate，所有模式都停】**

### 段 2 — 现状分析（代码 + 文档）

**Agent 必须做的：**
1. 先分析现有实现和现有文档（`doc/` 下相关内容）。
2. 输出受影响模块、复用点、风险点、文档差异点。
3. 落盘到 `doc/features/<feature>/02-analysis.md`。
4. **strict 模式**：等 `/confirm`。

### 段 3 — 技术设计 + 任务拆分

**Agent 必须做的：**
1. 按 [`references/02-tech-design.md`](references/02-tech-design.md) 输出设计。
2. 调用 `just-plan-eng-review` 对设计进行评审，收敛高风险项。
3. 按 [`references/03-tasks.md`](references/03-tasks.md) 拆分任务。
4. 每个 Task：
   - ≤ 3 个文件
   - ≤ 200 行 diff
   - 列出影响文件清单
   - 列出验证方式（编译/单测/手测）
5. 设计文档落盘到 `doc/features/<feature>/03-design.md`。
6. 任务文档落盘到 `doc/features/<feature>/04-tasks.md`。
7. **strict 模式**：等 `/confirm`。

### 段 4 — 代码实现 + 运行 + 迭代修改

**Agent 必须做的：**
1. 按 Task 顺序执行，先完成当前 Task 的代码实现，**一次回复只做一个 Task**
2. 每 Task 完成后：
   - 跑 build / test
    - 先识别项目类型，再运行验证：
       - Android 项目：启动并运行应用进行流程验证
       - Flutter 项目：热重载并验证当前改动
       - iOS 项目（原生）：重新编译并在模拟器/真机运行验证关键流程
   - 调用 `just-qa` 输出验证结果与问题清单
   - 若验证失败，调用 `just-investigate` 先做根因定位，再进入修复
   - 根据运行结果持续小步修改，直到当前 Task 可用
   - 若需求发生变化，立即更新 `doc/features/<feature>/01-requirement.md` 与 `04-tasks.md`
   - 简报：改了哪些文件、行数、测试结果
   - **任何模式都停下等"继续"**（fast 不等需求/设计/拆分，但每个 Task 都等）
3. 编码必须遵守：
   - [`common/baseline/03-coding-standards.md`](../../common/baseline/03-coding-standards.md)
   - [`common/baseline/04-testing-standards.md`](../../common/baseline/04-testing-standards.md)
4. **build/test 失败立即停下**，禁止"先跳过这个测试"
5. 测试结果落盘到 `doc/features/<feature>/05-test-result.md`。

### 段 5 — 自审 + 修复

**Agent 必须做的：**
1. 实现完成后必须调用 `just-review` 进行代码审查。
2. 输出问题清单：阻断问题 / 建议问题 / 文档影响点。
3. 遇到复杂问题或重复失败时，先调用 `just-investigate` 再修复。
4. 修复阻断问题后重新审查，直到可提交。
5. 审查结论落盘到 `doc/features/<feature>/06-review.md`。

### 段 6 — 提交与 PR + 文档收口

**Agent 必须做的：**
1. 按 [`references/05-commit.md`](references/05-commit.md) 写 commit message
2. 引用需求 ID（`refs: doc/features/<feature>/`）
3. 按 Task 粒度小步 commit（不要一个大 commit）
4. 输出 PR 草稿（标题、摘要、变更点、验证、风险、回滚说明）。
5. 提交前收口文档：更新 `03-design.md`、`04-tasks.md`、`08-doc-updates.md`，确保与最终代码一致。
6. 调用 `just-ship` 执行提交与 PR 流程，调用 `just-document-release` 完成文档同步。
7. **【硬 Gate，所有模式都停】** 等用户确认后执行 commit / push / PR。
8. PR 草稿落盘到 `doc/features/<feature>/07-pr.md`。

## 硬约束（任何模式不可关）

| 约束 | 数值 |
|------|------|
| 单次回复修改文件数 | ≤ 3 |
| 单次回复 diff 行数 | ≤ 200 |
| 单 Task 文件数 | ≤ 3 |
| 单 Task diff 行数 | ≤ 200 |
| 段 1 / 段 6 Gate | 强制停 |
| 破坏性操作 | 强制确认 |

**超出限制时**：必须先输出"分段计划"，等用户点头才继续。

## 产物目录

```
doc/features/<feature-name>/
├── 01-requirement.md
├── 02-analysis.md
├── 03-design.md
├── 04-tasks.md
├── 05-test-result.md
├── 06-review.md
├── 07-pr.md
└── 08-doc-updates.md
```

## 与 baseline 的关系

- **本 Skill 管"流程"**：怎么走六步
- **baseline 管"规则"**：每段产物的内容必须符合
- baseline 标准目录：`common/baseline/`
- 任何冲突：baseline 优先

## 切换模式（运行中）

用户可随时说：
- "切到 strict" → 后续段切 strict
- "切到 fast" → 后续段切 fast
- "全自动跑完" → 后续段切 yolo

## 反模式（禁止）

- ❌ 跳过段 1 直接写代码
- ❌ 需求不清晰还不提问就推进
- ❌ 不分析现有 doc 就直接开工
- ❌ 实现后不运行项目验证（Android/Flutter/iOS）
- ❌ 一次实现完多个 Task 才汇报
- ❌ 段 1 只问 1 个问题就生成需求文档
- ❌ 段 4 build/运行失败假装没看见
- ❌ 段 6 commit 信息只写 "update"
- ❌ 需求已变更但不更新 `doc/` 对应文档

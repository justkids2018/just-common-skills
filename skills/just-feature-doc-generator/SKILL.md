---
name: just-feature-doc-generator
description: |
  从当前项目代码反向生成某个功能的文档包：需求文档、逻辑文档、接口文档。
  输出严格采用业务抽象视角，不暴露代码细节。
  当用户说"分析某某功能并出文档""根据代码生成需求和接口文档""梳理当前功能逻辑"时自动触发。
---

# Feature Doc Generator

---

## 一、三种文档的定位

每次生成文档前，先明确三种文档的**读者和核心产出**：

| 文档 | 定位 | 主要读者 | 核心产出 |
|------|------|---------|---------|
| `01-requirement.md` | **产品需求规格**：页面上有什么、用户能做什么 | 产品、测试、UI | 每个 UI 区块 + 每个操作点的完整拆解 |
| `02-logic.md` | **业务逻辑规格**：用户操作触发哪些流程 | 业务分析师、开发 | 业务流程图 + 时序图 + 规则（纯文字） |
| `03-api.md` | **接口契约**：每个接口对应哪个 UI 操作 | 前后端、测试 | 按 UI 区块分组的接口清单 + 完整字段 |

---

## 二、三种文档的绝对禁止项

以下内容**禁止出现在任何一种文档中**：

- 代码块（任何语言）
- 函数名、方法名（如 loadPlanTemplates、createTask）
- 组件名（如 BeginnerComposerCard、EmployeeSkillsDialog）
- 变量名（如 rawInputExample、planJson.steps、isActive）
- 文件路径（如 src/views/Home.vue）
- 类型定义（如 interface PlanTemplate {...}）
- 字段内部命名（如"通过 planTemplateId 传入"）

**正确的替换方式举例**：

| 禁止写 | 应该写 |
|--------|---------|
| rawInputExample 字段 | 模板的示例输入文本 |
| planJson.steps 数组 | 执行步骤列表 |
| needsConfirmation: false | 任务创建后自动进入执行状态，无需等待用户确认 |
| BeginnerComposerCard | 工作台输入区 |
| status === 'plan_ready' | 当任务进入「计划已生成」状态时 |

---

## 三、每种文档的结构规范

### 3.1 需求文档 01-requirement.md

**这份文档回答：这个功能的页面上有什么？每个区块、每个按钮、每个状态是什么？**

必须包含的章节：

```
1. 功能概述 — 一句话：是什么功能、给谁用、解决什么问题
2. 目标用户与使用场景 — 用户角色 + 2-3 个典型场景 + 使用前提
3. 页面结构与功能拆解 — ⚠️ 核心章节，必须逐 UI 区块拆解

   每个区块必须包含：
   [区块名称]（业务名称，不用组件名）
     展示内容：每个可见元素逐一列出
     交互操作：每个操作单独描述
       操作名称
       - 触发条件：什么情况下可见/可点
       - 操作步骤：用户如何操作
       - 系统响应：系统做了什么
     状态说明：空态/加载/有数据/错误时的展示差异

4. 功能范围 — 包含（In Scope）/ 不包含（Out of Scope）
5. 验收标准 — 格式：「当 [前提] 时，[用户操作]，系统 [表现]」
6. 限制与约束 — 数量限制、权限限制、状态限制
```

---

### 3.2 逻辑文档 02-logic.md

**这份文档回答：用户操作触发哪些业务流程？系统如何一步步响应？关键规则是什么？**

⚠️ 严禁出现代码块、函数名、组件名、变量名。

必须包含的章节：

```
1. 整体业务流程图 — Mermaid flowchart
   - 参与方用业务角色命名（用户/工作台界面/任务服务/成员服务）
   - 覆盖主路径 + 关键分支 + 异常路径

2. 主流程描述 — 每个主流程用有序步骤描述
   步骤 1：[角色] [动作]
   步骤 2：[系统] [响应]

3. 关键业务规则
   格式：「[触发条件] 时，[规则内容]」

4. 状态流转（若有）— Mermaid stateDiagram

5. 异常流程与降级策略
   | 异常场景 | 处理策略 | 用户可见影响 |

6. 关键场景时序图 — Mermaid sequenceDiagram
   - 覆盖最复杂的操作路径
   - 参与方：用户/工作台界面/业务服务（业务语言）

7. 架构影响（若有）— 模块耦合风险 + 演进建议
```

---

### 3.3 接口文档 03-api.md

**这份文档回答：这个功能用到哪些接口？每个接口对应哪个用户操作？请求和响应字段是什么？**

⚠️ 按 UI 区块分组，不按技术模块分组。每个接口必须标注"触发该接口的用户操作"。

必须包含的章节：

```
1. 接口总览（按 UI 区块分组）
   | 接口名称 | 方法 | 路径 | 触发该接口的用户操作 | 所在 UI 区块 |

2. 接口详情（每个接口一节）
   接口名称（业务描述）
     调用时机：用户做了什么才触发
     所属区块：在哪个 UI 区块下
     请求参数
       | 参数位置 | 参数名 | 类型 | 必填 | 业务含义 |
     响应字段
       | 字段名 | 类型 | 业务含义 |
     错误情况
       | 状态码 | 说明 | 用户影响 |

3. 接口变更历史
   | 版本 | 日期 | 变更说明 |
```

---

## 四、输入

必须至少有一项：

1. 功能名称（例如：用户登录、订单支付、计划模板快捷入口）
2. 入口位置（模块名/页面名/路由路径）
3. 关键词（用于定位代码范围）

若以上输入都无法在代码中匹配到对应功能：
1. 明确返回"未匹配到功能范围"
2. 给出建议输入
3. 等用户补充后再继续

---

## 五、输出目录

doc/feature-docs/<feature>/

固定输出：01-requirement.md、02-logic.md、03-api.md

---

## 六、执行流程

### Step 1: 功能范围确认
1. 用用户给的功能名定位代码范围
2. 若范围不清晰，先追问关键问题再继续
3. 明确记录"包含范围/不包含范围"

### Step 2: 代码扫描，建立内部证据映射
1. 识别涉及的路由、视图、API 调用
2. 建立"代码行为 → 业务行为"的翻译表（仅内部使用，不写入文档）
3. 重要：将代码中的每个操作翻译为业务动作后再写文档

### Step 3: 生成需求文档
按 3.1 结构生成 01-requirement.md
重点：逐区块拆解 UI，每个交互点单独列出，不含任何代码引用

### Step 4: 生成逻辑文档
按 3.2 结构生成 02-logic.md
重点：flowchart + sequenceDiagram，全部业务语言，无代码

### Step 5: 生成接口文档
按 3.3 结构生成 03-api.md
重点：每个 API 标注对应 UI 操作，字段含义用业务语言描述

### Step 6: 质量检验
必须通过的检查：
- [ ] 三个文档均不含代码片段
- [ ] 三个文档均不含函数名、组件名、变量名
- [ ] 01-requirement.md 包含逐区块 UI 拆解（每个操作单独列出）
- [ ] 02-logic.md 包含 flowchart 和 sequenceDiagram
- [ ] 03-api.md 每个接口标注了触发它的 UI 操作
- [ ] 所有接口请求和响应字段完整

---

## 七、更新策略

用户说"修改了这个功能，更新文档"时：
1. 增量扫描改动
2. 只更新受影响章节
3. 在文档末尾追加 Update Log（日期 + 改动摘要）

---

## 八、反模式举例

### 需求文档反模式

❌ 禁止：用字段名描述展示内容
> 展示 rawInputExample 字段，作为输入框预填值

✅ 正确：
> 输入框预填该模板的示例输入文本，用户可自行修改

---

❌ 禁止：用 TypeScript 定义数据结构
> PlanTemplate 包含 id、name、planJson.steps 等字段

✅ 正确：
> 每条模板包含：名称、描述、示例输入、执行步骤列表、团队成员配置

---

❌ 禁止：笼统描述，不拆解 UI
> 用户可以管理团队成员

✅ 正确：
> 自动组队区块
> - 展示当前任务成员卡片（头像、姓名、职位名称）
> - 点击"展示更多组员"：打开成员选择弹窗（含我的员工/员工市场两个标签）
> - 点击成员卡片右侧"移除"：从任务中移除该成员
> - 点击成员头像：打开该成员的技能管理弹窗

### 逻辑文档反模式

❌ 禁止：包含代码块
> async function loadPlanTemplates() { ... }

✅ 正确：
> 页面加载时，系统自动拉取用户的计划模板列表（最多 10 条），同时批量查询涉及的技能名称。若拉取失败，静默忽略，快捷按钮区不显示。

---

❌ 禁止：流程图使用组件名
> BeginnerComposerCard → API → planTemplatesLoaded

✅ 正确：
> 工作台界面 → 模板服务 → 技能服务

---

## 九、Three-Question Design Test

### Q1: What exact job does this skill perform?
Reverse-engineer feature documentation from existing code into three business-readable docs:
- 01-requirement.md: product spec with detailed UI breakdown (every section, button, state)
- 02-logic.md: business logic with flowcharts and sequence diagrams (no code)
- 03-api.md: API contract with each endpoint mapped to the UI action that triggers it
All outputs use business terminology only—no code, no function names, no component names.

### Q2: When should it activate?
1. "分析某功能并出文档" / "document this feature"
2. "根据代码生成需求和接口文档"
3. "梳理当前功能逻辑" / "重新梳理一下这个功能文档"
4. "把这个功能的需求整理出来"
5. "这个页面有哪些功能点，帮我出文档"

### Q3: What does perfect output look like?

Perfect 01-requirement.md: 每个 UI 区块独立章节，每个交互操作单独列出（触发条件 + 步骤 + 系统响应），无任何代码引用。

Perfect 02-logic.md: 完整 flowchart（业务角色命名）+ sequenceDiagram（覆盖复杂场景）+ 有序步骤描述，无代码。

Perfect 03-api.md: 先按 UI 区块分组汇总，再每接口单独一节，含调用时机/所属区块/完整请求响应字段，无代码。

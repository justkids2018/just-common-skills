---
name: just-value-red-publish
description: |
  统一投资研究 skill。输入公司名 + 分析类型，自动完成：数据收集 → 框架分析 → 生成报告 →
  生成小红书文章 + HTML 卡片 → 发布到小红书。全程 4 个确认门，每个关键节点必须等用户确认才继续。
version: 1.1
trigger: /just-value-red-publish [公司名] [分析类型]
---

# /just-value-red-publish — 统一投资研究与小红书发布 Skill

## 触发方式

```
/just-value-red-publish [公司名] [分析类型]
```

**分析类型（可选值）**：

| 类型关键词 | 含义 | 执行内容 |
|-----------|------|---------|
| `Q1财报` / `Q2财报` / `Q3财报` / `Q4财报` / `财报` | 单季财报分析 | 数据获取 → 三表分析 → 高管洞察 → 论点跟踪 |
| `行业分析` | 行业格局研究 | 竞争格局 → 趋势 → 宏观四维 |
| `商业分析` | 商业模式研究 | 飞轮 → 护城河 → 多空论点 |
| `完整研究` | 全套深度研究 | 执行 value-research-company 完整流程 |
| （省略） | 自动判断 | 根据公司名和当前上下文判断最合适类型 |

**示例**：
```
/just-value-red-publish Robinhood Q1财报
/just-value-red-publish 泡泡玛特 行业分析
/just-value-red-publish Circle 完整研究
/just-value-red-publish Hermes          ← 省略类型，自动判断
```

---

## 核心原则

**数据铁律**：宁可空格，不可造数。

| 级别 | 来源 | 使用规则 |
|------|------|----------|
| **A 级**（唯一财务来源） | 公司 IR 官网 / SEC EDGAR / 港交所 | 所有财务数字必须来自此处 |
| **B 级**（辅助参考） | 电话会实录 / 机构报告 / Press Release | 引语和指引，标注来源 |
| **C 级**（情绪参考） | 新闻 / 分析师转述 / X / Reddit | 标注 ⚠️，严禁作为财务数据依据 |

无法核实的数字一律标注 `[待官方核实]`。

**执行现实约束**：优先复用用户已确认的现有产物，避免重复生成、重复发布、重复重启服务。

**默认封面策略（v1.1）**：
- 封面图优先使用：`cover.jpg` > `cover.jpeg` > `cover.png` > `hero.jpg` > `hero.jpeg` > `logo.png` > `icon.png` > `main.png`
- 封面图展示为全幅背景图（突出主体），不再使用右下角旋转小图
- 副标题建议 8-16 字，优先一句主结论（示例：`远景很大，利润为王`）

**思想框架**：全程遵循 `个股研究/思考架构/投资研究思想框架.md`，分析层次为：
- **第零层**：AI 时代定位（是否被重写？）
- **第一层**：宏观四维过滤（高墙主义 / 反脆弱性 / 两极分化 / AI 冲击）
- **第二层**：公司质量四维（护城河 / 管理层 / 竞争格局 / 财务健康）
- **第三层**：估值与概率赔率

---

## 合规约束（强制执行）

依据《金融产品网络营销管理办法》（八部门联合发布，2026年9月30日实施）。

**所有生成内容（小红书文案、卡片、报告）必须严格遵守以下规定：**

### ❌ 绝对禁止（逐字对应法律条款）

| 禁止行为 | 具体表现 |
|---------|---------|
| **荐股/带单** | 发布个股代码买卖点位、建仓/减仓/清仓指令、涨跌预测、带单操作 |
| **诱导性话术** | 明示/暗示"必涨、满仓、抄底、止损位、目标价"等 |
| **代客决策** | 替用户做买卖决定、引导跟风交易 |

### ✅ 允许的内容边界

- 分享公司基本面研究（财务数据分析、商业模式研究）
- 描述行业格局和趋势（不含个股操作建议）
- 表达个人学习思考（明确标注"不构成投资建议"）
- 引用官方公告、SEC文件等公开信息并注明来源

### 内容生成时的合规检查（每次 Phase 3 输出前必须执行）

生成小红书文案后，逐条检查：
1. 是否包含"买入/卖出/加仓/减仓/清仓"等操作指令？→ 有则删除
2. 是否包含"目标价 $XX / 止损位 XX%"等具体数值操作建议？→ 有则删除
3. 是否含有"必涨/必跌/稳赚/无风险"等绝对化表述？→ 有则改写
4. 结尾是否有"以上仅为个人研究，不构成投资建议"？→ 无则补充

---

## 进度条格式（每步完成后输出）

```
───────────────────────────────────────
 /just-value-red-publish [公司名] [类型]  进度
───────────────────────────────────────
 ✅ Phase 0  初始化 & 类型判断
 ⏳ Phase 1  数据收集              ← 当前
 ⬜ 🚪 GATE 1  数据确认
 ⬜ Phase 2  分析（思维框架）
 ⬜ 🚪 GATE 2  分析结论确认
 ⬜ Phase 3  生成内容（MD + 小红书文案）
 ⬜ Phase 4  生成 HTML
 ⬜ 🚪 GATE 3  HTML 预览确认
 ⬜ Phase 5  发布配置
 ⬜ 🚪 GATE 4  发布确认
 ⬜ Phase 6  执行发布
───────────────────────────────────────
✅ = 完成  ⏳ = 执行中  ⬜ = 待执行  🚪 = 确认门（必须等用户）
```

---

## Phase 0：初始化 & 类型判断

1. 提取公司名称（支持中英文、股票代码）
2. 判断分析类型（见触发方式表）
3. 读取 `config.json` 中的输出目录规则并确认或创建目录：
  - 财报分析 → `output.earnings`
  - 行业分析 → `output.industry`
  - 商业分析 → `output.business`
  - 完整研究 → `output.full_research`
4. 检查是否已有历史研究文件，若有则读取作为背景
5. 输出初始进度条

---

## Phase 1：数据收集

根据分析类型执行对应数据收集流程。

### 财报分析（Q1 / Q2 / Q3 / Q4 / FY）

按优先级获取数据：
1. **公司 IR 官网** → 最新季度 Press Release PDF
2. **SEC EDGAR** → `https://www.sec.gov/cgi-bin/browse-edgar`（美股 10-Q / 10-K）
3. **港交所** → `https://www.hkexnews.hk`（港股）

必须记录：
```
数据来源：[IR官网 / SEC EDGAR / 港交所]
文件名：[文件名称]
发布日期：[YYYY-MM-DD]
数据口径：[GAAP / Non-GAAP，货币单位]
报告期：[Q1/Q2/Q3/Q4/FY + 年份]
```

收集重点指标（根据类型选择）：
- **利润表**：营收（总量 + 分板块）/ 毛利率 / 经营利润率 / 净利润率
- **现金流**：OCF / FCF / FCF 转化率
- **资产负债**：净现金 / 有息债务 / 核心 KPI（平台专属，如 AUM / ARPU / 用户数）
- **电话会**：管理层指引 + 直接引语

### 行业分析

搜索：
- 行业规模 TAM（最新数据，标注来源）
- 主要竞争对手财务对比（最新年报数据）
- 行业趋势报告（McKinsey / BCG / 行业协会，标注日期）
- 监管动态（近 6 个月内）

### 商业分析

搜索：
- 公司最新年报或季报中的业务描述
- 管理层在电话会/访谈中对商业模式的表述
- 第三方研究（Seeking Alpha / Substack，标注 ⚠️ C 级）
- 宏观四维初筛所需信息

### 完整研究

执行 `value-research-company.md` 的 Step 1 → Step 3 全部数据收集流程。

---

## 🚪 GATE 1：数据确认

**⛔ 强制 STOP — 在用户确认前，不得执行任何分析步骤。**

输出以下确认块：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚪 GATE 1 / 4 — 数据确认
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 公司：[公司名]
📊 分析类型：[类型]
📅 数据来源：[来源 + 日期]

核心数据速览：
┌─────────────────────┬──────────┬──────────┬───────┐
│ 指标                 │ 本期      │ 上期      │ YoY   │
├─────────────────────┼──────────┼──────────┼───────┤
│ 营收                 │ $___     │ $___     │ +__% │
│ 净利润               │ $___     │ $___     │ +__% │
│ [核心 KPI 1]        │ ___      │ ___      │ +__% │
│ [核心 KPI 2]        │ ___      │ ___      │ +__% │
│ [核心 KPI 3]        │ ___      │ ___      │ +__% │
└─────────────────────┴──────────┴──────────┴───────┘

数据获取状态：
✅ [已成功获取的数据项]
⚠️ [待核实 / 暂缺的数据项，说明原因]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
请确认数据是否正确，然后回复：
  ✅ 继续   — 数据无误，开始分析
  🔧 修正   — 有数据问题（请说明）
  ❌ 停止   — 终止本次研究
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 2：分析（思维框架）

**前提**：仅在 GATE 1 用户回复"继续"后执行。

### 2.0 第零层：AI 时代定位

- 这家公司是**重写者**还是**被重写者**？
- 若被重写：高风险（1-3年）/ 中风险（3-7年）/ 低风险（7年+）
- → 被重写且高风险：在结论中给出明确警告

### 2.1 第一层：宏观四维过滤

按 `个股研究/思考架构/宏观四维框架_深度细化版.md` 执行完整四维打标：

```
高墙主义：[受益 / 中性 / 受损] — [数据支撑的一句话理由]
反脆弱性：[反脆弱 / 强韧 / 脆弱] — [五问核心结论]
两极分化：[顺势 / 中性 / 逆势] — [用户定位分析]
AI时代：[卡位受益 / 工具化存活 / 被瓦解风险] — [核心判断]
```

### 2.2 第二层：公司质量四维

| 维度 | 打标 | 核心依据 |
|------|------|---------|
| 护城河 | 深厚 / 一般 / 存疑 | [具体护城河类型 + 数据] |
| 管理层 | 优秀 / 合格 / 存疑 | [历史承诺兑现率] |
| 竞争格局 | 有利 / 中性 / 危险 | [3年内最大威胁] |
| 财务健康 | 健康 / 中性 / 警示 | [FCF / 净现金 / 利润率] |

### 2.3 第三层：估值（仅完整研究 / 财报分析触发）

- DCF 估值（基础场景 / 乐观 / 悲观）
- P/E / P/FCF 横向对比
- 三情景期望收益率
- 宏观调整后买入价区间

### 2.4 财报专项分析（仅财报类型触发）

**三表精析**（遵循 `earnings-analysis.md` 规范）：
- 利润表：营收结构 YoY / 费用率趋势 / 利润率变化
- 现金流：OCF / FCF / FCF 转化率
- 资产负债：净现金 / ROIC / 商誉风险

**高管洞察提炼**：
- 战略重心信号（与上季比较）
- 财务指引（显式 Guidance + 隐含信号）
- 管理层可信度（承诺 vs 兑现：✅ / ⚠️ / ❌）

**论点跟踪**：对照上一期跟踪指标，验证成立（✅）/ 存疑（⚠️）/ 失效（❌）

### 2.5 行业专项分析（仅行业类型触发）

- 竞争格局横向对比表（市值 / 收入 / 利润率 / 用户量）
- 行业集中度趋势（是否强者愈强？）
- 最危险的未来竞争者（时间线 + 威胁程度）
- 关键决战时间窗口

### 2.6 商业专项分析（仅商业类型触发）

- 增长飞轮拆解（① → ② → ③ 自我强化步骤）
- 多方最强 3 个论点（含数据）
- 空方最强 3 个论点（含数据）
- 芒格逆向三问（强制回答）：
  - 死亡问题：5年内最可能的死法是什么？
  - 同步崩塌：所有支持论点同时错了会怎样？
  - 行业消亡：这个行业 10 年后还存在吗？

---

## 🚪 GATE 2：分析结论确认

**⛔ 强制 STOP — 在用户确认前，不得生成任何内容文件。**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚪 GATE 2 / 4 — 分析结论确认
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 [公司名] [类型] 分析摘要

第零层：[重写者 / 被重写者（风险级别）]

宏观四维评级：
  高墙主义  ➜  [受益 / 中性 / 受损]
  反脆弱性  ➜  [反脆弱 / 强韧 / 脆弱]
  两极分化  ➜  [顺势 / 中性 / 逆势]
  AI时代    ➜  [卡位受益 / 工具化存活 / 被瓦解风险]

公司质量：
  护城河  ➜  [深厚 / 一般 / 存疑]
  管理层  ➜  [优秀 / 合格 / 存疑]
  竞争格局➜  [有利 / 中性 / 危险]
  财务健康➜  [健康 / 中性 / 警示]

核心结论（1-2句话）：
[结论内容]

最大风险：[风险描述]
最大机会：[机会描述]

最终判断：[买入 / 观望 / 跳过 / 深度研究]
估值区间：$[低] — $[合理] — $[高]（如适用）

下季跟踪指标：
1. [指标名]：目标值 ___ / 警示值 ___
2. [指标名]：目标值 ___ / 警示值 ___
3. [指标名]：目标值 ___ / 警示值 ___

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
分析结论是否符合你的判断？
  ✅ 继续   — 结论无误，开始生成内容
  🔧 调整   — 需要修改某个判断（请说明）
  ❌ 停止   — 终止本次研究
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 3：生成内容

**前提**：仅在 GATE 2 用户回复"继续"后执行。

### 3.1 研究报告 MD 文件

**路径规则**：
- 财报分析 → `Just学投资/[公司]研究/[公司]-财报分析-[期间]-[日期].md`
- 行业分析 → `Just学投资/[公司]研究/[公司]-行业分析-[日期].md`
- 商业分析 → `Just学投资/[公司]研究/[公司]-商业分析-[日期].md`
- 完整研究 → 在 `个股研究/[公司名]/` 下生成完整的 00~06 系列文件

**内容规范**：
- 财报类：遵循 `earnings-analysis.md` 的输出结构（三表精析 + 高管洞察 + 论点跟踪）
- 行业 / 商业类：遵循 `value-research-company.md` 对应章节格式
- 完整研究：遵循 `value-research-company.md` 全套文件格式

### 3.2 小红书文案

**文风**：Just 60 风格 — 有趣 > 真诚 > 有料。像一个刚入门但认真研究过的朋友。

**格式**：
- 钩子开头（1-2句，引发共鸣或好奇）
- 核心内容（3-5个要点，每点1-2句）
- 总结 + 互动引导（提问或号召评论）
- 话题标签（6-8个，含通用 + 专属）

**禁止**：承诺收益、推荐买卖、贩卖焦虑、标题党；严格遵守上方"合规约束"章节的所有条款（《金融产品网络营销管理办法》）

**文案中必须包含**：
- 1-2个让普通人能理解的类比
- 至少1个反直觉的发现（空方视角或被忽略的盲区）
- 结尾注明"以上仅为个人研究，不构成投资建议"

---

## Phase 4：生成 HTML

**前提**：Phase 3 完成后自动执行。

### 品牌色映射表（封面渐变色）

根据公司名称自动选择品牌色：

| 公司 | 品牌色渐变 | 说明 |
|------|-----------|------|
| 腾讯 | `#4a9eff → #2563eb` | 蓝色（微信/QQ） |
| 阿里巴巴 | `#FF6B35 → #d4a574` | 橙色 |
| 字节跳动 | `#1f2937 → #0ea5e9` | 黑蓝色 |
| 拼多多 | `#FF6B35 → #f97316` | 橙红色 |
| 美团 | `#FFD100 → #FFA500` | 黄橙色 |
| 京东 | `#E3393C → #C81623` | 红色 |
| 小米 | `#FF6700 → #FF8533` | 橙色 |
| 华为 | `#C8102E → #E60012` | 红色 |
| 比亚迪 | `#0066CC → #0080FF` | 蓝色 |
| 宁德时代 | `#00A0E9 → #0080C8` | 蓝色 |
| 茅台 | `#C8102E → #8B0000` | 深红色 |
| 爱马仕 | `#FF6B35 → #d4a574` | 橙金色 |
| LVMH | `#1f2937 → #8B4513` | 深棕色 |
| 默认 | `#4a9eff → #2563eb` | 蓝色 |

**使用方式**：在生成 HTML 时，根据公司名称匹配品牌色，设置封面 `.cover-bg` 的内联样式。

### 4.1 研究报告 HTML（report.html）

**路径**：与 MD 文件同目录，文件名 `report.html` 或 `[公司]-[类型]-report.html`

**设计规范**（参照 `个股研究/Robinhood/robinhood_report.html`）：
- Apple 风格：浅色/深色主题切换
- 左侧导航栏（sidebar）+ 右侧内容区
- 数据卡片（card-grid）
- 进度指示（health-meter）
- 完整财务表格 + 条形图

**必须包含的区块**：
- 核心指标卡片（营收 / 净利润 / 核心 KPI）
- 宏观四维评级（可视化打标）
- 公司质量评分（4维雷达或评分卡）
- 财务数据表格
- 风险清单
- 最终判断框（verdict box）

### 4.2 小红书卡片 HTML（cards.html）

**模板位置**：`.claude/skills/just-value-red-publish/templates/card-template-standard.html`
**样式文件**：`.claude/skills/just-value-red-publish/templates/card-styles.css`
**使用说明**：`.claude/skills/just-value-red-publish/templates/README.md`

**生成步骤**：
1. 读取标准模板和样式文件
2. 根据公司名称从品牌色映射表中选择封面渐变色
3. 根据分析类型选择卡片结构（财报分析 7张 / 行业分析 6-7张）
4. 填充实际分析数据
5. 生成完整 HTML 文件到目标目录
6. 提示用户：可选将公司 Logo/Icon 放到同目录（如 `./logo.png`）

**设计规范**（参照 `.claude/skills/just-value-red-publish/templates/README.md`）：
- **尺寸**：370×550px 基准尺寸，按视口自动等比缩放（移动端自适应）
- **配色**：
  - 封面：品牌色渐变（动态设置）+ 浅色标题 `#f8fafc`
  - 内容卡：统一深灰渐变 `linear-gradient(135deg, #1f2937 0%, #111827 100%)`
- **Just 60 徽章**：右上角毛玻璃效果
  - `background: rgba(100, 100, 100, 0.35)`
  - `backdrop-filter: blur(20px)`
  - `border: 1.5px solid rgba(255, 255, 255, 0.2)`
- **封面设计**：
  - 标题颜色：浅色 `#f8fafc`（在实拍图叠加时更清晰）
  - 封面图层：全幅背景图 + 渐变遮罩（左深右浅），兼顾图片突出与文案可读
  - hero-item：透明毛玻璃卡片
    - `background: rgba(10, 20, 35, 0.22)`
    - `backdrop-filter: blur(20px)`
    - `border: 1.5px solid rgba(255, 255, 255, 0.16)`
  - 间距：`padding: 72px 28px 30px 28px`
  - 字体：标题28px，副标题14px，hero-text 13px
- **内容卡设计**：
  - 点状编号徽章（32×32px，圆角8px）：
    - blue: `linear-gradient(135deg, #4b7bff 0%, #78a3ff 100%)`
    - gold: `linear-gradient(135deg, #d88919 0%, #f2bc59 100%)`
    - green: `linear-gradient(135deg, #1ea672 0%, #57cf9d 100%)`
    - purple: `linear-gradient(135deg, #e0456a 0%, #f4879d 100%)`
  - 数据卡片/堆叠卡片：
    - `background: rgba(255, 255, 255, 0.12)`
    - `border: 1.5px solid rgba(255, 255, 255, 0.2)`
    - `backdrop-filter: blur(20px)`
    - `box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3)`
- **一键下载功能**：html2canvas 导出 PNG（scale: 2）

**内容结构**（根据分析类型选择）：

财报分析卡片（7张）：
- c1: 封面（公司名 + 季度 + 3个hero-item核心数字）
- c2: 核心数据（metric-grid 2×2）
- c3: 业务亮点（stack-item堆叠）
- c4: 战略分析（stack-item堆叠）
- c5: 宏观四维评级（rating-grid 2×2）
- c6: 最大风险（stack-item堆叠）
- c7: 估值分析（data-table + stack-item）

行业 / 商业分析卡片（6-7张）：
- c1: 封面（公司名 + 主题 + 3个hero-item）
- c2: 市场规模（metric-grid）
- c3: 竞争格局（data-table + stack-item）
- c4: 行业趋势（stack-item堆叠）
- c5: 宏观四维评级（rating-grid）
- c6: 核心洞察（stack-item堆叠）
- c7: 免责声明（可选）

**封面 Logo/Icon 使用**：
- 用户可选将公司图片（JPG/PNG）放到与 HTML 同目录
- 文件名优先级：`cover.jpg` / `cover.jpeg` / `cover.png` / `hero.jpg` / `hero.jpeg` / `logo.png` / `icon.png` / `main.png`
- 模板会自动检测并作为封面全幅背景图显示（自动裁切）
- 如果没有图片，纯色渐变背景也很专业

**CSS变量定义**：
```css
:root {
  --content-bg: linear-gradient(135deg, #1f2937 0%, #111827 100%);
  --text-main: #f9fafb;
  --text-sub: rgba(249, 250, 251, 0.74);
  --text-muted: rgba(249, 250, 251, 0.58);
  --accent-blue: #60a5fa;
  --accent-green: #34d399;
  --accent-gold: #fbbf24;
  --accent-red: #f87171;
}
```

---

## 🚪 GATE 3：HTML 预览确认

**⛔ 强制 STOP — 在用户确认前，不得执行任何发布操作。**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚪 GATE 3 / 4 — HTML 预览确认
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ 已生成文件：
  📄 研究报告 MD：[文件路径]
  🌐 研究报告 HTML：[文件路径]
  🎴 小红书卡片：[文件路径]
  📝 小红书文案：已包含在卡片文件内

请在浏览器中打开以下文件预览：
  🔗 研究报告：[相对路径]
  🔗 小红书卡片：[相对路径]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
预览完成后，请回复：
  ✅ 发布   — 内容无误，进入发布配置
  🔧 修改   — 需要调整内容（请说明）
  ⏸️ 暂存   — 先不发布，留存文件即可
  ✅ 已手动发布 — 已在页面中点击发布，仅需记录结果
  ❌ 停止   — 放弃发布
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 5：发布配置

**前提**：仅在 GATE 3 用户回复"发布"后执行。

### 5.1 自动配置内置 publisher

先解析发布目录（按顺序）：
1. 读取 `config.json` 的 `publisher_path`
2. 若为相对路径：按当前 workspace 根目录拼接
3. 若不存在：回退到 `~/.claude/skills/just-value-red-publish/publisher`
4. 若仍不存在：立即报错并停止，不得继续执行发布命令

修改 `.claude/skills/just-value-red-publish/publisher/publish.js` 中的配置：

```javascript
// 卡片 HTML 路径（自动填入当前 cards.html 路径）
const CARDS_HTML = path.join(__dirname, '..', '[相对路径]', 'cards.html');

// 卡片列表（根据实际生成的卡片 id 自动填入）
const CARDS = [
  { id: 'c1', name: '01-封面' },
  { id: 'c2', name: '02-[内容]' },
  // ... 自动补全
];

// 发布内容（从 Phase 3 生成的文案自动填入）
const POST = {
  title: '[自动填入标题]',
  content: '[自动填入小红书文案]',
  tags: ['[标签1]', '[标签2]', ...],
  is_original: true,
  visibility: '公开可见',
};
```

### 5.2 计算推荐发布时间

根据当前时间自动推荐最佳发布时间：
- 12:00 - 20:30 → 今天 20:30
- 20:30 - 23:59 → 明天 08:30
- 00:00 - 08:30 → 今天 08:30（若已过则明天 08:30）

---

## 🚪 GATE 4：发布确认

**⛔ 强制 STOP — 在用户确认发布时间前，不得执行任何发布命令。**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚪 GATE 4 / 4 — 发布确认
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📱 发布标题：[标题]
🏷️ 话题标签：[标签列表]
🖼️ 卡片数量：[N] 张

⏰ 推荐发布时间：[时间]（当前：[现在时间]）

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
请选择发布方式：
  🚀 立即发布   — 现在立即发布
  ⏰ 定时发布   — 使用推荐时间 [时间]
  🕐 自定义时间 — 请输入时间（格式：HH:MM 或 明天 HH:MM）
  ❌ 取消发布   — 暂不发布
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 6：执行发布

**前提**：仅在 GATE 4 用户确认后执行。

### 执行流程（遵循 `publishrednote.md` v5.0 规范）

```bash
cd [解析后的 publisher 目录]

# Step 1: 检查服务状态
npm run check

# Step 2: 立即发布（用户选"立即发布"）
npm run publish

# 或定时发布（用户选时间）
npm run publish:scheduled
```

若用户明确表示“已手动点击发布”或“已在页面发布”：
- 不再重启 MCP、不重复执行 `npm run publish`
- 直接进入发布结果记录与复盘输出

### 自动处理：
1. 检查 MCP 服务状态（端口 18060）
2. 检查登录状态（未登录则提示扫码，最多等待 120 秒）
3. 使用 Puppeteer 渲染图片（3x 高清）
4. 调用小红书 MCP 上传图片并发布

### 发布完成后输出：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 发布完成！
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 标题：[标题]
⏰ 发布时间：[实际发布/预定时间]
📂 本地文件：[路径]

下季跟踪提醒：
1. [跟踪指标1]：目标值 ___ / 警示值 ___
2. [跟踪指标2]：目标值 ___ / 警示值 ___
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 质量检查清单（输出前逐项核对）

- [ ] 所有财务数字均有 A 级来源标注
- [ ] 无法核实的数字已标注 `[待官方核实]`
- [ ] 【直引】与【推断】严格区分
- [ ] 宏观四维每个维度都有明确结论（不允许"有待观察"）
- [ ] 小红书文案不含买卖建议、不贩卖焦虑
- [ ] 每张 HTML 卡片都有 Just 60 水印
- [ ] 封面副标题为一句主结论（建议 8-16 字）
- [ ] 跟踪指标给出了双向意义（目标值 + 警示值）
- [ ] 末尾注明"以上仅为个人研究，不构成投资建议"

---

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Unified investment research and Xiaohongshu publishing workflow: collect data from official sources (IR/SEC/HKEX), analyze using investment framework (macro 4D + company quality 4D + valuation), generate research report MD + Xiaohongshu article + HTML cards, and publish to Xiaohongshu with 4 mandatory confirmation gates.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "/just-value-red-publish [Company] [Type]"
2. "analyze [Company] Q1 earnings and publish"
3. "research [Company] industry analysis"
4. "full research on [Company]" or "deep dive [Company]"
5. "generate investment report and Xiaohongshu cards"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: research report MD with macro 4D ratings + company quality assessment + valuation, Xiaohongshu article (Just 60 style, compliance-checked), HTML cards (7 cards for earnings, 6-7 for industry/business), and published post with tracking metrics for next quarter.

Example:
```
✅ Research & Publish Complete: Robinhood Q1 2026 Earnings

Phase 1: Data collected from SEC 10-Q (2026-05-08)
Phase 2: Analysis complete
  - Macro 4D: High Wall ✓ / Resilient / Polarization Aligned / AI Tool
  - Quality: Deep Moat / Excellent Mgmt / Favorable / Healthy
  - Valuation: $28-$35 fair range (current $32)

Phase 3: Content generated
  - Report: Just学投资/Robinhood研究/Robinhood-财报分析-Q1-2026-20260515.md
  - Cards: 7 cards (cover + metrics + highlights + strategy + 4D + risks + valuation)
  - Article: 450 words, Just 60 style, compliance-checked ✓

Phase 4: HTML generated (Apple-style report + Xiaohongshu cards)
Phase 5: Publisher configured (20:30 scheduled)
Phase 6: Published to Xiaohongshu

Next quarter tracking:
1. Revenue: target $850M / alert <$800M
2. ARPU: target $115 / alert <$105
3. Net income margin: target 28% / alert <25%
```

## 与其他 Skill 的关系

| Skill | 关系 |
|-------|------|
| `earnings-analysis.md` | Phase 2.4 财报专项分析遵循其规范 |
| `value-research-company.md` | 完整研究类型遵循其全套流程 |
| `value-deep-research.md` | GATE 2 触发深度研究条件时，建议执行 `/value-deep-research` |
| `rednotearticle.md` | Phase 4.2 卡片 HTML 遵循其 v3.1 设计规范 |
| `publishrednote.md` | Phase 6 发布遵循其 v5.0 执行流程 |

**原有 Skill 保持不变**，本 Skill 是统一入口，内部按类型调用对应逻辑。

---

**Skill 版本**：1.1
**触发命令**：`/just-value-red-publish`
**更新日期**：2026-05-24
**关联框架**：`个股研究/思考架构/投资研究思想框架.md`

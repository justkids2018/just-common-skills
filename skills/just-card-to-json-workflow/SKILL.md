---
name: just-card-to-json-workflow
description: 
	学习卡片端到端生产技能（精简版）：图片 + Markdown -> 热点 JSON -> HTML 打分校验 -> Admin 上传提交。
	用于把单张或批量卡片按统一门禁落地，包含分数阈值 >= 89。
---

# Card Production Workflow Skill

## 目标

1. Skill 目录存放“规则与模板 + 可移植校验页兜底”。
2. 评分页采用“双入口”：项目路径优先，skill 内置副本兜底。
1. 卡片目录下图片与 Markdown 已就绪
2. 图片自动规范化（默认 `1024x1024`）
3. 图片自动压缩（目标 `<= 200KB`，像素不变）
1. 评分页项目入口（优先）：`kiki_web/doc/card-generation/hotspot-preview.html`
2. 评分页 skill 入口（兜底）：`.github/skills/just-card-to-json-workflow/templates/hotspot-preview.html`
3. Skill 模板目录：`.github/skills/just-card-to-json-workflow/templates/`
4. 模板仅做初始化与约束，不替代真实产物目录。

## 触发

强触发词：
4. `templates/hotspot-preview.html`：可移植评分页副本（换仓库时可直接使用）

1. "卡片全流程"
2. "从 prompt 到 admin"
3. "图片+md 生成 json"
4. "图片转 json 再校验"
5. "89 分门槛"
6. "学习卡片 workflow"
7. "学习卡片生产流程"
8. "学习法卡片 workflow"
9. "卡片生成并上传"
10. "一张卡从出图到提交"

## 一句话触发模板（可直接复制）

### 目录模式（推荐）

```text
请按卡片全流程跑目录：card_dir=<绝对或相对目录>，门槛=89分
```

### 目录模式示例

```text
请按卡片全流程跑目录：card_dir=kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_01_操场晨练，门槛=89分
```

### 场景目录批量模板

```text
请按卡片全流程批量跑目录：scene_dir=<绝对或相对目录>，门槛=89分
```

### 场景目录批量示例

```text
请按卡片全流程批量跑目录：scene_dir=kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣，门槛=89分
```

### 兼容模式（旧参数仍可用）

```text
请按卡片全流程跑这张卡：scene_slug=<scene_slug>，card_slug=<card_slug>，ext=<png|jpg>，门槛=89分
```

说明：

1. 不需要手动写 skill 名字。
2. 只要命中触发词，系统自动路由到本 skill。
3. 本 skill 默认不负责出图；要求图片已在目录中。
4. 优先使用目录模式（只给目录即可继续执行后续）。
5. 本 skill 默认自动完成“尺寸校验 + 压缩 + 评分循环 + 结果评价”。

## 输入

主输入（推荐其一）：

1. `card_dir`：单卡目录，目录内包含一对同名 `*.md` + `*.png|*.jpg|*.jpeg`
2. `scene_dir`：场景目录，目录下每个子目录视为一张卡

兼容输入（旧模式）：

1. `scene_slug`
2. `card_slug`
3. 图片扩展名（默认 `jpg`）

前置条件（必须满足）：

1. 卡片目录内存在且仅定位到一个主 Markdown（推荐同名）
2. 卡片目录内存在且仅定位到一个主图片（`png/jpg/jpeg`，推荐同名）

可选输入：

1. `baseRoot`（默认 `kiki_web/doc/card-generation/scene-info`）
2. 是否批量执行
3. `门槛`（默认 89）
4. `image_size`（可选；未指定时默认 `1024x1024`）
5. `image_max_kb`（可选；未指定时默认 `200`）

## 目录约束

目录优先约束：

1. 单卡：`<card_dir>/`
2. 批量：`<scene_dir>/<card_slug>/`

每张卡目录建议文件：

1. `<card_slug>.md`
2. `<card_slug>.png|jpg|jpeg`
3. `<card_slug>.json`（由流程生成）

命名容错：

1. 若目录中存在多个 md 或多个图片，视为歧义并 `BLOCKED`
2. 若 md 与图片不同名，允许继续但会在输出中标记 `DONE_WITH_CONCERNS`

## Skill 资产布局（省 token / 易维护）

原则：

1. Skill 目录存放“规则与模板 + 可移植校验页兜底”。
2. 评分页采用“双入口”：项目路径优先，skill 内置副本兜底。

规范路径：

1. 评分页项目入口（优先）：`kiki_web/doc/card-generation/hotspot-preview.html`
2. 评分页 skill 入口（兜底）：`.github/skills/just-card-to-json-workflow/templates/hotspot-preview.html`
3. Skill 模板目录：`.github/skills/just-card-to-json-workflow/templates/`
4. 模板仅做初始化与约束，不替代真实产物目录。

模板文件约定：

1. `templates/json-item-template.json`：单词条 JSON 骨架（含 `card` + `object`）
2. `templates/batch-run-template.md`：批量任务最小输入模板
3. `templates/report-template.md`：批量执行最小结果模板
4. `templates/hotspot-preview.html`：可移植评分页副本（换仓库时可直接使用）

## 执行流程

### Step 1: 输入文件验证

1. 根据 `card_dir/scene_dir` 定位目标卡目录
2. 自动发现主 `md` 与主图片
3. 任一缺失或歧义则 `BLOCKED`

### Step 2: 图片预检与规范化（自动）

默认规则：

1. 未显式指定尺寸时，目标尺寸固定为 `1024x1024`
2. 若图片不是目标尺寸，先做尺寸规范化
3. 若用户显式给了尺寸要求（如 `image_size`），以用户要求为准

尺寸门禁：

1. 最终用于评分和交付的图片尺寸必须等于目标尺寸
2. 尺寸不满足且无法修复时，`BLOCKED`

### Step 3: 图片压缩（自动）

默认规则：

1. 未显式指定体积阈值时，目标 `<= 200KB`
2. 压缩时不改变像素尺寸（保持 Step 2 的目标尺寸）
3. 优先通过质量参数/编码方式压缩，不做二次降采样

压缩策略：

1. 逐步降低质量（如 95 -> 90 -> 85 ...）
2. 必要时切换更高压缩率编码（仍保持同尺寸）
3. 在可读性可接受前提下尽量逼近阈值

结果判定：

1. `<= 阈值`：通过
2. 若视觉质量保护下仍略高于阈值：标记 `DONE_WITH_CONCERNS`
3. 若完全无法生成可用文件：`BLOCKED`

### Step 4: 图片 + MD 转 JSON

调用 `just-hotspot-generator`：

1. 输入图片路径
2. 输入 Markdown 路径
3. 输出同目录 JSON（默认同名前缀）
4. 若需初始化，优先复用 `templates/json-item-template.json`，再填充词条与坐标

JSON 结构硬约束（默认强制）：

1. 根节点必须是数组，采用词条分组结构（`item + regions`）
2. 每个词条默认必须生成 2 个热区：
	- `region_type = "card"`（标签卡区域）
	- `region_type = "object"`（物体主体区域）
3. `card` 与 `object` 共用同一词条 `id`，不得拆分成两个词条
4. 坐标必须是 4 点矩形且为整数，基于 `1024x1024` 坐标系
5. 若某词条确实无法安全生成 `object`（主体过小/遮挡/高误触风险），允许降级为仅 `card`，但必须：
	- 在结果中标记该词条为 `object_skipped`
	- 在总状态输出 `DONE_WITH_CONCERNS`
	- 禁止静默省略 `object`

两类热区语义定义（必须理解并执行）：

1. `card` 是“标签卡片本体”热区，不是箭头、不是真实物体。
2. `object` 是“真实物体主体”热区，不是标签卡、不含大面积背景。
3. 两者服务同一词条：点击 `card` 或 `object` 都触发同一词条内容。
4. 允许 `card` 与 `object` 位置相距较远（标签常漂浮在空白区），但语义必须一一对应。

`card` 定位规则（优先级从高到低）：

1. 以三行文本卡片外接框为准（拼音/汉字/英文在同一卡片内）。
2. 框必须完整包住卡片四边与文本，不切字。
3. 不要把箭头头部、相邻卡片、物体主体一起框进 `card`。
4. 推荐留白：相对卡片边缘外扩 4-12px（1024 基准），保证触控稳定。

`object` 定位规则（优先级从高到低）：

1. 先找“该词条箭头落点”，再从落点向内扩展到物体主体。
2. 仅覆盖该物体可识别主体，不吞并其他词条对象。
3. 对于细长/斜向目标（旗杆、绳子等），优先覆盖可点击主干区而不是整条极端细线。
4. 对于承载物（讲台、课桌、跑道等），框主体功能区域，避免把附属小物（粉笔、书签）一起包入。
5. 对于超小目标（哨子、瓢虫等），可适度放大 10-20% 触控缓冲，但不得跨到相邻对象中心区。

几何与质量约束（在 1024 坐标系下）：

1. `card` 最小尺寸：`48x48`；`object` 最小尺寸：`36x36`。
2. 同词条 `card` 与 `object` 不要求重叠，但禁止完全相同坐标（疑似复制）。
3. 跨词条热区重叠占比应 `<= 10%`；超过则视为高误触风险，必须调整。
4. `object` 中心点应落在目标物体可见区域；若中心点落在背景，视为无效标注。

场景化判定示例（用于减少“实物对象不对”）：

1. 升旗场景：
	- 国旗 `object` 应落在旗面主体，不是旗杆。
	- 旗杆 `object` 应落在杆身中段，不是顶部球头。
	- 话筒 `object` 应落在麦克风与支架连接主体，不是人物脸部。
2. 晨读场景：
	- 黑板 `object` 框黑板板面主体，不含整面墙。
	- 粉笔 `object` 可只框粉笔盒/粉笔主体，不应覆盖讲台大区域。
3. 手工场景：
	- 剪刀/画笔/胶水等 `object` 应尽量贴合器具主体，避免把整张桌面当对象。

失败回退策略（必须显式）：

1. 若 `object` 语义不确定，先依据箭头落点重标一次。
2. 若仍不确定，输出 `object_skipped` 并给出原因（遮挡/过小/箭头错误），禁止伪造 `object`。
3. 出现 `object_skipped` 时，结果状态必须为 `DONE_WITH_CONCERNS`，且在输出中列出词条清单。

## Token 与性能优化（默认开启）

1. 批量场景先做一次目录索引，再逐卡处理，禁止每张卡重复全量扫描。
2. Markdown 只提取词条必要行（`- [pinyin] / 汉字 / English`），不重复读取整文件上下文。
3. 评分阶段仅输出关键字段：`card_slug`、`score`、`PASS/FAIL`、`object_skipped_count`。
4. 失败重试只针对失败卡，最大重试 2 轮，禁止全量重跑。
5. 日志采用“汇总 + 异常明细”两层结构，避免逐卡长篇解释。
6. 输出 JSON 时不回显整文件内容，只给路径与统计，减少上下文占用。

## 批量快跑协议（scene_dir）

1. 预检阶段：一次性产出 `manifest`（卡目录、主 md、主图、现有 json 状态）。
2. 生成阶段：按 `manifest` 顺序生成/修复 JSON，默认并行策略为“读并行、写串行”。
3. 校验阶段：批量评分后仅回写失败卡；通过卡不重复编辑。
4. 汇报阶段：使用 `templates/report-template.md` 的最小字段输出，默认不展开大段说明。

### Step 5: HTML 评分校验（自动循环）

按以下顺序执行评分页（项目优先，skill 兜底）：

1. `kiki_web/doc/card-generation/hotspot-preview.html`
2. `.github/skills/just-card-to-json-workflow/templates/hotspot-preview.html`（当项目内不存在时）

1. 打开可用的校验页
2. 自动填充或映射到当前卡目录中的图片与 JSON
3. 加载叠层并检查评分

门禁：

1. 分数 >= 89
2. PASS

不满足时：

1. 优先调整 JSON
2. 仍不通过则回退修正 Markdown 或更换图片后重跑
3. 自动循环执行，直到：
	- 达到门槛并 PASS，或
	- 达到最大重试次数并判定 `BLOCKED`

### Step 6: 结果固化与评价（自动）

1. 产出最终图片与最终 JSON（同目录同名前缀）
2. 输出流程评价（如：尺寸合规、压缩效果、评分质量、风险项）
3. 评分通过即视为可交付生成完成

### Step 7: Admin 提交（可选人工）

1. 登录后台详情页
2. 点击添加
3. 上传同名图片与 JSON
4. `type` 固定为 `chinese`
5. 提交

说明：

1. 若用户未要求 Admin 操作，Step 7 可跳过
2. 默认以“生成完成 + 校验通过 + 给出评价”为主交付

## 输出

最小输出：

1. 卡目录路径
2. 最终图片路径
3. 最终 JSON 路径
4. 图片规格结果（目标尺寸、最终尺寸、最终体积KB）
5. 评分结果（分数 + PASS/FAIL）
6. 流程评价（1-3句，含风险提示）
7. Admin 提交状态（已提交/待提交/未要求）
8. JSON 结构统计（词条数、`card` 数、`object` 数、`object_skipped` 数）

## 状态定义

1. `DONE`：评分 >= 门槛，图片尺寸满足目标，图片体积满足阈值，且 JSON 满足结构约束（默认每词 `card+object`）
2. `DONE_WITH_CONCERNS`：评分 >= 门槛，但存在可接受告警（如体积略超阈值、未要求 Admin、或存在 `object_skipped`）
3. `BLOCKED`：评分 < 门槛、关键输入缺失、或尺寸/文件处理失败

## 反模式（禁止）

1. ❌ 未评分直接上传 Admin
2. ❌ 评分 < 89 仍提交
3. ❌ 图片和 JSON 文件不同名
4. ❌ 跳过 `just-hotspot-generator` 结构检查
5. ❌ 依赖本 skill 自动打开浏览器或自动出图
6. ❌ 目录中多 md/多图片却不先消歧
7. ❌ 为了压缩体积而改变目标像素尺寸
8. ❌ 未经用户要求擅自使用非目标尺寸
9. ❌ 在未说明原因的情况下省略 `object` 热区

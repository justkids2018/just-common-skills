---
name: just-card-to-json-workflow
description: 学习卡片固定流程（简明版）：先生成 1024x1024 的派生图（质量优先、体积尽量小）-> 基于派生图做大模型解析 -> 按固定合同输出 JSON -> HTML 验收。
---

# Card Production Workflow Skill

## 固定目标

这是一个固定流程，不做额外扩展。

1. 图片先标准化到 1024x1024 像素，再按“质量优先”策略尽量压缩体积（不设 200KB 硬阈值）
2. 原图不可变：只读使用，不允许覆盖原始主图
3. 大模型只基于“新生成的派生图”做解析（不是原图）
4. JSON 严格按固定合同输出
5. JSON 内容必须包含：图片文字语义 + card/object 坐标
6. MD 只负责词条语义比对，不负责几何坐标
7. 最后用 HTML 校验页验收
8. 当用户要求“重新验证/二次解析”时，必须重新看图并更新坐标，禁止只做 JSON 格式校验后直接结束

## 分层原则（必须遵守）

本 skill 采用“两层模型”，防止每次执行漂移：

1. 智能层（可变）：图片解析、目标定位、语义匹配策略
2. 合同层（不可变）：JSON 字段结构、字段命名、字段类型、必填项、取值约束

结论：

1. 允许优化“怎么识别图片”
2. 不允许改动“API 输出长什么样”
3. 任何场景都必须先满足合同层，再讨论评分和质量

## 输入

必须输入：

1. 一张主图（png/jpg/jpeg）
2. 一份主 md（词条来源）
3. 一个目标卡目录（card_dir）或场景目录（scene_dir）

可选输入：

1. `preview_page_path`：显式指定 HTML 验收页路径（跨仓库时推荐）

目录要求：

1. 单卡目录内必须且只能有 1 个主 md、1 个主图
2. 批量模式下每个子卡目录都必须满足上述要求
3. 任一卡目录不满足即该卡 BLOCKED
4. 标准化后的派生图默认写入当前卡目录：`<card_dir>/<card>.normalized.<ext>`

主 MD 命名与使用约束（新增硬规则）：

1. 主 md 固定为 `<card>.md`（例如 `kik_数学思维_01_数字乐园.md`）
2. 词条语义只允许从 `<card>.md` 提取
3. `prompt.md` 视为脚本/提示辅助文件，不是词条来源
4. 执行中禁止新建、覆盖、改写 `prompt.md`

## 固定三步法

### Step 1: 先生成 1024x1024 像素的新图，再做质量优先压缩（越小越好）

Step 1 预检门禁（建议脚本化，先于大模型执行）：

1. 先检查派生图是否已满足：`1024x1024` 且文件可读
2. 若满足：默认可直接复用该派生图
3. 若用户要求“重压缩/进一步优化体积”，即使已满足也可再执行一轮质量优先压缩
4. 若不满足：先执行标准化与压缩，生成新派生图
5. 只有预检通过后，才允许进入 Step 2 大模型解析

1. 读取主图（只读），不得改动原始主图文件
2. 先将派生图标准化到 1024x1024 像素
3. 再在不破坏可读性的前提下压缩派生图体积，目标是“越小越好”
4. 派生图默认路径：`<card_dir>/<card>.normalized.png`

强约束：

1. 不允许改成非 1024x1024
2. 不允许通过强失真换体积
3. 不设置 200KB 硬阈值；若可读性优先下体积仍较大，允许继续并输出真实体积及压缩率
4. 禁止覆盖、重命名、删除原始主图
5. 禁止把派生图写到其他目录（例如 `runs`）；必须与原图同目录

推荐脚本检查项（最小）：

1. `pixelWidth == 1024 && pixelHeight == 1024`
2. 输出 `file_size_before_kb`、`file_size_after_kb`、`reduction_ratio`
3. 输出 `PASSED/REGENERATED/BLOCKED` 三态（仅当图片不可读或标准化失败时 BLOCKED）

质量优先压缩方法（默认策略）：

1. 先做无损优化：去除冗余元数据、`optimize=true`、高压缩级别
2. 再做渐进降体积：优先调色板量化（颜色数从高到低逐步尝试），每轮都校验可读性
3. 若仍需下降体积：再启用轻度有损中转（例如 JPEG 中转后回写 PNG），并限制在“文字边缘清晰、主体不糊”的质量门槛内
4. 一旦出现明显锯齿、色块、文字发糊，立即回退到上一轮结果
5. 无论是否达到某个体积目标，都以“可读性达标 + 当前最小体积”作为 Step 1 输出
6. 推荐直接复用模板脚本：`.github/skills/just-card-to-json-workflow/templates/quality-first-compress.py`

执行稳定性（防阻断）规则：

1. 清理中间文件命令必须使用空匹配安全写法（例如 zsh 的 `*.tsv(N)`），避免 `no matches found` 导致中断
2. 在 zsh 中禁止使用只读变量名 `status`，统一使用 `run_state` 或 `step_state`
3. 长链路校验命令必须拆成短命令分步执行；若单条命令长时间无输出，应立即切换分步执行
4. HTML 验收若出现页面句柄失效（如 `pageId not found`），必须自动重开预览页后重试，不得直接判定 BLOCKED
5. 非合同类质量问题（如体积偏大、`max_dx>120`、重叠风险）默认降级为 DONE_WITH_CONCERNS，不得直接 BLOCKED

### Step 2: 基于新图进行大模型解析（识别文字与坐标）

二次深度重解析模式（新增硬规则）：

1. 触发条件：用户明确提到“重新解析/重标坐标/第二次验证/再看一遍图/坐标不对”
2. 触发后行为：即使 `<card>.json` 已存在，也必须重新基于派生图做 8 个词条的 `card/object` 定位
3. 旧 JSON 的用途仅限字段复用（如 `audio_*`），不得直接复用旧 `regions` 作为结果
4. 二次解析默认覆盖写回 `regions`，并在输出里说明“本次已重解析并覆盖坐标”
5. 禁止“只校验 JSON 合同就宣告完成”；未做重解析时不得标记 DONE

坐标生产方式约束（新增硬规则）：

1. 坐标必须由大模型视觉识别产生（基于图片语义与箭头关系）
2. 可以使用 OCR 作为文字定位辅助，但不得由脚本模板/固定网格自动推导坐标
3. 禁止使用 Python/OpenCV 规则化几何推导替代视觉解析结论
4. 脚本只允许用于校验与统计，不得作为坐标主来源

解析输入源锁定规则（强制）：

1. 只允许使用 Step 1 产出的派生图进行识别
2. 禁止回退到原图进行识别
3. 若派生图不存在或不可读，直接 BLOCKED

1. 每个词条必须生成两个区域：
   - card：标签卡片区域
   - object：真实物体主体区域
2. 坐标必须来自图片定位，不允许用模板网格或固定偏移硬填
3. 区域语义必须一一对应：同词条的 card/object 指向同一词条
4. `card/object` 配对质量必须通过：
   - 两者中心点横向偏移不得超过 120px（防止配错列）
   - 若超阈值，至少标记 DONE_WITH_CONCERNS；明显错配则 BLOCKED

引线锚点辅助定位（推荐策略）：

1. 先框 `card`：以白色文字卡片主体为准，不把下方实体并入 `card`
2. 再看引线：优先以引线箭头尖端/落点附近作为 `object` 搜索锚点
3. `object` 以引线落点附近的数字实物主体为准，避免框到无关背景或其他词条
4. 若引线较长导致横向偏移较大，应优先保证语义正确，并在结果中标记 DONE_WITH_CONCERNS

强约束：

1. 坐标必须为整数
2. 坐标必须在 [0,1023]
3. 每个区域必须是 4 点矩形
4. 点顺序固定：左上、右上、左下、右下

公共解析图片 Prompt（首轮/二轮通用）：

1. 模板文件固定使用：`.github/skills/just-card-to-json-workflow/templates/image-parse-prompt-template.md`
2. 首轮解析与二次重解析都必须使用同一模板，不允许每次临时改写语义规则
3. 模板实例化仅允许替换输入参数，不允许改动合同约束段落

模板调用参数（最小集）：

1. `parse_mode`：`first_parse` 或 `reparse`
2. `image_path`：Step 1 产出的 `<card>.normalized.png` 绝对路径
3. `card_name`：卡片名（用于日志与输出说明）
4. `expected_item_count`：词条目标数量（由 `vocab_lines` 实际行数计算）
5. `vocab_lines`：从 `<card>.md` 第 III 节提取的 N 行词条
6. `existing_json_hint`：可选；仅用于保留 `audio_*`，不得复用旧 `regions`

调用规则：

1. 第一次解析：`parse_mode=first_parse`
2. 第二次解析：`parse_mode=reparse`，必须覆盖写回全部 `regions`
3. 两次都只允许输出最终 JSON，不输出解释性段落
4. 输出数组长度必须等于 `expected_item_count`

### Step 3: 输出标准 JSON（按固定合同）

MD 使用规则：

1. 仅从章节 III 词条行提取：`- [pinyin] / 汉字 / English (/phonetic/)`
2. MD 只提供语义字段：`text`、`text_pinyin`、`text_english`、`text_phonetic`
3. MD 不参与坐标计算

中间产物清理规则（新增硬规则）：

1. 默认不保留中间分析文件（如 `*.md-parse.tsv`、`*.md-json-compare.tsv`、临时导出文件）
2. 验收结束后应自动清理上述中间文件
3. 必须保留：`<card>.png|jpg|jpeg`（原图）、`<card>.normalized.png`（派生图）、`<card>.md`、`<card>.json`
4. 若目录本来存在 `prompt.md`，允许保留但禁止改写；禁止新增 `prompt.md`
5. 禁止生成执行报告文件（如 `执行报告.txt`、`执行报告.md`、`report-*.md`）

Step 2 解析结果必须至少提供：

1. 卡片文字相关内容（与词条语义一致）
2. `card` 与 `object` 两类坐标
3. 若为二次解析，需明确输出 `reparse=true`（或同义说明）与“覆盖词条数（例如 N/N）”

JSON 固定合同（不可变）：

1. 根节点是数组
2. 每个词条对象必须包含：
   - type（固定 chinese）
   - id（chinese_01, chinese_02 ...）
   - index（1..N 连续）
   - text（中文词）
   - text_pinyin
   - text_english
   - text_phonetic
   - regions
3. regions 子项只允许：
   - region_type
   - coordinate
4. 禁止输出 `region.id` 等临时字段
5. 若旧 JSON 里已有 audio 字段（audio_cn_key/url、audio_en_key/url），重生成时必须保留

字段语义澄清（必须严格区分）：

1. 顶层 `type` 只有一个固定值：`chinese`
2. “两个区域类型”不是顶层 `type`，而是 `regions[].region_type`
3. `regions[].region_type` 只允许两个值：
   - `card`：汉字标签卡片区域
   - `object`：真实实物主体区域
4. 每个词条默认必须同时有 `card` + `object` 两个区域
5. 禁止把 `card/object` 写到顶层 `type`

## API 合同冻结规则

以下内容视为冻结，不得随任务波动：

1. 顶层字段集合与命名
2. `type/id/index` 规则
3. `regions` 子结构与坐标点顺序
4. `audio_*` 保留策略

若确实要改合同：

1. 必须由用户明确提出“修改 API 合同”
2. 必须在文档中新增“合同版本变更记录”
3. 未满足前两条时，一律按当前合同执行

## 验收（HTML）

评分页发现顺序（通用，不绑项目名）：

1. 若传入 `preview_page_path`，优先使用该路径
2. 在当前仓库自动查找以下候选文件名（取首个存在项）：
   - `**/doc/card-generation/hotspot-preview.html`
   - `**/docs/card-generation/hotspot-preview.html`
   - `**/hotspot-preview.html`
3. 若仓库内未找到，回退到 skill 内置模板：`.github/skills/just-card-to-json-workflow/templates/hotspot-preview.html`
4. 若仍不存在，判定 `BLOCKED`（提示用户提供 `preview_page_path` 或补齐模板）

一键验证跳转页规则（新增硬规则）：

1. 生成 `一键验证.html` 时，`baseRoot`、`image`、`json` 必须使用绝对路径（例如 `/Users/.../scene-info/...`）
2. 跳转到 `hotspot-preview.html` 的目标地址必须是绝对 URL（例如 `file:///.../hotspot-preview.html?...`）
3. 禁止输出仅依赖 `scene-info/...` 的相对路径参数
4. 必须附带 `mode=oneclick`，进入精简验收模式（不显示路径配置区）
5. 推荐使用模板：`.github/skills/just-card-to-json-workflow/templates/one-click-verify.html`

oneclick 模式最小功能集（固定 6 项）：

1. 加载并绘制
2. 开始编辑 / 结束编辑
3. 一键复制当前最新 JSON
4. 一键放大 / 一键缩小
5. 下载 JSON
6. 返回原始坐标

通过条件：

1. 分数 >= 89 且 PASS
2. JSON 合同校验通过
3. 人工语义复核通过（card/object 与词条语义一致）
4. 若用户要求二次解析：必须有“重新看图并覆盖坐标”的执行证据

说明：

1. 100 分主要是结构/几何分，不等于语义 100% 正确
2. 若结构分高但语义不对，必须降级为 DONE_WITH_CONCERNS 或 BLOCKED

## 执行边界

1. 用户给 `scene_dir`，只允许修改该目录
2. 禁止跨场景改写
3. 执行前必须打印目标目录与将修改文件数

执行前自检（每次必做）：

1. 本次是否只在用户指定目录内改动
2. 本次是否仅改智能层，未改 API 合同
3. 产出 JSON 是否逐项通过合同校验
4. 若评分高但语义不对，是否已降级而不是强行 DONE
5. 原始主图是否保持不变（mtime/hash 未变化）

## 输出（最小）

1. 卡目录路径
2. 原始图片路径（只读）
3. 派生图片路径、尺寸、体积（含 before/after 与压缩率）
4. 最终 JSON 路径
5. 评分结果（score + PASS/FAIL）
6. JSON 结构统计（items/card/object/object_skipped）
7. 状态（DONE / DONE_WITH_CONCERNS / BLOCKED）
8. 结果只在对话中返回；不落地执行报告文件

## 反模式（禁止）

1. 未做 Step 1 直接生成 JSON
2. 用模板坐标/固定网格伪造定位
3. 只看评分，不看 JSON 合同
4. 只看结构，不做人眼语义复核
5. 用户只给 scene_02 却改动其他 scene
6. 把验收页硬编码到某个项目路径（例如固定 `kiki_web/...`）
7. 未经用户明确授权擅自改动 API 字段或字段语义
8. 为了压缩体积直接覆盖或删除原始主图
9. 解析某卡图片却把派生图写到该卡目录之外
10. 把 `prompt.md` 当作词条主 md 读取
11. 运行中生成或改写 `prompt.md`
12. 验收结束后仍遗留中间分析文件
13. 用户要求二次解析，却仅复用旧 JSON 坐标并做格式校验
14. 用脚本自动推导坐标替代大模型视觉定位
15. 未重新看图就声称“坐标已重标完成”
16. 在卡目录或模板目录生成/保留执行报告文件

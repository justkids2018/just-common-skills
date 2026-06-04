---
name: just-hotspot-generator
description: 
	从 1024x1024 场景图 + 词汇 Markdown 自动生成 items_data 热区 JSON（词条分组结构）。
	目标是输出可直接给前端使用的数据，并强制执行精度校验与人工复核门禁。
---

# Hotspot Generator Skill

## 目标

输入场景图和词汇文档，输出高精度热区 JSON：

1. 采用词条分组结构（词条级公共 id + regions）
2. 每个词至少 1 个 `card` 热区
3. 可选 `object` 热区（主体清晰时）
4. 坐标严格基于 1024x1024 像素网格

## 分层原则（防漂移）

1. 可变层：图片解析与定位算法（可优化）
2. 不可变层：JSON API 合同（字段、命名、取值、结构）

执行规则：

1. 可以优化识别策略，但不能改输出合同
2. 若需改 API 合同，必须由用户明确提出并确认

## 原图保护（强制）

1. 原始输入图只读，不允许覆盖、删除、重命名
2. 标准化图必须另存为派生文件
3. 默认派生图路径：`doc/card-generation/runs/<scene>/<card>.normalized.png`
4. 报告中必须同时输出原图路径与派生图路径

## 触发

强触发词：

- "根据图片自动生成热区"
- "生成 items_data"
- "图片+MD 产 JSON"
- "自动标注 card/object 区域"
- "1024x1024 热区坐标"

## 输入

必须输入：

1. 场景图片路径（本地文件）
2. 词汇 Markdown 路径（通常为场景 prompt 或词汇表）
3. 场景名（用于命名输出文件）

推荐输入：

1. 目标输出路径
2. 是否开启 object 热区（默认开启）

## 输出

固定产物：

1. `items_data` JSON 文件
2. 生成报告（含精度检查与风险项）
3. H5 对照校验截图（至少 1 张）

默认路径：

1. JSON：`kiki_web/assets/data/<scene>/kiki_<scene>.json`
2. 报告：`kiki_web/doc/card-generation/runs/<scene>/hotspot-report.md`
3. 校验页：`kiki_web/doc/card-generation/hotspot-preview.html`
4. 截图：`kiki_web/doc/card-generation/runs/<scene>/preview-verify.png`

## 数据结构（强制）

输出必须符合词条分组结构：

```json
[
	{
		"type": "chinese",
		"id": "chinese_01",
		"index": 1,
		"text": "球",
		"text_pinyin": "qiú",
		"text_english": "Ball",
		"text_phonetic": "/bɔːl/",
		"regions": [
			{
				"region_type": "card",
				"coordinate": [
					{ "x": 100, "y": 100 },
					{ "x": 200, "y": 100 },
					{ "x": 100, "y": 200 },
					{ "x": 200, "y": 200 }
				]
			},
			{
				"region_type": "object",
				"coordinate": [
					{ "x": 120, "y": 220 },
					{ "x": 230, "y": 220 },
					{ "x": 120, "y": 330 },
					{ "x": 230, "y": 330 }
				]
			}
		]
	}
]
```

固定合同补充（必须遵守）：

1. `id` 必须为 `chinese_XX` 顺序编号，并与 `index` 对齐
2. `text` 仅存中文词，不拼接拼音/英文
3. `regions` 子项只允许 `region_type` 与 `coordinate`
4. `coordinate` 点顺序固定：左上、右上、左下、右下
5. 不得输出额外临时字段（例如 `region.id`）
6. 如输入旧 JSON 含音频字段，重写时需原样保留

## 语义与几何职责分离（必须遵守）

1. MD 负责语义：词条文本、拼音、英文、音标、词条顺序
2. 图片负责几何：`card/object` 的实际空间位置与坐标
3. 任何时候都不得用 MD 文本直接推导几何坐标
4. 任何时候都不得用图片识别结果反写词条文本语义

固定生成顺序：

1. 先解析 MD 词条集合
2. 再读取图片做定位
3. 最后组装 JSON 并做合同校验
4. 校验通过后再进入评分页

## 执行流程

### Step 1: 输入与尺寸校验

1. 校验图片存在且可读取
2. 若不是 `1024x1024`，先生成 `1024x1024` 的派生图
3. 后续定位、评分只使用派生图，不使用原图
4. 若派生图生成失败，直接 `BLOCKED`

### Step 2: 词汇提取

1. 从 MD 中提取词条（中文/拼音/英文/音标）
2. 保证 index 连续，从 1 开始
3. 若字段缺失，标记为 `DONE_WITH_CONCERNS`

默认解析协议（`hi_kiki_scene_v1`）：

1. 优先在章节 `### III. <N> Target Vocabulary Objects` 下提取词条
2. 词条匹配格式：`- [pinyin] / 汉字 / English (/phonetic/)`
3. 解析字段映射：
	- `text_pinyin` <- `[...]`
	- `text` <- `汉字`
	- `text_english` <- `English`
	- `text_phonetic` <- `(/.../)`（可空）
4. 输出字段固定：`type=chinese`、`id=chinese_XX`、`index=<1..N>`、`text/text_pinyin/text_english/text_phonetic`
5. `regions` 项仅允许：`region_type`、`coordinate`
6. `coordinate` 四点顺序固定：左上、右上、左下、右下
7. 声明数量 `<N>` 必须等于提取数量；不一致标记 `DONE_WITH_CONCERNS`
8. 若章节 III 不存在，可回退全文提取，但必须在报告中标注 `fallback_parse=true`
9. 若提取后词条数为 0，直接 `BLOCKED`

### Step 3: 区域生成

1. 对每个词生成 `card` 区域（强制）
2. 主体清晰时生成 `object` 区域（可选）
3. 坐标规则：
	 - 整数像素
	 - 全部位于 [0, 1023]
	 - 四点顺序固定：左上、右上、左下、右下
4. 配对规则（防错配）：
	 - 同词 `card` 与 `object` 的中心点横向偏移 <= 120px
	 - 超阈值必须标记风险并进入人工复核，不得直接 DONE

### Step 4: 精度检查（强制）

必须执行：

1. 边界检查：不得越界
2. 面积检查：
	 - card 最小面积建议 >= 48x48
	 - object 最小面积建议 >= 36x36
3. 重叠检查：不同词之间重叠面积占比建议 < 10%
4. 误触检查：大物体不得吞并邻近小物体
5. 配对检查：逐词确认 `card/object` 为同一目标，不得跨列、跨行错配

### Step 5: H5 对照校验（强制）

1. 打开 `kiki_web/doc/card-generation/hotspot-preview.html`
2. 加载本次图片与 JSON
3. 对照检查：
	- card 区域是否准确覆盖标签卡片
	- object 区域是否准确覆盖物体主体
	- 词与词之间是否存在明显误触冲突
4. 产出至少 1 张截图作为验收证据

评分解释（必须说明）：

1. H5 分数优先反映结构正确性，不直接证明语义 100% 正确
2. `100 分` 仅表示格式/几何规则满足，不代表 object 一定命中正确实物
3. 必须执行人工语义复核（词条-标签-实物三者一致）后才可判定最终可交付

### Step 6: 输出与复核门禁

1. 写入 JSON
2. 写入 `hotspot-report.md`（包含每词区域、重叠率、风险项）
3. 保存 H5 对照截图路径
3. 输出状态：
	 - `DONE`: 全部通过
	 - `DONE_WITH_CONCERNS`: 有风险但可用
	 - `BLOCKED`: 尺寸错误或关键字段缺失

## 精度基线（1024x1024）

为了保证点击准确率：

1. `card` 热区优先于 `object` 热区
2. 小物体允许仅保留 `card`
3. 复杂遮挡场景应缩小或取消 `object`
4. 不允许跨词语义重叠（例如黑板区覆盖粉笔词）

## 失败处理

出现以下任一情况必须停止并返回 `BLOCKED`：

1. 图片不可读取，或无法生成 1024x1024 派生图
2. 无法提取词条
3. 生成后所有区域越界或冲突严重
4. `card/object` 明显错配（跨词、跨列、语义不一致）

并给出下一步建议：

1. 先生成 1024x1024 派生图再重试
2. 补全词汇字段
3. 人工微调冲突区域

补充：

1. 若图片压缩无法在可读性前提下降到 `<=200KB`，应真实上报体积并标记 concern
2. 禁止“分数高”掩盖语义错误或压缩失真问题
3. 禁止以任何理由改写原始输入图

## Three-Question Design Test

### Q1: What exact job does this skill perform?
Generate high-precision hotspot JSON (items_data structure) from a 1024x1024 scene image and vocabulary Markdown. Output includes mandatory `card` regions and optional `object` regions per vocabulary item, with enforced accuracy checks and H5 preview verification.

### Q2: When should it activate? List at least 5 trigger phrases.
1. "generate hotspots from this image"
2. "create items_data JSON" or "produce hotspot JSON"
3. "image + MD to JSON" or "auto-annotate regions"
4. "generate card/object regions" or "hotspot coordinates needed"
5. "1024x1024 hotspot generation"

### Q3: What does perfect output look like? Include one concrete output example.
Perfect output includes: valid items_data JSON with grouped vocabulary structure, hotspot-report.md with accuracy metrics (overlap rates, boundary checks), and H5 preview screenshot showing accurate card/object region alignment.

Example:
```
✅ Hotspot Generation: DONE

Scene: classroom
Vocabulary: 12 items extracted
Output: kiki_web/assets/data/classroom/kiki_classroom.json

Accuracy Checks:
- Boundary: All regions within [0, 1023] ✓
- Area: card >= 48x48, object >= 36x36 ✓
- Overlap: Max 8% between items ✓
- H5 Preview: doc/card-generation/runs/classroom/preview-verify.png ✓

Report: doc/card-generation/runs/classroom/hotspot-report.md
Status: DONE
```

## 反模式（禁止）

1. ❌ 输出旧扁平结构作为主结果
2. ❌ 生成坐标时使用浮点数
3. ❌ 不做重叠检查直接落盘
4. ❌ 未校验 1024x1024 就继续
5. ❌ 把 `object` 热区强加给所有词


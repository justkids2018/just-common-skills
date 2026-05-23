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

## 执行流程

### Step 1: 输入与尺寸校验

1. 校验图片存在且可读取
2. 校验像素尺寸必须是 `1024x1024`
3. 若尺寸不符，直接 `BLOCKED`，禁止继续

### Step 2: 词汇提取

1. 从 MD 中提取词条（中文/拼音/英文/音标）
2. 保证 index 连续，从 1 开始
3. 若字段缺失，标记为 `DONE_WITH_CONCERNS`

### Step 3: 区域生成

1. 对每个词生成 `card` 区域（强制）
2. 主体清晰时生成 `object` 区域（可选）
3. 坐标规则：
	 - 整数像素
	 - 全部位于 [0, 1023]
	 - 四点顺序固定：左上、右上、左下、右下

### Step 4: 精度检查（强制）

必须执行：

1. 边界检查：不得越界
2. 面积检查：
	 - card 最小面积建议 >= 48x48
	 - object 最小面积建议 >= 36x36
3. 重叠检查：不同词之间重叠面积占比建议 < 10%
4. 误触检查：大物体不得吞并邻近小物体

### Step 5: H5 对照校验（强制）

1. 打开 `kiki_web/doc/card-generation/hotspot-preview.html`
2. 加载本次图片与 JSON
3. 对照检查：
	- card 区域是否准确覆盖标签卡片
	- object 区域是否准确覆盖物体主体
	- 词与词之间是否存在明显误触冲突
4. 产出至少 1 张截图作为验收证据

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

1. 图片不是 1024x1024
2. 无法提取词条
3. 生成后所有区域越界或冲突严重

并给出下一步建议：

1. 修正图片尺寸
2. 补全词汇字段
3. 人工微调冲突区域

## 反模式（禁止）

1. ❌ 输出旧扁平结构作为主结果
2. ❌ 生成坐标时使用浮点数
3. ❌ 不做重叠检查直接落盘
4. ❌ 未校验 1024x1024 就继续
5. ❌ 把 `object` 热区强加给所有词


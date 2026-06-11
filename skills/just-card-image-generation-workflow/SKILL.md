---
name: just-card-image-generation-workflow
description: >
  卡片主 Prompt 图片生成技能：从 scene-info 下的 <card>.md 主卡片 prompt 生成 <card>.png，
  严格以 <card>.md 为唯一事实源，进行场景、风格、尺寸、词条、标签、箭头、人物与小猫的视觉验证；
  验证不通过时优先做局部修正，仅在内容偏离 md、缺失核心对象、风格或构图整体失败时才整图重生成。
---

# Card Prompt -> Image -> Visual Validation Workflow

## 目标

1. 只读取主卡片 prompt：`<card_dir>/<card>.md`。
2. 严格根据 `<card>.md` 生成学习卡片主图，不允许按经验、历史图片或通用模板替换 md 内容。
3. 保存为 `<card_dir>/<card>.png`。
4. 验证图片是否逐项满足 `<card>.md` 中的场景、风格、角色、词条、标签、箭头和质量门。
5. 若验证不通过，先判断能否只修正标签、文字或箭头；不能局部修正时才整图重生成。
6. 不把未通过验证的图进入 JSON 流程。
7. Token 优化不能牺牲第一次图片生成完整性；第一次出图必须使用完整主 prompt。

## 触发

强触发词：

1. 根据卡片 prompt 生成图片
2. `<card>.md` 生成 `<card>.png`
3. 学习卡片图片生成
4. 卡片 prompt 出图并检查
5. scene-info 批量生成图片
6. 图片不满意重新生成

## 输入

必填其一：

1. `card_dir`：单张卡目录，例如 `.../kik_日常生活_01_超市购物`
2. `scene_dir`：场景目录，例如 `.../scene_03_日常生活`

可选：

1. `max_attempts`：每张卡单轮最多生成次数，默认 3。
2. `overwrite`：是否覆盖已有 `<card>.png`，默认否；若用户明确要求重新生成，则允许覆盖。
3. `save_rejected`：是否保留失败候选图，默认否。
4. `strict_size`：是否强制最终 `<card>.png` 为 1024x1024，默认是。
5. `cooldown_seconds`：图片生成/编辑请求之间的默认冷却秒数，默认 10；用户明确要求快速处理时可用 5。
6. `local_fix_first`：是否优先局部修正标签、箭头、局部文字，默认是。

## 主文件规则

1. 主 prompt 固定为 `<card>.md`，例如 `kik_日常生活_01_超市购物.md`，它是唯一事实源。
2. `prompt.md` 只是兼容副本，不作为主输入。
3. 禁止把 `prompt.md` 当词条来源。
4. 禁止新建或改写 `prompt.md`，除非用户明确要求同步兼容副本。
5. 每个卡目录只处理与目录同名的 `<card>.md` 和 `<card>.png`。
6. 禁止使用“上一张图”“类似场景”“模型默认理解”覆盖 `<card>.md` 的主题、词表或对象规则。
7. 若用户口头描述与 `<card>.md` 冲突，先报告冲突并以 `<card>.md` 为准；除非用户明确要求先修改 md。

## 固定流程

### Step 1: 预检主 prompt

1. 确认 `<card>.md` 存在。
2. 提取 ```text fenced code block；若不存在，读取完整 md 但标记 `DONE_WITH_CONCERNS`。
3. 从 `<card>.md` 提取“生成合同”，至少包含：
   - `theme`：主题/场景名
   - `style_lock`：风格锁定要求
   - `resolution`：尺寸要求
   - `characters`：姐姐、妹妹、小猫规则
   - `vocabulary`：8 个 `[pinyin] / 汉字 / English`
   - `object_rules`：每个目标物体的放置/区别规则
   - `label_rules`：标签卡规则
   - `arrow_rules`：箭头规则
   - `quality_gate`：DIRTY TEXT SCAN / COUNT CHECK / MAPPING CHECK 等质量门
4. 检查必须包含：
   - `Resolution: exact 1024x1024 pixels`
   - `premium miniature toy diorama`
   - `Exactly 8 target objects, 8 label cards, 8 arrows`
   - `older sister`
   - `younger sister`
   - `white kitten`
   - `DIRTY TEXT SCAN`
5. 统计词表行：`- [pinyin] / 汉字 / English (/phonetic/)`，期望为 8。
6. 输出或内部记录一份简短 `md_contract`，后续生成、验收、局部修正都只能围绕这份合同执行。
7. 若主 prompt 不满足以上关键项，先停止并报告，不直接出图。

### Step 2: 生成图片

1. 使用主 prompt 的 fenced code block 原文作为图片生成输入。
2. 外层只允许追加一条执行约束：
   - `Follow the following image prompt exactly. The <card>.md content is the only source of truth. Do not substitute the theme, objects, labels, arrows, characters, or style with prior examples or generic assumptions. Style Lock overrides any wording that could be interpreted as real photography.`
3. 第一次生成必须保持完整性：不得为了省 token 删除风格、角色、8 个词条、标签、箭头、质量检查或场景约束。
4. 禁止人工重写、删减或改义主 prompt；除非主 prompt 本身过长导致工具拒绝，此时只能做等价压缩，并必须保留全部硬性约束。
5. 若当前环境有图片生成工具，直接调用该工具生成。
6. 若当前环境没有图片生成能力，状态为 `BLOCKED`，提示用户需要可用图片模型。

### Step 3: 落盘

1. 将通过初检的候选图复制到 `<card_dir>/<card>.png`。
2. 不删除图片生成工具的原始输出文件。
3. 若输出不是 1024x1024，但为正方形且内容完整，允许复制后标准化到 1024x1024。
4. 原始候选图若不在卡目录，不得移动，只能复制。
5. 若已有 `<card>.png` 且 `overwrite=false`，不要覆盖，先询问或生成候选但不落正式文件。

### Step 4: 视觉验证

必须实际查看生成图，不能只检查文件存在。

必须把图片逐项对照 `md_contract`，不是只看“像不像学习卡片”。

检查项：

1. 尺寸：最终 `<card>.png` 必须是 1024x1024。
2. 主题：图片主场景必须与 `<card>.md` 的主题一致，不能生成其他场景、相邻场景或历史示例场景。
3. 风格：必须符合 `<card>.md` 的风格锁定，尤其是高质感玩具微缩场景，不是真实摄影、真人照片、普通场景快照。
4. 角色：必须符合 `<card>.md` 的角色规则，恰好 2 个女孩 + 1 只白色小猫；姐姐长发散着，妹妹双马尾。
5. 穿搭：必须符合 `<card>.md` 的穿搭规则，阳光、清爽、快乐、开心、积极；不能灰暗、成人化或攻击性。
6. 数量：必须与 `<card>.md` 一致，8 个目标物体、8 张标签卡、8 根箭头。
7. 词条：图片中的 8 个目标物体必须逐项等于 `<card>.md` 的 8 个词条，不允许替换、增删、合并或使用近义物。
8. 标签：每张卡只有三行 `[pinyin] / 汉字 / english`，内容必须逐项等于 `<card>.md`，无 citation/ref/source/序号污染。
9. 箭头：每根箭头触达 `<card>.md` 对应目标物体本体，不悬空、不指背景、不明显错配。
10. 对象规则：每个物体必须符合 `<card>.md` 的 object_rules，例如“宝箱”和“金币”必须分开时不能合并。
11. 构图：完整使用画布，有前景/中景/后景，不拥挤到影响识别。

md 对齐验收表：

| 项目 | 判定 |
| --- | --- |
| `theme` | 图片主题是否等于 `<card>.md` 主题 |
| `style_lock` | 图片风格是否等于 md 风格锁 |
| `characters` | 人物与小猫是否等于 md 角色规则 |
| `vocabulary` | 8 个目标物体是否逐项等于 md 词表 |
| `label_rules` | 8 张标签是否逐项等于 md 标签内容和格式 |
| `arrow_rules` | 8 根箭头是否逐项指向 md 对应物体本体 |
| `object_rules` | 物体区分、放置和可识别性是否满足 md |
| `quality_gate` | DIRTY TEXT / COUNT / MAPPING / ARROW / VISUAL 是否全部通过 |

### Step 5: 缺陷分级

验证失败后先分级，不要默认整图重生成。

局部可修正缺陷：

1. 标签文字有错别字、拼音错误、英文大小写/标点污染，但目标物体正确存在。
2. 标签卡名称和箭头所指物体不一致，但正确目标物体在图中清晰存在。
3. 箭头落点偏移、悬空、指到邻近物体或背景，但标签和目标物体都正确存在。
4. 单个标签卡覆盖目标物体、箭头交叉或局部排版拥挤，但主体画面、8 个对象和角色正确。
5. 少量局部文字污染，例如 `UFO.` 多了句点；可只重绘该标签。

必须整图重生成缺陷：

1. 风格整体错误：真实摄影、真人照片、普通快照、非玩具微缩场景。
2. 画布或尺寸错误且裁切后无法保持完整内容。
3. 角色硬性错误：不是 2 个女孩 + 1 只白色小猫，或角色遮挡大量核心对象。
4. 主题或场景与 `<card>.md` 不一致，例如 md 要“超市购物”却生成“公园/真实照片/其他场景”。
5. 目标物体缺失、重复、被替换，导致图片内容和 `<card>.md` 词表不一致，且无法通过局部标签/箭头修正。
6. 对象规则和 md 冲突，例如 md 要两个物体分离但图片合并成一个，或 md 要玩具化但图片是真实物体。
7. 多数标签/箭头混乱，局部修正会破坏画面或成本高于重生成。

## 局部修正规则

若失败属于“局部可修正缺陷”：

1. 不整图重生成，优先对已有 `<card>.png` 或候选图做局部编辑。
2. 修正范围必须限制在失败区域：标签卡、标签文字、箭头线条、箭头端点，或很小的局部遮挡区域。
3. 未失败区域必须保持不变：背景、人物、小猫、正确对象、正确标签和正确箭头不得重绘。
4. 修改卡片名称时，只改错误标签文本，不改词表、不改其他标签、不改主 prompt。
5. 修改指引标记时，只重画该标签对应箭头，使箭头端点落到正确目标物体本体。
6. 若覆盖已有正式 `<card>.png`，先复制备份为 `<card>.before-local-fix.png`；确认修正通过后可保留或按用户要求清理。
7. 能用确定性图像处理脚本完成时，优先用脚本修正标签/箭头；脚本无法自然擦除旧箭头或旧文字时，再使用局部图像编辑工具。
8. 若需要局部图像编辑工具，指令必须包含：
   - `Preserve the entire image except the specified label/arrow correction area.`
   - `Do not change characters, background, object positions, or other labels/arrows.`
9. 若当前环境没有可靠的局部编辑能力，保留当前最佳图并报告 `DONE_WITH_CONCERNS` 或请求用户确认是否整图重生成。
10. 局部修正完成后仍需实际查看图片，并重新检查尺寸、标签、箭头和对象映射。
11. 若图片中的实际物体不是 `<card>.md` 要求的物体，不能只改标签文字伪装通过；必须标记为 md 内容不一致并整图重生成。

局部修正示例：

```text
Fix only the [yǔ háng yuán] / 宇航员 / Astronaut arrow. Preserve the entire image except this arrow. Move the arrow endpoint so it lands directly on the astronaut toy helmet or suit body. Do not change any other label, arrow, object, character, kitten, or background.
```

## 整图重生成规则

仅当缺陷属于“必须整图重生成缺陷”，或局部修正失败且用户接受重生成时，才执行整图重生成。

1. 不进入 JSON workflow。
2. 记录失败原因，例如：
   - `风格偏真实摄影`
   - `少了白色小猫`
   - `标签数量不是 8`
   - `零食箭头指到购物袋`
   - `文字出现污染标记`
   - `图片主题和 <card>.md 不一致`
   - `实际物体不是 <card>.md 词表要求的物体`
3. 下一次生成时，仍使用主 prompt 原文，但在外层追加“失败修正约束”。
4. 修正约束只能强化失败项，不能改变词表、API 合同或主 prompt 语义。
5. 默认每张卡最多尝试 3 次；若仍不通过，保留最佳候选并让用户选择继续生成或人工接受。

失败修正约束示例：

```text
Previous attempt failed because: Snack arrow landed on the shopping bag. Regenerate with Snack and Shopping Bag separated, and make the Snack arrow land on the snack pack body only.
```

## 冷却与限流策略

1. 默认请求间隔为 10 秒；用户明确要求快速处理时，单张或局部编辑可用 5 秒。
2. 禁止并发调用图片生成/编辑；批量模式也必须串行。
3. 不要无条件等待 240 秒；只有实际遇到 rate limit、服务端 429、或连续服务端错误时才延长。
4. 自适应退避建议：
   - 正常成功：等待 `cooldown_seconds`。
   - 第一次限流/服务端繁忙：等待 30 秒。
   - 第二次连续限流/服务端繁忙：等待 60 秒。
   - 第三次连续限流/服务端繁忙：等待 120 秒，并标记该卡 `BLOCKED` 或等待用户确认继续。
5. 局部修正优先于整图重生成，因为它更省 token、保留大部分正确画面，也降低再次出错概率。

## Token 使用策略

1. 第一次图片生成：不省关键 prompt，必须使用完整主 prompt，保证风格、角色、词条、标签、箭头和质量门完整。
2. 预检阶段：只读取主 prompt 的必要结构和 8 个词条，不展开无关历史或旧 `prompt.md`，但必须形成 `md_contract`。
3. 视觉校验阶段：输出短结论优先；通过时只报告尺寸、8 个对象/标签/箭头、角色和状态。
4. 失败分析阶段：只描述失败项，不重复描述正确项。
5. 局部修正阶段：只构造失败区域的最小修正指令，不重新粘贴完整主 prompt。
6. 整图重生成阶段：才重新使用完整主 prompt，并只追加失败修正约束。
7. 批量模式：跳过已有且未被指出问题的 PNG；只处理缺失图或用户点名的问题图。

## 批量模式

当输入 `scene_dir`：

1. 只处理该目录下每个子目录的 `<card>.md`。
2. 默认跳过已有 `<card>.png` 的卡，除非用户要求重新生成。
3. 每张卡独立执行生成与验证。
4. 任一卡局部失败时，先尝试局部修正；局部修正不可用时标记 `DONE_WITH_CONCERNS` 或按用户要求整图重生成。
5. 任一卡失败不应中断整批；标记该卡 `BLOCKED` 或 `DONE_WITH_CONCERNS`，继续下一张。
6. 批量结束后输出每张卡状态，不生成执行报告文件。

## 与其他技能的衔接

1. 本 skill 只负责 `<card>.md -> <card>.png`。
2. 图片通过后，再交给 `just-card-to-json-workflow` 生成 `<card>.normalized.png` 与 `<card>.json`。
3. JSON 通过后，再交给 `just-card-audio-qiniu-workflow` 生成 `<card>_audio.json`。

## 输出最小格式

每张卡输出：

1. `card_dir`
2. `prompt_path`
3. `image_path`
4. `image_size`
5. `attempts`
6. `local_fixes`
7. `md_contract_check`
8. `validation_result`
9. `status`: `DONE` / `DONE_WITH_CONCERNS` / `BLOCKED`
10. 若失败，列出失败原因、md 不一致项、缺陷分级、局部修正结果和下一次建议。

## 禁止项

1. 禁止把 `prompt.md` 当主 prompt。
2. 禁止没看图就声称验证通过。
3. 禁止失败图直接进入 JSON workflow。
4. 禁止为了一次成功而删减词表、减少标签或移除箭头。
5. 禁止把真实摄影风格当作通过。
6. 禁止在批量模式中跨出用户指定的 `scene_dir`。
7. 禁止因为一个标签或箭头小错就直接整图重生成；必须先做缺陷分级。
8. 禁止局部修正时改变未失败区域。
9. 禁止生成或验收时脱离 `<card>.md`，不能用历史示例、相邻场景或主观判断替代 md。
10. 禁止“物体错了但标签改对”这类伪通过；实际物体必须和 md 词表一致。

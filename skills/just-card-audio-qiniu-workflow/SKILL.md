---
name: just-card-audio-qiniu-workflow
description: >
  卡片 JSON 音频生产技能：从 JSON 中提取中文与英文词条，使用微软 Edge TTS 生成音频，上传到七牛 kiki/audio/ 目录，
  并可回写 audio URL 到 JSON。
---

# Card JSON -> Audio -> Qiniu Workflow Skill

## 目标

1. 读取卡片 JSON 中中文与英文文本字段。
2. 使用微软免费语音能力（Edge TTS）生成中英音频。
3. 上传到七牛目录 `kiki/audio/`（可配置 key 前缀）。
4. 可选产出审计清单（manifest），可选回写音频 URL 到原 JSON。

## 触发

强触发词：

1. 卡片 JSON 生成语音
2. JSON 中文英文转语音上传七牛
3. 把卡片词条做成音频并上传 /audio
4. Edge TTS 批量音频上传
5. 卡片音频生产流水线

## 输入

必填：

1. `json_path`：卡片 JSON 路径

可选：

1. `api_base`：后端地址（默认 `http://127.0.0.1:8080`）
2. `token_source`：`auto|api|direct`（默认 `auto`，推荐）
2. `auth_token`：管理端鉴权 token（若接口有鉴权）
3. `key_prefix`：七牛 key 前缀（默认 `kiki/audio`）
4. `zh_voice`：中文 voice（默认 `zh-CN-XiaoyiNeural`，偏儿童感）
5. `en_voice`：英文 voice（默认 `en-US-AnaNeural`，偏儿童感）
6. `writeback_json`：是否把音频 URL 回写到 JSON
7. `output_json_path`：回写目标 JSON 路径（与 `writeback_json` 一起使用；设置后不改原文件）
8. `public_base_url`：回写 URL 的公网前缀（默认 `http://img.mtrain.xyz`，与现有图片一致）
9. `upload_url_override`：可覆盖上传地址（当音频上传 endpoint 与图片不同）
10. `domain_override`：可覆盖 token 返回域名
11. `name_strategy`：音频命名策略，默认 `split`（中文文件名用中文词、英文文件名用英文词），可选 `concat|id`
12. `qiniu_access_key` / `qiniu_secret_key` / `qiniu_bucket`：直传模式凭证（不依赖服务）
13. `qiniu_domain` / `qiniu_upload_url`：直传模式域名与上传地址
14. `write_manifest`：是否生成 `<json>.audio-manifest.json`（默认不生成）

## 默认字段约定

从每个 item 提取：

1. 中文：`text`
2. 英文：`text_english`
3. ID：`id`（缺失时自动生成）

回写字段（开启 `writeback_json` 时）：

1. `audio_cn_key`
2. `audio_cn_url`
3. `audio_en_key`
4. `audio_en_url`

## 执行流程

### Step 1: JSON 校验

1. 根节点必须为数组。
2. item 必须为对象。
3. 若中英文都为空，标记 `skipped`。

### Step 2: 音频生成（Edge TTS）

1. 中文使用 `zh_voice`。
2. 英文使用 `en_voice`。
3. 每个 item 生成两条音频：`*_cn.mp3` 与 `*_en.mp3`（存在对应文本时）。

### Step 3: 上传七牛

1. `token_source=api`：调用后端 token 接口 `GET /api/v1/admin/upload/token`
2. `token_source=direct`：Python 本地用 AK/SK 直接生成 upload token（无需启动服务）
3. `token_source=auto`：先走 API，失败自动回退 direct
4. 使用 `token/upload_url/domain` 执行 multipart 上传。
5. 若配置了 `upload_url_override/domain_override`，优先使用覆盖值。
3. key 规则（默认 `split`）：`{key_prefix}/{json_stem}/{中文名-短哈希}_cn.mp3` 与 `{key_prefix}/{json_stem}/{英文名-短哈希}_en.mp3`
4. 示例（split）：`.../课本-a1b2c3_cn.mp3` 与 `.../textbook-a1b2c3_en.mp3`
5. 若设 `name_strategy=concat`，则使用旧规则：`.../{中文名-英文名-短哈希}_{cn|en}.mp3`
6. 若设 `name_strategy=id`，则回退为 `.../{item_id}_{cn|en}.mp3`

### Step 4: 结果产物

1. 若开启 `write_manifest`，生成同目录 manifest：`<json>.audio-manifest.json`
2. 若回写开启且未设置 `output_json_path`：先备份原 JSON，再写入音频字段。
3. 若回写开启且设置了 `output_json_path`：写入新文件，不修改原 JSON。

## 脚本

路径：

1. `.github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py`

依赖：

1. `pip install edge-tts requests`

示例（只生成并上传，不回写）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_03_晨读时光/kik_晨光乐趣_03_晨读时光.json \
  --api-base http://127.0.0.1:8080
```

示例（上传并回写 JSON）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_03_晨读时光/kik_晨光乐趣_03_晨读时光.json \
  --api-base http://127.0.0.1:8080 \
  --public-base-url http://img.mtrain.xyz \
  --writeback-json
```

示例（基于原 JSON 生成新文件 `<name>_audio.json`，不改原文件）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_01_操场晨练/kik_晨光乐趣_01_操场晨练.json \
  --token-source direct \
  --qiniu-access-key "$QINIU_ACCESS_KEY" \
  --qiniu-secret-key "$QINIU_SECRET_KEY" \
  --qiniu-bucket "$QINIU_BUCKET" \
  --qiniu-domain img.mtrain.xyz \
  --qiniu-upload-url https://up-z2.qiniup.com \
  --public-base-url http://img.mtrain.xyz \
  --writeback-json \
  --output-json-path kik_晨光乐趣_01_操场晨练_audio.json
```

示例（音频上传地址与图片不一致时）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_03_晨读时光/kik_晨光乐趣_03_晨读时光.json \
  --api-base http://127.0.0.1:8080 \
  --upload-url-override https://up-z2.qiniup.com \
  --domain-override img.mtrain.xyz \
  --public-base-url http://img.mtrain.xyz \
  --writeback-json
```

示例（纯 Python 直传，不依赖服务）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_01_操场晨练/kik_晨光乐趣_01_操场晨练.json \
  --token-source direct \
  --qiniu-access-key "$QINIU_ACCESS_KEY" \
  --qiniu-secret-key "$QINIU_SECRET_KEY" \
  --qiniu-bucket "$QINIU_BUCKET" \
  --qiniu-domain img.mtrain.xyz \
  --qiniu-upload-url https://up-z2.qiniup.com \
  --public-base-url http://img.mtrain.xyz \
  --writeback-json
```

## 常见问题

1. 401/403：补充 `--auth-token` 或确认管理接口权限。
2. edge-tts 缺失：`pip install edge-tts`。
3. 上传成功但 URL 访问失败：确认 `domain` 对应 CDN 域名已生效。
4. 想改目录到 `/audio/`：保持 `key_prefix=kiki/audio`（默认即此规则）。

## 边界说明

1. 本 skill 是“文本转语音（TTS）”，不是“语音转文字（ASR）”。
2. 若你要做 ASR（音频识别成文字），应单独新建 skill，不复用本流程。

## 儿童音色推荐

1. 中文首选：`zh-CN-XiaoyiNeural`
2. 中文备选：`zh-CN-XiaoxiaoNeural`
3. 英文首选：`en-US-AnaNeural`
4. 英文备选：`en-US-AriaNeural`

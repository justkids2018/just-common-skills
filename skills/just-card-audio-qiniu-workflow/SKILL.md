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

## 运行原则（本次优化）

1. 原始 JSON 默认不改动；推荐始终输出到新的 `_audio.json` 文件。
2. 批量执行应可重复（idempotent）；七牛返回 `614 file exists` 视为可复用成功，不应中断整批。
3. `output_json_path` 推荐使用文件名（如 `xxx_audio.json`）或绝对路径，避免传入“workspace 相对全路径”导致嵌套目录误写。
4. 音频生成后必须执行校验；不能只看到脚本 `DONE` 就结束。
5. 只要生成 `_audio.json`，必须同时生成同目录 `一键音频验证.html`，用于逐条点击播放中文/英文音频做人耳复核。

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
8. `public_base_url`：回写 URL 的公网前缀（默认 `http://img.keepthinking.me`，与现有图片一致）
9. `upload_url_override`：可覆盖上传地址（当音频上传 endpoint 与图片不同）
10. `domain_override`：可覆盖 token 返回域名
11. `name_strategy`：音频命名策略，默认 `split`（中文文件名用中文词、英文文件名用英文词），可选 `global_text|concat|id`
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
3. key 规则（推荐新批次使用 `global_text`）：`{key_prefix}/{中文名-文本音色哈希}_cn.mp3` 与 `{key_prefix}/{英文名-文本音色哈希}_en.mp3`
4. 示例（global_text）：`http://img.keepthinking.me/kiki/audio/购物车-a19f69_cn.mp3` 与 `http://img.keepthinking.me/kiki/audio/shopping-cart-b42c71_en.mp3`
5. `global_text` 的短哈希必须由 `语言 + 文本 + voice + rate` 生成；相同文本、相同音色、相同语速可跨卡复用，不同音色不得误复用。
6. 默认 `split` 保留旧兼容路径：`{key_prefix}/{json_stem}/{中文名-短哈希}_cn.mp3` 与 `{key_prefix}/{json_stem}/{英文名-短哈希}_en.mp3`
7. 若设 `name_strategy=concat`，则使用旧规则：`.../{中文名-英文名-短哈希}_{cn|en}.mp3`
8. 若设 `name_strategy=id`，则回退为 `.../{item_id}_{cn|en}.mp3`
9. 不允许只用纯 `{汉字}_cn.mp3` 或 `{english}_en.mp3` 且没有哈希；否则同名、同词不同音色、后续重生成都会产生覆盖风险。
10. 若返回 `614 file exists`，按“对象已存在”处理：继续回写 URL 并不中断当前批次。

### Step 4: 结果产物

1. 若开启 `write_manifest`，生成同目录 manifest：`<json>.audio-manifest.json`
2. 若回写开启且未设置 `output_json_path`：先备份原 JSON，再写入音频字段。
3. 若回写开启且设置了 `output_json_path`：写入新文件，不修改原 JSON。
4. 默认同时生成同目录 `一键音频验证.html`；页面必须能根据最终 `_audio.json` 列出每个词条，并提供中文/英文单条播放、顺播、下载入口。
5. 若确实不需要 HTML，可显式加 `--skip-verify-html`，但批量生产正式卡片时不允许跳过。

### Step 5: 音频校验（必须执行）

生成或上传完成后必须校验输出 `_audio.json`，批量模式每个文件都要校验。

结构校验：

1. `_audio.json` 必须存在。
2. 根节点仍然是数组，数组长度必须等于源 JSON。
3. 每个非 skipped item 必须包含：
   - `audio_cn_key`
   - `audio_cn_url`
   - `audio_en_key`
   - `audio_en_url`
4. `audio_*_key` 必须以 `kiki/audio/` 或当前 `key_prefix` 开头。
5. `audio_*_url` 必须以 `public_base_url` 开头，例如 `http://img.keepthinking.me/`。
6. 原 item 的业务字段、`regions`、`audio_*` 以外字段不得丢失。

远程可访问性校验：

1. 对每个 `audio_cn_url/audio_en_url` 发起 `HEAD` 请求；若 CDN 不支持 `HEAD`，改用带短超时的 `GET`。
2. 成功条件：
   - HTTP 状态为 `200` 或可接受的 `206`
   - `Content-Type` 包含 `audio` 或 URL 扩展名为 `.mp3`
   - 内容长度大于 0；若拿不到长度，至少确认请求可读取到首段字节
3. 若出现短暂 CDN 未刷新，可等待 3-10 秒后重试一次。
4. 若仍不可访问，标记该卡 `DONE_WITH_CONCERNS` 或 `BLOCKED`，并列出失败 URL。

语义校验：

1. 每条中文音频必须来源于 `text` 字段。
2. 每条英文音频必须来源于 `text_english` 字段。
3. 音频 key 命名应能回溯到当前 JSON stem 和词条，不允许跨卡复用错误 key。

最小校验脚本示例：

```bash
python - <<'PY'
import json, sys, urllib.parse, urllib.request
from pathlib import Path

src = Path(sys.argv[1])
audio = Path(sys.argv[2])
base = sys.argv[3].rstrip('/') + '/'
source = json.loads(src.read_text())
data = json.loads(audio.read_text())
errors = []
if len(source) != len(data):
    errors.append(('count_mismatch', len(source), len(data)))
for item in data:
    for key in ['audio_cn_key','audio_cn_url','audio_en_key','audio_en_url']:
        if not item.get(key):
            errors.append((item.get('index'), item.get('text'), 'missing', key))
    for key in ['audio_cn_url','audio_en_url']:
        url = item.get(key, '')
        if url and not url.startswith(base):
            errors.append((item.get('index'), item.get('text'), 'bad_base_url', url))
        if url:
            request_url = urllib.parse.quote(url, safe=':/?&=%#[]@!$&\\'()*+,;')
            try:
                req = urllib.request.Request(request_url, method='HEAD')
                with urllib.request.urlopen(req, timeout=8) as resp:
                    if resp.status not in (200, 206):
                        errors.append((item.get('index'), item.get('text'), 'bad_status', resp.status, url))
            except Exception:
                try:
                    req = urllib.request.Request(request_url, headers={'Range': 'bytes=0-0'})
                    with urllib.request.urlopen(req, timeout=8) as resp:
                        if resp.status not in (200, 206):
                            errors.append((item.get('index'), item.get('text'), 'bad_get_status', resp.status, url))
                except Exception as exc:
                    errors.append((item.get('index'), item.get('text'), 'unreachable', url, str(exc)))
if errors:
    print('AUDIO_VERIFY_FAILED', errors)
    sys.exit(1)
print('AUDIO_VERIFY_OK', audio, 'items=', len(data))
PY
```

## 推荐执行模式（保护原始文件）

1. 单文件：始终加 `--writeback-json --output-json-path <name>_audio.json`
2. 批量：逐文件执行时，`--output-json-path` 只传“文件名”，不传完整目录链。
3. 每个 `_audio.json` 生成后立即执行 Step 5 校验；失败时记录该文件，继续下一张，最后统一汇总。
4. 新场景或重跑音频时推荐加 `--name-strategy global_text`，让同一词条音频在所有卡片间复用，减少重复生成与上传。

## 脚本

路径：

1. `.github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py`

依赖：

1. `pip install edge-tts requests`

## 音频验证页面（新增）

模板路径：

1. `.github/skills/just-card-audio-qiniu-workflow/templates/audio-verify.html`

用途：

1. 校验 `_audio.json` 中 `audio_cn_url/audio_en_url` 是否可播放
2. 支持 HTTP/HTTPS 音频在线播放
3. 支持一键下载音频后本地复核

使用方式：

1. 打开模板页面后，输入 JSON 绝对路径 / `file://` / `http(s)://` 地址加载
2. 或直接选择本地 `_audio.json` 文件加载
3. 支持单条播放与“顺播全部中文/英文”

一键页面生成建议（写入绝对 JSON 地址）：

1. 复制模板到卡目录并命名 `一键音频验证.html`
2. 把页面中的 `DEFAULT_JSON_PATH` 改成该卡 `_audio.json` 的绝对路径
3. 直接双击打开即可开始验证

一键页面生成要求：

1. 每次生成 `_audio.json` 时必须生成或更新 `一键音频验证.html`。
2. 页面默认加载同目录最新 `_audio.json` 的绝对路径，并内嵌最终 JSON 内容，避免浏览器阻止读取本地 JSON 时无法验证。
3. 页面必须按 JSON 展示每个 item 的 `text`、`text_english`、`audio_cn_url`、`audio_en_url`。
4. 页面必须支持单条中文播放、单条英文播放、顺播全部中文、顺播全部英文、下载音频。
5. 页面只是人工播放复核入口，不能替代 Step 5 的程序化结构与 URL 校验。

示例绝对路径（scene_02）：

1. `/Users/qisd/Documents/development/my_project/kiki_chain/kiki_web/doc/card-generation/scene-info/scene_02_数学思维/kik_数学思维_06_比大小/kik_数学思维_06_比大小_audio.json`

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
  --public-base-url http://img.keepthinking.me \
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
  --qiniu-domain img.keepthinking.me \
  --qiniu-upload-url https://up-z2.qiniup.com \
  --public-base-url http://img.keepthinking.me \
  --writeback-json \
  --output-json-path kik_晨光乐趣_01_操场晨练_audio.json
```

示例（zsh 批量，直传模式，不改原文件）：

```bash
set -a; source kiki_server/.env; set +a
base="kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣"

find "$base" -type f -name '*.json' ! -name '*_audio.json' | sort | while IFS= read -r f; do
  out_name="$(basename "${f%.json}")_audio.json"
  python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
    "$f" \
    --token-source direct \
    --qiniu-access-key "$QINIU_ACCESS_KEY" \
    --qiniu-secret-key "$QINIU_SECRET_KEY" \
    --qiniu-bucket "$QINIU_BUCKET" \
    --qiniu-domain "$QINIU_DOMAIN" \
    --qiniu-upload-url "https://up-z2.qiniup.com" \
    --public-base-url "http://img.keepthinking.me" \
    --writeback-json \
    --output-json-path "$out_name"
  python - <<'PY' "$f" "$(dirname "$f")/$out_name" "http://img.keepthinking.me"
import json, sys
from pathlib import Path
src, audio, base = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3].rstrip('/') + '/'
s, a = json.loads(src.read_text()), json.loads(audio.read_text())
missing = []
if len(s) != len(a):
    missing.append(('count', len(s), len(a)))
for item in a:
    for key in ['audio_cn_key','audio_cn_url','audio_en_key','audio_en_url']:
        if not item.get(key):
            missing.append((item.get('index'), item.get('text'), key))
    for key in ['audio_cn_url','audio_en_url']:
        if item.get(key) and not item[key].startswith(base):
            missing.append((item.get('index'), item.get('text'), 'bad_url', item[key]))
if missing:
    print('AUDIO_JSON_VERIFY_FAILED', audio, missing)
    sys.exit(1)
print('AUDIO_JSON_VERIFY_OK', audio, 'items=', len(a))
PY
done
```

示例（音频上传地址与图片不一致时）：

```bash
python .github/skills/just-card-audio-qiniu-workflow/scripts/json_text_to_audio_qiniu.py \
  kiki_web/doc/card-generation/scene-info/scene_01_晨光乐趣/kik_晨光乐趣_03_晨读时光/kik_晨光乐趣_03_晨读时光.json \
  --api-base http://127.0.0.1:8080 \
  --upload-url-override https://up-z2.qiniup.com \
  --domain-override img.keepthinking.me \
  --public-base-url http://img.keepthinking.me \
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
  --qiniu-domain img.keepthinking.me \
  --qiniu-upload-url https://up-z2.qiniup.com \
  --public-base-url http://img.keepthinking.me \
  --writeback-json
```

## 常见问题

1. 401/403：补充 `--auth-token` 或确认管理接口权限。
2. edge-tts 缺失：`pip install edge-tts`。
3. 上传成功但 URL 访问失败：确认 `domain` 对应 CDN 域名已生效。
4. 想改目录到 `/audio/`：保持 `key_prefix=kiki/audio`（默认即此规则）。
5. 批量后出现嵌套目录：通常是 `--output-json-path` 传了完整相对路径；改为仅文件名或绝对路径。
6. 报 `614 file exists`：表示七牛对象已存在，当前脚本会按可复用成功处理并继续。

## 边界说明

1. 本 skill 是“文本转语音（TTS）”，不是“语音转文字（ASR）”。
2. 若你要做 ASR（音频识别成文字），应单独新建 skill，不复用本流程。

## 儿童音色推荐

1. 中文首选：`zh-CN-XiaoyiNeural`
2. 中文备选：`zh-CN-XiaoxiaoNeural`
3. 英文首选：`en-US-AnaNeural`
4. 英文备选：`en-US-AriaNeural`

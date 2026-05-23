# 小红书自动发布工具

将本地 HTML 卡片自动渲染成图片并发布到小红书。

---

## 目录结构

```
publish/
├── xiaohongshu-mcp          # MCP 服务二进制（原生 ARM64）
├── agent.js                 # 通用发布 Agent（推荐用这个）
├── publish.js               # 发布主脚本（旧，PDD 专用）
├── package.json             # npm 脚本入口
├── templates/
│   └── article.html         # Just 品牌卡片模板（固定样式，不要改 CSS）
├── images/                  # 自动生成的卡片图片（不提交 git）
└── data/                    # 登录 cookies（不提交 git）
```

---

## 首次使用

### 第一步：启动 MCP 服务

在 `publish/` 目录打开**终端 A**，让它持续运行：

```bash
cd ~/Documents/development/ai/invest/小白学投资/publish
./xiaohongshu-mcp
```

看到以下日志说明启动成功：

```
msg="Registered 13 MCP tools"
msg="启动 HTTP 服务器: :18060"
```

> 首次运行会自动下载 Chromium（约 150MB），等下载完再继续。

### 第二步：扫码登录

在**终端 B** 执行：

```bash
cd ~/Documents/development/ai/invest/小白学投资/publish
npm run login
```

- 会自动打开二维码图片（`qr-login.png`）
- 用**小红书 App** 扫码登录
- 二维码有效期约 **2 分钟**，过期重新执行 `npm run login`

> ⚠️ 扫码期间不要在浏览器网页端登录同一账号，否则会被踢出（手机 App 不影响）

### 第三步：确认登录

```bash
npm run check
# 输出: ✅ 已登录
```

---

## 工作流一：文章发布（推荐）

适用于：**将研究笔记 / 分析文章转换为小红书帖子**

### 整体流程

```
研究笔记 / 分析文章
       ↓
[Claude] /rednote-article  (Just 品牌风格转换)
       ↓
生成 cards.html  (填入 templates/article.html 的内容)
       ↓
node agent.js --html cards.html --title "..." --content "..." --tags "..."
       ↓
Puppeteer 截图 → Preview 预览 → 终端 [y/N] 确认 → 发布到小红书
```

### Step 1：用 `/rednote-article` 转换文章

在 Claude 中执行：

```
/rednote-article
[粘贴你的研究笔记或文章]
```

Claude 会输出结构化内容：

```
【封面标题】认真研究了这家公司
【封面副标题】公司研究 · 2025年Q1
【小红书标题】花了一周看完这份财报，有几个想法
【正文】最近认真看了...（400-700字正文，发布 content 字段用）
【内容分段】
段落一：...
---
段落二：...
【标签】#投资 #公司研究 #财报分析
```

### Step 2：生成 cards.html

参考 `templates/article.html`，填入内容（**CSS 不要改，只替换占位内容**）：

- `{{COVER_TITLE}}` → 封面大标题（≤15字）
- `{{COVER_SUBTITLE}}` → 封面副标题（如 "公司研究 · 2025年Q1"）
- `{{SECTION_1}}`、`{{SECTION_2}}` → 各段正文（~250-300字/段）
- `{{TOTAL}}` → 总卡片数

可以要求 Claude 直接生成完整的 HTML 文件。

### Step 3：截图 + 发布

```bash
# 确保 MCP 服务在跑（终端 A）
./xiaohongshu-mcp

# 截图预览，不发布（终端 B）
node agent.js --html /path/to/cards.html --no-publish

# 正式发布
node agent.js \
  --html /path/to/cards.html \
  --title "花了一周看完这份财报，有几个想法" \
  --content "最近认真看了..." \
  --tags "投资,公司研究,财报分析"
```

---

## 工作流二：HTML 卡片发布

适用于：**已有设计好的 cards.html，直接发布**（如公司研究卡片）

```bash
node agent.js \
  --html ../拼多多公司研究/cards.html \
  --title "认真研究了拼多多，好的坏的都告诉你" \
  --content "最近..." \
  --tags "拼多多,美股,公司研究"
```

---

## agent.js 参数说明

```
node agent.js --html <文件路径> [选项]

必填：
  --html <path>         HTML 文件路径（含 .card-page 元素）

可选：
  --title "..."         帖子标题（默认: "Just · 研究分享"）
  --content "..."       帖子正文（放在图片下方）
  --tags "a,b,c"        话题标签，英文逗号分隔（默认: "投资,Just"）
  --no-original         不声明原创（默认声明原创）
  --no-publish          只截图预览，不发布
```

---

## 常用命令速查

| 命令 | 说明 |
|------|------|
| `./xiaohongshu-mcp` | 启动 MCP 服务（须持续运行） |
| `npm run login` | 获取登录二维码 |
| `npm run check` | 检查登录状态 |
| `node agent.js --html <file> --no-publish` | 只截图预览 |
| `node agent.js --html <file> --title "..." --content "..." --tags "..."` | 截图 + 发布 |
| `npm run render` | 渲染 PDD 卡片（旧流程） |
| `npm run publish` | 发布 PDD（旧流程） |

---

## 故障排查

**问题：`npm run check` 显示 ❌ 未登录**

重新扫码：
```bash
npm run login
```

**问题：发布超时或失败**

1. 检查 MCP 服务是否还在运行（终端 A 有无报错）
2. 重启 MCP 服务并重新登录
3. 确认图片路径是否正确（agent.js 会打印图片保存路径）

**问题：MCP 服务崩溃重启**

```bash
pkill xiaohongshu-mcp 2>/dev/null; ./xiaohongshu-mcp
```

登录状态会自动从 `data/cookies.json` 恢复，无需重新扫码。

**问题：二维码过期**

二维码仅 2 分钟有效，重新执行：
```bash
npm run login
```

**问题：卡片截图空白或字体不显示**

霞鹜文楷从 CDN 加载，需要网络连接。agent.js 已设置 2 秒字体加载等待时间，通常足够。

---

## templates/article.html 使用说明

这是 **Just 品牌标准卡片模板**，样式固定，不要修改 CSS。

卡片规格：
- 宽度 **390px**，截图分辨率 3x（1170px），适配小红书高清显示
- 封面卡（`#c1`）：暖灰底 `#EBEBEB`，霞鹜文楷大标题
- 内容卡（`#c2+`）：暖白底 `#FFFCF8`，正文 + Just 品牌页脚

**让 Claude 填充内容**：

> 把上面 rednote-article 的输出给 Claude，说：
> "参考 `templates/article.html` 的样式，生成一个完整的 cards.html，
> 封面标题是「...」，副标题是「...」，内容分成 N 张卡片，保存到「XX目录/cards.html」"

Claude 会保持 CSS 不变，只填入内容。

---

## 技术说明

- **MCP 服务**：`xiaohongshu-mcp` 是从 [xpzouying/xiaohongshu-mcp](https://github.com/xpzouying/xiaohongshu-mcp) 编译的原生 ARM64 二进制，通过 Chromium 无头浏览器操作小红书网页
- **图片渲染**：`agent.js` 用 Puppeteer 打开 HTML，对每个 `.card-page` 元素截图（3x 分辨率，适配高清屏）；无 `.card-page` 则全页截图
- **发布协议**：通过 MCP 协议（HTTP 18060 端口）调用 `publish_content` 工具，超时 300 秒
- **字体**：霞鹜文楷 (LXGW WenKai Screen)，从 jsDelivr CDN 加载，免费可商用

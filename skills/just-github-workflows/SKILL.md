---
name: just-github-workflows
description: >
  GitHub Actions CI/CD 工作流复制能力：把 Android APK 打包、iOS 打包、
  Docker 镜像构建+部署、Flutter CI 校验四条 workflow 模板化，
  可快速迁移到新项目。涵盖 Secrets 配置清单、工作目录适配、镜像命名规则。
---

# just-github-workflows

## 技能目录结构

```
just-github-workflows/
├── SKILL.md                    ← 本文档（Agent 引导流程 + 配置清单）
├── workflows/                  ← 可直接复制到新项目的 workflow 模板
│   ├── ci-validate.yml         ← Flutter 静态分析，每次 push/PR 触发
│   ├── android-release.yml     ← APK + AAB 签名打包
│   ├── ios-release.yml         ← IPA 签名打包（macOS runner）
│   └── docker-release.yml      ← 构建镜像推 GHCR + SSH 部署
└── scripts/                    ← 通用部署脚本（配合 just-deploy-release）
    ├── step1-prepare.sh
    ├── step2-deploy.sh
    ├── db-release.sh
    ├── docker-compose.yml
    ├── bin/common.sh
    └── profiles/
        └── example.env
```

---

## 占位符速查表

所有 yml 模板用 `YOUR_*` 标记需要修改的位置，Agent 收集好参数后直接替换，不要让用户手动改。

| 占位符 | 含义 | 示例值 |
|--------|------|--------|
| `YOUR_FLUTTER_DIR` | Flutter 项目子目录 | `my_app` |
| `YOUR_ORG` | GitHub 组织或用户名 | `mycompany` |
| `YOUR_PROJECT` | 项目名（用于镜像命名） | `my-project` |
| `YOUR_BACKEND_DIR` | 后端服务子目录 | `server` |
| `YOUR_ADMIN_DIR` | Admin 前端子目录 | `admin` |
| `YOUR_API_DOMAIN` | 后端 API 域名（无 `/api` 后缀） | `api.myapp.com` |
| `YOUR_DOMAIN` | 主域名（用于部署摘要） | `myapp.com` |

---

## Agent 执行流程

> 收到 "帮我配 CI/CD"、"新项目配 workflow"、"部署到服务器" 等意图时，
> **不要直接粘贴文档**，按以下 5 步主动引导。

### Step 1 — 确认需要哪些 workflow

一次性问清楚（用户不一定需要全部四个）：

| Workflow | 适用场景 | 备注 |
|----------|----------|------|
| [A] CI 校验 | 每次 push 自动跑 flutter analyze | 几乎所有 Flutter 项目都要 |
| [B] Android 打包 | 自动生成签名 APK / AAB | 需要有 Android Keystore |
| [C] iOS 打包 | 自动生成签名 IPA | 需要 Apple 开发者账号，macOS runner 额外计费 |
| [D] Docker + 部署 | 构建镜像并自动部署到服务器 | 需要有服务器和 SSH 访问权限 |

### Step 2 — 收集项目参数（一次问完）

根据用户选了哪些 workflow，询问以下对应参数：

| 参数 | 问法示例 | 用于 |
|------|----------|------|
| Flutter 子目录名 | "你的 Flutter 代码在仓库哪个子目录里？在根目录就填 `.`" | A/B/C |
| GitHub 用户名/组织名 | "仓库 URL `github.com/<这里>/xxx` 里的那部分" | D |
| 项目英文名 | "你的项目英文名叫什么？用于 Docker 镜像命名，如 `myapp`（小写字母加连字符）" | D |
| 后端代码目录名 | "后端服务（有 Dockerfile）的子目录叫什么？" | D |
| Admin 前端目录名 | "Admin 管理界面（有 Dockerfile）的子目录叫什么？" | D |
| API 域名 | "后端 API 的域名，比如 `api.myapp.com`，不含 `/api`" | D |

### Step 3 — 直接生成适配好的 yml

**不要让用户自己替换占位符。** 把收集到的参数直接替换 `workflows/` 模板里的 `YOUR_*`，输出完整、可直接使用的 yml 内容。

文件放置位置：`<仓库根目录>/.github/workflows/<文件名>.yml`

### Step 4 — 逐条引导 Secrets 配置

不要一次堆完所有 Secret。按用户选的 workflow，**一条一条**告诉用户：
- 这个 Secret 叫什么名字
- 它是什么，用来干什么
- **用什么命令来获取或生成它**（见下方各 workflow 的 Secrets 详解）

所有 Secret 统一填写位置：`GitHub 仓库 → Settings → Secrets and variables → Actions → New repository secret`

### Step 5 — 告知触发方式

Secrets 全部设好后，手动触发验证（按顺序来）：

```
1. Actions → CI Validate → Run workflow          → 验证：flutter analyze 绿色
2. Actions → Android Release Build → Run workflow → 验证：Artifacts 里有 APK/AAB
3. Actions → iOS Release Build → Run workflow     → 验证：Artifacts 里有 IPA
4. push 到 main，或 Actions → Docker Build and Deploy → 验证：服务器容器正常运行
```

---

## 整体流水线全景

```
代码 push / 手动触发
        │
        ├─ [A] CI 校验 ──────────── flutter analyze（阻断劣质 PR）
        │
        ├─ [B] Android 打包 ─────── APK + AAB 签名 → Artifact + git tag
        │
        ├─ [C] iOS 打包 ────────── IPA 签名 → Artifact + git tag
        │
        └─ [D] Docker 构建+部署 ──► Build backend 镜像
                                  ► Build admin 镜像
                                  ► Push 到 GHCR
                                  ► SSH 进服务器
                                  ► 拉镜像 → docker compose up
                                  ► 健康验证
```

每个环节独立，可单独触发，也可串联。

---

## [A] CI 校验 (`ci-validate.yml`)

### 这步是什么

每次 push 到主分支或 PR 合入前，自动跑 `flutter analyze`，阻止带分析错误的代码进主干。

### 新项目适配清单

| # | 检查项 | 说明 | 是否必改 |
|---|--------|------|--------|
| A1 | Flutter 工作目录 | `YOUR_FLUTTER_DIR` → 改为新项目的 Flutter 目录 | **必改** |
| A2 | 保护分支名 | `branches: [main]` → 按新项目分支策略调整 | 按需改 |
| A3 | 是否启用测试 | workflow 内注释了 `flutter test`，视项目情况解注释 | 按需改 |

### 常见问题

- `flutter analyze` 失败：本地先跑一遍，修完再 push
- Java 17 设置失败：`actions/setup-java@v4` 需要 `distribution: temurin`，不能省略

---

## [B] Android 打包 (`android-release.yml`)

### 这步是什么

定时（一三五 08:00 上海时间）或手动触发：用 Keystore 签名 APK/AAB，生成四段版本号，打 git tag，上传 Artifact。

### 新项目适配清单

| # | 检查项 | 说明 | 是否必改 |
|---|--------|------|--------|
| B1 | Flutter 工作目录 | `YOUR_FLUTTER_DIR` → 新 Flutter 目录 | **必改** |
| B2 | Keystore 路径 | `YOUR_FLUTTER_DIR/ci_release.jks` → 与新目录对齐 | **必改** |
| B3 | `key.properties` 路径 | `YOUR_FLUTTER_DIR/android/key.properties` → 与新目录对齐 | **必改** |
| B4 | `ANDROID_BASE_VERSION` | Repo → Settings → Variables，设默认基础版本号 | **必设** |
| B5 | 4 个签名 Secrets | 见下方 Secrets 详解 | **必设** |
| B6 | 调度时间 | `cron: "0 0 * * 1,3,5"` → 按需调整 | 按需改 |

### Secrets 详解（Android）

> ⚠️ base64 值**必须去掉换行符**，否则 CI 解码会失败。

**`ANDROID_KEYSTORE_BASE64`** — 签名用的 Keystore 文件（base64 编码）

```bash
# 如果还没有 keystore，先生成一个（按提示填组织信息和密码）：
keytool -genkey -v -keystore release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 然后 base64 编码（macOS）：
base64 < release.jks | tr -d '\n'
# Linux：
base64 -w 0 < release.jks
# 把输出的一整串字符串填入 Secret
```

**`ANDROID_STORE_PASSWORD`** — Keystore 密码（明文）

> 就是上面 `keytool` 命令运行时第一次要你输入的密码，直接填明文。

**`ANDROID_KEY_ALIAS`** — Key 别名（明文）

```bash
# 查看 keystore 里的 alias：
keytool -list -v -keystore release.jks | grep 'Alias name'
# 如果用上面命令生成的，alias 就是 upload
```

**`ANDROID_KEY_PASSWORD`** — Key 密码（明文）

> 通常与 `ANDROID_STORE_PASSWORD` 相同。如果 keytool 时没有单独设 key 密码，填同一个值即可。

### 常见问题

| 现象 | 原因 | 修复 |
|------|------|------|
| `Missing required Android signing secrets` | Secret 未设或名称拼错 | 核对 Repo Settings → Secrets |
| `key.properties not found` | 路径与新 Flutter 目录不匹配 | 检查 B2/B3 适配项 |
| Artifact 里没有 APK | `flutter build apk` 步骤失败 | 查看 Actions 日志，通常是签名配置问题 |

---

## [C] iOS 打包 (`ios-release.yml`)

### 这步是什么

与 Android 同频触发，运行于 macOS runner：还原 P12 证书 + Provisioning Profile，自动解析 Bundle ID，`flutter build ipa` 导出 IPA，打 git tag，上传 Artifact。

### 新项目适配清单

| # | 检查项 | 说明 | 是否必改 |
|---|--------|------|--------|
| C1 | Flutter 工作目录 | `YOUR_FLUTTER_DIR` → 新目录 | **必改** |
| C2 | IPA artifact 路径 | `YOUR_FLUTTER_DIR/build/ios/ipa/*.ipa` → 与新目录对齐 | **必改** |
| C3 | `IOS_EXPORT_METHOD` | Variable：`app-store` / `ad-hoc` / `development` | **必设** |
| C4 | `IOS_BASE_VERSION` | Variable：默认基础版本号 | **必设** |
| C5 | 4 个签名 Secrets | 见下方 Secrets 详解 | **必设** |
| C6 | Bundle ID | 由 Profile 自动解析，无需硬编码 | 无需改 |

### Secrets 详解（iOS）

> ⚠️ base64 值**必须去掉换行符**，否则 CI 解码会失败。

**`IOS_CERTIFICATE_P12_BASE64`** — 开发者证书（P12 格式，base64 编码）

```
获取步骤：
1. Xcode → Settings → Accounts → 选你的 Apple ID
2. 点 "Manage Certificates" → 右键你的证书 → "Export Certificate"
3. 保存为 cert.p12，设置一个导出密码（记住这个密码！）
```
```bash
# 导出后 base64 编码：
base64 < cert.p12 | tr -d '\n'
```

**`IOS_CERTIFICATE_PASSWORD`** — 上一步导出 P12 时设置的密码（明文）

**`IOS_PROVISIONING_PROFILE_BASE64`** — Provisioning Profile（base64 编码）

```
获取步骤：
1. developer.apple.com → Certificates, IDs & Profiles → Profiles
2. 找到或新建你 App 对应的 Profile → Download，下载 .mobileprovision 文件
```
```bash
# 下载后 base64 编码：
base64 < profile.mobileprovision | tr -d '\n'
```

**`IOS_KEYCHAIN_PASSWORD`** — CI 临时 keychain 密码（可选）

> 不填也可以，workflow 会自动随机生成。如果要填，任意字符串均可。

### 常见问题

| 现象 | 原因 | 修复 |
|------|------|------|
| `security import` 失败 | P12 密码错误 | 重新导出 P12 并确认密码 |
| `No profiles for bundle ID` | Profile 与 App Bundle ID 不匹配 | Apple Developer 重新下载正确 Profile |
| `code signing identity not found` | 证书 base64 含换行符 | 重新编码，加 `tr -d '\n'` |

---

## [D] Docker 构建 + 部署 (`docker-release.yml`)

### 这步是什么

push 到 main 或手动触发，两阶段：

**阶段 1：Build & Push**（GitHub runner 上）
1. 构建 backend + admin Docker 镜像
2. 推送到 GHCR，tag 为 `sha-<commit前8位>` 和 `latest`

**阶段 2：Deploy**（SSH 进服务器）
1. SSH 连服务器（可选登录 GHCR 拉私有镜像）
2. 调用 `step1-prepare.sh` 生成 deploy.env
3. 调用 `step2-deploy.sh` 拉镜像 → `docker compose up` → 健康检查

### 新项目适配清单

| # | 检查项 | 说明 | 是否必改 |
|---|--------|------|--------|
| D0 | GHCR write 权限 | Repo → Settings → Actions → General → Workflow permissions → **Read and write permissions** | **必设（否则推送直接 403）** |
| D1 | `IMAGE_BACKEND` | `ghcr.io/YOUR_ORG/YOUR_PROJECT-backend` | **必改** |
| D2 | `IMAGE_ADMIN` | `ghcr.io/YOUR_ORG/YOUR_PROJECT-admin` | **必改** |
| D3 | Backend Dockerfile 路径 | `context: ./YOUR_BACKEND_DIR` | **必改** |
| D4 | Admin Dockerfile 路径 | `context: ./YOUR_ADMIN_DIR` | **必改** |
| D5 | `VITE_API_BASE_URL` | `build-args` 里的 API 域名 | **必改** |
| D6 | 部署脚本 | `scripts/deploy-release/` 已复制到新项目 | **必做** |
| D7 | 服务器 Secrets | 见下方 Secrets 详解 | **必设** |
| D8 | 触发分支 | `push: branches: [main]` → 按需调整 | 按需改 |

### Secrets 详解（Docker + 部署）

**`SSH_DEPLOY_PRIVATE_KEY`**（kiki_chain 中原名 `TENCENT_SSH_PRIVATE_KEY`）— SSH 连接服务器用的私钥

> 💡 Secret 名称可按项目自定义，只需与 `docker-release.yml` 里的引用名保持一致。

```bash
# 方法 A：用本地已有的私钥（如果你已经能 SSH 进服务器）：
cat ~/.ssh/id_rsa
# 把从 -----BEGIN 到 -----END 整块内容填入 Secret

# 方法 B（推荐）：为 CI 单独生成一个密钥对，安全隔离：
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/deploy_key -N ""
# 把公钥追加到服务器 authorized_keys：
ssh-copy-id -i ~/.ssh/deploy_key.pub <user>@<server_ip>
# 或手动：cat ~/.ssh/deploy_key.pub | ssh <user>@<server_ip> 'cat >> ~/.ssh/authorized_keys'
# 私钥内容填入 Secret：
cat ~/.ssh/deploy_key
```

**`DEPLOY_SERVER_IP`** — 服务器公网 IP（纯 IP，不含端口或空格）

```
腾讯云：控制台 → 云服务器 → 实例列表 → 「公网IP」列
阿里云：ECS 控制台 → 实例 → 「公网IP」列
其他：服务商控制台找「弹性公网 IP」或「Floating IP」
```

**`DEPLOY_SSH_USER`** — SSH 登录用户名（明文）

```bash
# 连进服务器后确认：
whoami
# 腾讯云 Ubuntu 系统通常是 ubuntu，阿里云默认是 root
```

**`DEPLOY_REMOTE_DIR`** — 项目部署到服务器的目录路径（明文）

```
自己决定，不存在时脚本会自动创建，例如：
  /opt/myapp
  /data/myapp
  /home/ubuntu/myapp
```

**`GHCR_USERNAME`** 和 **`GHCR_READ_TOKEN`**（可选，私有镜像时才需要）

```
GHCR_USERNAME：你的 GitHub 用户名

GHCR_READ_TOKEN 生成步骤：
GitHub → Settings → Developer settings
→ Personal access tokens → Fine-grained tokens → Generate new token
权限：Packages → Read-only
```

### 常见问题

| 现象 | 原因 | 修复 |
|------|------|------|
| Build 推送 403 | `permissions.packages: write` 缺失 | workflow 顶部加 `packages: write` |
| SSH 连接超时 | 防火墙未放行 22 端口 | 服务器安全组入站放行 TCP 22 |
| `docker compose` 找不到文件 | `DEPLOY_REMOTE_DIR` 路径不对 | 确认服务器上路径与 Secret 值一致 |
| 镜像拉取失败（私有） | GHCR_READ_TOKEN 未设或过期 | 重新生成 PAT 并更新 Secret |
| IP 含空格导致 SSH 失败 | 复制 IP 时带了空白 | workflow 已有 `tr -d '[:space:]'`，检查 Secret 原始值 |
| 部署成功但页面 502 | 容器未健康启动 | SSH 进服务器跑 `docker compose ps` + `docker compose logs` |

---

## 文件放置说明

> **Agent 应直接生成替换好的 yml**，不让用户手动改占位符。
> 用户只需把文件放到正确位置。

### workflow 文件

```
<你的仓库>/
└── .github/
    └── workflows/
        ├── ci-validate.yml         ← [A]
        ├── android-release.yml     ← [B]
        ├── ios-release.yml         ← [C]
        └── docker-release.yml      ← [D]
```

### 部署脚本（只有选了 [D] 才需要）

```bash
# 从 skill 复制到新项目：
cp -r .github/skills/just-github-workflows/scripts/ <新项目>/scripts/deploy-release/
```

```
scripts/deploy-release/
  ├── step1-prepare.sh   ← 通用，无需修改
  ├── step2-deploy.sh    ← 通用，无需修改
  ├── db-release.sh      ← 通用，无需修改
  ├── docker-compose.yml ← 通用，无需修改
  └── profiles/
      └── example.env    ← 复制并重命名，填入服务器信息
```

---

## 版本号约定

| 字段 | 来源 | 示例 |
|------|------|------|
| `X.Y.Z` | Variable `ANDROID_BASE_VERSION` / `IOS_BASE_VERSION` | `1.0.0` |
| `AUTO` | `github.run_number`，三位补零 | `042` |
| 完整版本 | 拼接 | `1.0.0.042` |
| Git tag（Android） | `android/<branch>/v<full_version>` | `android/main/v1.0.0.042` |
| Docker image tag | `sha-<commit前8位>` + `latest` | `sha-a1b2c3d4` |

---

## Quick Triggers

- "帮我把 CI/CD workflow 移到新项目"
- "新项目配 GitHub Actions"
- "怎么配 APK 自动打包"
- "配安卓/iOS 签名 secrets"
- "Docker 镜像自动构建部署"
- "workflow 怎么改镜像名"
- "配完整的发布流水线"

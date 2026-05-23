---
name: just-deploy-release
description: 统一发布部署工作流技能（两步法）：Step1 生成镜像发布产物、Step2 远程拉镜像部署，再做域名/TLS 接入与回归验证。GitHub Actions 仅负责自动构建镜像，不做自动部署。
---

# just-deploy-release

## Purpose

把分散的发布部署动作收敛成可重复、可审计、可回滚的标准流程。

## Inputs

- 目标环境与 profile（例如 `scripts/deploy-release/profiles/tencent.env`）
- 服务器连接信息（主机、用户、路径）
- 域名与 TLS 目标（admin/mobile/api）
- 是否需要 DB 同步/迁移

## Outputs

- 本地部署产物（`deploy_files/latest` + release 快照）
- 远程部署结果（容器状态、健康检查、关键 URL 可达）
- 域名/TLS 接入结果与验证证据
- 失败时的诊断与回滚方案

## Workflow (必须按顺序)

1. 预检与安全边界
   - 加载 profile，确认目标服务器、域名、端口、compose 路径。
   - 检查是否高风险操作（覆盖、删卷、`down -v`）。

2. Step1: 生成部署产物（本地）
   - 执行 `scripts/deploy-release/step1-prepare.sh`。
   - 产出并校验：`deploy.env`、`deploy-manifest.txt`、release 快照目录。
   - 必须包含镜像字段：`DEPLOY_IMAGE_TAG`、`DEPLOY_BACKEND_IMAGE`、`DEPLOY_ADMIN_IMAGE`。

3. Step2: 远程部署执行
   - 执行 `scripts/deploy-release/step2-deploy.sh`。
   - 先 `pull` 镜像，再启动服务，禁止在生产机本地构建业务镜像。
   - 确认服务状态正常。

4. 数据库发布/迁移（按需）
   - 执行 `scripts/deploy-release/db-release.sh`。
   - 必须保留备份证据并校验核心表可用。

5. 域名与 TLS 接入
   - 执行 `scripts/deploy-release/install-host-nginx.sh`。
   - 校验 server_name、`/api` 代理、`/cdn` 代理、证书域名覆盖。

6. 回归验证（最小门禁）
   - `admin` 页面可打开并登录。
   - API 核心端点返回 200。
   - 场景封面图与互动图可见，`/cdn` 返回 `image/jpeg`。

7. 交付与记录
   - 输出部署摘要：变更、风险、验证结果、回滚指令。
   - 若失败，产出 `DIAGNOSIS.md`（根因 + 证据 + 修复路径）。

## Constraints

- 严格两步法：先 Step1 产物，再 Step2 执行，禁止跳步。
- 未经确认不得执行破坏性操作。
- 任何线上异常必须先诊断再大改。
- 每次部署必须有可复现验证证据（状态码/容器状态/关键日志）。

## Quick Triggers

- "部署到服务器"
- "跑统一发布流程"
- "先 step1 再 step2"
- "把域名和 HTTPS 接上"
- "admin + server + db 一键发布"
- "GitHub action 自动构建镜像"
- "tag 后自动构建镜像"

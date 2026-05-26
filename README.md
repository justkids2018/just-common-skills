# Just-Common-Skills

Engineering workflows you can reuse across projects.

简洁目标：一个入口词（jcs），两个高频动作（安装、注入）。

## Why

- 多项目复用同一套 skills 与规则
- 默认软链接模式，中心更新立即生效
- 保持最小命令面，降低学习成本

## Skills

- 编排器：just-dev-pipeline
- 核心工作器：just-plan-eng-review, just-qa, just-review, just-ship, just-document-release, just-investigate, just-careful
- 专用技能：CI/CD, 部署, 投研发布, 卡片工作流, 文档生成等

## Install and Update

推荐方式（免 npm）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)
```

npm 方式（全局后用短命令）：

```bash
npm i -g @qisd/just-common-skills
jcs i
```

更新：

```bash
jcs i
```

## Inject to Project

```bash
jcs inject /path/to/your-project --force
```

引用入口模式（更精简的治理文件）：

```bash
jcs inject /path/to/your-project --force --reference-entry
```

## Uninstall

```bash
jcs u --force
```

## Public Commands

1. jcs i
2. jcs inject <project>
3. jcs u

其余脚本保留为内部维护用途。

## Docs

- 对比分析：[docs/framework-comparison-waza-vs-just-cn.md](docs/framework-comparison-waza-vs-just-cn.md)
- 脚本说明：[scripts/README.md](scripts/README.md)

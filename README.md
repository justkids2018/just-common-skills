# Just-Common-Skills

**跨项目可复用技能的单一真源 (Single Source of Truth for Reusable Skills)**

企业级 AI 辅助开发技能框架，为团队协作和生产交付设计。通过编排器 + 工作器模式，提供端到端的开发工作流支持。

---

## 为什么需要 Just-Common-Skills

在多项目、多团队的企业环境中，AI 辅助开发面临以下挑战：

1. **一致性问题** - 不同项目使用不同的 AI 指令，导致代码质量参差不齐
2. **重复配置** - 每个项目都要重新配置相同的技能和规则
3. **更新困难** - 改进一个技能需要在所有项目中手动同步
4. **缺少护栏** - 破坏性操作没有统一的安全检查
5. **工作流割裂** - 从需求到发布的流程没有标准化

Just-Common-Skills 通过**中心化技能仓库 + 符号链接模式**解决这些问题：
- ✅ 一次更新，所有项目立即生效
- ✅ 强制 baseline 标准，确保代码质量
- ✅ 编排器管理端到端工作流
- ✅ 生产级安全护栏

---

## 核心理念

**目的一句话**：把公共规则和 skills 接入项目，并且始终使用软引用（symlink，不 copy）。

### 架构设计：编排器 + 工作器

```
just-dev-pipeline (编排器)
  ├─> just-plan-eng-review (架构评审)
  ├─> just-qa (验证 + 修复)
  ├─> just-review (代码审查)
  ├─> just-ship (提交/PR)
  ├─> just-document-release (文档同步)
  └─> just-investigate (根因分析)
```

### 治理模型

显式层级：`AGENTS.md > baseline > ARCHITECTURE.md > 个人偏好`

- **AGENTS.md** - 项目级规则真源
- **baseline/** - 6 个文档定义质量标准（SOLID、测试金字塔、git 安全）
- **技能设计门禁** - 每个 SKILL.md 必须回答 3 个问题（做什么/何时触发/完美输出）

---

## 技能列表

### 1 个编排器

| 技能 | 何时使用 | 作用 |
|------|---------|------|
| [`just-dev-pipeline`](skills/just-dev-pipeline/SKILL.md) | 完整功能开发 | 端到端 6 步交付工作流：需求澄清 → 分析 → 设计 → 实现 → 验证 → 提交 |

### 7 个核心工作器

| 技能 | 何时使用 | 作用 |
|------|---------|------|
| [`just-plan-eng-review`](skills/just-plan-eng-review/SKILL.md) | 实现前 | 架构评审，收敛风险 |
| [`just-qa`](skills/just-qa/SKILL.md) | 实现后 | 构建、测试、验证、修复 |
| [`just-review`](skills/just-review/SKILL.md) | 提交前 | 代码审查，识别风险 |
| [`just-ship`](skills/just-ship/SKILL.md) | 准备发布 | 提交、推送、创建 PR |
| [`just-document-release`](skills/just-document-release/SKILL.md) | 发布后 | 文档同步，保持一致 |
| [`just-investigate`](skills/just-investigate/SKILL.md) | 失败/回归 | 根因分析，定位问题 |
| [`just-careful`](skills/just-careful/SKILL.md) | 破坏性操作前 | 安全确认，回滚预案 |

### 7 个专用技能

| 技能 | 何时使用 | 作用 |
|------|---------|------|
| [`just-github-workflows`](skills/just-github-workflows/SKILL.md) | CI/CD 配置 | 复制 GitHub Actions 模板 |
| [`just-deploy-release`](skills/just-deploy-release/SKILL.md) | 部署发布 | 两步部署工作流 |
| [`just-hotspot-generator`](skills/just-hotspot-generator/SKILL.md) | 性能分析 | 生成热点分析报告 |
| [`just-card-to-json-workflow`](skills/just-card-to-json-workflow/SKILL.md) | 卡片生产 | 卡片数据生成工作流 |
| [`just-value-red-publish`](skills/just-value-red-publish/SKILL.md) | 投资研究 | 数据收集 → 分析 → 发布 |
| [`just-feature-doc-generator`](skills/just-feature-doc-generator/SKILL.md) | 文档生成 | 从代码反向生成文档 |
| [`just-ui-asset-cutter`](skills/just-ui-asset-cutter/SKILL.md) | UI 资产拆解 | 从设计图提取组件 |

---

## 安装

### 一键安装（推荐）

自动安装到 Claude Code、GitHub Copilot、Codex：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)
```

这会：
- 克隆仓库到 `~/.just-common-skills`
- 创建软链接到 `~/.claude/skills`、`~/.github/skills`、`~/.codex/skills`
- 所有项目自动共享最新版本

### 更新技能

重新运行安装命令即可：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)
```

### 卸载

```bash
rm -rf ~/.just-common-skills
rm -rf ~/.claude/skills/just-*
rm -rf ~/.github/skills/just-*
rm -rf ~/.codex/skills/just-*
```

### 项目注入（推荐用于团队项目）

将技能和治理规则注入到具体项目：

**模式 A：从共享中心运行**

```bash
cd /path/to/just-common-skills
./scripts/inject-current-project.sh /path/to/target-project --force
```

**模式 B：在目标项目内运行**

```bash
cd /path/to/target-project
/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

**引用入口模式（推荐用于中心化治理）**

```bash
./scripts/inject-current-project.sh /path/to/target-project --force --reference-entry
```

在此模式下，`AGENTS.md` 和 `CLAUDE.md` 是精简的引用文件，指向共享治理中心。

#### 注入后的项目结构

```
target-project/
├── AGENTS.md                    # 项目级规则真源
├── CLAUDE.md                    # 软引用适配器
├── .github/
│   ├── copilot-instructions.md  # Copilot 技能路由
│   └── skills/                  # -> just-common-skills/skills/
├── .claude/
│   └── skills/                  # -> .github/skills
└── .ai/
    ├── common-prompt/           # -> just-common-skills/common-prompt/
    └── system-platform/         # -> just-common-skills/system-platform/
```

### 更新

由于使用符号链接模式，更新非常简单：

```bash
cd /path/to/just-common-skills
git pull origin main
```

所有链接的项目会立即看到更新。

### 卸载

```bash
cd /path/to/just-common-skills
./scripts/uninstall-skills.sh
```

---

## 快速开始

### 1. 克隆仓库

```bash
git clone <repository-url> ~/just-common-skills
cd ~/just-common-skills
```

### 2. 全局安装

```bash
./scripts/install-skills.sh
```

### 3. 注入到项目

```bash
cd /path/to/your-project
~/just-common-skills/scripts/inject-current-project.sh --force
```

### 4. 验证安装

```bash
# 检查符号链接
ls -la .github/skills
ls -la .ai/common-prompt

# 在 Claude Code 中使用
# 输入 /just-dev-pipeline 开始完整开发流程
```

详细指南：[docs/quickstart-new-project.md](docs/quickstart-new-project.md)

---

## 工作流示例

### 完整功能开发

```bash
/just-dev-pipeline
```

自动执行 6 步流程：
1. 需求澄清
2. 代码/文档分析
3. 设计 + 任务拆解
4. 实现 + 迭代
5. 自审 + 修复
6. 提交/PR + 文档收口

### 快速修复

```bash
/just-investigate  # 定位根因
# 修复代码
/just-qa          # 验证修复
/just-review      # 代码审查
/just-ship        # 提交和 PR
```

### 代码审查

```bash
/just-review
```

识别：
- 逻辑风险
- 回归风险
- 可维护性问题
- 文档影响点

---

## 添加新技能

```bash
./scripts/new-skill.sh just-my-feature
```

然后编辑：
- `skills/just-my-feature/SKILL.md` - 必须回答 3 个问题
- `skills/just-my-feature/guide.md` - 可选详细指南

命名规则：
- `just-{feature}`
- 小写 + 连字符

每个 SKILL.md 必须回答：
1. **做什么** - 这个技能的核心功能
2. **何时触发** - 什么情况下应该使用
3. **完美输出** - 成功执行后的预期结果

---

## 自我验证（Dogfooding）

这个仓库本身也使用相同的链接模式来验证设置：

```bash
cd /path/to/just-common-skills
./scripts/self-dogfood.sh
```

这会创建：
- `.github/skills` -> `skills/`
- `.claude/skills` -> `.github/skills`
- `.ai/common-prompt` -> `common-prompt/`
- `.ai/system-platform` -> `system-platform/`

安全提示：此模式不会重写 `AGENTS.md` 或 `CLAUDE.md`。

---

## 项目结构

```
just-common-skills/
├── skills/                      # 所有可复用技能
│   ├── just-dev-pipeline/       # 编排器
│   ├── just-plan-eng-review/    # 核心工作器
│   ├── just-qa/
│   ├── just-review/
│   ├── just-ship/
│   ├── just-document-release/
│   ├── just-investigate/
│   ├── just-careful/
│   └── ...                      # 专用技能
├── common-prompt/
│   └── baseline/                # 6 个质量标准文档
│       ├── 01-design-principles.md
│       ├── 02-architecture.md
│       ├── 03-coding-standards.md
│       ├── 04-testing-standards.md
│       ├── 05-git-workflow.md
│       └── 06-skill-workflow-standards.md
├── system-platform/             # 系统平台文档
│   ├── system-charter.md
│   └── README.md
├── scripts/
│   ├── install-skills.sh        # 全局安装
│   ├── uninstall-skills.sh      # 卸载
│   ├── inject-current-project.sh # 项目注入
│   ├── new-skill.sh             # 创建新技能
│   ├── self-dogfood.sh          # 自我验证
│   └── validate-skills.sh       # 技能验证
├── docs/                        # 文档
│   ├── quickstart-new-project.md
│   ├── framework-comparison-waza-vs-just.md
│   └── waza-learnings.md
├── AGENTS.md                    # 规则真源
├── CLAUDE.md                    # 软引用
└── README.md                    # 本文件
```

---

## 治理文档

### 系统级

- [system-platform/system-charter.md](system-platform/system-charter.md) - 平台使命和运营模型
- [system-platform/README.md](system-platform/README.md) - 系统平台操作文档

### Baseline 标准

- [common-prompt/baseline/01-design-principles.md](common-prompt/baseline/01-design-principles.md) - SOLID 原则
- [common-prompt/baseline/02-architecture.md](common-prompt/baseline/02-architecture.md) - 架构模式
- [common-prompt/baseline/03-coding-standards.md](common-prompt/baseline/03-coding-standards.md) - 编码规范
- [common-prompt/baseline/04-testing-standards.md](common-prompt/baseline/04-testing-standards.md) - 测试金字塔
- [common-prompt/baseline/05-git-workflow.md](common-prompt/baseline/05-git-workflow.md) - Git 安全
- [common-prompt/baseline/06-skill-workflow-standards.md](common-prompt/baseline/06-skill-workflow-standards.md) - 工作流标准

---

## 兼容性

### 支持的平台

- ✅ **Claude Code** - 主要支持平台
- ✅ **GitHub Copilot** - 通过 `.github/copilot-instructions.md`
- ⚠️ **VS Code Prompts** - 可选镜像支持

### 系统要求

- Git
- Bash (macOS/Linux)
- 符号链接支持

---

## 与 Waza 的对比

Just-Common-Skills 和 [Waza](https://github.com/tw93/Waza) 是两个不同定位的框架：

| 维度 | Waza | Just-Common-Skills |
|------|------|-------------------|
| **定位** | 个人开发者工具包 | 企业级编排平台 |
| **技能数量** | 8 个（精选） | 14+ 个（全面） |
| **控制模式** | 用户驱动（手动串联） | 工作流驱动（自动编排） |
| **治理** | 最小规则（涌现） | 显式规则（强制） |
| **学习曲线** | 平缓（< 1 小时） | 陡峭（2-4 小时） |
| **适用场景** | 个人项目、快速原型 | 团队协作、生产系统 |

详细对比：[docs/framework-comparison-waza-vs-just.md](docs/framework-comparison-waza-vs-just.md)

---

## 常见问题

### Q: 为什么使用符号链接而不是复制？

**A:** 符号链接模式确保一次更新传播到所有项目。这对于企业环境中的多项目一致性至关重要。

### Q: 如果我不想要某个技能怎么办？

**A:** 技能是按需调用的。如果不使用某个技能，它不会影响你的工作流。

### Q: 可以自定义 baseline 标准吗？

**A:** 可以。Fork 这个仓库，修改 `common-prompt/baseline/` 下的文档，然后让你的项目链接到你的 fork。

### Q: 如何在团队中推广？

**A:** 
1. 在一个试点项目中注入技能
2. 让团队成员体验完整工作流
3. 收集反馈并调整
4. 逐步推广到其他项目

### Q: 更新会破坏现有项目吗？

**A:** 符号链接模式意味着更新是即时的。建议在更新前：
1. 在测试项目中验证
2. 通知团队即将更新
3. 准备回滚方案（git revert）

---

## 告诉 AI 如何设置

如果你在另一个项目中，想让 AI 正确执行设置，告诉它：

```text
读取 /path/to/just-common-skills/README.md。
然后为当前项目执行符号链接模式设置（不要复制）。
如果当前目录是目标项目，运行：
bash /path/to/just-common-skills/scripts/inject-current-project.sh --force
如果从中心仓库运行，运行：
bash /path/to/just-common-skills/scripts/inject-current-project.sh /path/to/target-project --force
执行后，验证 .github/skills 和 .ai/common-prompt 是符号链接。
```

---

## 贡献

欢迎贡献新技能或改进现有技能！

1. Fork 这个仓库
2. 创建新分支：`git checkout -b feature/my-skill`
3. 使用 `./scripts/new-skill.sh` 创建技能
4. 提交更改：`git commit -am 'Add my-skill'`
5. 推送分支：`git push origin feature/my-skill`
6. 创建 Pull Request

---

## 许可证

MIT License

---

## 支持

- 问题反馈：[GitHub Issues](../../issues)
- 文档：[docs/](docs/)
- 对比分析：[Waza vs Just-Common-Skills](docs/framework-comparison-waza-vs-just.md)

---

**Built for teams who ship production code with AI assistance.**

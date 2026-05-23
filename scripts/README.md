# Scripts 使用手册

## 脚本总览

| 脚本 | 用途 | 使用频率 |
|------|------|---------|
| `inject-current-project.sh` | 将共享规则注入目标项目 | **最常用** |
| `self-dogfood.sh` | 让 hub 自身消费 skills | 开发 hub 时用 |
| `install-skills.sh` | 全局安装 skills 到 `~/.claude/skills` | 一次性 |
| `uninstall-skills.sh` | 卸载全局 skills | 一次性 |
| `new-skill.sh` | 创建新 skill 脚手架 | 新增 skill 时用 |
| `validate-skills.sh` | 校验 skill 是否包含三问强制章节 | 提交前/周检 |

---

## inject-current-project.sh（主力脚本）

将 hub 的 skills、baseline、system-platform 注入到任意项目。

### 用法

```bash
bash scripts/inject-current-project.sh <项目路径>
```

### 示例

```bash
# 注入到 kiki_chain
bash scripts/inject-current-project.sh /Users/qisd/Documents/development/my_project/kiki_chain

# 注入到 agentia_mobile
bash scripts/inject-current-project.sh /Users/qisd/Documents/development/nd/agentia_mobile
```

### 行为逻辑

**文本文件（AGENTS.md / CLAUDE.md / copilot-instructions.md）：**

| 情况 | 行为 |
|------|------|
| 文件不存在 | 直接创建 |
| 文件已存在，无 managed block | 保留原内容，末尾追加 managed block |
| 文件已存在，有 managed block | 保留原内容，刷新 block 内容 |

Managed block 格式：
```
# BEGIN JUST-COMMON-SKILLS MANAGED BLOCK
（hub 注入的内容）
# END JUST-COMMON-SKILLS MANAGED BLOCK
```

**目录（skills / common-prompt / system-platform）：**

始终创建 symlink 指向 hub 目录。Hub 内文件改了，所有项目自动生效。

### 注入后项目结构

```
your-project/
├── AGENTS.md                          ← 合并（原有 + managed block）
├── CLAUDE.md                          ← 合并
├── .github/
│   ├── copilot-instructions.md        ← 合并
│   └── skills/                        ← symlink → hub/skills
├── .claude/
│   └── skills/                        ← symlink → .github/skills
└── .ai/
    ├── common-prompt/                 ← symlink → hub/common-prompt
    └── system-platform/               ← symlink → hub/system-platform
```

### 重复执行

安全。脚本可重复执行：
- 文本文件：managed block 会被刷新为最新内容
- Symlink：会被重建指向最新路径

---

## self-dogfood.sh

让 hub 仓库自身使用自己的 skills（开发调试用）。

```bash
bash scripts/self-dogfood.sh
```

只链接目录，**不修改** AGENTS.md / CLAUDE.md。

---

## new-skill.sh

创建新 skill 的脚手架。

```bash
bash scripts/new-skill.sh just-api-doc-sync
```

生成 `skills/just-api-doc-sync/SKILL.md` 和 `guide.md`。

命名规则：必须匹配 `just-{feature}`，只允许小写字母、数字和连字符。

---

## validate-skills.sh

校验 `skills/*/SKILL.md` 是否满足 baseline 06 的三问强制规范。

```bash
bash scripts/validate-skills.sh
```

若缺少以下任一项会失败：

- `## Three-Question Design Test`
- Q1: What exact job does this skill perform?
- Q2: When should it activate? List at least 5 trigger phrases.
- Q3: What does perfect output look like? Include one concrete output example.

---

## install-skills.sh / uninstall-skills.sh

全局安装/卸载 skills 到 `~/.claude/skills`。

```bash
# 安装
bash scripts/install-skills.sh

# 安装到 VS Code prompts 目录
bash scripts/install-skills.sh --with-vscode-prompts

# 卸载
bash scripts/uninstall-skills.sh
```

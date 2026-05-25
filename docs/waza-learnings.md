# Waza 框架学习总结

## 研究日期
2026-05-25

## 仓库信息
- **项目**: Waza (tw93)
- **GitHub**: https://github.com/tw93/Waza
- **版本**: v3.25.0
- **定位**: 极简主义的工程习惯框架，8个精心挑选的技能

## 可借鉴的关键点

### 1. 简洁的安装方式 ✅

**Waza 的做法**:
```bash
# Claude Code 全局安装
npx skills add tw93/Waza -a claude-code -g -y

# 单个技能安装
npx skills add tw93/Waza --skill think -a claude-code -g -y

# 更新
npx skills update -g -y
```

**优势**:
- 一行命令完成安装
- 支持全局和单技能安装
- 更新简单

**Just-Common-Skills 当前问题**:
- 需要运行 `./scripts/install-skills.sh`
- 项目注入需要 `./scripts/inject-current-project.sh --force`
- 多步骤，复杂

**改进建议**:
- 提供 `npx` 安装方式（如果发布到 npm）
- 简化脚本，减少参数
- 提供一键安装命令

---

### 2. GitHub Actions 自动化 ✅

**Waza 的 CI/CD 结构**:

#### test.yml (持续集成)
```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    - 安装依赖 (jq, ripgrep, python3, pytest)
    - 安装 shellcheck (固定版本)
    - 运行 make test
```

#### release.yml (发布流程)
```yaml
on:
  release:
    types: [published]

jobs:
  upload-zip:
    - 运行完整测试套件
    - make package (生成 waza.zip)
    - gh release upload (上传到 GitHub Release)
```

**核心特点**:
- 固定工具版本（shellcheck v0.10.0）确保可重现性
- 发布前重新运行完整测试
- 自动上传打包产物到 Release

**Just-Common-Skills 当前状态**:
- ❌ 没有 GitHub Actions
- ❌ 没有自动化测试
- ❌ 没有自动化发布

**改进建议**:
- 添加 `.github/workflows/test.yml` - 在 PR 和 push 时运行测试
- 添加 `.github/workflows/release.yml` - 自动打包和发布
- 考虑添加 Makefile 统一测试命令

---

### 3. 失败模式记录 ✅

**Waza 的做法**:
```
skills/check/
  ├── SKILL.md
  ├── references/
  │   ├── project-context.md
  │   ├── failure-modes.md
  │   └── ...
  └── scripts/
```

**references/ 目录内容**:
- 记录真实失败案例
- 反模式（anti-patterns）
- 项目上下文模板

**示例** (从 README 提取):
> "Every gotcha traces to a real failure: a wrong code path that took four rounds to find, a release posted before artifacts were uploaded, a server restarted eight times without reading the error."

**Just-Common-Skills 当前状态**:
- ❌ 没有失败模式文档
- ❌ 没有 references/ 目录
- ❌ 规则来自理论而非实战

**改进建议**:
- 为每个技能添加 `failures.md` 或 `anti-patterns.md`
- 记录真实失败场景和解决方案
- 让规则来自实战而非理论

---

### 4. 打包和分发 ✅

**Waza 的打包流程**:

#### package-skill.sh 核心逻辑:
1. 使用 `git ls-files` 获取文件清单
2. 通过 `packaging_filter.py` 过滤（白名单模式）
3. 合并所有 `skills/*/SKILL.md` 到根 `SKILL.md`
4. 生成 `dist/waza.zip`
5. 验证打包产物（`validate_package.py`）

#### packaging.allowlist (白名单):
```
LICENSE
README.md
rules/
scripts/
skills/
```

**多平台支持**:
- Claude Code (npx)
- Codex (npx)
- Claude Desktop (ZIP 上传)
- Pi coding agent (直接读取 SKILL.md)

**Just-Common-Skills 当前状态**:
- ✅ 有打包脚本但不完善
- ❌ 没有白名单过滤
- ❌ 没有打包验证
- ❌ 只支持 Claude Code 和 Copilot

**改进建议**:
- 添加 `packaging.allowlist`
- 添加打包验证脚本
- 考虑支持更多平台

---

### 5. 技能结构对比

#### Waza 技能结构:
```
skills/<name>/
  ├── SKILL.md (主指令)
  ├── references/ (文档、失败模式)
  └── scripts/ (辅助脚本)
```

#### Just-Common-Skills 技能结构:
```
skills/just-<name>/
  ├── SKILL.md (必须回答 3 个问题)
  └── guide.md (可选)
```

**对比**:
- Waza: 更丰富的支持文件（references, scripts）
- Just: 更简单但缺少失败案例记录

**改进建议**:
- 为每个技能添加 `references/` 目录
- 添加 `failures.md` 记录失败案例
- 保持 `guide.md` 作为详细指南

---

### 6. Makefile 统一测试 ✅

**Waza 的 Makefile**:
```makefile
test: verify-docs verify-generated verify-routing verify-scripts verify-unit $(SMOKE_TESTS)

verify-docs:
    python3 scripts/verify_skills.py --root .

verify-unit:
    python3 -m pytest tests/python/ -q

verify-scripts:
    bash -n scripts/*.sh
    shellcheck scripts/*.sh
    python3 -m py_compile scripts/*.py
```

**优势**:
- 统一入口 `make test`
- 多层验证（文档、脚本、单元测试）
- CI 和本地开发使用相同命令

**Just-Common-Skills 当前状态**:
- ❌ 没有 Makefile
- ❌ 没有统一测试入口
- ❌ 没有自动化验证

**改进建议**:
- 添加 Makefile
- 添加技能验证脚本
- 添加脚本语法检查

---

### 7. 版本管理

**Waza 的做法**:
- `VERSION` 文件存储版本号
- `package.json` 同步版本
- `scripts/build_metadata.py` 自动生成元数据
- Git tag 触发发布

**Just-Common-Skills 当前状态**:
- ❌ 没有版本文件
- ❌ 没有版本管理策略

**改进建议**:
- 添加 `VERSION` 文件
- 添加版本同步脚本
- 使用 Git tag 管理发布

---

### 8. 文档质量

**Waza README.md 结构**:
1. Why (为什么需要这个项目)
2. Skills (技能列表和触发时机)
3. Install and Update (清晰的安装指南)
4. Project Context (如何适配项目)
5. Chaining Skills (如何串联技能)
6. Extras (额外功能)
7. Uninstall (卸载指南)
8. Background (背景和理念)
9. Support (支持方式)

**特点**:
- 清晰的安装命令
- 多平台支持说明
- 实战数据（30天，300+会话，7个项目）
- 可视化图表

**Just-Common-Skills 当前状态**:
- ❌ README.md 不完整
- ❌ 缺少安装指南
- ❌ 缺少使用示例

**改进建议**:
- 重写 README.md
- 添加清晰的安装步骤
- 添加使用示例和工作流说明

---

## 优先级排序

根据用户反馈，聚焦以下3个优化：

### 🔥 P0 - 立即执行
1. **编写部署手册** - 用户明确要求
2. **添加 GitHub Actions** - 自动化测试和发布
3. **添加失败模式文档** - 借鉴 Waza 的实战经验

### 📋 P1 - 近期执行
4. **简化安装脚本** - 降低使用门槛
5. **添加 Makefile** - 统一测试入口
6. **添加版本管理** - 规范发布流程

### 💡 P2 - 未来考虑
7. **多平台支持** - 扩展到更多 AI 平台
8. **打包验证** - 确保分发质量

---

## 不借鉴的部分

### 1. 核心包/扩展包分层
- **原因**: 对 Claude Code 来说，所有技能都展示在列表里，分层收益不明显
- **决策**: 保持现有的扁平结构

### 2. 精简 baseline 文档
- **原因**: 可能影响现有项目，风险较大
- **决策**: 暂不精简，保持 6 个 baseline 文档

### 3. 轻量级模式
- **原因**: 过度设计，增加复杂度
- **决策**: 不添加 `--manual` 或 `--fast` 模式

---

## 总结

Waza 的核心优势在于：
1. **简洁的安装体验** - 一行命令完成
2. **完善的自动化** - GitHub Actions + Makefile
3. **实战驱动** - 失败模式来自真实案例
4. **清晰的文档** - 安装、使用、卸载一目了然

Just-Common-Skills 应该借鉴这些优势，同时保持自己的企业级定位和编排器架构。

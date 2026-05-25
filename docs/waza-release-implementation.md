# Waza-Inspired Release System Implementation

## 概述

成功实现了类似 [tw93/Waza](https://github.com/tw93/Waza) 的简化发布流程，使 just-common-skills 可以通过 GitHub Releases 轻松分发。

## 实现的功能

### 1. 自动化打包系统

**核心脚本**: `scripts/package-skill.sh`
- 从 git 跟踪的文件中收集所有需要的文件
- 合并所有 `skills/*/SKILL.md` 到单个根 `SKILL.md`
- 剥离 YAML frontmatter
- 生成 `dist/just-common-skills.zip` (约 55MB)

**Makefile 集成**:
```bash
make package  # 一键打包
```

### 2. GitHub Actions 自动化

**工作流**: `.github/workflows/release.yml`

触发条件：手动创建 GitHub Release

自动执行：
1. ✅ 运行完整测试 (`make test`)
2. ✅ 验证版本一致性 (VERSION 文件 vs Git tag)
3. ✅ 打包技能 (`make package`)
4. ✅ 上传 `just-common-skills.zip` 到 Release
5. ✅ 更新 Release Notes

### 3. 多种安装方式

#### 方式 1: npx（最简单）
```bash
npx skills add qisd/just-common-skills -a claude-code -g -y
```

#### 方式 2: GitHub Release 下载
```bash
curl -L https://github.com/qisd/just-common-skills/releases/latest/download/just-common-skills.zip -o just-common-skills.zip
unzip just-common-skills.zip -d ~/.claude/skills/just-common-skills
```

#### 方式 3: Git Clone（开发者模式）
```bash
git clone https://github.com/qisd/just-common-skills.git
cd just-common-skills
./scripts/install-skills.sh
```

### 4. 版本管理

**文件结构**:
- `VERSION` - 纯文本版本号 (如 `1.0.0`)
- `package.json` - npm 元数据，包含版本和文件列表
- Git tags - 格式 `v1.0.0`

**版本一致性检查**:
CI 会自动验证 VERSION 文件和 Git tag 是否匹配。

### 5. 文档

**新增文档**:
- `docs/RELEASE_GUIDE.md` - 完整的发布流程指南
- `README.md` - 更新了安装说明，包含 3 种安装方式

## 与 Waza 的对比

| 特性 | Waza | just-common-skills |
|------|------|-------------------|
| 主要分发渠道 | GitHub Releases | ✅ GitHub Releases |
| npx 安装 | ✅ | ✅ |
| 自动化打包 | ✅ | ✅ |
| SKILL.md 合并 | ✅ | ✅ |
| CI/CD | GitHub Actions | ✅ GitHub Actions |
| 版本管理 | package.json | ✅ VERSION + package.json |
| npm 发布 | 否 | 否（仅元数据） |

## 发布流程

### 简化的 4 步发布

```bash
# 1. 更新版本
echo "1.1.0" > VERSION
vim package.json  # 更新 version 字段

# 2. 提交
git commit -am "chore: bump version to v1.1.0"
git push

# 3. 在 GitHub 创建 Release
# - Tag: v1.1.0
# - Title: V1.1.0 <Name>
# - 填写 Release Notes

# 4. CI 自动完成剩余工作
# ✅ 测试、打包、上传 zip
```

## 技术细节

### 打包策略

1. **文件收集**: 使用 `git ls-files` 获取所有跟踪的文件
2. **过滤**: 跳过 `.github/*`, `dist/*`, `__pycache__` 等
3. **SKILL.md 合并**:
   - 基础模板: `scripts/dispatcher.md`
   - 添加每个技能的内容（剥离 frontmatter）
   - 每个技能一个 `# SKILL: <name>` 章节
4. **验证**: 确保根目录只有一个 `SKILL.md`
5. **打包**: 创建 zip 文件

### CI 工作流

```yaml
on:
  release:
    types: [published]

jobs:
  validate-and-tag:
    - 安装依赖 (jq, ripgrep)
    - 运行测试
    - 验证版本
    - 打包
    - 上传到 Release
```

## 优势

### 1. 简化发布
- 不需要 npm 账号和 token
- 不需要处理 npm 发布的复杂性
- GitHub Release 提供原生的版本管理和下载统计

### 2. 用户友好
- `npx skills add` 直接从 GitHub 安装
- 支持手动下载 zip
- 支持 Claude Desktop 直接上传

### 3. 自动化
- 创建 Release 后全自动
- 测试、打包、上传一气呵成
- 减少人为错误

### 4. 可维护性
- 单一真源（git 仓库）
- 版本一致性自动检查
- 清晰的发布流程文档

## 测试验证

### 本地测试
```bash
# 打包测试
make package
ls -lh dist/just-common-skills.zip

# 查看内容
unzip -l dist/just-common-skills.zip | grep SKILL.md
```

### 发布后验证
```bash
# 1. 检查 Release 页面
open https://github.com/qisd/just-common-skills/releases/latest

# 2. 测试下载
curl -L https://github.com/qisd/just-common-skills/releases/latest/download/just-common-skills.zip -o test.zip

# 3. 测试 npx 安装
npx skills add qisd/just-common-skills --skill just-dev-pipeline -a claude-code -g -y
```

## 下一步

### 准备首次发布

1. 确认所有更改已合并到 `main`
2. 在 GitHub 创建 Release `v1.0.0`
3. 观察 CI 工作流执行
4. 验证 zip 文件上传成功
5. 测试 npx 安装

### 未来改进

- [ ] 添加 CHANGELOG.md 自动生成
- [ ] 支持 pre-release 版本
- [ ] 添加下载统计监控
- [ ] 考虑发布到 npm（可选）

## 参考资料

- [Waza Release Workflow](https://github.com/tw93/Waza/blob/main/.github/workflows/release.yml)
- [Waza Package Script](https://github.com/tw93/Waza/blob/main/scripts/package-skill.sh)
- [Semantic Versioning](https://semver.org/)
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github)

## 总结

成功借鉴 Waza 的发布模式，实现了：
- ✅ 简化的发布流程（4 步）
- ✅ 自动化 CI/CD
- ✅ 多种安装方式
- ✅ 完整的文档
- ✅ 版本管理系统

现在 just-common-skills 可以像 Waza 一样轻松发布和分发！

# Release Guide

本文档说明如何发布 just-common-skills 的新版本。

## 发布流程

### 1. 准备发布

确保所有更改已提交并推送到 `main` 分支：

```bash
git status
git log --oneline -5
```

### 2. 更新版本号

编辑以下文件中的版本号：

```bash
# 更新 VERSION 文件
echo "1.1.0" > VERSION

# 更新 package.json
vim package.json  # 修改 "version" 字段
```

### 3. 提交版本更新

```bash
git add VERSION package.json
git commit -m "chore: bump version to v1.1.0"
git push origin main
```

### 4. 创建 GitHub Release

在 GitHub 上创建新的 Release：

1. 访问 https://github.com/qisd/just-common-skills/releases/new
2. 填写以下信息：
   - **Tag**: `v1.1.0` (必须以 `v` 开头)
   - **Target**: `main`
   - **Title**: `V1.1.0 <Release Name>`
   - **Description**: 填写 Release Notes（见下方模板）

3. 点击 **Publish release**

### 5. 自动化流程

创建 Release 后，GitHub Actions 会自动：

1. ✅ 运行完整测试套件 (`make test`)
2. ✅ 验证版本一致性（VERSION 文件 vs Git tag）
3. ✅ 打包技能 (`make package`)
4. ✅ 上传 `just-common-skills.zip` 到 Release
5. ✅ 更新 Release Notes

### 6. 验证发布

检查以下内容：

```bash
# 1. 检查 Release 页面
open https://github.com/qisd/just-common-skills/releases/latest

# 2. 验证 zip 文件可下载
curl -L https://github.com/qisd/just-common-skills/releases/latest/download/just-common-skills.zip -o test.zip
unzip -l test.zip | grep "SKILL.md"

# 3. 测试 npx 安装
npx skills add qisd/just-common-skills --skill just-dev-pipeline -a claude-code -g -y
```

## Release Notes 模板

```markdown
## What's New

### ✨ New Features
- Added `just-xxx` skill for ...
- Enhanced `just-yyy` with ...

### 🐛 Bug Fixes
- Fixed issue where ...
- Resolved problem with ...

### 📚 Documentation
- Updated installation guide
- Added examples for ...

### 🔧 Improvements
- Improved performance of ...
- Refactored ... for better maintainability

## Installation

### Quick Install
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/qisd/just-common-skills/main/scripts/quick-install.sh)
```

Automatically installs to Claude Code, GitHub Copilot, and Codex.

### Full Documentation
See [README.md](https://github.com/qisd/just-common-skills/blob/v1.1.0/README.md) for complete installation and usage instructions.

## What's Included

- 1 orchestrator: `just-dev-pipeline`
- 7 core workers: `just-plan-eng-review`, `just-qa`, `just-review`, `just-ship`, `just-document-release`, `just-investigate`, `just-careful`
- 7 specialized skills: CI/CD, deployment, analysis, and domain-specific workflows
- 6 baseline standards documents

**Full Changelog**: https://github.com/qisd/just-common-skills/compare/v1.0.0...v1.1.0
```

## 版本号规范

遵循 [Semantic Versioning](https://semver.org/)：

- **Major (x.0.0)**: 破坏性变更，不兼容旧版本
- **Minor (0.x.0)**: 新功能，向后兼容
- **Patch (0.0.x)**: Bug 修复，向后兼容

示例：
- `1.0.0` → `1.1.0`: 添加新技能
- `1.1.0` → `1.1.1`: 修复 bug
- `1.1.1` → `2.0.0`: 重构技能结构（破坏性变更）

## 回滚发布

如果发现问题需要回滚：

1. **删除 Release**:
   - 访问 Release 页面
   - 点击 "Delete" 删除有问题的 Release

2. **删除 Tag**:
   ```bash
   git tag -d v1.1.0
   git push origin :refs/tags/v1.1.0
   ```

3. **修复问题后重新发布**

## 故障排查

### 问题：CI 测试失败

```bash
# 本地运行测试
make test

# 检查具体失败的测试
./scripts/validate-skills.sh
```

### 问题：版本不一致错误

确保 `VERSION` 文件和 Git tag 匹配：

```bash
cat VERSION  # 应该是 1.1.0
git describe --tags  # 应该是 v1.1.0
```

### 问题：打包失败

本地测试打包：

```bash
make package
ls -lh dist/just-common-skills.zip
```

## 发布检查清单

发布前确认：

- [ ] 所有测试通过 (`make test`)
- [ ] VERSION 文件已更新
- [ ] package.json 版本已更新
- [ ] CHANGELOG 已更新（如果有）
- [ ] 文档已更新
- [ ] 本地打包成功 (`make package`)
- [ ] Git tag 格式正确 (`v1.1.0`)
- [ ] Release Notes 已准备好

发布后验证：

- [ ] GitHub Actions 工作流成功
- [ ] zip 文件已上传到 Release
- [ ] Release Notes 自动更新
- [ ] npx 安装测试通过
- [ ] 手动下载 zip 测试通过

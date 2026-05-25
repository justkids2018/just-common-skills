# 失败模式记录 (Failure Patterns)

本文档记录 `just-ship` 技能在实际使用中遇到的失败案例和解决方案。

---

## 失败案例 1: 提交信息不清晰

### 场景
AI 生成的提交信息过于简单或模糊，如 "fix bug" 或 "update code"。

### 表现
- 无法从 git log 理解改动内容
- Code review 时需要额外解释
- 未来回溯困难

### 根因
- 没有分析 git diff 的实际内容
- 使用通用模板而非具体描述
- 没有遵循项目的提交规范

### 解决方案
- **提交信息结构**:
  ```
  <type>(<scope>): <subject>
  
  <body>
  
  Co-Authored-By: Claude Sonnet 4.6 (1M context) <noreply@anthropic.com>
  ```
- **Type 类型**:
  - `feat`: 新功能
  - `fix`: Bug 修复
  - `refactor`: 重构
  - `docs`: 文档更新
  - `test`: 测试相关
  - `chore`: 构建/工具相关
- **Subject 要求**:
  - 使用祈使句（"add" 而非 "added"）
  - 不超过 50 字符
  - 不以句号结尾
  - 描述"做了什么"而非"为什么"
- **Body 要求**:
  - 解释"为什么"和"怎么做"
  - 每行不超过 72 字符
  - 可选，但复杂改动建议添加

### 预防措施
- 在 SKILL.md 中添加提交信息规范
- 检查项目是否有 `.gitmessage` 模板

---

## 失败案例 2: 提交了不应该提交的文件

### 场景
AI 使用 `git add .` 或 `git add -A`，意外提交了敏感文件或临时文件。

### 表现
- `.env` 文件被提交（泄露密钥）
- `node_modules/` 被提交（体积巨大）
- 临时文件被提交（`.DS_Store`, `*.swp`）

### 根因
- 使用 `git add .` 而非指定文件
- 没有检查 `git status`
- 没有检查 `.gitignore`

### 解决方案
- **安全提交流程**:
  1. 运行 `git status` 查看所有改动
  2. 逐个添加文件：`git add file1 file2`
  3. 再次运行 `git status` 确认暂存区
  4. 检查是否有敏感文件
  5. 提交
- **敏感文件清单**:
  - `.env`, `.env.local`
  - `credentials.json`, `secrets.yaml`
  - `*.pem`, `*.key`
  - `config/production.yml`
- **永远不要使用** `git add .` 或 `git add -A`

### 预防措施
- 在 SKILL.md 中明确禁止 `git add .`
- 要求 AI 列出将要提交的文件

---

## 失败案例 3: PR 标题和描述不完整

### 场景
AI 创建的 PR 只有简单的标题，没有描述或描述不完整。

### 表现
- Reviewer 不知道改动的背景
- 需要额外沟通
- PR 审查效率低

### 根因
- 只关注代码，忽略 PR 描述
- 没有使用 PR 模板
- 认为"代码即文档"

### 解决方案
- **PR 描述结构**:
  ```markdown
  ## 改动概述
  简要描述这个 PR 做了什么（1-2 句话）
  
  ## 改动详情
  - 添加了 XX 功能
  - 修复了 XX bug
  - 重构了 XX 模块
  
  ## 测试情况
  - [ ] 单元测试通过
  - [ ] 集成测试通过
  - [ ] 手动验证通过
  
  ## 影响范围
  - 影响的模块：XX, YY
  - 破坏性改动：无/有（说明）
  
  ## 截图（如果是 UI 改动）
  [添加截图]
  
  ## 相关 Issue
  Closes #123
  ```
- **PR 标题要求**:
  - 不超过 70 字符
  - 使用祈使句
  - 描述"做了什么"

### 预防措施
- 在 SKILL.md 中添加 PR 描述模板
- 检查项目是否有 `.github/pull_request_template.md`

---

## 失败案例 4: 推送到错误的分支

### 场景
AI 直接推送到 `main` 或 `master` 分支，而不是创建新分支。

### 表现
- 破坏了主分支
- 绕过了 PR 审查流程
- 需要回滚

### 根因
- 没有检查当前分支
- 没有创建新分支
- 不了解 git 工作流

### 解决方案
- **安全推送流程**:
  1. 检查当前分支：`git branch --show-current`
  2. 如果在 `main`/`master`，创建新分支：`git checkout -b feature/xxx`
  3. 提交改动
  4. 推送到新分支：`git push -u origin feature/xxx`
  5. 创建 PR
- **永远不要直接推送到 `main`/`master`**
- **分支命名规范**:
  - `feature/xxx` - 新功能
  - `fix/xxx` - Bug 修复
  - `refactor/xxx` - 重构
  - `docs/xxx` - 文档更新

### 预防措施
- 在 SKILL.md 中明确：永远不要直接推送到 main
- 要求 AI 在推送前检查当前分支

---

## 失败案例 5: 没有运行 pre-commit hooks

### 场景
AI 使用 `git commit --no-verify` 跳过了 pre-commit hooks。

### 表现
- 代码格式不一致
- Lint 错误被提交
- CI 失败

### 根因
- 为了"快速提交"跳过 hooks
- 不理解 hooks 的作用
- 遇到 hook 失败就跳过

### 解决方案
- **永远不要使用 `--no-verify`**
- **如果 hook 失败**:
  1. 阅读失败信息
  2. 修复问题（格式化代码、修复 lint 错误）
  3. 重新提交
- **常见 hooks**:
  - `pre-commit` - 代码格式化、lint 检查
  - `commit-msg` - 提交信息格式检查
  - `pre-push` - 运行测试

### 预防措施
- 在 SKILL.md 中明确禁止 `--no-verify`
- 如果 hook 失败，要求 AI 修复而非跳过

---

## 失败案例 6: PR 创建后没有检查 CI 状态

### 场景
AI 创建了 PR 后就认为任务完成，没有检查 CI 是否通过。

### 表现
- CI 失败但没人知道
- PR 无法合并
- 需要额外修复

### 根因
- 认为"创建 PR"就是"完成任务"
- 没有等待 CI 结果
- 不关注 CI 状态

### 解决方案
- **PR 创建后的检查清单**:
  1. 等待 CI 开始运行（通常几秒钟）
  2. 检查 CI 状态：`gh pr checks`
  3. 如果失败，查看日志：`gh pr checks --watch`
  4. 修复问题，推送新提交
  5. 再次检查 CI
- **CI 失败的常见原因**:
  - 测试失败
  - Lint 错误
  - 构建失败
  - 代码覆盖率不足

### 预防措施
- 在 SKILL.md 中添加 CI 检查步骤
- 要求 AI 输出 CI 状态

---

## 反模式总结

### ❌ 不要做
1. **模糊的提交信息** - "fix bug", "update code"
2. **使用 `git add .`** - 可能提交敏感文件
3. **空的 PR 描述** - 只有标题没有内容
4. **推送到 main** - 绕过 PR 审查
5. **跳过 hooks** - 使用 `--no-verify`
6. **忽略 CI** - 创建 PR 后不检查状态

### ✅ 应该做
1. **清晰的提交信息** - 遵循规范，描述具体改动
2. **逐个添加文件** - `git add file1 file2`
3. **完整的 PR 描述** - 使用模板，说明背景和测试
4. **创建新分支** - `feature/xxx`, `fix/xxx`
5. **运行 hooks** - 修复问题而非跳过
6. **检查 CI** - 确保通过后再请求审查

---

## 如何使用本文档

1. **提交前** - 阅读失败案例，准备检查清单
2. **遇到问题时** - 查找类似场景，参考解决方案
3. **提交后** - 如果遇到新的失败案例，添加到本文档

---

## 贡献

如果你在使用 `just-ship` 时遇到了新的失败案例，请提交 PR 更新本文档。

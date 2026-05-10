# 提交规范

> 步骤 6 的执行规则。**所有模式都强制 Gate**：commit 前必须用户确认计划。

---

## Commit 必须遵守

- [`baseline/05-git-workflow.md`](../baseline/05-git-workflow.md)

## 提交前 Agent 必须输出

```markdown
## 提交计划

**分支：** `feature/<name>`（当前分支）
**目标分支：** `dev`

**Commits（按 Task 粒度）：**

1. `feat: <Task 1 标题>`
   - 文件：a.rs, b.rs
   - 行数：+80 -5
   - refs: doc/features/<feature>/

2. `feat: <Task 2 标题>`
   - ...

3. `docs: 新增 <feature> 需求/设计文档`
   - 文件：doc/features/<feature>/*.md

**是否 push 到远程：** 否（默认）

**文档收口：**
- 已确认 `doc/features/<feature>/` 文档与最终代码一致

请确认上述计划，回复：
- `/confirm` 执行
- `/edit` 修改 commit message
- `/cancel` 取消
```

## Commit Message 格式

```
<type>: <中文一句话描述>

<可选：要点列表>

refs: doc/features/<feature>/
```

**type**：`feat` / `fix` / `refactor` / `perf` / `docs` / `test` / `chore` / `style`

## 拆分原则

- **一个 commit 做一件事**
- **可独立 revert**
- **优先按 Task 拆分**（一个 Task 一个 commit）
- **文档单独 commit**（不和代码混）
- **配置 / 依赖单独 commit**

## 禁止

- ❌ 自动 `git push`（必须用户明示）
- ❌ 自动 `git push --force`（强制要二次确认）
- ❌ 一个 commit 改 10 个不相关文件
- ❌ commit message 写 "update" / "fix" / "wip" 这种空话
- ❌ 提交未追踪的本地配置文件 / IDE 文件
- ❌ 提交 `.env` / 密钥 / token

## Push 流程（用户明示后）

1. 检查 `git log origin/<branch>..HEAD` 确认要 push 的内容
2. `git push` 普通推送
3. 输出 PR 模板（参考 `05-git-workflow.md`）

## 危险操作（强制二次确认）

| 操作 | 提示语 |
|------|--------|
| `git push --force` | "这会覆盖远程历史，确定？" |
| `git reset --hard` | "未提交的改动会丢失，确定？" |
| `git rebase 已 push 的 commit` | "会改写共享历史，确定？" |
| 删除远程分支 | "无法恢复，确定？" |

每次都要用户回复"确定" / "确认" 才执行。

---

**步骤 6 完成判据：**

- [ ] 用户已确认 commit 计划
- [ ] 所有 commit 已成功
- [ ] 工作区干净（`git status` 空）
- [ ] push 与否已按用户意愿处理

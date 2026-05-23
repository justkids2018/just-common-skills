# Copilot Instructions

## Runtime Contract

- AGENTS.md is the canonical rule source for this repository.
- CLAUDE.md is the only soft reference adapter.
- Use skills under `.github/skills/` as the authoritative skill assets in each target project.

## Skill-First Routing

When user intent matches an available specialized skill, you MUST:
1. Read the skill's SKILL.md file from `.github/skills/<skill-name>/SKILL.md`
2. Follow the workflow defined in that file
3. Do NOT improvise or skip the skill's defined steps

Avoid ad-hoc direct answers when a dedicated skill exists.

### Routing Decision Model

Before selecting a skill, classify the request by execution mode:

1. Default chat: discussion or light Q&A with no repeatable workflow.
2. Worker skill: single-domain, bounded task with clear start/end.
3. Workflow skill: multi-stage, stateful task spanning tools and checkpoints.
4. Subagent: large search/review/research tasks needing isolated context.
5. Human-in-the-loop: auth, approvals, destructive actions, or legal/financial confirmation.

If the request is multi-stage, cross-tool, or needs resumable execution, prefer a workflow skill over ad-hoc execution.

Default behavior:

- Prefer automatic routing from natural-language intent.
- Do not require users to type slash commands.
- Use skill workflows as default when intent is clear, but do not force execution if the user is clearly asking to discuss/analyze first.
- If confidence is low, ask a short confirmation question before entering a workflow.

Routing map (skill name -> file path):

- End-to-end feature delivery -> `.github/skills/just-dev-pipeline/SKILL.md`
- Generate requirement/logic/api docs from code -> `.github/skills/just-feature-doc-generator/SKILL.md`
- Design review before coding -> `.github/skills/just-plan-eng-review/SKILL.md`
- QA and verification -> `.github/skills/just-qa/SKILL.md`
- Pre-commit review -> `.github/skills/just-review/SKILL.md`
- Root cause analysis -> `.github/skills/just-investigate/SKILL.md`
- Commit/PR/release handoff -> `.github/skills/just-ship/SKILL.md` and `.github/skills/just-document-release/SKILL.md`
- High-risk operations safety -> `.github/skills/just-careful/SKILL.md`

## Keyword Trigger Hints

Use these phrases as strong routing signals in addition to semantic intent.

- `just-dev-pipeline`
	- Trigger words: 新增功能, 增加功能, 开发功能, 实现需求, 做一个功能, 功能迭代, 从需求到上线
- `just-feature-doc-generator`
	- Trigger words: 根据代码出文档, 反向生成功能文档, 梳理功能逻辑, 生成接口文档, 需求文档整理
- `just-plan-eng-review`
	- Trigger words: 先评审方案, 技术方案评审, 架构评审, 开发前评审, 风险评审
- `just-qa`
	- Trigger words: 跑测试, 做 QA, 回归验证, 验证修复, 验收测试
- `just-review`
	- Trigger words: 代码审查, 提交前检查, review 一下, 找风险点
- `just-investigate`
	- Trigger words: 排查问题, 根因分析, 为什么报错, 为什么没生效, 异常定位
- `just-ship` + `just-document-release`
	- Trigger words: 提交代码, 生成 PR, 发布版本, 发版收口, 发布文档同步
- `just-careful`
	- Trigger words: 删除, 覆盖, 回滚, 重置, force, down -v, 高风险操作

## Routing Priority

When multiple intents appear in one request, use this order:

1. High-risk safety (`just-careful`)
2. Failure diagnosis (`just-investigate`)
3. End-to-end feature workflow (`just-dev-pipeline`)
4. QA / Review / Ship / Docs worker skills

### Workflow-First Signals

Treat the request as workflow-first when two or more signals are present:

1. Multi-stage process (e.g., login -> operate -> download -> submit).
2. Cross-tool operations (browser + shell + file operations + validation).
3. Stateful execution (session, auth state, or checkpoints required).
4. Recoverability requirement (must resume after interruption/failure).
5. Evidence requirement (logs, artifacts, screenshots, run reports).

When workflow-first is true:

1. Select one primary orchestrator workflow.
2. Delegate narrow tasks to worker skills.
3. Persist run state and artifacts under a deterministic path.
4. Emit explicit stage status: DONE, DONE_WITH_CONCERNS, or BLOCKED.

If no installed skill matches workflow-first intent, do a second routing pass before defaulting to ad-hoc execution.

Fallback behavior:

- If the user's request is exploratory (e.g., "先分析", "先讨论方案", "先别写代码"), keep to analysis mode and do not auto-enter execution workflows.
- If request contains multiple intents, choose one primary workflow and explicitly list the next-step workflows.

## Documentation Discipline

- Keep feature artifacts under `doc/features/<feature>/`.
- Keep reverse docs under `doc/feature-docs/<feature>/`.
- Keep docs aligned with delivered behavior.

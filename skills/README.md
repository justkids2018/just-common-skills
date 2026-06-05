# Skills Directory

Put every reusable skill in its own folder:

- `skills/<skill-name>/SKILL.md`

Naming convention:

- lowercase
- words separated by hyphens
- pattern: `just-{feature}`
- example: `just-release-checklist`

## Recommended Architecture (1+7)

Use one orchestrator skill plus seven worker skills:

1. Orchestrator: `just-dev-pipeline`
2. Workers: `just-plan-eng-review`, `just-qa`, `just-review`, `just-ship`, `just-document-release`, `just-investigate`, `just-careful`

## CI/CD & Tooling Skills

- `just-github-workflows` — Android/iOS APK 打包、Docker 构建部署、Flutter CI 四条 workflow 模板，新项目快速复制
- `just-ui-compliance` — 移动端优先（iOS HIG）+ Web Apple 风格 UI 规范检测与修复，支持项目规范优先覆盖

Guideline:

- Orchestrator controls phases, gates, and artifact outputs.
- Worker skills handle focused execution and can run standalone when needed.

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

Guideline:

- Orchestrator controls phases, gates, and artifact outputs.
- Worker skills handle focused execution and can run standalone when needed.

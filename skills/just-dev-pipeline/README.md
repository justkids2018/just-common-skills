# just-dev-pipeline

## Purpose

Six-step orchestrator skill for end-to-end feature delivery:

1. requirement clarification
2. current-state analysis
3. technical design and task breakdown
4. implementation and validation
5. review and fix
6. commit and PR with doc closure

This skill is the single orchestrator in the 1+7 model. Worker skills execute focused actions:

Note: the list below is capability grouping, not step order.

- `just-plan-eng-review`
- `just-qa`
- `just-review`
- `just-ship`
- `just-document-release`
- `just-investigate`
- `just-careful`

## Step to Worker Mapping

1. requirement clarification: no worker skill, orchestrator handles clarification and requirement output.
2. current-state analysis: no worker skill, orchestrator handles impact analysis.
3. technical design and task breakdown: `just-plan-eng-review`
4. implementation and validation: `just-qa` (fallback `just-investigate` when failures occur)
5. review and fix: `just-review` (fallback `just-investigate` for complex issues)
6. commit and PR with doc closure: `just-ship` + `just-document-release`

Cross-step safety rule: run `just-careful` before destructive operations.

## Canonical Layout

- `SKILL.md`: execution protocol and gating rules
- `references/`: minimal templates used by the orchestrator
	- `01-requirement.md`
	- `02-tech-design.md`
	- `03-tasks.md`
	- `05-commit.md`

## Notes

- Baseline canonical path is `common-prompt/baseline/`.
- References keep only reusable templates. Execution-specific details live in worker skills.

# System Charter

## Mission

Build a reusable Agent foundation for product engineering.
The foundation must support one-person to small-team execution with high speed,
high quality, and measurable automation.

## Strategic Direction

1. Product-first: engineering serves product outcomes, not code volume.
2. Scale-first: projects must be structured for repeatable delivery.
3. AI-native execution: humans define goals and boundaries, AI executes and iterates.
4. Feedback-driven evolution: every workflow change must be validated by measurable results.

## Non-Negotiable Principles

1. Layering and boundaries are mandatory.
2. Core domain changes require explicit review and impact assessment.
3. Shared rules and skills are integrated by symlink, not copy.
4. AI workflows must be replaceable, auditable, and degradable.
5. Simplicity and readability are defaults; avoid speculative complexity.

## Operating Model

1. Human responsibilities:
	- Define goals, scope, constraints, and acceptance criteria.
	- Approve high-risk operations and core-domain changes.
	- Review outcomes and decide next iteration priorities.
2. AI responsibilities:
	- Plan and execute bounded tasks.
	- Produce implementation, tests, and documentation updates.
	- Report risks, fallback options, and verification evidence.

## System Boundaries

This repository defines platform-level governance and operating standards.

In scope:

- Shared baseline governance
- Skill routing and workflow conventions
- Injection and integration scripts
- Quality gates and evaluation loop

Out of scope:

- Business requirement details of individual projects
- Product feature specifications
- Project-specific architecture decisions beyond baseline constraints

## Canonical References

1. Baseline governance:
	- common-prompt/baseline/README.md
	- common-prompt/baseline/01-design-principles.md
	- common-prompt/baseline/02-architecture.md
	- common-prompt/baseline/03-coding-standards.md
	- common-prompt/baseline/04-testing-standards.md
	- common-prompt/baseline/05-git-workflow.md
2. System platform docs:
	- system-platform/README.md
	- system-platform/01-positioning.md
	- system-platform/02-operating-model.md
	- system-platform/03-skill-quality-gate.md
	- system-platform/04-evaluation-loop.md
	- system-platform/quickstart-card.md

## Weekly Review Contract

Run one system review each week with a fixed format.

Inputs:

1. Task success rate
2. Rework rate
3. Automation coverage
4. Top 3 failure categories

Outputs:

1. One rule/skill improvement with owner
2. One workflow simplification with expected impact
3. One risk item with mitigation and deadline

## Quality Gate For Changes

Any platform change is accepted only when all items pass:

1. Scope and boundary impact are explicit.
2. Validation evidence is attached.
3. Rollback path is available.
4. Documentation is synchronized.
5. Baseline compatibility is preserved.

## Execution Rule For New Projects

Use the unified injection entrypoint:

- scripts/inject-current-project.sh

Two supported execution modes are documented in:

- system-platform/quickstart-card.md

## Evolution Rule

This charter is a living document.
Updates must be driven by measured feedback from real project execution,
not by ad-hoc preference changes.
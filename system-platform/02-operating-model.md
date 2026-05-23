# 02 Operating Model

## Execution Layers

1. Governance layer: AGENTS/CLAUDE/Copilot instructions and baseline references.
2. Skill layer: reusable task-focused skills with clear trigger boundaries.
3. Workflow layer: orchestrated execution paths (dev, review, QA, ship).

## Standard Input

- Goal
- Scope
- Constraints
- Acceptance criteria

## Standard Output

- Implemented changes
- Verification evidence
- Risks and fallback notes

## Non-Negotiable Rules

- Use symlink-based shared assets by default.
- Keep module boundaries explicit.
- Prefer deterministic and reversible operations.

## Escalation Conditions

- Destructive operation is required.
- Baseline rules conflict with urgent requirements.
- Verification is inconclusive.

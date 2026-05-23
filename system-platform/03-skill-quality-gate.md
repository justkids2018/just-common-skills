# 03 Skill Quality Gate

## Entry Criteria

- Clear trigger statement
- Defined inputs and outputs
- Explicit boundaries and non-goals

## Design Qualification (Three-Question Test)

Before implementation, every skill must answer:

1. What exact job does this skill perform?
2. When should this skill activate (at least 5 trigger phrases)?
3. What does perfect output look like (with one concrete example)?

If any answer is vague, the skill is not ready for release.

## Quality Dimensions

1. Accuracy: task intent is correctly matched.
2. Determinism: repeated execution gives consistent outcomes.
3. Safety: no bypass of high-risk guardrails.
4. Maintainability: docs and behavior stay aligned.
5. Recoverability: rollback path is available when needed.

## Release Checklist

- [ ] Trigger and routing are unambiguous.
- [ ] Happy path and failure path are both defined.
- [ ] Baseline alignment is verified.
- [ ] Example usage is documented.
- [ ] Regression checks pass.

## Validation Qualification (Three-Scenario Test)

Each skill revision must pass:

1. Happy path: common input covering most real usage.
2. Edge case: incomplete or irregular input.
3. Stress case: largest realistic input and complexity.

For every failure, add a specific instruction or example, then rerun all three scenarios.

## Workflow Skill Addendum

For workflow/orchestrator skills, the following are mandatory:

1. Stage model with named checkpoints.
2. Stage-level success/failure criteria.
3. Resume strategy after interruption.
4. Artifact and log output contract.
5. Explicit human-in-the-loop points for auth/approval/high-risk actions.

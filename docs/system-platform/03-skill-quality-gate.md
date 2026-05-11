# 03 Skill Quality Gate

## Entry Criteria

- Clear trigger statement
- Defined inputs and outputs
- Explicit boundaries and non-goals

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

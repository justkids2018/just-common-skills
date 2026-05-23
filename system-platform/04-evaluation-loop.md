# 04 Evaluation Loop

## Goal

Create a measurable feedback loop for continuous skill and workflow improvement.

## Metrics

- Task success rate
- Rework rate
- Time to complete
- Safety incident count
- Rule compliance rate
- Four-artifact completeness rate (`SPEC`, `solution`, `RUN_LOG`, `DIAGNOSIS` on failure)

## Loop

1. Collect execution evidence.
2. Identify failures and drift patterns.
3. Update skill docs or routing rules.
4. Re-run representative scenarios.
5. Publish changes with summary.

## Evidence Contract

For each task run, evidence should map to the four-artifact standard:

1. `SPEC.md`: task contract and acceptance boundaries.
2. `solution.*`: implementation output.
3. `RUN_LOG.md`: command, exit code, and output evidence.
4. `DIAGNOSIS.md`: mandatory when run result is `FAIL`.

If `RUN_LOG.md` shows `FAIL` without `DIAGNOSIS.md`, mark as non-compliant.

## Cadence

- Weekly: quick quality review
- Monthly: baseline and routing alignment review
- Release cycle: risk-focused deep review

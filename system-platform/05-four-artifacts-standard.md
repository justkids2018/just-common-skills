# 05 Four Artifacts Standard

## Goal

Standardize execution evidence into four mandatory artifacts so runs are auditable and comparable.

## Artifact Set

1. `SPEC.md`: task contract and acceptance criteria.
2. `solution.*`: implementation output for current task.
3. `RUN_LOG.md`: execution evidence from build/test/run.
4. `DIAGNOSIS.md`: structured failure diagnosis and patch plan.

## Ownership

- `SPEC.md`: produced by planning/execution workflow (usually `just-dev-pipeline`).
- `solution.*`: produced by implementation step.
- `RUN_LOG.md`: produced by verification workflow (usually `just-qa`).
- `DIAGNOSIS.md`: produced by investigation workflow (usually `just-investigate`).

## Minimum Fields

### `SPEC.md`

- Task
- Required Skills
- Inputs/Outputs API
- Constraints
- Acceptance Criteria

### `RUN_LOG.md`

- Result (`PASS` or `FAIL`)
- Command(s)
- Exit Code
- Stdout (verbatim)
- Stderr/Traceback (verbatim)
- Summary

### `DIAGNOSIS.md`

- Failure Signature
- Root Cause
- Evidence
- Affected Scope
- Patch Plan (imperative steps)
- Regression Risk
- Verification Plan

## Process Rules

1. Every task execution must produce or update `RUN_LOG.md`.
2. Any failure must produce `DIAGNOSIS.md` before large-scope fixes.
3. Any successful rerun after failure should update `RUN_LOG.md` and keep the previous diagnosis history in git.
4. Artifacts must be plain text or markdown and committed with task changes when applicable.

See [06-compliance-checklist.md](06-compliance-checklist.md) for the minimal run-time enforcement checklist.

## Evaluation Mapping

- Success rate: derive from `RUN_LOG.md` result fields.
- Rework rate: count failure-to-pass cycles per task.
- Time to complete: compare first SPEC timestamp and final PASS timestamp.
- Rule compliance: check required fields completeness in all four artifacts.

## Recommended Location

For feature work in this repository, keep artifacts under:

`doc/features/<feature>/runs/<task-id>/`

Example:

`doc/features/user-auth/runs/task-02/`

Containing:

- `SPEC.md`
- `solution.diff.md` or language-specific solution files
- `RUN_LOG.md`
- `DIAGNOSIS.md` (only when failure happens)
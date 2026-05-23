# 06 Compliance Checklist

## Purpose

Use this tiny checklist at the end of each task run to ensure the four-artifact standard is actually executed, not only documented.

## When To Use

- After each task run in `just-dev-pipeline`
- Before commit/PR in step 6
- During weekly quality review

## Task-Level Checklist (30-second)

- [ ] `SPEC.md` exists and includes task + acceptance criteria.
- [ ] `solution.*` exists and matches current task scope.
- [ ] `RUN_LOG.md` exists with `Result`, `Command`, and `Exit Code`.
- [ ] If `RUN_LOG.md` is `FAIL`, `DIAGNOSIS.md` exists.
- [ ] If `DIAGNOSIS.md` exists, it includes `Root Cause` and `Patch Plan`.

## Release-Level Checklist (before PR)

- [ ] All changed tasks have run-level artifacts under `doc/features/<feature>/runs/<task-id>/`.
- [ ] No task has `FAIL` in `RUN_LOG.md` without a linked diagnosis.
- [ ] Artifact fields are complete enough for metric extraction.
- [ ] Final PR summary references the run artifacts path.

## Non-Compliance Handling

1. Mark current step as `DONE_WITH_CONCERNS` or `BLOCKED`.
2. Fill missing artifact fields first.
3. Re-run verification and update `RUN_LOG.md`.
4. Continue only after checklist is green.

## Ownership

- Primary owner: `just-dev-pipeline`
- Verification support: `just-qa`
- Failure analysis support: `just-investigate`
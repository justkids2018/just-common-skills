---
name: just-<workflow-name>
description: <Specific workflow description with trigger phrases and non-goals>
---

# Workflow Skill Template

## Purpose

State the exact job this workflow skill performs and what it does not do.

## Three-Question Design Test

1. What exact job does this skill perform?
2. When should it activate? List at least 5 trigger phrases.
3. What does perfect output look like? Include one concrete output example.

## Inputs

- Goal
- Scope
- Constraints
- Required credentials or approvals

## Outputs

- Primary outcome
- Artifact list
- Verification evidence

## Stage Model

Define stages in deterministic order:

1. Stage name
   - Input:
   - Action:
   - Success criteria:
   - Failure criteria:
   - Retry policy:
   - Human checkpoint (Y/N):

Repeat for each stage.

## Status Protocol

Every stage must end with one status:

- DONE
- DONE_WITH_CONCERNS
- BLOCKED

## Resume and Recovery

- Checkpoint location:
- Resume rules:
- Rollback rules:

## Evidence Contract

Persist run outputs under:

doc/workflows/<workflow-name>/runs/<run-id>/

Required files:

1. run.json
2. state.json
3. events.log
4. RUN_LOG.md
5. DIAGNOSIS.md (mandatory on failure)
6. artifacts/

## Validation Matrix (Three-Scenario Test)

1. Happy path
   - Input:
   - Expected result:
2. Edge case
   - Input:
   - Expected result:
3. Stress case
   - Input:
   - Expected result:

## Safety Constraints

1. No destructive action without explicit confirmation.
2. No hidden side effects.
3. No bypass of governance policies.

## Example Invocation

Provide one realistic user prompt and expected execution outline.

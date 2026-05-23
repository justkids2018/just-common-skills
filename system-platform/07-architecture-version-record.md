# 07 Architecture Version Record

## Purpose

Create one architecture record per release so changes are traceable and analyzable over time.

## Rule

Each released version must include exactly one architecture record.

Release index:

- [docs/releases/README.md](../../docs/releases/README.md)

Recommended path:

`docs/releases/<version>/architecture-record.md`

Example:

`docs/releases/v0.8.0/architecture-record.md`

## Required Sections

1. Version and date
2. Change summary (what changed)
3. Architecture impact (layers/modules/interfaces)
4. Trade-offs and rejected options
5. Risks and mitigations
6. Verification evidence links (`RUN_LOG`, `DIAGNOSIS`, tests)
7. Rollback plan
8. Next iteration focus

## Minimum Quality Bar

- Must reference actual changed files or modules.
- Must include at least one explicit trade-off decision.
- Must include risk owner and mitigation action.
- Must be updated before release note is finalized.

## Integration With Existing Flow

- `just-dev-pipeline`: produces run evidence and implementation context.
- `just-document-release`: writes and finalizes the architecture record.
- Evaluation loop: uses version records for monthly architecture drift review.

## Review Questions

Use these questions in release review:

1. Did this version increase coupling or reduce it?
2. Did this version add irreversible decisions?
3. Are context/memory assumptions documented and testable?
4. What should be simplified in the next version?
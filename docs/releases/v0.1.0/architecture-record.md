# Architecture Record - v0.1.0

## 1. Version Meta

- Version: v0.1.0
- Date: 2026-05-11
- Owner: just-common-skills maintainers

## 2. Change Summary

- Feature or objective:
  Build the first usable platform baseline for shared AI development governance, skill execution, and evidence-driven iteration.
- Scope:
  Platform governance docs, skill contracts, project injection workflow, release documentation discipline, and self-dogfooding enablement.
- Key changed modules/files:
  - system-platform/05-four-artifacts-standard.md
  - system-platform/06-compliance-checklist.md
  - system-platform/07-architecture-version-record.md
  - system-platform/templates/architecture-record.template.md
  - skills/just-dev-pipeline/SKILL.md
  - skills/just-qa/SKILL.md
  - skills/just-investigate/SKILL.md
  - skills/just-document-release/SKILL.md
  - scripts/inject-current-project.sh
  - scripts/self-dogfood.sh
  - docs/quickstart-new-project.md
  - system-platform/quickstart-card.md
  - README.md

## 3. Architecture Impact

- Governance layer impact:
  Established explicit system-platform governance and release-level architecture recording rule.
- Skill layer impact:
  Standardized execution evidence across skills using four artifacts and task-end compliance checks.
- Workflow/runtime impact:
  Injection workflow now supports clean-first backup, thin entry mode, legacy System.md cleanup, and hub self-dogfooding.
- Interface/contract changes:
  Added explicit artifact contract: SPEC, solution, RUN_LOG, DIAGNOSIS.

## 4. Trade-Off Decisions

### Decision A
- Option chosen:
  Keep existing repository structure and add standards/checklists incrementally.
- Options rejected:
  1) Full runtime orchestrator rebuild now.
  2) Containerized multi-agent execution stack now.
- Why:
  Current stage needs execution consistency and evidence quality first; large runtime rebuild would increase complexity before baseline metrics exist.

### Decision B
- Option chosen:
  Add self-dogfooding script that links runtime assets without rewriting AGENTS.md and CLAUDE.md.
- Options rejected:
  Reinject this hub as a normal target project with full overwrite/merge behavior.
- Why:
  Self-dogfooding should validate shared assets while minimizing risk to canonical governance files.

## 5. Risks And Mitigations

| Risk | Severity | Mitigation | Owner |
|------|----------|------------|-------|
| Team bypasses checklist under delivery pressure | Medium | Make checklist default in just-dev-pipeline and quickstart cards | Platform maintainers |
| Artifact completeness drifts across projects | Medium | Enforce release architecture record and monthly evidence review | Platform maintainers |
| Injection scripts accidentally remove desired local files | Medium | Keep clean-first backup path and require verification commands | Script maintainer |
| Governance/docs become too heavy for daily use | Medium | Keep only one main execution path and simplify monthly | Platform maintainers |

## 6. Verification Evidence

- RUN_LOG:
  Verified inject-current-project.sh with reference-entry and clean-first in target project kiki_chain. Symlink checks passed.
- DIAGNOSIS (if any):
  Not applicable for this governance release.
- Test summary:
  Shell-level verification only (injection, symlink checks, legacy file cleanup checks).
- Manual validation:
  Confirmed presence of new system-platform docs and templates in target project through symlinked path.

## 7. Rollback Plan

- Trigger:
  Injection behavior causes unintended file removal or project governance mismatch.
- Steps:
  1) Restore files from .ai/inject-backup/<timestamp>/ in the target project.
  2) Re-run injection with --no-clean-first if merge behavior is needed.
  3) Revert specific script/doc commits in this hub if defect is confirmed.
- Expected restoration state:
  Target project returns to pre-injection governance files and link layout.

## 8. Next Iteration Focus

- Simplification target:
  Reduce cognitive overhead by keeping one default workflow path and a short release checklist.
- Debt to retire:
  Add machine-readable output contract blocks for qa/investigate to support automated metrics extraction.
- Metrics to improve:
  Four-artifact completeness rate, failure-to-diagnosis compliance, and rework cycle count.

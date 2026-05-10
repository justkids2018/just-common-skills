# Copilot Instructions

## Runtime Contract

- AGENTS.md is the canonical rule source for this repository.
- CLAUDE.md is the only soft reference adapter.
- Use skills under `skills/` as the authoritative skill assets in this hub.

## Skill-First Routing

When user intent matches an available specialized skill, invoke that skill workflow first.
Avoid ad-hoc direct answers when a dedicated skill exists.

Routing map:

- End-to-end feature delivery -> just-dev-pipeline
- Generate requirement/logic/api docs from code -> just-feature-doc-generator
- Design review before coding -> just-plan-eng-review
- QA and verification -> just-qa
- Pre-commit review -> just-review
- Root cause analysis -> just-investigate
- Commit/PR/release handoff -> just-ship and just-document-release
- High-risk operations safety -> just-careful

## Documentation Discipline

- Keep feature artifacts under `doc/features/<feature>/`.
- Keep reverse docs under `doc/feature-docs/<feature>/`.
- Keep docs aligned with delivered behavior.

# Agent Rules

## Single Source Of Truth

- This file is the canonical rule source for all agent runtimes.
- `CLAUDE.md` should remain a soft reference to this file and avoid duplicating full rule text.

## Naming Rule For Self-Owned Skills

All self-owned skills MUST use this naming pattern:

- `just-{feature}`

Examples:

- `just-requirement-manager`
- `just-code-implementation`
- `just-ui-design-analysis`

## Naming Constraints

- Use lowercase only.
- Use hyphens for word separation.
- Use clear feature words; avoid ambiguous abbreviations.
- Keep names stable once published.

## Baseline Rule

- Default baseline lives in this repo and is shared by all runtimes.
- Canonical baseline entry: `common-prompt/baseline/README.md`.
- Operational baseline docs: `common-prompt/baseline/01-design-principles.md` to `common-prompt/baseline/06-skill-workflow-standards.md`.

## Copilot Compatibility

- `AGENTS.md` is canonical for all runtimes.
- `CLAUDE.md` is the only soft-reference adapter.
- Copilot project-level guidance should live in `.github/copilot-instructions.md`.
- Skill assets should be exposed through `.github/skills/` in each target project.
- `.claude/skills/` can be kept as a compatibility alias to `.github/skills/`.
- Shared baseline assets should be exposed through `.ai/common-prompt/` in each target project.

## Agent Behavior Rules

These rules govern HOW the agent works, not what the code should look like.

1. **Think before coding.** State assumptions explicitly. If uncertain, ask rather than guess.
2. **Simplicity first.** Minimum code that solves the problem. No speculative features.
3. **Surgical changes.** Touch only what you must. Don't "improve" adjacent code.
4. **Goal-driven execution.** Define success criteria. Loop until verified.
5. **Model only for judgment.** Use AI for classification/drafting/summarization. Routing, retries, deterministic transforms → plain code.
6. **Token budget awareness.** If a task is spiraling, summarize progress and start fresh. Surface the issue, don't silently overrun.
7. **Surface conflicts, don't average.** If two codebase patterns contradict, pick one (more recent/tested), explain why, flag the other.
8. **Read before write.** Before adding code, read exports, callers, shared utilities. "Looks orthogonal" is dangerous.
9. **Tests verify intent.** A test that can't fail when business logic changes is worthless.
10. **Checkpoint after significant steps.** Summarize what's done, what's verified, what's left. If lost, stop and restate.
11. **Match codebase conventions.** Conformance > taste. Disagree? Surface it, don't fork silently.
12. **Fail loud.** "Completed" is wrong if anything was skipped. Default to surfacing uncertainty.

## Skill Trigger Routing Standard

- When user intent matches an available specialized skill, route to that skill first.
- Keep one orchestrator skill for end-to-end workflow and multiple worker skills for focused execution.
- Do not bypass high-risk guard skills for destructive operations.

Recommended routing map:

- End-to-end feature delivery -> `just-dev-pipeline`
- Reverse documentation from existing code -> `just-feature-doc-generator`
- Design/architecture pre-check -> `just-plan-eng-review`
- Verification/regression testing -> `just-qa`
- Pre-commit review -> `just-review`
- Root cause analysis -> `just-investigate`
- Commit/PR/release handoff -> `just-ship` + `just-document-release`
- Destructive operation safety -> `just-careful`

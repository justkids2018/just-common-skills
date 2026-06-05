# Guide

## Execution Notes

1. Start with rule resolution, not code edits.
2. Detect first, then fix in small, verifiable batches.
3. Always include one before/after evidence point for each fixed blocker.
4. Prioritize critical flows: login, checkout, submit, navigation.

## Rule Resolution Procedure

1. Search project-level files: `AGENTS.md`, `Agent.md`, `copilot-instructions.md`, `docs/**design**`.
2. Extract explicit numeric constraints (font size, radius, spacing, touch target).
3. Merge with baseline defaults:
   - mobile: `rules/ios-mobile-baseline.md`
   - web: `rules/web-baseline.md`
4. Produce active rule set summary before fixing.

## Suggested Output Format

```md
## UI Compliance Report

### Active Rules
- source
- mode
- key numeric constraints

### Findings
- [Severity] issue | impacted screen | file

### Fixes Applied
- file + what changed

### Verification
- checked states/screens

### Verdict
PASS | FAIL
```

## Boundaries

- Stay inside requested scope and changed screens.
- Do not enforce baseline rules when project rules explicitly override them.
- If runtime validation is unavailable, provide static-check limitations explicitly.

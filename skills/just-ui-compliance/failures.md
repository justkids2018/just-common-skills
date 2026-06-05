# Failure Patterns

## Failure 1: Skipping Project Rules

### Symptom
Fixes follow default iOS/web values but conflict with project design tokens.

### Root Cause
Did not read `AGENTS.md`/`Agent.md` before auditing.

### Prevention
Always run rule resolution first and print the active rule source.

---

## Failure 2: Audit Without Real Fixes

### Symptom
Only outputs suggestions, no code changes.

### Root Cause
Treated this as documentation task, not remediation task.

### Prevention
For each blocker/high issue, require a concrete patch or explicit blocker reason.

---

## Failure 3: Typography Looks Correct at 100% Only

### Symptom
Text is fine at default scale but clipped at larger text scale.

### Root Cause
No dynamic type/browser zoom checks.

### Prevention
Re-check at larger text scale (mobile) or zoom (web).

---

## Failure 4: Touch Target Too Small

### Symptom
Buttons visually correct but hard to tap.

### Root Cause
Checked style, skipped actual hit area dimensions.

### Prevention
Enforce minimum touch target from active rule set.

---

## Failure 5: One-State Verification

### Symptom
Default state passes; pressed/disabled/error states break.

### Root Cause
Validation only on initial screen state.

### Prevention
Validate at least initial + after action + error state.

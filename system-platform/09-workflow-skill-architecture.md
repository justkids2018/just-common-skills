# 09 Workflow Skill Architecture

## Goal

Define a stable architecture for building and operating skill systems that support long, stateful workflows.

## Layered Architecture

1. Governance layer
   - Global rules and constraints.
   - Sources: AGENTS.md, CLAUDE.md, copilot-instructions.md, baseline docs.
2. Routing layer
   - Classifies intent and selects execution mode.
   - Modes: default chat, worker skill, workflow skill, subagent, human-in-the-loop.
3. Orchestration layer
   - Runs stage-based workflows with checkpoints.
   - Delegates narrow actions to worker skills/tools.
4. Capability layer
   - Atomic execution abilities (search, browser actions, scripts, QA, review).
5. Evidence layer
   - Stores state, logs, artifacts, and diagnosis for replay/recovery.

## Workflow Contract

Each workflow must define:

1. Trigger intent and non-goals.
2. Required inputs and constraints.
3. Stage list with deterministic order.
4. Stage success criteria and failure criteria.
5. Checkpoints and status protocol (DONE, DONE_WITH_CONCERNS, BLOCKED).
6. Resume behavior after interruption.
7. Human-in-the-loop stages.
8. Output and artifact schema.

## Recommended Stage Pattern

Use a generic stage pattern for long operations:

1. Preflight
2. Session init
3. Auth
4. Main operation
5. Artifact capture
6. Postprocess
7. Submit/commit
8. Verify
9. Recover/finalize

Not every workflow needs all stages, but stage names and transitions must remain explicit.

## Routing Heuristics

Prefer workflow skill when request has at least two of these:

1. Multiple sequential steps.
2. Cross-tool operations.
3. Stateful execution.
4. Resume requirement.
5. Evidence requirement.

If no matching workflow exists, route to default execution and emit a backlog suggestion for new workflow coverage.

## Evidence Contract

For each workflow run, persist under a deterministic path such as:

doc/workflows/<workflow-name>/runs/<run-id>/

Minimum files:

1. run.json (metadata)
2. state.json (latest checkpoint)
3. events.log (stage timeline)
4. artifacts/ (downloads, screenshots, outputs)
5. RUN_LOG.md (command evidence)
6. DIAGNOSIS.md (required on failure)

## Governance and Safety

1. Destructive actions require explicit confirmation.
2. Auth and external side effects require human approval point.
3. Workflow cannot bypass just-careful or just-investigate policies.

## Operating Cadence

1. Weekly: review routing misses and workflow failures.
2. Monthly: refactor stage boundaries and trigger definitions.
3. Release cycle: regression test representative workflows.

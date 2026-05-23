# Quickstart Card

## Recommended Path Name

Use `system-platform/` for system-level platform contracts.

## Two Execution Modes

Mode A: run from shared hub

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/inject-current-project.sh /absolute/path/to/target-project --force
```

Mode B: run from target project

```bash
cd /absolute/path/to/target-project
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

Centralized-governance mode (thin AGENTS/CLAUDE entry files):

```bash
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force --reference-entry
```

Mode C: enable self-dogfooding in this hub repo

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/self-dogfood.sh
```

## Purpose

Inject shared rules and skills into a target project in symlink mode.

Default execution strategy:

- Backup + clean old managed files first, then reinject.
- Backup location in target project: `.ai/inject-backup/<timestamp>/`.

## Verification

```bash
ls -l .github/skills .claude/skills .ai/common-prompt .ai/system-platform
```

All four path entries should be symlinks.

## Task End Card (5 checks)

At the end of each task run, confirm:

- [ ] `SPEC.md` exists and acceptance criteria are clear.
- [ ] `solution.*` exists and matches current task.
- [ ] `RUN_LOG.md` includes `Result`, `Command`, `Exit Code`.
- [ ] If `RUN_LOG.md` is `FAIL`, `DIAGNOSIS.md` exists.
- [ ] Patch plan and re-run evidence are updated before PR.

Reference: [06-compliance-checklist.md](06-compliance-checklist.md)

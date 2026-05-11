# Quickstart Card

## Recommended Path Name

Use `docs/system-platform/` for system-level platform docs.

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

## Purpose

Inject shared rules and skills into a target project in symlink mode.

## Verification

```bash
ls -l .github/skills .claude/skills .ai/common-prompt
```

All three entries should be symlinks.

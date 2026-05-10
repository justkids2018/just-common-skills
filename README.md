# Shared Skills Hub

This repository is the single source of truth for reusable skills.

## Goal

Keep all reusable skills in one place so multiple projects can apply them directly.

## Structure

- `skills/`: all reusable skills live here.
- `scripts/install-skills.sh`: install shared skills into global runtime paths.
- `scripts/uninstall-skills.sh`: remove globally installed shared skills.
- `scripts/bootstrap-project.sh`: one-command setup for a new project.
- `scripts/new-skill.sh`: scaffold a new skill directory.

## Install For Copilot/Claude Runtimes

Run:

```bash
./scripts/install-skills.sh
```

This installs shared skills to:

- `~/.claude/skills` (default)

Optional install for VS Code prompts mirror:

```bash
./scripts/install-skills.sh --with-vscode-prompts
```

Optional snapshot mode (copy instead of symlink):

```bash
./scripts/install-skills.sh --copy
```

Uninstall:

```bash
./scripts/uninstall-skills.sh
```

## Use In Another Project (legacy symlink style)

You can still create a project-local link manually:

Run:

```bash
ln -s /absolute/path/to/just-common-skills/skills /absolute/path/to/target-project/.claude/skills
```

This creates a symlink:

- `<target-project>/.claude/skills` -> `<this-repo>/skills`

After that, the target project uses the same shared skills directly.

## Bootstrap A New Project (Recommended)

One command to inject governance files, copilot routing, common baseline, and shared skills:

```bash
./scripts/bootstrap-project.sh /absolute/path/to/target-project
```

What it creates in the target project:

- `AGENTS.md` (canonical governance)
- `CLAUDE.md` (soft reference)
- `.github/copilot-instructions.md` (Copilot skill routing)
- `.github/skills` (linked to this repo's `skills/`)
- `.claude/skills` (compatibility alias to `.github/skills`)
- `.ai/common-prompt` (linked to this repo's `common-prompt/`)

Options:

```bash
./scripts/bootstrap-project.sh /absolute/path/to/target-project --copy
./scripts/bootstrap-project.sh /absolute/path/to/target-project --force
```

Quickstart guide:

- [docs/quickstart-new-project.md](docs/quickstart-new-project.md)

For both new and existing projects, use one unified injection command:

```bash
cd /absolute/path/to/target-project
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

This mode merges existing governance files (append/update managed block), creates missing files, and wires shared assets via symlink.

## Add A New Skill

Run:

```bash
./scripts/new-skill.sh just-my-feature
```

Then edit:

- `skills/just-my-feature/SKILL.md`
- `skills/just-my-feature/guide.md`

Naming rule:

- `just-{feature}`
- lowercase + hyphens

## Notes

- Symlink mode means one update in this repo is visible to all linked projects.
- If a project already has its own `.github/skills` or `.claude/skills` directory, back it up first.
- Rule governance uses one source of truth: `AGENTS.md` is canonical, `CLAUDE.md` is a soft reference adapter.
- Baseline governance uses one source of truth: `common-prompt/baseline/` is canonical.

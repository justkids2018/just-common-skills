# Shared Skills Hub

This repository is the single source of truth for reusable skills.

# 目的一句话：
 把公共规则和 skills 接入项目，并且始终使用软引用（symlink，不 copy）。
## Goal

Keep all reusable skills in one place so multiple projects can apply them directly.

## System Charter

The platform-level mission, operating model, and review contract are defined here:

- [system-platform/system-charter.md](system-platform/system-charter.md)

System platform operation docs are here:

- [system-platform/README.md](system-platform/README.md)

## Structure

- `skills/`: all reusable skills live here.
- `scripts/install-skills.sh`: install shared skills into global runtime paths.
- `scripts/uninstall-skills.sh`: remove globally installed shared skills.
- `scripts/inject-current-project.sh`: one-command inject/merge setup for any project (symlink mode).
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

## Inject Into Any Project (Recommended)

Use one script with two equivalent execution modes.

Default behavior of the injector:

- Clean-first: backup + remove existing managed files/links, then reinject.
- Backup path: `.ai/inject-backup/<timestamp>/` inside target project.
- Optional: pass `--no-clean-first` if you explicitly want merge/update behavior.

Mode A: run from shared hub and pass target path

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/inject-current-project.sh /absolute/path/to/target-project --force
```

Mode B: run inside target project and call shared script

```bash
cd /absolute/path/to/target-project
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh --force
```

Optional centralized-governance mode (recommended when you want project-side thin entries):

```bash
bash /absolute/path/to/just-common-skills/scripts/inject-current-project.sh /absolute/path/to/target-project --force --reference-entry
```

In this mode, `AGENTS.md` and `CLAUDE.md` are replaced by thin entry files that reference shared governance.

What it creates/wires in the target project:

- `AGENTS.md` (canonical governance)
- `CLAUDE.md` (soft reference)
- `.github/copilot-instructions.md` (Copilot skill routing)
- `.github/skills` (linked to this repo's `skills/`)
- `.claude/skills` (compatibility alias to `.github/skills`)
- `.ai/common-prompt` (linked to this repo's `common-prompt/`)
- `.ai/system-platform` (linked to this repo's `system-platform/`)

Quickstart guide:

- [docs/quickstart-new-project.md](docs/quickstart-new-project.md)

Both modes merge existing governance files (append/update managed block), create missing files, and wire shared assets via symlink.

## Self Dogfooding (This Repo)

This hub repository can also consume the same linked runtime assets to validate its own setup model.

Run:

```bash
cd /absolute/path/to/just-common-skills
bash ./scripts/self-dogfood.sh
```

What it wires locally:

- `.github/skills` -> `skills/`
- `.claude/skills` -> `.github/skills`
- `.ai/common-prompt` -> `common-prompt/`
- `.ai/system-platform` -> `system-platform/`

Safety note:

- This mode does not rewrite `AGENTS.md` or `CLAUDE.md`.

## Tell AI What To Do

If you are in another project and want AI to perform setup correctly, tell it this:

```text
Read /Users/qisd/Documents/development/ai/just-common-skills/README.md first.
Then execute symlink-only setup (no copy) for current project.
If current directory is the target project, run:
bash /Users/qisd/Documents/development/ai/just-common-skills/scripts/inject-current-project.sh --force
If running from hub directory, run:
bash /Users/qisd/Documents/development/ai/just-common-skills/scripts/inject-current-project.sh /absolute/path/to/target-project --force
After execution, verify .github/skills and .ai/common-prompt are symlinks.
```

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

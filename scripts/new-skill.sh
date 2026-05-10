#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'EOF'
Create a new skill scaffold.

Usage:
  scripts/new-skill.sh <skill-name>
  scripts/new-skill.sh -h | --help

Naming rule:
  - Must match: just-{feature}
  - Allowed chars: lowercase letters, digits, hyphens
  - Regex: ^just-[a-z0-9]+(-[a-z0-9]+)*$

What it creates:
  - skills/<skill-name>/SKILL.md
  - SKILL.md frontmatter name equals folder name

Example:
  scripts/new-skill.sh just-api-doc-sync

Generated path:
  skills/just-api-doc-sync/SKILL.md
EOF
}

if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
  show_help
  exit 0
fi

if [[ $# -ne 1 ]]; then
  show_help >&2
  exit 1
fi

SKILL_NAME="$1"
if [[ ! "$SKILL_NAME" =~ ^just-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Invalid skill name: $SKILL_NAME" >&2
  echo "Use pattern: just-{feature} with lowercase letters, digits, and hyphens." >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$HUB_ROOT/skills/$SKILL_NAME"
SKILL_FILE="$SKILL_DIR/SKILL.md"

if [[ -e "$SKILL_DIR" ]]; then
  echo "Skill already exists: $SKILL_DIR" >&2
  exit 3
fi

mkdir -p "$SKILL_DIR"
cat > "$SKILL_FILE" <<EOF
---
name: $SKILL_NAME
description: Briefly describe what this skill does and when to use it.
---

# ${SKILL_NAME}

## Purpose

Describe when this skill should be used.

## Inputs

List expected inputs.

## Outputs

List expected outputs.

## Steps

1. Describe step 1.
2. Describe step 2.
3. Describe step 3.

## Constraints

List guardrails and boundaries.
EOF

echo "Created skill scaffold: $SKILL_FILE"

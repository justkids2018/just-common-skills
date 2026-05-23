#!/usr/bin/env bash
set -euo pipefail

# Validate that each skill file includes the mandatory Three-Question section.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUB_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="$HUB_ROOT/skills"

if [[ ! -d "$SKILLS_ROOT" ]]; then
  echo "Skills directory not found: $SKILLS_ROOT" >&2
  exit 2
fi

missing=0
while IFS= read -r -d '' file; do
  if ! rg -q '^## Three-Question Design Test$' "$file"; then
    echo "[MISSING] $file -> missing section: ## Three-Question Design Test"
    missing=1
    continue
  fi

  if ! rg -q 'What exact job does this skill perform\?' "$file"; then
    echo "[MISSING] $file -> missing Q1"
    missing=1
  fi

  if ! rg -q 'When should it activate\? List at least 5 trigger phrases\.' "$file"; then
    echo "[MISSING] $file -> missing Q2"
    missing=1
  fi

  if ! rg -q 'What does perfect output look like\? Include one concrete output example\.' "$file"; then
    echo "[MISSING] $file -> missing Q3"
    missing=1
  fi
done < <(find "$SKILLS_ROOT" -type f -name 'SKILL.md' -print0)

if [[ $missing -eq 1 ]]; then
  echo "\nValidation failed: some skills do not meet baseline 06 requirements." >&2
  exit 1
fi

echo "All skills passed baseline 06 three-question validation."

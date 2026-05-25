#!/usr/bin/env bash
set -euo pipefail

# Package just-common-skills into a distributable zip file
# Consolidates all skills/*/SKILL.md into a single root SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$PROJECT_ROOT/dist"
STAGING_DIR="$DIST_DIR/staging"
ZIP_FILE="$DIST_DIR/just-common-skills.zip"

# Cleanup on exit
cleanup() {
    if [ -d "$STAGING_DIR" ]; then
        rm -rf "$STAGING_DIR"
    fi
}
trap cleanup EXIT

echo "📦 Packaging just-common-skills..."

# Create dist directory
mkdir -p "$DIST_DIR"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy all git-tracked files
cd "$PROJECT_ROOT"
git ls-files --cached --others --exclude-standard | while IFS= read -r file; do
    # Skip certain files
    case "$file" in
        .git*|.github/*|dist/*|*.pyc|__pycache__/*|node_modules/*|.DS_Store)
            continue
            ;;
    esac

    # Skip if file doesn't exist (deleted but still in index)
    if [ ! -e "$file" ]; then
        continue
    fi

    # Skip if it's a directory (shouldn't happen with git ls-files, but be safe)
    if [ -d "$file" ]; then
        continue
    fi

    # Create directory structure
    target_dir="$STAGING_DIR/$(dirname "$file")"
    mkdir -p "$target_dir"
    cp "$file" "$STAGING_DIR/$file"
done

# Consolidate all SKILL.md files into root SKILL.md
echo "🔗 Consolidating SKILL.md files..."

CONSOLIDATED_SKILL="$STAGING_DIR/SKILL.md"

# Start with dispatcher template
cp "$SCRIPT_DIR/dispatcher.md" "$CONSOLIDATED_SKILL"

# Find all skill directories and append their SKILL.md
find "$PROJECT_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | sort | while IFS= read -r skill_dir; do
    skill_name="$(basename "$skill_dir")"

    # Look for SKILL.md or skill.md
    skill_file=""
    if [ -f "$skill_dir/SKILL.md" ]; then
        skill_file="$skill_dir/SKILL.md"
    elif [ -f "$skill_dir/skill.md" ]; then
        skill_file="$skill_dir/skill.md"
    else
        echo "⚠️  Warning: No SKILL.md found in $skill_name"
        continue
    fi

    echo "  Adding $skill_name..."

    # Add section header
    echo "" >> "$CONSOLIDATED_SKILL"
    echo "# SKILL: $skill_name" >> "$CONSOLIDATED_SKILL"
    echo "" >> "$CONSOLIDATED_SKILL"

    # Strip YAML frontmatter and append content
    awk '
        BEGIN { in_frontmatter = 0; frontmatter_count = 0 }
        /^---$/ {
            frontmatter_count++
            if (frontmatter_count <= 2) {
                in_frontmatter = (frontmatter_count == 1)
                next
            }
        }
        !in_frontmatter { print }
    ' "$skill_file" >> "$CONSOLIDATED_SKILL"
done

# Remove individual SKILL.md files from staging
find "$STAGING_DIR/skills" -name "SKILL.md" -o -name "skill.md" | xargs rm -f

# Validate: ensure exactly one SKILL.md at root
skill_count=$(find "$STAGING_DIR" -maxdepth 1 -name "SKILL.md" | wc -l)
if [ "$skill_count" -ne 1 ]; then
    echo "❌ Error: Expected exactly 1 root SKILL.md, found $skill_count"
    exit 1
fi

# Create zip file
echo "📦 Creating zip archive..."
cd "$STAGING_DIR"
rm -f "$ZIP_FILE"
zip -r "$ZIP_FILE" . -q

# Report size
size=$(du -h "$ZIP_FILE" | cut -f1)
echo "✅ Package created: $ZIP_FILE ($size)"

# Cleanup staging
rm -rf "$STAGING_DIR"

echo "✅ Packaging complete!"

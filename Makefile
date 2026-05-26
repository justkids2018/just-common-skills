.PHONY: test validate-skills validate-baseline validate-scripts check-symlinks package help

# Default target
help:
	@echo "Just-Common-Skills Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make test              - Run all validation checks"
	@echo "  make validate-skills   - Validate skill structure"
	@echo "  make validate-baseline - Check baseline documentation"
	@echo "  make validate-scripts  - Verify scripts are executable and have no syntax errors"
	@echo "  make check-symlinks    - Find broken symlinks"
	@echo "  make package           - Create distributable zip package"
	@echo "  make install           - Install skills globally"
	@echo "  make uninstall         - Uninstall skills globally"
	@echo ""

# Run all tests
test: validate-skills validate-baseline validate-scripts check-symlinks
	@echo "✅ All validation checks passed"

# Validate skills structure
validate-skills:
	@echo "Validating skills structure..."
	@./scripts/validate-skills.sh
	@echo "✅ Skills validation passed"

# Check baseline documentation
validate-baseline:
	@echo "Checking baseline documentation..."
	@for doc in \
		common-prompt/baseline/01-design-principles.md \
		common-prompt/baseline/02-architecture.md \
		common-prompt/baseline/03-coding-standards.md \
		common-prompt/baseline/04-testing-standards.md \
		common-prompt/baseline/05-git-workflow.md \
		common-prompt/baseline/06-skill-workflow-standards.md; do \
		if [ ! -f "$$doc" ]; then \
			echo "❌ Missing baseline document: $$doc"; \
			exit 1; \
		fi; \
	done
	@echo "✅ All baseline documents present"

# Verify scripts
validate-scripts:
	@echo "Validating scripts..."
	@for script in scripts/*.sh; do \
		if [ ! -x "$$script" ]; then \
			echo "❌ Script not executable: $$script"; \
			exit 1; \
		fi; \
		bash -n "$$script" || exit 1; \
	done
	@echo "✅ All scripts are valid and executable"

# Check for broken symlinks
check-symlinks:
	@echo "Checking for broken symlinks..."
	@broken=$$(find . -type l ! -exec test -e {} \; -print 2>/dev/null | grep -v '^\./\.github/skills$$' | grep -v '^\./\.claude/skills$$' | grep -v '^\./\.ai/' || true); \
	if [ -n "$$broken" ]; then \
		echo "❌ Found broken symlinks:"; \
		echo "$$broken"; \
		exit 1; \
	fi
	@echo "✅ No broken symlinks found"

# Install skills globally
install:
	@./scripts/install-skills.sh

# Uninstall skills globally
uninstall:
	@./scripts/uninstall-skills.sh

# Create distributable package
package:
	@./scripts/package-skill.sh

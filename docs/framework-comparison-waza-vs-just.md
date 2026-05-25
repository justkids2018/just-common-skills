# Framework Comparison: Waza vs Just-Common-Skills

## Executive Summary

**Waza (tw93)**: Minimalist engineering habits framework with 8 carefully curated skills focused on individual developer workflows.

**Just-Common-Skills (yours)**: Enterprise-grade orchestration platform with 14+ skills designed for team collaboration and production delivery.

---

## 1. Core Philosophy

### Waza
- **"Engineering habits you already know, turned into skills Claude can run"**
- Deliberately incomplete: "Eight skills for the habits that actually matter"
- Anti-over-specification: "Every rule the author writes becomes a ceiling"
- Individual developer focus: personal workflow optimization
- Manual chaining: no auto-triggers, user controls every transition

### Just-Common-Skills
- **"Single source of truth for reusable skills across projects"**
- Comprehensive coverage: orchestrator + workers pattern (1+7 core + specialized)
- Explicit governance: AGENTS.md as canonical rule source, baseline standards
- Team/enterprise focus: multi-project consistency, production delivery
- Workflow orchestration: explicit phase gates, checkpoint recovery

**Key Difference**: Waza optimizes for individual autonomy; Just optimizes for organizational consistency.

---

## 2. Architecture

### Waza: Trilogy Structure
```
Kaku (書く) - writes code
Waza (技)   - drills habits  
Kami (紙)   - ships documents
```

**8 Core Skills**:
- `/think` - Pre-build design challenge
- `/design` - Frontend UI iteration
- `/check` - Pre-merge review + release
- `/hunt` - Systematic debugging
- `/write` - Prose editing (CN/EN)
- `/learn` - 6-phase research workflow
- `/read` - URL/PDF content fetching
- `/health` - Agent audit

**Skill Structure**:
```
skills/<name>/
  ├── SKILL.md (main instructions)
  ├── references/ (docs, failure patterns)
  └── helpers/ (scripts)
```

### Just-Common-Skills: Orchestrator + Workers

**1 Orchestrator**:
- `just-dev-pipeline` - End-to-end 6-step delivery workflow

**7 Core Workers**:
- `just-plan-eng-review` - Pre-implementation architecture review
- `just-qa` - Post-implementation verification + fixes
- `just-review` - Pre-commit code review
- `just-ship` - Commit/PR/release handoff
- `just-document-release` - Post-ship documentation sync
- `just-investigate` - Root cause analysis
- `just-careful` - Destructive operation safety

**7 Specialized Skills**:
- `just-github-workflows` - CI/CD template replication
- `just-deploy-release` - Two-step deployment workflow
- `just-hotspot-generator` - Hotspot analysis
- `just-card-to-json-workflow` - Card production
- `just-value-red-publish` - Investment research + publishing
- `just-feature-doc-generator` - Reverse documentation from code
- `just-dev-pipeline` - Full feature delivery orchestration

**Skill Structure**:
```
skills/just-<name>/
  ├── SKILL.md (must answer 3 questions)
  └── guide.md (optional)

common-prompt/baseline/
  ├── 01-design-principles.md
  ├── 02-architecture.md
  ├── 03-coding-standards.md
  ├── 04-testing-standards.md
  ├── 05-git-workflow.md
  └── 06-skill-workflow-standards.md
```

**Key Difference**: Waza is flat (8 peers); Just is hierarchical (orchestrator delegates to workers).

---

## 3. Governance Model

### Waza
- **Minimal rules**: "Sets a clear goal and constraints, then steps back"
- **Documented failures**: Every gotcha traces to real failure
- **Anti-patterns**: Cross-skill guardrails (no hallucinated paths, no scope creep)
- **Project context**: `/check` reads README/manifests/CI to become project-aware
- **No formal baseline**: Conventions emerge from usage

### Just-Common-Skills
- **Explicit hierarchy**: `AGENTS.md > baseline > ARCHITECTURE.md > personal preference`
- **Mandatory baseline**: 6 documents defining quality standards (SOLID, testing pyramid, git safety)
- **Skill design gates**: Every SKILL.md must answer 3 questions (what/when/output)
- **Workflow gates**: Multi-stage tasks require checkpoint + recovery strategy
- **Validation requirement**: 3-scenario testing (normal/edge/stress) before production

**Key Difference**: Waza trusts emergence; Just enforces compliance.

---

## 4. Workflow Design

### Waza: Manual Chaining
```
Design:  /think → approve → implement → /check → merge
Debug:   /hunt → fix → /check → release
Research: /read → /learn → /write
```
- User controls every arrow
- No auto-triggers
- Skills don't call other skills

### Just-Common-Skills: Orchestrated Phases
```
just-dev-pipeline (6 steps):
  1. Requirement clarification
  2. Code/doc analysis
  3. Design + task breakdown
  4. Implementation + iteration
  5. Self-review + fixes
  6. Commit/PR + doc closure

just-value-red-publish (4 gates):
  Data collection → Framework analysis → Report generation → 
  XHS article + HTML card → Publish
  (User confirmation required at each gate)
```
- Orchestrator manages phase transitions
- Explicit checkpoint/recovery
- Workers can run standalone or be delegated

**Key Difference**: Waza is user-driven; Just is workflow-driven.

---

## 5. Distribution & Installation

### Waza
**Targets**:
- Claude Code (npx or plugin marketplace)
- Codex (npx)
- Claude Desktop (ZIP upload)
- Pi coding agent (loads from `skills/<name>/SKILL.md`)

**Installation**: Simple copy/link to runtime

### Just-Common-Skills
**Targets**:
- Claude Code (`~/.claude/skills`)
- GitHub Copilot (`.github/skills`, `.github/copilot-instructions.md`)
- VS Code prompts (optional mirror)

**Installation Modes**:
1. **Global install**: `./scripts/install-skills.sh` → `~/.claude/skills`
2. **Project injection**: `./scripts/inject-current-project.sh --force`
   - Creates: `AGENTS.md`, `CLAUDE.md`, `.github/skills`, `.claude/skills`, `.ai/common-prompt`
   - Symlink mode: one update propagates to all projects
3. **Reference-entry mode**: `--reference-entry` flag creates thin governance files pointing to shared hub

**Key Difference**: Waza is portable; Just is centralized with multi-project sync.

---

## 6. Strengths & Weaknesses

### Waza Strengths ✅
1. **Low cognitive load**: 8 skills, easy to remember
2. **Fast onboarding**: Minimal rules, learn by doing
3. **Individual autonomy**: User controls every decision
4. **Portable**: Works across multiple AI platforms
5. **Battle-tested**: 30 days, 300+ sessions, 7 projects
6. **Failure-driven**: Every documented gotcha is real
7. **No over-engineering**: Deliberately incomplete

### Waza Weaknesses ❌
1. **No team coordination**: Skills don't enforce consistency across developers
2. **No production safety**: Limited guardrails for destructive operations
3. **Manual orchestration**: User must remember workflow sequences
4. **No baseline standards**: Code quality depends on individual judgment
5. **Limited specialization**: 8 skills can't cover domain-specific needs (CI/CD, deployment, investment research)
6. **No recovery strategy**: If workflow breaks mid-task, user must manually reconstruct state

### Just-Common-Skills Strengths ✅
1. **Enterprise-ready**: Enforces consistency across teams and projects
2. **Production safety**: `just-careful` guards destructive operations
3. **Automated orchestration**: `just-dev-pipeline` manages end-to-end delivery
4. **Baseline standards**: 6 documents ensure code quality (SOLID, testing, git safety)
5. **Checkpoint recovery**: Workflows can resume after interruption
6. **Domain specialization**: Skills for CI/CD, deployment, investment research, etc.
7. **Multi-project sync**: Symlink mode propagates updates instantly
8. **Copilot compatible**: Works with GitHub Copilot + Claude Code

### Just-Common-Skills Weaknesses ❌
1. **High cognitive load**: 14+ skills, complex hierarchy
2. **Steep learning curve**: Must understand orchestrator/worker pattern, baseline docs
3. **Over-specification risk**: Rigid rules may limit AI model improvements
4. **Heavy governance**: AGENTS.md + 6 baseline docs + skill gates
5. **Centralized dependency**: All projects depend on shared hub repo
6. **Slower iteration**: 3-scenario validation required before production
7. **Less portable**: Tightly coupled to Claude Code + Copilot ecosystem

---

## 7. Use Case Fit

### When to Choose Waza
- **Solo developer** working on personal projects
- **Rapid prototyping** where speed > consistency
- **Learning AI-assisted development** (low barrier to entry)
- **Cross-platform needs** (Claude Code, Codex, Pi, Claude Desktop)
- **Minimal governance** preference (trust emergence over enforcement)

### When to Choose Just-Common-Skills
- **Team/enterprise** with multiple developers and projects
- **Production systems** requiring safety guardrails
- **Regulated industries** needing audit trails and compliance
- **Complex workflows** (CI/CD, deployment, multi-stage delivery)
- **Domain specialization** (investment research, card production, etc.)
- **Multi-project consistency** (shared baseline across repos)

---

## 8. Philosophical Differences

| Dimension | Waza | Just-Common-Skills |
|-----------|------|-------------------|
| **Control** | User-driven | Workflow-driven |
| **Rules** | Minimal (emergent) | Explicit (enforced) |
| **Scope** | Individual habits | Team processes |
| **Completeness** | Deliberately incomplete | Comprehensive coverage |
| **Flexibility** | High (manual chaining) | Medium (orchestrated phases) |
| **Safety** | Trust user judgment | Enforce guardrails |
| **Learning curve** | Gentle | Steep |
| **Maintenance** | Low (8 skills) | High (14+ skills + baseline) |

---

## 9. Hybrid Approach Recommendations

If you want to combine the best of both:

### Option A: Waza Core + Just Extensions
- Use Waza's 8 core skills for individual workflows
- Add Just's specialized skills (CI/CD, deployment, investment) as opt-in
- Keep governance minimal (no baseline enforcement)

### Option B: Just Core + Waza Philosophy
- Keep Just's orchestrator/worker architecture
- Reduce baseline docs from 6 to 2 (design principles + git safety)
- Allow skills to "set goals and step back" instead of rigid rules
- Make 3-scenario validation optional (recommended, not mandatory)

### Option C: Parallel Tracks
- **Personal mode**: Use Waza's 8 skills for exploration/prototyping
- **Team mode**: Use Just's orchestrator for production delivery
- Let developers choose based on context

---

## 10. Conclusion

**Waza** is a **minimalist toolkit** for individual developers who value autonomy and speed. It's the Swiss Army knife: 8 tools, easy to carry, good enough for most tasks.

**Just-Common-Skills** is an **enterprise platform** for teams who need consistency and safety. It's the professional workshop: comprehensive tools, organized workflow, quality assurance.

Neither is "better" — they optimize for different constraints:
- Waza optimizes for **individual velocity**
- Just optimizes for **organizational reliability**

Your choice depends on whether you're building alone or with a team, and whether you prioritize speed or safety.

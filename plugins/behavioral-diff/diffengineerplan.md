# Behavioral Diff Engineer - Project Plan

## Executive Summary

The Behavioral Diff Engineer is a Claude Code plugin designed to catch logic inversions and behavioral changes in code before they reach production. Born from a real production incident where an inverted if-clause caused an outage, this tool acts as a safety net for developers.

## Problem Statement

Subtle logic inversions are among the most dangerous bugs in software:
- They compile without errors
- They pass casual code review ("it's just a small change")
- They may not be caught by incomplete test suites
- They can completely invert business logic

**Example of the inciting incident:**
```csharp
// Before (correct)
if (order.IsValid && order.HasStock)
{
    ProcessOrder(order);
}

// After (BROKEN - accidentally inverted)
if (!order.IsValid || !order.HasStock)
{
    ProcessOrder(order);  // Now processes INVALID orders!
}
```

## Project Phases

### Phase 1: Core Plugin (v1.0.0)
**Status:** Complete

**Delivered:**
- [x] Plugin structure with plugin.json
- [x] `control-flow-analyzer` agent for detecting inversions
- [x] `/behavioral-diff:review` command for manual invocation
- [x] STRICT mode by default (more false positives, fewer misses)
- [x] Support for staged changes (`--staged`, default)
- [x] Support for branch comparison (`--branch`)
- [x] Support for last commit review (`--commit`)
- [x] Support for specific file targeting
- [x] Confidence scoring for findings (50-100% scale)
- [x] Severity classification (Critical, High, Medium, Low)
- [x] Documentation in README.md
- [x] Full project roadmap (this document)

**Deferred to Phase 3:**
- [ ] Pre-commit hook (warn-only, optional) - Requires git hook integration, not Claude Code hooks

**Detection Capabilities (Implemented in control-flow-analyzer):**
- Direct boolean inversions (`if(x)` → `if(!x)`)
- Swapped if/else branches
- Comparison operator changes (`==` → `!=`, `<` → `>`, `<=` → `>=`)
- Boolean expression changes (`&&` → `||`, De Morgan violations)
- Null check inversions (`!= null` → `== null`, `?.` removal)
- Null coalescing changes (`??` removal or modification)
- Loop condition changes (off-by-one, direction reversal)
- Guard clause inversions (early return logic flipped)
- Return value inversions (`return true` → `return false`)
- LINQ query semantic changes (`.Any()` → `.All()`, `.First()` → `.FirstOrDefault()`)
- Ternary operator swaps (operand order, condition inversion)
- Pattern matching inversions (`is` → `is not`)
- Exception handling changes (throw conditions inverted)

**Primary Language:** C#/.NET

**How to Test:**
```bash
# Install the plugin
/plugin install behavioral-diff

# Make some code changes with potential inversions, then:
/behavioral-diff:review

# Or review your current branch against main:
/behavioral-diff:review --branch
```

---

### Phase 2: Enhanced Analysis (v1.1.0)
**Status:** Complete - Ready for Testing

**Deliverables:**
- [x] `business-logic-analyzer` agent for semantic understanding
- [x] Improved confidence scoring with context awareness
- [x] Pattern reference documentation (`references/inversion-patterns.md`)
- [x] `--normal` mode for reduced sensitivity
- [x] Better handling of intentional inversions (refactoring patterns)
- [x] Test coverage detection (warn if changed code has no tests)
- [x] Dual-analyzer orchestration in review command
- [x] Merged findings with deduplication

**New Detection Capabilities (business-logic-analyzer):**
- Business rule inversions (understands domain context)
- State machine transition changes
- Validation logic inversions
- Authorization check inversions
- Data transformation inversions
- Error handling inversions
- Boundary condition changes

**Context-Aware Features (control-flow-analyzer updates):**
- Confidence adjustments based on test coverage
- Intentional refactoring pattern recognition
- Guard clause refactoring detection
- De Morgan's law simplification detection
- Feature flag change detection

**How to Test:**
```bash
# Review with both analyzers (default STRICT mode)
/behavioral-diff:review

# Review with NORMAL mode (higher confidence threshold)
/behavioral-diff:review --normal

# Review branch with reduced sensitivity
/behavioral-diff:review --branch --normal
```

---

### Phase 3: CodeRabbit Integration (v1.2.0)
**Status:** Complete - Ready for Deployment

**Rationale:** Since CodeRabbit already runs on all MRs, we leverage it for automatic MR-level behavioral analysis. This provides zero-cost inversion detection (included in CodeRabbit subscription) with automatic triggering on every merge request.

**Deliverables:**
- [x] `inversion-patterns.md` reference documentation (delivered in Phase 2)
- [x] CodeRabbit configuration guide (`integrations/coderabbit-setup.md`)
- [x] Sample `.coderabbit.yaml` with full inversion detection (`integrations/sample.coderabbit.yaml`)
- [x] Path-specific instructions for C#, F#, VB.NET, XAML, Razor
- [x] Severity-based flagging (CRITICAL/HIGH/MEDIUM)
- [x] Intentional change detection guidance
- [x] Customization options for sensitivity tuning

**Deferred to Future:**
- [ ] Git pre-commit hook integration (moved to Phase 5 as optional local automation)
- [ ] JSON output format for tooling integration
- [ ] Configuration file support for project-specific settings

**How to Deploy:**

1. Copy `integrations/sample.coderabbit.yaml` to your repository root as `.coderabbit.yaml`
2. Adjust path filters for your project structure
3. Commit and push - CodeRabbit will use the new configuration on the next MR

```bash
# Quick setup
cp plugins/behavioral-diff/integrations/sample.coderabbit.yaml /path/to/your/repo/.coderabbit.yaml
```

**Division of Responsibility:**
| Stage | Tool | Cost | Trigger |
|-------|------|------|---------|
| Local development | Claude (`/behavioral-diff:review`) | Developer's Claude tokens | Manual |
| Merge Request | CodeRabbit | Included in subscription | Automatic |

---

### Phase 4: Multi-Language Support (v2.0.0)
**Status:** Future

**Deliverables:**
- [ ] Abstract pattern detection from language-specific parsing
- [ ] Language-specific analyzers:
  - [ ] TypeScript/JavaScript
  - [ ] Ruby
  - [ ] Python
  - [ ] Go
  - [ ] Java/Kotlin
- [ ] Auto-detection of project language
- [ ] Configurable language priorities

**Architecture:**
```
control-flow-analyzer (orchestrator)
├── csharp-analyzer
├── typescript-analyzer
├── ruby-analyzer
├── python-analyzer
└── ... (extensible)
```

---

### Phase 5: Learning & Improvement (v2.1.0)
**Status:** Future

**Deliverables:**
- [ ] Feedback mechanism for false positives/negatives
- [ ] Team-specific pattern learning
- [ ] Integration with bug tracking (correlate inversions with incidents)
- [ ] Historical analysis (which files have most inversions)
- [ ] Developer-specific patterns (optional, privacy-conscious)

---

## Architecture

### Current Plugin Structure (Phase 3 - Delivered)
```
plugins/behavioral-diff/
├── .claude-plugin/
│   └── plugin.json                # Plugin metadata (v1.2.0)
├── agents/
│   ├── control-flow-analyzer.md   # Syntactic pattern detection (350+ lines)
│   └── business-logic-analyzer.md # Semantic understanding (300+ lines)
├── commands/
│   └── review.md                  # /behavioral-diff:review command (350+ lines)
├── references/
│   └── inversion-patterns.md      # Comprehensive pattern documentation (600+ lines)
├── integrations/
│   ├── coderabbit-setup.md        # CodeRabbit configuration guide (300+ lines)
│   └── sample.coderabbit.yaml     # Ready-to-use CodeRabbit config (200+ lines)
└── diffengineerplan.md            # This document (project roadmap)
```

**File Descriptions:**
- **plugin.json**: Plugin manifest with name, version (1.2.0), description, and author
- **control-flow-analyzer.md**: Syntactic pattern detection with context-aware confidence scoring, intentional refactoring detection, test coverage analysis, and normal mode support
- **business-logic-analyzer.md**: Semantic analyzer for business rules, validation, authorization, state machines, and domain-specific patterns
- **review.md**: Command definition with dual-analyzer orchestration, parallel execution, merged findings, and mode-specific filtering
- **inversion-patterns.md**: Comprehensive catalog of all inversion patterns for reference, training, and CodeRabbit configuration
- **coderabbit-setup.md**: Complete guide for configuring CodeRabbit to detect inversions on MRs
- **sample.coderabbit.yaml**: Drop-in configuration file for immediate CodeRabbit integration
- **diffengineerplan.md**: Living document tracking project scope, phases, and progress

### Planned Structure (Phase 4+)
```
plugins/behavioral-diff/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── control-flow-analyzer.md
│   ├── business-logic-analyzer.md
│   ├── typescript-analyzer.md     # TypeScript/JavaScript support
│   └── python-analyzer.md         # Python support
├── commands/
│   └── review.md
├── references/
│   └── inversion-patterns.md
├── integrations/
│   ├── coderabbit-setup.md
│   └── sample.coderabbit.yaml
└── diffengineerplan.md
```

## Usage Patterns

### Developer Workflow (Manual)
```bash
# Before committing
git add .
/behavioral-diff:review

# Review findings, fix critical issues
# Commit with confidence
```

### Pre-Commit Hook (Automated Warning)
```bash
# Configured via hooks.json
# Runs automatically on every commit attempt
# Shows warnings but doesn't block (configurable)
```

### MR Review (CodeRabbit)
```yaml
# In .coderabbit.yaml
# CodeRabbit automatically reviews every MR/PR
# Configured with behavioral inversion detection patterns
# No additional Claude tokens consumed
```

## Configuration Options

### Sensitivity Modes
| Mode | Description | Use Case |
|------|-------------|----------|
| `--strict` (default) | Maximum sensitivity, more false positives | Recommended for safety |
| `--normal` | Balanced sensitivity | For experienced teams |

### Scope Options
| Option | Git Command | Use Case |
|--------|-------------|----------|
| `--staged` (default) | `git diff --cached` | Before commit |
| `--branch` | `git diff main...HEAD` | Before PR |
| `--commit` | `git diff HEAD~1..HEAD` | Review last commit |

### Future Configuration (Phase 3)
```json
{
  "behavioral-diff": {
    "sensitivity": "strict",
    "blockOnCritical": false,
    "warnOnHigh": true,
    "excludePaths": ["tests/", "*.test.cs"],
    "customPatterns": []
  }
}
```

## Success Metrics

### Short-term (Phase 1-2)
- Developer adoption within mobile team
- Reduction in logic inversion bugs reaching code review
- False positive rate acceptable (<30%)

### Medium-term (Phase 3)
- CodeRabbit integration across all mobile projects
- Zero logic inversions reaching production
- Reduced time spent in code review on logic verification
- Minimal Claude token usage (local only, CodeRabbit handles MRs)

### Long-term (Phase 4-5)
- Company-wide adoption across all products
- Migration to aidevops/claude-plugins repo
- Contribution to reduced incident rate

## Risk Assessment

### Technical Risks
| Risk | Mitigation |
|------|------------|
| High false positive rate | Start strict, allow tuning down |
| Performance on large diffs | Limit file count, add timeout |
| Language-specific edge cases | Iterative improvement based on feedback |

### Adoption Risks
| Risk | Mitigation |
|------|------------|
| Developer friction | Start as optional, prove value |
| Ignored warnings | Surface findings in code review |
| Tool fatigue | Keep output focused, hide low-priority |

## Future Considerations

### Integration Opportunities
- **CodeRabbit**: MR-level behavioral analysis (Phase 3)
- **Sentry**: Correlate production incidents with past inversions
- **IDE plugins**: Real-time detection while coding
- **Test generation**: Auto-suggest tests for inverted code

### Migration Path
Once proven in mobile team (this repo), the plugin can be:
1. Abstracted to be language-agnostic
2. Migrated to `trigent1/aidevops/claude-plugins`
3. Made available company-wide
4. Eventually open-sourced if valuable to community

## Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.2.0 | 2026-01-30 | Phase 3 complete: CodeRabbit integration for automatic MR-level inversion detection. Added coderabbit-setup.md guide and sample.coderabbit.yaml configuration. Path-specific instructions for C#, F#, VB.NET, XAML, Razor. Severity-based flagging and intentional change detection. |
| 1.1.0 | 2026-01-30 | Phase 2 complete: Added business-logic-analyzer agent for semantic understanding, context-aware confidence scoring with adjustments for test coverage/intentional refactoring, pattern reference documentation, --normal mode for reduced sensitivity, intentional inversion detection (guard clauses, De Morgan, feature flags), test coverage warnings, dual-analyzer orchestration with parallel execution and merged findings |
| 1.0.0 | 2026-01-30 | Phase 1 complete: Core plugin with control-flow-analyzer agent, review command, STRICT mode default, multi-scope diff support (staged/branch/commit), confidence scoring, severity classification |

## Contributors

- **Matthew Bailey** - Original concept, implementation
- **Mobile Team** - Early adopters, feedback

## Testing Checklist for Reviewers

Before approving this MR, please test the following scenarios:

### Phase 1 Features
- [ ] Install plugin successfully: `/plugin install behavioral-diff`
- [ ] Command appears in autocomplete: `/behavioral-diff:review`
- [ ] Review staged changes: Stage a file with an inverted conditional, run `/behavioral-diff:review`
- [ ] Review branch: Create a branch with changes, run `/behavioral-diff:review --branch`
- [ ] Review specific file: `/behavioral-diff:review path/to/file.cs`
- [ ] Verify findings include severity, confidence, before/after code
- [ ] Verify no false negatives on obvious inversions (e.g., `if(x)` → `if(!x)`)

### Phase 2 Features
- [ ] **Dual analyzers**: Verify both control-flow-analyzer and business-logic-analyzer are invoked
- [ ] **Business logic detection**: Test with validation/authorization code changes
- [ ] **Normal mode**: Run `/behavioral-diff:review --normal` and verify reduced findings
- [ ] **Context-aware confidence**: Verify confidence adjusts based on test coverage
- [ ] **Intentional detection**: Test guard clause refactoring - should have lower confidence
- [ ] **Test coverage warnings**: Verify warnings when tests don't accompany changes
- [ ] **Pattern reference**: Review `references/inversion-patterns.md` for completeness
- [ ] **Merged findings**: When both analyzers flag same issue, verify deduplication

### Phase 3 Features (CodeRabbit Integration)
- [ ] **Configuration file**: Copy `integrations/sample.coderabbit.yaml` to a test repository
- [ ] **MR trigger**: Create an MR with an inversion and verify CodeRabbit detects it
- [ ] **Severity levels**: Verify CRITICAL/HIGH/MEDIUM flagging works correctly
- [ ] **C# detection**: Test with `.cs` file inversions
- [ ] **Multi-language**: Test with `.fs`, `.vb`, `.xaml`, `.razor` if applicable
- [ ] **False positive rate**: Assess if CodeRabbit is too noisy or too quiet
- [ ] **Intentional handling**: Verify guard clause refactoring is noted as potentially intentional
- [ ] **Path filters**: Verify test files are excluded from detection

## Feedback Requested

After testing, please provide feedback on:
1. **Detection accuracy**: Did it catch real inversions? Any obvious misses?
2. **False positive rate**: How noisy is STRICT mode? Is NORMAL mode better balanced?
3. **Output clarity**: Are findings easy to understand and act on?
4. **Performance**: Any issues with large diffs? Does parallel execution help?
5. **Business logic analyzer**: Does it add value beyond control-flow detection?
6. **Confidence scoring**: Are context adjustments reasonable?
7. **Intentional detection**: Does it correctly identify refactoring patterns?
8. **Missing patterns**: Any inversion types you'd like to see detected?

---

*This is a living document. Update as the project evolves.*

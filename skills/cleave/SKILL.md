---
name: cleave
description: Recursive task decomposition system. Splits complex directives into subtasks, executes in isolation, reunifies results. Use for multi-system implementations requiring careful breakdown.
---

# Cleave Skill

Recursive decomposition system for complex directives. Splits tasks along domain boundaries, executes children in isolation, reunifies results with conflict detection.

## Prerequisites

**Sequential Thinking MCP server is REQUIRED.**

Verify availability: `mcp__MCP_DOCKER__sequentialthinking`

If not installed:
```
mcp__MCP_DOCKER__mcp-find query="sequential thinking"
mcp__MCP_DOCKER__mcp-add name="sequentialthinking" activate=true
```

## Complexity Formula

```
complexity = (1 + system_count) × (1 + 0.5 × modifier_count)
```

**System Counting:**
- UI/Frontend: +1 per framework
- API/Backend: +1 per service
- Database: +1
- Message Queue: +1
- Third-party API: +2 per provider
- Cloud service: +1 per service

**Overhead Modifiers** (binary, 0-8):
- State Coordination
- Error Handling
- Concurrency
- Security-Critical
- Breaking Changes
- Data Migration
- Third-Party API
- Performance-Critical

**Examples:**
| Task | Systems | Modifiers | Complexity |
|------|---------|-----------|------------|
| Fix typo | 1 | 0 | 2 (execute) |
| Full-stack CRUD | 3 | 1 | 6 (cleave) |
| JWT auth | 2 | 3 | 7.5 (cleave) |
| Stripe integration | 4 | 4 | 15 (deep cleave) |

**Threshold:** Default 2. Execute if complexity <= threshold, cleave otherwise.

## Operating Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Lean** (default) | No keyword | Token-optimized, reference-based, terse reunification |
| **Simple** | `cleave-simple` or auto-detected | Skips workspace, in-memory execution |
| **Robust** | `cleave-robust` | Full audit trail, verbose reunification |
| **iamverysmart** | Keyword in directive | Skip interrogation (requires acknowledgment) |

## Splitting Strategy

**Cardinality:** 2 or 3 children (binary or ternary)

**Domain-Based Seams:**
- **Layer:** UI / API / Data
- **Feature:** Auth / Payments / Notifications
- **Lifecycle:** Setup / Execute / Cleanup
- **Risk:** Safe changes / Risky changes

**Child Requirements:**
1. Independent (executable without siblings)
2. Complete (all context needed)
3. Reunifiable (output merges coherently)
4. Scoped (clear boundaries)

## Context Preservation

**Three Dimensions:**

1. **Vertical (Ancestry):** Parent chain from current node to root
2. **Horizontal (Siblings):** Coordination between peer tasks
3. **Immutable (Root Intent):** Original goal, never modified

**Token Budget:**
- Depth 0: ~800 tokens
- Depth 1: ~600 tokens
- Depth 2+: ~450-500 tokens (stable)

## Workspace Structure

```
.cleave/
├── manifest.yaml      # Config + intent + analysis
├── 0-task.md          # Child 0: directive + outcome
├── 1-task.md          # Child 1: directive + outcome
├── 2-task.md          # Child 2: optional third branch
├── siblings.yaml      # Lateral coordination
├── merge.md           # Created ONLY if conflicts detected
└── metrics.yaml       # Telemetry
```

## Reunification Contract

Every child result MUST include:

1. **Parent Context Echo** - Goal + role
2. **Interfaces Published** - `function(params) -> return_type`
3. **Decisions Made** - Choices affecting siblings
4. **Assumptions** - What child assumed true
5. **Interfaces Consumed** - Expected from siblings
6. **Shared File Modifications** - Files others might touch
7. **Deferred Decisions** - Parent must resolve
8. **Alignment Check** - Validates against root goal

## Conflict Detection

**Types:**
1. **Artifact Overlap** - Multiple children modified same file
2. **Decision Contradiction** - Incompatible choices
3. **Interface Mismatch** - Published != consumed
4. **Assumption Violation** - Contradicts parent or sibling

**Resolution:**
- File overlap -> 3-way merge
- Decision contradiction -> Parent directive wins
- Interface mismatch -> Adapter pattern
- Invalid assumption -> Retry affected child

## Failure Handling

- `halt_on_failure: true` -> Stop all on first error
- `halt_on_failure: false` -> Best-effort smoothing:
  1. Partial Incorporation
  2. Deferred Scope
  3. Graceful Degradation
  4. Escalate to user

## Phase Summary

| Phase | Action |
|-------|--------|
| 0 | Interrogation (root only, adaptive 1-6 questions) |
| 1 | Complexity assessment (fast-path or sequential thinking) |
| 2 | Execute or cleave decision |
| 3 | Splitting strategy (domain boundaries) |
| 4 | Child execution (parallel by default) |
| 5 | Reunification (conflict detection + merge) |

## Common Pitfalls

1. **Cleaving trivial tasks** - Execute directly when complexity <= threshold
2. **Splitting into 4+ children** - Use nested cleaves instead
3. **Duplicating context** - Use YAML frontmatter references (lean mode)
4. **Missing context echo** - Every result MUST echo parent goal
5. **Ignoring alignment** - Verify constraints before decisions

## Integration

- **Sequential Thinking MCP** - Required for assessment and reunification
- **Task tool** - For parallel child execution

## Success Criteria

- Complexity assessed correctly
- Split decision justified
- Children independent, complete, reunifiable
- Context preserved at all depths
- Conflicts detected and resolved
- Alignment verified
- Token budget met (<500 tokens overhead per depth)

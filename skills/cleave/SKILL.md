---
name: cleave
description: Recursive task decomposition system. Splits complex directives into subtasks, executes in isolation, reunifies results. Use for multi-system implementations requiring careful breakdown.
---

# Cleave Skill

Recursive decomposition system for complex directives. Splits tasks along domain boundaries, executes children in isolation, reunifies results with conflict detection.

**CLI Tool**: `cleave` handles assessment, workspace generation, conflict detection, and reunification.

## Installation

Requires `styrene-cleave >= 0.9.5`:

```bash
pipx install styrene-cleave   # or: pip install styrene-cleave
cleave --version              # verify (must be >= 0.9.5)
```

## Decision Pipeline

Before cleaving, assess complexity to choose the right execution mode:

```bash
cleave assess -d "<directive>" -f json
```

| Complexity | Action |
|-----------|--------|
| <= threshold (default 2) | Execute directly — no cleave needed |
| > threshold, moderate (2-4 children, single depth) | **Interactive** — in-session Task subagents |
| High, deep decomposition, or long-running | **Autonomous** — `cleave run` with isolated subprocesses |

The `probe` command provides codebase-aware context before decomposition:

```bash
cleave probe -d "<directive>" -r /path/to/repo
```

This scans the codebase (stack detection, file relevance, pattern matching) and generates Socratic questions to refine your understanding before splitting.

## Execution Models

### Interactive (In-Session)

Use when the invoking agent is in an interactive Claude Code session and the directive is moderate complexity (2-4 children, single depth). Children share the session's MCP servers, skills, and tool access.

**Workflow:**

1. **Assess**: `cleave assess -d "<directive>" -f json` or estimate complexity
2. **Split**: Identify 2-4 children along domain seams (layer, feature, lifecycle, risk)
3. **Dispatch**: Launch children in parallel via Task tool (see template below)
4. **Collect**: Gather results from all children
5. **Reunify**: Detect conflicts, merge decisions, validate alignment with root goal

#### Child Dispatch Template

For each child, launch a Task tool subagent with `subagent_type: "general-purpose"`. Structure the prompt as follows:

```
You are a cleave child agent executing one part of a decomposed task.

## Root Goal

<the original user directive, verbatim — never modified across depth>

## Your Task

**Label**: <child-label>
**Directive**: <what this child must accomplish>
**Scope**: <files and directories this child owns>
**Success Criteria**:
- <how to verify this child's work>

## Sibling Context

The following siblings are executing in parallel. Respect scope boundaries
and coordinate on shared interfaces.

| Label | Directive | Scope |
|-------|-----------|-------|
| <sibling-label> | <sibling-directive> | <sibling-scope> |

## Reunification Contract

When complete, you MUST report ALL of the following:

1. **Status**: SUCCESS | PARTIAL | FAILED
2. **Summary**: What was accomplished (2-3 sentences)
3. **Files Modified**: List every file created or changed
4. **Interfaces Published**: Function signatures, API endpoints, types exposed
5. **Decisions Made**: Choices that affect siblings (e.g., "used JWT not sessions")
6. **Assumptions**: What you assumed true about siblings or the codebase
7. **Verification**: Proof the work functions (test command + output)
8. **Alignment Check**: How your result satisfies the root goal

Do not modify files outside your scope. Commit your work with clear messages.
```

**Example dispatch** for a directive "Add user authentication with login page":

- Child 0: `label: "auth-backend"`, scope: `src/api/auth/**, src/models/user.py`, directive: "Implement JWT authentication — registration, login, token refresh endpoints"
- Child 1: `label: "auth-frontend"`, scope: `src/ui/pages/login/**, src/ui/components/auth/**`, directive: "Build login and registration pages consuming the auth API"

#### Reunification (Interactive)

After collecting all child results:

1. **Detect conflicts**: File overlap, decision contradictions, interface mismatches
2. **Resolve**: File overlap -> 3-way merge. Decision contradiction -> root directive wins. Interface mismatch -> adapter.
3. **Validate**: Merged result satisfies root goal and all success criteria
4. **Report**: Summarize to user — what was accomplished, unresolved issues, verification results

If the workspace was initialized on disk, automate conflict detection:

```bash
cleave reunify -w .cleave-<name>
```

### Autonomous (`cleave run`)

Use when the directive requires deep decomposition, long-running children, or overnight execution. Children are isolated `claude --print` subprocesses, each in a git worktree.

```bash
cleave run -d "<directive>" -r /path/to/repo \
  -s "<success criterion 1>" \
  -s "<success criterion 2>" \
  --model opus --max-budget 50 --child-budget 15 \
  --timeout 8h --child-timeout 2h --max-depth 3
```

**Review plan before execution (--confirm):**

```bash
cleave run -d "..." -r /path/to/repo --confirm
# Review plan-review.md, then:
cleave run --resume .cleave-<name>/
```

**Resume interrupted run:**

```bash
cleave run --resume .cleave-<name>/
```

**Dry run (plan only — still incurs planning API cost):**

```bash
cleave run -d "..." -r /path/to/repo --dry-run
```

The orchestrator manages the full lifecycle: preflight -> plan -> (planned) -> assess -> init -> dispatch -> monitor -> harvest -> reunify -> merge -> report. State persists to `orchestrator.json` for crash recovery.

### Root Directive Preservation

The original top-level directive is preserved across all recursion levels via `root_directive`. When a child is spawned at depth > 0, its prompt includes a **Root Goal** section with the verbatim original directive so alignment checks remain meaningful even after recursive decomposition.

### Dependency Ordering

The planner can declare `depends_on: ["label"]` for children that must wait for another child to finish before starting. The dispatcher groups children into sequential waves using topological ordering:

- Children with no dependencies run in wave 1
- Children whose dependencies completed run in wave 2, etc.
- Independent children within a wave run in parallel
- Cycle detection (Kahn's algorithm) gracefully clears deps on cyclic nodes

## Subprocess Isolation (Autonomous Mode)

**Critical: Children are capability-stripped.** The orchestrator spawns children with:

| Capability | Status | Detail |
|-----------|--------|--------|
| Built-in tools | `Bash Edit Read Write Glob Grep` | Explicit allowlist via `--allowedTools` |
| MCP servers | **None** | `--strict-mcp-config` prevents ambient inheritance |
| Skills/commands | **None** | `--disable-slash-commands` prevents recursive invocation |
| Plugins/hooks | **None** | `--print` mode does not load plugins or hooks |
| Session persistence | **Disabled** | `--no-session-persistence` prevents worktree pollution |
| WebFetch/WebSearch | **Unavailable** | Not in the allowed tools list |
| Task tool | **Unavailable** | Children cannot spawn subagents |
| Network via Bash | Unrestricted | `curl`, `wget` available through Bash |

**Implication**: The planner must ensure each child's task is achievable with only filesystem tools and Bash. Context requiring web research or MCP queries must be gathered by the parent and embedded in the child's prompt before dispatch.

### MCP Inheritance Prevention

Without isolation, children inherit MCP servers from `.mcp.json` and `settings.local.json` in the directory ancestry — non-deterministic depending on worktree location. The orchestrator prevents this with `--strict-mcp-config`. If a child needs a specific MCP server, configure it explicitly via `mcp_config`.

### Environment Isolation

Child subprocesses receive only allowlisted environment variables (PATH, HOME, LANG, ANTHROPIC_*, GIT_*, SSH_AUTH_SOCK, NODE_*, etc.). Credentials (AWS_*, GITHUB_TOKEN, etc.) are stripped to prevent leakage through `bypassPermissions` + Bash access.

## Complexity Formula

```
complexity = (1 + system_count) x (1 + 0.5 x modifier_count)
```

**Systems**: UI (+1/framework), API (+1/service), DB (+1), message queue (+1), third-party API (+2/provider), cloud service (+1/service).

**Modifiers** (binary, 0-8): State Coordination, Error Handling, Concurrency, Security-Critical, Breaking Changes, Data Migration, Third-Party API, Performance-Critical.

| Task | Systems | Modifiers | Complexity | Decision |
|------|---------|-----------|------------|----------|
| Fix typo | 1 | 0 | 2 | execute |
| Full-stack CRUD | 3 | 1 | 6 | cleave |
| JWT auth | 2 | 3 | 7.5 | cleave |
| Stripe integration | 4 | 4 | 15 | deep cleave |

**Threshold**: Default 2. No artificial caps — complexity reflects actual scope. Over-estimation is safer than under-estimation.

## Operating Modes

| Mode | Trigger | Behavior |
|------|---------|----------|
| **Lean** (default) | No keyword | Token-optimized, reference-based, terse reunification |
| **Robust** | `cleave-robust` | Full audit trail, verbose reunification, adversarial review |
| **iamverysmart** | Keyword in directive | Skip interrogation (requires acknowledgment) |

**TDD Workflow**: Task files include Red -> Green -> Refactor instructions by default. Disable with `--no-tdd` when TDD isn't appropriate.

## Splitting Strategy

**Cardinality**: 2-4 children per level. Prefer fewer, deeper splits over wide shallow ones.

**Domain Seams:**
- **Layer**: UI / API / Data
- **Feature**: Auth / Payments / Notifications
- **Lifecycle**: Setup / Execute / Cleanup
- **Risk**: Safe changes / Risky changes

**Child Requirements:**
1. Independent — executable without siblings (unless depends_on ordering is used)
2. Complete — all needed context included (no MCP/web/skill access in autonomous mode)
3. Reunifiable — output merges coherently
4. Scoped — clear file boundaries, minimal overlap

## Workspace Structure

```
.cleave-<name>/
├── manifest.yaml      # Config + intent + analysis
├── 0-task.md          # Child 0: directive + outcome
├── 1-task.md          # Child 1: directive + outcome
├── 2-task.md          # Child 2: optional third branch
├── siblings.yaml      # Lateral coordination (scope, interfaces, shared files)
├── merge.md           # Created ONLY if conflicts detected
├── review.md          # Adversarial review (default, --no-review to skip)
├── plan-review.md     # Created by --confirm for human plan review
└── metrics.yaml       # Telemetry
```

**Worktrees (autonomous mode):**
```
.cleave-worktrees/
├── <child-label-0>/   # git worktree on branch cleave/<child-label-0>
├── <child-label-1>/   # git worktree on branch cleave/<child-label-1>
└── <child-label-2>/   # git worktree on branch cleave/<child-label-2>
```

## Context Preservation

1. **Vertical (Ancestry)**: Parent chain from current node to root
2. **Horizontal (Siblings)**: Coordination via siblings.yaml
3. **Immutable (Root Intent)**: Original goal preserved via root_directive, never modified across depth

**Token Budget**: Depth 0: ~800 tokens. Depth 1: ~600. Depth 2+: ~450-500 (stable).

## Reunification Contract

**Child obligations** (task file result section or subagent response):
1. **Status**: SUCCESS | PARTIAL | FAILED | NEEDS_DECOMPOSITION
2. **Summary**: What was accomplished
3. **Files Modified**: Paths created or changed
4. **Interfaces Published**: `function(params) -> return_type`
5. **Decisions Made**: Choices affecting siblings
6. **Assumptions**: What was assumed true
7. **Verification**: Proof of function (test output, command results)
8. **Alignment Check**: Validates against root goal

**Parent obligations:**
1. Collect all child results
2. Detect conflicts (file overlap, decision contradiction, interface mismatch)
3. Resolve or escalate
4. Validate merged result against root intent

## Conflict Detection

1. **Artifact Overlap** — same file modified -> 3-way merge
2. **Decision Contradiction** — incompatible choices -> parent directive wins
3. **Interface Mismatch** — published != consumed -> adapter pattern
4. **Assumption Violation** — contradicts parent or sibling -> retry affected child

## Failure Handling

- `halt_on_failure: true` -> Stop all on first error
- `halt_on_failure: false` -> Best-effort: partial incorporation, deferred scope, graceful degradation, escalate
- Merge failures are surfaced in the result (success=False) with per-branch conflict details

## Permission Inference

For autonomous fire-and-forget execution, infer required permissions upfront:

```bash
cleave check-permissions -d "<directive>" --snippet
```

This maps the directive to permission bundles (python, node, docker, database, etc.) and reports gaps against `~/.claude/settings.local.json`. Use `--infer-permissions` with `init` to embed inferred permissions in the manifest.

## CLI Reference

```bash
cleave assess -d "directive" [-f json|yaml]      # Complexity assessment
cleave match -d "directive"                       # Pattern matching (9 core patterns)
cleave probe -d "directive" [-r /repo]            # Socratic codebase interrogation
cleave init -d "directive" -c '["A","B"]'         # Initialize workspace
cleave context -m .cleave/manifest.yaml           # Reconstruct full context
cleave reunify -w .cleave                         # Merge + conflict detection + review
cleave check-permissions -d "directive"            # Permission gap detection
cleave metrics -w .cleave                          # Assessment calibration data
cleave analytics [-f json|yaml|markdown|prometheus]  # Performance dashboard
cleave run -d "directive" -r /repo [opts]          # Autonomous orchestration
cleave run -d "directive" -r /repo --confirm       # Plan then pause for review
cleave run --resume .cleave-<name>/                # Resume from --confirm or interrupt
cleave config show                                 # Settings management
cleave install-skill                                # Install skill to ~/.claude/skills/
```

### `cleave run` flags

| Flag | Default | Description |
|------|---------|-------------|
| `-d, --directive` | (required) | Top-level task directive |
| `-r, --repo` | cwd | Path to target repository |
| `-s, --success-criteria` | [] | Success criterion (repeatable) |
| `--model` | opus | Model for child executors |
| `--planner-model` | sonnet | Model for planning phase |
| `--max-budget` | 50 | Total budget in USD |
| `--child-budget` | 15 | Per-child budget in USD |
| `--timeout` | 8h | Total timeout (e.g., 8h, 30m, 3600) |
| `--child-timeout` | 2h | Per-child timeout |
| `--max-depth` | 3 | Max recursion depth (1-10) |
| `--circuit-breaker` | 3 | Consecutive failures before halt |
| `--max-parallel` | 4 | Max parallel children |
| `--mcp-config` | "" | MCP config for children (empty = no MCP) |
| `--dry-run` | false | Plan only, don't dispatch |
| `--confirm` | false | Stop after planning for review |
| `--resume` | — | Resume from workspace path |
| `--verbose` | false | Debug logging |

## Common Pitfalls

1. **Cleaving trivial tasks** — Execute directly when complexity <= threshold
2. **Assuming children have MCP/web access** — In autonomous mode, only filesystem tools + Bash
3. **Missing sibling coordination** — Always include siblings context for children
4. **Missing reunification contract** — Every result MUST include status, files, interfaces, decisions
5. **Skipping alignment check** — Verify each child's result against root goal
6. **Not embedding context** — In autonomous mode, pre-fetch web/MCP data and embed in prompt
7. **Splitting for splitting's sake** — Each child should represent meaningful work

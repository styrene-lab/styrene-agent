---
name: distill
description: Context distillation for session handoff. Creates portable summaries of current session for fresh context bootstrap. Invoke with /distill.
---

# Distill Skill

Context distillation for session handoff. Use `/distill` to create a portable summary of the current session that can be used to bootstrap a fresh context.

## Invocation

```
/distill
```

## Behavior

When invoked, this skill:

1. **Analyzes the full conversation context** to extract:
   - Primary objectives and outcomes
   - Key technical decisions and implementations
   - File changes and their purposes
   - Pending work and next steps
   - Important context that would be lost

2. **Generates a distillation summary** organized as:
   - **Session Overview**: What was accomplished
   - **Technical State**: Current codebase state, versions, key changes
   - **Decisions Made**: Architectural choices, trade-offs, rationale
   - **Pending Items**: Incomplete work, known issues, planned next steps
   - **Critical Context**: Information essential for continuation

3. **Writes the distillation** to a timestamped file:
   ```
   .claude/distillations/YYYY-MM-DD-HHMMSS-<slug>.md
   ```

4. **Outputs a handoff directive** the user can copy into a fresh session:
   ```
   Continue from distillation: .claude/distillations/<filename>.md
   ```

## Output Format

The distillation file uses this structure:

```markdown
# Session Distillation: <brief-title>

Generated: <timestamp>
Working Directory: <path>
Repository: <repo-name>

## Session Overview

<2-3 sentence summary of what was accomplished>

## Technical State

### Repository Status
- Branch: <branch>
- Recent commits: <list>
- Uncommitted changes: <summary>

### Key Changes This Session
<bulleted list of significant modifications>

### Versions/Dependencies
<relevant version information>

## Decisions Made

<numbered list of architectural/design decisions with brief rationale>

## Pending Items

### Incomplete Work
<tasks started but not finished>

### Known Issues
<bugs, limitations, or problems identified>

### Planned Next Steps
<what should happen next>

## Critical Context

<information that would be difficult to reconstruct, such as:>
- User preferences expressed
- Constraints or requirements mentioned
- External system states
- Non-obvious relationships between components

## File Reference

Key files for continuation:
- <path>: <purpose>
- <path>: <purpose>
```

## Usage Notes

- Run `/distill` before ending a long session
- Run `/distill` when context is getting full
- Run `/distill` before switching to a different task
- The distillation is meant to be read by Claude in a fresh session
- Keep the handoff directive simple - the distillation file contains the detail

---
description: Recursive task decomposition via cleave CLI
---
# /cleave - Recursive Task Decomposition

Route complex directives to the `cleave` CLI orchestration engine.

## Usage

```
/cleave "directive text"
```

**Examples:**
```
/cleave "Add JWT authentication to the API"
/cleave "Migrate the database schema to support multi-tenancy"
```

## Quick Reference

### Prerequisite

```bash
which cleave || echo "Install with: pipx install styrene-cleave"
```

### State Machine

```
PREFLIGHT → ASSESS → ROUTE → PLAN → REVIEW → EXECUTE → REPORT
```

Follow each state sequentially. Wait for user input at every gate.

### Routing Tiers

| Assessment | Complexity | Tier |
|------------|-----------|------|
| `"execute"` | any | **Direct** — execute in-session |
| `"cleave"` | < 12 | **Orchestrator** — `cleave run` |
| `"cleave"` | ≥ 12 | **Architect** — `cleave architect` |

### Key Commands

| Command | Purpose |
|---------|---------|
| `cleave assess -d "<directive>" -f json` | Complexity assessment |
| `cleave run -d "<directive>" -r <repo> --confirm -f json` | Plan + pause |
| `cleave run --resume <workspace> -f json` | Resume orchestrator |
| `cleave architect -d "<directive>" -r <repo> --plan-only -f json` | Architect plan |
| `cleave architect --resume <db_path> -f json` | Resume architect |

## See Also

Use `/skill:cleave` for the full skill with complete state machine documentation.

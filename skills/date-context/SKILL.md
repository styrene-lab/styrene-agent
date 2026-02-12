---
name: date-context
description: Authoritative date context from system clock. Use before any date calculations, weekly reporting, or relative date references to eliminate AI calculation errors.
---

# Date Context Skill

Eliminates AI date calculation errors by providing authoritative date context from the system.

## Problem

LLMs frequently make errors when calculating:
- Day of week from a date
- Week boundaries (Monday-Friday)
- Relative dates ("last Tuesday", "this Friday")
- Year boundaries (especially Dec/Jan)

## Solution

Use the `date-context.sh` script to get authoritative date information. Never calculate dates manually.

## Usage

```bash
# Get full date context
skills/date-context/date-context.sh
```

### Output Format

```
DATE_CONTEXT:
  TODAY: 2025-01-25 (Saturday)
  CURR_WEEK_START: 2025-01-20 (Monday)
  CURR_WEEK_END: 2025-01-24 (Friday)
  CURR_WEEK_RANGE: Jan 20 - Jan 24, 2025
  PREV_WEEK_START: 2025-01-13 (Monday)
  PREV_WEEK_END: 2025-01-17 (Friday)
  PREV_WEEK_RANGE: Jan 13 - Jan 17, 2025
```

## When to Use

Invoke this skill before any operation involving:
- Weekly reporting or logging
- Scheduling references ("this week", "last week")
- Date-stamped entries
- Any relative date calculations

## Platform Support

Cross-platform: macOS (BSD date) and Linux (GNU date).

## Key Principle

**External source of truth > internal calculation.**

The system clock is authoritative. Use it.

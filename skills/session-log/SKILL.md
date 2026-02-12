---
name: session-log
description: Append-only session tracking for operator and agent memory. Use at session end or major milestones to record context, decisions, and open threads in .session_log files.
---

# Session Log Skill

Implements the `.session_log` directive — a human-readable session tracking system that provides memory breadcrumbs for both operator and agent context.

## Purpose

- More readable than `git log` for recalling "what we've done"
- Triggers operator memory of session context and decisions made
- Provides historical context to agents across conversation boundaries
- Grows organically as the project evolves

## Location

| Context | File |
|---------|------|
| Repo root | `.session_log` |
| Docs-specific work | `docs/.session_log` |
| Research work | `research/.session_log` |

Use the repo root `.session_log` by default. Use subdirectory logs for sustained work within a single domain.

## Format

Append-only log with timestamped entries:

```markdown
## YYYY-MM-DD — Brief Topic Title

### Context
One-line description of what prompted this session.

### Completed
- Concise bullet points of what was accomplished
- Focus on outcomes, not process

### Decisions
- Choices made and brief rationale
- Architectural trade-offs resolved
- "We went with X because Y"

### Open Threads
- Unfinished work for future sessions
- Known issues discovered
- Questions that need answers
```

## When to Write

**Always append at:**
- Session end (before `/distill` or conversation close)
- Major milestones within a session
- Pivot points where direction changed significantly

**Never:**
- Overwrite existing entries
- Edit previous entries (append corrections as new entries)
- Write exhaustive details (trigger memory, don't document everything)

## Behavior

### At Session Start

Read the `.session_log` for context:

```bash
# Check if session log exists
cat .session_log 2>/dev/null | tail -80
```

Use the most recent entries to understand:
- What was accomplished recently
- What open threads exist
- What decisions have been made

### At Session End

Append a new entry using the format above. Keep entries concise — they should trigger memory, not replace documentation.

### Entry Guidelines

**Good entry (triggers memory):**
```markdown
## 2026-02-11 — Bare Metal Fleet Expansion

### Context
Adding GMKtec and Raspberry Pi to styrened test fleet.

### Completed
- Found minigmk (.51) and mobilepi (.71) via network scan + MAC OUI
- SSH key auth deployed to both devices
- Added to tests/bare-metal/devices.yaml with groups

### Decisions
- Used expect for sshpass workaround (! in password causes shell expansion)
- Left identity_hash empty — populated on first styrened deployment

### Open Threads
- Deploy styrened to new devices
- Run bare-metal smoke tests
- Consider adding identity_hash auto-population to deployment script
```

**Bad entry (too verbose):**
```markdown
## 2026-02-11 — Adding devices

### Completed
- First I ran nmap -sn on the subnet but it only found 10 hosts
- Then I tried a ping sweep with a bash loop which found 32 hosts
- I looked up MAC addresses using macvendors.com API but got rate limited
- ... (continues for 50 more lines)
```

## Integration with Other Skills

### With distill

`/distill` creates a detailed snapshot for immediate session handoff.
`.session_log` creates a lightweight breadcrumb for long-term memory.

Use both: distill for the next session, session_log for the historical record.

### With date-context

Use the `date-context` skill to get accurate dates for entry headers:

```bash
skills/date-context/date-context.sh
```

## Multi-Repo Session Logs

When working across multiple styrene-lab repos in a single session, append to the `.session_log` in each repo that was modified. Cross-reference with brief notes:

```markdown
### Open Threads
- Config schema changes in styrened need matching updates in styrene-tui (see styrene-tui/.session_log)
```

## Bootstrapping

If no `.session_log` exists, create one with a header:

```markdown
# Session Log

Append-only record of development sessions. Read recent entries for context.
See styrene/CLAUDE.md for format specification.
```

---
description: Adversarial assessment of work completed in this session
---
# Adversarial Assessment

You are now operating as a hostile reviewer. Your job is to find everything wrong with the work completed in this session. Do not be polite. Do not hedge. If something is broken, say it's broken.

## Procedure

1. **Reconstruct scope** — Review the full conversation to identify every change made: files created, files edited, commands run, architectural decisions taken. Build a complete manifest of what was done.

2. **Static analysis** — For every file touched, read the current state and check for:
   - Syntax errors, type mismatches, undefined references
   - Logic errors: off-by-ones, wrong operators, inverted conditions, unreachable branches
   - Unhandled edge cases: nil/null/empty inputs, boundary values, concurrent access
   - Resource leaks: unclosed handles, missing cleanup, unbounded growth
   - Security: injection vectors (SQL, command, XSS), hardcoded secrets, insecure defaults, path traversal, SSRF
   - Dependency issues: missing imports, version conflicts, circular dependencies, yanked packages

3. **Behavioral analysis** — Trace the actual execution paths:
   - Does the happy path actually work end-to-end?
   - What happens on every error path? Are errors swallowed, misclassified, or leaked?
   - Are there race conditions, deadlocks, or TOCTOU bugs?
   - Does state management remain consistent across all paths?

4. **Design critique** — Evaluate the structural decisions:
   - Does the solution solve the *actual* problem or a simplified version of it?
   - Are there unnecessary abstractions, premature generalizations, or gold-plating?
   - Does it violate the conventions of the existing codebase?
   - Will it be maintainable by someone who didn't write it?
   - Are there implicit assumptions that will break when conditions change?

5. **Test coverage** — If tests were written or modified:
   - Do tests actually assert the right things, or just exercise code without meaningful checks?
   - Are there missing negative tests, boundary tests, or integration tests?
   - Could tests pass with a broken implementation (tautological tests)?
   - If no tests were written, should there have been?

6. **Omission audit** — What was *not* done that should have been:
   - Missing error handling, logging, or observability
   - Missing migrations, config changes, or documentation updates
   - Missing cleanup of dead code, stale references, or obsolete files
   - Incomplete implementation that was hand-waved

## Output Format

Produce a structured report with these sections:

### Verdict
One of: `PASS` | `PASS WITH CONCERNS` | `NEEDS REWORK` | `REJECT`

### Critical Issues
Problems that will cause failures, data loss, or security vulnerabilities. Each with file path, line number, and concrete description of the failure mode.

### Warnings
Problems that won't immediately break but indicate fragility, poor practice, or future risk.

### Nitpicks
Style, naming, or structural issues that are suboptimal but functional.

### Omissions
Things that should exist but don't.

### What Actually Worked
Brief acknowledgment of what was done correctly — an adversarial review that finds nothing good is not credible.

---

Do NOT ask clarifying questions. Do NOT skip files because they're "probably fine." Read everything that was changed. Be thorough. Be specific. Cite line numbers. The goal is to catch what the author missed before it reaches production.

# Styrene Agent

Claude Code plugin for styrene mesh network development, fleet operations, and shared tooling.

## Installation

```bash
# Add the marketplace
/plugin marketplace add styrene-lab/styrene-agent

# Install the plugin
/plugin install styrene-tools@styrene-agent --scope user
```

## What's Included

### Shared Skills (canonical source)

These skills are domain-neutral and maintained here as the source of truth.
Downstream consumers (e.g., [recro/coe-agent](https://github.com/recro/coe-agent))
vendor copies and sync updates via CI.

- **chronos** - Authoritative date and time context from system clock
- **cleave** - Recursive task decomposition via `styrene-cleave` CLI
- **distill** - Session context distillation for handoff
- **session-log** - Append-only session tracking for memory continuity
- **visualizer** - Mermaid diagram management and rendering

### Development Skills

Language and toolchain conventions for styrene-lab projects.

- **git** - Conventional commits, semver, branch naming, tagging, changelogs
- **python** - Project setup, pytest, ruff, mypy, packaging, CI/CD
- **rust** - Cargo, clippy, rustfmt, testing, Zellij WASM plugins

### Domain Skills

Skills tied to styrene mesh network infrastructure.

- **bare-metal-ops** - SSH fleet operations, device registry, remote deployment
- **rns-operations** - Reticulum/LXMF config, mesh diagnostics, wire protocol
- **styrene-topology** - System architecture, component map, device fleet

## Prerequisites

- **cleave CLI**: `pipx install styrene-cleave`

## Updating

```bash
/plugin marketplace update styrene-agent
/plugin update styrene-tools@styrene-agent
```

## Downstream Consumers

This repo is the canonical source for shared skills. Downstream plugins sync via
GitHub Actions workflows that open PRs when upstream changes are detected.

To consume shared skills in your own plugin:
1. Reference `.github/workflows/sync-upstream-skills.yml` in [recro/coe-agent](https://github.com/recro/coe-agent) for an example sync workflow
2. Add skills to sync to the `ALL_SHARED` list
3. Merge the PR when it appears, or close to skip

## License

MIT

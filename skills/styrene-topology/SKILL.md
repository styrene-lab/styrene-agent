---
name: styrene-topology
description: Styrene mesh network topology, component architecture, and device map. Use when asking about system components, how repos relate, device capabilities, or mesh network layout.
---

# Styrene Topology Skill

Architecture, component relationships, and device topology for the styrene mesh network system.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Operator Workstation                                            │
│  ┌───────────────────────────────────────────────────────┐      │
│  │  styrene-tui (Python + Textual)                        │      │
│  │  • Uses styrened as library (RPCClient, models)        │      │
│  │  • Fleet dashboard, device management                  │      │
│  └───────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                            │
            Styrene Wire Protocol over LXMF
                            │
┌───────────────────────────┼───────────────────────────────────┐
│                           │                                    │
│  ┌─────────────┐  ┌──────┴──────┐  ┌──────────────────┐      │
│  │ Styrene Hub │  │ Mesh Router │  │  Fleet Device    │      │
│  │ (NomadNet)  │  │ (OpenWrt)   │  │  (NixOS/Debian)  │      │
│  │ • Specs     │  │ • BATMAN    │  │  • styrened      │      │
│  │ • Fleet cfg │  │ • 802.11s   │  │  • RPCServer     │      │
│  │ [TODO]      │  │ • WiFi AP   │  │  • BATMAN        │      │
│  └─────────────┘  └─────────────┘  └──────────────────┘      │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

## Component Map

### Core Repos (styrene-lab/)

| Component | Repo | Language | Role |
|-----------|------|----------|------|
| **styrened** | `styrene-lab/styrened` | Python 3.9+ | Headless daemon + shared library. RPC server, device discovery, auto-reply. |
| **styrene-tui** | `styrene-lab/styrene-tui` | Python (Textual) | Terminal UI client. Fleet dashboard, device management. Imperial CRT aesthetic. |
| **styrene-edge** | `styrene-lab/styrene-edge` | Nix/Python/shell | Edge fleet provisioning for ARM SBCs and MCUs. NixOS configs. |
| **reticulum** | `styrene-lab/reticulum` | Python | Styrene Hub — public transport node with RNS/LXMF propagation, NomadNet BBS. |
| **styrene** | `styrene-lab/styrene` | Obsidian vault | Org context, planning docs, research notes, architecture decisions. |

### Dependency Graph

```
styrened (daemon + library)
├── styrene-tui (TUI consumer — imports RPCClient, models, protocols)
├── styrene-web-bridge (web API consumer — REST/WebSocket over IPC) [planning]
├── reticulum hub (fleet management consumer)
└── styrene-edge (device provisioning — deploys styrened to edge nodes)
```

### Network Layers

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Application** | Styrene Wire Protocol | RPC, fleet management, device discovery |
| **Message** | LXMF | Reliable message delivery, store-and-forward |
| **Transport** | Reticulum (RNS) | Cryptographic identity, encrypted links, routing |
| **L2 Mesh** | BATMAN-adv | Multi-hop wireless routing, transparent bridging |
| **Physical** | WiFi (802.11s), LoRa, Ethernet | Connectivity |

### Why Two Mesh Layers?

**BATMAN-adv (L2)**: "How do I get an Ethernet frame from radio A to radio B across 3 hops?" Uses MAC addresses, measures throughput, adapts to interference. Creates a virtual switch.

**Reticulum (Overlay)**: "How do I send an encrypted message to cryptographic identity X?" Uses 128-bit destination hashes, transport-agnostic. End-to-end encryption.

Reticulum sees BATMAN-adv's `bat0` interface as just another network interface. The layers complement each other.

## Physical Device Fleet

### Test Infrastructure

Located on the vanderlyn.local network (192.168.0.0/24). Managed via SSH with key auth (`~/.ssh/styrene-admin`).

| Device | Host | Hardware | CPU | Arch | OS |
|--------|------|----------|-----|------|----|
| styrene-node | styrene-node.vanderlyn.local | ASUS Q502LA | i5-4210U | x86_64 | NixOS 24.11 |
| t100ta | t100ta.vanderlyn.local | ASUS T100TA | Atom Z3740 | x86_64 | NixOS 24.11 |
| minigmk | minigmk.vanderlyn.local | GMKtec Mini PC | Intel N150 | x86_64 | Debian 13 |
| mobilepi | mobilepi.vanderlyn.local | RPi 4B Rev 1.5 | Cortex-A72 | aarch64 | Debian 12 |

### Device Capabilities

All test devices support:
- `tcp_server` — Can run RNS TCP server interface
- `auto_interface` — Supports RNS AutoInterface (LAN discovery)
- `systemd_user` — Supports systemd user services for daemon management

### Styrened on Devices

| Component | Path |
|-----------|------|
| Virtual env | `~/.local/styrene-venv` |
| Configuration | `~/.config/styrene/` |
| RNS storage | `~/.reticulum/` |
| Identity | `~/.reticulum/storage/identities/` |

## Deployment Targets

### Bare Metal (Test Fleet)

SSH-based deployment for physical devices. See `bare-metal-ops` skill.

- Registry: `tests/bare-metal/devices.yaml`
- Auth: `~/.ssh/styrene-admin` key
- Python: venv at `~/.local/styrene-venv`

### Kubernetes (CI/CD)

Helm-based deployment for integration testing.

- Chart: `charts/styrened/`
- Test harness: `tests/k8s/harness.py`
- Images: `ghcr.io/styrene-lab/styrened`, `ghcr.io/styrene-lab/styrened-test`
- Cluster: brutus (production K3s) or Kind (CI ephemeral)

### Container (Production)

Multi-arch container images (amd64, arm64):
- `ghcr.io/styrene-lab/styrened:X.Y.Z` — Tagged releases
- `ghcr.io/styrene-lab/styrened:latest` — Latest stable
- `ghcr.io/styrene-lab/styrened:edge` — Main branch bleeding edge

### Nix Flake

Reproducible builds for NixOS fleet devices:
- `styrene-edge` provides NixOS configurations
- Flake inputs include styrened as dependency
- Declarative system config with styrened as a service

## Key Files

| File | Purpose |
|------|---------|
| `styrene/docs/src/architecture-decisions.md` | Executive architecture summary |
| `styrene/docs/src/provisioning-vision.md` | Provisioning system design |
| `styrene/docs/src/styrene-tui-vision.md` | TUI application design |
| `styrened/CLAUDE.md` | Daemon development guide |
| `styrened/tests/bare-metal/devices.yaml` | Physical device registry |
| `styrened/charts/styrened/` | Helm chart for K8s deployment |
| `styrene/research/index.md` | Research notes index |

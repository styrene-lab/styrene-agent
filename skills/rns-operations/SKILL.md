---
name: rns-operations
description: Reticulum Network Stack operations for styrene mesh networks. Use when configuring RNS/LXMF, troubleshooting mesh connectivity, managing transport nodes, or working with the wire protocol.
---

# RNS Operations Skill

Operations and reference for the Reticulum Network Stack (RNS) as used by the styrene mesh network.

## Overview

Styrene uses Reticulum as its overlay network:
- **RNS (Reticulum)**: Transport layer — cryptographic identities, encrypted links, transport routing
- **LXMF**: Message layer — store-and-forward messaging over RNS
- **Styrene Wire Protocol**: Application layer — RPC, fleet management, device discovery over LXMF

## Layer Model

```
┌─────────────────────────────────────┐
│  Styrene Wire Protocol (StyreneEnvelope) │
├─────────────────────────────────────┤
│  LXMF (Message routing, delivery)   │
├─────────────────────────────────────┤
│  RNS (Identity, encryption, transport) │
├─────────────────────────────────────┤
│  Interface (TCP, UDP, Serial, LoRa)  │
└─────────────────────────────────────┘
```

## Key Concepts

### Identities

Every RNS node has a cryptographic identity (Curve25519 keypair):
- **Identity hash**: 128-bit truncated hash of the public key (displayed as 32-char hex)
- **Destination hash**: Identity hash + app name hash (used for routing)
- Identities are persistent — stored in `~/.reticulum/storage/`

### Destinations

A destination is an addressable endpoint:
- **Single**: One-to-one communication (default for styrened)
- **Group**: One-to-many broadcast
- **Plain**: Unencrypted (announcements only)

### Announces

Nodes periodically broadcast announcements with:
- Their destination hash
- Public key
- Application data (device type, capabilities)
- Used for peer discovery

### Interfaces

How RNS connects to the physical network:

| Interface | Use Case | Config Key |
|-----------|----------|------------|
| TCPServerInterface | Listen for incoming connections | `listen_ip`, `port` |
| TCPClientInterface | Connect to known peer | `target_host`, `target_port` |
| UDPInterface | Local LAN discovery | `listen_ip`, `listen_port` |
| AutoInterface | Zero-config LAN discovery | (automatic) |
| RNodeInterface | LoRa via RNode hardware | `port` (serial) |
| SerialInterface | Direct serial connection | `port`, `speed` |

## Configuration

### RNS Config

Default location: `~/.reticulum/config`

Styrened manages its own RNS instance. Config hierarchy:
1. `~/.config/styrene/core-config.yaml` (styrened config with RNS section)
2. Falls back to `~/.reticulum/config` for standalone RNS

### Styrened RNS Config Section

```yaml
reticulum:
  mode: standalone          # standalone | shared
  interfaces:
    server:
      enabled: true
      listen_ip: 0.0.0.0
      port: 4242
    peers:
      - host: 192.168.0.10
        port: 4242
    auto:
      enabled: true         # AutoInterface for LAN discovery
```

### Standalone vs Shared Mode

| Mode | Behavior |
|------|----------|
| **standalone** | Styrened runs its own RNS instance with dedicated interfaces |
| **shared** | Uses existing RNS instance (e.g., `rnsd` running separately) |

**Use standalone** for: dedicated styrened deployments, bare-metal test nodes
**Use shared** for: devices already running other RNS apps (NomadNet, Sideband)

## LXMF Operations

LXMF (Lightweight Extensible Message Format) provides reliable message delivery:

### Message Types

| Type | Delivery | Use |
|------|----------|-----|
| **Direct** | Immediate, requires active link | RPC requests, status queries |
| **Propagation** | Store-and-forward via propagation nodes | Async messages, offline delivery |

### Styrene Wire Protocol

Messages are wrapped in `StyreneEnvelope`:

```python
# Wire format (simplified)
{
    "protocol": "styrene",      # Protocol discriminator
    "version": 2,               # Wire protocol version
    "type": "rpc_request",      # Message type
    "payload": { ... }          # Type-specific payload
}
```

**Message types:**
| Type | Direction | Purpose |
|------|-----------|---------|
| `rpc_request` | Client → Server | Remote procedure call |
| `rpc_response` | Server → Client | RPC result |
| `announce` | Broadcast | Device discovery |
| `chat` | Peer → Peer | Chat messages (NomadNet compatible) |

### Protocol Discrimination

LXMF messages are routed by `fields["protocol"]`:
- `"styrene"` → StyreneProtocol handler (RPC, fleet ops)
- `"chat"` → ChatProtocol handler (NomadNet/MeshChat compatible)
- Unknown → Logged and dropped

## Diagnostic Commands

### From Operator Workstation

```bash
# List discovered mesh devices
styrened devices -w 15

# Query a remote device's status
styrened status <dest-hash>

# Send a test message
styrened send <dest-hash> "test message"

# Execute remote command
styrened exec <dest-hash> uptime

# Show local identity
styrened identity

# Trigger manual announce
styrened announce
```

### RNS Native Tools

```bash
# Check RNS status
rnstatus

# Path resolution
rnpath <dest-hash>

# Probe a destination
rnprobe <dest-hash>

# Transfer a file
rncp <source> <dest-hash>:<path>
```

### Common Diagnostics

```bash
# Check if RNS is running
pgrep -af rnsd || pgrep -af styrened

# View RNS logs
journalctl --user -u styrened -f | grep -i rns

# Check interface status
rnstatus -a

# Verify peer connectivity
rnprobe <peer-dest-hash>
```

## Transport Nodes

A transport node relays messages between network segments:

```yaml
# Enable transport on a node
reticulum:
  transport:
    enabled: true
```

Transport nodes are needed when:
- Devices are on different subnets
- Bridging between interface types (TCP ↔ LoRa)
- Running a propagation node for store-and-forward

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No peers discovered | AutoInterface not enabled, or firewall blocking | Enable auto interface, check UDP broadcast |
| Peer visible but no messages | Link not established, timeout | Increase timeout, check bidirectional connectivity |
| "Identity not found" | No identity created yet | `styrened identity --create` |
| Messages delayed | Using propagation instead of direct | Check if direct path exists: `rnpath <dest>` |
| Port 4242 in use | Another RNS/styrened instance running | Check `ss -tlnp \| grep 4242` |
| Announce not received | Announce interval too long, or network partition | `styrened announce` to force, check interfaces |

## Reference

- **RNS Documentation**: https://markqvist.github.io/Reticulum/manual/
- **LXMF Spec**: https://github.com/markqvist/LXMF
- **Styrene Wire Protocol**: `src/styrened/models/styrene_wire.py`
- **RNS Service**: `src/styrened/services/reticulum.py`
- **LXMF Service**: `src/styrened/services/lxmf_service.py`
- **Protocol Handlers**: `src/styrened/protocols/`

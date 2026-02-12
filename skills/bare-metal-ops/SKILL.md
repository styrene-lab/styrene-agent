---
name: bare-metal-ops
description: SSH fleet operations for styrened bare-metal test infrastructure. Use when deploying to physical devices, running remote tests, managing the device registry, or troubleshooting device connectivity.
---

# Bare-Metal Operations Skill

SSH-based fleet operations for the styrened bare-metal test infrastructure. Physical devices used for integration testing outside of K8s/Kind.

## Device Registry

The source of truth for bare-metal test devices is:
```
~/workspace/styrene-lab/styrened/tests/bare-metal/devices.yaml
```

### Current Fleet

| Device | Host | Hardware | Arch | OS |
|--------|------|----------|------|----|
| styrene-node | styrene-node.vanderlyn.local | ASUS Q502LA | x86_64 | NixOS 24.11 |
| t100ta | t100ta.vanderlyn.local | ASUS T100TA | x86_64 | NixOS 24.11 |
| minigmk | minigmk.vanderlyn.local | GMKtec Mini PC | x86_64 | Debian 13 |
| mobilepi | mobilepi.vanderlyn.local | Raspberry Pi 4B Rev 1.5 | aarch64 | Debian 12 |

### Device Groups

| Group | Devices | Use Case |
|-------|---------|----------|
| all | All 4 devices | Full fleet tests |
| nixos | styrene-node, t100ta | NixOS-specific features |
| debian | minigmk, mobilepi | Debian-specific features |
| x86_64 | styrene-node, t100ta, minigmk | x86 architecture tests |
| aarch64 | mobilepi | ARM architecture tests |

## SSH Access

All devices use key-based SSH authentication via `~/.ssh/styrene-admin`. SSH config should handle user/key selection.

```bash
# Test connectivity to a device
ssh styrene-node.vanderlyn.local hostname

# Test all devices
for host in styrene-node t100ta minigmk mobilepi; do
  echo -n "$host: "
  ssh "${host}.vanderlyn.local" hostname 2>/dev/null || echo "UNREACHABLE"
done
```

### SSH Config Pattern

```
Host *.vanderlyn.local
  User styrene
  IdentityFile ~/.ssh/styrene-admin
  StrictHostKeyChecking accept-new
```

## Remote Deployment

### Python venv Setup

All devices use `~/.local/styrene-venv` for the styrened virtual environment:

```bash
# Create/update venv on a device
ssh <host> 'python3 -m venv ~/.local/styrene-venv'
ssh <host> '~/.local/styrene-venv/bin/pip install --upgrade pip'

# Install styrened from wheel
scp dist/styrened-*.whl <host>:/tmp/
ssh <host> '~/.local/styrene-venv/bin/pip install /tmp/styrened-*.whl'

# Install from git (development)
ssh <host> '~/.local/styrene-venv/bin/pip install git+https://github.com/styrene-lab/styrened.git'
```

### Configuration

Device configs live at `~/.config/styrene/` on each device:

```bash
# Push config to a device
scp config/bare-metal/<device>/core-config.yaml <host>:~/.config/styrene/

# Verify config
ssh <host> 'cat ~/.config/styrene/core-config.yaml'
```

### Daemon Management

On NixOS devices (systemd user service):
```bash
ssh <host> 'systemctl --user restart styrened'
ssh <host> 'systemctl --user status styrened'
ssh <host> 'journalctl --user -u styrened -f'
```

On Debian devices (manual or systemd):
```bash
ssh <host> '~/.local/styrene-venv/bin/styrened daemon &'
ssh <host> 'pgrep -f styrened'
```

## Remote Testing

### Smoke Tests

Quick validation that styrened is running and responsive:

```bash
# Check daemon is running
ssh <host> 'pgrep -af styrened'

# Check identity exists
ssh <host> '~/.local/styrene-venv/bin/styrened identity'

# Check device discovery
ssh <host> '~/.local/styrene-venv/bin/styrened devices -w 5'
```

### Cross-Device Tests

Test mesh connectivity between two devices:

```bash
# Get identity hash from device A
HASH_A=$(ssh device-a '~/.local/styrene-venv/bin/styrened identity' | grep hash | awk '{print $2}')

# Query status from device B
ssh device-b "~/.local/styrene-venv/bin/styrened status $HASH_A"

# Send message from device B to A
ssh device-b "~/.local/styrene-venv/bin/styrened send $HASH_A 'hello from B'"
```

## Adding New Devices

1. Ensure device is on the vanderlyn.local network (192.168.0.0/24)
2. Create DNS record via Technitium (or verify existing)
3. Deploy SSH key: `ssh-copy-id -i ~/.ssh/styrene-admin <host>`
4. Verify SSH: `ssh <host> 'uname -a'`
5. Add entry to `tests/bare-metal/devices.yaml`
6. Set up Python venv and install styrened
7. Deploy configuration
8. Update `identity_hash` after first daemon run

## Troubleshooting

| Problem | Check |
|---------|-------|
| SSH timeout | `ping <host>.vanderlyn.local` — device may be offline |
| Permission denied | `ssh -v <host>` — check key, user, sshd config |
| styrened not found | Verify venv: `ssh <host> 'ls ~/.local/styrene-venv/bin/styrened'` |
| No mesh peers | Check RNS config, verify interfaces, check firewall (port 4242) |
| Identity missing | Run `ssh <host> '~/.local/styrene-venv/bin/styrened identity --create'` |

## Important Notes

- The `!` character in passwords causes shell expansion issues with `sshpass -p`. Use `SSHPASS` env var with `sshpass -e`, or `expect`, or (preferred) key-based auth.
- NixOS devices use declarative config — system changes go through `nixos-rebuild`, not manual package installs.
- The Raspberry Pi 4B (mobilepi) is the only aarch64 device — test ARM-specific behavior here.

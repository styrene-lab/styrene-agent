# /oci-login

Authenticate with OCI registries for container image operations.

## Usage

```
/oci-login
```

## Process

### 1. Pre-flight Check

```bash
# Check current auth status
gh auth status
podman login --get-login ghcr.io 2>/dev/null || echo "ghcr.io: not logged in"
```

### 2. Authenticate to Required Registries

#### GitHub Container Registry (ghcr.io)

**Requires:** `gh` CLI authenticated with `write:packages` scope

```bash
# Check scope
gh auth status

# Add scope if missing
gh auth refresh -s write:packages

# Login
gh auth token | podman login ghcr.io -u $(gh api user --jq .login) --password-stdin
```

styrene-lab images live at `ghcr.io/styrene-lab/`:
- `ghcr.io/styrene-lab/styrened` - Production daemon image
- `ghcr.io/styrene-lab/styrened-test` - CI test image

#### Docker Hub (docker.io)

```bash
# Interactive login (prompts for password)
podman login docker.io -u <username>
```

### 3. Post-login Verification

```bash
podman login --get-login ghcr.io
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| ghcr.io permission denied | `gh auth refresh -s write:packages` |
| podman not found | Use `docker login` instead |
| Token expired | Re-run login commands |

## Notes

- Podman stores credentials in `${XDG_RUNTIME_DIR}/containers/auth.json`
- Docker stores credentials in `~/.docker/config.json`
- For CI, use `GITHUB_TOKEN` environment variable instead of interactive login

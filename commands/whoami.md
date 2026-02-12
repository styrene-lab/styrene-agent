# /whoami

Check authentication status across all development tools and refresh expired sessions.

## Usage

```
/whoami
```

## Process

1. Find and run the identity script: `find ~/.claude/plugins/cache -path "*/skills/identity/identity.sh" -type f 2>/dev/null | head -1 | xargs bash -- all`
2. For each domain showing `⚠` or `✗`, offer refresh
3. Run appropriate login commands
4. Verify after refresh

## Status Indicators

| Symbol | Meaning | Action |
|--------|---------|--------|
| `✓` | Authenticated | None |
| `⚠` | Expired | Offer refresh |
| `✗` | Not authenticated | Offer login |
| (dim) | Not installed | Skip |

## Refresh Commands

| Domain | Command |
|--------|---------|
| Git | `git config user.name && git config user.email` |
| GitHub | `gh auth login` |
| ghcr.io | `gh auth token \| podman login ghcr.io -u $(gh api user --jq .login) --password-stdin` |
| AWS SSO | `aws sso login --profile <profile>` |
| K8s | `kubectl config current-context` |
| npm | `npm login` |

## Fallback

If the identity script is not found (no recro-tools plugin), perform manual checks:

```bash
# Git identity
echo "Git: $(git config user.name) <$(git config user.email)>"

# GitHub CLI
gh auth status

# OCI registries
podman login --get-login ghcr.io 2>/dev/null || echo "ghcr.io: not logged in"

# Kubernetes
kubectl config current-context 2>/dev/null || echo "k8s: no context"
```

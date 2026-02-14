#!/usr/bin/env bash
# styrene-tools statusline for Claude Code
# Shows: branch · model · context bar · MCP servers
#
# Install: add to ~/.claude/settings.json:
#   { "statusLine": { "type": "command", "command": "<path>/statusline/statusline.sh" } }

input=$(cat)

# Parse JSON
model=$(echo "$input" | jq -r '.model.display_name // "?"')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // "."')

# Git branch
branch=$(git -C "$project_dir" branch --show-current 2>/dev/null || true)

# MCP server count
mcp_count=0
for f in ~/.claude/mcp.json "${project_dir}/.mcp.json"; do
    if [[ -f "$f" ]]; then
        n=$(jq '.mcpServers | length' "$f" 2>/dev/null || echo 0)
        mcp_count=$((mcp_count + n))
    fi
done

# Color-coded context bar
BAR_WIDTH=10
filled=$((ctx_pct * BAR_WIDTH / 100))
empty=$((BAR_WIDTH - filled))

if [[ "$ctx_pct" -ge 95 ]]; then
    color='\033[30m'   # black
elif [[ "$ctx_pct" -ge 70 ]]; then
    color='\033[31m'   # red
elif [[ "$ctx_pct" -ge 40 ]]; then
    color='\033[33m'   # yellow
else
    color='\033[32m'   # green
fi
reset='\033[0m'

bar=$(printf "%${filled}s" | tr ' ' '█')$(printf "%${empty}s" | tr ' ' '░')
ctx_display="${color}${bar} ${ctx_pct}%${reset}"

# Build output
parts=()
[[ -n "${branch:-}" ]] && parts+=("${branch}")
parts+=("${model}")
parts+=("CTX_PLACEHOLDER")
[[ "$mcp_count" -gt 0 ]] && parts+=("mcp:${mcp_count}")

# Join with dimmed separator
dim='\033[2m'
sep="${dim}·${reset}"

result=""
for i in "${!parts[@]}"; do
    [[ $i -gt 0 ]] && result+=" ${sep} "
    part="${parts[$i]}"
    if [[ "$part" == "CTX_PLACEHOLDER" ]]; then
        result+="${ctx_display}"
    else
        result+="${part}"
    fi
done

echo -e "$result"

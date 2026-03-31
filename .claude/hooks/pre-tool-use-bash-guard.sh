#!/usr/bin/env bash
# Three-Layer Bash Command Defense Hook for Claude Code
# Layer 1: Dangerous pattern detection → DENY
# Layer 2: Blacklist interception → DENY
# Layer 3: Whitelist auto-allow → ALLOW
# Fallback: pass to user for judgment

set -uo pipefail

# Read JSON from stdin
INPUT=$(cat)

# Check jq availability; if missing, don't block
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Extract the command string
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# --- Helper functions ---

deny() {
    jq -n --arg reason "$1" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

allow() {
    jq -n '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "allow"
        }
    }'
    exit 0
}

# Split compound commands into segments (by |, ;, &&, ||)
# Store in array to avoid subshell issues
split_segments() {
    local cmd="$1"
    # Replace compound operators with newlines (order matters: || before |)
    echo "$cmd" | sed -E 's/\|\|/\n/g; s/&&/\n/g; s/;/\n/g; s/\|/\n/g'
}

# Extract the base command from a segment
get_base_cmd() {
    echo "$1" | sed 's/^[[:space:]]*//' | sed 's/^[A-Z_]*=[^ ]* //' | awk '{print $1}'
}

# ============================================================
# LAYER 1: Dangerous Pattern Detection → DENY
# Structural patterns that are dangerous regardless of command
# ============================================================

# Fork bomb patterns
if echo "$COMMAND" | grep -qE ':\(\)\s*\{.*\|.*&\s*\}'; then
    deny "Layer 1: Fork bomb pattern detected"
fi

# Pipe-to-shell: curl/wget piped to bash/sh/zsh/python
if echo "$COMMAND" | grep -qE '\|\s*(bash|sh|zsh|dash|python3?|ruby|perl|node)\b'; then
    deny "Layer 1: Pipe-to-shell detected — command output piped to interpreter"
fi

# Directory traversal: .. attempts to escape project directory
if echo "$COMMAND" | grep -qE '(^|\s|/)\.\.(\/|\s|$)'; then
    deny "Layer 1: Directory traversal detected — '..' attempts to escape project directory"
fi

# Redirect to ~ (home directory paths)
if echo "$COMMAND" | grep -qE '>\s*~'; then
    deny "Layer 1: Redirect to home directory path"
fi

# Redirect to absolute path outside project directory
redirect_target=$(echo "$COMMAND" | grep -oE '>\s*/[^ ]+' | head -1 | sed 's/^>[[:space:]]*//')
if [[ -n "$redirect_target" && -n "${CLAUDE_PROJECT_DIR:-}" ]] && [[ "$redirect_target" != "$CLAUDE_PROJECT_DIR"* ]]; then
    deny "Layer 1: Redirect to path outside project directory — $redirect_target"
fi

# dd writing to disk
if echo "$COMMAND" | grep -qE '\bdd\b.*\bof='; then
    deny "Layer 1: dd write operation detected"
fi

# /dev/sd* or /dev/disk* direct access
if echo "$COMMAND" | grep -qE '/dev/(sd[a-z]|disk[0-9]|nvme)'; then
    deny "Layer 1: Direct disk device access detected"
fi

# ============================================================
# LAYER 2: Blacklist Interception → DENY
# Known dangerous/write commands
# ============================================================

check_blacklist() {
    local cmd="$1"
    local base
    base=$(get_base_cmd "$cmd")

    case "$base" in
        rm|rmdir)
            deny "Layer 2: Destructive file removal — $base"
            ;;
        sudo|su)
            deny "Layer 2: Privilege escalation — $base"
            ;;
        eval|exec)
            deny "Layer 2: Dynamic execution — $base"
            ;;
        kill|killall|pkill)
            deny "Layer 2: Process termination — $base"
            ;;
        ssh|scp|sftp)
            deny "Layer 2: Remote access — $base"
            ;;
        chmod|chown|chgrp)
            deny "Layer 2: Permission modification — $base"
            ;;
        mkfs|fdisk|mount|umount)
            deny "Layer 2: Disk operation — $base"
            ;;
        systemctl|launchctl)
            deny "Layer 2: Service management — $base"
            ;;
        wget)
            deny "Layer 2: wget downloads files by default"
            ;;
        tee)
            deny "Layer 2: tee writes to files"
            ;;
        mv)
            deny "Layer 2: File move/rename"
            ;;
        cp)
            deny "Layer 2: File copy — may overwrite"
            ;;
        defaults)
            if echo "$cmd" | grep -qE '\bdefaults\s+write\b'; then
                deny "Layer 2: macOS defaults write — modifies system preferences"
            fi
            ;;
        git)
            if echo "$cmd" | grep -qE '\bgit\s+(push|reset|clean)\b'; then
                deny "Layer 2: Destructive git command — push/reset/clean"
            fi
            if echo "$cmd" | grep -qE '\bgit\s+checkout\s+--\s*\.'; then
                deny "Layer 2: git checkout -- . discards all changes"
            fi
            if echo "$cmd" | grep -qE '\bgit\s+restore\s+\.'; then
                deny "Layer 2: git restore . discards all changes"
            fi
            ;;
        curl)
            if echo "$cmd" | grep -qE '\bcurl\b.*\s-[A-Za-z]*[xX]\s*(POST|PUT|DELETE|PATCH)'; then
                deny "Layer 2: curl with write HTTP method"
            fi
            if echo "$cmd" | grep -qE '\bcurl\b.*\s--request\s+(POST|PUT|DELETE|PATCH)'; then
                deny "Layer 2: curl with write HTTP method"
            fi
            if echo "$cmd" | grep -qE '\bcurl\b.*\s(-[A-Za-z]*d\b|--data|--data-raw|--data-binary|--data-urlencode|-F\b|--form)'; then
                deny "Layer 2: curl with data upload (-d/--data/-F/--form implies POST)"
            fi
            if echo "$cmd" | grep -qE '\bcurl\b.*\s-[A-Za-z]*[oO]\b'; then
                deny "Layer 2: curl with file output (-o/-O)"
            fi
            if echo "$cmd" | grep -qE '\bcurl\b.*\s--output\b'; then
                deny "Layer 2: curl with file output (--output)"
            fi
            ;;
        pip|pip3)
            if echo "$cmd" | grep -qE '\bpip3?\s+install\b'; then
                deny "Layer 2: pip install — modifies environment"
            fi
            ;;
        npm|npx)
            if echo "$cmd" | grep -qE '\bnpm\s+install\b'; then
                deny "Layer 2: npm install — modifies node_modules"
            fi
            ;;
        brew)
            if echo "$cmd" | grep -qE '\bbrew\s+(install|uninstall|remove|upgrade)\b'; then
                deny "Layer 2: brew package modification"
            fi
            ;;
    esac
}

# Read segments into array using process substitution (avoids subshell)
while IFS= read -r segment; do
    [[ -z "$segment" ]] && continue
    check_blacklist "$segment"
done < <(split_segments "$COMMAND")

# ============================================================
# LAYER 3: Whitelist Auto-Allow → ALLOW
# Known safe read-only commands
# ============================================================

check_whitelist() {
    local cmd="$1"
    local base
    base=$(get_base_cmd "$cmd")

    case "$base" in
        # File browsing
        ls|cat|head|tail|file|stat|wc|du|df|less|more)
            return 0 ;;
        # Search
        grep|rg|find|which|whereis|locate|mdfind)
            return 0 ;;
        # Text processing (read-only)
        sort|uniq|cut|awk|tr|diff|comm|jq|column|fmt|fold|expand|unexpand)
            return 0 ;;
        sed)
            # sed without -i is safe (stdout only)
            if echo "$cmd" | grep -qE '\bsed\s+-[A-Za-z]*i'; then
                return 1
            fi
            return 0
            ;;
        # Directory info
        pwd|basename|dirname|realpath|tree)
            return 0 ;;
        # System info
        ps|top|uptime|uname|sw_vers|hostname|whoami|id|env|printenv|echo|printf|date|cal)
            return 0 ;;
        # macOS read-only
        defaults)
            if echo "$cmd" | grep -qE '\bdefaults\s+read\b'; then
                return 0
            fi
            return 1 ;;
        plutil)
            if echo "$cmd" | grep -qE '\bplutil\s+-p\b'; then
                return 0
            fi
            return 1 ;;
        mdls)
            return 0 ;;
        # Network read-only
        curl)
            # Already passed Layer 2 blacklist, so no dangerous flags
            return 0 ;;
        ping|nslookup|dig|host|traceroute)
            return 0 ;;
        # Git read-only
        git)
            if echo "$cmd" | grep -qE '\bgit\s+(log|diff|status|branch|show|fetch|stash\s+list|tag|remote|blame|rev-parse|ls-files|ls-tree|shortlog|describe|config\s+--get|config\s+-l|name-rev|reflog)\b'; then
                return 0
            fi
            return 1 ;;
        # Dev tools
        swift)
            if echo "$cmd" | grep -qE '\bswift\s+(--version|build|test|package\s+describe|package\s+dump-package|package\s+show-dependencies)\b'; then
                return 0
            fi
            return 1 ;;
        xcodebuild)
            if echo "$cmd" | grep -qE '\bxcodebuild\s+(-version|-showsdks|-showBuildSettings|build|test)\b'; then
                return 0
            fi
            return 1 ;;
        xcrun)
            return 0 ;;
        pod)
            if echo "$cmd" | grep -qE '\bpod\s+(--version|list|search|spec)\b'; then
                return 0
            fi
            return 1 ;;
        node|ruby)
            if echo "$cmd" | grep -qE '\b(node|ruby)\s+--version\b'; then
                return 0
            fi
            return 1 ;;
        python3)
            if echo "$cmd" | grep -qE '\bpython3\s+(--version|-m\s+json\.tool)\b'; then
                return 0
            fi
            return 1 ;;
        # xargs, open, osascript intentionally NOT whitelisted — too powerful
        # They fall through to user judgment
        *)
            return 1 ;;
    esac
}

# Guard: if command contains $(...) or backticks, skip whitelist auto-allow
# (embedded commands can't be statically verified — fall through to user judgment)
if echo "$COMMAND" | grep -qE '\$\(|`'; then
    # Skip whitelist, go straight to fallback
    exit 0
fi

# For whitelist: ALL segments must be whitelisted
all_whitelisted=true
while IFS= read -r segment; do
    [[ -z "$segment" ]] && continue
    if ! check_whitelist "$segment"; then
        all_whitelisted=false
        break
    fi
done < <(split_segments "$COMMAND")

if [[ "$all_whitelisted" == "true" ]]; then
    allow
fi

# ============================================================
# FALLBACK: No match → pass to user for judgment
# ============================================================
exit 0

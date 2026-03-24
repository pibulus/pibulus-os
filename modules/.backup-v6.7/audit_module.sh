#!/bin/bash
# PIBULUS CYBERDECK AUDIT MODULE v1.0
# Automated security & health verification.

run_audit() {
    clear
    figlet -f slant "AUDIT" | lolcat
    echo ""

    local PASS="[32m[PASS][0m"
    local WARN="[33m[WARN][0m"
    local FAIL="[31m[FAIL][0m"
    local INFO="[34m[INFO][0m"

    local total=0
    local passed=0
    local warnings=0
    local failures=0

    # ── SECURITY ──────────────────────────────────
    gum style --foreground 212 '--- SECURITY POSTURE ---'
    echo ""

    # SSH Password Auth
    total=$((total + 1))
    if sudo sshd -T 2>/dev/null | grep -q "passwordauthentication no"; then
        echo "  $PASS SSH password auth: Disabled"
        passed=$((passed + 1))
    else
        echo "  $FAIL SSH password auth: ENABLED (run install.sh to fix)"
        failures=$((failures + 1))
    fi

    # SSH Root Login
    total=$((total + 1))
    if sudo sshd -T 2>/dev/null | grep -q "permitrootlogin no"; then
        echo "  $PASS Root login: Disabled"
        passed=$((passed + 1))
    else
        echo "  $WARN Root login: Enabled"
        warnings=$((warnings + 1))
    fi

    # SSH Key
    total=$((total + 1))
    if [ -f "$HOME/.ssh/authorized_keys" ] && [ -s "$HOME/.ssh/authorized_keys" ]; then
        local key_count=$(wc -l < "$HOME/.ssh/authorized_keys")
        echo "  $PASS SSH keys: $key_count authorized key(s)"
        passed=$((passed + 1))
    else
        echo "  $FAIL SSH keys: No authorized keys found"
        failures=$((failures + 1))
    fi

    # UFW
    total=$((total + 1))
    if sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        echo "  $PASS Firewall: Active"
        passed=$((passed + 1))
        if sudo ufw status 2>/dev/null | grep -q "192.168.0.0/24"; then
            echo "       LAN rule: Configured"
        fi
        if sudo ufw status 2>/dev/null | grep -q "tailscale0"; then
            echo "       Tailscale rule: Configured"
        fi
    else
        echo "  $FAIL Firewall: INACTIVE"
        failures=$((failures + 1))
    fi

    # Secrets in Git
    total=$((total + 1))
    if git -C "$HOME/pibulus-os" ls-files 2>/dev/null | grep -q '\.env$'; then
        echo "  $FAIL Secrets in git: .env files are tracked!"
        failures=$((failures + 1))
    else
        echo "  $PASS Secrets in git: Protected"
        passed=$((passed + 1))
    fi

    # .gitignore exists
    total=$((total + 1))
    if [ -f "$HOME/pibulus-os/.gitignore" ]; then
        echo "  $PASS .gitignore: Present"
        passed=$((passed + 1))
    else
        echo "  $WARN .gitignore: Missing"
        warnings=$((warnings + 1))
    fi

    echo ""

    # ── CONTAINERS ────────────────────────────────
    gum style --foreground 46 '--- CONTAINER HEALTH ---'
    echo ""

    total=$((total + 1))
    if command -v docker &> /dev/null; then
        local running=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l | tr -d ' ')
        echo "  $INFO Docker: $running containers running"
        passed=$((passed + 1))

        # Unhealthy check
        local unhealthy=$(docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null)
        if [ -z "$unhealthy" ]; then
            echo "  $PASS All containers: Healthy"
        else
            echo "  $FAIL Unhealthy containers:"
            echo "$unhealthy" | while read name; do echo "       - $name"; done
            failures=$((failures + 1))
            total=$((total + 1))
        fi

        # Restarting check
        local restarting=$(docker ps --filter status=restarting --format '{{.Names}}' 2>/dev/null)
        if [ -n "$restarting" ]; then
            echo "  $FAIL Crash-looping:"
            echo "$restarting" | while read name; do echo "       - $name"; done
            failures=$((failures + 1))
            total=$((total + 1))
        fi
    else
        echo "  $FAIL Docker: Not installed"
        failures=$((failures + 1))
    fi

    echo ""

    # ── SYSTEM RESOURCES ──────────────────────────
    gum style --foreground 226 '--- SYSTEM RESOURCES ---'
    echo ""

    # Temperature
    total=$((total + 1))
    if command -v vcgencmd &> /dev/null; then
        local temp=$(vcgencmd measure_temp 2>/dev/null | grep -oP '[0-9]+\.[0-9]+')
        if [ -n "$temp" ]; then
            local temp_int=${temp%.*}
            if [ "$temp_int" -lt 60 ]; then
                echo "  $PASS Temperature: ${temp}C"
                passed=$((passed + 1))
            elif [ "$temp_int" -lt 70 ]; then
                echo "  $WARN Temperature: ${temp}C (warm)"
                warnings=$((warnings + 1))
            else
                echo "  $FAIL Temperature: ${temp}C (throttling risk!)"
                failures=$((failures + 1))
            fi
        fi
    fi

    # Swap
    total=$((total + 1))
    local swap_used=$(free -m | awk '/Swap:/ {print $3}')
    local swap_total=$(free -m | awk '/Swap:/ {print $2}')
    if [ "$swap_used" -lt 1000 ]; then
        echo "  $PASS Swap: ${swap_used}MB / ${swap_total}MB"
        passed=$((passed + 1))
    elif [ "$swap_used" -lt 1500 ]; then
        echo "  $WARN Swap: ${swap_used}MB / ${swap_total}MB (elevated)"
        warnings=$((warnings + 1))
    else
        echo "  $FAIL Swap: ${swap_used}MB / ${swap_total}MB (memory pressure!)"
        failures=$((failures + 1))
    fi

    # Passport Mount
    total=$((total + 1))
    if df -h 2>/dev/null | grep -q "/media/pibulus/passport"; then
        local usage=$(df -h /media/pibulus/passport | awk 'NR==2 {print $5}' | tr -d '%')
        echo "  $PASS Passport: Mounted (${usage}% used)"
        passed=$((passed + 1))
    else
        echo "  $FAIL Passport: NOT MOUNTED"
        failures=$((failures + 1))
    fi

    # Root Disk
    total=$((total + 1))
    local root_pct=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$root_pct" -lt 80 ]; then
        echo "  $PASS Root disk: ${root_pct}% used"
        passed=$((passed + 1))
    elif [ "$root_pct" -lt 90 ]; then
        echo "  $WARN Root disk: ${root_pct}% used (cleanup recommended)"
        warnings=$((warnings + 1))
    else
        echo "  $FAIL Root disk: ${root_pct}% used (CRITICAL)"
        failures=$((failures + 1))
    fi

    echo ""

    # ── NETWORK ───────────────────────────────────
    gum style --foreground 51 '--- NETWORK ---'
    echo ""

    # Tailscale
    if command -v tailscale &> /dev/null; then
        if tailscale status &>/dev/null; then
            local ts_ip=$(tailscale ip -4 2>/dev/null)
            echo "  $INFO Tailscale: Connected ($ts_ip)"
        else
            echo "  $WARN Tailscale: Not connected"
        fi
    fi

    # Cloudflared
    if sudo systemctl is-active --quiet cloudflared 2>/dev/null; then
        echo "  $INFO Cloudflare Tunnel: Active"
    else
        echo "  $WARN Cloudflare Tunnel: Inactive"
    fi

    echo ""

    # ── SUMMARY ───────────────────────────────────
    echo ""
    local score=0
    [ "$total" -gt 0 ] && score=$((passed * 100 / total))

    if [ "$failures" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        play_tone "confirm" 2>/dev/null
        gum style --border double --border-foreground 46 --padding "1 2" \
            "ALL SYSTEMS NOMINAL

Checks: $total | Passed: $passed | Score: ${score}%

Cyberdeck is secure and operational."
    elif [ "$failures" -eq 0 ]; then
        play_tone "click" 2>/dev/null
        gum style --border double --border-foreground 226 --padding "1 2" \
            "MINOR ISSUES DETECTED

Checks: $total | Passed: $passed | Warnings: $warnings | Score: ${score}%

System operational but needs attention."
    else
        play_tone "error" 2>/dev/null
        gum style --border double --border-foreground 196 --padding "1 2" \
            "CRITICAL ISSUES FOUND

Checks: $total | Passed: $passed | Warnings: $warnings | Failures: $failures | Score: ${score}%

Run install.sh or see FIELD_MANUAL.md for fixes."
    fi

    echo ""
    gum input --placeholder "Press Enter to return..."
}

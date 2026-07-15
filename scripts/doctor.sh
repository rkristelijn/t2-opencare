#!/bin/bash
# scripts/doctor.sh — T2 hardware & config diagnostics with auto-repair
# Usage: ./scripts/doctor.sh [--fix]
#
# Without --fix: report only
# With --fix: attempt automatic repairs

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "${REPO_DIR}/lib/common.sh"

AUTO_FIX=false
[[ "${1:-}" == "--fix" ]] && AUTO_FIX=true

ISSUES=0
FIXED=0

check() {
  local name="$1"
  shift
  if "$@" 2>/dev/null; then
    ok "$name"
  else
    fail "$name"
    ((ISSUES++))
    return 1
  fi
}

repair() {
  local desc="$1"
  shift
  if [[ "$AUTO_FIX" == true ]]; then
    info "  Repairing: $desc"
    if "$@" 2>/dev/null; then
      ok "  Fixed: $desc"
      ((FIXED++))
    else
      fail "  Repair failed: $desc"
    fi
  else
    info "  Fix available: run with --fix"
  fi
}

banner() {
  echo -e "${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║      t2-opencare doctor v0.1.0           ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════
# HARDWARE CHECKS
# ═══════════════════════════════════════════════════════════════

check_kernel() {
  step "Kernel & Drivers"

  check "T2 kernel loaded" uname -r | grep -q "t2" || {
    warn "  Running $(uname -r) — not a T2 kernel"
  }

  check "apple-bce module loaded" lsmod | grep -q "apple_bce" || {
    repair "Load apple-bce" sudo modprobe apple-bce
  }

  check "applespi blocked" grep -rq "blacklist applespi" /etc/modprobe.d/ || {
    repair "Block applespi" bash -c 'echo "blacklist applespi" | sudo tee /etc/modprobe.d/blacklist-applespi.conf'
  }
}

check_wifi() {
  step "WiFi"

  check "WiFi interface exists" ip link show wlp1s0 || {
    repair "Reload brcmfmac" bash -c 'sudo modprobe -r brcmfmac 2>/dev/null; sudo modprobe brcmfmac'
  }

  check "WiFi connected" iw dev wlp1s0 link | grep -q "Connected" || {
    warn "  WiFi not connected to a network"
  }
}

check_audio() {
  step "Audio"

  check "PipeWire running" systemctl --user is-active --quiet pipewire 2>/dev/null || \
    pgrep -x pipewire > /dev/null || {
    repair "Start PipeWire" systemctl --user start pipewire
  }

  check "Audio not muted" pactl get-sink-mute @DEFAULT_SINK@ | grep -q "no" || {
    repair "Unmute audio" pactl set-sink-mute @DEFAULT_SINK@ 0
  }
}

check_keyboard() {
  step "Keyboard & Input"

  if [[ -n "${DISPLAY:-}" ]]; then
    local layout
    layout=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}')
    check "Keyboard layout: ${layout}" test "$layout" != "us" || {
      warn "  Layout is US — expected nl or custom"
      repair "Restore keyboard layout" bash -c 'source ~/.xsessionrc 2>/dev/null'
    }
  fi

  check "hid_apple fnmode configured" test -f /etc/modprobe.d/hid_apple.conf || {
    repair "Set fnmode=2" bash -c 'echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf'
  }

  check "Suspend keyboard hook exists" test -x /lib/systemd/system-sleep/restore-keyboard.sh || {
    warn "  Keyboard may reset after suspend"
  }
}

check_kinto() {
  step "Kinto (Cmd↔Ctrl)"

  check "xkeysnail service active" systemctl is-active --quiet xkeysnail || {
    repair "Restart xkeysnail" bash -c 'xhost +SI:localuser:root 2>/dev/null; sudo systemctl restart xkeysnail'
  }

  # Check for crash loop
  local restarts
  restarts=$(systemctl show xkeysnail -p NRestarts 2>/dev/null | cut -d= -f2)
  if [[ "${restarts:-0}" -gt 10 ]]; then
    fail "xkeysnail crash-looping (${restarts} restarts)"
    ((ISSUES++))
    repair "Fix broken input devices" fix_broken_input_devices
  fi
}

check_trackpad() {
  step "Trackpad"

  check "Internal trackpad (apple-bce)" grep -q "Apple Internal Keyboard / Trackpad" /proc/bus/input/devices || {
    fail "Internal trackpad not detected — apple-bce issue?"
  }

  # Check for broken input devices
  local broken=0
  while IFS= read -r dev; do
    if ! sudo python3 -c "import os; os.open('$dev', os.O_RDONLY | os.O_NONBLOCK)" 2>/dev/null; then
      fail "Broken input device: $dev"
      ((ISSUES++))
      ((broken++))
    fi
  done < <(find /dev/input -name "event*" 2>/dev/null)

  if [[ $broken -gt 0 ]]; then
    repair "Remove broken input devices and restart xkeysnail" fix_broken_input_devices
  fi

  # External trackpad
  if grep -q "Magic Trackpad" /proc/bus/input/devices 2>/dev/null; then
    ok "External Magic Trackpad connected"
  else
    info "  No external trackpad detected (optional)"
  fi
}

check_touchbar() {
  step "Touch Bar"

  check "tiny-dfr installed" dpkg -l | grep -q tiny-dfr || {
    info "  Touch Bar shows Fn keys only (install tiny-dfr for full support)"
  }
}

check_touchegg() {
  step "Gestures (Touchegg)"

  check "Touchegg service active" systemctl is-active --quiet touchegg || {
    repair "Start touchegg" bash -c 'sudo systemctl enable touchegg; sudo systemctl start touchegg'
  }

  check "User in input group" groups | grep -q input || {
    repair "Add user to input group" sudo usermod -aG input "$USER"
    warn "  Logout required for group change"
  }
}

# ═══════════════════════════════════════════════════════════════
# PERFORMANCE CHECKS
# ═══════════════════════════════════════════════════════════════

check_performance() {
  step "Performance"

  local load
  load=$(awk '{print $1}' /proc/loadavg)
  local cores
  cores=$(nproc)
  check "Load average: ${load} (${cores} cores)" awk "BEGIN {exit ($load > $cores * 2)}" || {
    warn "  System is overloaded"
    # Find top CPU consumer
    local top_proc
    top_proc=$(ps aux --sort=-%cpu | awk 'NR==2{print $11, $3"%"}')
    info "  Top process: ${top_proc}"
  }

  local mem_pct
  mem_pct=$(free | awk '/Mem/{printf "%d", $3/$2*100}')
  check "Memory: ${mem_pct}% used" test "$mem_pct" -lt 90 || {
    warn "  Memory critically high"
  }

  local disk_pct
  disk_pct=$(df / | awk 'NR==2{gsub(/%/,""); print $5}')
  check "Disk: ${disk_pct}% used" test "$disk_pct" -lt 85 || {
    warn "  Disk getting full"
  }

  local temp
  temp=$(sensors 2>/dev/null | awk '/Package id 0/{gsub(/[^0-9.]/, "", $4); print int($4)}')
  if [[ -n "$temp" ]]; then
    check "CPU temp: ${temp}°C" test "$temp" -lt 85 || {
      warn "  CPU is hot — check fans/workload"
    }
  fi
}

# ═══════════════════════════════════════════════════════════════
# SECURITY CHECKS (CIS-lite)
# ═══════════════════════════════════════════════════════════════

check_security() {
  step "Security (CIS-lite)"

  check "Firewall active" sudo ufw status 2>/dev/null | grep -q "active" || {
    repair "Enable firewall" bash -c 'sudo ufw --force enable'
  }

  check "No world-writable in /etc" test "$(find /etc -perm -o+w -type f 2>/dev/null | wc -l)" -eq 0 || {
    warn "  World-writable files found in /etc"
  }

  check "SSH: no root login" grep -qE "^PermitRootLogin\s+no" /etc/ssh/sshd_config 2>/dev/null || {
    warn "  SSH allows root login (consider disabling)"
  }

  check "No failed systemd services" test "$(systemctl --failed --no-legend 2>/dev/null | wc -l)" -eq 0 || {
    local failed
    failed=$(systemctl --failed --no-legend | awk '{print $1}' | tr '\n' ' ')
    warn "  Failed services: ${failed}"
  }

  local updates
  updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
  if [[ "$updates" -gt 1 ]]; then
    info "  ${updates} pending security updates"
  fi
}

# ═══════════════════════════════════════════════════════════════
# REPAIR FUNCTIONS
# ═══════════════════════════════════════════════════════════════

fix_broken_input_devices() {
  info "  Scanning for broken input devices..."
  local fixed=0
  while IFS= read -r dev; do
    if ! sudo python3 -c "import os; os.open('$dev', os.O_RDONLY | os.O_NONBLOCK)" 2>/dev/null; then
      local event_name
      event_name=$(basename "$dev")
      local sysfs_path
      sysfs_path=$(grep -l "$event_name" /sys/class/input/*/event*/uevent 2>/dev/null | head -1)
      if [[ -n "$sysfs_path" ]]; then
        local device_path
        device_path=$(dirname "$(dirname "$sysfs_path")")
        info "  Removing broken device: $dev"
        # Find USB parent and reset
        local usb_path
        usb_path=$(echo "$device_path" | grep -oP '/sys/devices.*?/usb\d+/[\d.-]+' | head -1)
        if [[ -n "$usb_path" ]] && [[ -f "${usb_path}/authorized" ]]; then
          sudo sh -c "echo 0 > ${usb_path}/authorized" 2>/dev/null
          sleep 1
          sudo sh -c "echo 1 > ${usb_path}/authorized" 2>/dev/null
          ((fixed++))
        fi
      fi
    fi
  done < <(find /dev/input -name "event*" 2>/dev/null)

  if [[ $fixed -gt 0 ]]; then
    sleep 2
    sudo systemctl restart xkeysnail 2>/dev/null || true
    ok "  Reset ${fixed} device(s) and restarted xkeysnail"
  fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
  banner

  if [[ "$AUTO_FIX" == true ]]; then
    info "Running in repair mode (--fix)"
  else
    info "Running in diagnostic mode (use --fix to auto-repair)"
  fi
  echo ""

  check_kernel
  echo ""
  check_wifi
  echo ""
  check_audio
  echo ""
  check_keyboard
  echo ""
  check_kinto
  echo ""
  check_trackpad
  echo ""
  check_touchbar
  echo ""
  check_touchegg
  echo ""
  check_performance
  echo ""
  check_security

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if [[ $ISSUES -eq 0 ]]; then
    ok "All checks passed ✓"
  else
    warn "${ISSUES} issue(s) found"
    if [[ $FIXED -gt 0 ]]; then
      ok "${FIXED} auto-repaired"
    fi
    if [[ "$AUTO_FIX" == false ]] && [[ $ISSUES -gt $FIXED ]]; then
      info "Run './scripts/doctor.sh --fix' to attempt repairs"
    fi
  fi
}

main "$@"

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
  echo "  ║      t2-opencare doctor v0.2.0           ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
}

# ═══════════════════════════════════════════════════════════════
# HARDWARE CHECKS
# ═══════════════════════════════════════════════════════════════

check_kernel() {
  step "Kernel & Drivers"

  local kver
  kver=$(uname -r)
  if echo "$kver" | grep -q "t2"; then
    ok "T2 kernel: ${kver}"
  else
    fail "Not a T2 kernel: ${kver}"
    ((ISSUES++))
    repair "Install T2 kernel" bash -c 'sudo apt update && sudo apt install -y linux-t2'
  fi

  check "apple-bce driver active" bash -c 'lsmod | grep -q apple_bce || grep -q "Apple Internal Keyboard / Trackpad" /proc/bus/input/devices' || {
    repair "Load apple-bce" sudo modprobe apple-bce
  }

  check "applespi blocked" bash -c 'grep -rq "blacklist applespi" /etc/modprobe.d/' || {
    repair "Block applespi" bash -c 'echo "blacklist applespi" | sudo tee /etc/modprobe.d/blacklist-applespi.conf'
  }
}

check_wifi() {
  step "WiFi"

  check "WiFi interface exists" bash -c 'ip link show wlp1s0 >/dev/null 2>&1' || {
    repair "Reload brcmfmac" bash -c 'sudo modprobe -r brcmfmac 2>/dev/null; sudo modprobe brcmfmac'
  }

  if ip link show wlp1s0 &>/dev/null; then
    check "WiFi connected" bash -c 'iw dev wlp1s0 link 2>/dev/null | grep -q "Connected"' || {
      warn "  WiFi interface exists but not connected to a network"
    }
  fi
}

check_audio() {
  step "Audio"

  check "PipeWire running" bash -c 'systemctl --user is-active --quiet pipewire 2>/dev/null || pgrep -x pipewire >/dev/null' || {
    repair "Start PipeWire" systemctl --user start pipewire
  }

  check "Audio not muted" bash -c 'pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "no"' || {
    repair "Unmute audio" pactl set-sink-mute @DEFAULT_SINK@ 0
  }
}

check_keyboard_layout() {
  step "Keyboard Layout"

  local expected_layout="${KB_LAYOUT:-nl}"
  local expected_variant="${KB_VARIANT:-mac}"

  # /etc/default/keyboard
  check "/etc/default/keyboard has correct layout" \
    bash -c "grep -q 'XKBLAYOUT=\"${expected_layout}\"' /etc/default/keyboard" || {
    repair "Set keyboard layout to ${expected_layout}" bash -c "
      sudo tee /etc/default/keyboard > /dev/null <<KBEOF
XKBMODEL=\"apple_laptop\"
XKBLAYOUT=\"${expected_layout}\"
XKBVARIANT=\"${expected_variant}\"
XKBOPTIONS=\"\"
BACKSPACE=\"guess\"
KBEOF
      sudo setupcon 2>/dev/null || true"
  }

  # Cinnamon not overriding to US
  if [[ -n "${DISPLAY:-}" ]]; then
    local sources
    sources=$(gsettings get org.cinnamon.desktop.input-sources sources 2>/dev/null || echo "")
    if echo "$sources" | grep -q "'us'" && ! echo "$sources" | grep -q "${expected_layout}"; then
      fail "Cinnamon input-source set to US (will override layout)"
      ((ISSUES++))
      repair "Set Cinnamon input-source to ${expected_layout}" \
        gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', '${expected_layout}+${expected_variant}')]"
    else
      ok "Cinnamon input-source correct"
    fi
  fi

  # hid_apple fnmode
  check "hid_apple fnmode configured" test -f /etc/modprobe.d/hid_apple.conf || {
    repair "Set fnmode=2" bash -c 'echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf'
  }
}

check_keyd() {
  step "Keyboard Mapping (keyd)"

  # keyd binary exists
  check "keyd installed" bash -c 'command -v keyd >/dev/null' || {
    repair "Install keyd" bash -c "
      cd /tmp && rm -rf keyd-build
      git clone --depth 1 https://github.com/rvaiya/keyd.git keyd-build
      cd keyd-build && make -j\$(nproc) && sudo make install
      rm -rf /tmp/keyd-build"
  }

  # Service running
  check "keyd service active" bash -c 'systemctl is-active --quiet keyd' || {
    repair "Start keyd" bash -c 'sudo systemctl daemon-reload; sudo systemctl enable keyd; sudo systemctl restart keyd'
  }

  # Config has meta_mac layer (not dumb swap)
  if [[ -f /etc/keyd/default.conf ]]; then
    check "keyd config: meta_mac:C layer (not dumb swap)" \
      bash -c 'grep -q "meta_mac:C" /etc/keyd/default.conf' || {
      fail "  keyd config uses old Meta↔Ctrl swap (breaks terminal Ctrl)"
      repair "Write correct keyd config" bash -c "
        source '${REPO_DIR}/plugins/desktop/keyd.sh' 2>/dev/null
        _keyd_config | sudo tee /etc/keyd/default.conf >/dev/null
        sudo keyd reload"
    }
  else
    fail "keyd config missing: /etc/keyd/default.conf"
    ((ISSUES++))
    repair "Write keyd config" bash -c "
      sudo mkdir -p /etc/keyd
      source '${REPO_DIR}/plugins/desktop/keyd.sh' 2>/dev/null
      _keyd_config | sudo tee /etc/keyd/default.conf >/dev/null
      sudo keyd reload"
  fi

  # ─── No conflicting services ──────────────────────────────────
  check "xkeysnail NOT running" bash -c '! pgrep -x xkeysnail >/dev/null' || {
    repair "Stop and mask xkeysnail" bash -c 'sudo systemctl stop xkeysnail 2>/dev/null; sudo systemctl mask xkeysnail 2>/dev/null; sudo pkill -x xkeysnail 2>/dev/null || true'
  }

  check "kintotray NOT running" bash -c '! pgrep -x kintotray.py >/dev/null && ! pgrep -x kintotray >/dev/null' || {
    repair "Kill kintotray" bash -c 'pkill -f kintotray.py 2>/dev/null || true'
  }

  # ─── No conflicting autostart ─────────────────────────────────
  for entry in xkeysnail.desktop kintotray.desktop; do
    local path="${HOME}/.config/autostart/${entry}"
    check "No ${entry} autostart" test ! -f "$path" || {
      repair "Remove ${entry}" rm -f "$path"
    }
  done

  # ─── Cinnamon bindings match keyd output ───────────────────────
  if [[ -n "${DISPLAY:-}" ]]; then
    local sw
    sw=$(gsettings get org.cinnamon.desktop.keybindings.wm switch-windows 2>/dev/null || echo "")
    if echo "$sw" | grep -q "Alt"; then
      ok "Window switch = Alt+Tab (for Cmd+Tab)"
    else
      fail "Window switch not set to Alt+Tab (current: ${sw})"
      ((ISSUES++))
      repair "Set switch-windows to Alt+Tab" bash -c "
        gsettings set org.cinnamon.desktop.keybindings.wm switch-windows \"['<Alt>Tab']\"
        gsettings set org.cinnamon.desktop.keybindings.wm switch-windows-backward \"['<Alt><Shift>Tab']\""
    fi

    # Ulauncher hotkey
    local ulauncher_conf="${HOME}/.config/ulauncher/settings.json"
    if [[ -f "$ulauncher_conf" ]]; then
      check "Ulauncher hotkey = Super+Space (for Cmd+Space)" \
        bash -c "grep -q '\"<Super>space\"' '$ulauncher_conf'" || {
        repair "Set Ulauncher to Super+Space" \
          bash -c "sed -i 's/\"hotkey-show-app\": \".*\"/\"hotkey-show-app\": \"<Super>space\"/' '$ulauncher_conf'"
      }
    fi
  fi
}

check_touchbar() {
  step "Touch Bar"

  if dpkg -l 2>/dev/null | grep -q tiny-dfr; then
    ok "tiny-dfr installed (full Touch Bar support)"
  else
    warn "tiny-dfr not installed (Touch Bar shows basic Fn keys only)"
    repair "Install tiny-dfr" bash -c 'sudo apt-get install -y tiny-dfr'
  fi
}

check_trackpad() {
  step "Trackpad"

  check "Internal trackpad detected" \
    bash -c 'grep -q "Apple Internal Keyboard / Trackpad" /proc/bus/input/devices' || {
    fail "Internal trackpad not detected — apple-bce issue?"
  }
}

check_touchegg() {
  step "Gestures (Touchegg)"

  check "Touchegg service active" bash -c 'systemctl is-active --quiet touchegg' || {
    repair "Start touchegg" bash -c 'sudo systemctl enable touchegg; sudo systemctl start touchegg'
  }

  check "User in input group" bash -c 'groups | grep -q input' || {
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
  check "Load average: ${load} (${cores} cores)" bash -c "awk 'BEGIN {exit ($load > $cores * 2)}'" || {
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
}

# ═══════════════════════════════════════════════════════════════
# SECURITY CHECKS
# ═══════════════════════════════════════════════════════════════

check_security() {
  step "Security"

  check "Firewall active" bash -c 'sudo ufw status 2>/dev/null | grep -q "active"' || {
    repair "Enable firewall" bash -c 'sudo ufw --force enable'
  }

  local failed_count
  failed_count=$(systemctl --failed --no-legend 2>/dev/null | wc -l)
  if [[ "$failed_count" -gt 0 ]]; then
    warn "  ${failed_count} failed systemd services:"
    systemctl --failed --no-legend | awk '{print "    " $1}'
  else
    ok "No failed systemd services"
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
  check_keyboard_layout
  echo ""
  check_keyd
  echo ""
  check_touchbar
  echo ""
  check_trackpad
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

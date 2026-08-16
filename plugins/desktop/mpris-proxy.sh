#!/bin/bash
# plugin: desktop/mpris-proxy
# description: Bluetooth AVRCP media controls (AirPods next/prev/play via mpris-proxy)
# requires: bluez
# provides: bluetooth-media-keys

source "${LIB_DIR}/common.sh"

AUTOSTART_FILE="${HOME}/.config/autostart/mpris-proxy.desktop"
SERVICE_FILE="${HOME}/.config/systemd/user/mpris-proxy.service"

# ═══════════════════════════════════════════════════════════════
# PLUGIN CONTRACT
# ═══════════════════════════════════════════════════════════════

plugin_check() {
  is_installed mpris-proxy &&
    systemctl --user is-active --quiet mpris-proxy.service 2>/dev/null
}

plugin_install() {
  # ─── Step 1: Ensure bluez is installed (provides mpris-proxy) ──
  if ! is_installed mpris-proxy; then
    step "Installing bluez (provides mpris-proxy)..."
    apt_install bluez
  fi
  ok "mpris-proxy available: $(which mpris-proxy)"

  # ─── Step 2: Create user systemd service ───────────────────────
  step "Creating mpris-proxy user service..."
  mkdir -p "$(dirname "$SERVICE_FILE")"
  cat >"$SERVICE_FILE" <<'UNIT'
[Unit]
Description=MPRIS Proxy — Bluetooth AVRCP to MPRIS bridge
Documentation=man:mpris-proxy(1)
After=bluetooth.target
Wants=bluetooth.target

[Service]
Type=simple
ExecStart=/usr/bin/mpris-proxy
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
UNIT
  ok "Systemd user service created"

  # ─── Step 3: Enable and start ──────────────────────────────────
  step "Enabling mpris-proxy service..."
  systemctl --user daemon-reload
  systemctl --user enable mpris-proxy.service
  systemctl --user start mpris-proxy.service
  ok "mpris-proxy running"

  # ─── Done ──────────────────────────────────────────────────────
  info "AirPods / Bluetooth headphone media controls now work:"
  info "  • Single press = Play/Pause"
  info "  • Double press = Next track"
  info "  • Triple press = Previous track"
  info ""
  info "Requires an MPRIS-compatible player (qmmp with MPRIS plugin, Firefox, etc.)"
}

plugin_verify() {
  local errors=0

  if ! is_installed mpris-proxy; then
    fail "mpris-proxy not found (install bluez)"
    ((errors++))
  fi

  if ! systemctl --user is-active --quiet mpris-proxy.service 2>/dev/null; then
    fail "mpris-proxy service not running"
    ((errors++))
  fi

  # Check if a Bluetooth device is connected with AVRCP
  if ! bluetoothctl info 2>/dev/null | grep -q "A/V Remote Control"; then
    warn "No Bluetooth device with AVRCP currently connected"
  fi

  [[ $errors -eq 0 ]]
}

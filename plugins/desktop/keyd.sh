#!/bin/bash
# plugin: desktop/keyd
# description: Kernel-level Mac-style Cmd↔Ctrl key mapping (replaces Kinto/xkeysnail)
# requires: internet
# provides: macos-keybindings

source "${LIB_DIR}/common.sh"

KEYD_CONF="/etc/keyd/default.conf"
KEYD_SERVICE="keyd"
KINTO_SERVICE="xkeysnail"

plugin_check() {
  # keyd is installed and running
  is_installed keyd && systemctl is-active --quiet "$KEYD_SERVICE" 2>/dev/null
}

plugin_install() {
  require_internet

  # ─── Remove xkeysnail/Kinto if present ──────────────────────────
  if systemctl is-active --quiet "$KINTO_SERVICE" 2>/dev/null; then
    step "Removing xkeysnail/Kinto (replaced by keyd)..."
    sudo systemctl stop "$KINTO_SERVICE" 2>/dev/null || true
    sudo systemctl mask "$KINTO_SERVICE" 2>/dev/null || true
    pkill -f "xkeysnail\|kintotray" 2>/dev/null || true
    ok "xkeysnail disabled"
  fi

  # ─── Install keyd from source ──────────────────────────────────
  step "Building keyd from source..."
  local build_dir="/tmp/keyd-build"
  rm -rf "$build_dir"
  git clone --depth 1 https://github.com/rvaiya/keyd.git "$build_dir"
  cd "$build_dir"
  make -j"$(nproc)"
  sudo make install
  cd - >/dev/null
  rm -rf "$build_dir"
  ok "keyd $(keyd --version 2>&1 | head -1) installed"

  # ─── Write config ──────────────────────────────────────────────
  step "Writing keyd config..."
  sudo mkdir -p /etc/keyd
  sudo tee "$KEYD_CONF" >/dev/null << 'EOF'
# Mac-style keybindings for T2 MacBook
# Managed by: t2-opencare (plugins/desktop/keyd.sh)

[ids]
*

[main]

# Core: Cmd (Meta) ↔ Ctrl swap — makes ⌘ behave as Ctrl
leftmeta = leftcontrol
leftcontrol = leftmeta
rightmeta = rightcontrol
rightcontrol = rightmeta

# Caps Lock → Escape (tap) / Control (hold)
capslock = overload(control, esc)

# Alt+Backspace/Delete = delete word (macOS behavior)
[alt]
backspace = C-backspace
delete = C-delete
EOF
  ok "Config written to ${KEYD_CONF}"

  # ─── Install systemd service ───────────────────────────────────
  step "Enabling keyd service..."
  if [[ ! -f /etc/systemd/system/keyd.service ]] && [[ ! -f /usr/lib/systemd/system/keyd.service ]]; then
    sudo tee /etc/systemd/system/keyd.service >/dev/null << 'EOF'
[Unit]
Description=key remapping daemon

[Service]
Type=simple
ExecStart=/usr/local/bin/keyd

[Install]
WantedBy=multi-user.target
EOF
  fi
  sudo systemctl daemon-reload
  sudo systemctl enable "$KEYD_SERVICE"
  sudo systemctl start "$KEYD_SERVICE"

  # ─── Disable IBus (unnecessary with single layout) ─────────────
  step "Disabling IBus input method (unneeded latency)..."
  pkill -f ibus-daemon 2>/dev/null || true
  im-config -n none 2>/dev/null || true
  mkdir -p "${HOME}/.config/autostart"
  cat > "${HOME}/.config/autostart/ibus-daemon.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=IBus Daemon
Hidden=true
EOF
  ok "IBus disabled"

  ok "keyd installed — ⌘ key now works as Ctrl (zero-latency, kernel-level)"
  info "Config: ${KEYD_CONF}"
  info "Reload after edits: sudo keyd reload"
}

plugin_verify() {
  local errors=0

  # Check 1: keyd binary exists
  if ! is_installed keyd; then
    fail "keyd binary not found"
    ((errors++))
  fi

  # Check 2: service running
  if ! systemctl is-active --quiet "$KEYD_SERVICE" 2>/dev/null; then
    fail "keyd service is not running"
    info "  Try: sudo systemctl restart keyd"
    ((errors++))
  fi

  # Check 3: config exists and has our swap
  if [[ ! -f "$KEYD_CONF" ]]; then
    fail "Config missing: ${KEYD_CONF}"
    ((errors++))
  elif ! grep -q "leftmeta = leftcontrol" "$KEYD_CONF" 2>/dev/null; then
    fail "Config does not contain Meta↔Ctrl swap"
    ((errors++))
  fi

  # Check 4: xkeysnail is NOT running (replaced)
  if pgrep -x xkeysnail &>/dev/null; then
    warn "xkeysnail is still running (should be replaced by keyd)"
    info "  Fix: sudo systemctl stop xkeysnail && sudo systemctl mask xkeysnail"
  fi

  # Check 5: no IBus running
  if pgrep -x ibus-daemon &>/dev/null; then
    warn "IBus is still running (adds input latency)"
    info "  Fix: pkill ibus-daemon && im-config -n none"
  fi

  [[ $errors -eq 0 ]]
}

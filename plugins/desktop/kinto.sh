#!/bin/bash
# plugin: desktop/kinto
# description: [DEPRECATED] macOS-style Cmd↔Ctrl key mapping — use desktop/keyd instead
# requires: internet gui core/keyboard
# provides: macos-keybindings
# deprecated: true
# replaced-by: desktop/keyd
#
# ⚠️  This plugin is DEPRECATED as of ADR-003.
#     It conflicts with keyd and causes the terminal Ctrl shortcuts to break.
#     Use `desktop/keyd` instead — see docs/adr/adr-003-keyboard-mapping-design.md

source "${LIB_DIR}/common.sh"

KINTO_DIR="${HOME}/.config/kinto"
XKEYSNAIL_SERVICE="xkeysnail"

plugin_check() {
  # Kinto is installed and xkeysnail is running
  [[ -d "$KINTO_DIR" ]] &&
    systemctl is-active --quiet "$XKEYSNAIL_SERVICE" 2>/dev/null
}

plugin_install() {
  require_internet

  step "Installing Kinto (macOS-style keybindings)..."

  # Install dependencies
  sudo apt-get install -y xdotool python3-pip git

  # Clone and install kinto
  if [[ -d "$KINTO_DIR" ]]; then
    info "Kinto directory already exists, reinstalling..."
    cd "$KINTO_DIR" || return 1
    git pull 2>/dev/null || true
  else
    git clone https://github.com/rbreaves/kinto.git "$KINTO_DIR"
    cd "$KINTO_DIR" || return 1
  fi

  # Run kinto setup (non-interactive)
  ./setup.py

  # ─── Fix: evdev >= 1.5 renamed .fn to .path ───────────────────
  step "Applying evdev compatibility fix..."
  local xkeysnail_input="/usr/local/lib/python3.12/dist-packages/xkeysnail/input.py"
  if [[ -f "$xkeysnail_input" ]]; then
    if grep -q '\.fn' "$xkeysnail_input" 2>/dev/null; then
      # Replace .fn with .path but NOT inotify.fd (that's a real file descriptor)
      sudo sed -i 's/device\.fn/device.path/g' "$xkeysnail_input"
      ok "Fixed evdev .fn → .path incompatibility"
    fi
  fi

  # ─── Fix: disable Super+Space conflicts ────────────────────────
  step "Disabling conflicting Super+Space shortcuts..."
  gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source "[]" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source-backward "[]" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]" 2>/dev/null || true
  gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]" 2>/dev/null || true

  # ─── Enable and start service ──────────────────────────────────
  step "Starting xkeysnail service..."
  xhost +SI:localuser:root 2>/dev/null || true
  sudo systemctl enable "$XKEYSNAIL_SERVICE"
  sudo systemctl restart "$XKEYSNAIL_SERVICE"

  ok "Kinto installed — Cmd key now works like macOS (copy, paste, undo, tab switch)"
  info "If shortcuts don't work immediately, log out and back in."
}

plugin_verify() {
  local errors=0

  # Check 1: kinto config exists
  if [[ ! -d "$KINTO_DIR" ]]; then
    fail "Kinto config directory missing: $KINTO_DIR"
    ((errors++))
  fi

  # Check 2: xkeysnail service is running
  if ! systemctl is-active --quiet "$XKEYSNAIL_SERVICE" 2>/dev/null; then
    fail "xkeysnail service is not running"
    info "  Try: sudo systemctl restart xkeysnail"
    ((errors++))
  fi

  # Check 3: evdev fix applied (no .fn in xkeysnail source)
  local xkeysnail_input="/usr/local/lib/python3.12/dist-packages/xkeysnail/input.py"
  if [[ -f "$xkeysnail_input" ]] && grep -q 'device\.fn' "$xkeysnail_input" 2>/dev/null; then
    fail "evdev .fn incompatibility not fixed"
    ((errors++))
  fi

  # Check 4: Super+Space conflicts disabled
  local switch_source
  switch_source=$(gsettings get org.cinnamon.desktop.keybindings.wm switch-input-source 2>/dev/null || echo "[]")
  if [[ "$switch_source" != "@as []" && "$switch_source" != "[]" ]]; then
    warn "Super+Space still bound to input-source switch (may conflict with Kinto)"
    info "  Fix: gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source \"[]\""
  fi

  # Check 5: xkeysnail not crashing in logs
  local recent_errors
  recent_errors=$(journalctl -u "$XKEYSNAIL_SERVICE" --since "5 min ago" --no-pager 2>/dev/null |
    grep -c "Error\|AttributeError\|Traceback" || echo "0")
  if [[ "$recent_errors" -gt 0 ]]; then
    fail "xkeysnail has errors in recent logs"
    info "  Check: journalctl -u xkeysnail -f"
    ((errors++))
  fi

  [[ $errors -eq 0 ]]
}

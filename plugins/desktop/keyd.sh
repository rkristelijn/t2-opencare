#!/bin/bash
# plugin: desktop/keyd
# description: macOS-identical keyboard (Cmd=GUI, Ctrl=terminal) via kernel-level keyd
# requires: internet
# provides: macos-keybindings
# see: docs/adr/adr-003-keyboard-mapping-design.md

source "${LIB_DIR}/common.sh"

KEYD_CONF="/etc/keyd/default.conf"
BCORNE_CONF="/etc/keyd/bcorne.conf"
KEYD_SERVICE="keyd"

# ═══════════════════════════════════════════════════════════════
# KEYD CONFIG
# ═══════════════════════════════════════════════════════════════

_keyd_config() {
  cat <<'EOF'
# /etc/keyd/default.conf
# macOS-identical keyboard for T2 MacBook
# Managed by: t2-opencare (plugins/desktop/keyd.sh)
# Design: docs/adr/adr-003-keyboard-mapping-design.md
#
# Principle:
#   ⌘ Cmd  = GUI shortcuts (copy, paste, tab-switch, quit)
#   Ctrl   = terminal control chars (Ctrl+C, Ctrl+A, tmux)
#   Both work independently — just like a real Mac.

[ids]
*
-6401:45d4

[global]
macro_timeout = 200

[main]

# ─── Cmd (Meta) → "smart Ctrl" layer with Mac overrides ────────
leftmeta = layer(meta_mac)
rightmeta = layer(meta_mac)

# ─── Ctrl stays Ctrl (terminal Ctrl+C/A/U/K/D/Z, tmux) ────────
# (default behavior, no mapping needed)

# ─── Caps Lock → Escape (tap) / Control (hold) ─────────────────
capslock = overload(control, esc)

# ─── NL Mac ISO: 102nd key (right of left shift) → grave/tilde ─
102nd = `

# ─── Section key (top-left) → Escape (§/± is useless) ──────────
grave = esc

# ═══════════════════════════════════════════════════════════════
# meta_mac layer: Cmd behaves as Ctrl, with exceptions
# The :C suffix makes all unmapped keys emit Ctrl+key
# ═══════════════════════════════════════════════════════════════
[meta_mac:C]

# App switching: Cmd+Tab → swap to alt_tab layer (holds Alt while tabbing)
tab = swapm(alt_tab, A-tab)

# Reverse app switch: Cmd+` → swap to alt_tab layer with Shift+Alt+Tab
` = swapm(alt_tab, A-S-tab)

# Launcher: Cmd+Space → Super+Space
space = M-space

# Quit app: Cmd+Q → Alt+F4
q = A-f4

# Hide/minimize: Cmd+H → Super+H
h = M-h

# ═══════════════════════════════════════════════════════════════
# Alt (Option) layer: macOS word-level navigation
# ═══════════════════════════════════════════════════════════════
[alt]

# Option+Backspace/Delete = delete word
backspace = C-backspace
delete = C-delete

# Option+Left/Right = jump word
left = C-left
right = C-right

# ═══════════════════════════════════════════════════════════════
# alt_tab layer: keeps Alt held while Cmd is down (for app switcher)
# Entered via swap() from meta_mac — exited when Cmd is released
# ═══════════════════════════════════════════════════════════════
[alt_tab:A]

tab = A-tab
` = A-S-tab
EOF
}

# ═══════════════════════════════════════════════════════════════
# BCORNE SPLIT KEYBOARD CONFIG (DH747, VIAL firmware)
# ═══════════════════════════════════════════════════════════════

_bcorne_config() {
  cat <<'EOF'
# /etc/keyd/bcorne.conf
# DH747 BCORNE split keyboard
# Managed by: t2-opencare (plugins/desktop/keyd.sh)
#
# Fixes:
#   - Media keys: firmware sends fastforward/rewind instead of nextsong/previoussong
#   - Mac-like Cmd behavior (same as internal keyboard)

[ids]
6401:45d4

[main]
# ─── Fix media keys: BCORNE sends KC_MFFD/KC_MRWD not KC_MNXT/KC_MPRV
fastforward = nextsong
rewind = previoussong

# ─── Cmd (Meta) → "smart Ctrl" layer with Mac overrides ───────
leftmeta = layer(meta_bcorne)
rightmeta = layer(meta_bcorne)

[meta_bcorne:C]

# ─── Same Mac overrides as default ────────────────────────────
tab = swapm(alt_tab, A-tab)
` = swapm(alt_tab, A-S-tab)
space = M-space
q = A-f4
h = M-h

[alt]
backspace = C-backspace
delete = C-delete
left = C-left
right = C-right

[alt_tab:A]
tab = A-tab
` = A-S-tab
EOF
}

# ═══════════════════════════════════════════════════════════════
# PLUGIN CONTRACT
# ═══════════════════════════════════════════════════════════════

plugin_check() {
  is_installed keyd &&
    systemctl is-active --quiet "$KEYD_SERVICE" 2>/dev/null &&
    grep -q "meta_mac:C" "$KEYD_CONF" 2>/dev/null &&
    grep -q "fastforward = nextsong" "$BCORNE_CONF" 2>/dev/null
}

plugin_install() {
  require_internet

  # ─── Step 1: Remove conflicting services ───────────────────────
  _cleanup_conflicts

  # ─── Step 2: Install keyd (if not present) ─────────────────────
  if ! is_installed keyd; then
    _install_keyd
  else
    ok "keyd already installed ($(keyd --version 2>&1 | head -1))"
  fi

  # ─── Step 3: Write config ──────────────────────────────────────
  _write_config

  # ─── Step 4: Set Cinnamon keybindings to match ─────────────────
  _set_cinnamon_bindings

  # ─── Step 5: Set Ulauncher hotkey ──────────────────────────────
  _set_ulauncher_hotkey

  # ─── Step 6: Enable and start ──────────────────────────────────
  step "Starting keyd service..."
  sudo systemctl daemon-reload
  sudo systemctl enable "$KEYD_SERVICE"
  sudo systemctl restart "$KEYD_SERVICE"

  ok "keyd installed — Mac keyboard working"
  info "  ⌘+C/V/Z/Tab/Space = GUI shortcuts"
  info "  Ctrl+C/A/U = terminal (unchanged)"
  info "  Config: ${KEYD_CONF}"
  info "  Reload after edits: sudo keyd reload"
}

plugin_verify() {
  local errors=0

  # keyd binary
  if ! is_installed keyd; then
    fail "keyd binary not found"
    ((errors++))
  fi

  # Service running
  if ! systemctl is-active --quiet "$KEYD_SERVICE" 2>/dev/null; then
    fail "keyd service not running"
    ((errors++))
  fi

  # Config has meta_mac layer (not dumb swap)
  if ! grep -q "meta_mac:C" "$KEYD_CONF" 2>/dev/null; then
    fail "keyd config missing meta_mac:C layer"
    ((errors++))
  fi

  # BCORNE config exists with media key fix
  if ! grep -q "fastforward = nextsong" "$BCORNE_CONF" 2>/dev/null; then
    fail "BCORNE config missing media key remap (${BCORNE_CONF})"
    ((errors++))
  fi

  # No conflicting services
  if pgrep -x xkeysnail &>/dev/null; then
    fail "xkeysnail still running (conflicts with keyd)"
    ((errors++))
  fi
  if pgrep -f kintotray &>/dev/null; then
    fail "kintotray still running"
    ((errors++))
  fi

  # Cinnamon window switch = Alt+Tab
  local sw
  sw=$(gsettings get org.cinnamon.desktop.keybindings.wm switch-windows 2>/dev/null || echo "")
  if [[ -n "$sw" ]] && ! echo "$sw" | grep -q "Alt"; then
    fail "Cinnamon switch-windows not set to Alt+Tab"
    ((errors++))
  fi

  [[ $errors -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# INTERNAL FUNCTIONS
# ═══════════════════════════════════════════════════════════════

_install_keyd() {
  step "Building keyd from source..."
  local build_dir="/tmp/keyd-build"
  rm -rf "$build_dir"
  git clone --depth 1 https://github.com/rvaiya/keyd.git "$build_dir"
  cd "$build_dir" || return 1
  make -j"$(nproc)"
  sudo make install
  cd - >/dev/null || true
  rm -rf "$build_dir"

  # Create systemd service if missing
  if [[ ! -f /etc/systemd/system/keyd.service ]] &&
    [[ ! -f /usr/lib/systemd/system/keyd.service ]]; then
    sudo tee /etc/systemd/system/keyd.service >/dev/null <<'UNIT'
[Unit]
Description=key remapping daemon

[Service]
Type=simple
ExecStart=/usr/local/bin/keyd

[Install]
WantedBy=multi-user.target
UNIT
  fi

  ok "keyd $(keyd --version 2>&1 | head -1) installed"
}

_write_config() {
  step "Writing keyd config..."
  sudo mkdir -p /etc/keyd
  _keyd_config | sudo tee "$KEYD_CONF" >/dev/null

  # Validate config
  if keyd check "$KEYD_CONF" 2>/dev/null; then
    ok "Config validated"
  else
    warn "Config validation failed — check: sudo journalctl -eu keyd"
  fi

  # BCORNE split keyboard config
  step "Writing BCORNE keyboard config..."
  _bcorne_config | sudo tee "$BCORNE_CONF" >/dev/null
  ok "BCORNE config: ${BCORNE_CONF}"
}

_set_cinnamon_bindings() {
  step "Setting Cinnamon keybindings..."

  # Window switching → Alt+Tab (keyd sends Alt+Tab for Cmd+Tab)
  gsettings set org.cinnamon.desktop.keybindings.wm switch-windows "['<Alt>Tab']" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm switch-windows-backward "['<Alt><Shift>Tab']" 2>/dev/null || true

  # Close window → Alt+F4 (keyd sends this for Cmd+Q)
  gsettings set org.cinnamon.desktop.keybindings.wm close "['<Alt>F4']" 2>/dev/null || true

  # Disable input-source switch (conflicts with Cmd+Space)
  gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source "[]" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source-backward "[]" 2>/dev/null || true

  # Basic tiling with arrows (Cmd+Alt+Arrow → Ctrl+Alt+Arrow)
  gsettings set org.cinnamon.desktop.keybindings.wm push-tile-left "['<Ctrl><Alt>Left']" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm push-tile-right "['<Ctrl><Alt>Right']" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm push-tile-up "['<Ctrl><Alt>Up']" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm push-tile-down "['<Ctrl><Alt>Down']" 2>/dev/null || true

  # Disable keyboard workspace switching (use touchegg gestures instead)
  gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "[]" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "[]" 2>/dev/null || true

  ok "Cinnamon bindings set"
}

_set_ulauncher_hotkey() {
  local config="${HOME}/.config/ulauncher/settings.json"
  if [[ -f "$config" ]]; then
    step "Setting Ulauncher hotkey to Super+Space..."
    sed -i 's/"hotkey-show-app": ".*"/"hotkey-show-app": "<Super>space"/' "$config"
    # Restart Ulauncher if running
    if pgrep -x ulauncher &>/dev/null; then
      pkill -x ulauncher 2>/dev/null || true
      sleep 1
      nohup ulauncher --hide-window &>/dev/null &
      disown
    fi
    ok "Ulauncher hotkey = Super+Space (⌘+Space)"
  else
    info "Ulauncher not configured — skipping hotkey setup"
  fi
}

_cleanup_conflicts() {
  step "Removing conflicting key remappers..."

  # Stop and mask xkeysnail
  if systemctl is-active --quiet xkeysnail 2>/dev/null ||
    systemctl is-enabled --quiet xkeysnail 2>/dev/null; then
    sudo systemctl stop xkeysnail 2>/dev/null || true
    sudo systemctl mask xkeysnail 2>/dev/null || true
    ok "xkeysnail stopped and masked"
  fi

  # Kill kintotray
  if pgrep -f kintotray &>/dev/null; then
    pkill -f kintotray 2>/dev/null || true
    ok "kintotray killed"
  fi

  # Kill xkeysnail process (if running outside systemd)
  if pgrep -x xkeysnail &>/dev/null; then
    sudo pkill -x xkeysnail 2>/dev/null || true
  fi

  # Remove conflicting autostart entries
  local removed=0
  for entry in xkeysnail.desktop kintotray.desktop keyboard-fix.desktop; do
    if [[ -f "${HOME}/.config/autostart/${entry}" ]]; then
      rm -f "${HOME}/.config/autostart/${entry}"
      ((removed++))
    fi
  done
  [[ $removed -gt 0 ]] && ok "Removed ${removed} conflicting autostart entries"

  # Disable IBus (unneeded latency with single layout)
  if pgrep -x ibus-daemon &>/dev/null; then
    pkill -f ibus-daemon 2>/dev/null || true
    im-config -n none 2>/dev/null || true
  fi
  # Ensure IBus stays dead on next login
  mkdir -p "${HOME}/.config/autostart"
  cat >"${HOME}/.config/autostart/ibus-daemon.desktop" <<'ENTRY'
[Desktop Entry]
Type=Application
Name=IBus Daemon
Hidden=true
ENTRY

  ok "Conflicts cleaned up"
}

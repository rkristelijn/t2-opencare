#!/bin/bash
# plugin: core/keyboard
# description: Base keyboard layout (NL Mac ISO) + hid_apple fnmode
# requires: core/t2-kernel
# provides: keyboard-layout
#
# Note: This sets the BASE layout only. Key remapping (Cmd↔Ctrl, 102nd key)
# is handled by desktop/keyd. This plugin ensures the correct XKB layout
# is active and persistent across reboots/suspend.

source "${LIB_DIR}/common.sh"

# Default layout — override via env or setup.toml
KB_LAYOUT="${KB_LAYOUT:-nl}"
KB_VARIANT="${KB_VARIANT:-mac}"
KB_MODEL="${KB_MODEL:-apple_laptop}"

plugin_check() {
  grep -q "XKBLAYOUT=\"${KB_LAYOUT}\"" /etc/default/keyboard 2>/dev/null &&
    [[ -f /etc/modprobe.d/hid_apple.conf ]]
}

plugin_install() {
  step "Configuring base keyboard layout: ${KB_LAYOUT} (${KB_VARIANT})..."

  # ─── /etc/default/keyboard (system-wide, console + X11) ───────
  step "Writing /etc/default/keyboard..."
  sudo tee /etc/default/keyboard >/dev/null <<EOF
XKBMODEL="${KB_MODEL}"
XKBLAYOUT="${KB_LAYOUT}"
XKBVARIANT="${KB_VARIANT}"
XKBOPTIONS=""
BACKSPACE="guess"
EOF
  sudo setupcon 2>/dev/null || true

  # ─── Cinnamon input-source (prevent layout override to US) ────
  step "Setting Cinnamon input source..."
  gsettings set org.cinnamon.desktop.input-sources sources \
    "[('xkb', '${KB_LAYOUT}+${KB_VARIANT}')]" 2>/dev/null || true

  # ─── hid_apple: fnmode=2 (media keys default, Fn for F1-F12) ──
  step "Configuring hid_apple fnmode..."
  echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf >/dev/null
  # Apply immediately if module is loaded
  if [[ -f /sys/module/hid_apple/parameters/fnmode ]]; then
    echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode >/dev/null
  fi

  # ─── Apply layout now ─────────────────────────────────────────
  if [[ -n "${DISPLAY:-}" ]]; then
    setxkbmap -layout "${KB_LAYOUT}" -variant "${KB_VARIANT}" -model "${KB_MODEL}" 2>/dev/null || true
  fi

  ok "Keyboard layout configured: ${KB_LAYOUT}+${KB_VARIANT} (${KB_MODEL}), fnmode=2"
  info "  Key remapping (Cmd/Ctrl) is handled by: desktop/keyd"
}

plugin_verify() {
  local errors=0

  # /etc/default/keyboard correct
  if ! grep -q "XKBLAYOUT=\"${KB_LAYOUT}\"" /etc/default/keyboard 2>/dev/null; then
    fail "/etc/default/keyboard: layout not set to ${KB_LAYOUT}"
    ((errors++))
  fi

  # Cinnamon not overriding to US
  local sources
  sources=$(gsettings get org.cinnamon.desktop.input-sources sources 2>/dev/null || echo "")
  if [[ -n "$sources" ]] && echo "$sources" | grep -q "'us'" && ! echo "$sources" | grep -q "${KB_LAYOUT}"; then
    fail "Cinnamon input-sources set to US only (will override layout)"
    info "  Fix: gsettings set org.cinnamon.desktop.input-sources sources \"[('xkb', '${KB_LAYOUT}+${KB_VARIANT}')]\""
    ((errors++))
  fi

  # hid_apple configured
  if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
    fail "hid_apple fnmode not configured"
    ((errors++))
  fi

  # Active layout check
  if [[ -n "${DISPLAY:-}" ]]; then
    local current_layout
    current_layout=$(setxkbmap -query 2>/dev/null | awk '/layout/{print $2}' | cut -d, -f1)
    if [[ "$current_layout" != "$KB_LAYOUT" ]]; then
      warn "Active layout is '${current_layout}', expected '${KB_LAYOUT}'"
      info "  Quick fix: setxkbmap -layout ${KB_LAYOUT} -variant ${KB_VARIANT} -model ${KB_MODEL}"
    fi
  fi

  [[ $errors -eq 0 ]]
}

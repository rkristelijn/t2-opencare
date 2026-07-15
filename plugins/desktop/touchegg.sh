#!/bin/bash
# plugin: desktop/touchegg
# description: macOS-like trackpad gestures (3/4 finger swipe, pinch)
# requires: gui
# provides: gestures

source "${LIB_DIR}/common.sh"

plugin_check() {
  systemctl is-active --quiet touchegg 2>/dev/null
}

plugin_install() {
  step "Configuring touchegg gestures..."

  # touchegg is pre-installed on Mint Cinnamon, ensure it's running
  if ! is_installed touchegg; then
    require_root
    require_internet
    sudo apt-get install -y touchegg
  fi

  # Deploy config
  mkdir -p "${HOME}/.config/touchegg"
  cp "${CONFIG_DIR}/touchegg.conf" "${HOME}/.config/touchegg/touchegg.conf"

  # Enable and start
  sudo systemctl enable touchegg
  sudo systemctl start touchegg

  # Ensure user is in input group
  if ! groups | grep -q input; then
    sudo usermod -aG input "$USER"
    warn "Added to 'input' group — logout/login required for gestures to work"
  fi

  ok "Touchegg configured with macOS-like gestures"
}

plugin_verify() {
  systemctl is-active --quiet touchegg 2>/dev/null
}

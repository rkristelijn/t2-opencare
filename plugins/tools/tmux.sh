#!/bin/bash
# plugin: tools/tmux
# description: Terminal multiplexer with sensible macOS-friendly defaults
# requires: internet
# provides: tmux

source "${LIB_DIR}/common.sh"

plugin_check() {
  is_installed tmux && [[ -f "${HOME}/.tmux.conf" ]]
}

plugin_install() {
  require_internet

  step "Installing tmux..."
  if ! is_installed tmux; then
    sudo apt-get install -y tmux
  fi

  # Deploy config
  cp "${CONFIG_DIR}/tmux.conf" "${HOME}/.tmux.conf"

  ok "tmux installed with macOS-friendly keybindings"
}

plugin_verify() {
  is_installed tmux
}

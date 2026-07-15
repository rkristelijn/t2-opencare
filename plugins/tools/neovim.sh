#!/bin/bash
# plugin: tools/neovim
# description: Modern Neovim setup with NvChad
# requires: internet
# provides: neovim

source "${LIB_DIR}/common.sh"

plugin_check() {
  is_installed nvim && [[ -d "${HOME}/.config/nvim" ]]
}

plugin_install() {
  require_internet

  step "Installing Neovim..."
  if ! is_installed nvim; then
    sudo apt-get install -y neovim
  fi

  # Install NvChad if no config exists
  if [[ ! -d "${HOME}/.config/nvim" ]]; then
    step "Installing NvChad..."
    git clone https://github.com/NvChad/starter "${HOME}/.config/nvim"
    info "Launch nvim to complete NvChad setup"
  else
    info "Existing nvim config found — skipping NvChad"
  fi

  ok "Neovim installed"
}

plugin_verify() {
  is_installed nvim
}

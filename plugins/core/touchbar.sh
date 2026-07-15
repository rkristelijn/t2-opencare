#!/bin/bash
# plugin: core/touchbar
# description: Configure Touch Bar with tiny-dfr (function keys + media controls)
# requires: internet core/t2-kernel
# provides: touchbar

source "${LIB_DIR}/common.sh"

plugin_check() {
  dpkg -l | grep -q "tiny-dfr"
}

plugin_install() {
  require_root
  require_internet

  step "Installing tiny-dfr for Touch Bar support..."
  sudo apt-get install -y tiny-dfr

  ok "Touch Bar configured. Shows Fn keys with media controls."
}

plugin_verify() {
  dpkg -l | grep -q "tiny-dfr" && systemctl is-active --quiet tiny-dfr 2>/dev/null
}

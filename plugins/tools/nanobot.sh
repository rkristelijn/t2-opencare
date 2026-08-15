#!/bin/bash
# plugin: tools/nanobot
# description: ROZ NanoBots self-healing daemon (auto-fixes system issues)
# requires: internet
# provides: self-healing

source "${LIB_DIR}/common.sh"

NANOBOT_DIR="/opt/nanobot"
NANOBOT_REPO="https://github.com/rkristelijn/ROZ-nanobots-for-your-pc-.git"

plugin_check() {
  [[ -f "${NANOBOT_DIR}/nanobot.py" ]] &&
    systemctl is-active --quiet nanobot 2>/dev/null
}

plugin_install() {
  require_root
  require_internet

  step "Installing ROZ NanoBots..."

  # Clone or update
  if [[ -d "${NANOBOT_DIR}" ]]; then
    info "Updating existing installation..."
    cd "${NANOBOT_DIR}" || return 1
    git pull 2>/dev/null || true
  else
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone "$NANOBOT_REPO" "$tmp_dir"
    cd "$tmp_dir" || return 1
    sudo ./install.sh
    rm -rf "$tmp_dir"
  fi

  ok "ROZ NanoBots installed and running"
  info "  Status: sudo systemctl status nanobot"
  info "  Logs:   sudo journalctl -u nanobot -f"
  info "  Config: /etc/nanobot/config.json"
}

plugin_verify() {
  local errors=0

  if [[ ! -f "${NANOBOT_DIR}/nanobot.py" ]]; then
    fail "nanobot.py not found in ${NANOBOT_DIR}"
    ((errors++))
  fi

  if ! systemctl is-active --quiet nanobot 2>/dev/null; then
    fail "nanobot service not running"
    ((errors++))
  fi

  [[ $errors -eq 0 ]]
}

#!/bin/bash
# plugin: tools/firefox
# description: Firefox performance tuning (limit CPU/RAM via user.js)
# requires: gui
# provides: firefox-optimized

source "${LIB_DIR}/common.sh"

# Find the active Firefox profile
get_firefox_profile() {
  local profile_dir
  profile_dir=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -name "*.default-release" -type d 2>/dev/null | head -1)
  if [[ -z "$profile_dir" ]]; then
    profile_dir=$(find "${HOME}/.mozilla/firefox" -maxdepth 1 -name "*.default" -type d 2>/dev/null | head -1)
  fi
  echo "$profile_dir"
}

plugin_check() {
  local profile
  profile=$(get_firefox_profile)
  [[ -n "$profile" ]] && [[ -f "${profile}/user.js" ]] && \
    grep -q "t2-opencare" "${profile}/user.js" 2>/dev/null
}

plugin_install() {
  local profile
  profile=$(get_firefox_profile)

  if [[ -z "$profile" ]]; then
    fail "No Firefox profile found. Start Firefox once first."
    return 1
  fi

  step "Deploying Firefox user.js to: ${profile}"

  # Backup existing user.js
  if [[ -f "${profile}/user.js" ]] && ! grep -q "t2-opencare" "${profile}/user.js"; then
    cp "${profile}/user.js" "${profile}/user.js.bak.$(date +%s)"
    info "Existing user.js backed up"
  fi

  cp "${CONFIG_DIR}/firefox/user.js" "${profile}/user.js"

  ok "Firefox user.js deployed"
  info "Changes take effect on next Firefox restart"
  info "Recommended: install 'Auto Tab Discard' extension manually"
  info "  → https://addons.mozilla.org/en-US/firefox/addon/auto-tab-discard/"
}

plugin_verify() {
  local profile
  profile=$(get_firefox_profile)
  [[ -n "$profile" ]] && grep -q "t2-opencare" "${profile}/user.js" 2>/dev/null
}

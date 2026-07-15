#!/bin/bash
# lib/plugin.sh — plugin discovery and execution
# shellcheck source=lib/common.sh

source "${LIB_DIR}/common.sh"

# Discover all available plugins
list_plugins() {
  local layer
  for layer in core desktop tools network skins; do
    if [[ -d "${PLUGIN_DIR}/${layer}" ]]; then
      for plugin in "${PLUGIN_DIR}/${layer}"/*.sh; do
        [[ -f "$plugin" ]] || continue
        local name
        name="${layer}/$(basename "$plugin" .sh)"
        local desc
        desc=$(grep '^# description:' "$plugin" | head -1 | sed 's/^# description: //')
        printf "  %-28s %s\n" "$name" "$desc"
      done
    fi
  done
}

# Run a single plugin (check → install → verify)
run_plugin() {
  local plugin_path="$1"
  local plugin_name
  plugin_name=$(basename "$plugin_path" .sh)
  local layer
  layer=$(basename "$(dirname "$plugin_path")")

  step "${layer}/${plugin_name}"

  # Source the plugin (loads its functions)
  # shellcheck disable=SC1090
  source "$plugin_path"

  # Check if already installed
  if plugin_check 2>/dev/null; then
    ok "Already installed — skipping"
    return 0
  fi

  # Install
  info "Installing..."
  if plugin_install; then
    # Verify
    if plugin_verify 2>/dev/null; then
      ok "Installed and verified ✓"
    else
      warn "Installed but verification failed — may need reboot"
    fi
  else
    fail "Installation failed"
    return 1
  fi
}

# Run all plugins in a layer
run_layer() {
  local layer="$1"
  local plugin
  for plugin in "${PLUGIN_DIR}/${layer}"/*.sh; do
    [[ -f "$plugin" ]] || continue
    run_plugin "$plugin"
  done
}

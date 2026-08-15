#!/bin/bash
# scripts/skin.sh — Live skin switcher for t2-opencare
# Usage:
#   ./scripts/skin.sh macos      Apply macOS skin
#   ./scripts/skin.sh winxp      Apply Windows XP skin
#   ./scripts/skin.sh reset      Remove current skin, restore defaults
#   ./scripts/skin.sh current    Show current active skin
#   ./scripts/skin.sh list       List available skins

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${REPO_DIR}/lib"
PLUGIN_DIR="${REPO_DIR}/plugins"
CONFIG_DIR="${REPO_DIR}/config"
export REPO_DIR LIB_DIR PLUGIN_DIR CONFIG_DIR

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"

usage() {
  echo "Usage: $(basename "$0") <command>"
  echo ""
  echo "Commands:"
  echo "  <skin-name>   Apply a skin (e.g., macos, winxp)"
  echo "  reset          Remove current skin and restore defaults"
  echo "  current        Show which skin is active"
  echo "  list           List available skins"
  echo ""
  echo "Available skins:"
  _list_skins
}

_list_skins() {
  for skin_file in "${PLUGIN_DIR}/skins"/*.sh; do
    [[ -f "$skin_file" ]] || continue
    local name desc
    name=$(basename "$skin_file" .sh)
    desc=$(grep '^# description:' "$skin_file" | head -1 | sed 's/^# description: //')
    printf "  %-12s %s\n" "$name" "$desc"
  done
}

_get_active_skin() {
  if [[ -f "$ACTIVE_SKIN_FILE" ]]; then
    cat "$ACTIVE_SKIN_FILE"
  else
    echo "none"
  fi
}

_set_active_skin() {
  mkdir -p "$SKIN_STATE_DIR"
  echo "$1" >"$ACTIVE_SKIN_FILE"
}

_clear_active_skin() {
  rm -f "$ACTIVE_SKIN_FILE"
}

_load_skin() {
  local name="$1"
  local skin_file="${PLUGIN_DIR}/skins/${name}.sh"

  if [[ ! -f "$skin_file" ]]; then
    fail "Skin not found: ${name}"
    echo ""
    echo "Available skins:"
    _list_skins
    exit 1
  fi

  # Check that this skin supports switching (has skin_apply)
  if ! grep -q '^skin_apply()' "$skin_file"; then
    fail "Skin '${name}' does not support live switching (missing skin_apply function)"
    exit 1
  fi

  # shellcheck source=/dev/null
  source "$skin_file"
}

cmd_apply() {
  local target="$1"
  local current
  current=$(_get_active_skin)

  # If a different skin is active, remove it first
  if [[ "$current" != "none" && "$current" != "$target" ]]; then
    info "Removing current skin: ${current}"
    _load_skin "$current"
    skin_remove
  fi

  # Apply the new skin
  _load_skin "$target"

  # Ensure dependencies are installed
  if declare -f skin_deps_install &>/dev/null; then
    skin_deps_install
  fi

  skin_apply
  _set_active_skin "$target"
}

cmd_reset() {
  local current
  current=$(_get_active_skin)

  if [[ "$current" == "none" ]]; then
    info "No skin active — nothing to reset"
    return
  fi

  _load_skin "$current"
  skin_remove
  _clear_active_skin
}

cmd_current() {
  local current
  current=$(_get_active_skin)
  if [[ "$current" == "none" ]]; then
    echo "No skin active (default Mint theme)"
  else
    echo "Active skin: ${current}"
  fi
}

cmd_list() {
  echo "Available skins:"
  _list_skins
  echo ""
  cmd_current
}

# Main
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case "$1" in
  -h | --help) usage ;;
  reset) cmd_reset ;;
  current) cmd_current ;;
  list) cmd_list ;;
  *)
    cmd_apply "$1"
    ;;
esac

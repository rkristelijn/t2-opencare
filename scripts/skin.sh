#!/bin/bash
# scripts/skin.sh — Live skin switcher for t2-opencare
# Usage:
#   ./scripts/skin.sh macos       Apply macOS skin
#   ./scripts/skin.sh winxp       Apply Windows XP skin
#   ./scripts/skin.sh reset       Remove current skin, restore previous state
#   ./scripts/skin.sh original    Restore to original state (before any skin)
#   ./scripts/skin.sh current     Show current active skin
#   ./scripts/skin.sh list        List available skins
#   ./scripts/skin.sh backups     List all timestamped backups
#   ./scripts/skin.sh restore <timestamp>  Restore specific backup

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB_DIR="${REPO_DIR}/lib"
PLUGIN_DIR="${REPO_DIR}/plugins"
CONFIG_DIR="${REPO_DIR}/config"
export REPO_DIR LIB_DIR PLUGIN_DIR CONFIG_DIR

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"
source "${LIB_DIR}/skin-registry.sh"

usage() {
  echo "Usage: $(basename "$0") <command>"
  echo ""
  echo "Commands:"
  echo "  <skin-name>          Apply a skin (from registry or plugins)"
  echo "  reset                Remove current skin → restore previous state"
  echo "  original             Restore to original state (before any skin)"
  echo "  current              Show which skin is active"
  echo "  list                 List all available skins"
  echo "  info <skin>          Show details about a skin"
  echo "  backups              List all saved state backups"
  echo "  restore <timestamp>  Restore a specific backup"
  echo ""
  echo "Every skin switch creates a timestamped backup."
  echo "You can always roll back with 'restore <timestamp>' or 'original'."
}

_list_skins() {
  # Registry skins (auto-download)
  registry_list
}

_get_active_skin() {
  if [[ -f "$ACTIVE_SKIN_FILE" ]]; then
    cat "$ACTIVE_SKIN_FILE"
  else
    echo "none"
  fi
}

_set_active_skin() {
  mkdir -p "$(dirname "$ACTIVE_SKIN_FILE")"
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
    cmd_reset_quiet
  fi

  # Try registry first
  local reg_name
  reg_name=$(_toml_get "$REGISTRY_FILE" "$target" "name")
  if [[ -n "$reg_name" ]]; then
    registry_apply "$target"
    return $?
  fi

  # Fall back to legacy plugin
  _load_skin "$target"
  skin_save_state
  if declare -f skin_deps_install &>/dev/null; then
    skin_deps_install
  fi
  skin_apply
  _set_active_skin "$target"
  echo ""
  ok "Skin '${target}' applied. Previous state backed up."
  info "  Undo: ./scripts/skin.sh reset"
  info "  Full undo: ./scripts/skin.sh original"
}

cmd_reset_quiet() {
  local current
  current=$(_get_active_skin)
  [[ "$current" == "none" ]] && return

  # Try legacy plugin
  local skin_file="${PLUGIN_DIR}/skins/${current}.sh"
  if [[ -f "$skin_file" ]] && grep -q '^skin_remove()' "$skin_file"; then
    _load_skin "$current"
    skin_remove
  else
    registry_remove
  fi
}

cmd_reset() {
  local current
  current=$(_get_active_skin)

  if [[ "$current" == "none" ]]; then
    info "No skin active — nothing to reset"
    return
  fi

  # Backup before removing
  skin_save_state

  # Try legacy plugin first
  local skin_file="${PLUGIN_DIR}/skins/${current}.sh"
  if [[ -f "$skin_file" ]] && grep -q '^skin_remove()' "$skin_file"; then
    _load_skin "$current"
    skin_remove
  else
    registry_remove
  fi

  _clear_active_skin
  ok "Skin '${current}' removed — previous state restored"
}

cmd_original() {
  local current
  current=$(_get_active_skin)

  # If a skin is active, remove it first
  if [[ "$current" != "none" ]]; then
    skin_save_state
    _load_skin "$current"
    skin_remove
    _clear_active_skin
  fi

  skin_restore_original
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

cmd_backups() {
  skin_list_backups
}

cmd_info() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    fail "Usage: $(basename "$0") info <skin-name>"
    exit 1
  fi
  registry_info "$target"
}

cmd_restore() {
  local target="${1:-}"
  if [[ -z "$target" ]]; then
    fail "Usage: $(basename "$0") restore <timestamp>"
    echo ""
    skin_list_backups
    exit 1
  fi

  skin_restore_backup "$target"
  _clear_active_skin
}

# Main
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case "$1" in
  -h | --help) usage ;;
  reset) cmd_reset ;;
  original) cmd_original ;;
  current) cmd_current ;;
  list) cmd_list ;;
  info)
    shift
    cmd_info "$@"
    ;;
  backups) cmd_backups ;;
  restore)
    shift
    cmd_restore "$@"
    ;;
  *)
    cmd_apply "$1"
    ;;
esac

#!/bin/bash
# t2-opencare — Open source care plan for T2 MacBooks running Linux
# Usage: ./install.sh [options] [plugin...]
#
# Examples:
#   ./install.sh                    # Interactive menu
#   ./install.sh --core             # Install core plugins only
#   ./install.sh --all              # Install everything
#   ./install.sh core/wifi tools/tmux  # Specific plugins
#   ./install.sh --dry-run --all    # Preview what would be installed
#   ./install.sh --list             # List available plugins

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${REPO_DIR}/lib"
PLUGIN_DIR="${REPO_DIR}/plugins"
CONFIG_DIR="${REPO_DIR}/config"
export REPO_DIR LIB_DIR PLUGIN_DIR CONFIG_DIR

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/plugin.sh"

# Defaults
DRY_RUN=false
INTERACTIVE=true
SELECTED_PLUGINS=()

# Banner
banner() {
  echo -e "${BOLD}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║          t2-opencare v0.1.0              ║"
  echo "  ║  Open source care for T2 MacBooks        ║"
  echo "  ║  Your warranty expired. Your laptop didn't. ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
}

usage() {
  echo "Usage: ./install.sh [options] [plugin...]"
  echo ""
  echo "Options:"
  echo "  --core       Install core plugins only (kernel, wifi, audio, keyboard, touchbar)"
  echo "  --desktop    Install core + desktop plugins"
  echo "  --all        Install all plugins"
  echo "  --list       List available plugins"
  echo "  --dry-run    Show what would be installed without doing it"
  echo "  --doctor     Run hardware & config diagnostics"
  echo "  --doctor-fix Run diagnostics with auto-repair"
  echo "  -h, --help   Show this help"
  echo ""
  echo "Examples:"
  echo "  ./install.sh                         # Interactive menu"
  echo "  ./install.sh core/wifi tools/tmux    # Specific plugins"
  echo "  ./install.sh --dry-run --all         # Preview all"
}

# Interactive plugin selector
interactive_menu() {
  echo ""
  step "Available plugins:"
  echo ""
  list_plugins
  echo ""
  echo "Options:"
  echo "  1) Core only (recommended first run)"
  echo "  2) Core + Desktop (daily driver)"
  echo "  3) Everything"
  echo "  4) Pick individual plugins"
  echo "  q) Quit"
  echo ""
  read -rp "Choose [1-4/q]: " choice

  case "$choice" in
    1) run_layer "core" ;;
    2) run_layer "core"; run_layer "desktop" ;;
    3)
      for layer in core desktop tools network skins; do
        run_layer "$layer"
      done
      ;;
    4)
      echo ""
      echo "Enter plugin names separated by spaces (e.g., core/wifi tools/tmux):"
      read -rp "> " -a plugins
      for p in "${plugins[@]}"; do
        local path="${PLUGIN_DIR}/${p}.sh"
        if [[ -f "$path" ]]; then
          run_plugin "$path"
        else
          fail "Plugin not found: $p"
        fi
      done
      ;;
    q|Q) echo "Bye!"; exit 0 ;;
    *) fail "Invalid choice"; exit 1 ;;
  esac
}

# Parse arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --core)
        INTERACTIVE=false
        SELECTED_PLUGINS+=("LAYER:core")
        shift ;;
      --desktop)
        INTERACTIVE=false
        SELECTED_PLUGINS+=("LAYER:core" "LAYER:desktop")
        shift ;;
      --all)
        INTERACTIVE=false
        SELECTED_PLUGINS+=("LAYER:core" "LAYER:desktop" "LAYER:tools" "LAYER:network" "LAYER:skins")
        shift ;;
      --list)
        list_plugins
        exit 0 ;;
      --dry-run)
        DRY_RUN=true
        shift ;;
      --doctor)
        exec bash "${REPO_DIR}/scripts/doctor.sh" "${@:2}"
        ;;
      --doctor-fix)
        exec sudo bash "${REPO_DIR}/scripts/doctor.sh" --fix
        ;;
      -h|--help)
        usage
        exit 0 ;;
      *)
        INTERACTIVE=false
        SELECTED_PLUGINS+=("$1")
        shift ;;
    esac
  done
}

# Main
main() {
  banner
  parse_args "$@"

  # Hardware check
  require_t2

  if [[ "$DRY_RUN" == true ]]; then
    info "DRY RUN — no changes will be made"
    echo ""
  fi

  if [[ "$INTERACTIVE" == true ]]; then
    interactive_menu
  else
    for item in "${SELECTED_PLUGINS[@]}"; do
      if [[ "$item" == LAYER:* ]]; then
        local layer="${item#LAYER:}"
        if [[ "$DRY_RUN" == true ]]; then
          info "Would run layer: $layer"
          for p in "${PLUGIN_DIR}/${layer}"/*.sh; do
            [[ -f "$p" ]] && info "  → $(basename "$p" .sh)"
          done
        else
          run_layer "$layer"
        fi
      else
        local path="${PLUGIN_DIR}/${item}.sh"
        if [[ -f "$path" ]]; then
          if [[ "$DRY_RUN" == true ]]; then
            info "Would install: $item"
          else
            run_plugin "$path"
          fi
        else
          fail "Plugin not found: $item"
        fi
      fi
    done
  fi

  echo ""
  ok "Done! You may need to reboot for kernel/driver changes to take effect."
}

main "$@"

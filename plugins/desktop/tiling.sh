#!/bin/bash
# plugin: desktop/tiling
# description: Custom window tiling bindings (⅓, ½, ¼, ⅙ splits + layouts)
# requires: desktop/keyd gui
# provides: window-tiling
# optional: true
#
# Keybindings (all use ⌘+Alt / ⌘+Alt+Shift physically):
#   ⌘+Alt+H/J/K       = ⅓ left/center/right
#   ⌘+Alt+Arrows      = ½ tiles (push-tile)
#   ⌘+Alt+Shift+H/J/K/L = ½ left/bottom/top/right (vim-style)
#   ⌘+Alt+Y/U/I       = ⅙ top-left/center/right
#   ⌘+Alt+N/M/,       = ⅙ bottom-left/center/right
#   ⌘+Alt+1-6         = Quick layouts
#   ⌘+Alt+Enter       = Full screen tile
#   ⌘+Alt+/           = Show keybindings help

source "${LIB_DIR}/common.sh"

TILE_SCRIPT="${HOME}/.local/share/keybindings/tile.sh"
HELP_SCRIPT="${HOME}/.local/share/keybindings/show-keybindings.sh"

plugin_check() {
  [[ -x "$TILE_SCRIPT" ]] && \
    dconf read /org/cinnamon/desktop/keybindings/custom-list 2>/dev/null | grep -q "custom"
}

plugin_install() {
  step "Installing tiling keybindings..."

  # Ensure tile.sh script exists
  if [[ ! -x "$TILE_SCRIPT" ]]; then
    fail "tile.sh not found at ${TILE_SCRIPT}"
    info "  Install from: config/keybindings/tile.sh"
    return 1
  fi

  # ─── Set custom keybindings via dconf ──────────────────────────
  # All use <Ctrl><Alt> which maps to physical ⌘+Alt (via keyd meta_mac:C layer)

  step "Setting Cinnamon custom keybindings..."

  local -a bindings=()
  local idx=0

  # Helper to add a binding
  _add() {
    local name="$1" binding="$2" command="$3"
    local path="/org/cinnamon/desktop/keybindings/custom-keybindings/custom${idx}/"
    dconf write "${path}name" "'${name}'"
    dconf write "${path}binding" "['${binding}']"
    dconf write "${path}command" "'${command}'"
    bindings+=("'/org/cinnamon/desktop/keybindings/custom-keybindings/custom${idx}/'")
    ((idx++))
  }

  # ─── App launchers ────────────────────────────────────────────
  _add "Terminal (tmux)"     "<Ctrl><Alt>t"       "gnome-terminal -- tmux new-session"
  _add "Browser"             "<Ctrl><Alt>b"       "xdg-open http://"
  _add "VS Code"             "<Ctrl><Alt>c"       "code"
  _add "Text Editor"         "<Ctrl><Alt>e"       "xed"
  _add "File Manager"        "<Ctrl><Alt>f"       "nemo"
  _add "Calculator"          "<Ctrl><Alt>r"       "gnome-calculator"
  _add "Screenshot (area)"   "<Ctrl><Alt>s"       "gnome-screenshot -a"
  _add "Calendar"            "<Ctrl><Alt>d"       "gnome-calendar"
  _add "Email"               "<Ctrl><Alt>g"       "thunderbird"
  _add "Media Player"        "<Ctrl><Alt>v"       "celluloid"
  _add "Settings"            "<Ctrl><Alt>x"       "cinnamon-settings"

  # ─── ⅓ tiles (Ctrl+Alt+H/J/K) ────────────────────────────────
  _add "⅓ Left"              "<Ctrl><Alt>h"       "${TILE_SCRIPT} third-left"
  _add "⅓ Center"           "<Ctrl><Alt>j"       "${TILE_SCRIPT} third-center"
  _add "⅓ Right"            "<Ctrl><Alt>k"       "${TILE_SCRIPT} third-right"

  # ─── ½ tiles vim-style (Ctrl+Alt+Shift+H/J/K/L) ──────────────
  _add "½ Left"              "<Ctrl><Alt><Shift>h" "${TILE_SCRIPT} half-left"
  _add "½ Bottom"           "<Ctrl><Alt><Shift>j" "${TILE_SCRIPT} half-bottom"
  _add "½ Top"              "<Ctrl><Alt><Shift>k" "${TILE_SCRIPT} half-top"
  _add "½ Right"            "<Ctrl><Alt><Shift>l" "${TILE_SCRIPT} half-right"

  # ─── ¼ tiles (Ctrl+Alt+Shift+Y/O/N/.) ────────────────────────
  _add "¼ Top-Left"          "<Ctrl><Alt><Shift>y"      "${TILE_SCRIPT} quarter-topleft"
  _add "¼ Top-Right"        "<Ctrl><Alt><Shift>o"      "${TILE_SCRIPT} quarter-topright"
  _add "¼ Bottom-Left"      "<Ctrl><Alt><Shift>n"      "${TILE_SCRIPT} quarter-bottomleft"
  _add "¼ Bottom-Right"     "<Ctrl><Alt><Shift>period" "${TILE_SCRIPT} quarter-bottomright"

  # ─── ⅙ tiles (Ctrl+Alt+Y/U/I top, N/M/, bottom) ─────────────
  _add "⅙ Top-Left"          "<Ctrl><Alt>y"       "${TILE_SCRIPT} sixth-topleft"
  _add "⅙ Top-Center"       "<Ctrl><Alt>u"       "${TILE_SCRIPT} sixth-topcenter"
  _add "⅙ Top-Right"        "<Ctrl><Alt>i"       "${TILE_SCRIPT} sixth-topright"
  _add "⅙ Bottom-Left"      "<Ctrl><Alt>n"       "${TILE_SCRIPT} sixth-bottomleft"
  _add "⅙ Bottom-Center"   "<Ctrl><Alt>m"       "${TILE_SCRIPT} sixth-bottomcenter"
  _add "⅙ Bottom-Right"    "<Ctrl><Alt>comma"   "${TILE_SCRIPT} sixth-bottomright"

  # ─── Full + Layouts ───────────────────────────────────────────
  _add "Full Screen"         "<Ctrl><Alt>Return"  "${TILE_SCRIPT} full"
  _add "Layout: Stacked"    "<Ctrl><Alt>1"       "${TILE_SCRIPT} layout-1"
  _add "Layout: Halves"     "<Ctrl><Alt>2"       "${TILE_SCRIPT} layout-2"
  _add "Layout: Thirds"     "<Ctrl><Alt>3"       "${TILE_SCRIPT} layout-3"
  _add "Layout: Quarters"   "<Ctrl><Alt>4"       "${TILE_SCRIPT} layout-4"
  _add "Layout: Quads+1"    "<Ctrl><Alt>5"       "${TILE_SCRIPT} layout-5"
  _add "Layout: Sixths"     "<Ctrl><Alt>6"       "${TILE_SCRIPT} layout-6"

  # ─── Monitor move (Ctrl+Alt+Super) ───────────────────────────
  _add "Move to Prev Monitor" "<Ctrl><Alt><Super>h" "${TILE_SCRIPT} monitor-prev"
  _add "Move to Next Monitor" "<Ctrl><Alt><Super>l" "${TILE_SCRIPT} monitor-next"

  # ─── Help ─────────────────────────────────────────────────────
  _add "Show Keybindings"    "<Ctrl><Alt>slash"   "${HELP_SCRIPT}"

  # Write the custom-list
  local list
  list=$(printf ",%s" "${bindings[@]}")
  list="[${list:1}]"
  dconf write /org/cinnamon/desktop/keybindings/custom-list "${list}"

  ok "Tiling keybindings installed (${idx} bindings)"
  info "  Physical: ⌘+Alt+key (keyd translates to Ctrl+Alt+key)"
  info "  Help: ⌘+Alt+/"
}

plugin_verify() {
  local errors=0

  if [[ ! -x "$TILE_SCRIPT" ]]; then
    fail "tile.sh not found or not executable: ${TILE_SCRIPT}"
    ((errors++))
  fi

  local custom_list
  custom_list=$(dconf read /org/cinnamon/desktop/keybindings/custom-list 2>/dev/null || echo "")
  if [[ -z "$custom_list" ]] || [[ "$custom_list" == "@as []" ]]; then
    fail "No custom keybindings set in Cinnamon"
    ((errors++))
  fi

  [[ $errors -eq 0 ]]
}

#!/bin/bash
# lib/skin.sh — shared skin switching utilities
# Provides state save/restore for all skins
# shellcheck source=lib/common.sh

source "${LIB_DIR}/common.sh"

SKIN_STATE_DIR="${HOME}/.config/t2-opencare"
SKIN_STATE_FILE="${SKIN_STATE_DIR}/skin-state-before.conf"
export ACTIVE_SKIN_FILE="${SKIN_STATE_DIR}/active-skin"

# Save current desktop state before applying a skin
skin_save_state() {
  mkdir -p "$SKIN_STATE_DIR"

  # Don't overwrite if already saved (prevents losing original state on double-apply)
  if [[ -f "$SKIN_STATE_FILE" ]]; then
    info "State already saved — keeping original"
    return
  fi

  cat >"$SKIN_STATE_FILE" <<EOF
PREV_CINNAMON_THEME=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
PREV_GTK_THEME=$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
PREV_ICON_THEME=$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null | tr -d "'")
PREV_BUTTON_LAYOUT=$(gsettings get org.cinnamon.desktop.wm.preferences button-layout 2>/dev/null | tr -d "'")
PREV_WALLPAPER=$(gsettings get org.cinnamon.desktop.background picture-uri 2>/dev/null | tr -d "'")
PREV_PANELS=$(gsettings get org.cinnamon panels-enabled 2>/dev/null)
PREV_CURSOR=$(gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null | tr -d "'")
EOF
  info "Desktop state saved"
}

# Restore desktop state to what it was before any skin was applied
skin_restore_state() {
  if [[ ! -f "$SKIN_STATE_FILE" ]]; then
    warn "No saved state found — applying Mint defaults"
    gsettings set org.cinnamon.theme name "Mint-Y-Dark"
    gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark"
    gsettings set org.cinnamon.desktop.interface icon-theme "Mint-Y-Dark"
    gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close"
    gsettings set org.cinnamon panels-enabled "['1:0:bottom']" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface cursor-theme "DMZ-Black" 2>/dev/null || true
    return
  fi

  # shellcheck source=/dev/null
  source "$SKIN_STATE_FILE"

  gsettings set org.cinnamon.theme name "${PREV_CINNAMON_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.interface gtk-theme "${PREV_GTK_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.interface icon-theme "${PREV_ICON_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.wm.preferences button-layout "${PREV_BUTTON_LAYOUT:-:minimize,maximize,close}"
  gsettings set org.cinnamon.desktop.background picture-uri "${PREV_WALLPAPER:-}"
  gsettings set org.cinnamon panels-enabled "${PREV_PANELS:-['1:0:bottom']}" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.interface cursor-theme "${PREV_CURSOR:-DMZ-Black}" 2>/dev/null || true

  rm -f "$SKIN_STATE_FILE"
  info "Desktop state restored"
}

# Helper: set wallpaper if file exists
skin_set_wallpaper() {
  local wallpaper="$1"
  if [[ -f "$wallpaper" ]]; then
    gsettings set org.cinnamon.desktop.background picture-uri "file://${wallpaper}"
    gsettings set org.cinnamon.desktop.background picture-options "zoom"
  else
    warn "Wallpaper not found: ${wallpaper}"
  fi
}

# Helper: set Cinnamon theme + GTK + icons in one call
skin_set_theme() {
  local cinnamon_theme="${1:-}"
  local gtk_theme="${2:-$cinnamon_theme}"
  local icon_theme="${3:-$gtk_theme}"

  [[ -n "$cinnamon_theme" ]] && gsettings set org.cinnamon.theme name "$cinnamon_theme"
  [[ -n "$gtk_theme" ]] && gsettings set org.cinnamon.desktop.interface gtk-theme "$gtk_theme"
  [[ -n "$icon_theme" ]] && gsettings set org.cinnamon.desktop.interface icon-theme "$icon_theme"
}

# Helper: set window button layout
skin_set_buttons() {
  local layout="$1" # "left" or "right"
  case "$layout" in
    left) gsettings set org.cinnamon.desktop.wm.preferences button-layout "close,minimize,maximize:" ;;
    right) gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close" ;;
    *) gsettings set org.cinnamon.desktop.wm.preferences button-layout "$layout" ;;
  esac
}

# Helper: set panel position
skin_set_panel() {
  local position="$1" # "top" or "bottom"
  gsettings set org.cinnamon panels-enabled "['1:0:${position}']" 2>/dev/null || true
}

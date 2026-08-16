#!/bin/bash
# lib/skin.sh — shared skin switching utilities
# Provides timestamped state backup/restore for all skins
# shellcheck source=lib/common.sh

source "${LIB_DIR}/common.sh"

SKIN_STATE_DIR="${HOME}/.config/t2-opencare/skin-backups"
export ACTIVE_SKIN_FILE="${HOME}/.config/t2-opencare/active-skin"
SKIN_ORIGINAL_FILE="${HOME}/.config/t2-opencare/skin-original.conf"

# ═══════════════════════════════════════════════════════════════
# BACKUP / RESTORE
# ═══════════════════════════════════════════════════════════════

# Capture current desktop state into a file
_capture_state() {
  local output="$1"
  cat >"$output" <<EOF
# Captured: $(date -Iseconds)
CINNAMON_THEME="$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")"
GTK_THEME="$(gsettings get org.cinnamon.desktop.interface gtk-theme 2>/dev/null | tr -d "'")"
ICON_THEME="$(gsettings get org.cinnamon.desktop.interface icon-theme 2>/dev/null | tr -d "'")"
CURSOR_THEME="$(gsettings get org.cinnamon.desktop.interface cursor-theme 2>/dev/null | tr -d "'")"
BUTTON_LAYOUT="$(gsettings get org.cinnamon.desktop.wm.preferences button-layout 2>/dev/null | tr -d "'")"
WM_THEME="$(gsettings get org.cinnamon.desktop.wm.preferences theme 2>/dev/null | tr -d "'")"
WALLPAPER="$(gsettings get org.cinnamon.desktop.background picture-uri 2>/dev/null | tr -d "'")"
WALLPAPER_MODE="$(gsettings get org.cinnamon.desktop.background picture-options 2>/dev/null | tr -d "'")"
PANELS="$(gsettings get org.cinnamon panels-enabled 2>/dev/null)"
FONT="$(gsettings get org.cinnamon.desktop.interface font-name 2>/dev/null | tr -d "'")"
EOF
}

# Apply a state file to the desktop
_apply_state() {
  local state_file="$1"
  if [[ ! -f "$state_file" ]]; then
    fail "State file not found: $state_file"
    return 1
  fi

  # shellcheck source=/dev/null
  source "$state_file"

  gsettings set org.cinnamon.theme name "${CINNAMON_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.interface gtk-theme "${GTK_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.interface icon-theme "${ICON_THEME:-Mint-Y-Dark}"
  gsettings set org.cinnamon.desktop.interface cursor-theme "${CURSOR_THEME:-DMZ-Black}" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.wm.preferences button-layout "${BUTTON_LAYOUT:-:minimize,maximize,close}"
  gsettings set org.cinnamon.desktop.wm.preferences theme "${WM_THEME:-${GTK_THEME:-Mint-Y-Dark}}"
  [[ -n "${WALLPAPER:-}" ]] && gsettings set org.cinnamon.desktop.background picture-uri "$WALLPAPER"
  [[ -n "${WALLPAPER_MODE:-}" ]] && gsettings set org.cinnamon.desktop.background picture-options "$WALLPAPER_MODE"
  gsettings set org.cinnamon panels-enabled "${PANELS:-['1:0:bottom']}" 2>/dev/null || true
  [[ -n "${FONT:-}" ]] && gsettings set org.cinnamon.desktop.interface font-name "$FONT" 2>/dev/null || true
}

# Save current state BEFORE applying a skin (timestamped backup)
skin_save_state() {
  mkdir -p "$SKIN_STATE_DIR"

  # Always save a timestamped backup
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_file="${SKIN_STATE_DIR}/${timestamp}.conf"
  _capture_state "$backup_file"
  info "State backed up: ${backup_file}"

  # Save original state only once (the very first time, before any skin)
  if [[ ! -f "$SKIN_ORIGINAL_FILE" ]]; then
    cp "$backup_file" "$SKIN_ORIGINAL_FILE"
    info "Original state saved (first run)"
  fi
}

# Restore to the previous state (most recent backup)
skin_restore_state() {
  local latest
  latest=$(find "$SKIN_STATE_DIR" -name "*.conf" -type f 2>/dev/null | sort -r | head -1)

  if [[ -z "$latest" ]]; then
    warn "No backups found — applying Mint defaults"
    _apply_defaults
    return
  fi

  info "Restoring from: $(basename "$latest")"
  _apply_state "$latest"
  ok "Desktop state restored"
}

# Restore to the original state (before any skin was ever applied)
skin_restore_original() {
  if [[ -f "$SKIN_ORIGINAL_FILE" ]]; then
    info "Restoring original state (before any skin)"
    _apply_state "$SKIN_ORIGINAL_FILE"
    ok "Original desktop state restored"
  else
    warn "No original state saved — applying Mint defaults"
    _apply_defaults
  fi
}

# List all available backups
skin_list_backups() {
  if [[ ! -d "$SKIN_STATE_DIR" ]]; then
    info "No backups yet"
    return
  fi

  local count
  count=$(find "$SKIN_STATE_DIR" -name "*.conf" -type f 2>/dev/null | wc -l)
  echo "Available backups (${count}):"
  find "$SKIN_STATE_DIR" -name "*.conf" -type f 2>/dev/null | sort -r | while read -r f; do
    local name skin_at
    name=$(basename "$f" .conf)
    skin_at=$(head -1 "$f" | sed 's/# Captured: //')
    printf "  %-20s  %s\n" "$name" "$skin_at"
  done

  if [[ -f "$SKIN_ORIGINAL_FILE" ]]; then
    echo ""
    echo "Original state: $(head -1 "$SKIN_ORIGINAL_FILE" | sed 's/# Captured: //')"
  fi
}

# Restore a specific backup by timestamp
skin_restore_backup() {
  local target="$1"
  local file="${SKIN_STATE_DIR}/${target}.conf"

  if [[ ! -f "$file" ]]; then
    fail "Backup not found: $target"
    echo "Available:"
    skin_list_backups
    return 1
  fi

  # Backup current state before restoring (so we can undo the undo)
  skin_save_state

  info "Restoring backup: $target"
  _apply_state "$file"
  ok "Restored from $target"
}

# Apply Mint defaults as fallback
_apply_defaults() {
  gsettings set org.cinnamon.theme name "Mint-Y-Dark"
  gsettings set org.cinnamon.desktop.interface gtk-theme "Mint-Y-Dark"
  gsettings set org.cinnamon.desktop.interface icon-theme "Mint-Y-Dark"
  gsettings set org.cinnamon.desktop.interface cursor-theme "DMZ-Black" 2>/dev/null || true
  gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close"
  gsettings set org.cinnamon panels-enabled "['1:0:bottom']" 2>/dev/null || true

  # Set a random default Mint wallpaper to force theme repaint
  local wallpaper_dir="/usr/share/backgrounds/linuxmint"
  if [[ -d "$wallpaper_dir" ]]; then
    local wp
    wp=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" \) 2>/dev/null | shuf -n1)
    if [[ -n "$wp" ]]; then
      gsettings set org.cinnamon.desktop.background picture-uri "file://${wp}"
      gsettings set org.cinnamon.desktop.background picture-options "zoom"
    fi
  fi
}

# ═══════════════════════════════════════════════════════════════
# SKIN HELPERS (used by skin plugins)
# ═══════════════════════════════════════════════════════════════

# Set wallpaper if file exists
skin_set_wallpaper() {
  local wallpaper="$1"
  if [[ -f "$wallpaper" ]]; then
    gsettings set org.cinnamon.desktop.background picture-uri "file://${wallpaper}"
    gsettings set org.cinnamon.desktop.background picture-options "zoom"
  else
    warn "Wallpaper not found: ${wallpaper}"
  fi
}

# Set Cinnamon theme + GTK + icons + WM in one call
skin_set_theme() {
  local cinnamon_theme="${1:-}"
  local gtk_theme="${2:-$cinnamon_theme}"
  local icon_theme="${3:-$gtk_theme}"

  [[ -n "$cinnamon_theme" ]] && gsettings set org.cinnamon.theme name "$cinnamon_theme"
  [[ -n "$gtk_theme" ]] && gsettings set org.cinnamon.desktop.interface gtk-theme "$gtk_theme"
  [[ -n "$gtk_theme" ]] && gsettings set org.cinnamon.desktop.wm.preferences theme "$gtk_theme"
  [[ -n "$icon_theme" ]] && gsettings set org.cinnamon.desktop.interface icon-theme "$icon_theme"
}

# Set window button layout
skin_set_buttons() {
  local layout="$1" # "left" or "right"
  case "$layout" in
    left) gsettings set org.cinnamon.desktop.wm.preferences button-layout "close,minimize,maximize:" ;;
    right) gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close" ;;
    *) gsettings set org.cinnamon.desktop.wm.preferences button-layout "$layout" ;;
  esac
}

# Set panel position
skin_set_panel() {
  local position="$1" # "top" or "bottom"
  gsettings set org.cinnamon panels-enabled "['1:0:${position}']" 2>/dev/null || true
}

# Set font
skin_set_font() {
  local font="$1" # e.g. "Tahoma 11" or "SF Pro Display 10"
  gsettings set org.cinnamon.desktop.interface font-name "$font" 2>/dev/null || true
}

#!/bin/bash
# plugin: skins/macos
# description: macOS Monterey skin (WhiteSur theme, Plank dock, top panel)
# requires: gui
# provides: macos-theme

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"

# -- Standard plugin contract --

plugin_check() {
  local current_theme
  current_theme=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
  [[ "$current_theme" == "WhiteSur-Dark" ]]
}

plugin_install() {
  require_internet
  skin_deps_install
  skin_apply
}

plugin_verify() {
  plugin_check
}

# -- Skin switching contract --

skin_deps_install() {
  step "Installing macOS skin dependencies..."

  # Plank dock
  if ! is_installed plank; then
    info "Installing Plank dock..."
    apt_install plank
  fi

  # WhiteSur GTK theme
  local theme_dir="${HOME}/.themes/WhiteSur-Dark"
  if [[ ! -d "$theme_dir" ]]; then
    info "Installing WhiteSur GTK theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$tmp_dir"
    bash "$tmp_dir/install.sh" -c Dark -l
    rm -rf "$tmp_dir"
  fi

  # WhiteSur icon theme
  local icon_dir="${HOME}/.icons/WhiteSur-dark"
  if [[ ! -d "$icon_dir" ]]; then
    info "Installing WhiteSur icon theme..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$tmp_dir"
    bash "$tmp_dir/install.sh" -t default
    rm -rf "$tmp_dir"
  fi

  ok "macOS skin dependencies installed"
}

skin_apply() {
  step "Applying macOS skin..."
  skin_save_state

  skin_set_theme "WhiteSur-Dark" "WhiteSur-Dark" "WhiteSur-dark"
  skin_set_buttons "left"
  skin_set_wallpaper "${CONFIG_DIR}/skins/macos/monterey.jpg"
  skin_set_panel "top"

  # Start Plank dock
  if is_installed plank && ! pgrep -x plank >/dev/null; then
    nohup plank &>/dev/null &
    disown
  fi

  gsettings set org.cinnamon.desktop.interface cursor-theme "DMZ-White" 2>/dev/null || true

  ok "macOS skin applied ✓"
}

skin_remove() {
  step "Removing macOS skin..."
  skin_restore_state

  # Stop Plank
  if pgrep -x plank >/dev/null; then
    killall plank 2>/dev/null || true
  fi

  ok "macOS skin removed ✓"
}

#!/bin/bash
# plugin: skins/winxp
# description: Windows XP nostalgic skin (Luna theme, Bliss wallpaper, startup sound)
# requires: gui
# provides: winxp-theme

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"

# -- Standard plugin contract --

plugin_check() {
  local current_theme
  current_theme=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
  [[ "$current_theme" == "Mint-XP" ]]
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
  step "Installing Windows XP skin dependencies..."

  local theme_dir="${HOME}/.themes/Mint-XP"
  if [[ ! -d "$theme_dir" ]]; then
    warn "Manual step: Install 'Mint-XP' from System Settings → Themes → Add/Remove"
  fi

  ok "Windows XP skin dependencies checked"
}

skin_apply() {
  step "Applying Windows XP skin..."
  skin_save_state

  skin_set_theme "Mint-XP" "Mint-XP" "Mint-XP"
  skin_set_buttons "right"
  skin_set_wallpaper "${CONFIG_DIR}/skins/winxp/bliss.jpg"
  skin_set_panel "bottom"

  # Startup sound
  mkdir -p "${HOME}/.config/autostart"
  local sound_file="${CONFIG_DIR}/skins/winxp/windows-xp-startup.mp3"
  if [[ -f "$sound_file" ]]; then
    cat >"${HOME}/.config/autostart/winxp-startup-sound.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=WinXP Startup Sound
Exec=paplay ${sound_file}
X-GNOME-Autostart-enabled=true
EOF
  fi

  ok "Windows XP skin applied ✓"
}

skin_remove() {
  step "Removing Windows XP skin..."
  skin_restore_state

  rm -f "${HOME}/.config/autostart/winxp-startup-sound.desktop"

  ok "Windows XP skin removed ✓"
}

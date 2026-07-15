#!/bin/bash
# plugin: skins/winxp
# description: Windows XP nostalgic skin (theme, icons, wallpaper, startup sound)
# requires: gui
# provides: winxp-theme

source "${LIB_DIR}/common.sh"

plugin_check() {
  local current_theme
  current_theme=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
  [[ "$current_theme" == "Mint-XP" ]]
}

plugin_install() {
  require_internet

  step "Installing Windows XP skin..."

  # Install theme dependencies
  local theme_dir="${HOME}/.themes/Mint-XP"

  # Download Mint-XP theme if not present
  if [[ ! -d "$theme_dir" ]]; then
    info "Download Mint-XP theme from Cinnamon Spices..."
    warn "Manual step: Install 'Mint-XP' from System Settings → Themes → Add/Remove"
  fi

  # Set wallpaper
  if [[ -f "${CONFIG_DIR}/skins/winxp/bliss.jpg" ]]; then
    gsettings set org.cinnamon.desktop.background picture-uri \
      "file://${CONFIG_DIR}/skins/winxp/bliss.jpg"
  fi

  # Startup sound
  mkdir -p "${HOME}/.config/autostart"
  cat > "${HOME}/.config/autostart/startup-sound.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Startup Sound
Exec=paplay ${CONFIG_DIR}/skins/winxp/windows-xp-startup.mp3
X-GNOME-Autostart-enabled=true
EOF

  ok "Windows XP skin applied (some manual steps may be needed)"
}

plugin_verify() {
  [[ -f "${HOME}/.config/autostart/startup-sound.desktop" ]]
}

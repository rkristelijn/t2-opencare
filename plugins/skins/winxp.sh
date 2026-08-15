#!/bin/bash
# plugin: skins/winxp
# description: Windows XP nostalgic skin (Luna theme, Bliss wallpaper, startup sound)
# requires: gui
# provides: winxp-theme
# optional: true

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"

THEME_NAME="Mint-XP"
THEME_DIR="${HOME}/.themes/${THEME_NAME}"
THEME_URL="https://cinnamon-spices.linuxmint.com/files/themes/Mint-XP.zip"

ICONS_NAME="Chicago95"
ICONS_DIR="${HOME}/.icons/${ICONS_NAME}"
ICONS_URL="https://github.com/grassmunk/Chicago95/archive/refs/heads/master.zip"

WALLPAPER_PATH="${HOME}/.local/share/backgrounds/bliss.jpg"
# Try local copy first (from old linux-intel-macbook repo or bundled)
LOCAL_WALLPAPER_CANDIDATES=(
  "${CONFIG_DIR}/skins/winxp/bliss.jpg"
  "${HOME}/git/hub/linux-intel-macbook/skins/winxp/windows_xp_original-wallpaper-2560x1600.jpg"
)

STARTUP_SOUND_CANDIDATES=(
  "${CONFIG_DIR}/skins/winxp/windows-xp-startup.mp3"
  "${HOME}/git/hub/linux-intel-macbook/skins/winxp/windows-xp-startup.mp3"
)

# -- Standard plugin contract --

plugin_check() {
  local current_theme
  current_theme=$(gsettings get org.cinnamon.theme name 2>/dev/null | tr -d "'")
  [[ "$current_theme" == "$THEME_NAME" ]]
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

  # Mint-XP GTK/Cinnamon theme
  if [[ ! -d "$THEME_DIR" ]]; then
    info "Downloading Mint-XP theme..."
    wget -q "$THEME_URL" -O /tmp/Mint-XP.zip || {
      fail "Theme download failed"
      return 1
    }
    mkdir -p "${HOME}/.themes"
    unzip -qo /tmp/Mint-XP.zip -d "${HOME}/.themes/"
    rm -f /tmp/Mint-XP.zip
    ok "Mint-XP theme installed"
  else
    ok "Mint-XP theme already installed"
  fi

  # Chicago95 icon theme (Windows 95/XP style icons)
  if [[ ! -d "$ICONS_DIR" ]]; then
    info "Downloading Chicago95 icons..."
    wget -q "$ICONS_URL" -O /tmp/chicago95.zip || {
      fail "Icons download failed"
      return 1
    }
    mkdir -p "${HOME}/.icons"
    unzip -qo /tmp/chicago95.zip 'Chicago95-master/Icons/Chicago95/*' -d /tmp/chicago95/
    mv /tmp/chicago95/Chicago95-master/Icons/Chicago95 "$ICONS_DIR"
    rm -rf /tmp/chicago95.zip /tmp/chicago95
    ok "Chicago95 icons installed"
  else
    ok "Chicago95 icons already installed"
  fi

  # Wallpaper (Bliss)
  if [[ ! -f "$WALLPAPER_PATH" ]]; then
    mkdir -p "$(dirname "$WALLPAPER_PATH")"
    local found=false
    for candidate in "${LOCAL_WALLPAPER_CANDIDATES[@]}"; do
      if [[ -f "$candidate" ]]; then
        cp "$candidate" "$WALLPAPER_PATH"
        found=true
        break
      fi
    done
    if [[ "$found" == false ]]; then
      warn "Bliss wallpaper not found locally — download manually to: $WALLPAPER_PATH"
    else
      ok "Bliss wallpaper installed"
    fi
  fi

  ok "Windows XP skin dependencies ready"
}

skin_apply() {
  step "Applying Windows XP skin..."
  skin_save_state

  # Theme + icons
  skin_set_theme "$THEME_NAME" "$THEME_NAME" "$ICONS_NAME"

  # Buttons on the right (Windows-style)
  skin_set_buttons "right"

  # Panel at bottom
  skin_set_panel "bottom"

  # Wallpaper
  if [[ -f "$WALLPAPER_PATH" ]]; then
    skin_set_wallpaper "$WALLPAPER_PATH"
  fi

  # Font (Tahoma was the XP default)
  skin_set_font "Tahoma 11"

  # Startup sound autostart
  local sound_file=""
  for candidate in "${STARTUP_SOUND_CANDIDATES[@]}"; do
    if [[ -f "$candidate" ]]; then
      sound_file="$candidate"
      break
    fi
  done

  if [[ -n "$sound_file" ]]; then
    mkdir -p "${HOME}/.config/autostart"
    cat >"${HOME}/.config/autostart/winxp-startup-sound.desktop" <<SNDEOF
[Desktop Entry]
Type=Application
Name=WinXP Startup Sound
Exec=paplay ${sound_file}
X-GNOME-Autostart-enabled=true
SNDEOF
  fi

  ok "Windows XP skin applied ✓"
}

skin_remove() {
  step "Removing Windows XP skin..."
  skin_restore_state

  # Remove startup sound autostart
  rm -f "${HOME}/.config/autostart/winxp-startup-sound.desktop"

  ok "Windows XP skin removed ✓"
}

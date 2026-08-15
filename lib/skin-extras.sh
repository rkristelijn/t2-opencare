#!/bin/bash
# lib/skin-extras.sh — download and apply skin extras (wallpapers, icons, overrides)
# Assets are downloaded on-demand to ~/.cache/t2-opencare/assets/
# Wallpapers are resized to match screen resolution
# shellcheck source=lib/common.sh

source "${LIB_DIR}/common.sh"

ASSETS_CACHE="${HOME}/.cache/t2-opencare/assets"
WALLPAPER_DIR="${HOME}/.local/share/backgrounds/t2-opencare"

# ═══════════════════════════════════════════════════════════════
# ASSET SOURCES (URLs for on-demand download)
# ═══════════════════════════════════════════════════════════════

declare -A WALLPAPER_SOURCES=(
  [winxp]="https://archive.org/download/bliss_202407/Bliss.jpg"
  [win7]="https://archive.org/download/windows-7-wallpapers/img0.jpg"
  [win95]=""
  [macos]=""
)

# shellcheck disable=SC2034  # Used by future asset download functions
declare -A ASSET_REPOS=(
  [winxp - icons]="https://github.com/B00merang-Artwork/Windows-XP.git"
  [winxp - sprites]="https://github.com/tdcosta100/WindowsXP.git"
  [xp - hires - icons]="https://github.com/softwarehistorysociety/XPIcons.git"
)

# ═══════════════════════════════════════════════════════════════
# WALLPAPER MANAGEMENT
# ═══════════════════════════════════════════════════════════════

# Download wallpaper for a skin (if not cached)
extras_download_wallpaper() {
  local skin_id="$1"
  local url="${WALLPAPER_SOURCES[$skin_id]:-}"

  if [[ -z "$url" ]]; then
    # Try local sources
    local local_candidates=(
      "${CONFIG_DIR}/skins/${skin_id}/wallpaper.jpg"
      "${HOME}/git/hub/linux-intel-macbook/skins/winxp/windows_xp_original-wallpaper-2560x1600.jpg"
    )
    for f in "${local_candidates[@]}"; do
      if [[ -f "$f" ]]; then
        mkdir -p "${ASSETS_CACHE}/${skin_id}"
        cp "$f" "${ASSETS_CACHE}/${skin_id}/wallpaper-source.jpg"
        return 0
      fi
    done
    return 1
  fi

  local dest="${ASSETS_CACHE}/${skin_id}/wallpaper-source.jpg"
  if [[ -f "$dest" ]]; then
    return 0 # Already cached
  fi

  mkdir -p "${ASSETS_CACHE}/${skin_id}"
  step "Downloading wallpaper for ${skin_id}..."
  wget -q "$url" -O "$dest" || {
    fail "Wallpaper download failed: $url"
    return 1
  }
  ok "Wallpaper cached: $(du -h "$dest" | cut -f1)"
}

# Generate wallpaper variants for different resolutions
extras_generate_wallpapers() {
  local skin_id="$1"
  local source="${ASSETS_CACHE}/${skin_id}/wallpaper-source.jpg"

  if [[ ! -f "$source" ]]; then
    extras_download_wallpaper "$skin_id" || return 1
  fi

  if ! command -v convert &>/dev/null; then
    warn "imagemagick not installed — using source wallpaper as-is"
    mkdir -p "$WALLPAPER_DIR"
    cp "$source" "${WALLPAPER_DIR}/${skin_id}.jpg"
    return 0
  fi

  mkdir -p "$WALLPAPER_DIR"
  step "Generating wallpaper variants..."

  # Generate standard sizes
  local -A sizes=(
    [4k]="3840x2160"
    [1440p]="2560x1440"
    [1080p]="1920x1080"
    [vga]="640x480"
  )

  for label in "${!sizes[@]}"; do
    local res="${sizes[$label]}"
    local out="${WALLPAPER_DIR}/${skin_id}-${label}.jpg"
    if [[ ! -f "$out" ]]; then
      convert "$source" -resize "${res}^" -gravity center -extent "$res" -quality 90 "$out" 2>/dev/null
    fi
  done

  # Also create a "best match" for current resolution
  local screen_res
  screen_res=$(xrandr 2>/dev/null | grep '\*' | head -1 | awk '{print $1}')
  if [[ -n "$screen_res" ]]; then
    local out="${WALLPAPER_DIR}/${skin_id}.jpg"
    convert "$source" -resize "${screen_res}^" -gravity center -extent "$screen_res" -quality 90 "$out" 2>/dev/null
    ok "Wallpapers: ${screen_res} + 4K/1440p/1080p/VGA"
  else
    cp "$source" "${WALLPAPER_DIR}/${skin_id}.jpg"
    ok "Wallpapers: 4K/1440p/1080p/VGA"
  fi
}

# Apply the best wallpaper for current screen
extras_apply_wallpaper() {
  local skin_id="$1"
  local wp="${WALLPAPER_DIR}/${skin_id}.jpg"

  if [[ ! -f "$wp" ]]; then
    extras_generate_wallpapers "$skin_id" || return 1
  fi

  gsettings set org.cinnamon.desktop.background picture-uri "file://${wp}"
  gsettings set org.cinnamon.desktop.background picture-options "zoom"
}

# ═══════════════════════════════════════════════════════════════
# DESKTOP ICONS (My Computer, Recycle Bin, etc.)
# ═══════════════════════════════════════════════════════════════

extras_desktop_icons() {
  local skin_id="$1"
  local desktop_dir="${HOME}/Desktop"
  mkdir -p "$desktop_dir"

  case "$skin_id" in
    winxp | winxp-* | win7 | win95 | win10 | win10-dark | vista | longhorn)
      # Windows-style desktop icons
      cat >"${desktop_dir}/my-computer.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=My Computer
Icon=computer
Exec=nemo computer:///
Terminal=false
EOF
      cat >"${desktop_dir}/recycle-bin.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Recycle Bin
Icon=user-trash
Exec=nemo trash:///
Terminal=false
EOF
      cat >"${desktop_dir}/my-documents.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=My Documents
Icon=folder-documents
Exec=nemo ~/Documents
Terminal=false
EOF
      chmod +x "${desktop_dir}/my-computer.desktop" \
        "${desktop_dir}/recycle-bin.desktop" \
        "${desktop_dir}/my-documents.desktop"
      ok "Desktop icons: My Computer, Recycle Bin, My Documents"
      ;;
  esac
}

extras_remove_desktop_icons() {
  rm -f "${HOME}/Desktop/my-computer.desktop" \
    "${HOME}/Desktop/recycle-bin.desktop" \
    "${HOME}/Desktop/my-documents.desktop"
}

# ═══════════════════════════════════════════════════════════════
# APP ICON OVERRIDES (Firefox → IE, etc.)
# ═══════════════════════════════════════════════════════════════

extras_app_overrides() {
  local skin_id="$1"
  local override_dir="${HOME}/.local/share/applications"
  mkdir -p "$override_dir"

  case "$skin_id" in
    winxp | winxp-*)
      # Firefox → Internet Explorer icon
      local ie_icon="${CONFIG_DIR}/skins/winxp/ie.png"
      [[ ! -f "$ie_icon" ]] && ie_icon="${HOME}/git/hub/linux-intel-macbook/skins/winxp/ie.png"

      if [[ -f "$ie_icon" ]]; then
        local ff_desktop="/usr/share/applications/firefox.desktop"
        if [[ -f "$ff_desktop" ]]; then
          sed "s|^Icon=.*|Icon=${ie_icon}|" "$ff_desktop" >"${override_dir}/firefox.desktop"
          sed -i "s|^Name=Firefox.*|Name=Internet Explorer|" "${override_dir}/firefox.desktop"
          ok "Firefox → Internet Explorer (icon + name)"
        fi
      fi
      ;;
  esac
}

extras_remove_app_overrides() {
  rm -f "${HOME}/.local/share/applications/firefox.desktop"
  # Refresh desktop database
  update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
# START BUTTON (Cinnamon menu applet icon)
# ═══════════════════════════════════════════════════════════════

extras_start_button() {
  local skin_id="$1"
  local menu_conf="${HOME}/.config/cinnamon/spices/menu@cinnamon.org/0.json"

  if [[ ! -f "$menu_conf" ]]; then
    info "Menu applet config not found — skipping start button"
    return
  fi

  case "$skin_id" in
    winxp | winxp-*)
      local start_icon="${CONFIG_DIR}/skins/winxp/xp-start.png"
      [[ ! -f "$start_icon" ]] && start_icon="${HOME}/git/hub/linux-intel-macbook/skins/winxp/xp-start.png"

      if [[ -f "$start_icon" ]]; then
        # Backup menu config
        cp "$menu_conf" "${menu_conf}.bak-$(date +%s)"
        # Set custom icon (using python3 for safe JSON manipulation)
        python3 -c "
import json
with open('$menu_conf', 'r') as f:
    conf = json.load(f)
conf['menu-custom'] = {'value': True}
conf['menu-icon'] = {'value': '$start_icon'}
conf['menu-label'] = {'value': 'Start'}
with open('$menu_conf', 'w') as f:
    json.dump(conf, f, indent=2)
" 2>/dev/null && ok "Start button: XP logo"
      fi
      ;;
    win95)
      # Similar but with Win95 start button
      info "Win95 start button: use Chicago95 applet"
      ;;
  esac
}

extras_remove_start_button() {
  local menu_conf="${HOME}/.config/cinnamon/spices/menu@cinnamon.org/0.json"
  local backup
  backup=$(ls -t "${menu_conf}.bak-"* 2>/dev/null | head -1)
  if [[ -n "$backup" ]]; then
    cp "$backup" "$menu_conf"
    info "Start button restored from backup"
  fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN: Apply all extras for a skin
# ═══════════════════════════════════════════════════════════════

extras_apply() {
  local skin_id="$1"

  # Wallpaper (download + resize + apply)
  if [[ -n "${WALLPAPER_SOURCES[$skin_id]:-}" ]] ||
    [[ -f "${CONFIG_DIR}/skins/${skin_id}/wallpaper.jpg" ]] ||
    [[ -f "${HOME}/git/hub/linux-intel-macbook/skins/winxp/windows_xp_original-wallpaper-2560x1600.jpg" && "$skin_id" == winxp* ]]; then
    extras_generate_wallpapers "$skin_id"
    extras_apply_wallpaper "$skin_id"
  fi

  # Desktop icons
  extras_desktop_icons "$skin_id"

  # App overrides (Firefox → IE etc.)
  extras_app_overrides "$skin_id"

  # Start button
  extras_start_button "$skin_id"
}

# Remove all extras
extras_remove() {
  extras_remove_desktop_icons
  extras_remove_app_overrides
  extras_remove_start_button
}

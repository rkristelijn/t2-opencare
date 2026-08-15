#!/bin/bash
# lib/skin-registry.sh — generic skin installer from registry.toml
# Reads skin definitions and auto-downloads/installs themes
# shellcheck source=lib/common.sh

source "${LIB_DIR}/common.sh"
source "${LIB_DIR}/skin.sh"
source "${LIB_DIR}/skin-extras.sh"

REGISTRY_FILE="${CONFIG_DIR}/skins/registry.toml"
SKIN_CACHE_DIR="${HOME}/.cache/t2-opencare/skins"

# ═══════════════════════════════════════════════════════════════
# TOML PARSER (minimal — reads key=value from a section)
# ═══════════════════════════════════════════════════════════════

# Get a value from a TOML section: _toml_get <file> <section> <key>
_toml_get() {
  local file="$1" section="$2" key="$3"
  awk -v section="$section" -v key="$key" '
    /^\[/ { in_section = ($0 == "[" section "]") }
    in_section && $0 ~ "^" key " *= *" {
      sub(/^[^=]*= *"?/, "")
      sub(/"? *$/, "")
      print
      exit
    }
  ' "$file"
}

# List all section names from TOML
_toml_sections() {
  local file="$1"
  grep '^\[' "$file" | sed 's/\[//;s/\]//' | sort
}

# ═══════════════════════════════════════════════════════════════
# REGISTRY FUNCTIONS
# ═══════════════════════════════════════════════════════════════

# List all available skins from registry
registry_list() {
  if [[ ! -f "$REGISTRY_FILE" ]]; then
    fail "Registry not found: $REGISTRY_FILE"
    return 1
  fi

  local current_cat=""
  while IFS= read -r skin_id; do
    local name desc category
    name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "name")
    desc=$(_toml_get "$REGISTRY_FILE" "$skin_id" "description")
    category=$(_toml_get "$REGISTRY_FILE" "$skin_id" "category")

    # Print category header
    if [[ "$category" != "$current_cat" ]]; then
      [[ -n "$current_cat" ]] && echo ""
      echo "  ${category^^}:"
      current_cat="$category"
    fi

    # Check if installed
    local theme_name installed=""
    theme_name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_name")
    if [[ -d "${HOME}/.themes/${theme_name}" ]]; then
      installed=" [installed]"
    fi

    printf "    %-16s %-40s%s\n" "$skin_id" "$name" "$installed"
  done < <(_toml_sections "$REGISTRY_FILE")
}

# Get skin info
registry_info() {
  local skin_id="$1"
  local name desc theme_repo icons_repo buttons panel font
  name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "name")

  if [[ -z "$name" ]]; then
    fail "Skin not found in registry: $skin_id"
    echo ""
    echo "Available skins:"
    registry_list
    return 1
  fi

  desc=$(_toml_get "$REGISTRY_FILE" "$skin_id" "description")
  theme_repo=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_repo")
  icons_repo=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_repo")
  buttons=$(_toml_get "$REGISTRY_FILE" "$skin_id" "buttons")
  panel=$(_toml_get "$REGISTRY_FILE" "$skin_id" "panel")
  font=$(_toml_get "$REGISTRY_FILE" "$skin_id" "font")

  echo "  Name:    $name"
  echo "  Desc:    $desc"
  echo "  Theme:   $theme_repo"
  [[ -n "$icons_repo" ]] && echo "  Icons:   $icons_repo"
  echo "  Buttons: $buttons"
  echo "  Panel:   $panel"
  echo "  Font:    $font"
}

# Install a skin's theme files (download if needed)
registry_install_deps() {
  local skin_id="$1"
  local theme_repo theme_name theme_branch theme_path theme_installer
  local icons_repo icons_name icons_path icons_installer

  theme_repo=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_repo")
  theme_name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_name")
  theme_branch=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_branch")
  theme_path=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_path")
  theme_installer=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_installer")
  icons_repo=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_repo")
  icons_name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_name")
  icons_path=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_path")
  icons_installer=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_installer")

  mkdir -p "$SKIN_CACHE_DIR" "${HOME}/.themes" "${HOME}/.icons"

  # ─── Install GTK theme ──────────────────────────────────────
  if [[ -n "$theme_repo" ]] && [[ ! -d "${HOME}/.themes/${theme_name}" ]]; then
    step "Downloading theme: ${theme_name}..."
    local clone_dir="${SKIN_CACHE_DIR}/${skin_id}-theme"
    rm -rf "$clone_dir"

    local branch_flag=""
    [[ -n "$theme_branch" ]] && branch_flag="--branch $theme_branch"

    # shellcheck disable=SC2086
    git clone --depth 1 $branch_flag "$theme_repo" "$clone_dir" 2>/dev/null || {
      fail "Failed to clone theme: $theme_repo"
      return 1
    }

    if [[ -n "$theme_installer" ]]; then
      # Theme has its own installer script
      (cd "$clone_dir" && bash $theme_installer) 2>/dev/null
    elif [[ -n "$theme_path" ]]; then
      # Copy specific subdirectory
      cp -r "${clone_dir}/${theme_path}" "${HOME}/.themes/${theme_name}"
    else
      # Whole repo IS the theme
      cp -r "$clone_dir" "${HOME}/.themes/${theme_name}"
      rm -rf "${HOME}/.themes/${theme_name}/.git"
    fi

    ok "Theme installed: ${theme_name}"
  elif [[ -d "${HOME}/.themes/${theme_name}" ]]; then
    ok "Theme already installed: ${theme_name}"
  fi

  # ─── Install icon theme ─────────────────────────────────────
  if [[ -n "$icons_repo" ]] && [[ -n "$icons_name" ]] && [[ ! -d "${HOME}/.icons/${icons_name}" ]]; then
    step "Downloading icons: ${icons_name}..."
    local clone_dir="${SKIN_CACHE_DIR}/${skin_id}-icons"
    rm -rf "$clone_dir"

    git clone --depth 1 "$icons_repo" "$clone_dir" 2>/dev/null || {
      fail "Failed to clone icons: $icons_repo"
      return 1
    }

    if [[ -n "$icons_installer" ]]; then
      (cd "$clone_dir" && bash $icons_installer) 2>/dev/null
    elif [[ -n "$icons_path" ]]; then
      cp -r "${clone_dir}/${icons_path}" "${HOME}/.icons/${icons_name}"
    else
      cp -r "$clone_dir" "${HOME}/.icons/${icons_name}"
      rm -rf "${HOME}/.icons/${icons_name}/.git"
    fi

    ok "Icons installed: ${icons_name}"
  elif [[ -n "$icons_name" ]] && [[ -d "${HOME}/.icons/${icons_name}" ]]; then
    ok "Icons already installed: ${icons_name}"
  fi
}

# Apply a skin from the registry
registry_apply() {
  local skin_id="$1"
  local name theme_name icons_name buttons panel font extras

  name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "name")
  if [[ -z "$name" ]]; then
    fail "Skin not found: $skin_id"
    return 1
  fi

  theme_name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "theme_name")
  icons_name=$(_toml_get "$REGISTRY_FILE" "$skin_id" "icons_name")
  buttons=$(_toml_get "$REGISTRY_FILE" "$skin_id" "buttons")
  panel=$(_toml_get "$REGISTRY_FILE" "$skin_id" "panel")
  font=$(_toml_get "$REGISTRY_FILE" "$skin_id" "font")
  extras=$(_toml_get "$REGISTRY_FILE" "$skin_id" "extras")

  # Backup current state
  skin_save_state

  # Install dependencies (downloads themes if needed)
  registry_install_deps "$skin_id" || return 1

  # Apply theme
  step "Applying skin: ${name}..."
  [[ -n "$theme_name" ]] && skin_set_theme "$theme_name" "$theme_name" "${icons_name:-$theme_name}"
  [[ -n "$buttons" ]] && skin_set_buttons "$buttons"
  [[ -n "$panel" ]] && skin_set_panel "$panel"
  [[ -n "$font" ]] && skin_set_font "$font"

  # Wallpaper (local files)
  local wallpaper_local
  wallpaper_local=$(_toml_get "$REGISTRY_FILE" "$skin_id" "wallpaper_local")
  if [[ -n "$wallpaper_local" ]]; then
    local wp_path="${CONFIG_DIR}/skins/${wallpaper_local}"
    # Also check old repo location
    [[ ! -f "$wp_path" ]] && wp_path="${HOME}/git/hub/linux-intel-macbook/skins/${wallpaper_local}"
    [[ -f "$wp_path" ]] && skin_set_wallpaper "$wp_path"
  fi

  # Extras (e.g., plank dock)
  if [[ "$extras" == *"plank"* ]]; then
    if command -v plank &>/dev/null && ! pgrep -x plank &>/dev/null; then
      nohup plank &>/dev/null &
      disown
    fi
  fi

  # Record active skin
  mkdir -p "$(dirname "$ACTIVE_SKIN_FILE")"
  echo "$skin_id" >"$ACTIVE_SKIN_FILE"

  # Apply extras (wallpaper resize, desktop icons, start button, app overrides)
  extras_apply "$skin_id"

  ok "Skin '${name}' applied ✓"
  info "  Undo: ./scripts/skin.sh reset"
}

# Remove current skin and restore
registry_remove() {
  # Remove extras first (desktop icons, app overrides, start button)
  extras_remove

  skin_restore_state

  # Stop plank if running
  pgrep -x plank &>/dev/null && killall plank 2>/dev/null || true

  rm -f "$ACTIVE_SKIN_FILE"
  ok "Skin removed — previous state restored"
}

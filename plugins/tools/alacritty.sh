#!/bin/bash
# plugin: tools/alacritty
# description: GPU-accelerated terminal emulator (replaces gnome-terminal for lower latency)
# requires: internet gui
# provides: terminal

source "${LIB_DIR}/common.sh"

ALACRITTY_CONF="${HOME}/.config/alacritty/alacritty.toml"

plugin_check() {
  is_installed alacritty && [[ -f "$ALACRITTY_CONF" ]]
}

plugin_install() {
  require_internet

  step "Installing alacritty..."
  apt_install alacritty
  ok "alacritty $(alacritty --version | awk '{print $2}') installed"

  # ─── Install JetBrains Mono Nerd Font if missing ───────────────
  if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    step "Installing JetBrains Mono Nerd Font..."
    local font_dir="${HOME}/.local/share/fonts/JetBrainsMono"
    mkdir -p "$font_dir"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    curl -sL "$url" | tar -xJ -C "$font_dir"
    fc-cache -f "$font_dir"
    ok "JetBrains Mono Nerd Font installed"
  fi

  # ─── Write config ──────────────────────────────────────────────
  step "Writing alacritty config..."
  mkdir -p "$(dirname "$ALACRITTY_CONF")"
  cat > "$ALACRITTY_CONF" << 'EOF'
# Alacritty — GPU-accelerated terminal
# Managed by: t2-opencare (plugins/tools/alacritty.sh)

[env]
TERM = "xterm-256color"

[window]
padding = { x = 4, y = 4 }
dynamic_padding = true
opacity = 0.95

[font]
size = 11.0

[font.normal]
family = "JetBrainsMono Nerd Font Mono"
style = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font Mono"
style = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font Mono"
style = "Italic"

[scrolling]
history = 10000

[selection]
save_to_clipboard = true

# Catppuccin Mocha
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"
EOF
  ok "Config written to ${ALACRITTY_CONF}"

  info "Launch: alacritty"
  info "Consider setting as default terminal in Cinnamon preferences."
}

plugin_verify() {
  local errors=0

  if ! is_installed alacritty; then
    fail "alacritty not installed"
    ((errors++))
  fi

  if [[ ! -f "$ALACRITTY_CONF" ]]; then
    fail "Config missing: ${ALACRITTY_CONF}"
    ((errors++))
  fi

  if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
    warn "JetBrains Mono Nerd Font not found (alacritty will use fallback)"
  fi

  [[ $errors -eq 0 ]]
}

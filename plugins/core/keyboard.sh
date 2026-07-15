#!/bin/bash
# plugin: core/keyboard
# description: Configure Mac keyboard layout with suspend-safe xmodmap and Cinnamon fixes
# requires: core/t2-kernel
# provides: keyboard

source "${LIB_DIR}/common.sh"

# Default layout — override via env or setup.toml
KB_LAYOUT="${KB_LAYOUT:-us}"
KB_VARIANT="${KB_VARIANT:-mac}"
KB_MODEL="${KB_MODEL:-apple_laptop}"

# Keycode remaps (default: NL Mac ISO layout fixes)
# keycode 94 (key right of left shift): grave/tilde instead of </> 
# keycode 49 (top-left key): Escape instead of §/±
KEYCODE_94="${KEYCODE_94:-grave asciitilde}"
KEYCODE_49="${KEYCODE_49:-Escape}"

plugin_check() {
  # All 4 layers must be in place
  grep -q "XKBLAYOUT=${KB_LAYOUT}" /etc/default/keyboard 2>/dev/null && \
    [[ -f /etc/modprobe.d/hid_apple.conf ]] && \
    [[ -f /lib/systemd/system-sleep/restore-keyboard.sh ]] && \
    [[ -f "${HOME}/.config/autostart/keyboard-fix.desktop" ]]
}

plugin_install() {
  step "Configuring keyboard: layout=${KB_LAYOUT}, variant=${KB_VARIANT}..."

  # ─── Layer 1: /etc/default/keyboard (system-wide base) ────────
  sudo tee /etc/default/keyboard > /dev/null <<EOF
XKBMODEL="${KB_MODEL}"
XKBLAYOUT="${KB_LAYOUT}"
XKBVARIANT="${KB_VARIANT}"
XKBOPTIONS=""
BACKSPACE="guess"
EOF
  sudo setupcon 2>/dev/null || true

  # ─── Layer 2: Cinnamon input-sources (prevent layout override) ─
  step "Setting Cinnamon input source to ${KB_LAYOUT}+${KB_VARIANT}..."
  gsettings set org.cinnamon.desktop.input-sources sources \
    "[('xkb', '${KB_LAYOUT}+${KB_VARIANT}')]" 2>/dev/null || true

  # ─── Layer 3: ~/.xsessionrc (login) ───────────────────────────
  step "Creating ~/.xsessionrc..."
  cat > "${HOME}/.xsessionrc" <<EOF
#!/bin/bash
setxkbmap -layout ${KB_LAYOUT} -variant ${KB_VARIANT} -model ${KB_MODEL}
xmodmap -e "keycode 94 = ${KEYCODE_94}"
xmodmap -e "keycode 49 = ${KEYCODE_49}"
EOF
  chmod +x "${HOME}/.xsessionrc"

  # ─── Layer 4: Autostart (3s after login, after Cinnamon init) ──
  step "Creating autostart keyboard fix..."
  mkdir -p "${HOME}/.config/autostart"
  cat > "${HOME}/.config/autostart/keyboard-fix.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Keyboard Layout Fix
Comment=Restore Mac keyboard layout and xmodmap fixes after login
Exec=bash -c "sleep 3 && setxkbmap -layout ${KB_LAYOUT} -variant ${KB_VARIANT} -model ${KB_MODEL} && xmodmap -e 'keycode 94 = ${KEYCODE_94}' && xmodmap -e 'keycode 49 = ${KEYCODE_49}'"
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=true
EOF

  # ─── Layer 5: Suspend/resume hook ─────────────────────────────
  step "Creating suspend/resume keyboard restore hook..."
  sudo tee /lib/systemd/system-sleep/restore-keyboard.sh > /dev/null <<EOF
#!/bin/bash
if [ "\$1" = "post" ]; then
    # Find the active user (first logged-in graphical session)
    active_user=\$(loginctl list-sessions --no-legend | awk '{print \$3}' | head -1)
    if [ -n "\$active_user" ]; then
        sudo -u "\$active_user" DISPLAY=:0 setxkbmap -layout ${KB_LAYOUT} -variant ${KB_VARIANT} -model ${KB_MODEL}
        sudo -u "\$active_user" DISPLAY=:0 xmodmap -e "keycode 94 = ${KEYCODE_94}"
        sudo -u "\$active_user" DISPLAY=:0 xmodmap -e "keycode 49 = ${KEYCODE_49}"
    fi
fi
EOF
  sudo chmod +x /lib/systemd/system-sleep/restore-keyboard.sh

  # ─── hid_apple: fnmode=2 (media keys default, Fn for F1-F12) ──
  step "Configuring hid_apple fnmode..."
  echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf > /dev/null
  sudo update-initramfs -u 2>/dev/null || true

  # Apply immediately
  setxkbmap -layout "${KB_LAYOUT}" -variant "${KB_VARIANT}" -model "${KB_MODEL}" 2>/dev/null || true
  xmodmap -e "keycode 94 = ${KEYCODE_94}" 2>/dev/null || true
  xmodmap -e "keycode 49 = ${KEYCODE_49}" 2>/dev/null || true

  ok "Keyboard configured with 5 protection layers"
  info "  Layout: ${KB_LAYOUT} (${KB_VARIANT}), fnmode=2"
  info "  Keycode 94 → ${KEYCODE_94}, Keycode 49 → ${KEYCODE_49}"
}

plugin_verify() {
  local errors=0

  # Check 1: /etc/default/keyboard
  if ! grep -q "XKBLAYOUT=${KB_LAYOUT}" /etc/default/keyboard 2>/dev/null; then
    fail "/etc/default/keyboard: layout not set to ${KB_LAYOUT}"
    ((errors++))
  fi

  # Check 2: Cinnamon input-sources (not 'us' only)
  local sources
  sources=$(gsettings get org.cinnamon.desktop.input-sources sources 2>/dev/null || echo "")
  if [[ -n "$sources" ]] && echo "$sources" | grep -q "'us'" && ! echo "$sources" | grep -q "${KB_LAYOUT}"; then
    fail "Cinnamon input-sources set to US only (will override layout)"
    info "  Fix: gsettings set org.cinnamon.desktop.input-sources sources \"[('xkb', '${KB_LAYOUT}+${KB_VARIANT}')]\""
    ((errors++))
  fi

  # Check 3: suspend hook exists and is executable
  if [[ ! -x /lib/systemd/system-sleep/restore-keyboard.sh ]]; then
    fail "Suspend/resume keyboard hook missing or not executable"
    ((errors++))
  fi

  # Check 4: autostart entry
  if [[ ! -f "${HOME}/.config/autostart/keyboard-fix.desktop" ]]; then
    fail "Autostart keyboard-fix.desktop missing"
    ((errors++))
  fi

  # Check 5: hid_apple fnmode
  if [[ ! -f /etc/modprobe.d/hid_apple.conf ]]; then
    fail "hid_apple fnmode not configured"
    ((errors++))
  fi

  # Check 6: current layout (if X is running)
  if [[ -n "${DISPLAY:-}" ]]; then
    local current_layout
    current_layout=$(setxkbmap -query 2>/dev/null | grep "layout" | awk '{print $2}')
    if [[ "$current_layout" != "$KB_LAYOUT" ]]; then
      warn "Current active layout is '${current_layout}', expected '${KB_LAYOUT}'"
      info "  Quick fix: setxkbmap -layout ${KB_LAYOUT} -variant ${KB_VARIANT} -model ${KB_MODEL}"
    fi
  fi

  [[ $errors -eq 0 ]]
}

#!/bin/bash
# plugin: core/wifi
# description: Install WiFi firmware for Broadcom BCM4364 (T2 MacBooks)
# requires: internet core/t2-kernel
# provides: wifi bluetooth

source "${LIB_DIR}/common.sh"

plugin_check() {
  # Check if wifi firmware is installed and interface is up
  dpkg -s apple-firmware &>/dev/null && ip link show wlp1s0 &>/dev/null
}

plugin_install() {
  require_root
  require_internet

  step "Adding Apple firmware repository..."
  if ! grep -q "Apple-Firmware" /etc/apt/sources.list.d/t2.list 2>/dev/null; then
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/Apple-Firmware/releases/download/debian /" |
      sudo tee -a /etc/apt/sources.list.d/t2.list
  fi

  sudo apt-get update
  sudo apt-get install -y apple-firmware

  step "Reloading WiFi driver..."
  sudo modprobe -r brcmfmac_wcc 2>/dev/null || true
  sudo modprobe -r brcmfmac 2>/dev/null || true
  sudo modprobe brcmfmac

  ok "WiFi firmware installed. Interface should appear shortly."
}

plugin_verify() {
  # Check that wifi interface exists
  ip link show wlp1s0 &>/dev/null
}

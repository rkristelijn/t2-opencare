#!/bin/bash
# plugin: core/t2-kernel
# description: Install T2 Linux kernel with apple-bce driver
# requires: internet
# provides: keyboard trackpad camera audio touchbar

source "${LIB_DIR}/common.sh"

plugin_check() {
  # Check if t2 kernel is installed and running
  uname -r | grep -q "t2"
}

plugin_install() {
  require_root
  require_internet

  step "Adding t2linux apt repository..."
  curl -s --compressed "https://adityagarg8.github.io/t2-ubuntu-repo/KEY.gpg" |
    gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg >/dev/null

  # Detect Ubuntu codename
  local codename
  codename=$(lsb_release -cs 2>/dev/null || echo "noble")
  info "Detected codename: ${codename}"

  sudo curl -s --compressed -o /etc/apt/sources.list.d/t2.list \
    "https://adityagarg8.github.io/t2-ubuntu-repo/t2.list"

  echo "deb [signed-by=/etc/apt/trusted.gpg.d/t2-ubuntu-repo.gpg] https://github.com/AdityaGarg8/t2-ubuntu-repo/releases/download/${codename} /" |
    sudo tee -a /etc/apt/sources.list.d/t2.list

  step "Installing T2 kernel..."
  sudo apt-get update
  sudo apt-get install -y linux-t2

  step "Configuring kernel parameters..."
  sudo sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 intel_iommu=on iommu=pt pcie_ports=compat"/' /etc/default/grub
  sudo update-grub

  step "Loading apple-bce at boot..."
  echo apple-bce | sudo tee /etc/modules-load.d/t2.conf
  echo "blacklist applespi" | sudo tee /etc/modprobe.d/blacklist-applespi.conf

  ok "T2 kernel installed. Reboot required to activate."
}

plugin_verify() {
  uname -r | grep -q "t2"
}

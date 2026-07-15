#!/bin/bash
# lib/common.sh — shared utilities for t2-opencare plugins
# shellcheck disable=SC2034

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="${REPO_DIR}/lib"
PLUGIN_DIR="${REPO_DIR}/plugins"
CONFIG_DIR="${REPO_DIR}/config"

# Logging
info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[  ok]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; }
step()  { echo -e "${BOLD}:: $*${NC}"; }

# Checks
require_root() {
  if [[ $EUID -ne 0 ]]; then
    fail "This plugin requires root. Run with sudo or as root."
    exit 1
  fi
}

require_internet() {
  if ! ping -c1 -W2 1.1.1.1 &>/dev/null; then
    fail "No internet connection detected."
    exit 1
  fi
}

require_t2() {
  if ! system_profiler 2>/dev/null | grep -q "T2" && \
     ! dmesg 2>/dev/null | grep -qi "apple-bce\|t8012"; then
    # Fallback: check model identifier
    local model
    model=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
    if [[ ! "$model" =~ MacBookPro1[5-6] ]]; then
      warn "This does not appear to be a T2 MacBook (detected: ${model:-unknown})"
      warn "Proceed anyway? (plugins may not work correctly)"
      read -rp "[y/N] " confirm
      [[ "$confirm" =~ ^[Yy] ]] || exit 1
    fi
  fi
}

is_installed() {
  command -v "$1" &>/dev/null
}

apt_install() {
  sudo apt-get install -y --no-install-recommends "$@"
}

# Plugin runner
run_plugin_func() {
  local func="$1"
  if declare -f "$func" &>/dev/null; then
    "$func"
  else
    fail "Plugin does not implement ${func}()"
    return 1
  fi
}

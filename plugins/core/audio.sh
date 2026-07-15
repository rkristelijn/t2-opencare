#!/bin/bash
# plugin: core/audio
# description: Verify and configure audio (apple-bce + PipeWire)
# requires: core/t2-kernel
# provides: audio

source "${LIB_DIR}/common.sh"

plugin_check() {
  # Audio works OOTB with apple-bce, just check it's not muted
  pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "no"
}

plugin_install() {
  step "Configuring audio..."

  # Unmute and set reasonable volume
  pactl set-sink-mute @DEFAULT_SINK@ 0
  pactl set-sink-volume @DEFAULT_SINK@ 80%

  ok "Audio unmuted and set to 80%"
}

plugin_verify() {
  pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -q "no"
}

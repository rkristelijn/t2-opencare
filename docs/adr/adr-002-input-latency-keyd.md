# ADR-002: Input Latency Reduction — keyd replaces Kinto/xkeysnail

*Status*: Accepted · *Date*: 2026-08-15

## Context

The default input pipeline on a Linux Mint T2 MacBook adds 15-35ms of latency per keystroke through three layers:

| Layer | Technology | Latency added |
|-------|-----------|---------------|
| Key remapping | xkeysnail (Python, userspace) | 5-15ms |
| Input method | IBus (D-Bus IPC) | 2-5ms |
| Terminal | gnome-terminal (VTE, CPU-rendered) | 8-16ms |

This was not noticeable on a fast desktop, but on a 2018 MacBook Pro with limited CPU headroom, the accumulated delay causes perceptible typing lag — especially under load.

Additionally, xkeysnail is crash-prone: it grabs `/dev/input` devices and crashes with `BrokenPipeError` when devices disconnect (e.g., Thunderbolt dock unplug). This leads to crash-loops that consume 80%+ CPU.

## Decision

Replace all three latency sources:

### 1. xkeysnail → keyd

| | xkeysnail (Kinto) | keyd |
|---|---|---|
| Language | Python 3 | C |
| Level | Userspace (evdev grab) | Kernel (virtual input device) |
| Latency | 5-15ms | <0.1ms |
| Crashes | Yes (evdev BrokenPipeError) | No known crashes |
| Config | Python script | Declarative INI |

keyd performs the same Meta↔Ctrl swap at the kernel level with zero measurable latency.

### 2. IBus → disabled

IBus provides input method switching (e.g., Chinese/Japanese). With a single keyboard layout (NL Mac), it's pure overhead on the D-Bus path between keypress and application.

### 3. gnome-terminal → alacritty

| | gnome-terminal | alacritty |
|---|---|---|
| Rendering | CPU (Cairo/VTE) | GPU (OpenGL) |
| Frame time | 8-16ms | <1ms |
| RAM | ~55MB | ~15MB |

## Consequences

- **Positive:** Typing feels instant. No more crash-loops from xkeysnail. Lower CPU and RAM usage.
- **Negative:** App-specific keymaps from Kinto (JetBrains, file managers) are lost. keyd supports app-specific layers but requires more manual config.
- **Migration:** The `desktop/kinto` plugin is deprecated. Users should run `desktop/keyd` instead.

## Plugin changes

- New: `plugins/desktop/keyd.sh` — installs keyd, writes config, disables xkeysnail + IBus
- New: `plugins/tools/alacritty.sh` — GPU-accelerated terminal with Nerd Font
- Deprecated: `plugins/desktop/kinto.sh` — still available for users who prefer Python-level app-specific mappings

## References

- [keyd](https://github.com/rvaiya/keyd)
- [alacritty](https://github.com/alacritty/alacritty)
- INC-001 (linux-intel-macbook): xkeysnail crash-loop consuming 80% CPU

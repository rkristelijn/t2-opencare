# t2-opencare

> Your warranty expired. Your laptop didn't.

Open source care plan for Intel MacBooks with T2 chip, running Linux Mint or Ubuntu.

## Why this exists

Apple has confirmed that **macOS 27 (Golden Gate)**, releasing September 2026, will be the first macOS version to drop all Intel Macs. macOS 26 Tahoe is the final version with Intel support. After that: no security updates, no new features, no Apple care.

This affects every MacBook with a T2 chip (2018–2020) — machines that are still fast, well-built, and perfectly capable. They just need an OS that won't abandon them.

**t2-opencare gives these machines a second life on Linux** — with one command.

| Timeline | What happens |
|----------|-------------|
| WWDC 2025 | Apple announces macOS Tahoe is final for Intel |
| Sep 2026 | macOS 27 releases, Intel Macs get no updates |
| 2027+ | Security patches stop, hardware marked "obsolete" |
| **Now** | Install Linux, keep your MacBook alive indefinitely |

### Sources

- [macOS 27 drops Intel support](https://www.macrumors.com/2026/04/18/macos-27-compatibility-change/) — MacRumors, Apr 2026
- [Apple confirms end of Intel support](https://www.zdnet.com/article/your-old-macbooks-days-are-numbered-as-apple-confirms-end-of-support/) — ZDNet, Jun 2025
- [t2linux wiki](https://wiki.t2linux.org) — Community drivers for T2 hardware on Linux
- [T2 Ubuntu kernel](https://github.com/t2linux/T2-Debian-and-Ubuntu-Kernel) — Maintained kernel with apple-bce patches

### The problem with stock Linux on T2 Macs

A vanilla Linux Mint install on a T2 MacBook gives you a black screen, no keyboard, no trackpad, no WiFi, and no audio. The T2 chip routes all internal hardware through a proprietary PCIe interface (`apple-bce`), not standard USB/SPI.

**t2-opencare automates the entire fix** — from kernel to desktop experience.

---

One command to go from vanilla Mint to a fully working MacBook — keyboard, trackpad, WiFi, Touch Bar, audio, gestures, macOS-style keybindings, and more.

## Quick Start

### Step 0: Install Linux Mint (one-time)

Download the [T2-Mint ISO](https://github.com/t2linux/T2-Mint/releases) — this is a vanilla Linux Mint ISO with T2 kernel drivers baked in, so your keyboard and trackpad work during installation.

1. Flash the ISO to USB (`dd` or [Balena Etcher](https://etcher.balena.io/))
2. Boot from USB (hold ⌥ Option at startup, select EFI Boot)
3. Install Linux Mint normally
4. Reboot into your new install
5. Connect internet (ethernet, USB tethering, or USB WiFi dongle)

> Already running Mint/Ubuntu? Skip to step 1 below. t2-opencare works on any existing install.

### Step 1: Run t2-opencare

```bash
git clone https://github.com/rkristelijn/t2-opencare.git
cd t2-opencare
./install.sh
```

That's it. Choose "Core" on first run to get hardware working, then run again for desktop tweaks and tools.

<!-- TODO: add screenshot of working setup here -->
<!-- ![My setup](docs/images/setup.jpg) -->

## What it does

| Layer | Plugins | Description |
|-------|---------|-------------|
| **core** | t2-kernel, wifi, audio, keyboard, touchbar | Make hardware work |
| **desktop** | touchegg, kinto | macOS UX on Linux (gestures, Cmd key) |
| **tools** | tmux, neovim, docker, espanso, ollama | Developer power tools |
| **network** | nordvpn, firewall | Connectivity & security |
| **skins** | winxp | Cosmetic fun |

## Usage

```bash
./install.sh                  # Interactive menu
./install.sh --core           # Hardware essentials only
./install.sh --all            # Everything
./install.sh core/wifi tools/tmux  # Pick specific plugins
./install.sh --dry-run --all  # Preview without changes
./install.sh --list           # Show available plugins
```

## Supported Hardware

All Intel MacBooks with T2 chip (2018–2020):

| Model | Identifier |
|-------|-----------|
| MacBook Pro 13" (2018/2019) | MacBookPro15,2 |
| MacBook Pro 15" (2018/2019) | MacBookPro15,1 / 15,3 |
| MacBook Pro 13" (2020) | MacBookPro15,4 |
| MacBook Pro 16" (2019) | MacBookPro16,1 / 16,4 |
| MacBook Pro 13" (2020) | MacBookPro16,2 / 16,3 |
| MacBook Air (2018–2020) | MacBookAir8,1 / 8,2 / 9,1 |

## Plugin System

Each plugin follows a simple contract:

```bash
plugin_check()    # Already installed? (skip if yes)
plugin_install()  # Do the work
plugin_verify()   # Confirm it works
```

Plugins are idempotent — run them again without side effects.

## Quality Gates (CPM-style)

```bash
make check-fast   # Tier 1: shfmt format check
make check        # Tier 2: + shellcheck + gitleaks
make check-full   # Tier 3: + dry-run install test
make fix          # Auto-fix formatting
make tools        # Install quality tools
```

## Project Structure

```
t2-opencare/
├── install.sh           # Entrypoint
├── setup.toml           # Configuration
├── Makefile             # Quality gates
├── CONVENTIONS.md       # Naming standards
├── plugins/
│   ├── core/            # Hardware (always install)
│   ├── desktop/         # UX layer
│   ├── tools/           # Optional dev tools
│   ├── network/         # VPN, firewall
│   └── skins/           # Themes
├── config/              # Default config files
└── lib/                 # Shared functions
```

## Requirements

- Linux Mint 22+ or Ubuntu 24.04+ (fresh install)
- Internet connection (for first run)
- Wired ethernet or USB tethering (WiFi firmware not yet installed)

## Contributing

1. Fork → create a plugin in `plugins/<layer>/<name>.sh`
2. Follow the contract in [CONVENTIONS.md](CONVENTIONS.md)
3. Run `make check` before submitting
4. PR with conventional commit message

## License

MIT

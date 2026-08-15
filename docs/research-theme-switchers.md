# Research: Linux Desktop Theme Switchers

*Date*: 2026-08-15 · *Context*: t2-opencare skin system

## Existing Tools

### cinnamon-profile-manager
- **URL**: https://github.com/ClaytonTDM/cinnamon-profile-manager
- **Tech**: TypeScript/Deno CLI
- **What it does**: Saves/restores complete Cinnamon desktop profiles (panels, applets, themes, shortcuts, workspace settings, fonts)
- **Pros**: Very complete (saves full dconf dumps), import/export, automatic backups
- **Cons**: Requires Deno runtime, beta quality, 23 commits, Cinnamon-only
- **Relevance**: Closest to what we're building. Could adopt their dconf dump approach for more complete state capture.

### cinnamon-layout (wasta-linux)
- **URL**: https://github.com/wasta-linux/cinnamon-layout
- **Tech**: Bash + gschema overrides
- **What it does**: Switches between pre-defined desktop layouts (panel positions, applets)
- **Pros**: Pure bash, production-used (wasta-linux distro)
- **Cons**: No theme downloads, no visual skin switching, just layout presets
- **Relevance**: Good reference for panel/applet layout manipulation.

### ThemeChanger
- **URL**: https://github.com/ALEX11BR/ThemeChanger
- **Tech**: Python GUI (GTK)
- **What it does**: Change GTK 2/3/4, Kvantum, icon and cursor themes with live preview
- **Pros**: Supports libadwaita, can install theme archives, live CSS editing
- **Cons**: GUI-only, no CLI, no "skin packs", no state backup
- **Relevance**: Good UX reference for what settings to toggle.

### DermoDeX
- **URL**: https://github.com/duracell80/DermoDeX
- **Tech**: Python, for Linux Mint 21
- **What it does**: Dynamic theme engine — generates color variants
- **Cons**: Abandoned-looking, very specific

### automatic-theme-cinnamon
- **URL**: https://github.com/dboun/automatic-theme-cinnamon
- **Tech**: Python3
- **What it does**: Auto light/dark switch based on time of day
- **Relevance**: Could integrate time-based switching later.

## Available Skin Sources — Complete Catalog

### Nostalgia / Retro (B00merang Project — 77 repos, 284 followers)

All themes: GTK 2/3/4, Cinnamon, GNOME Shell, Metacity, XFWM. Install by extracting to `~/.themes/`.

| Skin | Stars | Source | Notes |
|------|-------|--------|-------|
| **Windows XP** (Luna, Olive, Silver, Royale, Embedded, Zune) | 483 ⭐ | [B00merang-Project/Windows-XP](https://github.com/B00merang-Project/Windows-XP) | Multiple color schemes in releases |
| **Windows 7** | 267 ⭐ | [B00merang-Project/Windows-7](https://github.com/B00merang-Project/Windows-7) | Aero glass effect |
| **Windows 10 Light** | 881 ⭐ | [B00merang-Project/Windows-10](https://github.com/B00merang-Project/Windows-10) | Most popular B00merang theme |
| **Windows 10 Dark** | 352 ⭐ | [B00merang-Project/Windows-10-Dark](https://github.com/B00merang-Project/Windows-10-Dark) | Dark mode variant |
| **Windows Vista** | 66 ⭐ | [B00merang-Project/Windows-Vista](https://github.com/B00merang-Project/Windows-Vista) | Aero |
| **Windows 8.1** | 24 ⭐ | [B00merang-Project/Windows-8.1](https://github.com/B00merang-Project/Windows-8.1) | Metro flat |
| **Windows Longhorn** | 50 ⭐ | [B00merang-Project/Windows-Longhorn](https://github.com/B00merang-Project/Windows-Longhorn) | Pre-Vista beta builds |
| **macOS** (generic) | 756 ⭐ | [B00merang-Project/macOS](https://github.com/B00merang-Project/macOS) | Clean Apple look |
| **macOS Catalina** | — | [B00merang-Project/macOS-Catalina](https://github.com/B00merang-Project/macOS-Catalina) | 10.15 specific |
| **macOS Catalina Dark** | — | [B00merang-Project/macOS-Catalina-Dark](https://github.com/B00merang-Project/macOS-Catalina-Dark) | Dark variant |
| **Mac OS X Cheetah** | 53 ⭐ | [B00merang-Project/Mac-OS-X-Cheetah](https://github.com/B00merang-Project/Mac-OS-X-Cheetah) | Original Aqua (2001) |
| **Solaris 9 (CDE)** | 59 ⭐ | [B00merang-Project/Solaris-9](https://github.com/B00merang-Project/Solaris-9) | Classic UNIX CDE look |
| **Haiku (BeOS)** | 41 ⭐ | [B00merang-Project/Haiku](https://github.com/B00merang-Project/Haiku) | BeOS nostalgia |
| **Android** | 36 ⭐ | [B00merang-Project/Android](https://github.com/B00merang-Project/Android) | Chrome OS-based |
| **Unity 8** | 30 ⭐ | [B00merang-Project/Unity-8](https://github.com/B00merang-Project/Unity-8) | Ubuntu Unity |

**Install pattern (all B00merang):**
```bash
git clone --depth 1 https://github.com/B00merang-Project/<THEME>.git ~/.themes/<THEME>
```

### Cinnamon-specific XP themes

| Skin | Source | Notes |
|------|--------|-------|
| **CinnXP** | [ndwarshuis/CinnXP](https://github.com/ndwarshuis/CinnXP) | Full XP for Cinnamon (theme + panel + applets) |
| **Mint-XP** | [Cinnamon Spices](https://cinnamon-spices.linuxmint.com/themes/view/Mint-XP) | Simple XP-inspired (less accurate) |
| **Windows 7 Cinnamon** | [Xalalau/Windows-7-Theme-Cinnamon](https://github.com/Xalalau/Windows-7-theme-cinnamon) | Updated for Cinnamon 6 |

### Modern macOS themes

| Skin | Stars | Source | Notes |
|------|-------|--------|-------|
| **WhiteSur** (GTK) | 6000+ ⭐ | [vinceliuice/WhiteSur-gtk-theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) | Best macOS theme. Light/Dark, all accents |
| **WhiteSur** (icons) | 1000+ ⭐ | [vinceliuice/WhiteSur-icon-theme](https://github.com/vinceliuice/WhiteSur-icon-theme) | Matching icon set |
| **WhiteSur** (cursors) | — | [vinceliuice/WhiteSur-cursors](https://github.com/vinceliuice/WhiteSur-cursors) | macOS cursors |

### Color scheme themes (modern, popular for ricing)

| Skin | Stars | Source | Notes |
|------|-------|--------|-------|
| **Catppuccin GTK** | 1500+ ⭐ | [catppuccin/gtk](https://github.com/catppuccin/gtk) | Pastel, 4 flavors (Latte/Frappé/Macchiato/Mocha) |
| **Dracula GTK** | 800+ ⭐ | [dracula/gtk](https://github.com/dracula/gtk) | Dark purple, iconic. Cinnamon support. |
| **Gruvbox GTK** | 400+ ⭐ | [Fausto-Korpsvart/Gruvbox-GTK-Theme](https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme) | Warm retro terminal colors |
| **Nord GTK** | — | (via Catppuccin or custom) | Cool blue |
| **Everforest** | 400+ ⭐ | (via GTK port) | Green forest tones |

### Icon packs (pair with any theme)

| Icons | Source | Style |
|-------|--------|-------|
| **Chicago95** | [grassmunk/Chicago95](https://github.com/grassmunk/Chicago95) | Win95/2000 (includes full GTK theme + sounds) |
| **Papirus** | [PapirusDevelopmentTeam/papirus-icon-theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) | Modern flat (most popular Linux icons) |
| **Tela** | [vinceliuice/Tela-icon-theme](https://github.com/vinceliuice/Tela-icon-theme) | Modern flat, many colors |
| **WhiteSur** | See above | macOS Big Sur style |

## How themes work (technical)

### Directory structure
```
~/.themes/<ThemeName>/
├── cinnamon/          # Cinnamon shell theme (CSS)
├── gtk-2.0/           # GTK2 theme (gtkrc)
├── gtk-3.0/           # GTK3 theme (CSS)
├── gtk-4.0/           # GTK4/libadwaita (CSS)
├── metacity-1/        # Window borders (Mutter/Muffin)
├── xfwm4/             # XFWM window borders
└── index.theme        # Theme metadata

~/.icons/<IconThemeName>/
├── 16x16/             # Small icons
├── 22x22/
├── 24x24/
├── 32x32/
├── 48x48/
├── 64x64/
├── 128x128/
├── scalable/          # SVG icons
├── cursors/           # X11 cursor files
└── index.theme        # Icon theme metadata
```

### How switching works (gsettings/dconf)
```bash
# Cinnamon shell theme (panels, menu, OSD)
gsettings set org.cinnamon.theme name "ThemeName"

# GTK theme (app windows, buttons, inputs)
gsettings set org.cinnamon.desktop.interface gtk-theme "ThemeName"

# Icon theme
gsettings set org.cinnamon.desktop.interface icon-theme "IconThemeName"

# Cursor theme
gsettings set org.cinnamon.desktop.interface cursor-theme "CursorThemeName"

# Window border theme (metacity)
gsettings set org.cinnamon.desktop.wm.preferences theme "ThemeName"

# Window buttons position
gsettings set org.cinnamon.desktop.wm.preferences button-layout "close,minimize,maximize:"  # left
gsettings set org.cinnamon.desktop.wm.preferences button-layout ":minimize,maximize,close"  # right
```

All changes are instant — no logout needed. Cinnamon watches these dconf keys and reloads in real-time.

### Full skin = theme + icons + cursors + wallpaper + panel + font + sounds

A "skin" in our system is a combination of all the above, applied atomically with rollback support.

## Gap Analysis: What our skin.sh does that others don't

| Feature | skin.sh | cinnamon-profile-manager | ThemeChanger |
|---------|---------|--------------------------|--------------|
| CLI operation | ✅ | ✅ | ❌ (GUI) |
| Zero dependencies (pure bash) | ✅ | ❌ (Deno) | ❌ (Python) |
| Auto-download themes | ✅ | ❌ | ❌ |
| Timestamped rollback | ✅ | ✅ | ❌ |
| Skin "packs" (theme+icons+wallpaper+sound) | ✅ | ❌ | ❌ |
| Hot-swap without logout | ✅ | ✅ | ✅ |
| Panel layout switching | ❌ | ✅ (via dconf dump) | ❌ |
| Applet configuration | ❌ | ✅ | ❌ |
| Cross-DE support | ❌ | ❌ | ✅ (GTK/Qt) |
| Terminal theme sync | ❌ | ❌ | ❌ |

## Future: Standalone Theme Switcher Project

A universal tool could combine the best of all approaches:

1. **Core**: Pure bash CLI (like skin.sh) for speed and zero deps
2. **State**: Full dconf dump + selective restore (like cinnamon-profile-manager)
3. **Packs**: Downloadable skin packs from a registry (theme + icons + wallpaper + sounds + terminal colors + panel layout)
4. **Sync**: Terminal theme (Alacritty/kitty), editor theme (VS Code), browser (Firefox CSS)
5. **Rollback**: Timestamped backups with named checkpoints
6. **Registry**: Public skin pack repository (GitHub-based, like cinnamon-spices but broader)

### Potential skin pack format

```toml
[skin]
name = "Windows XP Luna"
version = "1.0.0"
author = "..."
description = "Pixel-perfect Windows XP Luna recreation"
screenshot = "screenshot.png"

[theme]
gtk = "B00merang-Windows-XP"
gtk_source = "https://github.com/B00merang-Project/Windows-XP/archive/refs/heads/master.zip"
cinnamon = "B00merang-Windows-XP"
icons = "Chicago95"
icons_source = "https://github.com/grassmunk/Chicago95/archive/refs/heads/master.zip"
cursor = "Chicago95"

[layout]
buttons = "right"            # minimize,maximize,close on right
panel = "bottom"
font = "Tahoma 11"

[extras]
wallpaper = "bliss.jpg"
startup_sound = "windows-xp-startup.mp3"
login_theme = "xp-login.png"

[terminal]
alacritty_theme = "xp-cmd.toml"  # black background, white text, no transparency

[optional]
firefox_css = "xp-firefox.css"
```

This could become a standalone project: `skinner` or `deskswitch` — a universal desktop skin manager.

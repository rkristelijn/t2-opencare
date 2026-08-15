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

## Retro/Nostalgia Theme Packs

### B00merang Windows-XP (RECOMMENDED)
- **URL**: https://github.com/B00merang-Project/Windows-XP
- **Quality**: Pixel-perfect Luna recreation
- **Variants**: Luna (blue), Olive Green, Silver, Royale, Embedded, Zune
- **Includes**: GTK 2/3, Cinnamon, Metacity, XFWM
- **Install**: Extract zip to ~/.themes/
- **Why better than Mint-XP**: Proper Luna gradients, correct title bar colors, authentic button styles

### CinnXP
- **URL**: https://github.com/ndwarshuis/CinnXP
- **Quality**: Full XP look specifically for Cinnamon
- **Includes**: Theme + panel layout + applet configs
- **Note**: Requires specific fonts (Tahoma, Franklin Gothic)
- **Status**: Last updated 2019, may need fixes for Mint 22

### Chicago95
- **URL**: https://github.com/grassmunk/Chicago95
- **Quality**: Excellent Windows 95/2000/Classic recreation
- **Includes**: Full GTK theme + icons + cursors + sounds + Plymouth boot + LightDM
- **Install**: Has its own installer script
- **Note**: Already using their icons in our winxp skin

### WhiteSur (already in use)
- **URL**: https://github.com/vinceliuice/WhiteSur-gtk-theme
- **Quality**: Best macOS theme for Linux
- **Variants**: Light, Dark, solid, all accent colors
- **Includes**: GTK, icons, cursors, Firefox theme, GDM
- **Note**: Active project, frequent updates

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

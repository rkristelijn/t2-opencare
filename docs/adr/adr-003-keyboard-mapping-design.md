# ADR-003: Keyboard Mapping — macOS-identical via keyd layers

*Status*: Proposed · *Date*: 2026-08-15

## Context

Op een MacBook Pro heb je twee modifier-toetsen die elk hun eigen rol hebben:

- **⌘ Cmd** = GUI shortcuts (copy, paste, tab-switch, quit, spotlight)
- **Ctrl** = terminal control characters (Ctrl+C, Ctrl+A, Ctrl+U) en tmux prefix

De huidige keyd config doet een **domme swap** (`leftmeta = leftcontrol`) die Cmd→Ctrl fixt maar fysieke Ctrl naar Super vertaalt. Resultaat: terminal shortcuts, tmux, en tiling bindings werken niet.

## Decision

Gebruik keyd **layer met modifier emulatie** (`[meta_mac:C]`). Dit maakt ⌘ een "slim Ctrl" met uitzonderingen, terwijl fysieke Ctrl onaangeraakt blijft.

## Volledige keyd config

```ini
# /etc/keyd/default.conf
# macOS-identical keyboard for T2 MacBook
# Managed by: t2-opencare (plugins/desktop/keyd.sh)
# Docs: ADR-003

[ids]
*

[global]
macro_timeout = 200

[main]

# ─── Cmd (Meta) → "smart Ctrl" with exceptions ─────────────────
leftmeta = layer(meta_mac)
rightmeta = layer(meta_mac)

# ─── Ctrl stays Ctrl (terminal: Ctrl+C, Ctrl+A, tmux) ──────────
# (no mapping needed — default behavior)

# ─── Caps Lock → Escape (tap) / Control (hold) ─────────────────
capslock = overload(control, esc)

# ─── Fix NL ISO layout: 102nd key (right of left shift) ────────
102nd = `

# ─── Section key (top-left, keycode 49) → Escape ───────────────
# On NL Mac ISO this is the §/± key, rarely used
grave = esc

# ─── meta_mac: Cmd acts as Ctrl, with Mac-specific overrides ───
[meta_mac:C]

# App switching: Cmd+Tab → Alt+Tab (Cinnamon window switcher)
tab = A-tab

# Reverse app switch: Cmd+Shift+Tab is handled by Cinnamon (Alt+Shift+Tab)
# keyd propagates Shift automatically through the :C layer

# Cycle windows same app: Cmd+` → Alt+`
` = A-`

# Launcher: Cmd+Space → Super+Space (Ulauncher hotkey)
space = M-space

# Quit: Cmd+Q → Alt+F4 (standard Linux close window)
q = A-f4

# Minimize/hide: Cmd+H → Super+H
h = M-h

# ─── Alt (Option) layer: macOS word-level operations ────────────
[alt]

# Option+Backspace = delete word backward
backspace = C-backspace
delete = C-delete

# Option+Left/Right = word navigation
left = C-left
right = C-right

# Option+Shift+Left/Right = word selection (Shift propagates)
```

## Hoe het werkt — complete mapping table

### Fysiek → Wat het systeem ziet

| Fysieke toetsen | keyd output | Wat er gebeurt |
|---|---|---|
| **⌘+C** | Ctrl+C | Copy (in GUI) |
| **⌘+V** | Ctrl+V | Paste |
| **⌘+X** | Ctrl+X | Cut |
| **⌘+Z** | Ctrl+Z | Undo |
| **⌘+Shift+Z** | Ctrl+Shift+Z | Redo |
| **⌘+A** | Ctrl+A | Select all |
| **⌘+S** | Ctrl+S | Save |
| **⌘+W** | Ctrl+W | Close tab |
| **⌘+T** | Ctrl+T | New tab |
| **⌘+N** | Ctrl+N | New window |
| **⌘+F** | Ctrl+F | Find |
| **⌘+L** | Ctrl+L | Address bar / go to line |
| **⌘+R** | Ctrl+R | Refresh |
| **⌘+P** | Ctrl+P | Print |
| **⌘+Tab** | Alt+Tab | Switch windows |
| **⌘+`** | Alt+` | Cycle same-app windows |
| **⌘+Space** | Super+Space | Ulauncher |
| **⌘+Q** | Alt+F4 | Quit/close window |
| **⌘+H** | Super+H | Minimize |
| **⌘+,** | Ctrl+, | Preferences |
| **Ctrl+C** | Ctrl+C | Terminal interrupt |
| **Ctrl+A** | Ctrl+A | tmux prefix |
| **Ctrl+U** | Ctrl+U | Clear line backward |
| **Ctrl+K** | Ctrl+K | Clear line forward |
| **Ctrl+L** | Ctrl+L | Clear screen |
| **Ctrl+D** | Ctrl+D | EOF/exit |
| **Ctrl+R** | Ctrl+R | Reverse search |
| **Ctrl+Z** | Ctrl+Z | Suspend process |
| **Ctrl+W** | Ctrl+W | Delete word |
| **Alt+Backspace** | Ctrl+Backspace | Delete word |
| **Alt+←** | Ctrl+Left | Word left |
| **Alt+→** | Ctrl+Right | Word right |

### Window tiling (via ⌘+Alt combos)

Fysiek ⌘+Alt drukt `meta_mac` layer (`:C`) + Alt in. Systeem ziet `Ctrl+Alt+key`.

| Fysieke toetsen | keyd output | Cinnamon binding | Actie |
|---|---|---|---|
| **⌘+Alt+H** | Ctrl+Alt+H | `<Ctrl><Alt>h` | ⅓ left |
| **⌘+Alt+J** | Ctrl+Alt+J | `<Ctrl><Alt>j` | ⅓ center |
| **⌘+Alt+K** | Ctrl+Alt+K | `<Ctrl><Alt>k` | ⅓ right |
| **⌘+Alt+Y/U/I** | Ctrl+Alt+Y/U/I | `<Ctrl><Alt>y/u/i` | ⅙ top row |
| **⌘+Alt+N/M/,** | Ctrl+Alt+N/M/, | `<Ctrl><Alt>n/m/,` | ⅙ bottom row |
| **⌘+Alt+1-6** | Ctrl+Alt+1-6 | `<Ctrl><Alt>1-6` | Layouts |
| **⌘+Alt+Enter** | Ctrl+Alt+Return | `<Ctrl><Alt>Return` | Full screen |
| **⌘+Alt+T** | Ctrl+Alt+T | `<Ctrl><Alt>t` | Terminal |
| **⌘+Alt+B** | Ctrl+Alt+B | `<Ctrl><Alt>b` | Browser |
| **⌘+Alt+F** | Ctrl+Alt+F | `<Ctrl><Alt>f` | File manager |

### ½ tiles (momenteel op `<Super><Alt>`)

Die moeten **verplaatst** naar `<Ctrl><Alt><Shift>` of een ander scheme:

| Fysieke toetsen | Voorstel | Actie |
|---|---|---|
| **⌘+Alt+Shift+H** | `<Ctrl><Alt><Shift>h` | ½ left |
| **⌘+Alt+Shift+L** | `<Ctrl><Alt><Shift>l` | ½ right |
| **⌘+Alt+Shift+K** | `<Ctrl><Alt><Shift>k` | ½ top |
| **⌘+Alt+Shift+J** | `<Ctrl><Alt><Shift>j` | ½ bottom |

Of simpeler — **arrow keys** (geen conflict):

| Fysieke toetsen | Cinnamon binding | Actie |
|---|---|---|
| **⌘+Alt+←** | `<Ctrl><Alt>Left` | ½ left |
| **⌘+Alt+→** | `<Ctrl><Alt>Right` | ½ right |
| **⌘+Alt+↑** | `<Ctrl><Alt>Up` | ½ top / maximize |
| **⌘+Alt+↓** | `<Ctrl><Alt>Down` | ½ bottom |

> **Aanbeveling:** arrow keys. Is ook hoe macOS Rectangle/Magnet werkt.

## Cinnamon keybinding changes

De doctor `--fix` moet deze instellen:

```bash
# Window switching → Alt+Tab (keyd stuurt dit voor Cmd+Tab)
gsettings set org.cinnamon.desktop.keybindings.wm switch-windows "['<Alt>Tab']"
gsettings set org.cinnamon.desktop.keybindings.wm switch-windows-backward "['<Alt><Shift>Tab']"

# Tiling arrows
gsettings set org.cinnamon.desktop.keybindings.wm push-tile-left "['<Ctrl><Alt>Left']"
gsettings set org.cinnamon.desktop.keybindings.wm push-tile-right "['<Ctrl><Alt>Right']"
gsettings set org.cinnamon.desktop.keybindings.wm push-tile-up "['<Ctrl><Alt>Up']"
gsettings set org.cinnamon.desktop.keybindings.wm push-tile-down "['<Ctrl><Alt>Down']"

# Clear conflicts
gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source "[]"
gsettings set org.cinnamon.desktop.keybindings.wm switch-input-source-backward "[]"

# Close window → Alt+F4 (keyd stuurt dit voor Cmd+Q)
gsettings set org.cinnamon.desktop.keybindings.wm close "['<Alt>F4']"

# Workspace switching → Ctrl+Alt+Arrow (fysiek: Ctrl+Cmd+Arrow)
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "['<Ctrl><Alt>Left']"
# ^ conflict met tile! Oplossing: workspace op 3-finger swipe (Touchegg), niet keyboard
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-left "[]"
gsettings set org.cinnamon.desktop.keybindings.wm switch-to-workspace-right "[]"
```

### Ulauncher

```bash
# Ulauncher hotkey → Super+Space (keyd stuurt dit voor Cmd+Space)
sed -i 's/"hotkey-show-app": ".*"/"hotkey-show-app": "<Super>space"/' ~/.config/ulauncher/settings.json
```

## Wat de doctor moet checken (keyboard section)

De huidige `check_keyboard()` en `check_kinto()` worden vervangen door:

```bash
check_keyd() {
  step "Keyboard (keyd)"

  # 1. keyd running
  check "keyd service active" systemctl is-active --quiet keyd || {
    repair "Start keyd" sudo systemctl restart keyd
  }

  # 2. Config has meta_mac layer (not dumb swap)
  check "keyd config: meta_mac layer" grep -q "meta_mac:C" /etc/keyd/default.conf || {
    repair "Write correct keyd config" write_keyd_config
  }

  # 3. No conflicting services
  check "xkeysnail NOT running" ! pgrep -x xkeysnail || {
    repair "Stop xkeysnail" bash -c 'sudo systemctl stop xkeysnail; sudo systemctl mask xkeysnail'
  }
  check "kintotray NOT running" ! pgrep -f kintotray || {
    repair "Kill kintotray" pkill -f kintotray
  }

  # 4. Cinnamon switch-windows = Alt+Tab
  local sw
  sw=$(gsettings get org.cinnamon.desktop.keybindings.wm switch-windows 2>/dev/null)
  check "Window switch = Alt+Tab" echo "$sw" | grep -q "Alt" || {
    repair "Set switch-windows to Alt+Tab" \
      gsettings set org.cinnamon.desktop.keybindings.wm switch-windows "['<Alt>Tab']"
  }

  # 5. Ulauncher = Super+Space
  check "Ulauncher hotkey = Super+Space" grep -q '"<Super>space"' ~/.config/ulauncher/settings.json || {
    repair "Set Ulauncher hotkey" \
      sed -i 's/"hotkey-show-app": ".*"/"hotkey-show-app": "<Super>space"/' ~/.config/ulauncher/settings.json
  }

  # 6. No conflicting autostart entries
  check "No xkeysnail autostart" test ! -f ~/.config/autostart/xkeysnail.desktop || {
    repair "Remove xkeysnail autostart" rm ~/.config/autostart/xkeysnail.desktop
  }
  check "No kintotray autostart" test ! -f ~/.config/autostart/kintotray.desktop || {
    repair "Remove kintotray autostart" rm ~/.config/autostart/kintotray.desktop
  }
}
```

## Wat opgeruimd moet worden

| Item | Actie |
|---|---|
| `~/.config/autostart/xkeysnail.desktop` | Verwijderen |
| `~/.config/autostart/kintotray.desktop` | Verwijderen |
| `~/.config/autostart/keyboard-fix.desktop` | Verwijderen (keyd + 102nd fix vervangt xmodmap) |
| `xkeysnail` systemd service | `stop` + `mask` |
| `~/.config/kinto/` | Kan blijven (geen actief effect meer) |
| `~/.xsessionrc` xmodmap regels | Verwijderen (keyd doet het) |
| `plugins/desktop/kinto.sh` | Deprecated markeren in header |

## Impact op bestaande plugins

| Plugin | Impact |
|---|---|
| `core/keyboard` | Vereenvoudigen: alleen `/etc/default/keyboard` + Cinnamon input-source + hid_apple. Geen xmodmap meer. |
| `desktop/keyd` | Herschrijven met nieuwe config (meta_mac layer) |
| `desktop/kinto` | Deprecated (conflicteert met keyd) |
| `scripts/doctor.sh` | `check_kinto()` → `check_keyd()`, keyboard-fix check toevoegen |

## Flow: verse Mint install → werkend systeem

```
$ git clone https://github.com/.../t2-opencare.git
$ cd t2-opencare
$ ./install.sh --core      # kernel, wifi, audio, keyboard, touchbar
$ ./install.sh desktop/keyd # keyd met meta_mac layer
$ ./scripts/doctor.sh --fix # auto-repair alles wat niet klopt
```

Doctor output (voorbeeld):
```
:: Keyboard (keyd)
[  ok] keyd service active
[  ok] keyd config: meta_mac layer
[  ok] xkeysnail NOT running
[  ok] kintotray NOT running
[  ok] Window switch = Alt+Tab
[  ok] Ulauncher hotkey = Super+Space
[  ok] No xkeysnail autostart
[  ok] No kintotray autostart
```

## Skin hot-swap: niet geraakt

Skins wijzigen alleen visuele instellingen (theme, wallpaper, dock, panel). Keyboard mapping is volledig onafhankelijk. `./scripts/skin.sh winxp` en `./scripts/skin.sh macos` werken zonder uit te loggen. ✅

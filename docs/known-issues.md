# Known Issues

## Firefox cursor flicker on multi-monitor (X11 limitation)

**Status:** Open — architectural limitation  
**Date:** 2026-07-15  
**Hardware:** MacBookPro15,2, Intel Iris Plus 655, 3 displays (mixed resolution/DPI)

### Symptoms

- Cursor flickers/distorts ("pie slice" shape) when hovering over Firefox content
- Cursor rapidly alternates between X11 hardware cursor and Firefox CSS cursor
- Worse on links/buttons (cursor state changes: arrow → hand → arrow)
- Typing delay in text fields when Firefox window on secondary display

### Root cause

X11 has no concept of per-monitor DPI for hardware cursors (architecture from 1984). When Firefox/WebRender renders its own cursor via CSS, it conflicts with the X11 cursor — causing flicker on state transitions. macOS doesn't have this because WindowServer manages all cursor rendering in one compositor.

### Workarounds

| Fix | Tradeoff |
|-----|----------|
| Disable HW accel in Firefox | Fixes flicker, but CPU does video decoding |
| Same DPI on all monitors | Fixes flicker, but not practical with mixed hardware |
| `SWcursor` in Xorg | Fixes desktop cursor, not inside Firefox |
| Wait for Cinnamon Wayland | Fundamental fix, not ready yet |

### References

- [linuxmint/linuxmint#443](https://github.com/linuxmint/linuxmint/issues/443) — HiDPI cursor flicker
- [Linux Mint forums: screen flicker with Firefox](https://forums.linuxmint.com/viewtopic.php?t=432105)

---

## Touch ID

**Status:** Not possible  
**Date:** 2026-07-15

Touch ID uses the T2 Secure Enclave which stores fingerprint data in an isolated, encrypted chip. There is no Linux driver and likely never will be — Apple has no incentive to open it, and the security model prevents reverse engineering.

### Alternatives

- `howdy` — face unlock via IR camera (but T2 MacBook camera is routed through apple-bce, may not work with IR)
- PAM fingerprint with a USB fingerprint reader
- Passwordless sudo via polkit (less secure)

---

## Universal clipboard (iPhone ↔ Linux)

**Status:** Workaround available  
**Date:** 2026-07-15

Apple's Universal Clipboard (Handoff) is proprietary and requires iCloud + Bluetooth LE + WiFi peer-to-peer between Apple devices. Not replicable on Linux.

### Alternatives

| Tool | How it works |
|------|-------------|
| [KDE Connect](https://kdeconnect.kde.org/) | Works on Cinnamon too (install `kdeconnect`). Clipboard sync, file transfer, notifications. Requires KDE Connect app on iPhone (limited). |
| [ClipCascade](https://github.com/Sathvik-Rao/ClipCascade) | Self-hosted clipboard sync server. Works cross-platform including iOS via Shortcuts. |
| [Clipboard Portal](https://github.com/nicehash/clipboard-portal) | Simple websocket-based clipboard sharing |
| Shared notes app (Standard Notes, Obsidian) | Manual but reliable |

### Next steps

- [ ] Test KDE Connect with iPhone
- [ ] Test ClipCascade self-hosted setup
- [ ] Document best working solution as a plugin

---

## AirPods Pro

**Status:** Research (see [ADR-001](adr/adr-001-airpods-bluetooth.md))  
**Date:** 2026-07-15

Pairing should work via Bluetooth + PipeWire. Needs hands-on testing for:
- Audio quality (AAC codec support?)
- Microphone in calls
- Auto-connect reliability
- Battery level reporting


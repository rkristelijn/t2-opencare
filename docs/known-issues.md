# Known Issues

## Firefox cursor flicker on multi-monitor

**Status:** Open  
**Date:** 2026-07-15  
**Hardware:** MacBookPro15,2, Intel Iris Plus 655, 3 displays (mixed resolution)

### Symptoms

- Cursor flickers/distorts ("pie slice" shape) when hovering over Firefox content
- Typing delay in text fields when Firefox window is resized to lower-right area
- Occurs on multi-monitor setup: eDP-1 (1280x800) + DP-2 (2560x1440) + DP-1-2 (3840x1080)

### What we tried

1. ✅ VA-API hardware acceleration (`user.js` + env vars) — slight improvement
2. ✅ `SWcursor` in Xorg config — fixes cursor on desktop, not inside Firefox
3. ✅ `dom.ipc.processCount` = 4 — reduces load, doesn't fix flicker
4. ❌ Not yet tried: switch from `modesetting` to `intel` driver
5. ❌ Not yet tried: disable Cinnamon compositor and test
6. ❌ Not yet tried: Firefox Wayland mode (Mint 22 is X11 by default)

### Likely root cause

The `modesetting` driver + WebRender + mixed DPI multi-monitor has a known compositing conflict. Firefox renders its own cursor in some cases (CSS `cursor:` changes), which fights with the X11 hardware/software cursor.

### Potential fixes to explore

- Switch to `intel` Xorg driver (`Option "AccelMethod" "sna"`)
- Disable Firefox internal cursor rendering
- Try `MOZ_USE_XINPUT2=1` env var
- Upgrade to a newer Firefox version (may have WebRender fixes)
- Test with compositor disabled: `cinnamon --replace --no-composite`

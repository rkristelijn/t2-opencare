// t2-opencare Firefox user.js — performance tuning for 16GB MacBook
// This file is loaded on every Firefox start and overrides about:config.
// Manual changes in about:config will be reset on restart.
//
// To revert: delete this file or run the plugin with --restore.

// === Process & Memory ===
// Limit content processes (default 8 → 4, saves ~400MB baseline)
user_pref("dom.ipc.processCount", 4);

// Suspend tabs when system memory is low
user_pref("browser.tabs.unloadOnLowMemory", true);

// Threshold (MB free) at which tabs get unloaded
user_pref("browser.low_commit_space_threshold_mb", 2048);

// Limit memory cache (default: auto, can grow huge)
user_pref("browser.cache.memory.capacity", 262144); // 256MB max

// === Tab Behavior ===
// Don't load tabs from previous session until clicked
user_pref("browser.sessionstore.restore_on_demand", true);
user_pref("browser.sessionstore.restore_pinned_tabs_on_demand", false);

// === Rendering & GPU ===
// Hardware acceleration (Intel Iris Plus 655 via VA-API)
user_pref("layers.acceleration.force-enabled", true);
user_pref("gfx.webrender.all", true);
user_pref("media.ffmpeg.vaapi.enabled", true);
user_pref("media.hardware-video-decoding.force-enabled", true);
user_pref("widget.dmabuf.force-enabled", true);
user_pref("gfx.x11-egl.force-enabled", true);

// Reduce reflow/repaint jank
user_pref("layout.frame_rate", 60);

// === Network (reduce background load) ===
// Disable prefetching (saves CPU + bandwidth)
user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.http.speculative-parallel-limit", 0);

// === Privacy (bonus: also reduces resource usage) ===
// Disable telemetry
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("datareporting.healthreport.uploadEnabled", false);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);

// Disable sponsored content on new tab
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);

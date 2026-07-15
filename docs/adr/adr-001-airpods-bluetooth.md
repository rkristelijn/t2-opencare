# ADR-001: AirPods / Bluetooth Audio Support

*Status*: Proposed · *Date*: 2026-07-15

## Context

AirPods (Pro) should work on the T2 MacBook via Bluetooth. Initial research shows:
- PipeWire + BlueZ handles pairing and audio
- A2DP works for playback, HSP/HFP for mic
- May need `libspa-0.2-bluetooth` package
- Apple-specific features (auto-pause, seamless handoff) don't work natively

## Questions to resolve

- Does `apple-firmware` package include BT firmware for AirPods pairing?
- Is AAC codec supported OOTB or do we need `pipewire-codec-aptx`?
- Can we detect AirPods battery level reliably?
- Is there a way to auto-connect on lid open / case open?
- Does the [handoff](https://github.com/xatuke/handoff) project work for Mac↔Linux switching?

## Options

1. **`core/bluetooth` plugin** — ensure BT firmware + PipeWire codecs are installed, pair instructions
2. **`tools/airpods` plugin** — specific AirPods optimizations (codec priority, battery widget)
3. **Combined** — bluetooth as core, airpods as optional tools layer

## Decision

TBD — needs hands-on testing with actual AirPods.

## Next steps

- [ ] Test pairing AirPods Pro with current setup
- [ ] Check audio quality (A2DP vs SBC vs AAC)
- [ ] Test microphone in calls
- [ ] Document findings and build plugin

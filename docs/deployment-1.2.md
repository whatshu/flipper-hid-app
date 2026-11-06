> Archived investigation snapshot. For the current source layout and verification, see [development notes](development-notes.md).

# Version 1.2 deployment verification

Verified on 2026-11-06 with official Flipper Zero firmware 1.5.1, target f7,
API 88.2, and OPPO Find N5 / Android 16. This supersedes the earlier note that
the device FAP differed from the local build.

## Build and installation

- `build.ps1 lint` passed.
- `build.ps1` built both Bluetooth and USB FAPs; both passed API 88.2 checks.
- `build.ps1 launch APPID=hid_ble` installed and launched Bluetooth Remote 1.2.
- Device path: `/ext/apps/Bluetooth/hid_ble.fap`.
- The installed FAP was downloaded back from the device and compared with
  `dist/hid_ble.fap`; both files were 90324 bytes with identical SHA256:

```text
55260824e97dadd6aec4ab0d64658deb56ec9c431ee09820505e5ef43cd4ef65
```

The prior device app was backed up locally before replacement. The existing
Remote Bluetooth bond reconnected without re-pairing. No firmware was flashed.

## Functional checks after installation

All test control keys came from the Flipper's Media (Android) view over Bluetooth.
Android recorded Consumer usage 0x0C/0xCD as KEY_PLAYPAUSE DOWN/UP; OK did not
inject Space, Enter or a simulated screen tap.

| Foreground player | Observed playback-state transitions |
| --- | --- |
| VLC local video | PAUSED → PLAYING → PAUSED → PLAYING; final OK paused it |
| Bilibili, playlist half-screen | PLAYING → PAUSED → PLAYING |
| Bilibili, playlist landscape full-screen | PLAYING → PAUSED → PLAYING → PAUSED |

The full-screen check included a landscape screenshot (2616 × 1140), not just
the Activity name. Bilibili remained in UnitedPlaylistActivity while keys were
sent. Key Mapper's accessibility and notification-listener permissions were off.

Local diagnostic records under `D:\project\flipper\env`:

- `final-deploy-vlc.json`, `final-deploy-vlc-paused.json`
- `final-deploy-bili-playlist-half.json`, `final-deploy-bili-fullscreen.json`
- `final-deploy-bili-fullscreen-before.png`
- `backups\hid_ble-final-installed-1.2.fap` (read-back copy)

USB received build/API checks only. Other Bluetooth hosts were not functionally
tested. Keyboard arrows remain focus-sensitive; seeking is not claimed as fixed.
Earlier Android/Bilibili failures were not reproduced with this installed build,
but their exact framework/app cause was not identified.
